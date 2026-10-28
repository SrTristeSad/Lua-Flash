#!/usr/bin/env python3
"""Offline tests for the portable Windows x64 packager.

No downloaded binaries required: use tiny synthetic PE, DLL, and .love data.
The real CI Windows job supplies the pinned LÖVE 11.5 distribution.
"""
from __future__ import annotations

import hashlib
import importlib.util
from pathlib import Path
import tempfile
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parent.parent
PATH = ROOT / "tools/package_player_windows.py"
spec = importlib.util.spec_from_file_location("package_player_windows", PATH)
assert spec and spec.loader
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def run() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        work = Path(tmp)
        game = work / "game.love"
        with ZipFile(game, "w") as out:
            for name in ("main.lua", "conf.lua", "src/package_v9.lua"):
                out.writestr(name, "-- Lua-Flash test\n")
        official_zip = work / "runtime.zip"
        with ZipFile(official_zip, "w") as out:
            root = "love-11.5-win64/"
            out.writestr(root + "love.exe", b"MZ" + bytes(254))
            out.writestr(root + "lovec.exe", b"MZ" + bytes(254))
            out.writestr(root + "SDL2.dll", b"MZ" + b"SDL")
            out.writestr(root + "OpenAL32.dll", b"MZ" + b"AUDIO")
            out.writestr(root + "license.txt", b"zlib license test")
        # Replace the fixed official checksum only in this locally loaded module.
        official_hash = module.LOVE_SHA256
        module.LOVE_SHA256 = hashlib.sha256(official_zip.read_bytes()).hexdigest()
        output = work / "release.zip"
        module.build(official_zip, game, output)
        with ZipFile(output, "r") as archive:
            root = module.OUTPUT_DIR + "/"
            exe_name = root + module.EXE_NAME
            names = archive.namelist()
            assert exe_name in names
            assert root + "SDL2.dll" in names
            assert root + "OpenAL32.dll" in names
            assert root + "license.txt" in names
            assert root + "README-Windows.txt" in names
            assert root + module.LAUNCHER_NAME in names
            assert root + module.ICON_NAME in names
            ico = archive.read(root + module.ICON_NAME)
            assert ico[:4] == b"\x00\x00\x01\x00" and b"PNG" in ico[:40]
            launcher = archive.read(root + module.LAUNCHER_NAME)
            assert b"Lua-Flash-Player.exe" in launcher
            assert b"%~f1" in launcher
            assert root + "love.exe" not in names
            assert root + "lovec.exe" not in names
            exe = work / "Lua-Flash-Player.exe"
            exe.write_bytes(archive.read(exe_name))
            assert exe.read_bytes().startswith(b"MZ")
        with ZipFile(exe, "r") as embedded:
            assert set(("main.lua", "conf.lua", "src/package_v9.lua")) <= set(
                embedded.namelist()
            )
            assert embedded.read("main.lua") == b"-- Lua-Flash test\n"
        # A modified or unpinned runtime MUST NOT be packaged.
        module.LOVE_SHA256 = official_hash
        try:
            module.build(official_zip, game, work / "bad.zip")
        except ValueError as err:
            assert "checksum mismatch" in str(err)
        else:
            raise AssertionError("runtime checksum was not checked")
        # Reject crafted escape entries, even from a locally trusted caller.
        assert ".." in "a/../b"
        try:
            module._safe_name("love-11.5-win64/../../malware.dll")
        except ValueError:
            pass
        else:
            raise AssertionError("unsafe archive path was accepted")

    print("OK: portable Windows packager fusion, DLLs, game payload, checksum and paths")


if __name__ == "__main__":
    run()
