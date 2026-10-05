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
MAP_W, MAP_H = 20, 10
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


FONT_8X8 = {
    ' ': [0, 0, 0, 0, 0, 0, 0, 0],
    '!': [0x18, 0x18, 0x18, 0x18, 0x18, 0x00, 0x18, 0x00],
    '(': [0x0C, 0x18, 0x30, 0x30, 0x30, 0x18, 0x0C, 0x00],
    ')': [0x30, 0x18, 0x0C, 0x0C, 0x0C, 0x18, 0x30, 0x00],
    '*': [0x00, 0x66, 0x3C, 0xFF, 0x3C, 0x66, 0x00, 0x00],
    '+': [0x00, 0x18, 0x18, 0x7E, 0x18, 0x18, 0x00, 0x00],
    '-': [0x00, 0x00, 0x00, 0x7E, 0x00, 0x00, 0x00, 0x00],
    '.': [0x00, 0x00, 0x00, 0x00, 0x00, 0x18, 0x18, 0x00],
    '/': [0x03, 0x06, 0x0C, 0x18, 0x30, 0x60, 0x40, 0x00],
    ':': [0x00, 0x18, 0x18, 0x00, 0x18, 0x18, 0x00, 0x00],
    '<': [0x0C, 0x18, 0x30, 0x60, 0x30, 0x18, 0x0C, 0x00],
    '=': [0x00, 0x7E, 0x00, 0x7E, 0x00, 0x00, 0x00, 0x00],
    '>': [0x30, 0x18, 0x0C, 0x06, 0x0C, 0x18, 0x30, 0x00],
    '[': [0x3C, 0x30, 0x30, 0x30, 0x30, 0x30, 0x3C, 0x00],
    ']': [0x3C, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x3C, 0x00],
    '_': [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0x00],
    '|': [0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18],
    '&': [0x18, 0x24, 0x24, 0x18, 0x2A, 0x44, 0x3A, 0x00],

    # Chiffres 0..9
    '0': [0x3C, 0x66, 0x6E, 0x76, 0x66, 0x66, 0x3C, 0x00],
    '1': [0x18, 0x38, 0x18, 0x18, 0x18, 0x18, 0x7E, 0x00],
    '2': [0x3C, 0x66, 0x06, 0x0C, 0x18, 0x30, 0x7E, 0x00],
    '3': [0x3C, 0x66, 0x06, 0x1C, 0x06, 0x66, 0x3C, 0x00],
    '4': [0x0C, 0x1C, 0x34, 0x64, 0x7E, 0x04, 0x04, 0x00],
    '5': [0x7E, 0x60, 0x7C, 0x06, 0x06, 0x66, 0x3C, 0x00],
    '6': [0x3C, 0x66, 0x60, 0x7C, 0x66, 0x66, 0x3C, 0x00],
    '7': [0x7E, 0x06, 0x0C, 0x18, 0x30, 0x30, 0x30, 0x00],
    '8': [0x3C, 0x66, 0x66, 0x3C, 0x66, 0x66, 0x3C, 0x00],
    '9': [0x3C, 0x66, 0x66, 0x3E, 0x06, 0x66, 0x3C, 0x00],

    # Lettres A..Z
    'A': [0x18, 0x3C, 0x66, 0x66, 0x7E, 0x66, 0x66, 0x00],
    'B': [0x7C, 0x66, 0x66, 0x7C, 0x66, 0x66, 0x7C, 0x00],
    'C': [0x3C, 0x66, 0x60, 0x60, 0x60, 0x66, 0x3C, 0x00],
    'D': [0x78, 0x6C, 0x66, 0x66, 0x66, 0x6C, 0x78, 0x00],
    'E': [0x7E, 0x60, 0x60, 0x7C, 0x60, 0x60, 0x7E, 0x00],
    'F': [0x7E, 0x60, 0x60, 0x7C, 0x60, 0x60, 0x60, 0x00],
    'G': [0x3C, 0x66, 0x60, 0x6E, 0x66, 0x66, 0x3A, 0x00],
    'H': [0x66, 0x66, 0x66, 0x7E, 0x66, 0x66, 0x66, 0x00],
    'I': [0x3C, 0x18, 0x18, 0x18, 0x18, 0x18, 0x3C, 0x00],
    'J': [0x0E, 0x06, 0x06, 0x06, 0x06, 0x66, 0x3C, 0x00],
    'K': [0x66, 0x6C, 0x78, 0x70, 0x78, 0x6C, 0x66, 0x00],
    'L': [0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x7E, 0x00],
    'M': [0x63, 0x77, 0x7F, 0x6B, 0x63, 0x63, 0x63, 0x00],
    'N': [0x66, 0x76, 0x7E, 0x7E, 0x6E, 0x66, 0x66, 0x00],
    'O': [0x3C, 0x66, 0x66, 0x66, 0x66, 0x66, 0x3C, 0x00],
    'P': [0x7C, 0x66, 0x66, 0x7C, 0x60, 0x60, 0x60, 0x00],
    'Q': [0x3C, 0x66, 0x66, 0x66, 0x6A, 0x6C, 0x36, 0x00],
    'R': [0x7C, 0x66, 0x66, 0x7C, 0x78, 0x6C, 0x66, 0x00],
    'S': [0x3C, 0x66, 0x60, 0x3C, 0x06, 0x66, 0x3C, 0x00],
    'T': [0x7E, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x00],
    'U': [0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x3C, 0x00],
    'V': [0x66, 0x66, 0x66, 0x66, 0x66, 0x3C, 0x18, 0x00],
    'W': [0x63, 0x63, 0x63, 0x6B, 0x7F, 0x77, 0x63, 0x00],
    'X': [0x66, 0x66, 0x3C, 0x18, 0x3C, 0x66, 0x66, 0x00],
    'Y': [0x66, 0x66, 0x66, 0x3C, 0x18, 0x18, 0x18, 0x00],
    'Z': [0x7E, 0x06, 0x0C, 0x18, 0x30, 0x60, 0x7E, 0x00],

    # Icones Zelda HUD (codes 96..106)
    96: [0x00, 0x66, 0xFF, 0xFF, 0x7E, 0x3C, 0x18, 0x00],   # Coeur plein ♥
    97: [0x00, 0x66, 0x99, 0x81, 0x42, 0x24, 0x18, 0x00],   # Coeur vide ♡
    98: [0x18, 0x3C, 0x7E, 0xFF, 0x7E, 0x3C, 0x18, 0x00],   # Rubis ◆
    99: [0x38, 0x44, 0x38, 0x10, 0x18, 0x10, 0x18, 0x00],   # Clef
    100: [0x0C, 0x08, 0x38, 0x7C, 0xFE, 0xFE, 0x7C, 0x38],  # Bombe
    101: [0x7C, 0x60, 0x70, 0x38, 0x1C, 0x0E, 0x04, 0x00],  # Boomerang
    102: [0x10, 0x18, 0x14, 0x12, 0x14, 0x18, 0x10, 0x00],  # Arc
    103: [0x10, 0x38, 0x38, 0x10, 0x7C, 0x7C, 0x7C, 0x7C],  # Bougie
    104: [0x00, 0x00, 0x00, 0x18, 0x18, 0x00, 0x00, 0x00],  # Salle minimap point
    105: [0x00, 0x7E, 0x7E, 0x7E, 0x7E, 0x7E, 0x7E, 0x00],  # Salle active (bloc plein)
    106: [0x00, 0x7E, 0x42, 0x42, 0x42, 0x42, 0x7E, 0x00],  # Salle visitee (cadre)
}


def write_charset(path, tiles, src):
    # Dictionnaire complet de 256 caracteres (8 octets chacun)
    chars = {i: [0] * 8 for i in range(256)}

    # Caracteres 0..31 : tuiles de la carte
    for i, t in enumerate(tiles):
        for q, (label, c0, r0) in enumerate((("HG", 0, 0), ("HD", 4, 0),
                                             ("BG", 0, 8), ("BD", 4, 8))):
            chars[i * 4 + q] = char_bytes(t["rows"], c0, r0)

    # Caracteres ASCII et icones HUD
    for k, rows in FONT_8X8.items():
        code = ord(k) if isinstance(k, str) else k
        chars[code] = rows

    with open(path, "w", encoding="utf-8") as f:
        f.write(f"; GENERE par tools/tilegen.py depuis {src} - ne pas editer a la main.\n")
        f.write("; Jeu de caracteres : tuiles (0..31), police ASCII (32..95), icones HUD (96..106).\n")
        f.write("charset:\n")
        for i in range(256):
            b = ", ".join(f"%{v:08b}" for v in chars[i])
            f.write(f"        !byte {b}   ; char {i}\n")


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

        f.write("\n; table ty * MAP_W\ntile_row_offset:\n        !byte ")
        f.write(", ".join(str(ty * MAP_W) for ty in range(MAP_H)) + "\n")

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
