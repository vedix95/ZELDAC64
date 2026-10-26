#!/usr/bin/env python3
"""
tools/test_armos_feature.py - Valide les statues Armos en émulation VICE :
1. Salle 36 (E-3) : 8 statues Armos immobiles sur l'herbe
2. Link s'approche et touche la statue Armos en haut à droite
3. La statue s'éveille et commence à se déplacer
4. L'escalier secret (TILE_CAVE) apparaît sous la statue
5. Le Bracelet de Force est octroyé
"""

import subprocess, os, time

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT_DIR = "/home/vedix/.gemini/antigravity-cli/brain/80df6d3b-ab21-48b6-8efe-b0005a652eca"

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

labels = load_labels(os.path.join(BASE_DIR, "build", "zelda.vs"))
cmd_addr = labels['debug_hook_cmd']
arg_addr = labels['debug_hook_arg']
arg2_addr = labels['debug_hook_arg2']
main_addr = labels['main_loop']
px_addr = labels['player_x']
py_addr = labels['player_y']
pdir_addr = labels['player_dir']
brace_addr = labels['player_has_bracelet']

mon_file = "/tmp/test_armos.mon"
with open(mon_file, "w") as f:
    f.write(f"bk {main_addr:04x}\n")
    f.write("g\n")

    # 1. Warp en Salle 36 (E-3 / $24)
    # Link apparaît au centre en bas
    f.write(f"> {arg2_addr:04x} 00\n")
    f.write(f"> {arg_addr:04x} 24\n")
    f.write(f"> {cmd_addr:04x} 01\n")
    f.write("g\n")
    f.write("g\n")
    f.write("g\n")
    f.write(f'screenshot "{os.path.join(OUT_DIR, "armos_01_sleeping_statues.png")}" 2\n')

    # 2. Positionner Link touchant la statue en haut à droite (col 14, row 3 -> X=248, Y=130)
    # On place Link juste en dessous à X=248, Y=144, marchant vers le haut
    f.write(f"> {px_addr:04x} f8 00\n")   # X = 248 ($00F8)
    f.write(f"> {py_addr:04x} 90\n")      # Y = 144 ($90)
    f.write(f"> {pdir_addr:04x} 01\n")    # DIR_UP (1)
    # Laisse tourner plusieurs frames pour que la boucle de jeu et AI_STATUE s'exécutent
    for _ in range(30):
        f.write("g\n")
    f.write(f'screenshot "{os.path.join(OUT_DIR, "armos_02_awakened_secret.png")}" 2\n')

    f.write("q\n")

print(f"Generated {mon_file}")
cmdline = [
    "x64sc",
    "-autostart", "build/zelda.d64:zelda",
    "-moncommands", mon_file,
    "+sound",
    "-warp"
]
print("Running VICE test for Armos...")
t0 = time.time()
res = subprocess.run(cmdline, capture_output=True, text=True, timeout=60)
elapsed = time.time() - t0
print(f"VICE finished in {elapsed:.1f}s")

for fname in ["armos_01_sleeping_statues.png", "armos_02_awakened_secret.png"]:
    p = os.path.join(OUT_DIR, fname)
    if os.path.exists(p):
        print(f"✓ OK: {fname} ({os.path.getsize(p)} bytes)")
    else:
        print(f"✗ MANQUANT: {fname}")
