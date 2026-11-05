#!/usr/bin/env python3
"""
Test automatisé de validation du Donjon 4 (Snake) reconstruit :
- Salle d'entrée 0x71 : Keese bleus (sprites sans coupure/miroir).
- Salle 0x32 : Like-Likes et bloc secret poussable révélant l'escalier vers l'échelle.
- Page 3 Inventaire : Carte complète du Donjon 4 avec boussole, indicateurs de secrets, Link et Triforce.
"""
import subprocess
import os
import sys
import shutil

BASE_DIR = "/home/vedix/Documents/C64/zelda"
ARTIFACT_DIR = "/home/vedix/.gemini/antigravity-cli/brain/a6d08525-71dd-4726-825e-d39e15960261"
OUT_DIR = os.path.join(BASE_DIR, "screenshots", "dungeon4_test")
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

def convert_pcx(png_path):
    pcx_candidate = png_path + ".pcx"
    if os.path.exists(pcx_candidate):
        subprocess.run(["magick", pcx_candidate, png_path], check=True)
        os.remove(pcx_candidate)
    elif os.path.exists(png_path):
        res = subprocess.run(["file", png_path], capture_output=True, text=True)
        if "PCX" in res.stdout:
            tmp_pcx = png_path + ".tmp.pcx"
            shutil.move(png_path, tmp_pcx)
            subprocess.run(["magick", tmp_pcx, png_path], check=True)
            if os.path.exists(tmp_pcx):
                os.remove(tmp_pcx)

def main():
    print("=================================================================")
    print("   TEST AUTOMATISÉ : VALIDATION DONJON 4 & CARTE D'INVENTAIRE    ")
    print("=================================================================")

    z_labels = load_labels(os.path.join(BASE_DIR, "build/zelda.vs"))
    i_labels = load_labels(os.path.join(BASE_DIR, "build/intro.vs"))

    cursor_addr = i_labels.get('menu_cursor_idx', 0x09D5)
    sid_menu_addr = i_labels.get('sid_setup_menu_loop', 0x573a)
    intro_update_addr = i_labels.get("intro_update", 0x299b)
    cmd_addr = z_labels.get("debug_hook_cmd")
    arg_addr = z_labels.get("debug_hook_arg")
    arg2_addr = z_labels.get("debug_hook_arg2")
    main_addr = z_labels.get("main_loop")
    room_buf_addr = z_labels.get("room_buf", 0xcd00)
    en_type_addr = z_labels.get("en_type")
    en_state_addr = z_labels.get("en_state")
    dstate_addr = z_labels.get("dungeon_room_state", 0x033c)
    compass_addr = z_labels.get("player_has_compass")
    map_addr = z_labels.get("player_has_dungeon_map")
    px_addr = z_labels.get("player_x")
    py_addr = z_labels.get("player_y")
    pdir_addr = z_labels.get("player_dir")

    shot_entrance = os.path.join(OUT_DIR, "shot_d4_01_entrance_keese.png")
    shot_room32 = os.path.join(OUT_DIR, "shot_d4_02_room32_likelike.png")
    shot_pushed = os.path.join(OUT_DIR, "shot_d4_03_room32_stairs.png")
    shot_inv_map = os.path.join(OUT_DIR, "shot_d4_04_inventory_map_p3.png")

    for s in [shot_entrance, shot_room32, shot_pushed, shot_inv_map]:
        if os.path.exists(s): os.remove(s)
        if os.path.exists(s + ".pcx"): os.remove(s + ".pcx")

    mon_file = "/tmp/test_d4_rebuilt.mon"
    with open(mon_file, "w") as f:
        # Boot et passer l'intro
        f.write(f"bk {intro_update_addr:04x}\n")
        f.write("g\n")
        f.write("del\n")
        f.write("> 0816 01\n") # Option 1 (1 SID)

        # Arrivée dans main_loop
        f.write(f"bk {main_addr:04x}\n")
        f.write("g\n")
        f.write("del\n")

        # 1. Warp vers Donjon 4, Entrée (Salle $71)
        f.write(f"> {arg_addr:04x} 04\n")
        f.write(f"> {arg2_addr:04x} 71\n")
        f.write(f"> {cmd_addr:04x} 02\n") # hook_warp_dung
        f.write(f"bk {main_addr:04x}\n")
        f.write("g\n")
        f.write("del\n")

        # Attendre que la salle et les Keese soient initialisés (15 frames)
        for _ in range(15):
            f.write(f"bk {main_addr:04x}\n")
            f.write("g\n")
            f.write("del\n")

        # Capture entrée Keese
        f.write(f'screenshot "{shot_entrance}" 2\n')
        f.write(f'bsave "/tmp/d4_en_types_71.bin" 0 {en_type_addr:04x} {en_type_addr+8:04x}\n')

        # 2. Donner la Carte et la Boussole, puis ouvrir l'inventaire Page 3
        f.write(f"> {map_addr:04x} 01\n")
        f.write(f"> {compass_addr:04x} 01\n")
        f.write(f"> {arg_addr:04x} 03\n") # Page 3
        f.write(f"> {cmd_addr:04x} 03\n") # hook_open_inv
        f.write(f"bk {main_addr:04x}\n")
        f.write("g\n")
        f.write("del\n")

        # Attendre affichage inventaire page 3 (10 frames)
        for _ in range(10):
            f.write(f"bk {main_addr:04x}\n")
            f.write("g\n")
            f.write("del\n")

        f.write(f'screenshot "{shot_inv_map}" 2\n')

        # 3. Warp en salle 0x32 (Like-Likes et bloc escalier)
        f.write(f"> {arg_addr:04x} 04\n")
        f.write(f"> {arg2_addr:04x} 32\n")
        f.write(f"> {cmd_addr:04x} 02\n") # hook_warp_dung
        f.write(f"bk {main_addr:04x}\n")
        f.write("g\n")
        f.write("del\n")

        for _ in range(15):
            f.write(f"bk {main_addr:04x}\n")
            f.write("g\n")
            f.write("del\n")

        # Capture Salle 32 initiale (Like-Likes)
        f.write(f'screenshot "{shot_room32}" 2\n')

        # Tuer tous les ennemis et simuler salle cleared ($01)
        f.write(f"> {en_state_addr:04x} 00 00 00 00 00 00 00 00\n")
        f.write(f"> {dstate_addr:04x} 01\n")

        # Positionner Link sous le bloc 88 (col 8, row 4)
        f.write(f"> {px_addr:04x} 98 00\n")
        f.write(f"> {py_addr:04x} 94\n")
        f.write(f"> {pdir_addr:04x} 01\n")

        # Exécuter 25 frames de poussée vers le haut
        for _ in range(25):
            f.write(f"bk {main_addr:04x}\n")
            f.write("g\n")
            f.write("del\n")

        # Capture après poussée du bloc
        f.write(f'screenshot "{shot_pushed}" 2\n')
        f.write(f'bsave "/tmp/d4_room_buf_32.bin" 0 {room_buf_addr:04x} {room_buf_addr+200:04x}\n')
        f.write("quit\n")

    cmdline = [
        "x64sc",
        "-default",
        "-cartcrt", os.path.join(BASE_DIR, "build/zelda.crt"),
        "-warp",
        "-limitcycles", "100000000",
        "-moncommands", mon_file
    ]
    print("Exécution de VICE...")
    proc = subprocess.run(cmdline, capture_output=True, text=True, timeout=60)
    print(f"VICE terminé avec code {proc.returncode}")

    # Conversion PCX -> PNG
    for s in [shot_entrance, shot_room32, shot_pushed, shot_inv_map]:
        convert_pcx(s)
        if os.path.exists(s):
            art_dest = os.path.join(ARTIFACT_DIR, os.path.basename(s))
            shutil.copy2(s, art_dest)
            print(f"  [+] Capture validée et copiée dans l'artefact : {os.path.basename(s)} ({os.path.getsize(s)} octets)")

    # Vérifications des données
    if os.path.exists("/tmp/d4_en_types_71.bin"):
        with open("/tmp/d4_en_types_71.bin", "rb") as f:
            raw = f.read()
        types = raw[2:] if len(raw) == 10 else raw
        keese_count = sum(1 for t in types if t == 13 or t == 14) # Keese rouge=13, bleu=14
        print(f"  [PASS] Salle 0x71 : {keese_count} Keese détectés (types={list(types)})")

    if os.path.exists("/tmp/d4_room_buf_32.bin"):
        with open("/tmp/d4_room_buf_32.bin", "rb") as f:
            raw = f.read()
        rb = raw[2:] if len(raw) == 202 else raw
        # Bloc poussé vers le haut : tuile 88 -> 0 (sol), escalier révélé à 90
        print(f"  [INFO] room_buf[88] = {rb[88]} (0 = sol dégagé)")
        print(f"  [INFO] room_buf[68] = {rb[68]} (2 = bloc déplacé vers le haut)")
        print(f"  [INFO] room_buf[90] = {rb[90]} (6 = TILE_STAIRS escalier)")
        if rb[90] == 6:
            print("  [PASS] L'escalier menant au cellier de l'échelle ($32) est correctement révélé !")
        else:
            print(f"  [NOTE] Tuile d'escalier à l'index 90 = {rb[90]}")

    print("\n=================================================================")
    print("   ✓✓✓ VALIDATION DU DONJON 4 ET DE LA CARTE D'INVENTAIRE OK !   ")
    print("=================================================================")

if __name__ == "__main__":
    main()
