#!/usr/bin/env python3
"""Build a self-contained Lua-Flash Player .love package (not a Windows EXE).

Uses only Python stdlib and the player-lua directory. Never packs Studio code,
legacy Adobe binaries, test scripts, or a Git history.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import sys
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

ROOT = Path(__file__).resolve().parent.parent
PLAYER = ROOT / "player-lua"
REQUIRED = {
    "main.lua", "conf.lua", "src/model.lua", "src/runtime.lua",
    "src/demo.lua", "src/transport.lua", "src/interpolation.lua",
    "src/input.lua", "src/target_game.lua",
    "src/package.lua", "src/package_v2.lua", "src/package_v3.lua",
    "src/package_v4.lua", "src/package_v5.lua", "src/package_v6.lua",
    "src/package_v7.lua", "src/package_v8.lua", "src/package_v9.lua", "src/sprite_transform.lua",
    "src/sprite_tween.lua", "src/keyframe_editor.lua", "src/edit_history.lua",
    "src/recovery.lua", "src/diagnostics.lua", "src/media_runtime.lua",
    "src/session.lua", "src/collision.lua", "src/pixel_mask.lua",
    "src/game_example.lua", "src/game_example_v2.lua",
    "src/game_example_v3.lua", "src/game_example_v4.lua", "src/game_example_v5.lua", "src/game_example_v6.lua", "src/game_example_v7.lua",
    "src/game_example_v8.lua", "src/game_example_v9.lua",
}
VERSION = "0.17"


def build(output: Path) -> None:
    scripts = sorted(p for p in PLAYER.rglob("*.lua") if p.is_file())
    entries = {str(p.relative_to(PLAYER)).replace("\\", "/") for p in scripts}
    missing = REQUIRED - entries
    if missing:
        raise RuntimeError("missing required Player modules: " + ", ".join(sorted(missing)))
    if any(p.is_symlink() for p in scripts):
        raise RuntimeError("refusing to pack symlink")
    output.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(output, "w", compression=ZIP_DEFLATED, compresslevel=9) as archive:
        for path in scripts:
            name = path.relative_to(PLAYER).as_posix()
            info = ZipInfo(name, (2026, 1, 1, 0, 0, 0))
            info.compress_type = ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            archive.writestr(info, path.read_bytes(), compress_type=ZIP_DEFLATED, compresslevel=9)
    with ZipFile(output, "r") as z:
        got = set(z.namelist())
        assert REQUIRED <= got
        assert all(n.endswith(".lua") and not n.startswith("/") and ".." not in n for n in got)
        assert z.testzip() is None
    print(f"Created {output} ({output.stat().st_size} bytes), {len(scripts)} Lua files")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=ROOT / "dist" / f"Lua-Flash-Player-{VERSION}.love")
    args = parser.parse_args()
    try:
        build(args.output)
    except (OSError, RuntimeError, AssertionError) as exc:
        print("Error: " + str(exc), file=sys.stderr)
        sys.exit(1)
