#!/usr/bin/env python3
"""Genere le jeu de caracteres multicolore et le monde (multi-ecrans) a partir de l'ASCII art.

Usage : tilegen.py assets/tiles.txt assets/world.txt --charset src/charset.asm \
            --map src/map_data.asm [--preview apercu.png]
"""
import argparse
import re
import sys

from sprgen import write_png      # meme dossier

ART_W, ART_H = 8, 16
MAP_W, MAP_H = 20, 12
MAX_TILES = 64
PIX = {".": 0, "1": 1, "2": 2, "c": 3}       # 00 fond, 01 MC1, 10 MC2, 11 propre

COLOR_NAMES = ("black white red cyan purple green blue yellow orange brown "
               "lred dgrey grey lgreen lblue lgrey").split()
COLORS = {n: i for i, n in enumerate(COLOR_NAMES)}
PALETTE = [(0x00, 0x00, 0x00), (0xFF, 0xFF, 0xFF), (0x68, 0x37, 0x2B), (0x70, 0xA4, 0xB2),
           (0x6F, 0x3D, 0x86), (0x58, 0x8D, 0x43), (0x35, 0x28, 0x79), (0xB8, 0xC7, 0x6F),
           (0x6F, 0x4F, 0x25), (0x43, 0x39, 0x00), (0x9A, 0x67, 0x59), (0x44, 0x44, 0x44),
           (0x6C, 0x6C, 0x6C), (0x9A, 0xD2, 0x84), (0x6C, 0x5E, 0xB5), (0x95, 0x95, 0x95)]


def die(msg):
    sys.exit(f"erreur : {msg}")


def parse_tiles(path):
    cfg, tiles, cur = {}, [], None
    with open(path, encoding="utf-8") as f:
        for n, raw in enumerate(f, 1):
            line = raw.strip()
            if not line or line.startswith(";"):
                continue
            where = f"{path}:{n}"
            if line.startswith("["):
                head, _, rest = line.partition("]")
                parts = rest.split()
                if len(parts) < 2:
                    die(f"{where}: attendu [nom] symbole couleur [solid]")
                if parts[1] not in COLORS or COLORS[parts[1]] > 7:
                    die(f"{where}: couleur propre invalide (0-7 seulement) : {parts[1]}")
                cur = {"name": head[1:].strip(), "symbol": parts[0], "color": COLORS[parts[1]],
                       "solid": "solid" in parts[2:], "rows": []}
                tiles.append(cur)
            elif ":" in line:
                key, _, val = line.partition(":")
                key, val = key.strip(), val.strip()
                if key not in ("bg", "mc1", "mc2") or val not in COLORS:
                    die(f"{where}: reglage inconnu : {line}")
                cfg[key] = COLORS[val]
            else:
                if cur is None:
                    die(f"{where}: ligne hors tuile : {line}")
                if len(line) != ART_W or any(c not in PIX for c in line):
                    die(f"{where}: ligne invalide (8 car. parmi {''.join(PIX)}) : {line}")
                cur["rows"].append(line)
    for k in ("bg", "mc1", "mc2"):
        if k not in cfg:
            die(f"reglage manquant : {k}")
    if not 1 <= len(tiles) <= MAX_TILES:
        die(f"{len(tiles)} tuiles (1 a {MAX_TILES} attendues)")
    symbols = [t["symbol"] for t in tiles]
    if len(set(symbols)) != len(symbols):
        die("symboles de tuiles en double")
    for t in tiles:
        if len(t["rows"]) != ART_H:
            die(f"[{t['name']}] : {len(t['rows'])} lignes, {ART_H} attendues")
    return cfg, tiles


def parse_world(path, tiles):
    index = {t["symbol"]: i for i, t in enumerate(tiles)}
    raw_lines = []
    with open(path, encoding="utf-8") as f:
        for n, raw in enumerate(f, 1):
            line = raw.strip()
            if not line or line.startswith(";"):
                continue
            line = "".join(line.split())
            for c in line:
                if c not in index:
                    die(f"{path}:{n}: symbole inconnu {c!r}")
            raw_lines.append([index[c] for c in line])
    if not raw_lines:
        die(f"{path}: fichier vide")
    w = len(raw_lines[0])
    h = len(raw_lines)
    if w % MAP_W != 0:
        die(f"{path}: largeur {w} non multiple de {MAP_W}")
    if h % MAP_H != 0:
        die(f"{path}: hauteur {h} non multiple de {MAP_H}")
    for i, r in enumerate(raw_lines):
        if len(r) != w:
            die(f"{path}: ligne {i+1} de longueur {len(r)}, attendu {w}")

    rooms_x = w // MAP_W
    rooms_y = h // MAP_H
    rooms = []
    for ry in range(rooms_y):
        for rx in range(rooms_x):
            room = []
            for y in range(MAP_H):
                row = raw_lines[ry * MAP_H + y][rx * MAP_W:(rx + 1) * MAP_W]
                room.append(row)
            rooms.append(room)
    return rooms, rooms_x, rooms_y, raw_lines


def char_bytes(rows, col0, row0):
    """8 octets d'un caractere multicolore (4 pixels x 2 bits par ligne)."""
    out = []
    for r in range(row0, row0 + 8):
        v = 0
        for c in range(col0, col0 + 4):
            v = (v << 2) | PIX[rows[r][c]]
        out.append(v)
    return out


def ident(name):
    return re.sub(r"\W", "_", name).upper()


def write_charset(path, tiles, src):
    with open(path, "w", encoding="utf-8") as f:
        f.write(f"; GENERE par tools/tilegen.py depuis {src} - ne pas editer a la main.\n")
        f.write("; Jeu de caracteres multicolore : tuile N = caracteres 4N..4N+3 (HG, HD, BG, BD).\n")
        f.write("charset:\n")
        for i, t in enumerate(tiles):
            for q, (label, c0, r0) in enumerate((("HG", 0, 0), ("HD", 4, 0),
                                                 ("BG", 0, 8), ("BD", 4, 8))):
                b = ", ".join(f"%{v:08b}" for v in char_bytes(t["rows"], c0, r0))
                f.write(f"        !byte {b}   ; {i}:{t['name']} {label}\n")


def write_map(path, cfg, tiles, rooms, rooms_x, rooms_y, src_tiles, src_world):
    with open(path, "w", encoding="utf-8") as f:
        f.write(f"; GENERE par tools/tilegen.py depuis {src_tiles} et {src_world} - ne pas editer.\n")
        f.write(f"MAP_W           = {MAP_W}\nMAP_H           = {MAP_H}\n")
        f.write(f"MAP_BG_COLOR    = {cfg['bg']}\nMAP_MC1_COLOR   = {cfg['mc1']}\n")
        f.write(f"MAP_MC2_COLOR   = {cfg['mc2']}\n\n")
        f.write(f"WORLD_ROOMS_X   = {rooms_x}\nWORLD_ROOMS_Y   = {rooms_y}\n")
        f.write(f"WORLD_ROOMS_CNT = {len(rooms)}\n\n")
        f.write("TILE_SOLID      = %00000001\n\n")
        for i, t in enumerate(tiles):
            f.write(f"TILE_{ident(t['name'])} = {i}\n")
        f.write("\n; couleur de chaque tuile (+8 = caractere multicolore)\ntile_color:\n")
        for t in tiles:
            f.write(f"        !byte {t['color'] + 8}   ; {t['name']}\n")
        f.write("\n; drapeaux de chaque tuile (bit 0 = solide)\ntile_flags:\n")
        for t in tiles:
            f.write(f"        !byte {'TILE_SOLID' if t['solid'] else '0'}   ; {t['name']}\n")

        f.write("\n; table ry * WORLD_ROOMS_X\nworld_row_offset:\n        !byte ")
        f.write(", ".join(str(ry * rooms_x) for ry in range(rooms_y)) + "\n")

        f.write("\n; tables des pointeurs de chaque salle (ordre Y puis X)\nroom_tbl_lo:\n        !byte ")
        f.write(", ".join(f"<room_{i:02d}" for i in range(len(rooms))) + "\n")
        f.write("room_tbl_hi:\n        !byte ")
        f.write(", ".join(f">room_{i:02d}" for i in range(len(rooms))) + "\n")

        for i, room in enumerate(rooms):
            rx = i % rooms_x
            ry = i // rooms_x
            f.write(f"\n; Salle ({rx}, {ry}) - {MAP_W}x{MAP_H} tuiles = {MAP_W * MAP_H} octets\nroom_{i:02d}:\n")
            for row in room:
                f.write("        !byte " + ", ".join(str(v) for v in row) + "\n")


def preview(path, cfg, tiles, grid, scale=2):
    pal = [PALETTE[cfg["bg"]], PALETTE[cfg["mc1"]], PALETTE[cfg["mc2"]]]
    pix = []
    for row in grid:
        for ar in range(ART_H):
            line = []
            for t in row:
                tile = tiles[t]
                cols = pal + [PALETTE[tile["color"]]]
                for ch in tile["rows"][ar]:
                    line.extend([cols[PIX[ch]]] * (2 * scale))
            pix.extend([line] * scale)
    write_png(path, pix)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("tiles")
    ap.add_argument("world")
    ap.add_argument("--charset", required=True)
    ap.add_argument("--map-out", required=True, dest="map_out")
    ap.add_argument("--preview")
    a = ap.parse_args()
    cfg, tiles = parse_tiles(a.tiles)
    rooms, rx, ry, grid = parse_world(a.world, tiles)
    write_charset(a.charset, tiles, a.tiles)
    write_map(a.map_out, cfg, tiles, rooms, rx, ry, a.tiles, a.world)
    if a.preview:
        preview(a.preview, cfg, tiles, grid)
    print(f"{len(tiles)} tuiles, monde {rx}x{ry} ecrans ({len(rooms)} salles)")


if __name__ == "__main__":
    main()
