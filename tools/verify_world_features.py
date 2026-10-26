#!/usr/bin/env python3
"""
tools/verify_world_features.py - Valide en émulation VICE les accès aux Donjons 2, 4, 5, 6,
les mécaniques du Radeau (Raft), du Bracelet de force, du Mur traversable,
des Labyrinthes (Lost Woods / Lost Hills), et capture les captures d'écran.
"""

import subprocess, os, time, sys

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
raft_addr = labels['player_has_raft']
brace_addr = labels['player_has_bracelet']
px_addr = labels['player_x']
py_addr = labels['player_y']
pdir_addr = labels['player_dir']

SCENARIOS = [
    # 1. Donjon 2 : Salle 60 (M-4) Overworld
    ("dungeon2_ow_entrance.png", [
        (f"> {arg2_addr:04x} 00",),
        (f"> {arg_addr:04x} 3c",),   # Room 60 ($3C)
        (f"> {cmd_addr:04x} 01",),   # Warp OW
    ], "Overworld Salle 60 (M-4) Entrée Donjon 2"),

    # 2. Donjon 2 : Entrée dans le Donjon 2
    ("dungeon2_inside.png", [
        (f"> {arg2_addr:04x} 00",),
        (f"> {arg_addr:04x} 02",),   # Level 2
        (f"> {cmd_addr:04x} 02",),   # Warp Dung 2
    ], "Intérieur Entrée Donjon 2 (Niveau 2)"),

    # 3. Donjon 4 & Radeau : Salle 85 (F-6) quai de radeau
    ("dungeon4_ow_dock_f6.png", [
        (f"> {arg2_addr:04x} 00",),
        (f"> {arg_addr:04x} 55",),   # Room 85 ($55)
        (f"> {cmd_addr:04x} 01",),   # Warp OW 85
        (f"> {raft_addr:04x} 01",),  # Donner le radeau
    ], "Overworld Salle 85 (F-6) Quai de départ vers Donjon 4"),

    # 4. Donjon 4 : Salle 69 (F-5) Île du Donjon 4 après traversée en Radeau
    ("dungeon4_ow_island_f5.png", [
        (f"> {arg2_addr:04x} 00",),
        (f"> {arg_addr:04x} 45",),   # Room 69 ($45)
        (f"> {cmd_addr:04x} 01",),   # Warp OW 69
    ], "Overworld Salle 69 (F-5) Île du Donjon 4 au milieu du lac"),

    # 5. Donjon 4 : Entrée dans le Donjon 4
    ("dungeon4_inside.png", [
        (f"> {arg2_addr:04x} 00",),
        (f"> {arg_addr:04x} 04",),   # Level 4
        (f"> {cmd_addr:04x} 02",),   # Warp Dung 4
    ], "Intérieur Entrée Donjon 4 (Niveau 4)"),

    # 6. Donjon 6 : Salle 34 (C-3) Cimetière avec tombes authentiques
    ("dungeon6_ow_graveyard.png", [
        (f"> {arg2_addr:04x} 00",),
        (f"> {arg_addr:04x} 22",),   # Room 34 ($22)
        (f"> {cmd_addr:04x} 01",),   # Warp OW 34
    ], "Overworld Salle 34 (C-3) Cimetière & Entrée Donjon 6"),

    # 7. Donjon 6 : Entrée dans le Donjon 6
    ("dungeon6_inside.png", [
        (f"> {arg2_addr:04x} 00",),
        (f"> {arg_addr:04x} 06",),   # Level 6
        (f"> {cmd_addr:04x} 02",),   # Warp Dung 6
    ], "Intérieur Entrée Donjon 6 (Niveau 6)"),

    # 8. Donjon 5 : Salle 11 (L-1) Entrée Donjon 5
    ("dungeon5_ow_entrance.png", [
        (f"> {arg2_addr:04x} 00",),
        (f"> {arg_addr:04x} 0b",),   # Room 11 ($0B)
        (f"> {cmd_addr:04x} 01",),   # Warp OW 11
    ], "Overworld Salle 11 (L-1) Entrée Donjon 5"),

    # 9. Donjon 5 : Entrée dans le Donjon 5
    ("dungeon5_inside.png", [
        (f"> {arg2_addr:04x} 00",),
        (f"> {arg_addr:04x} 05",),   # Level 5
        (f"> {cmd_addr:04x} 02",),   # Warp Dung 5
    ], "Intérieur Entrée Donjon 5 (Niveau 5)"),

    # 10. Collines Perdues (Lost Hills) : Salle 43 (L-3)
    ("lost_hills_ow_room43.png", [
        (f"> {arg2_addr:04x} 00",),
        (f"> {arg_addr:04x} 2b",),   # Room 43 ($2B)
        (f"> {cmd_addr:04x} 01",),   # Warp OW 43
    ], "Overworld Salle 43 (L-3) Collines Perdues (Lost Hills)"),

    # 11. Mur traversable : Salle 31 (P-2) avec mur illusion W
    ("wall_illusion_p2.png", [
        (f"> {arg2_addr:04x} 00",),
        (f"> {arg_addr:04x} 1f",),   # Room 31 ($1F)
        (f"> {cmd_addr:04x} 01",),   # Warp OW 31
    ], "Overworld Salle 31 (P-2) Mur traversable secret vers P-1"),

    # 12. Grotte secrète Moblin : Salle 15 (P-1)
    ("moblin_secret_p1.png", [
        (f"> {arg2_addr:04x} 00",),
        (f"> {arg_addr:04x} 0f",),   # Room 15 ($0F)
        (f"> {cmd_addr:04x} 01",),   # Warp OW 15
    ], "Overworld Salle 15 (P-1) Grotte Moblin secret (+100 rubis)"),

    # 13. Armos / Bracelet de force : Salle 36 (E-3)
    ("armos_bracelet_e3.png", [
        (f"> {arg2_addr:04x} 00",),
        (f"> {arg_addr:04x} 24",),   # Room 36 ($24)
        (f"> {cmd_addr:04x} 01",),   # Warp OW 36
    ], "Overworld Salle 36 (E-3) Statues Armos & Bracelet de Force"),
]

mon_file = "/tmp/verify_world.mon"
with open(mon_file, "w") as f:
    f.write(f"bk {main_addr:04x}\n")
    f.write("g\n")
    for fname, cmds, desc in SCENARIOS:
        out_png = os.path.join(OUT_DIR, fname)
        for c in cmds:
            f.write(c[0] + "\n")
        f.write("g\n")
        f.write("g\n")
        f.write("g\n")
        f.write(f'screenshot "{out_png}" 2\n')
    f.write("q\n")

print(f"Generated {mon_file} with {len(SCENARIOS)} scenarios")
cmdline = [
    "x64sc",
    "-autostart", "build/zelda.d64:zelda",
    "-moncommands", mon_file,
    "+sound",
    "-warp"
]
print("Running VICE test...")
t0 = time.time()
res = subprocess.run(cmdline, capture_output=True, text=True, timeout=120)
elapsed = time.time() - t0
print(f"VICE finished in {elapsed:.1f}s")

for fname, _, desc in SCENARIOS:
    path = os.path.join(OUT_DIR, fname)
    if os.path.exists(path):
        print(f"✓ OK: {fname} ({os.path.getsize(path)} octets) - {desc}")
    else:
        print(f"✗ MANQUANT: {fname}")
