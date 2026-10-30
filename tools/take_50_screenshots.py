#!/usr/bin/env python3
"""
take_50_screenshots.py
Captures 50 screenshots of the game across:
- 20 Overworld locations (different zones, terrains, dungeon entrances)
- 22 Dungeon rooms (Dungeons 1 to 9, bosses, treasures, common rooms)
- 4 Inventory subscreen pages
- 3 Debug menu pages
- 1 Active item scene
"""

import os
import subprocess
import sys
import time

OUT_DIR = os.path.abspath("screenshots")
os.makedirs(OUT_DIR, exist_ok=True)

def load_labels(vs_path):
    labels = {}
    with open(vs_path) as f:
        for line in f:
            parts = line.strip().split()
            if len(parts) >= 3 and parts[0] == 'al':
                addr = int(parts[1].split(':')[-1], 16)
                name = parts[2].lstrip('.')
                labels[name] = addr
    return labels

# 50 scenarios definitions: (filename, hook_cmd, hook_arg, hook_arg2, description)
# hook_cmd:
# 1 = Warp Overworld (arg = room_idx $00..$7F)
# 2 = Warp Dungeon (arg = dung_level 1..9, arg2 = room $00..$7F or 0 for start)
# 3 = Open Inventory (arg = page 0..3)
# 4 = Open Debug (arg = page 0..2)
# 5 = Use Item B (arg = item_id 0..7)

SCENARIOS = [
    # --- 20 Overworld Locations ---
    ("shot_01_ow_start.png", 1, 0x77, 0, "OW Starting Room (Zone 0, Room 7,7)"),
    ("shot_02_ow_coast.png", 1, 0x7F, 0, "OW Coastline (Zone 0, Room 15,7)"),
    ("shot_03_ow_forest_trees.png", 1, 0x62, 0, "OW Deep Forest (Zone 0, Room 2,6)"),
    ("shot_04_ow_clearing.png", 1, 0x67, 0, "OW Green Clearing (Zone 0, Room 7,6)"),
    ("shot_05_ow_lake.png", 1, 0x56, 0, "OW Large Lake (Zone 0, Room 6,5)"),
    ("shot_06_ow_graveyard.png", 1, 0x41, 0, "OW Graveyard with Ghinis (Zone 2, Room 1,4)"),
    ("shot_07_ow_lost_woods.png", 1, 0x52, 0, "OW Lost Woods (Zone 3, Room 2,5)"),
    ("shot_08_ow_desert.png", 1, 0x24, 0, "OW Desert Sands (Zone 1, Room 4,2)"),
    ("shot_09_ow_waterfall.png", 1, 0x1E, 0, "OW Waterfall Basin (Zone 3, Room 14,1)"),
    ("shot_10_ow_death_mountain.png", 1, 0x05, 0, "OW Death Mountain Foothills (Zone 1, Room 5,0)"),
    ("shot_11_ow_dung1_entrance.png", 1, 0x37, 0, "OW Dungeon 1 Eagle Entrance (Tree bridge)"),
    ("shot_12_ow_dung2_entrance.png", 1, 0x3C, 0, "OW Dungeon 2 Moon Entrance"),
    ("shot_13_ow_dung3_entrance.png", 1, 0x74, 0, "OW Dungeon 3 Manji Entrance"),
    ("shot_14_ow_dung4_entrance.png", 1, 0x45, 0, "OW Dungeon 4 Snake Entrance"),
    ("shot_15_ow_dung5_entrance.png", 1, 0x1C, 0, "OW Dungeon 5 Lizard Entrance"),
    ("shot_16_ow_dung6_entrance.png", 1, 0x22, 0, "OW Dungeon 6 Dragon Entrance"),
    ("shot_17_ow_dung7_entrance.png", 1, 0x24, 0, "OW Dungeon 7 Demon Entrance"),
    ("shot_18_ow_dung8_entrance.png", 1, 0x6D, 0, "OW Dungeon 8 Lion Entrance"),
    ("shot_19_ow_dung9_entrance.png", 1, 0x05, 0, "OW Dungeon 9 Death Mountain Entrance"),
    ("shot_20_ow_fairy_fountain.png", 1, 0x78, 0, "OW Fairy Fountain pond (Room 8,7)"),

    # --- 22 Dungeon Locations (Levels 1 to 9) ---
    ("shot_21_dung1_entrance.png", 2, 1, 0x00, "Dungeon 1 Entrance room"),
    ("shot_22_dung1_stalfos.png", 2, 1, 0x22, "Dungeon 1 Stalfos room with Key"),
    ("shot_23_dung1_keese.png", 2, 1, 0x74, "Dungeon 1 Keese bats room"),
    ("shot_24_dung1_goriya.png", 2, 1, 0x45, "Dungeon 1 Goriya boomerangs room"),
    ("shot_25_dung1_aquamentus.png", 2, 1, 0x35, "Dungeon 1 Boss Aquamentus Dragon"),
    ("shot_26_dung1_triforce.png", 2, 1, 0x36, "Dungeon 1 Triforce Chamber"),
    ("shot_27_dung2_entrance.png", 2, 2, 0x00, "Dungeon 2 Moon Entrance"),
    ("shot_28_dung2_ropes.png", 2, 2, 0x6E, "Dungeon 2 Rope Snakes room"),
    ("shot_29_dung2_dodongo.png", 2, 2, 0x0E, "Dungeon 2 Boss Dodongo"),
    ("shot_30_dung3_entrance.png", 2, 3, 0x00, "Dungeon 3 Manji Entrance"),
    ("shot_31_dung3_darknuts.png", 2, 3, 0x5B, "Dungeon 3 Darknut Knights room"),
    ("shot_32_dung3_manhandla.png", 2, 3, 0x4D, "Dungeon 3 Boss Manhandla 4-heads"),
    ("shot_33_dung4_entrance.png", 2, 4, 0x00, "Dungeon 4 Snake Entrance"),
    ("shot_34_dung4_gleeok.png", 2, 4, 0x13, "Dungeon 4 Boss Gleeok 2-headed Dragon"),
    ("shot_35_dung5_entrance.png", 2, 5, 0x00, "Dungeon 5 Lizard Entrance"),
    ("shot_36_dung5_digdogger.png", 2, 5, 0x24, "Dungeon 5 Boss Digdogger Urchin"),
    ("shot_37_dung6_entrance.png", 2, 6, 0x00, "Dungeon 6 Dragon Entrance"),
    ("shot_38_dung6_gohma.png", 2, 6, 0x1C, "Dungeon 6 Boss Gohma One-Eyed Spider"),
    ("shot_39_dung7_entrance.png", 2, 7, 0x00, "Dungeon 7 Demon Entrance"),
    ("shot_40_dung8_entrance.png", 2, 8, 0x00, "Dungeon 8 Lion Entrance"),
    ("shot_41_dung9_entrance.png", 2, 9, 0x00, "Dungeon 9 Death Mountain Entrance"),
    ("shot_42_dung9_ganon.png", 2, 9, 0x42, "Dungeon 9 Ganon's Inner Lair"),

    # --- 4 Inventory Pages ---
    ("shot_43_inv_page0_items.png", 3, 0, 0, "Inventory Page 0: Selectable B-Items Grid"),
    ("shot_44_inv_page1_triforce.png", 3, 1, 0, "Inventory Page 1: Triforce Triangle Fragments"),
    ("shot_45_inv_page2_equipment.png", 3, 2, 0, "Inventory Page 2: Link's Equipment & Relics"),
    ("shot_46_inv_page3_worldmap.png", 3, 3, 0, "Inventory Page 3: Full 16x8 Hyrule World Map"),

    # --- 3 Debug Menu Pages ---
    ("shot_47_debug_p0_teleport.png", 4, 0, 0, "Debug Menu Page 0: Dungeon & OW Teleporter"),
    ("shot_48_debug_p1_cheats.png", 4, 1, 0, "Debug Menu Page 1: Cheats & Stats Modifier"),
    ("shot_49_debug_p2_hardware.png", 4, 2, 0, "Debug Menu Page 2: Memory & Hardware Diagnostics"),

    # --- 1 Item Action Scene ---
    ("shot_50_item_bomb_active.png", 5, 1, 0, "Active Secondary Item: Bomb Placed in Overworld")
]

def main():
    labels = load_labels("build/zelda.vs")
    cmd_addr = labels['debug_hook_cmd']
    arg_addr = labels['debug_hook_arg']
    arg2_addr = labels['debug_hook_arg2']
    main_addr = labels['main_loop']

    print(f"Loaded symbols from build/zelda.vs:")
    print(f"  main_loop:      ${main_addr:04X}")
    print(f"  debug_hook_cmd: ${cmd_addr:04X}")
    print(f"  debug_hook_arg: ${arg_addr:04X}")
    print(f"  debug_hook_arg2:${arg2_addr:04X}")

    print(f"\nGenerating monitor command script for all {len(SCENARIOS)} screenshots...")
    mon_file = "/tmp/zelda_50_shots.mon"
    with open(mon_file, "w") as f:
        # Initial breakpoint at main_loop ($1045)
        f.write("break 080d\n")
        f.write("g\n")
        f.write("g 55c2\n")
        f.write(f"break {main_addr:04x}\n")
        f.write("g\n")

        for fname, cmd, arg1, arg2, desc in SCENARIOS:
            out_png = os.path.join(OUT_DIR, fname)
            f.write(f"> {arg2_addr:04x} {arg2:02x}\n")
            f.write(f"> {arg_addr:04x} {arg1:02x}\n")
            f.write(f"> {cmd_addr:04x} {cmd:02x}\n")
            for _ in range(5):
                f.write("g\n")
            f.write(f'screenshot "{out_png}" 2\n')

        f.write("quit\n")

    cmdline = [
        "x64sc",
        "-default",
        "-cartcrt", "build/zelda.crt",
        "-warp",
        "-limitcycles", "200000000",
        "-moncommands", mon_file
    ]
    print("Executing VICE in warp mode to capture all 50 screenshots...")
    t0 = time.time()
    res = subprocess.run(cmdline, capture_output=True, text=True, timeout=300)
    elapsed = time.time() - t0
    print(f"VICE finished in {elapsed:.1f}s.")

    for f in os.listdir(OUT_DIR):
        if f.endswith(".pcx"):
            p = os.path.join(OUT_DIR, f)
            subprocess.run(["magick", p, p[:-4]])
            os.remove(p)
    files = sorted([f for f in os.listdir(OUT_DIR) if f.endswith(".png")])
    print(f"\nSuccessfully generated {len(files)} screenshots out of {len(SCENARIOS)}!")
    for f in files:
        size = os.path.getsize(os.path.join(OUT_DIR, f))
        print(f"  {f} ({size} bytes)")

if __name__ == "__main__":
    main()
