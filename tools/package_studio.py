#!/usr/bin/env python3
"""Build a reproducible standalone .love archive for Lua-Flash Studio."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "studio-lua"
DEST = ROOT / "dist" / "Lua-Flash-Studio-0.2.love"

def main():
    assert (SOURCE / "main.lua").is_file(), "Studio entry point missing"
    assert (SOURCE / "conf.lua").is_file(), "Studio configuration missing"
    files = sorted(p for p in SOURCE.rglob("*") if p.is_file())
    assert files, "Empty Studio source"
    DEST.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(DEST, "w", ZIP_DEFLATED) as bundle:
        for path in files:
            bundle.write(path, path.relative_to(SOURCE).as_posix())
    with ZipFile(DEST) as bundle:
        assert bundle.testzip() is None, "Corrupt Studio bundle"
        assert {"main.lua", "conf.lua"} <= set(bundle.namelist())
    print(f"Studio packaged: {DEST} ({len(files)} files)")

if __name__ == "__main__":
    main()
