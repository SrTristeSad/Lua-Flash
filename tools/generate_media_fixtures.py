#!/usr/bin/env python3
"""Generate tiny ORIGINAL PNG & WAV test fixtures using Python stdlib only."""
from __future__ import annotations
import argparse, math, struct, wave, zlib
from pathlib import Path

def chunk(name: bytes, payload: bytes) -> bytes:
    return struct.pack(">I", len(payload)) + name + payload + struct.pack(">I", zlib.crc32(name + payload) & 0xffffffff)

def png() -> bytes:
    rows=[]
    for y in range(16):
        line=bytearray(b"\0")
        for x in range(16):
            bright=(x-7.5)**2+(y-7.5)**2<44
            line.extend((245, 195 if x%2 else 140, 40, 255) if bright else (0, 0, 0, 0))
        rows.append(bytes(line))
    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB",16,16,8,6,0,0,0))
        + chunk(b"IDAT", zlib.compress(b"".join(rows),9))
        + chunk(b"IEND", b"")
    )

def wav(path: Path) -> None:
    rate=8000
    values=[]
    samples=1600
    for i in range(samples):
        fade=min(1,i/80,(samples-1-i)/330)
        n=round(9000*max(0,fade)*math.sin(2*math.pi*660*i/rate))
        values.append(struct.pack("<h",n))
    with wave.open(str(path),"wb") as f:
        f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate)
        f.writeframes(b"".join(values))

if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--directory",type=Path,default=Path("dist"))
    args=parser.parse_args()
    args.directory.mkdir(parents=True,exist_ok=True)
    image=args.directory/"icone-original.png"
    sound=args.directory/"efeito-original.wav"
    image.write_bytes(png());wav(sound)
    print("Created",image,sound)
