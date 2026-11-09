#!/usr/bin/env python3
"""
tools/test_armos_feature.py - Valide les statues Armos en émulation VICE :
1. Salle 36 (E-3) : statues Armos immobiles sur l'herbe
2. Link s'approche et touche la statue Armos en haut à droite (tx=16, ty=4)
3. La statue s'éveille et commence à se déplacer
4. L'escalier secret (TILE_CAVE) apparaît sous la statue
5. Le Bracelet de Force est octroyé
"""

import subprocess
import os
import time

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
CONV_ID = "365f32a0-f74f-4db0-9615-3c00e08c47af"
OUT_DIR = os.path.join("/home/vedix/.gemini/antigravity-cli/brain", CONV_ID, "screenshots")
os.makedirs(OUT_DIR, exist_ok=True)


def load_labels(vs_path):
    labels = {}
    with open(vs_path) as f:
        for line in f:
            parts = line.strip().split()
            if len(parts) >= 3 and parts[0] == "al":
                addr = int(parts[1].split(":")[-1], 16)
                name = parts[2].lstrip(".")
                labels[name] = addr
    return labels


labels = load_labels(os.path.join(BASE_DIR, "build", "zelda.vs"))
intro_labels = load_labels(os.path.join(BASE_DIR, "build", "intro.vs"))

cmd_addr = labels["debug_hook_cmd"]
arg_addr = labels["debug_hook_arg"]
arg2_addr = labels["debug_hook_arg2"]
main_addr = labels["main_loop"]
px_addr = labels["player_x"]
py_addr = labels["player_y"]
pdir_addr = labels["player_dir"]
brace_addr = labels["player_has_bracelet"]
launch_addr = intro_labels["launch_zelda_game"]

mon_file = "/tmp/test_armos.mon"
with open(mon_file, "w") as f:
    # 1. Boot cartouche et passage direct au jeu
    f.write("break 080d\n")
    f.write("g\n")
    f.write(f"g {launch_addr:04x}\n")
    f.write(f"break {main_addr:04x}\n")
    f.write("g\n")

    # 2. Warp en Salle 36 (E-3 / $24)
    # Link apparaît au centre en bas
    f.write(f"> {arg2_addr:04x} 00\n")
    f.write(f"> {arg_addr:04x} 24\n")
    f.write(f"> {cmd_addr:04x} 01\n")
    for _ in range(10):
        f.write("g\n")
    f.write(f'screenshot "{os.path.join(OUT_DIR, "armos_01_sleeping_statues.png")}" 2\n')

    # 3. Positionner Link touchant la statue en haut à droite (tx=16, ty=4 -> X=276, Y=144)
    # On place Link juste en dessous à X=276, Y=152, marchant vers le haut
    f.write(f"> {px_addr:04x} 14 01\n")   # X = 276 ($0114)
    f.write(f"> {py_addr:04x} 98\n")      # Y = 152 ($98)
    f.write(f"> {pdir_addr:04x} 01\n")    # DIR_UP (1)
    # Laisse tourner plusieurs frames pour que la boucle de jeu et AI_STATUE s'exécutent
    for _ in range(30):
        f.write("g\n")
    f.write(f'screenshot "{os.path.join(OUT_DIR, "armos_02_awakened_secret.png")}" 2\n')
    f.write(f"m {brace_addr:04x} {brace_addr:04x}\n")

    f.write("quit\n")

cmdline = [
    "x64sc",
    "-default",
    "-cartcrt", os.path.join(BASE_DIR, "build", "zelda.crt"),
    "-warp",
    "-limitcycles", "250000000",
    "-moncommands", mon_file
]
print("Running VICE test for Armos...")
t0 = time.time()
res = subprocess.run(cmdline, capture_output=True, text=True, timeout=60)
elapsed = time.time() - t0
print(f"VICE finished in {elapsed:.1f}s")

for fname in ["armos_01_sleeping_statues.png", "armos_02_awakened_secret.png"]:
    pcx = os.path.join(OUT_DIR, fname + ".pcx")
    png = os.path.join(OUT_DIR, fname)
    if os.path.exists(pcx):
        subprocess.run(["magick", pcx, png], check=True)
        os.remove(pcx)
    if os.path.exists(png):
        print(f"✓ OK: {fname} ({os.path.getsize(png)} bytes)")
    else:
        print(f"✗ MANQUANT: {fname}")

out = res.stdout
for line in out.splitlines():
    if ">C:" in line or "m " in line:
        print(line)
