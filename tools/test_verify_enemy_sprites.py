#!/usr/bin/env python3
"""
tools/test_verify_enemy_sprites.py
Capture et vérifie les sprites authentiques NES en jeu sous VICE :
- Goriya (D1 room 0x45)
- Darknut (D3 room 0x5B)
- Aquamentus multi-sprites assemblé 24x32 (D1 room 0x35)
- Dodongo multi-sprites assemblé 32x16 (D2 room 0x0E)
- Manhandla multi-sprites assemblé (D3 room 0x4D)
- Ropes (D2 room 0x6E)
"""
import os
import subprocess
import sys
import time

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT_DIR = os.path.join(BASE_DIR, "screenshots")
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

SCENARIOS = [
    ("shot_test_goriya.png",     2, 1, 0x45, "Goriya (Dungeon 1 Room 0x45)"),
    ("shot_test_darknut.png",    2, 3, 0x5B, "Darknut Knights (Dungeon 3 Room 0x5B)"),
    ("shot_test_aquamentus.png", 2, 1, 0x35, "Boss Aquamentus 24x32 assemblé (Dungeon 1 Room 0x35)"),
    ("shot_test_dodongo.png",    2, 2, 0x0E, "Boss Dodongo 32x16 assemblé (Dungeon 2 Room 0x0E)"),
    ("shot_test_manhandla.png",  2, 3, 0x4D, "Boss Manhandla assemblé (Dungeon 3 Room 0x4D)"),
    ("shot_test_ropes.png",      2, 2, 0x6E, "Ropes serpents rapides (Dungeon 2 Room 0x6E)"),
]

def main():
    z_labels = load_labels(os.path.join(BASE_DIR, "build", "zelda.vs"))
    i_labels = load_labels(os.path.join(BASE_DIR, "build", "intro.vs"))

    cmd_addr = z_labels['debug_hook_cmd']
    arg_addr = z_labels['debug_hook_arg']
    arg2_addr = z_labels['debug_hook_arg2']
    main_addr = z_labels['main_loop']
    launch_addr = i_labels['launch_zelda_game']

    mon_file = "/tmp/zelda_verify_sprites.mon"
    with open(mon_file, "w") as f:
        f.write("break 080d\n")
        f.write("g\n")
        f.write(f"g {launch_addr:04x}\n")
        f.write(f"break {main_addr:04x}\n")
        f.write("g\n")

        for fname, cmd, arg1, arg2, desc in SCENARIOS:
            out_png = os.path.join(OUT_DIR, fname)
            f.write(f"> {arg2_addr:04x} {arg2:02x}\n")
            f.write(f"> {arg_addr:04x} {arg1:02x}\n")
            f.write(f"> {cmd_addr:04x} {cmd:02x}\n")
            for _ in range(8):
                f.write("g\n")
            f.write(f'screenshot "{out_png}" 2\n')

        f.write("quit\n")

    cmdline = [
        "x64sc",
        "-default",
        "-cartcrt", "build/zelda.crt",
        "-warp",
        "-limitcycles", "100000000",
        "-moncommands", mon_file
    ]
    print("Exécution de VICE en mode warp pour capturer les scènes de validation...")
    t0 = time.time()
    res = subprocess.run(cmdline, capture_output=True, text=True, timeout=120)
    print(f"VICE terminé en {time.time() - t0:.1f}s.")

    # Convert .pcx to .png if needed
    for f in os.listdir(OUT_DIR):
        if f.endswith(".pcx"):
            p = os.path.join(OUT_DIR, f)
            subprocess.run(["magick", p, p[:-4]])
            os.remove(p)

    print("\n--- RÉSULTATS DES CAPTURES ---")
    for fname, _, _, _, desc in SCENARIOS:
        p = os.path.join(OUT_DIR, fname)
        if os.path.exists(p):
            sz = os.path.getsize(p)
            print(f"  [✓] {fname} ({sz} octets) : {desc}")
        else:
            print(f"  [✗] MANQUANT : {fname}")

if __name__ == "__main__":
    main()
