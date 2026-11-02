#!/usr/bin/env python3
"""
Capture updated screenshots for the 4 inventory pages:
- Page 0: Selectable B-Items Grid
- Page 1: Hardware Sprite Assembled Triforce
- Page 2: Link's Equipment & Relics
- Page 3: Full 16x8 Biome World Map
"""
import os
import subprocess
import time

BASE_DIR = "/home/vedix/Documents/C64/zelda"
DOCS_IMG_DIR = os.path.join(BASE_DIR, "docs/images")
ARTIFACT_DIR = "/home/vedix/.gemini/antigravity-cli/brain/948c3f56-813e-4558-8dcf-700117d0de02"

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

def main():
    labels = load_labels(os.path.join(BASE_DIR, "build/zelda.vs"))
    main_addr = labels['main_loop']
    cmd_addr = labels['debug_hook_cmd']
    arg_addr = labels['debug_hook_arg']
    arg2_addr = labels['debug_hook_arg2']

    sword_addr = labels['player_has_sword']
    shield_addr = labels['player_has_shield']
    ring_addr = labels['player_has_blue_ring']
    bracelet_addr = labels['player_has_bracelet']
    raft_addr = labels['player_has_raft']
    ladder_addr = labels['player_has_stepladder']
    key_addr = labels['player_has_magic_key']
    book_addr = labels['player_has_book']

    boom_addr = labels['player_has_boomerang']
    bow_addr = labels['player_has_bow']
    arrows_addr = labels['player_has_arrows']
    candle_addr = labels['player_has_candle']
    whistle_addr = labels['player_has_whistle']
    food_addr = labels['player_has_food']
    potion_addr = labels['player_has_potion']
    wand_addr = labels['player_has_wand']

    triforce_addr = labels['player_triforce_pieces']
    visited_addr = labels['visited_rooms']

    # 4 pages to capture
    pages = [
        (0, "gal_inv_items", "Inventory Page 0: Items"),
        (1, "gal_inv_triforce", "Inventory Page 1: Sprite-Assembled Triforce"),
        (2, "gal_inv_equipment", "Inventory Page 2: Equipment & Relics"),
        (3, "gal_inv_map", "Inventory Page 3: 16x8 Biome World Map")
    ]

    # Generate monitor script
    mon_file = "/tmp/capture_inv.mon"
    with open(mon_file, "w") as f:
        # Boot and skip intro
        f.write("bk 299b\n")
        f.write("g\n")
        f.write("del\n")
        f.write("> 0816 01\n") # Option 1 (1 SID)

        # Reach main_loop
        f.write(f"bk {main_addr:04x}\n")
        f.write("g\n")
        f.write("del\n")

        # Equip Link with full gear & items
        f.write(f"> {sword_addr:04x} 02\n")     # White Sword
        f.write(f"> {shield_addr:04x} 02\n")    # Magical Shield
        f.write(f"> {ring_addr:04x} 01\n")      # Blue Ring
        f.write(f"> {bracelet_addr:04x} 01\n")  # Power Bracelet
        f.write(f"> {raft_addr:04x} 01\n")      # Raft
        f.write(f"> {ladder_addr:04x} 01\n")    # Stepladder
        f.write(f"> {key_addr:04x} 01\n")       # Magic Key
        f.write(f"> {book_addr:04x} 01\n")      # Book of Magic

        f.write(f"> {boom_addr:04x} 01\n")      # Boomerang
        f.write(f"> {bow_addr:04x} 01\n")       # Bow
        f.write(f"> {arrows_addr:04x} 01\n")    # Arrows
        f.write(f"> {candle_addr:04x} 01\n")    # Blue Candle
        f.write(f"> {whistle_addr:04x} 01\n")   # Whistle
        f.write(f"> {food_addr:04x} 01\n")      # Food
        f.write(f"> {potion_addr:04x} 02\n")    # Red Potion
        f.write(f"> {wand_addr:04x} 01\n")      # Wand

        # Triforce pieces: 6 pieces (%00111111 = $3F) to demonstrate both assembled pieces and empty dais slots
        f.write(f"> {triforce_addr:04x} 3f\n")

        # Visited rooms: populate a rich selection of all 6 biomes
        visited_set = [
            0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, # Death Mountain (BROWN)
            0x0E, 0x0F, 0x1E, 0x2E, 0x3E, 0x46, 0x47, 0x7E, 0x7F, # Waters / Rivers / Ocean (LIGHT BLUE)
            0x20, 0x21, 0x30, 0x31, 0x40, 0x41, # Graveyard (DARK GREY)
            0x29, 0x2A, 0x2B, 0x3A, 0x3B, # Desert (YELLOW)
            0x51, 0x52, 0x53, 0x61, 0x62, 0x63, 0x72, 0x73, # Forest & Lost Woods (GREEN)
            0x24, 0x25, 0x4A, 0x64, 0x71, 0x76, 0x77 # Plains, Clearings & Start (LIGHT GREEN)
        ]
        for room_idx in visited_set:
            f.write(f"> {visited_addr + room_idx:04x} 01\n")

        # Now for each page, open inventory at that page, run a few frames, and take screenshot
        for page_num, base_name, desc in pages:
            out_path = f"/tmp/{base_name}.png"
            f.write(f"bk {main_addr:04x}\n")
            f.write(f"> {arg_addr:04x} {page_num:02x}\n")
            f.write(f"> {cmd_addr:04x} 03\n") # hook_inv_resident
            f.write("g\n")
            f.write("del\n")

            # Let the inventory frame render and stabilize (10 frames)
            for _ in range(10):
                f.write(f"bk {main_addr:04x}\n")
                f.write("g\n")
                f.write("del\n")

            f.write(f'screenshot "{out_path}" 2\n')

        f.write("quit\n")

    print("Running VICE in warp mode...")
    cmdline = [
        "x64sc",
        "-default",
        "-cartcrt", os.path.join(BASE_DIR, "build/zelda.crt"),
        "-warp",
        "-limitcycles", "100000000",
        "-moncommands", mon_file
    ]
    t0 = time.time()
    res = subprocess.run(cmdline, capture_output=True, text=True, timeout=120)
    print(f"VICE finished in {time.time() - t0:.1f}s.")

    # Convert any PCX to PNG if necessary
    for _, base_name, desc in pages:
        pcx_path = f"/tmp/{base_name}.pcx"
        png_path = f"/tmp/{base_name}.png"
        if os.path.exists(pcx_path):
            subprocess.run(["magick", pcx_path, png_path])
            os.remove(pcx_path)

        if os.path.exists(png_path):
            # Copy to docs/images
            dest_docs = os.path.join(DOCS_IMG_DIR, f"{base_name}.png")
            dest_art = os.path.join(ARTIFACT_DIR, f"{base_name}.png")
            subprocess.run(["cp", png_path, dest_docs])
            subprocess.run(["cp", png_path, dest_art])
            sz = os.path.getsize(dest_docs)
            print(f"Captured {base_name}.png ({sz} bytes) -> {dest_docs}")
        else:
            print(f"ERROR: {png_path} not created!")

if __name__ == "__main__":
    main()
