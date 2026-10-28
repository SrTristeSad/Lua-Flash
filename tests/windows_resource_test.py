#!/usr/bin/env python3
"""Offline tests for native Windows PE icon group payloads."""
from __future__ import annotations
import importlib.util
from pathlib import Path
import struct

ROOT=Path(__file__).resolve().parent.parent
def load(name,path):
    spec=importlib.util.spec_from_file_location(name,path)
    assert spec and spec.loader
    mod=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod
windows=load("windows_resources",ROOT/"tools/windows_resources.py")
package=load("package_player_windows",ROOT/"tools/package_player_windows.py")
ico=package.original_icon_ico()
image,group=windows.split_ico(ico)
assert image.startswith(b"\x89PNG\r\n\x1a\n")
assert group[:6]==struct.pack("<HHH",0,1,1)
width,height,colors,reserved,planes,depth,length,id=struct.unpack_from(
    "<BBBBHHIH",group,6
)
assert (width,height,depth,id)==(64,64,32,windows.IMAGE_ID)
assert length==len(image)
for bad in (ico[:20],b"invalid ICO",ico[:4]+b"\x02\x00"+ico[6:],
            ico[:18]+struct.pack("<I",999999)+ico[22:]):
    try: windows.split_ico(bad)
    except ValueError: pass
    else: raise AssertionError("accepted broken icon")
print("OK: original PNG ICO and Windows RT_ICON/RT_GROUP_ICON table encoding")
