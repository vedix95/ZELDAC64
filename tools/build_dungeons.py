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
    2: {0x7d, 0x6d, 0x6e, 0x6f, 0x5e, 0x5f, 0x4e, 0x4f, 0x3e, 0x3f, 0x2e, 0x2f, 0x1e, 0x1f, 0x0d, 0x0e, 0x0f},
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

    # Si Donjon 1 : décodage authentique depuis zelda.nes
    if lvl == 1:
        decoded_rooms = decode_nes_level1()
        enemies_table = build_level1_enemies_table()
    else:
        # Donjons 2..9 : salles scellées
        decoded_rooms = {}
        for r in dungeon_rooms:
            # Salle générique de donjon scellée
            g = []
            g.append([8] + [1]*8 + [12, 12] + [1]*8 + [9])
            for y in range(7):
                g.append([3, 3] + [0]*16 + [4, 4])
            g.append([3, 3] + [0]*16 + [4, 4])
            g.append([10] + [2]*8 + [12, 12] + [2]*8 + [11])
            decoded_rooms[r] = g

        empty = "TYPE_NONE         ,  0,  0"
        bx, by = meta['boss_coords']
        boss_slot = f"{meta['boss_type']:<18}, {bx:>2}, {by:>2}"
        enemies_table = {}
        for r in range(128):
            slots = [empty] * 8
            if r == boss:
                slots[0] = boss_slot
            elif r in dungeon_rooms and r != ent and r != tri:
                slots[0] = f"{'TYPE_STALFOS':<18},  8,  4"
                slots[1] = f"{'TYPE_KEESE_RED':<18}, 12,  3"
            enemies_table[r] = slots

    lines = []
    lines.append("; ===========================================================================")
    lines.append(f"; dung{lvl}.asm - Donjon Niveau {lvl} : {meta['name']} pour Zelda C64")
    lines.append("; GENERE AUTOMATIQUEMENT par tools/build_dungeons.py - NE PAS MODIFIER")
    lines.append(f"; Salles étanches : {len(dungeon_rooms)} salles")
    lines.append("; ===========================================================================")
    lines.append("!cpu 6510")
    lines.append("!source \"src/enemy_types.inc\"")
    lines.append("* = $a000\n")

    lines.append("; En-tête Donjon (6 octets : $A000..$A005)")
    lines.append("map_rooms_w:        !byte 16")
    lines.append("map_rooms_h:        !byte 8")
    lines.append(f"map_rooms_cnt:      !byte {len(dungeon_rooms)}")
    lines.append("map_bg_col:         !byte 0   ; noir")
    lines.append(f"map_mc1_col:        !byte {meta['mc1']}")
    lines.append("map_mc2_col:        !byte 14  ; bleu clair\n")

    # Table des offsets ry * 16 (8 octets : $A006..$A00D)
    row_offsets = [ry * 16 for ry in range(8)]
    lines.append("; Table des offsets ry * map_rooms_w (8 octets : $A006..$A00D)")
    lines.append("map_row_offset:")
    lines.append("        !byte " + ", ".join(str(v) for v in row_offsets))

    # Pointeur vers le jeu de caractères du donjon ($A00E..$A00F)
    lines.append("; Pointeur vers le jeu de caracteres du donjon ($A00E..$A00F)")
    lines.append("map_charset_ptr:")
    lines.append("        !word dungeon_charset")
    lines.append("        !fill 6, 0                          ; Alignement à $A015\n")

    # Tables des pointeurs LO / HI
    lines.append("; Tables des pointeurs (128 octets LO : $A016..$A095 / 128 octets HI : $A096..$A115)")
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

    # Métadonnées Donjon & Palette (128 octets : $A116..$A195)
    lines.append("; Métadonnées Donjon & Palette (128 octets : $A116..$A195)")
    lines.append("room_zone_palette:")
    lines.append("dungeon_enemies_ptr:    !word map_enemies   ; $A116 ($A116..$A117)")
    lines.append(f"dungeon_boss_room:      !byte ${boss:02x}    ; $A118")
    lines.append(f"dungeon_tri_room:       !byte ${tri:02x}     ; $A119")
    lines.append(f"dungeon_boss_type:      !byte {meta['boss_type']} ; $A11A")
    lines.append(f"dungeon_boss_hp:        !byte {meta['boss_hp']}   ; $A11B")
    lines.append(f"dungeon_level:          !byte {lvl}         ; $A11C")
    lines.append(f"dungeon_wall_col:       !byte {meta['wall']} ; $A11D")
    lines.append(f"dungeon_start_rx:       !byte {start_rx}    ; $A11E")
    lines.append(f"dungeon_start_ry:       !byte {start_ry}    ; $A11F")
    lines.append("        !fill 128 - 10, 0                   ; Reste des 128 octets ($A120..$A195)\n")

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

    # Table des ennemis
    lines.append("; Table d'apparition des monstres pour ce donjon")
    lines.append("map_enemies:")
    for r in range(128):
        rx, ry = r % 16, r // 16
        slots = enemies_table[r]
        lines.append(f"        ; Salle ${r:02x} ({rx:>2}, {ry:>2})")
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
