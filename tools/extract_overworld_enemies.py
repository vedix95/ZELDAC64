#!/usr/bin/env python3
"""
tools/extract_overworld_enemies.py - Extrait les ennemis authentiques de Zelda 1 NES
depuis zelda.nes et calcule leurs positions (X, Y) optimales et valides sur la carte
Overworld C64 (assets/world.txt), puis met à jour world_enemies dans src/enemies.asm.
"""

import os
import re
import sys

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
ROM_PATH = os.path.join(BASE_DIR, "zelda.nes")
WORLD_PATH = os.path.join(BASE_DIR, "assets", "world.txt")
ENEMIES_ASM = os.path.join(BASE_DIR, "src", "enemies.asm")

NES_TO_C64 = {
    0x01: 'TYPE_LYNEL_BLUE',
    0x02: 'TYPE_LYNEL_RED',
    0x03: 'TYPE_MOBLIN_BLUE',
    0x04: 'TYPE_MOBLIN_RED',
    0x05: 'TYPE_GORIYA_BLUE',
    0x06: 'TYPE_GORIYA_RED',
    0x07: 'TYPE_OCTO_BLUE',
    0x08: 'TYPE_OCTO_RED',
    0x09: 'TYPE_OCTO_BLUE',
    0x0A: 'TYPE_OCTO_RED',
    0x0B: 'TYPE_DARKNUT_BLUE',
    0x0C: 'TYPE_DARKNUT_RED',
    0x0D: 'TYPE_TEKTITE_BLUE',
    0x0E: 'TYPE_TEKTITE_RED',
    0x0F: 'TYPE_LEEVER_BLUE',
    0x10: 'TYPE_LEEVER_RED',
    0x11: 'TYPE_ZORA',
    0x1A: 'TYPE_PEAHAT',
    0x1E: 'TYPE_ARMOS',
    0x1F: 'TYPE_TEKTITE_RED',  # Chemins montagneux
    0x21: 'TYPE_GHINI',        # Cimetière
    0x2F: 'TYPE_NONE',         # Bassins des fées
}

WALKABLE_SYMBOLS = {'.', ',', 'f', '_'}


def load_world_rooms():
    with open(WORLD_PATH, 'r', encoding='utf-8') as f:
        lines = [l for l in f if not l.startswith(';') and l.strip()]

    rooms = {}
    for ry in range(8):
        row_lines = lines[ry * 10 : (ry + 1) * 10]
        for rx in range(16):
            r_grid = []
            for y in range(10):
                line_parts = row_lines[y].split()
                r_grid.append(line_parts[rx])
            rooms[(rx, ry)] = r_grid
    return rooms


def pick_spawn_coords(grid, count):
    if count == 0:
        return []

    caves = []
    for y in range(10):
        for x in range(20):
            if grid[y][x] == 'O':
                caves.append((x, y))

    # Priorité 1 : Intérieur sûr (x dans 3..16, y dans 2..7)
    candidates = []
    for y in range(2, 8):
        for x in range(3, 17):
            if grid[y][x] in WALKABLE_SYMBOLS:
                if all(abs(x - cx) + abs(y - cy) >= 2 for cx, cy in caves):
                    candidates.append((x, y))

    # Priorité 2 : Marge plus large (x dans 2..17, y dans 1..8)
    if len(candidates) < count:
        for y in range(1, 9):
            for x in range(2, 18):
                if (x, y) not in candidates and grid[y][x] in WALKABLE_SYMBOLS:
                    if all(abs(x - cx) + abs(y - cy) >= 2 for cx, cy in caves):
                        candidates.append((x, y))

    # Priorité 3 : Toutes tuiles marchables
    if len(candidates) < count:
        for y in range(10):
            for x in range(20):
                if (x, y) not in candidates and grid[y][x] in WALKABLE_SYMBOLS:
                    candidates.append((x, y))

    if not candidates:
        return [(10, 4)] * count

    # Farthest point sampling (dispersion spatiale maximale)
    center = (10, 4)
    candidates.sort(key=lambda p: (p[0] - center[0]) ** 2 + (p[1] - center[1]) ** 2)
    selected = [candidates[0]]

    while len(selected) < count:
        if len(selected) >= len(candidates):
            selected.append(selected[-1])
            continue
        best_cand = None
        best_dist = -1
        for cand in candidates:
            if cand in selected:
                continue
            min_d = min((cand[0] - s[0]) ** 2 + (cand[1] - s[1]) ** 2 for s in selected)
            if min_d > best_dist:
                best_dist = min_d
                best_cand = cand
        selected.append(best_cand)

    return selected


def extract_nes_enemies():
    if not os.path.exists(ROM_PATH):
        sys.exit(f"Erreur : {ROM_PATH} introuvable !")

    with open(ROM_PATH, 'rb') as f:
        rom = f.read()

    lb_off = 99328 + 16
    attrs_c = rom[lb_off + 256 : lb_off + 384]
    attrs_d = rom[lb_off + 384 : lb_off + 512]
    li_off = 103168 + 16
    foe_counts = rom[li_off + 36 : li_off + 40]
    ol_off = 83574 + 16
    obj_lists = rom[ol_off : ol_off + 201]

    offsets = [
        0, 5, 9, 15, 19, 25, 31, 36, 40, 45, 50, 56, 64, 72, 80, 88, 96, 104, 110,
        118, 126, 134, 142, 148, 156, 164, 169, 177, 185, 193, 201
    ]

    room_data = {}

    for r in range(128):
        c = attrs_c[r]
        d = attrs_d[r]
        m_id = c & 0x3F
        if d & 0x80:
            m_id |= 0x40
        count_idx = (c >> 6) & 3
        count = foe_counts[count_idx]

        if m_id == 0 or m_id == 0x2F:
            types = []
        elif m_id >= 0x62:
            list_idx = m_id - 0x62
            sub = list(obj_lists[offsets[list_idx] : offsets[list_idx + 1]])
            types = [NES_TO_C64.get(t, 'TYPE_NONE') for t in sub[:count]]
        else:
            c64_t = NES_TO_C64.get(m_id, 'TYPE_NONE')
            if m_id == 0x21:
                # Cimetière : 3 Ghinis
                types = [c64_t] * 3
            elif m_id == 0x1F:
                # Sentiers montagneux : 3 Tektites rouges
                types = [c64_t] * 3
            elif 0x32 <= m_id < 0x62:
                types = [c64_t]
            else:
                types = [c64_t] * count

        # Filtrer TYPE_NONE
        types = [t for t in types if t != 'TYPE_NONE']
        # Limiter à 8 ennemis max par salle
        types = types[:8]
        room_data[r] = types

    return room_data


def generate_world_enemies_asm():
    rooms = load_world_rooms()
    nes_enemies = extract_nes_enemies()

    lines = []
    lines.append("; ---------------------------------------------------------------------------")
    lines.append("; Table de spawn des ennemis pour les 128 salles de l'Overworld (indices 0..127)")
    lines.append("; Extrait authentiquement depuis The Legend of Zelda (NES 1986)")
    lines.append("; Format par salle (8 slots x 3 octets = 24 octets par salle) :")
    lines.append(";   Slot 0..7 : type, spawn_tile_x, spawn_tile_y")
    lines.append("; ---------------------------------------------------------------------------")
    lines.append("world_enemies:")

    for r in range(128):
        rx, ry = r % 16, r // 16
        col_letter = chr(ord('A') + rx)
        row_num = ry + 1
        lines.append(f"        ; Salle {r:3d} : ({rx:2d}, {ry:2d}) {col_letter}-{row_num}")

        enemy_types = nes_enemies[r]
        grid = rooms[(rx, ry)]
        spawns = pick_spawn_coords(grid, len(enemy_types))

        slots = []
        for i in range(len(enemy_types)):
            t = enemy_types[i]
            sx, sy = spawns[i]
            slots.append(f"{t:<16}, {sx:3d}, {sy:2d}")

        while len(slots) < 8:
            slots.append(f"{'TYPE_NONE':<16},   0,  0")

        lines.append("        !byte " + ",   ".join(slots))

    return "\n".join(lines) + "\n"



def update_enemies_asm():
    new_asm_block = generate_world_enemies_asm()

    with open(ENEMIES_ASM, 'r', encoding='utf-8') as f:
        content = f.read()

    pattern = r'(; -{20,}\n; Table de spawn des ennemis pour les 128 salles.*?\nworld_enemies:\n)(.*?)(\n; -{20,}\n; get_rand|\n\s*get_rand:)'
    if not re.search(pattern, content, re.DOTALL):
        # Alternative pattern matching just world_enemies: up to get_rand:
        pattern = r'(world_enemies:\n)(.*?)(\n; -{10,}\n; get_rand|\n\s*get_rand:)'

    match = re.search(pattern, content, re.DOTALL)
    if not match:
        print("Erreur : Impossible de localiser la table world_enemies dans src/enemies.asm !")
        sys.exit(1)

    new_content = content[:match.start()] + new_asm_block + content[match.end(2):]

    with open(ENEMIES_ASM, 'w', encoding='utf-8') as f:
        f.write(new_content)

    print(f"Succès : {ENEMIES_ASM} mis à jour avec les 128 salles authentiques et coordonnées valides !")


if __name__ == '__main__':
    update_enemies_asm()
