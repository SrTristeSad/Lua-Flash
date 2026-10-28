#!/usr/bin/env python3
"""Package Lua-Flash Player as a fused Windows x64 LÖVE application.

Consumes the verified OFFICIAL LÖVE 11.5 win64 zip and our own .love archive.
No binary downloads at runtime, no Studio assets, and no machine-local paths.
This tool does not create an installer or digitally sign the executable.
"""
from __future__ import annotations

import argparse
import hashlib
import math
import struct
import zlib
from pathlib import Path, PurePosixPath
import tempfile
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

VERSION = "0.22"
LOVE_VERSION = "11.5"
LOVE_DIR = "love-11.5-win64"
# Pinned against the public Scoop love.json 11.5 win64 distribution.
LOVE_SHA256 = "ba6e56be2685e53c817749c4a5007f51137136fe5a3ab64920508babc2e74369"
OUTPUT_DIR = f"Lua-Flash-Player-{VERSION}-Windows-x64"
EXE_NAME = "Lua-Flash-Player.exe"
LAUNCHER_NAME = "ABRIR-JOGO.cmd"
ICON_NAME = "Lua-Flash-Player.ico"
ROOT = Path(__file__).resolve().parent.parent

README = """Lua-Flash Player 0.22 — Windows x64 (portable)
===================================================
1. Extract ALL contents of this ZIP into one folder.
2. Double-click Lua-Flash-Player.exe.
3. Do not remove or move its adjacent DLL files.
4. Click ABRIR ARQUIVO or press Ctrl+O for the Windows file picker.
   Ctrl+Shift+O keeps the manual paste-path dialog as a fallback.
5. You can also drag .lflash/.lfgame into the window or onto ABRIR-JOGO.cmd.
6. Use Windows 'Open With...' to select Lua-Flash-Player.exe for these files.
   This portable build DOES NOT change Windows registry or associations.
An original Lua-Flash icon is used for the running window and is supplied as
Lua-Flash-Player.ico for custom desktop shortcuts. The unsigned executable
still uses the upstream runtime's PE icon resource.

The Player embeds LÖVE 11.5; installing LÖVE separately is NOT required.
This is NOT an MSI installer, and is not digitally signed. Windows may
show a SmartScreen warning for unsigned executables.

This software reads Lua-Flash native files (LUAFGAME 1–9, .lflash).
It DOES NOT execute Adobe SWF/FLA/ActionScript programs.
The Studio application is not included.
LÖVE is distributed under its own license. The official bundled copyright
and license text is included alongside the executable.

Source: https://github.com/SrTristeSad/Lua-Flash
Runtime: https://github.com/love2d/love/releases/tag/11.5

No guarantees are made for every Windows GPU or installation. Test on your
hardware before treating the player as production ready.
"""

LAUNCHER = b"""@echo off\r
setlocal\r
if "%~1"=="" (\r
  echo Arraste um arquivo .lflash ou .lfgame para este .cmd.\r
  pause\r
  exit /b 1\r
)\r
if not exist "%~1" (\r
  echo Arquivo nao encontrado.\r
  pause\r
  exit /b 1\r
)\r
start "" "%~dp0Lua-Flash-Player.exe" "%~f1"\r
"""


def original_icon_ico(size: int = 64) -> bytes:
    """Original bolt artwork, encoded as a standards-compliant PNG-in-ICO."""
    def inside_polygon(x: float, y: float, pts: tuple[int, ...]) -> bool:
        hit = False
        for i in range(0, len(pts), 2):
            j = (i + 2) % len(pts)
            xi, yi, xj, yj = pts[i], pts[i + 1], pts[j], pts[j + 1]
            if (yi > y) != (yj > y) and x < (
                (xj - xi) * (y - yi) / (yj - yi) + xi
            ):
                hit = not hit
        return hit

    bolt = (36, 9, 20, 34, 30, 34, 25, 55, 47, 28, 36, 28, 43, 9)
    pixels = bytearray()
    for y in range(size):
        pixels.append(0)  # PNG filter type none
        for x in range(size):
            xx, yy = (x + .5) * 64 / size, (y + .5) * 64 / size
            dx, dy = abs(xx - 32) - 27, abs(yy - 32) - 27
            d = math.hypot(max(dx + 10, 0), max(dy + 10, 0)) + min(
                max(dx + 10, dy + 10), 0
            ) - 10
            alpha = max(0, min(1, .5 - d))
            r, g, b = .064, .094, .18
            ox, oy = (xx - 32) / 23, (yy - 32) / 23
            if abs(ox * ox + oy * oy - 1) < .135 and xx < 47:
                r, g, b = .10, .72, .95
            if inside_polygon(xx, yy, bolt):
                r, g, b = (.97, .88, .35) if xx <= 35 else (1, .72, .20)
            pixels.extend(
                (int(c * 255 + .5) for c in (r, g, b, alpha))
            )

    def chunk(kind: bytes, data: bytes) -> bytes:
        return (struct.pack(">I", len(data)) + kind + data +
                struct.pack(">I", zlib.crc32(kind + data) & 0xffffffff))

    png = (b"\x89PNG\r\n\x1a\n" +
           chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)) +
           chunk(b"IDAT", zlib.compress(pixels, 9)) +
           chunk(b"IEND", b""))
    header = struct.pack("<HHH", 0, 1, 1)
    entry = struct.pack("<BBBBHHII", size if size < 256 else 0,
                        size if size < 256 else 0, 0, 0, 1, 32,
                        len(png), 22)
    return header + entry + png


def _safe_name(name: str) -> PurePosixPath:
    if "\\" in name or name.startswith("/") or "\x00" in name:
        raise ValueError(f"unsafe LÖVE archive entry: {name!r}")
    path = PurePosixPath(name)
    if ".." in path.parts or any(part == "" for part in path.parts):
        raise ValueError(f"unsafe archive traversal: {name!r}")
    return path


def _add(archive: ZipFile, name: str, data: bytes) -> None:
    info = ZipInfo(name, (2026, 1, 1, 0, 0, 0))
    info.compress_type = ZIP_DEFLATED
    info.external_attr = 0o644 << 16
    archive.writestr(info, data, compress_type=ZIP_DEFLATED, compresslevel=9)


def build(love_zip: Path, game: Path, output: Path) -> None:
    with love_zip.open("rb") as source:
        actual_hash = hashlib.file_digest(source, "sha256").hexdigest()
    if actual_hash != LOVE_SHA256:
        raise ValueError(
            f"official LÖVE archive checksum mismatch: got {actual_hash}, "
            f"expected {LOVE_SHA256}"
        )
    if not game.is_file() or game.stat().st_size > 25 * 1024 * 1024:
        raise ValueError("missing or oversized .love game")

    with ZipFile(game, "r") as game_archive:
        if game_archive.testzip() is not None:
            raise ValueError("game .love archive failed CRC test")
        expected = {"main.lua", "conf.lua", "src/package_v9.lua"}
        if not expected.issubset(set(game_archive.namelist())):
            raise ValueError("game .love archive missing Player runtime files")
    game_data = game.read_bytes()

    extracted: dict[str, bytes] = {}
    with ZipFile(love_zip, "r") as official:
        if official.testzip() is not None:
            raise ValueError("official LÖVE ZIP failed CRC test")
        for item in official.infolist():
            path = _safe_name(item.filename)
            if item.is_dir():
                continue
            # Ignore top-level listing noise but reject unexpected inner paths.
            if len(path.parts) < 2 or path.parts[0] != LOVE_DIR:
                raise ValueError(f"unexpected LÖVE distribution path: {path}")
            relative = PurePosixPath(*path.parts[1:])
            if len(relative.parts) != 1:
                raise ValueError(f"unexpected LÖVE nested executable: {relative}")
            name = str(relative)
            if name in extracted:
                raise ValueError(f"duplicate Windows runtime file: {name}")
            extracted[name] = official.read(item)
    source_exe = extracted.pop("love.exe", None)
    if not source_exe or not source_exe.startswith(b"MZ"):
        raise ValueError("official Windows 64-bit love.exe was not found")
    extracted.pop("lovec.exe", None)  # console-only launcher isn't needed.

    dlls = [name for name in extracted if name.lower().endswith(".dll")]
    if not dlls:
        raise ValueError("LÖVE distribution must contain its required DLLs")
    legal = [name for name in extracted if "license" in name.lower()
             or "licence" in name.lower() or "copyright" in name.lower()]
    if not legal:
        raise ValueError("LÖVE distribution did not contain a license file")

    # Fusing is official LOVE.exe followed by the .love ZIP, byte-for-byte.
    # LÖVE locates its ZIP payload at the end of the Windows PE executable.
    fused = source_exe + game_data
    if not fused.startswith(b"MZ"):
        raise AssertionError("invalid fused PE header")
    with tempfile.TemporaryDirectory() as tmp:
        executable_path = Path(tmp) / EXE_NAME
        executable_path.write_bytes(fused)
        with ZipFile(executable_path, "r") as embedded:
            if embedded.testzip() is not None or "main.lua" not in embedded.namelist():
                raise ValueError("fused executable is missing its playable .love")
            if embedded.read("main.lua") != game_archive_main(game):
                raise ValueError("fused executable contains a different game")

    output.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(output, "w") as archive:
        _add(archive, f"{OUTPUT_DIR}/{EXE_NAME}", fused)
        _add(archive, f"{OUTPUT_DIR}/{LAUNCHER_NAME}", LAUNCHER)
        _add(archive, f"{OUTPUT_DIR}/{ICON_NAME}", original_icon_ico())
        _add(archive, f"{OUTPUT_DIR}/README-Windows.txt", README.encode("utf-8"))
        for name in sorted(extracted):
            _add(archive, f"{OUTPUT_DIR}/{name}", extracted[name])
    with ZipFile(output, "r") as verify:
        if verify.testzip() is not None:
            raise ValueError("Windows release failed ZIP integrity check")
        names = verify.namelist()
        if f"{OUTPUT_DIR}/{EXE_NAME}" not in names:
            raise AssertionError("fused application missing from output")
        if f"{OUTPUT_DIR}/{ICON_NAME}" not in names:
            raise AssertionError("portable original icon missing")
        if f"{OUTPUT_DIR}/{LAUNCHER_NAME}" not in names:
            raise AssertionError("file activation launcher missing from output")
        if not any(name.lower().endswith(".dll") for name in names):
            raise AssertionError("Windows DLLs missing from output")
    print(
        f"Created {output} ({output.stat().st_size:,} bytes); "
        f"{len(dlls)} DLLs; {len(legal)} runtime license files; fused .love verified"
    )


def game_archive_main(game: Path) -> bytes:
    with ZipFile(game, "r") as archive:
        return archive.read("main.lua")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--love-zip", type=Path, required=True)
    parser.add_argument("--game", type=Path,
                        default=ROOT / "dist" / f"Lua-Flash-Player-{VERSION}.love")
    parser.add_argument("--output", type=Path,
                        default=ROOT / "dist" / f"{OUTPUT_DIR}.zip")
    args = parser.parse_args()
    try:
        build(args.love_zip, args.game, args.output)
    except (OSError, AssertionError, ValueError, RuntimeError) as error:
        parser.exit(1, f"Windows build failed: {error}\n")
