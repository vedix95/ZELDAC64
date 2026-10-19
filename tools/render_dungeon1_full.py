#!/usr/bin/env python3
"""
tools/render_dungeon1_full.py - Renders the authentic NES Level 1 Dungeon for C64
and generates a comparison image with 1.png.
"""
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "tools"))
from sprgen import write_png
from tilegen import PALETTE, PIX

# C64 Colors for Dungeon 1:
COL_BG = 0      # Black
COL_MC1 = 3     # Cyan
COL_MC2 = 14    # Light Blue
COL_RAM = 6     # Blue

# ASCII art for the 16 dungeon tiles (8 multicolor chars wide x 16 lines high):
# Symbols:
# '.' = 0 (Background = Black)
# '1' = 1 (MC1 = Cyan)
# '2' = 2 (MC2 = Light Blue)
# 'c' = 3 (Color RAM = Blue)

TILES_ART = {
    # 0: Floor slab (authentic NES floor with fine joint lines)
    0: [
        "........",
        ".1111111",
        ".1111111",
        ".1111111",
        ".1111111",
        ".1111111",
        ".1111111",
        ".1111111",
        "........",
        ".1111111",
        ".1111111",
        ".1111111",
        ".1111111",
        ".1111111",
        ".1111111",
        ".1111111",
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
        "21112111",
        "21112111",
        "22222222",
        "12111211",
        "12111211",
        "22222222",
        "21112111",
        "21112111",
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
        "21112111",
        "21112111",
        "22222222",
        "12111211",
        "12111211",
        "22222222",
        "21112111",
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

    # 6: Dragon Statue (Statue dragon sculptée authentique NES)
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

    # 12: Door Open (Passage voûté ouvert)
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

    # 13: Door Locked (Porte avec trou de serrure)
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

def render_room_rgb(room_grid):
    img = [[(0, 0, 0)] * 320 for _ in range(160)]
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
                    img[ty * 16 + py][tx * 16 + px * 2] = color
                    img[ty * 16 + py][tx * 16 + px * 2 + 1] = color

    return img

def decode_nes_level1():
    candidates = [
        "zelda.nes",
        os.path.join(os.path.dirname(__file__), "..", "zelda.nes"),
        os.path.join(os.path.dirname(__file__), "zelda.nes"),
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

    ns_doors_16 = rom[0x18700 : 0x18780]
    ew_doors_16 = rom[0x18780 : 0x18800]
    room_types = rom[0x18880 : 0x18900]
    monsters = rom[0x18800 : 0x18880]

    # Map from NES tile byte to our 16 tile indices:
    # 0x74: floor -> 0
    # 0x68: sand/path -> 0 (floor)
    # 0xb0: diamond block -> 5
    # 0x94, 0xb4: dragon statue -> 6
    # 0x70: stairs -> 7
    # 0xf4: labyrinth wall -> 5
    # 0x24: black void / room floor -> 0
    T_INNER = {
        0x74: 0,
        0x68: 0,
        0xb0: 5,
        0x94: 6,
        0xb4: 6,
        0x70: 7,
        0xf4: 5,
        0x24: 0,
    }

    def door_code_to_tile(code, is_horizontal=True):
        if code == 0:
            return 12  # Open
        elif code == 1:
            return 1 if is_horizontal else 3  # Solid wall
        elif code == 4:
            # Bombable cracked wall (or shutter)
            return 15  # Bombable
        elif code == 5:
            return 13  # Locked
        elif code == 7:
            return 14  # Shutter
        return 1 if is_horizontal else 3

    LEVEL1_ROOMS = [0x22, 0x23, 0x33, 0x35, 0x36, 0x41, 0x42, 0x43, 0x44, 0x45, 0x52, 0x53, 0x54, 0x63, 0x72, 0x73, 0x74]

    decoded_rooms = {}
    for r in LEVEL1_ROOMS:
        rt = room_types[r] & 0x3F
        ns = ns_doors_16[r]
        ew = ew_doors_16[r]
        nd = (ns >> 5) & 7
        sd = (ns >> 2) & 7
        wd = (ew >> 5) & 7
        ed = (ew >> 2) & 7

        r_def = rom[0x160DE + rt*12 : 0x160DE + (rt+1)*12]
        inner_cols = [decode_column(b) for b in r_def]

        # In room 0x53, North door is shutter code 4 (not bomb)
        # In room 0x43, South door is shutter code 4
        # In room 0x54, North door is bomb code 4
        # In room 0x44, South door is bomb code 4
        n_tile = 14 if (r == 0x53 and nd == 4) else door_code_to_tile(nd, True)
        s_tile = 14 if (r == 0x43 and sd == 4) else door_code_to_tile(sd, True)
        w_tile = door_code_to_tile(wd, False)
        e_tile = door_code_to_tile(ed, False)

        # Build 20x10 grid
        grid = []
        # Row 0: Top wall with 45° beveled corners
        row0 = [8] + [1]*8 + [n_tile, n_tile] + [1]*8 + [9]
        grid.append(row0)

        # Rows 1..7: Inner 12 columns x 7 rows
        for y in range(7):
            row = [0] * 20
            # Border columns 0..3 (Left wall / door)
            if y in (3, 4) and wd != 1:
                row[0] = w_tile
                row[1] = 0
                row[2] = 0
                row[3] = 0
            else:
                row[0] = 3
                row[1] = 3
                row[2] = 0
                row[3] = 0

            # Inner 12 columns (cols 4..15)
            for x in range(12):
                val = inner_cols[x][y]
                tile_val = T_INNER.get(val, 0)
                if r == 0x22 and tile_val == 7:
                    tile_val = 5  # Hide stairs as diamond block until pushed
                row[4 + x] = tile_val

            # Border columns 16..19 (Right wall / door)
            if y in (3, 4) and ed != 1:
                row[16] = 0
                row[17] = 0
                row[18] = 0
                row[19] = e_tile
            else:
                row[16] = 0
                row[17] = 0
                row[18] = 4
                row[19] = 4
            grid.append(row)

        # Row 8: Circulation threshold before south door
        row8 = [3, 3] + [0]*16 + [4, 4]
        grid.append(row8)

        # Row 9: Bottom wall with 45° beveled corners
        row9 = [10] + [2]*8 + [s_tile, s_tile] + [2]*8 + [11]
        grid.append(row9)

        decoded_rooms[r] = grid

    return decoded_rooms

def main():
    print("[*] Decoding authentic Level 1 rooms...")
    rooms = decode_nes_level1()

    # Create composite map of Eagle (6 columns x 6 rows)
    # rx ranges from 1 to 6 (col 1=0x41, col 2=0x22/0x42/0x52/0x72, col 3=0x23/0x33/0x43/0x53/0x63/0x73, col 4=0x44/0x54/0x74, col 5=0x35/0x45, col 6=0x36)
    # ry ranges from 2 to 7 (2=row 0, 3=row 1, 4=row 2, 5=row 3, 6=row 4, 7=row 5)
    map_w_px = 6 * 320
    map_h_px = 6 * 160
    full_img = [[(0, 0, 0)] * map_w_px for _ in range(map_h_px)]

    for r, grid in rooms.items():
        rx, ry = r % 16, r // 16
        # Offset in composite grid:
        grid_x = (rx - 1) * 320
        grid_y = (ry - 2) * 160
        room_img = render_room_rgb(grid)
        for y in range(160):
            for x in range(320):
                full_img[grid_y + y][grid_x + x] = room_img[y][x]

    out_path = "build/preview_dung1_eagle_full.png"
    write_png(out_path, full_img)
    print(f"[+] Full Level 1 Eagle rendered to {out_path} ({map_w_px}x{map_h_px})!")

if __name__ == "__main__":
    main()

