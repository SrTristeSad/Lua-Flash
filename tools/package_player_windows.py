#!/usr/bin/env python3
"""Package Lua-Flash Player as a fused Windows x64 LÖVE application.

Consumes the verified OFFICIAL LÖVE 11.5 win64 zip and our own .love archive.
No binary downloads at runtime, no Studio assets, and no machine-local paths.
This tool does not create an installer or digitally sign the executable.
"""
from __future__ import annotations

import argparse
import hashlib
from pathlib import Path, PurePosixPath
import shutil
import tempfile
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

VERSION = "0.20"
LOVE_VERSION = "11.5"
LOVE_DIR = "love-11.5-win64"
# Pinned against the public Scoop love.json 11.5 win64 distribution.
LOVE_SHA256 = "ba6e56be2685e53c817749c4a5007f51137136fe5a3ab64920508babc2e74369"
OUTPUT_DIR = f"Lua-Flash-Player-{VERSION}-Windows-x64"
EXE_NAME = "Lua-Flash-Player.exe"
ROOT = Path(__file__).resolve().parent.parent

README = """Lua-Flash Player 0.20 — Windows x64 (portable)
===================================================
1. Extract ALL contents of this ZIP into one folder.
2. Double-click Lua-Flash-Player.exe.
3. Do not remove or move its adjacent DLL files.
4. To import, drag a native .lflash or .lfgame file into the window.

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
    actual_hash = hashlib.file_digest(love_zip.open("rb"), "sha256").hexdigest()
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
        _add(archive, f"{OUTPUT_DIR}/README-Windows.txt", README.encode("utf-8"))
        for name in sorted(extracted):
            _add(archive, f"{OUTPUT_DIR}/{name}", extracted[name])
    with ZipFile(output, "r") as verify:
        if verify.testzip() is not None:
            raise ValueError("Windows release failed ZIP integrity check")
        names = verify.namelist()
        if f"{OUTPUT_DIR}/{EXE_NAME}" not in names:
            raise AssertionError("fused application missing from output")
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
