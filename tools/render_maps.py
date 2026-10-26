#!/usr/bin/env python3
"""
tools/render_maps.py - Générateur d'images PNG des cartes réelles de Zelda C64
Génère :
  - build/map_overworld.png : Carte complète 16x8 de l'Overworld (128 salles)
  - build/map_dungeon_1.png .. map_dungeon_9.png : Rendu pixel-art des 9 Donjons
"""

import os
import sys

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
BLD_DIR = os.path.join(BASE_DIR, "build")
TOOLS_DIR = os.path.join(BASE_DIR, "tools")
ASSETS_DIR = os.path.join(BASE_DIR, "assets")

sys.path.insert(0, TOOLS_DIR)

from sprgen import write_png
from tilegen import PALETTE, PIX, parse_tiles, parse_world, preview
from build_dungeons import DUNGEON_METADATA, DUNGEON_ROOMS, decode_nes_dungeon_rooms
from render_dungeon1_full import TILES_ART

def render_dungeon_room_rgb(grid, col_bg=0, col_mc1=3, col_mc2=14, col_ram=6):
    """Rend une salle de donjon (20x10 tuiles) en pixels RGB (320x160)."""
    room_w_px = 20 * 16
    room_h_px = 10 * 16
    img = [[(0, 0, 0)] * room_w_px for _ in range(room_h_px)]

    colors = [
        PALETTE[col_bg],
        PALETTE[col_mc1],
        PALETTE[col_mc2],
        PALETTE[col_ram],
    ]

    for ty in range(10):
        for tx in range(20):
            t_idx = grid[ty][tx]
            art = TILES_ART.get(t_idx, TILES_ART[0])
            for r in range(16):
                row_str = art[r]
                py = ty * 16 + r
                for c in range(8):
                    ch = row_str[c]
                    val = 0
                    if ch == '1': val = 1
                    elif ch == '2': val = 2
                    elif ch == 'c': val = 3
                    rgb = colors[val]
                    px1 = tx * 16 + c * 2
                    px2 = px1 + 1
                    img[py][px1] = rgb
                    img[py][px2] = rgb
    return img

def render_dungeon(lvl, out_path):
    meta = DUNGEON_METADATA[lvl]
    room_set = DUNGEON_ROOMS[lvl]
    ent = meta['ent']
    rooms = decode_nes_dungeon_rooms(lvl, room_set, ent)

    col_bg = 0
    col_mc1 = meta['mc1']
    col_mc2 = meta['wall'] % 16
    col_ram = 1

    # Calcule les bornes min et max des coordonnées de salles
    r_coords = [(r % 16, r // 16) for r in rooms.keys()]
    min_rx = min(rx for rx, ry in r_coords)
    max_rx = max(rx for rx, ry in r_coords)
    min_ry = min(ry for rx, ry in r_coords)
    max_ry = max(ry for rx, ry in r_coords)

    span_x = max_rx - min_rx + 1
    span_y = max_ry - min_ry + 1

    map_w_px = span_x * 320
    map_h_px = span_y * 160
    full_img = [[(0, 0, 0)] * map_w_px for _ in range(map_h_px)]

    for r, grid in rooms.items():
        rx, ry = r % 16, r // 16
        grid_x = (rx - min_rx) * 320
        grid_y = (ry - min_ry) * 160
        room_img = render_dungeon_room_rgb(grid, col_bg, col_mc1, col_mc2, col_ram)
        for y in range(160):
            for x in range(320):
                full_img[grid_y + y][grid_x + x] = room_img[y][x]

    write_png(out_path, full_img)
    print(f"  [+] Donjon {lvl} ({meta['name']}) rendu -> {out_path} ({map_w_px}x{map_h_px})")

def render_overworld(out_path):
    tiles_txt = os.path.join(ASSETS_DIR, "tiles.txt")
    world_txt = os.path.join(ASSETS_DIR, "world.txt")
    cfg, tiles = parse_tiles(tiles_txt)
    rooms, rx, ry, grid = parse_world(world_txt, tiles)
    preview(out_path, cfg, tiles, grid, rooms_x=rx, rooms_y=ry, scale=2)
    print(f"  [+] Overworld complet (16x8 salles) rendu -> {out_path}")

def main():
    os.makedirs(BLD_DIR, exist_ok=True)
    print("[*] Génération des cartes PNG du jeu pour analyse visuelle...")

    # 1. Overworld
    ow_path = os.path.join(BLD_DIR, "map_overworld.png")
    render_overworld(ow_path)

    # 2. Donjons 1 à 9
    for lvl in range(1, 10):
        dung_path = os.path.join(BLD_DIR, f"map_dungeon_{lvl}.png")
        render_dungeon(lvl, dung_path)

    print("[✓] Toutes les cartes PNG ont été générées avec succès dans build/ !")

if __name__ == "__main__":
    main()
