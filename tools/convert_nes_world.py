#!/usr/bin/env python3
"""
tools/convert_nes_world.py - Convertit la carte Overworld NES 16x8 originale (1986)
vers le format C64 Zelda (16x8 ecrans de 20x10 tuiles).

Garantit la continuite parfaite des passages entre ecrans voisins (Nord, Sud, Est, Ouest).
"""

import os
import sys

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
NES_DIR = os.path.join(BASE_DIR, "assets", "nes")

TILES_FILE = os.path.join(NES_DIR, "nes_zelda_overworld_tile_map.txt")
BLOCKS_FILE = os.path.join(NES_DIR, "nes_zelda_overworld_blocking_map.txt")
OUTPUT_WORLD = os.path.join(BASE_DIR, "assets", "world.txt")

WATER_TILES = {
    '50', '51', '52', '64', '65', '66', '78', '79', '7a',
    '8c', '8d', '8e', '8f', '90', '91', '92'
}
TREE_TILES = {
    '15', '16', '17', '19', '1a', '1b', '1c', '1d', '1e', '1f',
    '20', '21', '22', '28', '29', '2a', '2b', '2c', '2d', '2e',
    '2f', '30', '31', '32', '33', '34', '6a', '6b', '6c', '7e',
    '7f', '80'
}
CAVE_TILES = {'12'}
ROAD_TILES = {'00', '0e', '14', '40'}

SOLID = {'#', 'T', '~'}


def get_tile_symbol(t, b, x, y):
    if t in CAVE_TILES:
        return 'O'
    if t in WATER_TILES:
        return '~'
    if b == 'X':
        if t in TREE_TILES:
            return 'T'
        else:
            return '#'
    else:
        if t in ROAD_TILES:
            return '_'
        # Variabilite naturelle de l'herbe avec fleurs et touffes
        h = (x * 37 + y * 19) % 100
        if h < 5:
            return 'f'
        elif h < 12:
            return ','
        else:
            return '.'


def convert_nes_to_c64():
    if not os.path.exists(TILES_FILE) or not os.path.exists(BLOCKS_FILE):
        sys.exit(f"Erreur : Fichiers NES manquants dans {NES_DIR}")

    with open(TILES_FILE, "r", encoding="utf-8") as f:
        nes_tiles = [l.strip().split() for l in f if l.strip()]
    with open(BLOCKS_FILE, "r", encoding="utf-8") as f:
        nes_blocks = [l.strip() for l in f if l.strip()]

    rooms = {}

    for ry in range(8):
        for rx in range(16):
            c64_room = []
            for y in range(10):
                nes_y = ry * 11 + y
                row = []
                for cx in range(20):
                    if cx == 0:
                        nes_x = rx * 16 + 0
                    elif cx == 1:
                        nes_x = rx * 16 + 1
                    elif cx == 18:
                        nes_x = rx * 16 + 14
                    elif cx == 19:
                        nes_x = rx * 16 + 15
                    else:
                        interp = 2 + round((cx - 2) * (11.0 / 15.0))
                        nes_x = rx * 16 + interp

                    sym = get_tile_symbol(
                        nes_tiles[nes_y][nes_x],
                        nes_blocks[nes_y][nes_x],
                        nes_x, nes_y
                    )
                    row.append(sym)
                c64_room.append(row)
            rooms[(rx, ry)] = c64_room

    # Harmonisation des bordures pour garantir 100% de continuite
    # 1. Bordures Horizontales (Est / Ouest)
    for ry in range(8):
        for rx in range(15):
            left_r = rooms[(rx, ry)]
            right_r = rooms[(rx + 1, ry)]
            for y in range(10):
                l_solid = left_r[y][19] in SOLID
                r_solid = right_r[y][0] in SOLID
                if l_solid != r_solid:
                    if l_solid:
                        # Rendre solide à droite
                        right_r[y][0] = left_r[y][19]
                    else:
                        # Rendre solide à gauche
                        left_r[y][19] = right_r[y][0]

    # 2. Bordures Verticales (Nord / Sud)
    for ry in range(7):
        for rx in range(16):
            top_r = rooms[(rx, ry)]
            bot_r = rooms[(rx, ry + 1)]
            for x in range(20):
                t_solid = top_r[9][x] in SOLID
                b_solid = bot_r[0][x] in SOLID
                if t_solid != b_solid:
                    if t_solid:
                        bot_r[0][x] = top_r[9][x]
                    else:
                        top_r[9][x] = bot_r[0][x]

    # Ajustement specifique de la salle de depart (7, 7) H-8
    # Placer la grotte de l'epee a la falaise rocheuse
    start_r = rooms[(7, 7)]
    # Placer l'entree de grotte en (x=6, y=1) ou (x=5, y=1)
    start_r[1][5] = 'O'
    start_r[1][6] = 'O'
    # S'assurer que le sol sous la grotte est degage pour Link
    start_r[2][5] = '.'
    start_r[2][6] = '.'

    # Ecriture de assets/world.txt
    room_labels = [
        "A", "B", "C", "D", "E", "F", "G", "H",
        "I", "J", "K", "L", "M", "N", "O", "P"
    ]

    lines_out = [
        "; ===========================================================================",
        "; CARTE OVERWORLD DU MONDE ZELDA NES (1986) - 16 x 8 ECRANS (128 SALLES)",
        "; Format : 20 x 10 tuiles par ecran (320 x 80 tuiles au total).",
        "; Symboles : . herbe  , touffes  f fleurs  T arbre  ~ eau  # rocher  _ chemin  O grotte",
        "; ===========================================================================",
        ""
    ]

    for ry in range(8):
        lines_out.append(f"; ---------------------------------------------------------------------------")
        lines_out.append(f"; RANGÉE {ry} (Ligne {ry + 1}) : Ecrans ({room_labels[0]}-{ry+1} a {room_labels[15]}-{ry+1})")
        lines_out.append(f"; ---------------------------------------------------------------------------")
        for y in range(10):
            row_chunks = []
            for rx in range(16):
                row_str = "".join(rooms[(rx, ry)][y])
                row_chunks.append(row_str)
            lines_out.append(" ".join(row_chunks))
        lines_out.append("")

    with open(OUTPUT_WORLD, "w", encoding="utf-8") as f:
        f.write("\n".join(lines_out))

    print(f"OK : Carte 16x8 générée dans {OUTPUT_WORLD} (128 écrans de 20x10 tuiles)")

    # Génération de world_enemies (128 salles x 8 slots x 3 octets = 3072 octets)
    update_enemies_asm(rooms, room_labels)
    return rooms


def update_enemies_asm(rooms, room_labels):
    enemies_asm_path = os.path.join(BASE_DIR, "src", "enemies.asm")
    with open(enemies_asm_path, "r", encoding="utf-8") as f:
        content = f.read()

    lines = []
    lines.append("; ---------------------------------------------------------------------------")
    lines.append("; Table de spawn des ennemis pour les 128 salles (indices 0..127)")
    lines.append("; Format par salle (8 slots x 3 octets = 24 octets par salle) :")
    lines.append(";   Slot 0..7 : type, spawn_tile_x, spawn_tile_y")
    lines.append("; ---------------------------------------------------------------------------")
    lines.append("world_enemies:")

    for ry in range(8):
        for rx in range(16):
            r_idx = ry * 16 + rx
            r_name = f"({rx}, {ry}) {room_labels[rx]}-{ry + 1}"
            r_tiles = rooms[(rx, ry)]

            if (rx, ry) == (7, 7):
                # Salle de départ Zelda 1 (H-8) : Aucun ennemi (paisible)
                slots = [("TYPE_NONE", 0, 0)] * 8
            else:
                # Recherche des tuiles praticables à l'intérieur
                open_tiles = []
                water_count = 0
                tree_count = 0
                for y in range(2, 8):
                    for x in range(3, 17):
                        t = r_tiles[y][x]
                        if t not in SOLID:
                            open_tiles.append((x, y))
                        elif t == '~':
                            water_count += 1
                        elif t == 'T':
                            tree_count += 1

                slots = []
                if open_tiles:
                    # 2 à 4 ennemis par salle
                    count = 2 + (r_idx % 3)
                    if len(open_tiles) < count:
                        count = len(open_tiles)

                    # Espacement des positions
                    step = max(1, len(open_tiles) // count)
                    for k in range(count):
                        tx, ty = open_tiles[(k * step + (r_idx * 7)) % len(open_tiles)]
                        # Type selon terrain
                        if water_count > 10:
                            en_type = "TYPE_OCTO"
                        elif tree_count > 40:
                            en_type = "TYPE_MOBLIN" if (k % 2 == 0) else "TYPE_OCTO"
                        else:
                            en_type = "TYPE_OCTO" if ((k + r_idx) % 2 == 0) else "TYPE_MOBLIN"
                        slots.append((en_type, tx, ty))

                while len(slots) < 8:
                    slots.append(("TYPE_NONE", 0, 0))

            lines.append(f"        ; Salle {r_idx:3d} : {r_name}")
            parts = []
            for t, x, y in slots:
                parts.append(f"{t:<11}, {x:3d}, {y:2d}")
            lines.append("        !byte " + ",   ".join(parts))

    new_block = "\n".join(lines) + "\n"

    # Remplacement dans src/enemies.asm
    import re
    pattern = r'(world_enemies:\s*\n)(.*?)(\n; -{10,}\n; get_rand)'
    if re.search(pattern, content, re.DOTALL):
        new_content = re.sub(
            pattern,
            lambda m: f"{new_block}{m.group(3)}",
            content,
            flags=re.DOTALL
        )
        with open(enemies_asm_path, "w", encoding="utf-8") as f:
            f.write(new_content)
        print(f"OK : src/enemies.asm mis à jour avec les 128 salles de world_enemies")
    else:
        print("ATTENTION : Pattern world_enemies non trouvé dans src/enemies.asm")


if __name__ == "__main__":
    convert_nes_to_c64()
