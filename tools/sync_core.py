#!/usr/bin/env python3
"""Keep standalone LÖVE apps ABI-compatible with the same model and renderer."""
from pathlib import Path
import argparse
import sys

root = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser()
parser.add_argument("--check", action="store_true")
args = parser.parse_args()

different = []
for name in ("model.lua", "runtime.lua"):
    origin = root / "player-lua" / "src" / name
    target = root / "studio-lua" / "src" / name
    if origin.read_bytes() != target.read_bytes():
        different.append(name)
        if not args.check:
            target.write_bytes(origin.read_bytes())
            print(f"Synced {name}")
if different and args.check:
    print("Incompatible core modules: " + ", ".join(different), file=sys.stderr)
    sys.exit(1)
print("Shared core in sync.")
