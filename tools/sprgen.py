#!/usr/bin/env python3
"""Convertit un fichier d'images ASCII (assets/*.txt) en sprites C64 multicolores.

Usage : sprgen.py assets/link.txt -o src/sprites.asm [--preview apercu.png]

Sortie : un bloc de 64 octets par image, etiquete sprite_<prefixe>_<nom>.
Les blocs sont consecutifs : le premier doit etre aligne sur 64 octets.
"""
import argparse
import os
import struct
import sys
import zlib

ART_W, ART_H = 8, 16          # taille du dessin (pixels multicolores)
SPR_W, SPR_H = 12, 21         # taille d'un sprite multicolore
PAD_X, PAD_Y = 2, 2           # position du dessin dans le sprite
CODES = {".": 0, "s": 1, "g": 2, "b": 3}   # 00 transp., 01 MC1, 10 propre, 11 MC2

# Apercu uniquement (palette C64 "pepto") : doit refleter src/player.asm
PREVIEW = {0: (0x35, 0x28, 0x79),          # fond bleu C64
           1: (0xB8, 0x69, 0x62),          # peau  = rouge clair ($0a)
           2: (0x58, 0x8D, 0x43),          # vert  = vert ($05)
           3: (0x6F, 0x4F, 0x25)}          # marron = marron ($09)


def parse(path):
    frames = {}                 # nom -> rows | ("mirror", autre)
    order = []
    current = None
    with open(path, encoding="utf-8") as f:
        for n, raw in enumerate(f, 1):
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            if line.startswith("["):
                head, _, rest = line.partition("]")
                current = head[1:].strip()
                order.append(current)
                rest = rest.split()
                frames[current] = ("mirror", rest[1]) if rest[:1] == ["mirror"] else []
                continue
            if current is None or isinstance(frames[current], tuple):
                sys.exit(f"{path}:{n}: ligne hors image : {line!r}")
            if len(line) != ART_W or any(c not in CODES for c in line):
                sys.exit(f"{path}:{n}: ligne invalide (attendu {ART_W} car. parmi "
                         f"{''.join(CODES)}) : {line!r}")
            frames[current].append(line)
    for name in order:
        v = frames[name]
        if isinstance(v, tuple):
            if v[1] not in frames or isinstance(frames[v[1]], tuple):
                sys.exit(f"[{name}] : mirror vers une image inconnue ({v[1]})")
            frames[name] = [r[::-1] for r in frames[v[1]]]
        elif len(v) != ART_H:
            sys.exit(f"[{name}] : {len(v)} lignes, {ART_H} attendues")
    return order, frames


def to_grid(rows):
    grid = [[0] * SPR_W for _ in range(SPR_H)]
    for y, row in enumerate(rows):
        for x, c in enumerate(row):
            grid[y + PAD_Y][x + PAD_X] = CODES[c]
    return grid


def encode(grid):
    out = []
    for row in grid:
        bits = "".join(f"{p:02b}" for p in row)
        out.append([int(bits[i:i + 8], 2) for i in range(0, 24, 8)])
    return out


def write_png(path, pixels):
    h, w = len(pixels), len(pixels[0])
    raw = b"".join(b"\x00" + bytes(c for px in row for c in px) for row in pixels)

    def chunk(tag, data):
        body = tag + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body))

    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)))
        f.write(chunk(b"IDAT", zlib.compress(raw, 9)))
        f.write(chunk(b"IEND", b""))


def preview(path, order, grids, scale=14):
    gap = 2
    width = len(order) * (SPR_W + gap) + gap
    cells = [[PREVIEW[0]] * width for _ in range(SPR_H + 2 * gap)]
    for i, name in enumerate(order):
        for y in range(SPR_H):
            for x in range(SPR_W):
                cells[y + gap][gap + i * (SPR_W + gap) + x] = PREVIEW[grids[name][y][x]]
    pix = []
    for row in cells:
        wide = [px for px in row for _ in range(2 * scale)]   # pixel MC = 2x1
        pix.extend([wide] * scale)
    write_png(path, pix)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("source")
    ap.add_argument("-o", "--output", required=True)
    ap.add_argument("--preview")
    a = ap.parse_args()

    order, frames = parse(a.source)
    grids = {n: to_grid(frames[n]) for n in order}
    prefix = os.path.splitext(os.path.basename(a.source))[0]

    with open(a.output, "w", encoding="utf-8") as f:
        f.write(f"; GENERE par tools/sprgen.py depuis {a.source} - ne pas editer a la main.\n")
        f.write("; Sprites multicolores 12x21, 64 octets chacun, blocs consecutifs.\n")
        f.write("; Le premier doit etre aligne sur 64 octets (voir main.asm).\n")
        for name in order:
            f.write(f"sprite_{prefix}_{name}:\n")
            for b0, b1, b2 in encode(grids[name]):
                f.write(f"        !byte %{b0:08b}, %{b1:08b}, %{b2:08b}\n")
            f.write("        !byte 0                         ; remplissage a 64 octets\n")
    if a.preview:
        preview(a.preview, order, grids)


if __name__ == "__main__":
    main()
