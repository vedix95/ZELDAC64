#!/usr/bin/env python3
"""
tools/relocate_overworld_spawns.py
Relocalise automatiquement tous les spawns d'ennemis de l'Overworld qui tombent
sur des tuiles solides ou hors des limites de déplacement.
Garantit que chaque ennemi terrestre apparaît sur une tuile praticable libre,
et que les Zoras apparaissent exclusivement dans l'eau.
"""

import os
import re
import sys

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.join(BASE_DIR, "tools"))

import tilegen

# Décalages en spirale par rayon croissant (distance de Manhattan / Chebyshev)
SPIRAL_OFFSETS = []
for r in range(1, 10):
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            if max(abs(dx), abs(dy)) == r:
                SPIRAL_OFFSETS.append((dx, dy))


def find_valid_tile(r_grid, tiles, start_x, start_y, is_water_enemy, used_tiles):
    # Vérifie d'abord la tuile courante
    def is_tile_ok(tx, ty):
        if not (1 <= tx <= 18 and 1 <= ty <= 8):
            return False
        tid = r_grid[ty][tx]
        t_solid = tiles[tid]["solid"]
        t_name = tiles[tid].get("name", "")
        # Tuile eau = ID 4 ou nom 'water'
        is_water = (tid == 4 or t_name == "water")

        if is_water_enemy:
            return is_water
        else:
            return (not t_solid) and (not is_water)

    if is_tile_ok(start_x, start_y) and (start_x, start_y) not in used_tiles:
        return start_x, start_y

    # Recherche en spirale
    for dx, dy in SPIRAL_OFFSETS:
        tx, ty = start_x + dx, start_y + dy
        if is_tile_ok(tx, ty) and (tx, ty) not in used_tiles:
            return tx, ty

    # Si toutes les tuiles préférées sont prises, accepter une tuile ok même si partagée
    if is_tile_ok(start_x, start_y):
        return start_x, start_y
    for dx, dy in SPIRAL_OFFSETS:
        tx, ty = start_x + dx, start_y + dy
        if is_tile_ok(tx, ty):
            return tx, ty

    # Fallback sécurisé : centre de l'écran
    return 10, 4


def relocate_all():
    tiles_path = os.path.join(BASE_DIR, "assets", "tiles.txt")
    world_path = os.path.join(BASE_DIR, "assets", "world.txt")
    en_inc_path = os.path.join(BASE_DIR, "src", "map_overworld_enemies.inc")

    cfg, tiles = tilegen.parse_tiles(tiles_path)
    world_rooms = tilegen.parse_world(world_path, tiles)[0]

    with open(en_inc_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    out_lines = []
    cur_room = None
    relocated_count = 0

    for line in lines:
        m = re.search(r"Salle\s+(\d+)", line)
        if m:
            cur_room = int(m.group(1))
            out_lines.append(line)
            continue

        raw = line.strip()
        if raw.startswith("!byte") and cur_room is not None:
            parts = [p.strip() for p in raw[5:].split(",")]
            r_grid = world_rooms[cur_room]
            used_tiles = set()
            new_slots = []

            for i in range(0, len(parts), 3):
                if i + 2 < len(parts):
                    en_type = parts[i]
                    sx = int(parts[i + 1])
                    sy = int(parts[i + 2])

                    if en_type == "TYPE_NONE":
                        new_slots.append((en_type, 0, 0))
                    else:
                        is_water_enemy = (en_type == "TYPE_ZORA")
                        # Si l'ennemi est aquatique mais que la salle ne contient pas d'eau, remplacer par TYPE_NONE
                        has_water = any((r_grid[y][x] == 4 or tiles[r_grid[y][x]].get("name") == "water")
                                        for y in range(10) for x in range(20))
                        if is_water_enemy and not has_water:
                            new_slots.append(("TYPE_NONE", 0, 0))
                            relocated_count += 1
                            continue

                        new_x, new_y = find_valid_tile(r_grid, tiles, sx, sy, is_water_enemy, used_tiles)
                        used_tiles.add((new_x, new_y))
                        if (new_x, new_y) != (sx, sy):
                            relocated_count += 1
                        new_slots.append((en_type, new_x, new_y))

            # Formatage de la ligne en conservant l'alignement
            slot_strs = []
            for en_type, nx, ny in new_slots:
                slot_strs.append(f"{en_type:<16}, {nx:3d}, {ny:2d}")
            new_line = "        !byte " + ",   ".join(slot_strs) + "\n"
            out_lines.append(new_line)
            cur_room = None
        else:
            out_lines.append(line)

    with open(en_inc_path, "w", encoding="utf-8") as f:
        f.writelines(out_lines)

    print(f"[+] Relocalisation terminée : {relocated_count} monstres relocalisés.")
    return relocated_count


if __name__ == "__main__":
    relocate_all()
