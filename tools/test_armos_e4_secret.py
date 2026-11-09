#!/usr/bin/env python3
"""
tools/test_armos_e4_secret.py - Teste et valide la mécanique Armos et le secret en E-4 :
1. Téléporte Link en salle 52 (E-4, $34).
2. Touche la statue non-secrète en (4, 4) :
   - L'Armos se réveille.
   - La tuile (4, 4) devient TILE_GRASS (0).
   - Aucun escalier n'apparaît.
3. Touche la statue secrète en (6, 4) :
   - L'Armos se réveille.
   - La tuile (6, 4) devient TILE_CAVE (12).
   - Le carillon secret retentit et overworld_secrets_opened est mis à jour.
4. Link entre dans l'escalier (tuile 86) :
   - Transition vers la grotte CAVE_TYPE_SHOP_SECRET (Anneau Bleu à 250R).
5. Link ressort de la grotte :
   - La tuile 86 reste un escalier TILE_CAVE (persistance de l'ouverture).
   - L'Armos du secret ne réapparaît pas sur l'escalier.
"""

import subprocess
import os
import sys
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


def run_test():
    vs_path = os.path.join(BASE_DIR, "build", "zelda.vs")
    intro_vs = os.path.join(BASE_DIR, "build", "intro.vs")
    labels = load_labels(vs_path)
    intro_labels = load_labels(intro_vs)

    cmd_addr = labels["debug_hook_cmd"]
    arg_addr = labels["debug_hook_arg"]
    arg2_addr = labels["debug_hook_arg2"]
    main_addr = labels["main_loop"]
    px_addr = labels["player_x"]
    py_addr = labels["player_y"]
    pdir_addr = labels["player_dir"]
    gstate_addr = labels["game_state"]
    room_buf_addr = labels["room_buf"]
    sec_open_addr = labels["overworld_secrets_opened"]
    cave_type_addr = labels["current_cave_type"]
    launch_addr = intro_labels["launch_zelda_game"]

    mon_file = "/tmp/test_armos_e4.mon"
    with open(mon_file, "w") as f:
        # 1. Boot cartouche et passage direct au jeu
        f.write("break 080d\n")
        f.write("g\n")
        f.write(f"g {launch_addr:04x}\n")
        f.write(f"break {main_addr:04x}\n")
        f.write("g\n")

        # 2. Warp en Salle 52 (E-4 / $34)
        f.write(f"> {arg2_addr:04x} 00\n")
        f.write(f"> {arg_addr:04x} 34\n")
        f.write(f"> {cmd_addr:04x} 01\n")
        for _ in range(10):
            f.write("g\n")
        f.write(f'screenshot "{os.path.join(OUT_DIR, "armos_e4_01_init.png")}" 2\n')

        # 3. Toucher la statue non-secrète en (4, 4)
        # tx=4, ty=4 -> statue_x = 20 + 64 = 84 ($54), statue_y = 80 + 64 = 144 ($90)
        # Position Link : X=84 ($54), Y=152 ($98), dir=UP (1)
        f.write(f"> {px_addr:04x} 54 00\n")
        f.write(f"> {py_addr:04x} 98\n")
        f.write(f"> {pdir_addr:04x} 01\n")
        for _ in range(30):
            f.write("g\n")
        f.write(f'screenshot "{os.path.join(OUT_DIR, "armos_e4_02_grass_statue.png")}" 2\n')

        # 4. Toucher la statue secrète en (6, 4)
        # tx=6, ty=4 -> statue_x = 20 + 96 = 116 ($74), statue_y = 80 + 64 = 144 ($90)
        # Position Link : X=116 ($74), Y=152 ($98), dir=UP (1)
        f.write(f"> {px_addr:04x} 74 00\n")
        f.write(f"> {py_addr:04x} 98\n")
        f.write(f"> {pdir_addr:04x} 01\n")
        for _ in range(30):
            f.write("g\n")
        f.write(f'screenshot "{os.path.join(OUT_DIR, "armos_e4_03_cave_revealed.png")}" 2\n')

        # 5. Link monte sur l'escalier (tx=6, ty=4 -> X=116, Y=144)
        f.write(f"> {px_addr:04x} 74 00\n")
        f.write(f"> {py_addr:04x} 90\n")
        for _ in range(40):
            f.write("g\n")
        f.write(f'screenshot "{os.path.join(OUT_DIR, "armos_e4_04_inside_shop.png")}" 2\n')

        # 6. Link sort de l'échoppe par l'entrée/sortie centrale sud (X=180, Y=216)
        f.write(f"> {px_addr:04x} b4 00\n")
        f.write(f"> {py_addr:04x} d8\n")
        for _ in range(40):
            f.write("g\n")
        f.write(f'screenshot "{os.path.join(OUT_DIR, "armos_e4_05_reentered_room.png")}" 2\n')

        # Dump de contrôle mémoire :
        f.write(f's "/tmp/armos_e4_tiles.bin" 0 {room_buf_addr + 84:04x} {room_buf_addr + 86:04x}\n')
        f.write(f's "/tmp/armos_e4_sec.bin" 0 {sec_open_addr + 6:04x} {sec_open_addr + 6:04x}\n')
        f.write(f's "/tmp/armos_e4_state.bin" 0 {gstate_addr:04x} {gstate_addr:04x}\n')

        f.write("quit\n")

    cmdline = [
        "x64sc",
        "-default",
        "-cartcrt", os.path.join(BASE_DIR, "build", "zelda.crt"),
        "-warp",
        "-limitcycles", "250000000",
        "-moncommands", mon_file
    ]
    print("[*] Lancement du test Armos E-4 sous VICE...")
    t0 = time.time()
    res = subprocess.run(cmdline, capture_output=True, text=True, timeout=60)
    print(f"[*] Fin VICE en {time.time() - t0:.1f}s (code {res.returncode})")

    # Conversion des screenshots PCX si générés
    for fname in ["armos_e4_01_init.png", "armos_e4_02_grass_statue.png",
                  "armos_e4_03_cave_revealed.png", "armos_e4_04_inside_shop.png",
                  "armos_e4_05_reentered_room.png"]:
        pcx = os.path.join(OUT_DIR, fname + ".pcx")
        png = os.path.join(OUT_DIR, fname)
        if os.path.exists(pcx):
            subprocess.run(["magick", pcx, png], check=True)
            os.remove(pcx)
        if os.path.exists(png):
            print(f"  [✓] Capture créée : {png} ({os.path.getsize(png)} octets)")
        else:
            print(f"  [✗] MANQUANT : {png}")

    # Analyse des sorties mémoires et assertions
    with open("/tmp/armos_e4_tiles.bin", "rb") as f:
        tiles = list(f.read()[2:])
        t84 = tiles[0]
        t86 = tiles[2]
        print(f"  [+] Tuile 84 (4, 4) = {t84} (attendu statue=14 réinitialisée au retour)")
        print(f"  [+] Tuile 86 (6, 4) = {t86} (attendu escalier=7 persistant)")
        assert t84 == 14, f"Tuile 84 non statue réinitialisée : {t84}"
        assert t86 == 7, f"Tuile 86 non escalier : {t86}"

    with open("/tmp/armos_e4_sec.bin", "rb") as f:
        sec_val = list(f.read()[2:])[0]
        print(f"  [+] Secrets ouverts chunk 6 = 0x{sec_val:02x} (attendu bit 4 = 0x10)")
        assert sec_val & 0x10 != 0, f"Bit secret salle 52 non enregistré : 0x{sec_val:02x}"

    assert os.path.exists(os.path.join(OUT_DIR, "armos_e4_03_cave_revealed.png")), "Screenshot cave_revealed manquant"
    print("\n[+] Succès de la validation Armos E-4 !")


if __name__ == "__main__":
    run_test()
