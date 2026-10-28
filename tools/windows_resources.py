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
GROUP_ID = 1
IMAGE_ID = 50000


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
    kernel = _kernel()
    module = kernel.LoadLibraryExW(str(executable), None, 0x2)
    if not module:
        raise ctypes.WinError(ctypes.get_last_error())
    try:
        for kind, ident, expected in (
            (RT_ICON, IMAGE_ID, image),
            (RT_GROUP_ICON, GROUP_ID, group),
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
    a = p.parse_args()
    embed_icon(a.exe, a.ico.read_bytes())
    print("Verified original Lua-Flash icon embedded in executable resources")
