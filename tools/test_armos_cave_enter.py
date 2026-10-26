#!/usr/bin/env python3
"""
tools/test_armos_cave_enter.py - Teste l'entrée dans l'escalier sous l'Armos éveillé en Salle 36.
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

mon_file = "/tmp/test_armos_enter.mon"
with open(mon_file, "w") as f:
    f.write(f"bk {main_addr:04x}\n")
    f.write("g\n")

    # 1. Warp en Salle 36 (E-3 / $24)
    f.write(f"> {arg2_addr:04x} 00\n")
    f.write(f"> {arg_addr:04x} 24\n")
    f.write(f"> {cmd_addr:04x} 01\n")
    f.write("g\n")
    f.write("g\n")

    # 2. Positionner Link sur la statue pour l'éveiller
    f.write(f"> {px_addr:04x} f8 00\n")   # X = 248
    f.write(f"> {py_addr:04x} 90\n")      # Y = 144
    f.write(f"> {pdir_addr:04x} 01\n")    # DIR_UP
    for _ in range(20):
        f.write("g\n")

    # 3. Avancer Link dans l'escalier (Y = 130)
    f.write(f"> {py_addr:04x} 82\n")      # Y = 130
    for _ in range(25):
        f.write("g\n")
    f.write(f'screenshot "{os.path.join(OUT_DIR, "armos_03_inside_cave.png")}" 2\n')
    f.write("q\n")

cmdline = [
    "x64sc",
    "-autostart", "build/zelda.d64:zelda",
    "-moncommands", mon_file,
    "+sound",
    "-warp"
]
res = subprocess.run(cmdline, capture_output=True, text=True, timeout=60)
p = os.path.join(OUT_DIR, "armos_03_inside_cave.png")
if os.path.exists(p):
    print(f"✓ OK: armos_03_inside_cave.png ({os.path.getsize(p)} bytes)")
else:
    print("✗ MANQUANT: armos_03_inside_cave.png")
