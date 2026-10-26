#!/usr/bin/env python3
"""Genere le jeu de caracteres multicolore et le monde (multi-ecrans) a partir de l'ASCII art.

Usage : tilegen.py assets/tiles.txt assets/world.txt --charset src/charset.asm \
            --map src/map_data.asm [--preview apercu.png]
"""
import argparse
import os
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

# Bases de caracteres pour chaque tuile (2x2 = 4 caracteres)
# Tuiles 0..7 dans 0..31, Tuiles 8..23 dans 168..231
TILE_CHAR_BASES = [
    0, 4, 8, 12, 16, 20, 24, 28,
    168, 184, 188, 192, 196, 200, 204, 208, 212, 216, 220, 224, 228
]

# Couleurs d'arriere-plan et multicolores par zone regionale (C64) :
# 0: Cimetiere, 1: Montagne de la Mort, 2: Plaines, 3: Cote
ZONE_BG = [
    COLORS["dgrey"],   # Zone 0: Cimetiere (11 - terre sombre du cimetiere)
    COLORS["brown"],   # Zone 1: Montagne (9 - roche volcanique)
    COLORS["lgreen"],  # Zone 2: Plaines (13 - prairie verdoyante de la plaine)
    COLORS["lgreen"],  # Zone 3: Cote (13 - continuite naturelle vers les cotes et lacs)
]
ZONE_MC1 = [
    COLORS["black"],   # Zone 0: Cimetiere (0 - ombres et gravures tombales)
    COLORS["orange"],  # Zone 1: Montagne (8 - teinte rocheuse)
    COLORS["orange"],  # Zone 2: Plaines (8 - ecorce des arbres et failles)
    COLORS["orange"],  # Zone 3: Cote (8 - ecorce et failles rocheuses)
]
ZONE_MC2 = [
    COLORS["white"],   # Zone 0: Cimetiere (1 - pierre blanche des tombes)
    COLORS["white"],   # Zone 1: Montagne (1 - reflets rocheux)
    COLORS["white"],   # Zone 2: Plaines (1 - ecume de l'eau, coeur fleurs)
    COLORS["white"],   # Zone 3: Cote (1 - ecume et embruns marins)
]

# Couleurs de tuiles propres (Color RAM, 0-7) par zone :
# Tuiles : 0:grass, 1:tufts, 2:flowers, 3:tree, 4:water, 5:wall, 6:sand, 7:cave, 8:grave,
#          9:bridge_h, 10:bridge_v, 11:wall_pass, 12:wall_bomb, 13:rock
ZONE_TILE_COLORS = [
    # Zone 0: Cimetiere (fond dgrey, MC1 black, MC2 white)
    [COLORS["black"], COLORS["white"], COLORS["white"], COLORS["black"],
     COLORS["blue"], COLORS["black"], COLORS["black"], COLORS["black"], COLORS["white"],
     COLORS["black"], COLORS["black"], COLORS["black"], COLORS["black"], COLORS["black"]],

    # Zone 1: Montagne de la Mort (fond brown, MC1 orange, MC2 white)
    [COLORS["red"], COLORS["yellow"], COLORS["yellow"], COLORS["red"],
     COLORS["blue"], COLORS["red"], COLORS["yellow"], COLORS["black"], COLORS["white"],
     COLORS["black"], COLORS["black"], COLORS["red"], COLORS["red"], COLORS["red"]],

    # Zone 2: Plaines (fond lgreen, MC1 orange, MC2 white)
    [COLORS["green"], COLORS["green"], COLORS["red"], COLORS["green"],
     COLORS["blue"], COLORS["black"], COLORS["yellow"], COLORS["black"], COLORS["white"],
     COLORS["black"], COLORS["black"], COLORS["black"], COLORS["black"], COLORS["black"]],

    # Zone 3: Cote (fond orange, MC1 brown, MC2 white)
    [COLORS["green"], COLORS["green"], COLORS["red"], COLORS["green"],
     COLORS["blue"], COLORS["black"], COLORS["yellow"], COLORS["black"], COLORS["white"],
     COLORS["black"], COLORS["black"], COLORS["black"], COLORS["black"], COLORS["black"]],
]

ZONE_DUNGEON_TILE_COLORS = [
    COLORS["black"],   # 0: grass (sol noir donjon)
    COLORS["dgrey"],   # 1: tufts (détail sol)
    COLORS["red"],     # 2: flowers (torches / feu)
    COLORS["cyan"],    # 3: tree (bloc / pilier cyan Level 1)
    COLORS["blue"],    # 4: water (eau)
    COLORS["cyan"],    # 5: wall (murs de pierre cyan)
    COLORS["grey"],    # 6: sand (dalle centrale / passerelle)
    COLORS["black"],   # 7: cave (escalier / fosse)
    COLORS["black"],   # 8: grave
    COLORS["black"],   # 9: bridge_h
    COLORS["black"],   # 10: bridge_v
    COLORS["cyan"],    # 11: wall_pass
    COLORS["cyan"],    # 12: wall_bomb
    COLORS["cyan"],    # 13: rock
]

DEFAULT_ROOM_ZONES = [
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
    0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 3, 3,
    0, 0, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3,
    0, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3,
    3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3,
    3, 3, 3, 3, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3,
]


def get_room_zones(total_rooms=128):
    rom_path = "zelda.nes"
    if os.path.exists(rom_path):
        try:
            with open(rom_path, "rb") as f:
                rom = f.read()
            if len(rom) >= 0x18410 + 128:
                t1 = rom[0x18410:0x18410+128]
                zones = []
                for y in range(8):
                    for x in range(16):
                        idx = y * 16 + x
                        outer = t1[idx] & 3
                        if (x in [0, 1] and y in [2, 3, 4]) or (x == 0 and y == 5):
                            z = 0  # 7 salles authentiques du cimetiere et son passage
                        elif y in [0, 1]:
                            z = 1  # 32 salles de la Montagne de la Mort
                        elif outer == 2:
                            z = 2  # Plaines et forets du centre
                        else:
                            z = 3  # Cotes, lacs et rivieres
                        zones.append(z)
                return zones
        except Exception:
            pass
    return list(DEFAULT_ROOM_ZONES[:total_rooms])


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
    "'": [0x18, 0x18, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00],
    ',': [0x00, 0x00, 0x00, 0x00, 0x00, 0x18, 0x18, 0x08],
    '?': [0x3C, 0x66, 0x0C, 0x18, 0x18, 0x00, 0x18, 0x00],
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
    '\\': [0x40, 0x60, 0x30, 0x18, 0x0C, 0x06, 0x03, 0x00],
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
    '@': [0x3C, 0x42, 0x99, 0xA5, 0xA1, 0x99, 0x42, 0x3C],  # © Copyright

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

    # Caracteres graphiques pour jauges de debug (codes 107..115)
    107: [0x00, 0x3F, 0x30, 0x30, 0x30, 0x30, 0x3F, 0x00],  # Jauge bord gauche [
    108: [0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00],  # Jauge segment plein
    109: [0x00, 0xFF, 0xF0, 0xF0, 0xF0, 0xF0, 0xFF, 0x00],  # Jauge demi-segment
    110: [0x00, 0xFF, 0x00, 0x00, 0x00, 0x00, 0xFF, 0x00],  # Jauge segment vide
    111: [0x00, 0xFC, 0x0C, 0x0C, 0x0C, 0x0C, 0xFC, 0x00],  # Jauge bord droit ]
    112: [0x00, 0x00, 0x00, 0x18, 0x18, 0x00, 0x00, 0x00],  # Point median
    113: [0x00, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00],  # Ligne haute
    114: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0x00],  # Ligne basse
    115: [0x00, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0x00],  # Ligne mediane separation

    # Icones et graphismes Intro Zelda 1 (codes 116..127)
    116: [0x00, 0x18, 0x3C, 0x7E, 0xDB, 0xFF, 0x00, 0x00],  # Triforce sacree
    117: [0x18, 0x18, 0x18, 0x7E, 0x18, 0x18, 0x18, 0x00],  # Epee magique
    118: [0x7E, 0xFF, 0xBD, 0xBD, 0x7E, 0x3C, 0x18, 0x00],  # Bouclier magique
    119: [0x06, 0x0F, 0x1B, 0x33, 0x66, 0xCC, 0x98, 0x30],  # Flute / Recorder
    120: [0x00, 0xFF, 0xDB, 0xDB, 0xFF, 0xDB, 0x00, 0x00],  # Radeau (Raft)
    121: [0xC3, 0xFF, 0xC3, 0xC3, 0xFF, 0xC3, 0xC3, 0x00],  # Echelle (Ladder)
    122: [0x3C, 0x66, 0xC3, 0xC3, 0xC3, 0x66, 0x3C, 0x00],  # Bracelet de force
    123: [0x18, 0x18, 0x3C, 0x7E, 0x7E, 0x7E, 0x3C, 0x00],  # Potion de vie
    124: [0x24, 0x48, 0x90, 0x24, 0x48, 0x90, 0x24, 0x48],  # Cascade eau phase 0
    125: [0x48, 0x90, 0x24, 0x48, 0x90, 0x24, 0x48, 0x90],  # Cascade eau phase 1
    126: [0x90, 0x24, 0x48, 0x90, 0x24, 0x48, 0x90, 0x24],  # Cascade eau phase 2
    127: [0x00, 0x00, 0x42, 0xA5, 0x5A, 0x24, 0xFF, 0x7E],  # Ecume de cascade

    128: [0xFF, 0xDB, 0xFF, 0xED, 0xFF, 0xDB, 0xFF, 0xBD],
    129: [0x3C, 0x7E, 0xFF, 0xDB, 0xFF, 0xED, 0xFF, 0xDB],
    130: [0x0F, 0x1F, 0x3F, 0x7F, 0x7F, 0x3F, 0x1F, 0x0F],
    131: [0xF0, 0xF8, 0xFC, 0xFE, 0xFE, 0xFC, 0xF8, 0xF0],
    132: [0x18, 0x3C, 0x7E, 0x3C, 0x7E, 0xFF, 0x7E, 0xFF],
    133: [0x3C, 0x7E, 0xFF, 0x18, 0x18, 0x18, 0x3C, 0x00],
    134: [0x00, 0x44, 0xAA, 0x11, 0x00, 0x22, 0x55, 0x88],
    135: [0x42, 0xA5, 0xDB, 0xFF, 0x7E, 0x3C, 0x18, 0x00],
    136: [0xFF, 0xFF, 0x03, 0x07, 0x0E, 0x1C, 0x38, 0x70],
    137: [0xFF, 0xFF, 0xE0, 0xC0, 0x80, 0x00, 0x00, 0x00],
    138: [0xE0, 0xC0, 0x80, 0x00, 0x00, 0x00, 0xFF, 0xFF],
    139: [0x00, 0x00, 0x01, 0x03, 0x07, 0x0E, 0xFF, 0xFF],
    140: [0xFF, 0xFF, 0xE0, 0xE0, 0xE0, 0xE0, 0xFF, 0xFF],
    141: [0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0xFE, 0xFE],
    142: [0xE0, 0xE0, 0xE0, 0xE0, 0xE0, 0xE0, 0xFF, 0xFF],
    143: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF],
    144: [0xE0, 0xE0, 0xE0, 0xE0, 0xE0, 0xE0, 0xE0, 0xE0],
    145: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00],
    146: [0xE0, 0xE0, 0xE0, 0xE0, 0xE0, 0xE0, 0xFF, 0xFF],
    147: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF],
    148: [0xFF, 0xFF, 0xE0, 0xE0, 0xE0, 0xE0, 0xE0, 0xE0],
    149: [0xFC, 0xFE, 0x07, 0x03, 0x03, 0x03, 0x03, 0x03],
    150: [0xE0, 0xE0, 0xE0, 0xE0, 0xE0, 0xE0, 0xFF, 0xFF],
    151: [0x03, 0x03, 0x03, 0x03, 0x03, 0x07, 0xFE, 0xFC],
    152: [0x07, 0x0F, 0x1E, 0x3C, 0x78, 0xF0, 0xFF, 0xFF],
    153: [0xE0, 0xF0, 0x78, 0x3C, 0x1E, 0x0F, 0xFF, 0xFF],
    154: [0xE0, 0xE0, 0xE0, 0xE0, 0xE0, 0xE0, 0xE0, 0xE0],
    155: [0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07],
    156: [0x00, 0x01, 0x03, 0x07, 0x0F, 0x1F, 0x3F, 0x7F],
    157: [0x00, 0x80, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC, 0xFE],
    158: [0x07, 0x0F, 0x1E, 0x3C, 0x78, 0xF0, 0xFF, 0xFF],
    159: [0xE0, 0xF0, 0x78, 0x3C, 0x1E, 0x0F, 0xFF, 0xFF],

    # Bordures et enroulements de parchemin (codes 160..167)
    160: [0x07, 0x1F, 0x3F, 0x7E, 0xFC, 0xF8, 0xF8, 0xF8],
    161: [0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00],
    162: [0xE0, 0xF8, 0xFC, 0x7E, 0x3F, 0x1F, 0x1F, 0x1F],
    163: [0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18],
    164: [0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18],
    165: [0xF8, 0xF8, 0xF8, 0xFC, 0x7E, 0x3F, 0x1F, 0x07],
    166: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF],
    167: [0x1F, 0x1F, 0x1F, 0x3F, 0x7E, 0xFC, 0xF8, 0xE0],

    # Icones supplementaires d'objets et tresors officiels (codes 172..182)
    172: [0x10, 0x38, 0x54, 0x10, 0x10, 0x10, 0x54, 0x38],  # Fleche (Arrow)
    173: [0x10, 0x38, 0x7C, 0xC6, 0x82, 0x82, 0xC6, 0x7C],  # Bague (Ring)
    174: [0x54, 0x38, 0xFE, 0x38, 0x54, 0x10, 0x10, 0x10],  # Baguette magique (Rod)
    175: [0x7E, 0x81, 0xBD, 0xBD, 0xBD, 0xBD, 0x81, 0x7E],  # Livre de magie (Book)
    176: [0x3C, 0x7E, 0xE7, 0xE7, 0xE7, 0xE7, 0x7E, 0x3C],  # Carte (Map)
    177: [0x3C, 0x5A, 0x99, 0xBD, 0xBD, 0x99, 0x5A, 0x3C],  # Boussole (Compass)
    178: [0x7E, 0xDB, 0xFF, 0xFF, 0x7E, 0x3C, 0x18, 0x7E],  # Receptacle de coeur (Heart Container)
    179: [0x81, 0xC3, 0x7E, 0x3C, 0x3C, 0x7E, 0xC3, 0x81],  # Fee (Fairy)
    180: [0x7E, 0xDB, 0x5A, 0x18, 0x18, 0x5A, 0xDB, 0x7E],  # Horloge (Clock)
    181: [0x1C, 0x3E, 0x7F, 0x7F, 0x3E, 0x1C, 0x36, 0x36],  # Nourriture / Appat (Food)
    182: [0xFF, 0x81, 0xBD, 0xA5, 0x99, 0x81, 0x81, 0xFF],  # Lettre royale (Letter)
}


def write_charset(path, tiles, src):
    # Dictionnaire complet de 256 caracteres (8 octets chacun)
    chars = {i: [0] * 8 for i in range(256)}

    # Caracteres des tuiles de la carte
    for i, t in enumerate(tiles):
        base = TILE_CHAR_BASES[i]
        for q, (label, c0, r0) in enumerate((("HG", 0, 0), ("HD", 4, 0),
                                             ("BG", 0, 8), ("BD", 4, 8))):
            chars[base + q] = char_bytes(t["rows"], c0, r0)

    # Caracteres ASCII et icones HUD
    for k, rows in FONT_8X8.items():
        code = ord(k) if isinstance(k, str) else k
        chars[code] = rows

    with open(path, "w", encoding="utf-8") as f:
        f.write(f"; GENERE par tools/tilegen.py depuis {src} - ne pas editer a la main.\n")
        f.write("; Jeu de caracteres : tuiles (0..31, 168..), police ASCII (32..95), icones HUD (96..106).\n")
        f.write("charset:\n")
        for i in range(256):
            b = ", ".join(f"%{v:08b}" for v in chars[i])
            f.write(f"        !byte {b}   ; char {i}\n")


def compress_room_rle(room):
    flat = [t for row in room for t in row]
    rle = []
    j = 0
    while j < len(flat):
        run = 1
        while j + run < len(flat) and flat[j + run] == flat[j]:
            run += 1
        t = flat[j]
        rem = run
        while rem > 0:
            c = min(rem, 15)
            byte = ((c - 1) << 4) | (t & 0x0F)
            rle.append(byte)
            rem -= c
        j += run
    rle.append(0xFF)  # marqueur de fin de salle ($FF)
    return rle


def write_tiles_data(path, cfg, tiles, rooms_x, rooms_y):
    with open(path, "w", encoding="utf-8") as f:
        f.write("; GENERE par tools/tilegen.py - Donnees de tuiles et decompressor resident\n")
        f.write(f"MAP_W           = {MAP_W}\nMAP_H           = {MAP_H}\n")
        f.write(f"MAP_BG_COLOR    = {cfg['bg']}\nMAP_MC1_COLOR   = {cfg['mc1']}\n")
        f.write(f"MAP_MC2_COLOR   = {cfg['mc2']}\n\n")
        f.write(f"WORLD_ROOMS_X   = {rooms_x}\nWORLD_ROOMS_Y   = {rooms_y}\n")
        f.write("WORLD_ROOMS_CNT = 128\n\n")
        f.write("TILE_SOLID      = %00000001\n\n")
        for i, t in enumerate(tiles):
            f.write(f"TILE_{ident(t['name'])} = {i}\n")

        f.write("\n; Constantes des tuiles de donjon (16 tuiles 16x16)\n")
        f.write("TILE_DUNG_FLOOR         = 0     ; Sol en dalle\n")
        f.write("TILE_DUNG_WALL_TOP      = 1     ; Mur superieur\n")
        f.write("TILE_DUNG_WALL_BOT      = 2     ; Mur inferieur\n")
        f.write("TILE_DUNG_WALL_LEFT     = 3     ; Mur gauche\n")
        f.write("TILE_DUNG_WALL_RIGHT    = 4     ; Mur droit\n")
        f.write("TILE_DUNG_BLOCK         = 5     ; Bloc diamant 3D\n")
        f.write("TILE_DUNG_STATUE        = 6     ; Statue dragon\n")
        f.write("TILE_DUNG_STAIRS        = 7     ; Escalier secret\n")
        f.write("TILE_DUNG_CORNER_TL     = 8     ; Biseau 45 haut-gauche\n")
        f.write("TILE_DUNG_CORNER_TR     = 9     ; Biseau 45 haut-droit\n")
        f.write("TILE_DUNG_CORNER_BL     = 10    ; Biseau 45 bas-gauche\n")
        f.write("TILE_DUNG_CORNER_BR     = 11    ; Biseau 45 bas-droit\n")
        f.write("TILE_DUNG_DOOR_OPEN     = 12    ; Porte ouverte (passage)\n")
        f.write("TILE_DUNG_DOOR_LOCKED   = 13    ; Porte verrouillee avec serrure\n")
        f.write("TILE_DUNG_DOOR_SHUTTER  = 14    ; Volet / herse metallique\n")
        f.write("TILE_DUNG_DOOR_BOMB     = 15    ; Mur fissure a la bombe\n\n")

        f.write("ow_tile_char_base:\n        !byte 0, 4, 8, 12, 16, 20, 24, 28, 168, 184, 188, 192, 196, 200, 0, 0\n")
        f.write("dung_tile_char_base:\n        !byte 0, 4, 8, 12, 16, 20, 24, 28, 168, 172, 176, 180, 184, 188, 192, 196\n")

        f.write("\n; Caractere de base de chaque tuile (2x2 = 4 caracteres)\ntile_char_base:\n        !byte ")
        bases = [TILE_CHAR_BASES[i] if i < len(tiles) else 0 for i in range(16)]
        f.write(", ".join(str(v) for v in bases) + "\n")

        f.write("\n; Couleurs de chaque zone regionale (+8 pour mode multicolore)\n")
        for z in range(4):
            cols = []
            for i in range(16):
                if i < len(tiles):
                    cols.append(ZONE_TILE_COLORS[z][i] + 8)
                else:
                    cols.append(0)
            f.write(f"zone{z}_tile_color:\n        !byte " + ", ".join(str(c) for c in cols) + "\n")

        # Couleurs de donjon
        dungeon_cols = []
        for i in range(16):
            if i < len(ZONE_DUNGEON_TILE_COLORS):
                dungeon_cols.append(ZONE_DUNGEON_TILE_COLORS[i] + 8)
            elif i < len(tiles):
                dungeon_cols.append(tiles[i]["color"] + 8)
            else:
                dungeon_cols.append(0)
        f.write("zone_dungeon_tile_color:\n        !byte " + ", ".join(str(c) for c in dungeon_cols) + "\n\n")

        f.write("zone_color_lo:\n        !byte <zone0_tile_color, <zone1_tile_color, <zone2_tile_color, <zone3_tile_color\n")
        f.write("zone_color_hi:\n        !byte >zone0_tile_color, >zone1_tile_color, >zone2_tile_color, >zone3_tile_color\n\n")

        f.write("zone_bg_color:\n        !byte " + ", ".join(str(c) for c in ZONE_BG) + "\n")
        f.write("zone_mc1_color:\n        !byte " + ", ".join(str(c) for c in ZONE_MC1) + "\n")
        f.write("zone_mc2_color:\n        !byte " + ", ".join(str(c) for c in ZONE_MC2) + "\n\n")

        f.write("; Tampon de couleur des tuiles de la salle active\nactive_tile_color:\n        !fill 16, 0\ntile_color = active_tile_color\n\n")

        f.write("ow_tile_flags:\n        !byte 0, 0, 0, TILE_SOLID, TILE_SOLID, TILE_SOLID, 0, 0, TILE_SOLID, 0, 0, 0, TILE_SOLID, TILE_SOLID, 0, 0\n")
        f.write("dung_tile_flags:\n        !byte 0, TILE_SOLID, TILE_SOLID, TILE_SOLID, TILE_SOLID, TILE_SOLID, TILE_SOLID, 0, TILE_SOLID, TILE_SOLID, TILE_SOLID, TILE_SOLID, 0, TILE_SOLID, TILE_SOLID, TILE_SOLID\n\n")

        f.write("; drapeaux de chaque tuile (bit 0 = solide)\ntile_flags:\n        !byte ")
        flags = [("TILE_SOLID" if t["solid"] else "0") for t in tiles]
        while len(flags) < 16:
            flags.append("0")
        f.write(", ".join(flags) + "\n")

        f.write("\n; table ty * MAP_W\ntile_row_offset:\n        !byte ")
        f.write(", ".join(str(ty * MAP_W) for ty in range(MAP_H)) + "\n")

        f.write("\n; Pointeur vers la table de rangées dynamique de la carte active ($A006)\n")
        f.write("world_row_offset = map_row_offset\n")

        f.write("\n; Les tampons room_buf et target_room_buf sont alloues en BSS resident dans main.asm\n\n")

        f.write("; ---------------------------------------------------------------------------\n")
        f.write("; Decompression RLE compact (1-octet) de la salle pointee par ZP_SRC dans room_buf\n")
        f.write("; Format : bit 7..4 = (run - 1) [0..14 -> 1..15 tuiles], bit 3..0 = tile (0..15)\n")
        f.write("; Fin de salle : $FF\n")
        f.write("; ---------------------------------------------------------------------------\n")
        f.write("decompress_room_main:\n")
        f.write("        ldy #0\n        ldx #0\n.drm_loop:\n")
        f.write("        lda (ZP_SRC),y\n        cmp #$ff\n        beq .drm_done\n        iny\n")
        f.write("        pha\n        lsr\n        lsr\n        lsr\n        lsr\n        clc\n        adc #1\n        sta ZP_TMP\n")
        f.write("        pla\n        and #$0f\n.drm_put:\n")
        f.write("        sta room_buf,x\n        inx\n        dec ZP_TMP\n        bne .drm_put\n")
        f.write("        cpx #200\n        bcc .drm_loop\n.drm_done:\n        rts\n\n")
        f.write("; ---------------------------------------------------------------------------\n")
        f.write("; Decompression RLE compact (1-octet) dans target_room_buf\n")
        f.write("; ---------------------------------------------------------------------------\n")
        f.write("decompress_room_target:\n")
        f.write("        ldy #0\n        ldx #0\n.drt_loop:\n")
        f.write("        lda (ZP_SRC),y\n        cmp #$ff\n        beq .drt_done\n        iny\n")
        f.write("        pha\n        lsr\n        lsr\n        lsr\n        lsr\n        clc\n        adc #1\n        sta ZP_TMP\n")
        f.write("        pla\n        and #$0f\n.drt_put:\n")
        f.write("        sta target_room_buf,x\n        inx\n        dec ZP_TMP\n        bne .drt_put\n")
        f.write("        cpx #200\n        bcc .drt_loop\n.drt_done:\n        rts\n\n")


def write_ow_chunk(path, chunk_id, cfg, tiles, rooms, rooms_x, rooms_y, src_tiles, src_world, enemy_lines):
    room_zones = get_room_zones(len(rooms))
    r_start = chunk_id * 32
    r_end = min(r_start + 32, len(rooms))

    # Deduplicate enemy formations for this chunk
    empty_line = "!byte TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0"
    uniq_formations = [empty_line]
    formation_map = {empty_line: 0}
    enemy_indices = [0] * 128
    for r in range(r_start, r_end):
        line = enemy_lines[r] if r < len(enemy_lines) else empty_line
        if line not in formation_map:
            formation_map[line] = len(uniq_formations)
            uniq_formations.append(line)
        enemy_indices[r] = formation_map[line]

    with open(path, "w", encoding="utf-8") as f:
        f.write(f"; GENERE par tools/tilegen.py - Chunk Overworld {chunk_id} (Salles {r_start}..{r_end-1})\n")
        f.write("!cpu 6510\n!source \"src/enemy_types.inc\"\n* = $c000\n\n")
        f.write(f"map_rooms_w:    !byte {rooms_x}\n")
        f.write(f"map_rooms_h:    !byte {rooms_y}\n")
        f.write(f"map_rooms_cnt:  !byte {len(rooms)}\n")
        f.write(f"map_bg_col:     !byte {cfg['bg']}\n")
        f.write(f"map_mc1_col:    !byte {cfg['mc1']}\n")
        f.write(f"map_mc2_col:    !byte {cfg['mc2']}\n\n")

        row_offsets = [ry * rooms_x for ry in range(rooms_y)]
        while len(row_offsets) < 8:
            row_offsets.append(0)
        f.write("; Table des offsets ry * map_rooms_w (8 octets : $C006..$C00D)\nmap_row_offset:\n        !byte ")
        f.write(", ".join(str(v) for v in row_offsets[:8]) + "\n")
        f.write("; Pointeur vers le jeu de caracteres de la carte ($C00E..$C00F)\nmap_charset_ptr:\n        !word overworld_charset\n")
        f.write("; Pointeur vers la table des ennemis ($C010..$C011)\nmap_enemies_ptr_hdr:\n        !word map_enemies\n        !fill 4, 0\n\n")

        f.write("; Tables des pointeurs (128 octets LO : $C016..$C095 / 128 octets HI : $C096..$C115)\n")
        lo_ptrs = [f"<room_{i:02d}" if r_start <= i < r_end else f"<room_{r_start:02d}" for i in range(128)]
        hi_ptrs = [f">room_{i:02d}" if r_start <= i < r_end else f">room_{r_start:02d}" for i in range(128)]
        f.write("room_tbl_lo:\n")
        for i in range(0, 128, 16):
            f.write("        !byte " + ", ".join(lo_ptrs[i:i+16]) + "\n")
        f.write("room_tbl_hi:\n")
        for i in range(0, 128, 16):
            f.write("        !byte " + ", ".join(hi_ptrs[i:i+16]) + "\n")
        f.write("\n")

        while len(room_zones) < 128:
            room_zones.append(0)
        f.write("; Table des zones régionales par salle (128 octets : $C116..$C195)\nroom_zone_palette:\n        !byte ")
        f.write(", ".join(str(z) for z in room_zones[:128]) + "\n\n")

        f.write("; Index de formation d'ennemis par salle (128 octets : $C196..$C215)\nroom_enemy_idx:\n")
        for i in range(0, 128, 16):
            f.write("        !byte " + ", ".join(str(v) for v in enemy_indices[i:i+16]) + "\n")
        f.write("\n")

        for i in range(r_start, r_end):
            room = rooms[i]
            rx = i % rooms_x
            ry = i // rooms_x
            rle = compress_room_rle(room)
            f.write(f"; Salle ({rx}, {ry}) - RLE compact ({len(rle)} octets)\nroom_{i:02d}:\n")
            for chunk_start in range(0, len(rle), 16):
                chunk = rle[chunk_start:chunk_start + 16]
                f.write("        !byte " + ", ".join(str(v) for v in chunk) + "\n")

        f.write("\n; 512 octets de caracteres Overworld\noverworld_charset:\n")
        chars = {i: [0] * 8 for i in range(256)}
        for i, t in enumerate(tiles):
            base = TILE_CHAR_BASES[i]
            for q, (label, c0, r0) in enumerate((("HG", 0, 0), ("HD", 4, 0),
                                                 ("BG", 0, 8), ("BD", 4, 8))):
                chars[base + q] = char_bytes(t["rows"], c0, r0)

        f.write("; Chars 0..31 (Tuiles 0..7 : 256 octets)\n")
        for c in range(32):
            f.write("        !byte " + ", ".join(str(v) for v in chars[c]) + f"   ; char {c}\n")

        f.write("; Chars 168..199 (Tuiles 8..12 : 256 octets)\n")
        for c in range(168, 200):
            f.write("        !byte " + ", ".join(str(v) for v in chars[c]) + f"   ; char {c}\n")

        f.write("; Chars 200..207 (Tuiles 13..14 : 64 octets dont rocher escargot)\n")
        for c in range(200, 208):
            f.write("        !byte " + ", ".join(str(v) for v in chars[c]) + f"   ; char {c}\n")

        f.write(f"\n; Formations d'ennemis dédupliquées ({len(uniq_formations)} formations x 24 octets)\nmap_enemies:\n")
        for idx, line in enumerate(uniq_formations):
            f.write(f"        ; Formation {idx}\n        {line}\n")


def write_map(path, cfg, tiles, rooms, rooms_x, rooms_y, src_tiles, src_world, overlay_mode=False):
    enemy_lines = []
    en_inc_path = os.path.join(os.path.dirname(path), "map_overworld_enemies.inc")
    if os.path.exists(en_inc_path):
        with open(en_inc_path, encoding="utf-8") as ef:
            enemy_lines = [l.strip() for l in ef if l.strip().startswith("!byte")]
    if overlay_mode:
        out_dir = os.path.dirname(path)
        for chunk_id in range(4):
            chunk_path = os.path.join(out_dir, f"ow{chunk_id}.asm")
            write_ow_chunk(chunk_path, chunk_id, cfg, tiles, rooms, rooms_x, rooms_y, src_tiles, src_world, enemy_lines)
        write_ow_chunk(path, 3, cfg, tiles, rooms, rooms_x, rooms_y, src_tiles, src_world, enemy_lines)
        return
    write_ow_chunk(path, 3, cfg, tiles, rooms, rooms_x, rooms_y, src_tiles, src_world, enemy_lines)



def preview(path, cfg, tiles, grid, rooms_x=16, rooms_y=8, scale=2):
    room_zones = get_room_zones(rooms_x * rooms_y)
    pix = []
    for y_tile, row in enumerate(grid):
        ry = y_tile // MAP_H
        for ar in range(ART_H):
            line = []
            for x_tile, t in enumerate(row):
                rx = x_tile // MAP_W
                room_idx = ry * rooms_x + rx
                zone = room_zones[room_idx] if room_idx < len(room_zones) else 2
                bg_col = ZONE_BG[zone]
                mc1_col = ZONE_MC1[zone]
                mc2_col = ZONE_MC2[zone]
                tile_col = ZONE_TILE_COLORS[zone][t] if t < len(ZONE_TILE_COLORS[zone]) else tiles[t]["color"]
                cols = [PALETTE[bg_col], PALETTE[mc1_col], PALETTE[mc2_col], PALETTE[tile_col]]
                tile = tiles[t]
                for ch in tile["rows"][ar]:
                    line.extend([cols[PIX[ch]]] * (2 * scale))
            pix.extend([line] * scale)
    write_png(path, pix)


def write_underworld_map(path, cfg, tiles, rooms, rooms_x, rooms_y, src_tiles, src_world):
    with open(path, "w", encoding="utf-8") as f:
        f.write(f"; GENERE par tools/tilegen.py depuis {src_tiles} et {src_world} - ne pas editer.\n")
        f.write("!cpu 6510\n* = $a000\n\n")
        f.write(f"map_rooms_w:    !byte {rooms_x}\n")
        f.write(f"map_rooms_h:    !byte {rooms_y}\n")
        f.write(f"map_rooms_cnt:  !byte {len(rooms)}\n")
        # Couleurs donjon : Fond noir (0), MC1 cyan (3), MC2 gris (12)
        f.write("map_bg_col:     !byte 0   ; noir\n")
        f.write("map_mc1_col:    !byte 3   ; cyan donjon Niveau 1\n")
        f.write("map_mc2_col:    !byte 12  ; gris\n\n")

        row_offsets = [ry * rooms_x for ry in range(rooms_y)]
        while len(row_offsets) < 16:
            row_offsets.append(0)
        f.write("; Table des offsets ry * map_rooms_w (16 octets : $A006..$A015)\nmap_row_offset:\n        !byte ")
        f.write(", ".join(str(v) for v in row_offsets) + "\n\n")

        f.write("; Tables des pointeurs (128 octets LO : $A016..$A095 / 128 octets HI : $A096..$A115)\n")
        f.write("room_tbl_lo:\n        !byte ")
        f.write(", ".join(f"<u_room_{i:02d}" for i in range(len(rooms))))
        if len(rooms) < 128:
            f.write("\n        !fill " + str(128 - len(rooms)) + ", 0\n")
        else:
            f.write("\n")

        f.write("room_tbl_hi:\n        !byte ")
        f.write(", ".join(f">u_room_{i:02d}" for i in range(len(rooms))))
        if len(rooms) < 128:
            f.write("\n        !fill " + str(128 - len(rooms)) + ", 0\n\n")
        else:
            f.write("\n\n")

        # Table des zones par salle ($A116..$A195 - 128 octets à 0 pour donjons)
        f.write("; Table des palettes régionales (128 octets à 0 pour les donjons : $A116..$A195)\nroom_zone_palette:\n        !fill 128, 0\n\n")

        for i, room in enumerate(rooms):
            rx = i % rooms_x
            ry = i // rooms_x
            rle = compress_room_rle(room)
            f.write(f"; Salle Souterraine ({rx}, {ry}) - RLE compact ({len(rle)} octets)\nu_room_{i:02d}:\n")
            for chunk_start in range(0, len(rle), 16):
                chunk = rle[chunk_start:chunk_start + 16]
                f.write("        !byte " + ", ".join(str(v) for v in chunk) + "\n")

        f.write("\n* = $b800\n!source \"src/map_underworld_enemies.inc\"\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("tiles")
    ap.add_argument("world")
    ap.add_argument("--charset", required=True)
    ap.add_argument("--map-out", required=True, dest="map_out")
    ap.add_argument("--tiles-out", default=None, dest="tiles_out")
    ap.add_argument("--underworld", default=None)
    ap.add_argument("--underworld-out", default=None, dest="underworld_out")
    ap.add_argument("--preview")
    a = ap.parse_args()
    cfg, tiles = parse_tiles(a.tiles)
    rooms, rx, ry, grid = parse_world(a.world, tiles)
    write_charset(a.charset, tiles, a.tiles)

    if a.tiles_out:
        write_tiles_data(a.tiles_out, cfg, tiles, rx, ry)
        write_map(a.map_out, cfg, tiles, rooms, rx, ry, a.tiles, a.world, overlay_mode=True)
    else:
        write_map(a.map_out, cfg, tiles, rooms, rx, ry, a.tiles, a.world, overlay_mode=False)

    if a.underworld and a.underworld_out:
        u_rooms, u_rx, u_ry, _ = parse_world(a.underworld, tiles)
        write_underworld_map(a.underworld_out, cfg, tiles, u_rooms, u_rx, u_ry, a.tiles, a.underworld)
        print(f"Underworld : {u_rx}x{u_ry} ecrans ({len(u_rooms)} salles souterraines)")

    if a.preview:
        preview(a.preview, cfg, tiles, grid, rooms_x=rx, rooms_y=ry)
    print(f"{len(tiles)} tuiles, monde {rx}x{ry} ecrans ({len(rooms)} salles)")


if __name__ == "__main__":
    main()
