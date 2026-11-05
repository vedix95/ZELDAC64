#!/usr/bin/env python3
"""
tools/capture_ow_enemies.py
Capture des captures d'écran de tous les ennemis de l'Overworld dans différentes salles.
"""
import os
import subprocess
import time

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT_DIR = os.path.join(BASE_DIR, "screenshots", "ow_enemies")
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

# Liste des pièces et ennemis à tester :
# (nom_fichier, room_id, description)
SCENARIOS = [
    ("shot_ow_119_spawn.png",       119, "Salle de départ (Spawn Screen)"),
    ("shot_ow_120_octo_blue.png",   120, "Octoroks Bleus (Salle 120, est du spawn)"),
    ("shot_ow_103_octo_blue.png",   103, "Octoroks Bleus (Salle 103, nord du spawn)"),
    ("shot_ow_055_octo_red_zora.png", 55, "Octoroks Rouges & Zora (Salle 55)"),
    ("shot_ow_075_moblin_red.png",   75, "Moblins Rouges (Salle 75, forêt)"),
    ("shot_ow_077_moblin_blue.png",  77, "Moblins Bleus (Salle 77, forêt)"),
    ("shot_ow_118_tektite_red.png", 118, "Tektites Rouges (Salle 118, ouest du spawn)"),
    ("shot_ow_074_tektite_blue.png", 74, "Tektites Bleus (Salle 74)"),
    ("shot_ow_011_leever_red.png",   11, "Leevers Rouges (Salle 11)"),
    ("shot_ow_042_leever_blue.png",  42, "Leevers Bleus & Peahat (Salle 42)"),
    ("shot_ow_006_peahat_lynel.png",  6, "Peahat & Lynels (Salle 6)"),
    ("shot_ow_028_armos.png",        28, "Armos (Salle 28)"),
    ("shot_ow_032_ghini.png",        32, "Ghinis (Salle 32, cimetière)"),
    ("shot_ow_014_zora.png",         14, "Zora aquatique (Salle 14)"),
    ("shot_ow_001_lynel_red.png",     1, "Lynels Rouges (Salle 1, montagne)"),
    ("shot_ow_004_lynel_blue.png",    4, "Lynels Bleus (Salle 4, montagne)"),
]

def main():
    z_labels = load_labels(os.path.join(BASE_DIR, "build", "zelda.vs"))
    i_labels = load_labels(os.path.join(BASE_DIR, "build", "intro.vs"))

    cmd_addr = z_labels['debug_hook_cmd']
    arg_addr = z_labels['debug_hook_arg']
    arg2_addr = z_labels['debug_hook_arg2']
    main_addr = z_labels['main_loop']
    launch_addr = i_labels['launch_zelda_game']

    mon_file = "/tmp/zelda_capture_ow.mon"
    with open(mon_file, "w") as f:
        f.write("break 080d\n")
        f.write("g\n")
        f.write(f"g {launch_addr:04x}\n")
        f.write(f"break {main_addr:04x}\n")
        f.write("g\n")

        for fname, room_id, desc in SCENARIOS:
            out_png = os.path.join(OUT_DIR, fname)
            f.write(f"> {arg2_addr:04x} 00\n")
            f.write(f"> {arg_addr:04x} {room_id:02x}\n")
            f.write(f"> {cmd_addr:04x} 01\n") # cmd 1 = warp overworld
            # Laisser s'exécuter 30 frames pour que les monstres apparaissent et s'animent
            for _ in range(30):
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
    print(f"Exécution de VICE pour capturer {len(SCENARIOS)} salles d'Overworld...")
    t0 = time.time()
    res = subprocess.run(cmdline, capture_output=True, text=True, timeout=180)
    print(f"VICE terminé en {time.time() - t0:.1f}s.")

    # Conversion .pcx -> .png
    for f in os.listdir(OUT_DIR):
        if f.endswith(".pcx"):
            p = os.path.join(OUT_DIR, f)
            subprocess.run(["magick", p, p[:-4]], check=True)
            os.remove(p)

    print("\n--- RÉSULTATS DES CAPTURES OVERWORLD ---")
    for fname, _, desc in SCENARIOS:
        p = os.path.join(OUT_DIR, fname)
        if os.path.exists(p):
            sz = os.path.getsize(p)
            print(f"  [✓] {fname} ({sz} octets) : {desc}")
        else:
            print(f"  [X] {fname} MANQUANT : {desc}")

if __name__ == "__main__":
    main()
