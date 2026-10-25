#!/usr/bin/env python3
"""
tools/build_dungeons.py - Génère les fichiers assembleur autonomes pour les 9 Donjons de Zelda C64.

Chaque donjon est généré dans son propre fichier source ('src/dung<N>.asm') :
  - Découpé et scellé de manière étanche (aucune ouverture vers d'autres donjons ou le vide).
  - Table de pointeurs de salles (128 entrées : les salles hors-donjon pointent vers une salle scellée).
  - 16 tuiles de donjon authentiques NES (Dalle, Murs, Biseaux 45°, Diamant 3D, Statue dragon, Portes).
  - Charset de 512 octets embarqué dans le fichier et chargé dynamiquement en RAM VIC ($2000 et $2540).
  - Pointeur MAP_CHARSET_PTR à $A00E pour une permutation instantanée et transparente.
  - Table d'apparition des monstres authentiques et boss officiel à map_enemies.
  - Palette et décors authentiques de chaque niveau.
  - Compilé en 'build/dung<N>.dat' chargé dynamiquement à $A000 par le C64.
"""

import os
import sys

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.join(BASE_DIR, "tools"))

from tilegen import compress_room_rle, char_bytes
from render_dungeon1_full import TILES_ART, decode_nes_level1

UNDERWORLD_TXT = os.path.join(BASE_DIR, "assets", "underworld.txt")
SRC_DIR = os.path.join(BASE_DIR, "src")
BLD_DIR = os.path.join(BASE_DIR, "build")

# Données des 9 Donjons officiels
DUNGEON_METADATA = {
    1: {
        'name': 'Eagle (Aigle)',
        'ent': 0x73, 'boss': 0x35, 'tri': 0x36,
        'boss_type': 'TYPE_AQUAMENTUS', 'boss_hp': 6,
        'mc1': 3, 'wall': 11, 'is_79': False,
        'boss_coords': (14, 4)
    },
    2: {
        'name': 'Moon (Lune)',
        'ent': 0x7d, 'boss': 0x0e, 'tri': 0x0d,
        'boss_type': 'TYPE_DODONGO', 'boss_hp': 8,
        'mc1': 6, 'wall': 14, 'is_79': False,
        'boss_coords': (14, 4)
    },
    3: {
        'name': 'Manji',
        'ent': 0x7c, 'boss': 0x4d, 'tri': 0x3d,
        'boss_type': 'TYPE_MANHANDLA', 'boss_hp': 8,
        'mc1': 5, 'wall': 13, 'is_79': False,
        'boss_coords': (10, 4)
    },
    4: {
        'name': 'Steer (Gnou)',
        'ent': 0x71, 'boss': 0x13, 'tri': 0x03,
        'boss_type': 'TYPE_GLEEOK', 'boss_hp': 8,
        'mc1': 15, 'wall': 23, 'is_79': False,
        'boss_coords': (10, 3)
    },
    5: {
        'name': 'Lizard (Lézard)',
        'ent': 0x76, 'boss': 0x24, 'tri': 0x14,
        'boss_type': 'TYPE_DIGDOGGER', 'boss_hp': 8,
        'mc1': 2, 'wall': 10, 'is_79': False,
        'boss_coords': (10, 4)
    },
    6: {
        'name': 'Dragon',
        'ent': 0x79, 'boss': 0x1c, 'tri': 0x0c,
        'boss_type': 'TYPE_GOHMA_RED', 'boss_hp': 2,
        'mc1': 8, 'wall': 16, 'is_79': False,
        'boss_coords': (10, 2)
    },
    7: {
        'name': 'Demon (Démon)',
        'ent': 0x79, 'boss': 0x2a, 'tri': 0x2b,
        'boss_type': 'TYPE_AQUAMENTUS', 'boss_hp': 8,
        'mc1': 5, 'wall': 13, 'is_79': True,
        'boss_coords': (14, 4)
    },
    8: {
        'name': 'Lion',
        'ent': 0x7e, 'boss': 0x3c, 'tri': 0x2c,
        'boss_type': 'TYPE_DODONGO', 'boss_hp': 8,
        'mc1': 14, 'wall': 22, 'is_79': True,
        'boss_coords': (14, 4)
    },
    9: {
        'name': 'Death Mountain (Montagne de la Mort)',
        'ent': 0x76, 'boss': 0x42, 'tri': 0x32,
        'boss_type': 'TYPE_GANON', 'boss_hp': 16,
        'mc1': 2, 'wall': 10, 'is_79': True,
        'boss_coords': (10, 4)
    },
}

# Liste authentique des 17 salles du Donjon 1 (Aigle)
DUNGEON_1_ROOMS = {0x22, 0x23, 0x33, 0x35, 0x36, 0x41, 0x42, 0x43, 0x44, 0x45, 0x52, 0x53, 0x54, 0x63, 0x72, 0x73, 0x74}

DUNGEON_ROOMS = {
    1: DUNGEON_1_ROOMS,
    2: {0x7d, 0x6d, 0x6e, 0x6f, 0x5e, 0x5f, 0x4e, 0x4f, 0x3e, 0x3f, 0x2e, 0x2f, 0x1e, 0x1f, 0x0d, 0x0e},
    3: {0x7b, 0x7c, 0x6a, 0x6b, 0x6c, 0x5a, 0x5b, 0x5c, 0x5d, 0x4a, 0x4b, 0x4c, 0x4d, 0x3a, 0x3b, 0x3c, 0x3d},
    4: {0x70, 0x71, 0x60, 0x61, 0x62, 0x50, 0x51, 0x40, 0x41, 0x30, 0x31, 0x32, 0x20, 0x21, 0x10, 0x11, 0x12, 0x13, 0x00, 0x01, 0x02, 0x03, 0x04},
    5: {0x76, 0x77, 0x65, 0x66, 0x67, 0x55, 0x56, 0x57, 0x45, 0x46, 0x47, 0x35, 0x36, 0x37, 0x24, 0x25, 0x26, 0x14, 0x15, 0x16},
    6: {0x78, 0x79, 0x7a, 0x68, 0x69, 0x6a, 0x58, 0x59, 0x5a, 0x48, 0x49, 0x4a, 0x38, 0x39, 0x3a, 0x28, 0x29, 0x2a, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x08, 0x09, 0x0a, 0x0b, 0x0c},
    7: {0x78, 0x79, 0x7a, 0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x58, 0x59, 0x5a, 0x5b, 0x5c, 0x5d, 0x48, 0x49, 0x4a, 0x38, 0x39, 0x3a, 0x28, 0x29, 0x2a, 0x2b, 0x18, 0x19, 0x1a},
    8: {0x7c, 0x7d, 0x7e, 0x7f, 0x6d, 0x6e, 0x6f, 0x5c, 0x5d, 0x5e, 0x5f, 0x4c, 0x4d, 0x4e, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f, 0x2c, 0x2d},
    9: {0x75, 0x76, 0x77, 0x63, 0x64, 0x65, 0x66, 0x53, 0x54, 0x55, 0x56, 0x42, 0x43, 0x44, 0x45, 0x46, 0x32, 0x33, 0x34, 0x35, 0x23, 0x24},
}

def generate_dungeon_charset_bytes():
    """Génère les 512 octets de caractères VIC-II pour les 16 tuiles de donjon."""
    chars_0_31 = []
    for t in range(8):
        art = TILES_ART[t]
        chars_0_31.extend(char_bytes(art, 0, 0))
        chars_0_31.extend(char_bytes(art, 4, 0))
        chars_0_31.extend(char_bytes(art, 0, 8))
        chars_0_31.extend(char_bytes(art, 4, 8))

    chars_168_199 = []
    for t in range(8, 16):
        art = TILES_ART[t]
        chars_168_199.extend(char_bytes(art, 0, 0))
        chars_168_199.extend(char_bytes(art, 4, 0))
        chars_168_199.extend(char_bytes(art, 0, 8))
        chars_168_199.extend(char_bytes(art, 4, 8))

    return chars_0_31, chars_168_199

def build_level1_enemies_table():
    """Table authentique d'ennemis pour le Niveau 1 (Aigle)."""
    empty = "TYPE_NONE         ,  0,  0"
    tbl = {}
    for r in range(128):
        tbl[r] = [empty] * 8

    # Boss Aquamentus (0x35)
    tbl[0x35][0] = "TYPE_AQUAMENTUS   , 14,  4"

    # Red Goriyas (0x44 et 0x23)
    tbl[0x44] = [
        "TYPE_GORIYA_RED   ,  8,  3",
        "TYPE_GORIYA_RED   , 12,  3",
        "TYPE_GORIYA_RED   , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x23] = [
        "TYPE_GORIYA_RED   ,  8,  3",
        "TYPE_GORIYA_RED   , 12,  3",
        "TYPE_GORIYA_RED   , 10,  5",
        empty, empty, empty, empty, empty
    ]

    # Stalfos (0x74, 0x63, 0x53, 0x33)
    tbl[0x74] = [
        "TYPE_STALFOS      ,  6,  3",
        "TYPE_STALFOS      , 14,  3",
        "TYPE_STALFOS      , 10,  4",
        "TYPE_STALFOS      ,  6,  6",
        "TYPE_STALFOS      , 14,  6",
        empty, empty, empty
    ]
    tbl[0x63] = [
        "TYPE_STALFOS      ,  7,  3",
        "TYPE_STALFOS      , 13,  3",
        "TYPE_STALFOS      , 10,  6",
        empty, empty, empty, empty, empty
    ]
    tbl[0x53] = [
        "TYPE_STALFOS      ,  6,  3",
        "TYPE_STALFOS      , 14,  3",
        "TYPE_STALFOS      , 10,  4",
        "TYPE_STALFOS      ,  6,  6",
        "TYPE_STALFOS      , 14,  6",
        empty, empty, empty
    ]
    tbl[0x33] = [
        "TYPE_STALFOS      ,  6,  3",
        "TYPE_STALFOS      , 14,  3",
        "TYPE_STALFOS      , 10,  4",
        "TYPE_STALFOS      ,  6,  6",
        "TYPE_STALFOS      , 14,  6",
        empty, empty, empty
    ]

    # Keese (0x72, 0x52, 0x54, 0x22)
    tbl[0x72] = [
        "TYPE_KEESE_RED    ,  6,  2",
        "TYPE_KEESE_RED    , 14,  2",
        "TYPE_KEESE_RED    , 10,  4",
        "TYPE_KEESE_RED    ,  6,  6",
        "TYPE_KEESE_RED    , 14,  6",
        empty, empty, empty
    ]
    tbl[0x52] = [
        "TYPE_KEESE_RED    ,  6,  2",
        "TYPE_KEESE_RED    , 14,  2",
        "TYPE_KEESE_RED    , 10,  4",
        "TYPE_KEESE_RED    ,  6,  6",
        "TYPE_KEESE_RED    , 14,  6",
        empty, empty, empty
    ]
    tbl[0x54] = [
        "TYPE_KEESE_RED    ,  6,  2",
        "TYPE_KEESE_RED    , 14,  2",
        "TYPE_KEESE_RED    , 10,  4",
        "TYPE_KEESE_RED    ,  6,  6",
        "TYPE_KEESE_RED    , 14,  6",
        empty, empty, empty
    ]
    tbl[0x22] = [
        "TYPE_KEESE_RED    ,  6,  2",
        "TYPE_KEESE_RED    , 14,  2",
        "TYPE_KEESE_RED    ,  6,  6",
        "TYPE_KEESE_RED    , 14,  6",
        empty, empty, empty, empty
    ]

    # Gels / Spikes (0x42, 0x43)
    tbl[0x42] = [
        "TYPE_GEL          ,  8,  3",
        "TYPE_GEL          , 12,  3",
        "TYPE_GEL          , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x43] = [
        "TYPE_GEL          ,  8,  3",
        "TYPE_GEL          , 12,  3",
        "TYPE_GEL          , 10,  5",
        empty, empty, empty, empty, empty
    ]

    # Map room (0x45)
    tbl[0x45] = [
        "TYPE_KEESE_RED    ,  7,  2",
        "TYPE_KEESE_RED    , 13,  2",
        empty, empty, empty, empty, empty, empty
    ]

    return tbl

def build_level2_enemies_table():
    """Table authentique d'ennemis pour le Niveau 2 (Lune)."""
    empty = "TYPE_NONE         ,  0,  0"
    tbl = {r: [empty] * 8 for r in range(128)}
    # Boss Dodongo (0x0E)
    tbl[0x0E][0] = "TYPE_DODONGO      , 14,  4"
    # Blue Goriyas (0x4F - Magical Boomerang)
    tbl[0x4F] = [
        "TYPE_GORIYA_BLUE  ,  8,  3",
        "TYPE_GORIYA_BLUE  , 12,  3",
        "TYPE_GORIYA_BLUE  , 10,  5",
        empty, empty, empty, empty, empty
    ]
    # Red Goriyas (0x3E, 0x1F)
    tbl[0x3E] = [
        "TYPE_GORIYA_RED   ,  8,  3",
        "TYPE_GORIYA_RED   , 12,  3",
        "TYPE_GORIYA_RED   , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x1F] = [
        "TYPE_GORIYA_RED   ,  8,  3",
        "TYPE_GORIYA_RED   , 12,  3",
        "TYPE_GORIYA_RED   , 10,  5",
        empty, empty, empty, empty, empty
    ]
    # Stalfos (0x1E, 0x5E)
    tbl[0x1E] = [
        "TYPE_STALFOS      ,  6,  3",
        "TYPE_STALFOS      , 14,  3",
        "TYPE_STALFOS      ,  6,  6",
        "TYPE_STALFOS      , 14,  6",
        empty, empty, empty, empty
    ]
    tbl[0x5E] = [
        "TYPE_STALFOS      ,  6,  3",
        "TYPE_STALFOS      , 14,  3",
        "TYPE_STALFOS      , 10,  4",
        "TYPE_STALFOS      , 10,  6",
        empty, empty, empty, empty
    ]
    # Ropes (0x6D, 0x6E, 0x4E, 0x2E)
    tbl[0x6D] = [
        "TYPE_ROPE         ,  6,  3",
        "TYPE_ROPE         , 14,  3",
        "TYPE_ROPE         , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x6E] = [
        "TYPE_ROPE         ,  7,  3",
        "TYPE_ROPE         , 13,  3",
        "TYPE_ROPE         , 10,  6",
        empty, empty, empty, empty, empty
    ]
    tbl[0x4E] = [
        "TYPE_ROPE         ,  6,  3",
        "TYPE_ROPE         , 14,  3",
        "TYPE_ROPE         , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x2E] = [
        "TYPE_ROPE         ,  6,  3",
        "TYPE_ROPE         , 14,  3",
        "TYPE_ROPE         ,  8,  5",
        "TYPE_ROPE         , 12,  5",
        empty, empty, empty, empty
    ]
    # Gels (0x6F, 0x5F, 0x2F)
    tbl[0x6F] = [
        "TYPE_GEL          ,  8,  3",
        "TYPE_GEL          , 12,  3",
        "TYPE_GEL          , 10,  5",
        "TYPE_GEL          ,  8,  6",
        empty, empty, empty, empty
    ]
    tbl[0x5F] = [
        "TYPE_GEL          ,  7,  3",
        "TYPE_GEL          , 13,  3",
        "TYPE_GEL          , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x2F] = [
        "TYPE_GEL          ,  8,  3",
        "TYPE_GEL          , 12,  3",
        "TYPE_GEL          , 10,  5",
        empty, empty, empty, empty, empty
    ]
    # Keese (0x3F)
    tbl[0x3F] = [
        "TYPE_KEESE_BLUE   ,  6,  2",
        "TYPE_KEESE_BLUE   , 14,  2",
        "TYPE_KEESE_BLUE   ,  6,  6",
        "TYPE_KEESE_BLUE   , 14,  6",
        empty, empty, empty, empty
    ]
    return tbl

def build_level3_enemies_table():
    """Table authentique d'ennemis pour le Niveau 3 (Manji)."""
    empty = "TYPE_NONE         ,  0,  0"
    tbl = {r: [empty] * 8 for r in range(128)}
    # Boss Manhandla (0x4D)
    tbl[0x4D][0] = "TYPE_MANHANDLA    , 10,  4"
    # Darknuts Blue (0x3A, 0x6A)
    tbl[0x3A] = [
        "TYPE_DARKNUT_BLUE ,  6,  3",
        "TYPE_DARKNUT_BLUE , 14,  3",
        "TYPE_DARKNUT_BLUE ,  6,  6",
        "TYPE_DARKNUT_BLUE , 14,  6",
        empty, empty, empty, empty
    ]
    tbl[0x6A] = [
        "TYPE_DARKNUT_BLUE ,  6,  3",
        "TYPE_DARKNUT_BLUE , 10,  3",
        "TYPE_DARKNUT_BLUE ,  6,  6",
        empty, empty, empty, empty, empty
    ]
    # Darknuts Red (0x3B, 0x3C, 0x5C, 0x5B, 0x6C)
    tbl[0x3B] = [
        "TYPE_DARKNUT_RED  ,  6,  3",
        "TYPE_DARKNUT_RED  , 14,  3",
        "TYPE_DARKNUT_RED  ,  6,  6",
        "TYPE_DARKNUT_RED  , 14,  6",
        empty, empty, empty, empty
    ]
    tbl[0x3C] = [
        "TYPE_DARKNUT_RED  ,  7,  3",
        "TYPE_DARKNUT_RED  , 13,  3",
        "TYPE_DARKNUT_RED  , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x5C] = [
        "TYPE_DARKNUT_RED  ,  6,  3",
        "TYPE_DARKNUT_RED  , 14,  3",
        "TYPE_DARKNUT_RED  , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x5B] = [
        "TYPE_DARKNUT_RED  ,  7,  3",
        "TYPE_DARKNUT_RED  , 13,  3",
        "TYPE_DARKNUT_RED  , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x6C] = [
        "TYPE_DARKNUT_RED  ,  6,  3",
        "TYPE_DARKNUT_RED  , 14,  3",
        "TYPE_DARKNUT_RED  , 10,  5",
        empty, empty, empty, empty, empty
    ]
    # Red Goriyas (0x4B, 0x6B, 0x7B)
    tbl[0x4B] = [
        "TYPE_GORIYA_RED   ,  8,  3",
        "TYPE_GORIYA_RED   , 12,  3",
        "TYPE_GORIYA_RED   , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x6B] = [
        "TYPE_GORIYA_RED   ,  8,  3",
        "TYPE_GORIYA_RED   , 12,  3",
        "TYPE_GORIYA_RED   , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x7B] = [
        "TYPE_GORIYA_RED   ,  6,  3",
        "TYPE_GORIYA_RED   , 14,  3",
        "TYPE_GORIYA_RED   ,  8,  6",
        "TYPE_GORIYA_RED   , 12,  6",
        empty, empty, empty, empty
    ]
    # Stalfos (0x4A)
    tbl[0x4A] = [
        "TYPE_STALFOS      ,  6,  3",
        "TYPE_STALFOS      , 14,  3",
        "TYPE_STALFOS      ,  6,  6",
        "TYPE_STALFOS      , 14,  6",
        empty, empty, empty, empty
    ]
    # Zols (0x5A)
    tbl[0x5A] = [
        "TYPE_ZOL          ,  8,  3",
        "TYPE_ZOL          , 12,  3",
        "TYPE_ZOL          , 10,  5",
        empty, empty, empty, empty, empty
    ]
    # Keese (0x4C, 0x5D)
    tbl[0x4C] = [
        "TYPE_KEESE_BLUE   ,  6,  2",
        "TYPE_KEESE_BLUE   , 14,  2",
        "TYPE_KEESE_BLUE   ,  6,  6",
        "TYPE_KEESE_BLUE   , 14,  6",
        empty, empty, empty, empty
    ]
    tbl[0x5D] = [
        "TYPE_KEESE_RED    ,  6,  2",
        "TYPE_KEESE_RED    , 14,  2",
        "TYPE_KEESE_RED    ,  6,  6",
        "TYPE_KEESE_RED    , 14,  6",
        empty, empty, empty, empty
    ]
    return tbl

def build_level4_enemies_table():
    """Table authentique d'ennemis pour le Niveau 4 (Steer/Snake)."""
    empty = "TYPE_NONE         ,  0,  0"
    tbl = {r: [empty] * 8 for r in range(128)}
    # Boss Gleeok (0x13)
    tbl[0x13][0] = "TYPE_GLEEOK       , 10,  3"
    # Like-Likes (0x32, 0x21)
    tbl[0x32] = [
        "TYPE_LIKE_LIKE    ,  6,  3",
        "TYPE_LIKE_LIKE    , 14,  3",
        "TYPE_LIKE_LIKE    , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x21] = [
        "TYPE_LIKE_LIKE    ,  7,  3",
        "TYPE_LIKE_LIKE    , 13,  3",
        "TYPE_LIKE_LIKE    , 10,  5",
        empty, empty, empty, empty, empty
    ]
    # Vires (0x70, 0x40, 0x12, 0x30)
    tbl[0x70] = [
        "TYPE_VIRE         ,  6,  3",
        "TYPE_VIRE         , 14,  3",
        "TYPE_VIRE         , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x40] = [
        "TYPE_VIRE         ,  6,  3",
        "TYPE_VIRE         , 14,  3",
        "TYPE_VIRE         ,  8,  5",
        "TYPE_VIRE         , 12,  5",
        empty, empty, empty, empty
    ]
    tbl[0x12] = [
        "TYPE_VIRE         ,  7,  3",
        "TYPE_VIRE         , 13,  3",
        "TYPE_VIRE         , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x30] = [
        "TYPE_VIRE         ,  6,  3",
        "TYPE_VIRE         , 14,  3",
        "TYPE_VIRE         , 10,  5",
        empty, empty, empty, empty, empty
    ]
    # Zols (0x61, 0x31, 0x41, 0x51)
    tbl[0x61] = [
        "TYPE_ZOL          ,  8,  3",
        "TYPE_ZOL          , 12,  3",
        "TYPE_ZOL          , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x31] = [
        "TYPE_ZOL          ,  7,  3",
        "TYPE_ZOL          , 13,  3",
        "TYPE_ZOL          , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x41] = [
        "TYPE_ZOL          ,  8,  3",
        "TYPE_ZOL          , 12,  3",
        "TYPE_ZOL          , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x51] = [
        "TYPE_ZOL          ,  6,  3",
        "TYPE_ZOL          , 14,  3",
        "TYPE_ZOL          , 10,  5",
        empty, empty, empty, empty, empty
    ]
    # Keese (0x62, 0x71, 0x00, 0x10)
    tbl[0x62] = [
        "TYPE_KEESE_BLUE   ,  6,  2",
        "TYPE_KEESE_BLUE   , 14,  2",
        "TYPE_KEESE_BLUE   ,  6,  6",
        "TYPE_KEESE_BLUE   , 14,  6",
        empty, empty, empty, empty
    ]
    tbl[0x71] = [
        "TYPE_KEESE_BLUE   ,  8,  2",
        "TYPE_KEESE_BLUE   , 12,  2",
        empty, empty, empty, empty, empty, empty
    ]
    tbl[0x00] = [
        "TYPE_KEESE_RED    ,  6,  2",
        "TYPE_KEESE_RED    , 14,  2",
        "TYPE_KEESE_RED    , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x10] = [
        "TYPE_KEESE_BLUE   ,  6,  2",
        "TYPE_KEESE_BLUE   , 14,  2",
        "TYPE_KEESE_BLUE   ,  6,  6",
        "TYPE_KEESE_BLUE   , 14,  6",
        empty, empty, empty, empty
    ]
    return tbl

def build_level5_enemies_table():
    """Table authentique d'ennemis pour le Niveau 5 (Lézard)."""
    empty = "TYPE_NONE         ,  0,  0"
    tbl = {r: [empty] * 8 for r in range(128)}
    # Boss Digdogger (0x24)
    tbl[0x24][0] = "TYPE_DIGDOGGER    , 10,  4"
    # Pols Voice (0x55, 0x47, 0x37)
    tbl[0x55] = [
        "TYPE_POLS_VOICE   ,  6,  3",
        "TYPE_POLS_VOICE   , 14,  3",
        "TYPE_POLS_VOICE   , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x47] = [
        "TYPE_POLS_VOICE   ,  7,  3",
        "TYPE_POLS_VOICE   , 13,  3",
        "TYPE_POLS_VOICE   , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x37] = [
        "TYPE_POLS_VOICE   ,  6,  3",
        "TYPE_POLS_VOICE   , 14,  3",
        "TYPE_POLS_VOICE   ,  8,  5",
        "TYPE_POLS_VOICE   , 12,  5",
        empty, empty, empty, empty
    ]
    # Gibdos (0x16, 0x25, 0x67)
    tbl[0x16] = [
        "TYPE_GIBDO        ,  6,  3",
        "TYPE_GIBDO        , 14,  3",
        "TYPE_GIBDO        , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x25] = [
        "TYPE_GIBDO        ,  7,  3",
        "TYPE_GIBDO        , 13,  3",
        "TYPE_GIBDO        , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x67] = [
        "TYPE_GIBDO        ,  6,  3",
        "TYPE_GIBDO        , 14,  3",
        "TYPE_GIBDO        , 10,  5",
        empty, empty, empty, empty, empty
    ]
    # Darknuts Blue & Red (0x15, 0x57, 0x66, 0x45)
    tbl[0x15] = [
        "TYPE_DARKNUT_BLUE ,  6,  3",
        "TYPE_DARKNUT_BLUE , 14,  3",
        "TYPE_DARKNUT_BLUE , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x57] = [
        "TYPE_DARKNUT_BLUE ,  7,  3",
        "TYPE_DARKNUT_RED  , 13,  3",
        "TYPE_DARKNUT_RED  , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x66] = [
        "TYPE_DARKNUT_RED  ,  6,  3",
        "TYPE_DARKNUT_RED  , 14,  3",
        "TYPE_DARKNUT_RED  , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x45] = [
        "TYPE_DARKNUT_RED  ,  8,  3",
        "TYPE_DARKNUT_RED  , 12,  3",
        "TYPE_DARKNUT_RED  , 10,  5",
        empty, empty, empty, empty, empty
    ]
    # Zols (0x65, 0x35, 0x77)
    tbl[0x65] = [
        "TYPE_ZOL          ,  8,  3",
        "TYPE_ZOL          , 12,  3",
        "TYPE_ZOL          , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x35] = [
        "TYPE_ZOL          ,  6,  3",
        "TYPE_ZOL          , 14,  3",
        "TYPE_ZOL          , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x77] = [
        "TYPE_ZOL          ,  8,  3",
        "TYPE_ZOL          , 12,  3",
        empty, empty, empty, empty, empty, empty
    ]
    # Keese (0x76, 0x26)
    tbl[0x76] = [
        "TYPE_KEESE_BLUE   ,  8,  3",
        "TYPE_KEESE_BLUE   , 12,  3",
        empty, empty, empty, empty, empty, empty
    ]
    tbl[0x26] = [
        "TYPE_KEESE_RED    ,  6,  2",
        "TYPE_KEESE_RED    , 14,  2",
        "TYPE_KEESE_RED    , 10,  5",
        empty, empty, empty, empty, empty
    ]
    return tbl

def build_level6_enemies_table():
    """Table authentique d'ennemis pour le Niveau 6 (Dragon)."""
    empty = "TYPE_NONE         ,  0,  0"
    tbl = {r: [empty] * 8 for r in range(128)}
    # Boss Gohma Red (0x1C)
    tbl[0x1C][0] = "TYPE_GOHMA_RED    , 10,  2"
    # Wizzrobes Blue (0x49, 0x5A)
    tbl[0x49] = [
        "TYPE_WIZZROBE_BLUE,  8,  3",
        "TYPE_WIZZROBE_BLUE, 12,  3",
        "TYPE_WIZZROBE_BLUE, 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x5A] = [
        "TYPE_WIZZROBE_BLUE,  8,  3",
        "TYPE_WIZZROBE_BLUE, 12,  3",
        "TYPE_WIZZROBE_BLUE, 10,  5",
        empty, empty, empty, empty, empty
    ]
    # Darknuts Blue (0x1B, 0x38, 0x3A, 0x6A)
    tbl[0x1B] = [
        "TYPE_DARKNUT_BLUE ,  6,  3",
        "TYPE_DARKNUT_BLUE , 14,  3",
        "TYPE_DARKNUT_BLUE , 10,  4",
        "TYPE_DARKNUT_BLUE ,  6,  6",
        "TYPE_DARKNUT_BLUE , 14,  6",
        empty, empty, empty
    ]
    tbl[0x38] = [
        "TYPE_DARKNUT_BLUE ,  6,  3",
        "TYPE_DARKNUT_BLUE , 14,  3",
        "TYPE_DARKNUT_BLUE , 10,  4",
        "TYPE_DARKNUT_BLUE ,  6,  6",
        "TYPE_DARKNUT_BLUE , 14,  6",
        empty, empty, empty
    ]
    tbl[0x3A] = [
        "TYPE_DARKNUT_BLUE ,  6,  3",
        "TYPE_DARKNUT_BLUE , 14,  3",
        "TYPE_DARKNUT_BLUE , 10,  4",
        "TYPE_DARKNUT_BLUE ,  6,  6",
        "TYPE_DARKNUT_BLUE , 14,  6",
        empty, empty, empty
    ]
    tbl[0x6A] = [
        "TYPE_DARKNUT_BLUE , 10,  4",
        empty, empty, empty, empty, empty, empty, empty
    ]
    # Darknuts Red (0x09, 0x28, 0x29, 0x59, 0x69)
    tbl[0x09] = [
        "TYPE_DARKNUT_RED  ,  8,  3",
        "TYPE_DARKNUT_RED  , 12,  3",
        "TYPE_DARKNUT_RED  , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x28] = [
        "TYPE_DARKNUT_RED  ,  8,  3",
        "TYPE_DARKNUT_RED  , 12,  3",
        "TYPE_DARKNUT_RED  , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x29] = [
        "TYPE_DARKNUT_RED  ,  8,  3",
        "TYPE_DARKNUT_RED  , 12,  3",
        "TYPE_DARKNUT_RED  , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x59] = [
        "TYPE_DARKNUT_RED  ,  8,  3",
        "TYPE_DARKNUT_RED  , 12,  3",
        "TYPE_DARKNUT_RED  , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x69] = [
        "TYPE_DARKNUT_RED  ,  6,  3",
        "TYPE_DARKNUT_RED  , 14,  3",
        "TYPE_DARKNUT_RED  , 10,  4",
        "TYPE_DARKNUT_RED  ,  6,  6",
        "TYPE_DARKNUT_RED  , 14,  6",
        empty, empty, empty
    ]
    # Gibdos (0x08 - Wand cellar)
    tbl[0x08] = [
        "TYPE_GIBDO        ,  6,  3",
        "TYPE_GIBDO        , 14,  3",
        "TYPE_GIBDO        , 10,  5",
        empty, empty, empty, empty, empty
    ]
    # Like-Likes (0x39)
    tbl[0x39] = [
        "TYPE_LIKE_LIKE    ,  6,  3",
        "TYPE_LIKE_LIKE    , 14,  3",
        "TYPE_LIKE_LIKE    , 10,  5",
        empty, empty, empty, empty, empty
    ]
    # Goriyas (0x0A, 0x18, 0x19, 0x68)
    tbl[0x0A] = [
        "TYPE_GORIYA_RED   ,  6,  3",
        "TYPE_GORIYA_RED   , 14,  3",
        "TYPE_GORIYA_RED   ,  8,  6",
        "TYPE_GORIYA_RED   , 12,  6",
        empty, empty, empty, empty
    ]
    tbl[0x18] = [
        "TYPE_GORIYA_BLUE  , 10,  4",
        empty, empty, empty, empty, empty, empty, empty
    ]
    tbl[0x19] = [
        "TYPE_GORIYA_RED   ,  6,  3",
        "TYPE_GORIYA_RED   , 14,  3",
        "TYPE_GORIYA_RED   ,  8,  6",
        "TYPE_GORIYA_RED   , 12,  6",
        empty, empty, empty, empty
    ]
    tbl[0x68] = [
        "TYPE_GORIYA_RED   ,  8,  3",
        "TYPE_GORIYA_RED   , 12,  3",
        "TYPE_GORIYA_RED   , 10,  5",
        empty, empty, empty, empty, empty
    ]
    # Wallmasters (0x1A, 0x78, 0x7A)
    tbl[0x1A] = [
        "TYPE_WALLMASTER   ,  6,  3",
        "TYPE_WALLMASTER   , 14,  3",
        "TYPE_WALLMASTER   ,  6,  6",
        "TYPE_WALLMASTER   , 14,  6",
        empty, empty, empty, empty
    ]
    tbl[0x78] = [
        "TYPE_WALLMASTER   ,  6,  3",
        "TYPE_WALLMASTER   , 14,  3",
        "TYPE_WALLMASTER   , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x7A] = [
        "TYPE_WALLMASTER   ,  6,  3",
        "TYPE_WALLMASTER   , 14,  3",
        "TYPE_WALLMASTER   , 10,  5",
        empty, empty, empty, empty, empty
    ]
    # Stalfos (0x0B, 0x2A, 0x4A, 0x58)
    tbl[0x0B] = [
        "TYPE_STALFOS      , 10,  4",
        empty, empty, empty, empty, empty, empty, empty
    ]
    tbl[0x2A] = [
        "TYPE_STALFOS      ,  6,  3",
        "TYPE_STALFOS      , 14,  3",
        "TYPE_STALFOS      , 10,  4",
        "TYPE_STALFOS      ,  6,  6",
        "TYPE_STALFOS      , 14,  6",
        empty, empty, empty
    ]
    tbl[0x4A] = [
        "TYPE_STALFOS      ,  6,  3",
        "TYPE_STALFOS      , 14,  3",
        "TYPE_STALFOS      , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x58] = [
        "TYPE_STALFOS      ,  6,  3",
        "TYPE_STALFOS      , 14,  3",
        "TYPE_STALFOS      , 10,  4",
        "TYPE_STALFOS      ,  6,  6",
        "TYPE_STALFOS      , 14,  6",
        empty, empty, empty
    ]
    # Ropes (0x48)
    tbl[0x48] = [
        "TYPE_ROPE         , 10,  4",
        empty, empty, empty, empty, empty, empty, empty
    ]
    return tbl

def build_level7_enemies_table():
    """Table authentique d'ennemis pour le Niveau 7 (Démon)."""
    empty = "TYPE_NONE         ,  0,  0"
    tbl = {r: [empty] * 8 for r in range(128)}
    # Boss Aquamentus (0x2A)
    tbl[0x2A][0] = "TYPE_AQUAMENTUS   , 14,  4"
    # Dodongos (0x28, 0x39, 0x6C)
    tbl[0x28][0] = "TYPE_DODONGO      , 10,  4"
    tbl[0x39][0] = "TYPE_DODONGO      , 10,  4"
    tbl[0x6C][0] = "TYPE_DODONGO      , 10,  4"
    # Wizzrobes Blue (0x68)
    tbl[0x68] = [
        "TYPE_WIZZROBE_BLUE,  8,  3",
        "TYPE_WIZZROBE_BLUE, 12,  3",
        "TYPE_WIZZROBE_BLUE, 10,  5",
        empty, empty, empty, empty, empty
    ]
    # Darknuts (0x1A, 0x29, 0x38, 0x48, 0x59, 0x5C)
    tbl[0x1A] = [
        "TYPE_DARKNUT_RED  ,  6,  3",
        "TYPE_DARKNUT_RED  , 14,  3",
        "TYPE_DARKNUT_RED  ,  8,  6",
        "TYPE_DARKNUT_RED  , 12,  6",
        empty, empty, empty, empty
    ]
    tbl[0x29] = [
        "TYPE_DARKNUT_RED  ,  6,  3",
        "TYPE_DARKNUT_RED  , 14,  3",
        "TYPE_DARKNUT_RED  ,  8,  6",
        "TYPE_DARKNUT_RED  , 12,  6",
        empty, empty, empty, empty
    ]
    tbl[0x38] = [
        "TYPE_DARKNUT_RED  ,  6,  3",
        "TYPE_DARKNUT_RED  , 14,  3",
        "TYPE_DARKNUT_RED  ,  8,  6",
        "TYPE_DARKNUT_RED  , 12,  6",
        empty, empty, empty, empty
    ]
    tbl[0x48] = [
        "TYPE_DARKNUT_BLUE , 10,  4",
        empty, empty, empty, empty, empty, empty, empty
    ]
    tbl[0x59] = [
        "TYPE_DARKNUT_RED  ,  6,  3",
        "TYPE_DARKNUT_RED  , 14,  3",
        "TYPE_DARKNUT_RED  ,  8,  6",
        "TYPE_DARKNUT_RED  , 12,  6",
        empty, empty, empty, empty
    ]
    tbl[0x5C] = [
        "TYPE_DARKNUT_RED  , 10,  4",
        empty, empty, empty, empty, empty, empty, empty
    ]
    # Goriyas (0x19, 0x3A, 0x69, 0x6B, 0x7A)
    tbl[0x19] = [
        "TYPE_GORIYA_BLUE  ,  6,  3",
        "TYPE_GORIYA_BLUE  , 14,  3",
        "TYPE_GORIYA_BLUE  ,  8,  6",
        "TYPE_GORIYA_BLUE  , 12,  6",
        empty, empty, empty, empty
    ]
    tbl[0x3A] = [
        "TYPE_GORIYA_RED   , 10,  4",
        empty, empty, empty, empty, empty, empty, empty
    ]
    tbl[0x69] = [
        "TYPE_GORIYA_BLUE  ,  8,  3",
        "TYPE_GORIYA_BLUE  , 12,  3",
        "TYPE_GORIYA_BLUE  , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x6B] = [
        "TYPE_GORIYA_BLUE  ,  6,  3",
        "TYPE_GORIYA_BLUE  , 14,  3",
        "TYPE_GORIYA_BLUE  ,  8,  6",
        "TYPE_GORIYA_BLUE  , 12,  6",
        empty, empty, empty, empty
    ]
    tbl[0x7A] = [
        "TYPE_GORIYA_RED   , 10,  4",
        empty, empty, empty, empty, empty, empty, empty
    ]
    # Gibdos (0x4A - Candle cellar, 0x78)
    tbl[0x4A] = [
        "TYPE_GIBDO        ,  6,  3",
        "TYPE_GIBDO        , 14,  3",
        "TYPE_GIBDO        , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x78] = [
        "TYPE_GIBDO        ,  6,  3",
        "TYPE_GIBDO        , 14,  3",
        "TYPE_GIBDO        , 10,  5",
        empty, empty, empty, empty, empty
    ]
    # Stalfos (0x5B, 0x6A)
    tbl[0x5B] = [
        "TYPE_STALFOS      , 10,  4",
        empty, empty, empty, empty, empty, empty, empty
    ]
    tbl[0x6A] = [
        "TYPE_STALFOS      ,  6,  3",
        "TYPE_STALFOS      , 14,  3",
        "TYPE_STALFOS      , 10,  4",
        "TYPE_STALFOS      ,  6,  6",
        "TYPE_STALFOS      , 14,  6",
        empty, empty, empty
    ]
    # Keeses (0x5A, 0x5D, 0x6D)
    tbl[0x5A] = [
        "TYPE_KEESE_RED    ,  6,  2",
        "TYPE_KEESE_RED    , 14,  2",
        "TYPE_KEESE_RED    , 10,  4",
        "TYPE_KEESE_RED    ,  6,  6",
        "TYPE_KEESE_RED    , 14,  6",
        empty, empty, empty
    ]
    tbl[0x5D] = [
        "TYPE_KEESE_BLUE   ,  6,  2",
        "TYPE_KEESE_BLUE   , 14,  2",
        "TYPE_KEESE_BLUE   ,  6,  6",
        "TYPE_KEESE_BLUE   , 14,  6",
        empty, empty, empty, empty
    ]
    tbl[0x6D] = [
        "TYPE_KEESE_RED    ,  6,  2",
        "TYPE_KEESE_RED    , 14,  2",
        "TYPE_KEESE_RED    , 10,  4",
        "TYPE_KEESE_RED    ,  6,  6",
        "TYPE_KEESE_RED    , 14,  6",
        empty, empty, empty
    ]
    # Wallmasters & Bubbles (0x58, 0x18, 0x49)
    tbl[0x58] = [
        "TYPE_WALLMASTER   , 10,  4",
        empty, empty, empty, empty, empty, empty, empty
    ]
    tbl[0x18] = [
        "TYPE_BUBBLE       ,  6,  3",
        "TYPE_BUBBLE       , 14,  3",
        "TYPE_BUBBLE       , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x49] = [
        "TYPE_BUBBLE       ,  6,  3",
        "TYPE_BUBBLE       , 14,  3",
        "TYPE_BUBBLE       , 10,  5",
        empty, empty, empty, empty, empty
    ]
    return tbl

def build_level8_enemies_table():
    """Table authentique d'ennemis pour le Niveau 8 (Lion)."""
    empty = "TYPE_NONE         ,  0,  0"
    tbl = {r: [empty] * 8 for r in range(128)}
    # Boss Dodongos (0x3C)
    tbl[0x3C] = [
        "TYPE_DODONGO      , 14,  4",
        "TYPE_DODONGO      , 10,  4",
        empty, empty, empty, empty, empty, empty
    ]
    # Wizzrobes Blue (0x7F)
    tbl[0x7F] = [
        "TYPE_WIZZROBE_BLUE,  8,  3",
        "TYPE_WIZZROBE_BLUE, 12,  3",
        "TYPE_WIZZROBE_BLUE, 10,  5",
        empty, empty, empty, empty, empty
    ]
    # Darknuts (0x3B, 0x3D, 0x5C, 0x6E, 0x7D)
    tbl[0x3B] = [
        "TYPE_DARKNUT_RED  , 10,  4",
        empty, empty, empty, empty, empty, empty, empty
    ]
    tbl[0x3D] = [
        "TYPE_DARKNUT_BLUE , 10,  4",
        empty, empty, empty, empty, empty, empty, empty
    ]
    tbl[0x5C] = [
        "TYPE_DARKNUT_RED  , 10,  4",
        empty, empty, empty, empty, empty, empty, empty
    ]
    tbl[0x6E] = [
        "TYPE_DARKNUT_BLUE , 10,  4",
        empty, empty, empty, empty, empty, empty, empty
    ]
    tbl[0x7D] = [
        "TYPE_DARKNUT_BLUE , 10,  4",
        empty, empty, empty, empty, empty, empty, empty
    ]
    # Like-Likes (0x3F, 0x4E, 0x7C)
    tbl[0x3F] = [
        "TYPE_LIKE_LIKE    ,  6,  3",
        "TYPE_LIKE_LIKE    , 14,  3",
        "TYPE_LIKE_LIKE    ,  8,  6",
        "TYPE_LIKE_LIKE    , 12,  6",
        empty, empty, empty, empty
    ]
    tbl[0x4E] = [
        "TYPE_LIKE_LIKE    ,  6,  3",
        "TYPE_LIKE_LIKE    , 14,  3",
        "TYPE_LIKE_LIKE    ,  8,  6",
        "TYPE_LIKE_LIKE    , 12,  6",
        empty, empty, empty, empty
    ]
    tbl[0x7C] = [
        "TYPE_LIKE_LIKE    ,  6,  3",
        "TYPE_LIKE_LIKE    , 14,  3",
        "TYPE_LIKE_LIKE    ,  8,  6",
        "TYPE_LIKE_LIKE    , 12,  6",
        empty, empty, empty, empty
    ]
    # Gibdos (0x6F - Magic Key cellar)
    tbl[0x6F] = [
        "TYPE_GIBDO        ,  6,  3",
        "TYPE_GIBDO        , 14,  3",
        "TYPE_GIBDO        , 10,  5",
        empty, empty, empty, empty, empty
    ]
    # Stalfos (0x3E, 0x5E)
    tbl[0x3E] = [
        "TYPE_STALFOS      ,  6,  3",
        "TYPE_STALFOS      , 14,  3",
        "TYPE_STALFOS      ,  8,  6",
        "TYPE_STALFOS      , 12,  6",
        empty, empty, empty, empty
    ]
    tbl[0x5E] = [
        "TYPE_STALFOS      ,  6,  3",
        "TYPE_STALFOS      , 14,  3",
        "TYPE_STALFOS      , 10,  5",
        empty, empty, empty, empty, empty
    ]
    # Keeses (0x4C, 0x5D, 0x5F, 0x6D)
    tbl[0x4C] = [
        "TYPE_KEESE_RED    ,  6,  2",
        "TYPE_KEESE_RED    , 14,  2",
        "TYPE_KEESE_RED    ,  6,  6",
        "TYPE_KEESE_RED    , 14,  6",
        empty, empty, empty, empty
    ]
    tbl[0x5D] = [
        "TYPE_KEESE_BLUE   ,  6,  2",
        "TYPE_KEESE_BLUE   , 14,  2",
        "TYPE_KEESE_BLUE   ,  6,  6",
        "TYPE_KEESE_BLUE   , 14,  6",
        empty, empty, empty, empty
    ]
    tbl[0x5F] = [
        "TYPE_KEESE_RED    ,  6,  2",
        "TYPE_KEESE_RED    , 14,  2",
        "TYPE_KEESE_RED    ,  6,  6",
        "TYPE_KEESE_RED    , 14,  6",
        empty, empty, empty, empty
    ]
    tbl[0x6D] = [
        "TYPE_KEESE_RED    ,  6,  2",
        "TYPE_KEESE_RED    , 14,  2",
        "TYPE_KEESE_RED    ,  6,  6",
        "TYPE_KEESE_RED    , 14,  6",
        empty, empty, empty, empty
    ]
    # Goriyas & Bubbles (0x4D, 0x2D)
    tbl[0x4D] = [
        "TYPE_GORIYA_RED   , 10,  4",
        empty, empty, empty, empty, empty, empty, empty
    ]
    tbl[0x2D] = [
        "TYPE_BUBBLE       , 10,  4",
        empty, empty, empty, empty, empty, empty, empty
    ]
    return tbl

def build_level9_enemies_table():
    """Table authentique d'ennemis pour le Niveau 9 (Montagne de la Mort)."""
    empty = "TYPE_NONE         ,  0,  0"
    tbl = {r: [empty] * 8 for r in range(128)}
    # Boss Ganon (0x42)
    tbl[0x42][0] = "TYPE_GANON        , 10,  4"
    # Princess Zelda Room (0x32) - Complètement sécurisée
    # Darknuts Blue (0x45, 0x53, 0x64)
    tbl[0x45] = [
        "TYPE_DARKNUT_BLUE ,  6,  3",
        "TYPE_DARKNUT_BLUE , 14,  3",
        "TYPE_DARKNUT_BLUE ,  8,  6",
        "TYPE_DARKNUT_BLUE , 12,  6",
        empty, empty, empty, empty
    ]
    tbl[0x53] = [
        "TYPE_DARKNUT_BLUE ,  6,  3",
        "TYPE_DARKNUT_BLUE , 14,  3",
        "TYPE_DARKNUT_BLUE ,  8,  6",
        "TYPE_DARKNUT_BLUE , 12,  6",
        empty, empty, empty, empty
    ]
    tbl[0x64] = [
        "TYPE_DARKNUT_BLUE ,  6,  3",
        "TYPE_DARKNUT_BLUE , 14,  3",
        "TYPE_DARKNUT_BLUE ,  8,  6",
        "TYPE_DARKNUT_BLUE , 12,  6",
        empty, empty, empty, empty
    ]
    # Darknuts Red (0x35, 0x54, 0x55, 0x66)
    tbl[0x35] = [
        "TYPE_DARKNUT_RED  ,  8,  3",
        "TYPE_DARKNUT_RED  , 12,  3",
        "TYPE_DARKNUT_RED  , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x54] = [
        "TYPE_DARKNUT_RED  ,  8,  3",
        "TYPE_DARKNUT_RED  , 12,  3",
        "TYPE_DARKNUT_RED  , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x55] = [
        "TYPE_DARKNUT_BLUE , 10,  4",
        empty, empty, empty, empty, empty, empty, empty
    ]
    tbl[0x66] = [
        "TYPE_DARKNUT_RED  , 10,  4",
        empty, empty, empty, empty, empty, empty, empty
    ]
    # Goriyas (0x56, 0x63)
    tbl[0x56] = [
        "TYPE_GORIYA_RED   ,  6,  3",
        "TYPE_GORIYA_RED   , 14,  3",
        "TYPE_GORIYA_RED   ,  8,  6",
        "TYPE_GORIYA_RED   , 12,  6",
        empty, empty, empty, empty
    ]
    tbl[0x63] = [
        "TYPE_GORIYA_RED   ,  8,  3",
        "TYPE_GORIYA_RED   , 12,  3",
        "TYPE_GORIYA_RED   , 10,  5",
        empty, empty, empty, empty, empty
    ]
    # Wizzrobes Blue (0x46)
    tbl[0x46] = [
        "TYPE_WIZZROBE_BLUE,  8,  3",
        "TYPE_WIZZROBE_BLUE, 12,  3",
        "TYPE_WIZZROBE_BLUE, 10,  5",
        empty, empty, empty, empty, empty
    ]
    # Gibdos (0x75, 0x77)
    tbl[0x75] = [
        "TYPE_GIBDO        ,  6,  3",
        "TYPE_GIBDO        , 14,  3",
        "TYPE_GIBDO        , 10,  5",
        empty, empty, empty, empty, empty
    ]
    tbl[0x77] = [
        "TYPE_GIBDO        ,  6,  3",
        "TYPE_GIBDO        , 14,  3",
        "TYPE_GIBDO        , 10,  5",
        empty, empty, empty, empty, empty
    ]
    # Wallmasters (0x44, 0x65)
    tbl[0x44] = [
        "TYPE_WALLMASTER   ,  6,  3",
        "TYPE_WALLMASTER   , 14,  3",
        "TYPE_WALLMASTER   ,  6,  6",
        "TYPE_WALLMASTER   , 14,  6",
        empty, empty, empty, empty
    ]
    tbl[0x65] = [
        "TYPE_WALLMASTER   ,  6,  3",
        "TYPE_WALLMASTER   , 14,  3",
        "TYPE_WALLMASTER   ,  6,  6",
        "TYPE_WALLMASTER   , 14,  6",
        empty, empty, empty, empty
    ]
    # Stalfos (0x34, 0x43)
    tbl[0x34] = [
        "TYPE_STALFOS      ,  6,  3",
        "TYPE_STALFOS      , 14,  3",
        "TYPE_STALFOS      ,  8,  6",
        "TYPE_STALFOS      , 12,  6",
        empty, empty, empty, empty
    ]
    tbl[0x43] = [
        "TYPE_STALFOS      , 10,  4",
        empty, empty, empty, empty, empty, empty, empty
    ]
    # Gels (0x23 - Red Ring cellar, 0x33)
    tbl[0x23] = [
        "TYPE_GEL          ,  6,  3",
        "TYPE_GEL          , 14,  3",
        "TYPE_GEL          ,  8,  6",
        "TYPE_GEL          , 12,  6",
        empty, empty, empty, empty
    ]
    tbl[0x33] = [
        "TYPE_GEL          ,  6,  3",
        "TYPE_GEL          , 14,  3",
        "TYPE_GEL          ,  8,  6",
        "TYPE_GEL          , 12,  6",
        empty, empty, empty, empty
    ]
    # Like-Likes (0x24)
    tbl[0x24] = [
        "TYPE_LIKE_LIKE    ,  6,  3",
        "TYPE_LIKE_LIKE    , 14,  3",
        "TYPE_LIKE_LIKE    , 10,  5",
        empty, empty, empty, empty, empty
    ]
    return tbl

def decode_nes_dungeon_rooms(lvl, room_set, ent):
    candidates = [
        "zelda.nes",
        os.path.join(BASE_DIR, "zelda.nes"),
        os.path.join(os.path.dirname(__file__), "..", "zelda.nes"),
    ]
    nes_path = None
    for c in candidates:
        if os.path.exists(c):
            nes_path = c
            break
    if not nes_path:
        return {}

    with open(nes_path, "rb") as f:
        rom = f.read()[16:]

    bank5 = rom[0x14000 : 0x18000]
    ptrs = []
    for i in range(10):
        lo = bank5[0xa704 - 0x8000 + i*2]
        hi = bank5[0xa704 - 0x8000 + i*2 + 1]
        ptrs.append((lo | (hi << 8)) - 0x8000)

    tile_table = bank5[0xa718 - 0x8000 : 0xa718 - 0x8000 + 8]

    def decode_column(macro_byte):
        seq_idx = (macro_byte >> 4) & 0x0F
        entry_idx = macro_byte & 0x0F
        ptr = ptrs[seq_idx]
        cur_entry = -1
        pos = ptr
        while True:
            b = bank5[pos]
            if b & 0x80:
                cur_entry += 1
                if cur_entry == entry_idx:
                    break
            pos += 1
        col = []
        while len(col) < 7:
            b = bank5[pos]
            t_idx = b & 7
            count = ((b & 0x70) >> 4) + 1
            tile = tile_table[t_idx]
            for _ in range(count):
                if len(col) < 7:
                    col.append(tile)
            pos += 1
        return col

    if lvl in (7, 8, 9):
        ns_doors_16 = rom[0x18a00 : 0x18a80]
        ew_doors_16 = rom[0x18a80 : 0x18b00]
        room_types = rom[0x18b80 : 0x18c00]
    else:
        ns_doors_16 = rom[0x18700 : 0x18780]
        ew_doors_16 = rom[0x18780 : 0x18800]
        room_types = rom[0x18880 : 0x18900]

    T_INNER = {
        0x74: 0, 0x68: 0, 0xb0: 5, 0x94: 6, 0xb4: 6, 0x70: 7, 0xf4: 5, 0x24: 0
    }

    def door_code_to_tile(code, is_horizontal=True):
        if code == 0:
            return 12  # Open
        elif code == 1:
            return 1 if is_horizontal else 3  # Solid wall
        elif code == 4:
            return 15  # Bombable / shutter
        elif code == 5:
            return 13  # Locked
        elif code == 7:
            return 14  # Shutter
        return 1 if is_horizontal else 3

    decoded = {}
    for r in sorted(room_set):
        rt = room_types[r] & 0x3F
        ns = ns_doors_16[r]
        ew = ew_doors_16[r]
        nd = (ns >> 5) & 7
        sd = (ns >> 2) & 7
        wd = (ew >> 5) & 7
        ed = (ew >> 2) & 7

        rx, ry = r % 16, r // 16
        # Seal doors leading outside the dungeon rooms
        if (r - 16) not in room_set: nd = 1
        if (r + 16) not in room_set and r != ent: sd = 1
        if rx == 0 or (r - 1) not in room_set: wd = 1
        if rx == 15 or (r + 1) not in room_set: ed = 1

        # Shutter / specific overrides
        if lvl == 1:
            if r == 0x53 and nd == 4: nd = 7
            if r == 0x43 and sd == 4: sd = 7
        elif lvl == 2:
            if r == 0x0E and wd != 1: wd = 7 # West shutter to Triforce
            if r == 0x0D: ed = 0            # Open back to Dodongo
        elif lvl == 3:
            if r == 0x4D and nd != 1: nd = 7 # North shutter to Triforce
            if r == 0x3D: sd = 0            # Open back to Manhandla
            if r == 0x5C and ed == 4: ed = 7
            if r == 0x5D and wd == 4: wd = 7
        elif lvl == 4:
            if r == 0x13 and nd != 1: nd = 7 # North shutter to Triforce
            if r == 0x03: sd = 0            # Open back to Gleeok
            if r == 0x40 and ed == 4: ed = 7
            if r == 0x41 and wd == 4: wd = 7
            if r == 0x31 and nd == 4: nd = 7
        elif lvl == 5:
            if r == 0x24 and wd != 1: wd = 7 # West shutter to Triforce
            if r == 0x23: ed = 0            # Open back to Digdogger
            if r == 0x56 and nd == 4: nd = 7
            if r == 0x46 and sd == 4: sd = 7
            if r == 0x66 and ed == 4: ed = 7
            if r == 0x67 and wd == 4: wd = 7
        elif lvl == 6:
            if r == 0x1C and nd != 1: nd = 7 # North shutter to Triforce
            if r == 0x0C: sd = 0            # Open back to Gohma
            if r == 0x49 and ed == 4: ed = 7
            if r == 0x4A and wd == 4: wd = 7
            if r == 0x59 and ed == 4: ed = 7
            if r == 0x5A and wd == 4: wd = 7
        elif lvl == 7:
            if r == 0x2A and ed != 1: ed = 7 # East shutter to Triforce
            if r == 0x2B: wd = 0            # Open back to Boss
            if r == 0x6A and nd == 4: nd = 7
            if r == 0x5A and sd == 4: sd = 7
        elif lvl == 8:
            if r == 0x3C and nd != 1: nd = 7 # North shutter to Triforce
            if r == 0x2C: sd = 0            # Open back to Boss
            if r == 0x5D and ed == 4: ed = 7
            if r == 0x5E and wd == 4: wd = 7
        elif lvl == 9:
            if r == 0x42 and nd != 1: nd = 7 # North shutter to Zelda
            if r == 0x32: sd = 0            # Open back to Ganon
            if r == 0x43: wd = 4            # Bomb door West into Ganon room
            if r == 0x42: ed = 4            # Bomb door East into 0x43
            if r == 0x53: sd = 4            # Bomb door South into 0x63
            if r == 0x63: nd = 4            # Bomb door North into 0x53

        n_tile = door_code_to_tile(nd, True)
        s_tile = door_code_to_tile(sd, True)
        w_tile = door_code_to_tile(wd, False)
        e_tile = door_code_to_tile(ed, False)

        # Entrance south door is ALWAYS exit (tile 12)
        if r == ent:
            s_tile = 12

        r_def = rom[0x160DE + rt*12 : 0x160DE + (rt+1)*12]
        inner_cols = [decode_column(b) for b in r_def]

        grid = []
        grid.append([8] + [1]*8 + [n_tile, n_tile] + [1]*8 + [9])
        for y in range(7):
            row = [0] * 20
            if y in (3, 4) and wd != 1:
                row[0] = w_tile
            else:
                row[0] = 3
                row[1] = 3
            for x in range(12):
                row[4 + x] = T_INNER.get(inner_cols[x][y], 0)
            if y in (3, 4) and ed != 1:
                row[19] = e_tile
            else:
                row[18] = 4
                row[19] = 4
            grid.append(row)
        grid.append([3, 3] + [0]*16 + [4, 4])
        grid.append([10] + [2]*8 + [s_tile, s_tile] + [2]*8 + [11])

        # Level specific room adjustments
        if lvl == 1 and r == 0x22:
            grid[4][10] = 0 # Hidden under floor until block pushed
        elif lvl == 3 and r == 0x6A:
            grid[4][14] = 7 # Diamond staircase to Raft cellar!
        elif lvl == 4 and r == 0x04:
            grid[4][14] = 7 # Diamond staircase to Stepladder cellar!
        elif lvl == 5 and r == 0x36:
            grid[4][14] = 7 # Diamond staircase to Whistle cellar!
        elif lvl == 6 and r == 0x08:
            grid[4][14] = 7 # Diamond staircase to Wand cellar!
        elif lvl == 7 and r == 0x4A:
            grid[4][14] = 7 # Diamond staircase to Red Candle cellar!
        elif lvl == 8 and r == 0x6F:
            grid[4][14] = 7 # Diamond staircase to Magic Key cellar!
        elif lvl == 9 and r == 0x23:
            grid[4][14] = 7 # Diamond staircase to Red Ring cellar!
        elif lvl == 9 and r == 0x45:
            grid[4][14] = 7 # Diamond staircase to Silver Arrows cellar!

        decoded[r] = grid

    return decoded

def build_dungeon_asm(lvl):
    meta = DUNGEON_METADATA[lvl]
    ent = meta['ent']
    boss = meta['boss']
    tri = meta['tri']

    dungeon_rooms = set(DUNGEON_ROOMS[lvl])
    dungeon_rooms.add(boss)
    dungeon_rooms.add(tri)
    dungeon_rooms.add(ent)

    start_rx, start_ry = ent % 16, ent // 16

    # Décodage authentique depuis zelda.nes pour tous les donjons 1 à 9
    decoded_rooms = decode_nes_dungeon_rooms(lvl, dungeon_rooms, ent)
    if lvl == 1:
        enemies_table = build_level1_enemies_table()
    elif lvl == 2:
        enemies_table = build_level2_enemies_table()
    elif lvl == 3:
        enemies_table = build_level3_enemies_table()
    elif lvl == 4:
        enemies_table = build_level4_enemies_table()
    elif lvl == 5:
        enemies_table = build_level5_enemies_table()
    elif lvl == 6:
        enemies_table = build_level6_enemies_table()
    elif lvl == 7:
        enemies_table = build_level7_enemies_table()
    elif lvl == 8:
        enemies_table = build_level8_enemies_table()
    elif lvl == 9:
        enemies_table = build_level9_enemies_table()

    # Deduplicate enemy formations
    empty_slot = "TYPE_NONE         ,  0,  0"
    empty_tuple = tuple([empty_slot] * 8)
    uniq_formations = [empty_tuple]
    formation_map = {empty_tuple: 0}
    enemy_indices = [0] * 128
    for r in range(128):
        t = tuple(enemies_table[r])
        if t not in formation_map:
            formation_map[t] = len(uniq_formations)
            uniq_formations.append(t)
        enemy_indices[r] = formation_map[t]

    lines = []
    lines.append("; ===========================================================================")
    lines.append(f"; dung{lvl}.asm - Donjon Niveau {lvl} : {meta['name']} pour Zelda C64")
    lines.append("; GENERE AUTOMATIQUEMENT par tools/build_dungeons.py - NE PAS MODIFIER")
    lines.append(f"; Salles étanches : {len(dungeon_rooms)} salles")
    lines.append("; ===========================================================================")
    lines.append("!cpu 6510")
    lines.append("!source \"src/enemy_types.inc\"")
    lines.append("* = $c000\n")

    lines.append("; En-tête Donjon (6 octets : $C000..$C005)")
    lines.append("map_rooms_w:        !byte 16")
    lines.append("map_rooms_h:        !byte 8")
    lines.append(f"map_rooms_cnt:      !byte {len(dungeon_rooms)}")
    lines.append("map_bg_col:         !byte 0   ; noir")
    lines.append(f"map_mc1_col:        !byte {meta['mc1']}")
    lines.append("map_mc2_col:        !byte 14  ; bleu clair\n")

    # Table des offsets ry * 16 (8 octets : $C006..$C00D)
    row_offsets = [ry * 16 for ry in range(8)]
    lines.append("; Table des offsets ry * map_rooms_w (8 octets : $C006..$C00D)")
    lines.append("map_row_offset:")
    lines.append("        !byte " + ", ".join(str(v) for v in row_offsets))

    # Pointeur vers le jeu de caractères du donjon ($C00E..$C00F)
    lines.append("; Pointeur vers le jeu de caracteres du donjon ($C00E..$C00F)")
    lines.append("map_charset_ptr:")
    lines.append("        !word dungeon_charset")
    lines.append("; Pointeur vers la table des ennemis ($C010..$C011)")
    lines.append("map_enemies_ptr_hdr:")
    lines.append("        !word map_enemies")
    lines.append("        !fill 4, 0                          ; Alignement à $C015\n")

    # Tables des pointeurs LO / HI
    lines.append("; Tables des pointeurs (128 octets LO : $C016..$C095 / 128 octets HI : $C096..$C115)")
    lines.append("room_tbl_lo:")
    lo_ptrs = []
    hi_ptrs = []
    for r in range(128):
        if r in dungeon_rooms:
            lo_ptrs.append(f"<u_room_{r:02x}")
            hi_ptrs.append(f">u_room_{r:02x}")
        else:
            lo_ptrs.append("<dummy_sealed_room")
            hi_ptrs.append(">dummy_sealed_room")

    for i in range(0, 128, 16):
        lines.append("        !byte " + ", ".join(lo_ptrs[i:i+16]))
    lines.append("room_tbl_hi:")
    for i in range(0, 128, 16):
        lines.append("        !byte " + ", ".join(hi_ptrs[i:i+16]))
    lines.append("")

    # Métadonnées Donjon & Palette (128 octets : $C116..$C195)
    lines.append("; Métadonnées Donjon & Palette (128 octets : $C116..$C195)")
    lines.append("room_zone_palette:")
    lines.append("dungeon_enemies_ptr:    !word map_enemies   ; $C116 ($C116..$C117)")
    lines.append(f"dungeon_boss_room:      !byte ${boss:02x}    ; $C118")
    lines.append(f"dungeon_tri_room:       !byte ${tri:02x}     ; $C119")
    lines.append(f"dungeon_boss_type:      !byte {meta['boss_type']} ; $C11A")
    lines.append(f"dungeon_boss_hp:        !byte {meta['boss_hp']}   ; $C11B")
    lines.append(f"dungeon_level:          !byte {lvl}         ; $C11C")
    lines.append(f"dungeon_wall_col:       !byte {meta['wall']} ; $C11D")
    lines.append(f"dungeon_start_rx:       !byte {start_rx}    ; $C11E")
    lines.append(f"dungeon_start_ry:       !byte {start_ry}    ; $C11F")
    lines.append("        !fill 128 - 10, 0                   ; Reste des 128 octets ($C120..$C195)\n")

    # Index de formation d'ennemis par salle (128 octets : $C196..$C215)
    lines.append("; Index de formation d'ennemis par salle (128 octets : $C196..$C215)")
    lines.append("room_enemy_idx:")
    for i in range(0, 128, 16):
        lines.append("        !byte " + ", ".join(str(v) for v in enemy_indices[i:i+16]))
    lines.append("")

    # RLE des salles du donjon
    for r in sorted(list(dungeon_rooms)):
        rx, ry = r % 16, r // 16
        tile_grid = decoded_rooms[r]
        rle = compress_room_rle(tile_grid)
        lines.append(f"; Salle (${r:02x} : rx={rx}, ry={ry}) - RLE compact ({len(rle)} octets)")
        lines.append(f"u_room_{r:02x}:")
        for chunk_start in range(0, len(rle), 16):
            chunk = rle[chunk_start:chunk_start + 16]
            lines.append("        !byte " + ", ".join(str(v) for v in chunk))

    # Salle hermétique de secours (murs pleins 20x10)
    sealed_dummy = [[1] * 20 for _ in range(10)]
    dummy_rle = compress_room_rle(sealed_dummy)
    lines.append("\n; Salle scellée étanche pour toutes les coordonnées hors-donjon")
    lines.append("dummy_sealed_room:")
    lines.append("        !byte " + ", ".join(str(v) for v in dummy_rle) + "\n")

    # Table des ennemis dédupliquée
    lines.append(f"; Table d'apparition des monstres dédupliquée ({len(uniq_formations)} formations x 24 octets)")
    lines.append("map_enemies:")
    for idx, slots in enumerate(uniq_formations):
        lines.append(f"        ; Formation {idx}")
        lines.append("        !byte " + ",   ".join(slots))

    # Charset de 512 octets authentique du donjon
    chars_0_31, chars_168_199 = generate_dungeon_charset_bytes()
    lines.append("\n; ===========================================================================")
    lines.append("; Jeu de caracteres authentique du donjon (512 octets)")
    lines.append("; Copié dynamiquement par disk.asm a $2000 (0..31) et $2540 (168..199)")
    lines.append("; ===========================================================================")
    lines.append("dungeon_charset:")
    lines.append("; Chars 0..31 (Tuiles 0..7 : 256 octets)")
    for i in range(0, 256, 8):
        chunk = chars_0_31[i:i+8]
        lines.append("        !byte " + ", ".join(str(v) for v in chunk))

    lines.append("; Chars 168..199 (Tuiles 8..15 : 256 octets)")
    for i in range(0, 256, 8):
        chunk = chars_168_199[i:i+8]
        lines.append("        !byte " + ", ".join(str(v) for v in chunk))

    return "\n".join(lines) + "\n"

def main():
    os.makedirs(SRC_DIR, exist_ok=True)
    os.makedirs(BLD_DIR, exist_ok=True)

    nes_path = os.path.join(BASE_DIR, "zelda.nes")
    if not os.path.exists(nes_path):
        all_exist = all(os.path.exists(os.path.join(SRC_DIR, f"dung{lvl}.asm")) for lvl in range(1, 10))
        if all_exist:
            print("[+] zelda.nes absent mais tous les dung<N>.asm sont déjà générés.")
            return

    print("[*] Génération des 9 Donjons autonomes avec tuiles authentiques...")
    for lvl in range(1, 10):
        asm_code = build_dungeon_asm(lvl)
        out_path = os.path.join(SRC_DIR, f"dung{lvl}.asm")
        with open(out_path, "w", encoding="utf-8") as f:
            f.write(asm_code)
        print(f"  [+] {out_path} généré.")

    print("[+] Tous les 9 fichiers donjons sont prêts pour la compilation ACME !")

if __name__ == "__main__":
    main()
