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
version=windows.build_version_info()
assert struct.unpack_from("<H",version,0)[0]==len(version)
assert "VS_VERSION_INFO".encode("utf-16le") in version
assert "Lua-Flash Player".encode("utf-16le") in version
assert "0.26.0.0".encode("utf-16le") in version
assert "Lua-Flash-Player.exe".encode("utf-16le") in version
assert struct.pack("<I",0xFEEF04BD) in version
assert struct.pack("<I",26) in version
assert windows.RT_VERSION==16
for major,minor in ((-1,24),(0,65536)):
    try: windows.build_version_info(major,minor)
    except ValueError: pass
    else: raise AssertionError("accepted invalid file version")
print("OK: original PNG ICO, Windows RT_ICON/RT_GROUP_ICON and 0.26 VERSIONINFO")
