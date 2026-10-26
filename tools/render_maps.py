#!/usr/bin/env python3
"""
tools/render_maps.py - Générateur d'images PNG des cartes réelles de Zelda C64
Génère :
  - build/map_overworld.png : Carte complète 16x8 de l'Overworld (128 salles)
    avec découpage en grille (traits contrastés), délimitation des chunks,
    et badge de debug dans chaque salle : Coordonnées (ex: D4, H8), Chunk (ex: Chunk 1),
    index de salle en décimal et hexadécimal (#51 / $33).
  - build/map_dungeon_1.png .. map_dungeon_9.png : Rendu pixel-art des 9 Donjons
    avec découpage de chaque salle, coordonnées donjon et index de salle ($XX).
"""

import os
import sys

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
BLD_DIR = os.path.join(BASE_DIR, "build")
TOOLS_DIR = os.path.join(BASE_DIR, "tools")
ASSETS_DIR = os.path.join(BASE_DIR, "assets")

sys.path.insert(0, TOOLS_DIR)

from sprgen import write_png
from tilegen import (
    PALETTE, PIX, MAP_W, MAP_H, ART_H,
    parse_tiles, parse_world, get_room_zones,
    ZONE_BG, ZONE_MC1, ZONE_MC2, ZONE_TILE_COLORS
)
from build_dungeons import DUNGEON_METADATA, DUNGEON_ROOMS, decode_nes_dungeon_rooms
from render_dungeon1_full import TILES_ART

# -----------------------------------------------------------------------------
# Police Bitmap 5x7 autonome (ASCII complet sans dépendance PIL)
# -----------------------------------------------------------------------------
FONT_5X7 = {
    ' ': [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00],
    '!': [0x04, 0x04, 0x04, 0x04, 0x00, 0x04, 0x00],
    '"': [0x0A, 0x0A, 0x0A, 0x00, 0x00, 0x00, 0x00],
    '#': [0x0A, 0x0A, 0x1F, 0x0A, 0x1F, 0x0A, 0x0A],
    '$': [0x04, 0x0F, 0x14, 0x0E, 0x05, 0x1E, 0x04],
    '%': [0x19, 0x19, 0x02, 0x04, 0x08, 0x13, 0x13],
    '&': [0x0C, 0x12, 0x14, 0x08, 0x15, 0x12, 0x0D],
    "'": [0x04, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00],
    '(': [0x02, 0x04, 0x08, 0x08, 0x08, 0x04, 0x02],
    ')': [0x08, 0x04, 0x02, 0x02, 0x02, 0x04, 0x08],
    '*': [0x00, 0x0A, 0x04, 0x1F, 0x04, 0x0A, 0x00],
    '+': [0x00, 0x04, 0x04, 0x1F, 0x04, 0x04, 0x00],
    ',': [0x00, 0x00, 0x00, 0x00, 0x04, 0x04, 0x08],
    '-': [0x00, 0x00, 0x00, 0x1F, 0x00, 0x00, 0x00],
    '.': [0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x00],
    '/': [0x01, 0x02, 0x04, 0x08, 0x10, 0x00, 0x00],
    '0': [0x0E, 0x11, 0x13, 0x15, 0x19, 0x11, 0x0E],
    '1': [0x04, 0x0C, 0x04, 0x04, 0x04, 0x04, 0x0E],
    '2': [0x0E, 0x11, 0x01, 0x02, 0x04, 0x08, 0x1F],
    '3': [0x1F, 0x02, 0x04, 0x02, 0x01, 0x11, 0x0E],
    '4': [0x02, 0x06, 0x0A, 0x12, 0x1F, 0x02, 0x02],
    '5': [0x1F, 0x10, 0x1E, 0x01, 0x01, 0x11, 0x0E],
    '6': [0x06, 0x08, 0x10, 0x1E, 0x11, 0x11, 0x0E],
    '7': [0x1F, 0x01, 0x02, 0x04, 0x08, 0x08, 0x08],
    '8': [0x0E, 0x11, 0x11, 0x0E, 0x11, 0x11, 0x0E],
    '9': [0x0E, 0x11, 0x11, 0x0F, 0x01, 0x02, 0x0C],
    ':': [0x00, 0x04, 0x00, 0x00, 0x04, 0x00, 0x00],
    ';': [0x00, 0x04, 0x00, 0x00, 0x04, 0x04, 0x08],
    '<': [0x02, 0x04, 0x08, 0x10, 0x08, 0x04, 0x02],
    '=': [0x00, 0x1F, 0x00, 0x1F, 0x00, 0x00, 0x00],
    '>': [0x08, 0x04, 0x02, 0x01, 0x02, 0x04, 0x08],
    '?': [0x0E, 0x11, 0x01, 0x02, 0x04, 0x00, 0x04],
    '@': [0x0E, 0x11, 0x01, 0x0D, 0x15, 0x15, 0x0E],
    'A': [0x0E, 0x11, 0x11, 0x1F, 0x11, 0x11, 0x11],
    'B': [0x1E, 0x11, 0x11, 0x1E, 0x11, 0x11, 0x1E],
    'C': [0x0E, 0x11, 0x10, 0x10, 0x10, 0x11, 0x0E],
    'D': [0x1C, 0x12, 0x11, 0x11, 0x11, 0x12, 0x1C],
    'E': [0x1F, 0x10, 0x10, 0x1E, 0x10, 0x10, 0x1F],
    'F': [0x1F, 0x10, 0x10, 0x1E, 0x10, 0x10, 0x10],
    'G': [0x0E, 0x11, 0x10, 0x17, 0x11, 0x11, 0x0F],
    'H': [0x11, 0x11, 0x11, 0x1F, 0x11, 0x11, 0x11],
    'I': [0x0E, 0x04, 0x04, 0x04, 0x04, 0x04, 0x0E],
    'J': [0x07, 0x02, 0x02, 0x02, 0x02, 0x12, 0x0C],
    'K': [0x11, 0x12, 0x14, 0x18, 0x14, 0x12, 0x11],
    'L': [0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x1F],
    'M': [0x11, 0x1B, 0x15, 0x15, 0x11, 0x11, 0x11],
    'N': [0x11, 0x19, 0x15, 0x13, 0x11, 0x11, 0x11],
    'O': [0x0E, 0x11, 0x11, 0x11, 0x11, 0x11, 0x0E],
    'P': [0x1E, 0x11, 0x11, 0x1E, 0x10, 0x10, 0x10],
    'Q': [0x0E, 0x11, 0x11, 0x11, 0x15, 0x12, 0x0D],
    'R': [0x1E, 0x11, 0x11, 0x1E, 0x14, 0x12, 0x11],
    'S': [0x0E, 0x11, 0x10, 0x0E, 0x01, 0x11, 0x0E],
    'T': [0x1F, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04],
    'U': [0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x0E],
    'V': [0x11, 0x11, 0x11, 0x11, 0x11, 0x0A, 0x04],
    'W': [0x11, 0x11, 0x11, 0x15, 0x15, 0x15, 0x0A],
    'X': [0x11, 0x11, 0x0A, 0x04, 0x0A, 0x11, 0x11],
    'Y': [0x11, 0x11, 0x0A, 0x04, 0x04, 0x04, 0x04],
    'Z': [0x1F, 0x01, 0x02, 0x04, 0x08, 0x10, 0x1F],
    '[': [0x0E, 0x08, 0x08, 0x08, 0x08, 0x08, 0x0E],
    '\\': [0x10, 0x08, 0x04, 0x02, 0x01, 0x00, 0x00],
    ']': [0x0E, 0x02, 0x02, 0x02, 0x02, 0x02, 0x0E],
    '^': [0x04, 0x0A, 0x11, 0x00, 0x00, 0x00, 0x00],
    '_': [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1F],
    '|': [0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04],
    'a': [0x00, 0x00, 0x0E, 0x01, 0x0F, 0x11, 0x0F],
    'b': [0x10, 0x10, 0x16, 0x19, 0x11, 0x11, 0x1E],
    'c': [0x00, 0x00, 0x0E, 0x11, 0x10, 0x11, 0x0E],
    'd': [0x01, 0x01, 0x0D, 0x13, 0x11, 0x11, 0x0F],
    'e': [0x00, 0x00, 0x0E, 0x11, 0x1F, 0x10, 0x0E],
    'f': [0x06, 0x09, 0x08, 0x1C, 0x08, 0x08, 0x08],
    'g': [0x00, 0x00, 0x0F, 0x11, 0x0F, 0x01, 0x0E],
    'h': [0x10, 0x10, 0x16, 0x19, 0x11, 0x11, 0x11],
    'i': [0x04, 0x00, 0x0C, 0x04, 0x04, 0x04, 0x0E],
    'j': [0x02, 0x00, 0x06, 0x02, 0x02, 0x12, 0x0C],
    'k': [0x10, 0x10, 0x12, 0x14, 0x18, 0x14, 0x12],
    'l': [0x0C, 0x04, 0x04, 0x04, 0x04, 0x04, 0x0E],
    'm': [0x00, 0x00, 0x1A, 0x15, 0x15, 0x11, 0x11],
    'n': [0x00, 0x00, 0x16, 0x19, 0x11, 0x11, 0x11],
    'o': [0x00, 0x00, 0x0E, 0x11, 0x11, 0x11, 0x0E],
    'p': [0x00, 0x00, 0x1E, 0x11, 0x1E, 0x10, 0x10],
    'q': [0x00, 0x00, 0x0D, 0x13, 0x0F, 0x01, 0x01],
    'r': [0x00, 0x00, 0x16, 0x19, 0x10, 0x10, 0x10],
    's': [0x00, 0x00, 0x0F, 0x10, 0x0E, 0x01, 0x1E],
    't': [0x08, 0x08, 0x1C, 0x08, 0x08, 0x09, 0x06],
    'u': [0x00, 0x00, 0x11, 0x11, 0x11, 0x13, 0x0D],
    'v': [0x00, 0x00, 0x11, 0x11, 0x11, 0x0A, 0x04],
    'w': [0x00, 0x00, 0x11, 0x11, 0x15, 0x15, 0x0A],
    'x': [0x00, 0x00, 0x11, 0x0A, 0x04, 0x0A, 0x11],
    'y': [0x00, 0x00, 0x11, 0x11, 0x0F, 0x01, 0x0E],
    'z': [0x00, 0x00, 0x1F, 0x02, 0x04, 0x08, 0x1F],
}

def draw_char(img, ch, x0, y0, scale=1, fg=(255, 255, 255)):
    glyph = FONT_5X7.get(ch, FONT_5X7.get('?'))
    img_h = len(img)
    img_w = len(img[0])
    for r_idx, row_bits in enumerate(glyph):
        for c_idx in range(5):
            if row_bits & (1 << (4 - c_idx)):
                px = x0 + c_idx * scale
                py = y0 + r_idx * scale
                for sy in range(scale):
                    for sx in range(scale):
                        iy = py + sy
                        ix = px + sx
                        if 0 <= iy < img_h and 0 <= ix < img_w:
                            img[iy][ix] = fg

def draw_text(img, text, x0, y0, scale=1, fg=(255, 255, 255)):
    cur_x = x0
    char_w = 6 * scale
    for ch in text:
        draw_char(img, ch, cur_x, y0, scale=scale, fg=fg)
        cur_x += char_w

def draw_box(img, x, y, w, h, fill_col=(16, 20, 28), border_col=(255, 215, 0), border_w=1):
    img_h = len(img)
    img_w = len(img[0])
    for py in range(y, y + h):
        if not (0 <= py < img_h):
            continue
        for px in range(x, x + w):
            if not (0 <= px < img_w):
                continue
            is_border = (px < x + border_w or px >= x + w - border_w or
                         py < y + border_w or py >= y + h - border_w)
            img[py][px] = border_col if is_border else fill_col

def draw_badge_segments(img, segments, x, y, scale=2, fill_col=(14, 16, 24), border_col=(255, 215, 0), border_w=1):
    char_w = 6 * scale
    char_h = 7 * scale
    pad_x = 4 * scale
    pad_y = 2 * scale

    total_chars = sum(len(text) for text, _ in segments)
    box_w = total_chars * char_w + pad_x * 2
    box_h = char_h + pad_y * 2

    draw_box(img, x, y, box_w, box_h, fill_col=fill_col, border_col=border_col, border_w=border_w)

    cur_x = x + pad_x
    cur_y = y + pad_y
    for text, color in segments:
        draw_text(img, text, cur_x, cur_y, scale=scale, fg=color)
        cur_x += len(text) * char_w

# -----------------------------------------------------------------------------
# Rendu Donjon
# -----------------------------------------------------------------------------
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

    if not rooms:
        print(f"  [!] Donjon {lvl} : aucune salle décodée (source de données absente), carte ignorée.")
        return

    r_coords = [(r % 16, r // 16) for r in rooms.keys()]
    min_rx = min(rx for rx, ry in r_coords)
    max_rx = max(rx for rx, ry in r_coords)
    min_ry = min(ry for rx, ry in r_coords)
    max_ry = max(ry for rx, ry in r_coords)

    span_x = max_rx - min_rx + 1
    span_y = max_ry - min_ry + 1

    room_w = 320
    room_h = 160
    map_w_px = span_x * room_w
    map_h_px = span_y * room_h
    full_img = [[(10, 10, 14)] * map_w_px for _ in range(map_h_px)]

    # 1. Rendu des tuiles de chaque salle
    for r, grid in rooms.items():
        rx, ry = r % 16, r // 16
        grid_x = (rx - min_rx) * room_w
        grid_y = (ry - min_ry) * room_h
        room_img = render_dungeon_room_rgb(grid, col_bg, col_mc1, col_mc2, col_ram)
        for y in range(room_h):
            for x in range(room_w):
                full_img[grid_y + y][grid_x + x] = room_img[y][x]

    # 2. Traits de découpage et badges de debug pour chaque salle existante
    for r in rooms.keys():
        rx, ry = r % 16, r // 16
        grid_x = (rx - min_rx) * room_w
        grid_y = (ry - min_ry) * room_h

        # Bordure de salle (traits de découpage 2px)
        border_col = (255, 215, 0) if r == ent else (70, 130, 200)
        for x in range(room_w):
            full_img[grid_y][grid_x + x] = border_col
            full_img[grid_y + 1][grid_x + x] = border_col
            full_img[grid_y + room_h - 1][grid_x + x] = border_col
            full_img[grid_y + room_h - 2][grid_x + x] = border_col
        for y in range(room_h):
            full_img[grid_y + y][grid_x] = border_col
            full_img[grid_y + y][grid_x + 1] = border_col
            full_img[grid_y + y][grid_x + room_w - 1] = border_col
            full_img[grid_y + y][grid_x + room_w - 2] = border_col

        # Badge debug en haut à gauche
        segments = [
            (f"[{rx},{ry}] ", (255, 220, 0)),
            (f"${r:02X}", (240, 240, 240)),
        ]
        if r == ent:
            segments.append((" [START]", (80, 255, 120)))

        draw_badge_segments(full_img, segments, grid_x + 6, grid_y + 6, scale=1,
                            fill_col=(10, 12, 18), border_col=border_col, border_w=1)

    write_png(out_path, full_img)
    print(f"  [+] Donjon {lvl} ({meta['name']}) rendu -> {out_path} ({map_w_px}x{map_h_px})")

# -----------------------------------------------------------------------------
# Rendu Overworld avec Découpage et Badges Debug
# -----------------------------------------------------------------------------
def render_overworld(out_path):
    tiles_txt = os.path.join(ASSETS_DIR, "tiles.txt")
    world_txt = os.path.join(ASSETS_DIR, "world.txt")
    cfg, tiles = parse_tiles(tiles_txt)
    rooms, rooms_x, rooms_y, grid = parse_world(world_txt, tiles)

    scale = 2
    room_zones = get_room_zones(rooms_x * rooms_y)

    # 1. Rendu graphique complet des tuiles (multicolore C64 scalé x2)
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

    img_h = len(pix)
    img_w = len(pix[0])

    room_w = 20 * 16 * scale  # 640 px
    room_h = 10 * 16 * scale  # 320 px

    # 2. Découpage avec des traits (Lignes de grille)
    col_grid_norm = (255, 215, 0)      # Or pour séparateurs de salle normaux
    col_grid_chunk = (0, 220, 255)     # Cyan lumineux pour séparateurs de CHUNK (ROM / streaming)
    col_edge = (0, 0, 0)               # Noir pour contraste maximal

    # Lignes verticales séparant chaque colonne (rx: 1..15)
    for rx in range(1, rooms_x):
        x = rx * room_w
        for y in range(img_h):
            pix[y][x - 1] = col_edge
            pix[y][x]     = col_grid_norm
            pix[y][x + 1] = col_edge

    # Lignes horizontales séparant chaque rangée (ry: 1..7)
    for ry in range(1, rooms_y):
        y = ry * room_h
        is_chunk_boundary = (ry in (2, 4, 6))

        if is_chunk_boundary:
            # Trait épais 5px cyan contrasté pour délimiter les 4 chunks Overworld
            for x in range(img_w):
                pix[y - 2][x] = col_edge
                pix[y - 1][x] = col_grid_chunk
                pix[y][x]     = (255, 255, 255)  # Coeur blanc
                pix[y + 1][x] = col_grid_chunk
                pix[y + 2][x] = col_edge
        else:
            # Trait 3px doré pour les séparateurs intra-chunk
            for x in range(img_w):
                pix[y - 1][x] = col_edge
                pix[y][x]     = col_grid_norm
                pix[y + 1][x] = col_edge

    # Cadre extérieur (bordure de la carte entière)
    for x in range(img_w):
        pix[0][x] = col_grid_chunk
        pix[1][x] = col_grid_chunk
        pix[img_h - 2][x] = col_grid_chunk
        pix[img_h - 1][x] = col_grid_chunk
    for y in range(img_h):
        pix[y][0] = col_grid_chunk
        pix[y][1] = col_grid_chunk
        pix[y][img_w - 2] = col_grid_chunk
        pix[y][img_w - 1] = col_grid_chunk

    # 3. Badges de debug dans CHAQUE salle (16x8 = 128 salles)
    # Affiche le xy (ex: D4, H8), le chunk (ex: Chunk 1) et l'index de salle
    for ry in range(rooms_y):
        for rx in range(rooms_x):
            room_idx = ry * rooms_x + rx
            col_letter = chr(ord('A') + rx)
            row_num = str(ry + 1)
            coord_str = f"{col_letter}{row_num}"
            chunk_num = ry // 2
            chunk_str = f"Chunk {chunk_num}"
            idx_str = f"#{room_idx:02d} (${room_idx:02X})"

            badge_x = rx * room_w + 8
            badge_y = ry * room_h + 6

            # Segments colorés : [XY] en Or, Chunk en Cyan, ID en Blanc
            segments = [
                (f"[{coord_str}] ", (255, 220, 0)),
                (f"{chunk_str} ", (80, 220, 255)),
                (idx_str, (240, 240, 240)),
            ]

            draw_badge_segments(pix, segments, badge_x, badge_y, scale=2,
                                fill_col=(12, 14, 22), border_col=(255, 215, 0), border_w=1)

    write_png(out_path, pix)
    print(f"  [+] Overworld complet (16x8 salles avec grille & badges debug) rendu -> {out_path} ({img_w}x{img_h})")

# -----------------------------------------------------------------------------
# Point d'entrée
# -----------------------------------------------------------------------------
def main():
    os.makedirs(BLD_DIR, exist_ok=True)
    print("[*] Génération des cartes PNG annotées (découpage & repères debug)...")

    # 1. Overworld
    ow_path = os.path.join(BLD_DIR, "map_overworld.png")
    render_overworld(ow_path)

    # 2. Donjons 1 à 9
    for lvl in range(1, 10):
        dung_path = os.path.join(BLD_DIR, f"map_dungeon_{lvl}.png")
        render_dungeon(lvl, dung_path)

    print("[✓] Toutes les cartes PNG avec découpage et repères debug sont prêtes dans build/ !")

if __name__ == "__main__":
    main()
