#!/usr/bin/env python3
"""
Test rendering of authentic NES Dungeon 1 tiles and rooms to verify match with 1.png.
"""
import sys
import os
sys.path.insert(0, 'tools')
from sprgen import write_png
from tilegen import PALETTE, PIX, char_bytes

# C64 Colors for Dungeon 1:
# Background ($D021): Black (0)
# MC1 ($D022): Cyan (3)
# MC2 ($D023): Light Blue (14)
# Color RAM: Blue (6) or White (1)
COL_BG = 0
COL_MC1 = 3
COL_MC2 = 14
COL_RAM = 6

# ASCII art for the 16 dungeon tiles (8 chars wide x 16 lines high):
TILES_ART = {
    # 0: Floor (Sol en dalles de pierre avec joints)
    0: [
        "11111111",
        "1......1",
        "1......1",
        "1......1",
        "1......1",
        "1......1",
        "1......1",
        "11111111",
        "11111111",
        "1......1",
        "1......1",
        "1......1",
        "1......1",
        "1......1",
        "1......1",
        "11111111",
    ],
    # 1: Wall Top (Mur supérieur horizontal)
    1: [
        "22222222",
        "21112111",
        "21112111",
        "22222222",
        "12111211",
        "12111211",
        "22222222",
        "........",
        "22222222",
        "21112111",
        "21112111",
        "22222222",
        "12111211",
        "12111211",
        "22222222",
        "........",
    ],
    # 2: Wall Bottom (Mur inférieur horizontal)
    2: [
        "........",
        "22222222",
        "21112111",
        "21112111",
        "22222222",
        "12111211",
        "12111211",
        "22222222",
        "........",
        "22222222",
        "21112111",
        "21112111",
        "22222222",
        "12111211",
        "12111211",
        "22222222",
    ],
    # 3: Wall Left (Mur gauche vertical)
    3: [
        "2112211.",
        "2112211.",
        "2112211.",
        "2222222.",
        "2112211.",
        "2112211.",
        "2112211.",
        "2222222.",
        "2112211.",
        "2112211.",
        "2112211.",
        "2222222.",
        "2112211.",
        "2112211.",
        "2112211.",
        "2222222.",
    ],
    # 4: Wall Right (Mur droit vertical)
    4: [
        ".1122112",
        ".1122112",
        ".1122112",
        ".2222222",
        ".1122112",
        ".1122112",
        ".1122112",
        ".2222222",
        ".1122112",
        ".1122112",
        ".1122112",
        ".2222222",
        ".1122112",
        ".1122112",
        ".1122112",
        ".2222222",
    ],
    # 5: Diamond Block (Bloc diamant bevelle 3D authentique NES)
    5: [
        "........",
        "..2222..",
        ".22222c.",
        ".2211cc.",
        ".21111c.",
        ".21111c.",
        ".21111c.",
        ".2c11cc.",
        ".2cc1cc.",
        ".2ccccc.",
        "..cccc..",
        "........",
        "........",
        "........",
        "........",
        "........",
    ],
    # 6: Statue (Statue dragon sculptée authentique NES)
    6: [
        "..2112..",
        ".211112.",
        "21c11c12",
        "21c11c12",
        "21111112",
        ".211112.",
        ".212212.",
        ".211112.",
        "21c11c12",
        "21122112",
        "21111112",
        ".211112.",
        "..2112..",
        "..2112..",
        "..2112..",
        "........",
    ],
    # 7: Stairs (Escalier secret descendant)
    7: [
        "22222222",
        "2......2",
        "2.2222.2",
        "2.2..2.2",
        "2.2.c2.2",
        "2.2.c2.2",
        "2.2.c2.2",
        "2.2.c2.2",
        "2.2.c2.2",
        "2.2.c2.2",
        "2.2.c2.2",
        "2.2..2.2",
        "2.2222.2",
        "2......2",
        "22222222",
        "........",
    ],
    # 8: Corner Top-Left (Biseau 45° haut-gauche)
    8: [
        "22222222",
        "22222221",
        "22222211",
        "2222211.",
        "222211..",
        "22211...",
        "2211....",
        "211.....",
        "21......",
        "11......",
        "1.......",
        "........",
        "........",
        "........",
        "........",
        "........",
    ],
    # 9: Corner Top-Right (Biseau 45° haut-droit)
    9: [
        "22222222",
        "12222222",
        "11222222",
        ".1122222",
        "..112222",
        "...11222",
        "....1122",
        ".....112",
        "......12",
        "......11",
        ".......1",
        "........",
        "........",
        "........",
        "........",
        "........",
    ],
    # 10: Corner Bottom-Left (Biseau 45° bas-gauche)
    10: [
        "........",
        "........",
        "........",
        "........",
        "........",
        "........",
        "1.......",
        "11......",
        "21......",
        "211.....",
        "2211....",
        "22211...",
        "222211..",
        "2222211.",
        "22222211",
        "22222222",
    ],
    # 11: Corner Bottom-Right (Biseau 45° bas-droit)
    11: [
        "........",
        "........",
        "........",
        "........",
        "........",
        "........",
        ".......1",
        "......11",
        "......12",
        ".....112",
        "....1122",
        "...11222",
        "..112222",
        ".1122222",
        "11222222",
        "22222222",
    ],
    # 12: Door Open (Passage voûté ouvert dans le mur)
    12: [
        "........",
        "........",
        "........",
        "........",
        "........",
        "........",
        "........",
        "........",
        "........",
        "........",
        "........",
        "........",
        "........",
        "........",
        "........",
        "........",
    ],
    # 13: Door Locked (Porte verrouillée avec trou de serrure)
    13: [
        "22222222",
        "21111112",
        "21111112",
        "21111112",
        "21122112",
        "212..212",
        "212..212",
        "21122112",
        "211..112",
        "211..112",
        "211..112",
        "21111112",
        "21111112",
        "21111112",
        "21111112",
        "22222222",
    ],
    # 14: Door Shutter (Porte à volet / grille métallique)
    14: [
        "22222222",
        "2.2.2.2.",
        "2.2.2.2.",
        "22222222",
        "2.2.2.2.",
        "2.2.2.2.",
        "22222222",
        "2.2.2.2.",
        "2.2.2.2.",
        "22222222",
        "2.2.2.2.",
        "2.2.2.2.",
        "22222222",
        "2.2.2.2.",
        "2.2.2.2.",
        "22222222",
    ],
    # 15: Door Bomb (Mur fissuré / bombe)
    15: [
        "22222222",
        "21.12111",
        "21.12111",
        "22..2222",
        "121..211",
        "121.1211",
        "222..222",
        "....1...",
        "222.1222",
        "21.12111",
        "21.12111",
        "22..2222",
        "121..211",
        "1211.211",
        "2222.222",
        "........",
    ]
}

# Function to render a 20x10 tile room into a 320x160 RGB image
def render_room(room_grid):
    # Width = 20 tiles * 16 px = 320 px
    # Height = 10 tiles * 16 px = 160 px
    img_data = [[(0,0,0)] * 320 for _ in range(160)]
    palette_map = {
        0: PALETTE[COL_BG],
        1: PALETTE[COL_MC1],
        2: PALETTE[COL_MC2],
        3: PALETTE[COL_RAM],
    }

    for ty in range(10):
        for tx in range(20):
            tile_id = room_grid[ty][tx]
            art = TILES_ART.get(tile_id, TILES_ART[0])
            for py in range(16):
                row_str = art[py]
                for px in range(8):
                    p_val = PIX[row_str[px]]
                    color = palette_map[p_val]
                    # Double wide pixels on C64:
                    img_data[ty * 16 + py][tx * 16 + px * 2] = color
                    img_data[ty * 16 + py][tx * 16 + px * 2 + 1] = color

    return img_data

# Test Room 0x73 (Entrance)
def make_room_73():
    # Outer frame:
    # Row 0: 8 (corner_tl), 1*8 (wall_top), 13, 13 (LOCKED DOOR NORTH), 1*8 (wall_top), 9 (corner_tr)
    # Row 9: 10 (corner_bl), 2*8 (wall_bot), 12, 12 (OPEN DOOR SOUTH to OW), 2*8 (wall_bot), 11 (corner_br)
    grid = []
    # Row 0
    grid.append([8] + [1]*8 + [13, 13] + [1]*8 + [9])
    # Rows 1..8
    for y in range(1, 9):
        row = [0] * 20
        # West and East doors at rows 4, 5
        if y in (4, 5):
            row[0] = 12   # Open door West
            row[19] = 12  # Open door East
        else:
            row[0] = 3    # Wall left
            row[19] = 4   # Wall right
        grid.append(row)
    # Row 9
    grid.append([10] + [2]*8 + [12, 12] + [2]*8 + [11])

    # Place 6 dragon statues: (cols 5, 8, 11, 14 at rows 2, 4, 6)
    for ry in (2, 4, 6):
        grid[ry][5] = 6
        grid[ry][8] = 6
        grid[ry][11] = 6
        grid[ry][14] = 6

    return grid

grid73 = make_room_73()
img73 = render_room(grid73)
write_png('build/preview_dung1_room73.png', img73)
print('build/preview_dung1_room73.png successfully written!')

