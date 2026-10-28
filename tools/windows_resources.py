#!/usr/bin/env python3
"""Embed an original icon as Win32 PE resources without external executables.

The resource is inserted into the upstream LÖVE .exe *before* fusing .love.
Only standard Python ctypes is used. The ICO has one 64x64 PNG image.
"""
from __future__ import annotations

import ctypes
from ctypes import wintypes
import os
from pathlib import Path
import struct

RT_ICON = 3
RT_GROUP_ICON = 14
RT_VERSION = 16
VERSION_ID = 1
GROUP_ID = 1
IMAGE_ID = 50000



def build_version_info(major: int = 0, minor: int = 24) -> bytes:
    """Create a standard VS_VERSION_INFO block without third-party tools.

    FILEVERSION and PRODUCTVERSION use four 16-bit numbers. The Windows
    Explorer Details panel reads this from RT_VERSION resource 1.
    """
    if not (0 <= major <= 65535 and 0 <= minor <= 65535):
        raise ValueError("invalid Windows version")
    def align(buffer: bytearray) -> None:
        buffer.extend(b"\0" * ((-len(buffer)) % 4))

    def utf16(value: str) -> bytes:
        return (value + "\0").encode("utf-16le")

    def block(key: str, value: bytes = b"", children: tuple[bytes, ...] = (),
              string: bool = False) -> bytes:
        data = bytearray(b"\0" * 6)
        data.extend(utf16(key))
        align(data)
        data.extend(value)
        align(data)
        for child in children:
            data.extend(child)
            align(data)
        if len(data) > 65535:
            raise ValueError("Windows version resource exceeds DWORD size")
        struct.pack_into("<HHH", data, 0, len(data),
                         len(value) // 2 if string else len(value),
                         1 if string else 0)
        return bytes(data)

    fixed = struct.pack(
        "<13I",
        0xFEEF04BD, 0x00010000,  # VS_FIXEDFILEINFO signature/version
        (major << 16) | minor, 0,
        (major << 16) | minor, 0,
        0x3F, 0, 0x00040004, 1, 0, 0, 0
    )
    metadata = {
        "CompanyName": "Lua-Flash Community",
        "FileDescription": "Lua-Flash Player for Windows",
        "FileVersion": f"{major}.{minor}.0.0",
        "InternalName": "Lua-Flash-Player",
        "LegalCopyright": "Lua-Flash contributors",
        "OriginalFilename": "Lua-Flash-Player.exe",
        "ProductName": "Lua-Flash Player",
        "ProductVersion": f"{major}.{minor}.0.0",
    }
    strings = tuple(block(k, utf16(v), string=True)
                    for k, v in sorted(metadata.items()))
    string_table = block("040904B0", children=strings, string=True)
    string_info = block("StringFileInfo", children=(string_table,), string=True)
    translation = block("Translation", struct.pack("<HH", 0x0409, 1200))
    var_info = block("VarFileInfo", children=(translation,), string=True)
    return block("VS_VERSION_INFO", fixed, (string_info, var_info))


def _id(value: int) -> ctypes.c_void_p:
    return ctypes.c_void_p(value)


def split_ico(ico: bytes) -> tuple[bytes, bytes]:
    if len(ico) < 22:
        raise ValueError("icon is truncated")
    reserved, icon_type, count = struct.unpack_from("<HHH", ico)
    if reserved != 0 or icon_type != 1 or count != 1:
        raise ValueError("expected a single-image ICO")
    width, height, colors, reserved_byte, planes, depth, length, offset = (
        struct.unpack_from("<BBBBHHII", ico, 6)
    )
    if width != 64 or height != 64 or reserved_byte != 0 or \
            length < 32 or offset + length != len(ico):
        raise ValueError("ICO image bounds or dimensions are invalid")
    image = ico[offset:offset + length]
    if not image.startswith(b"\x89PNG\r\n\x1a\n"):
        raise ValueError("ICO must contain PNG image data")
    # GRPICONDIRENTRY changes DWORD file offset into WORD resource ID.
    group = (struct.pack("<HHH", 0, 1, 1) +
             struct.pack("<BBBBHHIH", width, height, colors, reserved_byte,
                         planes, depth, length, IMAGE_ID))
    return image, group


def _kernel():
    if os.name != "nt":
        raise OSError("Windows PE resource operations require Windows")
    dll = ctypes.WinDLL("kernel32", use_last_error=True)
    dll.BeginUpdateResourceW.argtypes = (wintypes.LPCWSTR, wintypes.BOOL)
    dll.BeginUpdateResourceW.restype = wintypes.HANDLE
    dll.UpdateResourceW.argtypes = (
        wintypes.HANDLE, ctypes.c_void_p, ctypes.c_void_p,
        wintypes.WORD, ctypes.c_void_p, wintypes.DWORD
    )
    dll.UpdateResourceW.restype = wintypes.BOOL
    dll.EndUpdateResourceW.argtypes = (wintypes.HANDLE, wintypes.BOOL)
    dll.EndUpdateResourceW.restype = wintypes.BOOL
    dll.LoadLibraryExW.argtypes = (
        wintypes.LPCWSTR, wintypes.HANDLE, wintypes.DWORD
    )
    dll.LoadLibraryExW.restype = wintypes.HANDLE
    dll.FindResourceW.argtypes = (
        wintypes.HANDLE, ctypes.c_void_p, ctypes.c_void_p
    )
    dll.FindResourceW.restype = wintypes.HANDLE
    dll.SizeofResource.argtypes = (wintypes.HANDLE, wintypes.HANDLE)
    dll.SizeofResource.restype = wintypes.DWORD
    dll.LoadResource.argtypes = (wintypes.HANDLE, wintypes.HANDLE)
    dll.LoadResource.restype = wintypes.HANDLE
    dll.LockResource.argtypes = (wintypes.HANDLE,)
    dll.LockResource.restype = ctypes.c_void_p
    dll.FreeLibrary.argtypes = (wintypes.HANDLE,)
    dll.FreeLibrary.restype = wintypes.BOOL
    return dll


def embed_icon(executable: Path, ico: bytes) -> None:
    image, group = split_ico(ico)
    version = build_version_info()
    if not executable.is_file() or executable.read_bytes()[:2] != b"MZ":
        raise ValueError("expected an existing Windows PE executable")
    kernel = _kernel()
    handle = kernel.BeginUpdateResourceW(str(executable), False)
    if not handle:
        raise ctypes.WinError(ctypes.get_last_error())
    success = False
    try:
        for kind, ident, data in (
            (RT_ICON, IMAGE_ID, image),
            (RT_GROUP_ICON, GROUP_ID, group),
            (RT_VERSION, VERSION_ID, version),
        ):
            buffer = ctypes.create_string_buffer(data)
            if not kernel.UpdateResourceW(
                handle, _id(kind), _id(ident), 0,
                ctypes.cast(buffer, ctypes.c_void_p), len(data)
            ):
                raise ctypes.WinError(ctypes.get_last_error())
        success = True
    finally:
        if not kernel.EndUpdateResourceW(handle, not success):
            raise ctypes.WinError(ctypes.get_last_error())
    verify_icon(executable, ico)


def verify_icon(executable: Path, ico: bytes) -> None:
    image, group = split_ico(ico)
    version = build_version_info()
    kernel = _kernel()
    module = kernel.LoadLibraryExW(str(executable), None, 0x2)
    if not module:
        raise ctypes.WinError(ctypes.get_last_error())
    try:
        for kind, ident, expected in (
            (RT_ICON, IMAGE_ID, image),
            (RT_GROUP_ICON, GROUP_ID, group),
            (RT_VERSION, VERSION_ID, version),
        ):
            item = kernel.FindResourceW(module, _id(ident), _id(kind))
            if not item:
                raise ValueError("embedded PE icon resource not found")
            size = kernel.SizeofResource(module, item)
            handle = kernel.LoadResource(module, item)
            ptr = kernel.LockResource(handle)
            if not ptr or size != len(expected) or \
                    ctypes.string_at(ptr, size) != expected:
                raise ValueError("embedded PE icon payload differs")
    finally:
        kernel.FreeLibrary(module)


if __name__ == "__main__":
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument("exe", type=Path)
    p.add_argument("ico", type=Path)
    p.add_argument("--verify", action="store_true")
    a = p.parse_args()
    if a.verify:
        verify_icon(a.exe,a.ico.read_bytes())
    else:
        embed_icon(a.exe,a.ico.read_bytes())
    print("Verified original Lua-Flash icon embedded in executable resources")
