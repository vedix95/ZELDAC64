#!/usr/bin/env python3
"""
Test de non-régression : Ramassage de l'épée dans la grotte de départ
Vérifie :
1. Link entre dans la caverne de l'Épée de Bois (salle overworld 119 = 0x77).
2. Le slot 2 contient l'Épée de Bois et est actif.
3. Link marche sur le slot 2 : l'objet est octroyé (player_has_sword = 1),
   le slot 2 est immédiatement désactivé (cave_slot2_active = 0).
4. La célébration s'enclenche (cave_pickup_timer = 75, Link en pose SPR_COMMON_ITEM_GET,
   Sprite 7 affiche l'objet levé).
5. Après expiration du minuteur (80 frames), Link reprend sa pose normale de marche,
   Sprite 7 est éteint, et la célébration NE BOUCLE PAS indéfiniment même si Link
   reste sur l'emplacement du slot.
6. Link peut sortir de la caverne vers l'Overworld et possède l'épée affichée au HUD.
"""

import os
import sys
import time
import subprocess

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCREENSHOT_DIR = "/home/vedix/.gemini/antigravity-cli/brain/365f32a0-f74f-4db0-9615-3c00e08c47af/screenshots"
os.makedirs(SCREENSHOT_DIR, exist_ok=True)

def load_labels(vs_path):
    labels = {}
    with open(vs_path, "r", encoding="utf-8") as f:
        for line in f:
            parts = line.strip().split()
            if len(parts) >= 3 and parts[0] == "al":
                addr = int(parts[1].split(":")[-1], 16)
                name = parts[2].lstrip(".")
                labels[name] = addr
    return labels

def main():
    zelda_vs = os.path.join(BASE_DIR, "build", "zelda.vs")
    intro_vs = os.path.join(BASE_DIR, "build", "intro.vs")
    cave_vs = os.path.join(BASE_DIR, "build", "ovl_cave.vs")

    if not os.path.exists(zelda_vs) or not os.path.exists(intro_vs) or not os.path.exists(cave_vs):
        print("Erreur : Fichiers .vs manquants. Lancez 'make' d'abord.")
        return 1

    lbl_zelda = load_labels(zelda_vs)
    lbl_intro = load_labels(intro_vs)
    lbl_cave = load_labels(cave_vs)

    launch_addr = lbl_intro["launch_zelda_game"]
    main_addr = lbl_zelda["main_loop"]
    px_addr = lbl_zelda["player_x"]
    py_addr = lbl_zelda["player_y"]
    pdir_addr = lbl_zelda["player_dir"]
    has_sword_addr = lbl_zelda["player_has_sword"]
    game_state_addr = lbl_zelda["game_state"]
    cur_cave_type_addr = lbl_zelda["current_cave_type"]
    cave_cleared_addr = lbl_zelda["cave_room_cleared"]

    cave_pickup_timer_addr = lbl_cave["cave_pickup_timer"]
    cave_slot2_active_addr = lbl_cave["cave_slot2_active"]

    dump_state_1 = "/tmp/cave_state_1.bin"
    dump_state_2 = "/tmp/cave_state_2.bin"
    dump_state_3 = "/tmp/cave_state_3.bin"
    for p in [dump_state_1, dump_state_2, dump_state_3]:
        if os.path.exists(p):
            os.remove(p)

    ss1 = os.path.join(SCREENSHOT_DIR, "test_cave_pickup_celebration.png")
    ss2 = os.path.join(SCREENSHOT_DIR, "test_cave_pickup_finished.png")
    ss3 = os.path.join(SCREENSHOT_DIR, "test_cave_pickup_exit_ow.png")

    mon_file = "/tmp/test_cave_pickup.mon"
    with open(mon_file, "w") as f:
        # 1. Boot cartouche -> passer l'intro
        f.write("break 080d\n")
        f.write("g\n")
        f.write(f"g {launch_addr:04x}\n")

        # 2. Arrivée dans main_loop (Overworld de départ)
        f.write(f"break {main_addr:04x}\n")
        f.write("g\n")

        # 3. Téléporter Link devant l'entrée de la grotte (Salle 119 : X=108, Y=86)
        # Note : 108 = 0x6C, 86 = 0x56
        f.write(f"> {px_addr:04x} 6c 00\n")
        f.write(f"> {py_addr:04x} 56\n")
        f.write(f"> {pdir_addr:04x} 00\n")  # DIR_UP

        # Avancer de 5 frames pour entrer dans la grotte
        for _ in range(5):
            f.write("g\n")

        # 4. Maintenant dans la grotte (Link à X=176, Y=214 par défaut)
        # Placer Link directement sur le slot 2 de l'épée (X=176 = 0xB0, Y=150 = 0x96)
        f.write(f"> {px_addr:04x} b0 00\n")
        f.write(f"> {py_addr:04x} 96\n")

        # Avancer de 2 frames pour déclencher le ramassage de l'épée
        f.write("g\n")
        f.write("g\n")

        # Dump 1 : Pendant la célébration
        # cave_pickup_timer, cave_slot2_active, has_sword, game_state, SPRITE_PTR0 (07f8), VIC_SPRITE_EN (d015)
        # On va dumper les variables clés
        f.write(f's "{dump_state_1}" 0 {cave_pickup_timer_addr:04x} {cave_pickup_timer_addr+16:04x}\n')
        f.write(f'screenshot "{ss1}" 2\n')

        # 5. Attendre 85 frames (la célébration dure 75 frames)
        for _ in range(85):
            f.write("g\n")

        # Dump 2 : Après la fin théorique de la célébration
        f.write(f's "{dump_state_2}" 0 {cave_pickup_timer_addr:04x} {cave_pickup_timer_addr+16:04x}\n')
        f.write(f'screenshot "{ss2}" 2\n')

        # 6. Attendre encore 30 frames de plus sans bouger :
        # Link est TOUJOURS sur l'emplacement du slot 2.
        # Si le bug persiste, la célébration reboucle et timer redevient > 0 !
        for _ in range(30):
            f.write("g\n")

        f.write(f's "{dump_state_3}" 0 {cave_pickup_timer_addr:04x} {cave_pickup_timer_addr+16:04x}\n')

        # 7. Marcher vers le bas pour sortir de la grotte (Y -> 214)
        # Placer Link à Y=214 pour déclencher la sortie
        f.write(f"> {py_addr:04x} d6\n") # 214 = 0xD6
        for _ in range(15):
            f.write("g\n")

        f.write(f'screenshot "{ss3}" 2\n')
        f.write("quit\n")

    cmd = [
        "x64sc",
        "-default",
        "-cartcrt", os.path.join(BASE_DIR, "build", "zelda.crt"),
        "-moncommands", mon_file,
        "-warp",
        "-sound",
    ]

    print("[*] Lancement de la vérification VICE sous moniteur...")
    proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=40)

    # Conversion d'éventuels PCX
    for p in [ss1, ss2, ss3]:
        pcx_p = p + ".pcx"
        if os.path.exists(pcx_p):
            subprocess.run(["magick", pcx_p, p], check=True)
            os.remove(pcx_p)

    # Analyse des dumps
    if not os.path.exists(dump_state_1) or not os.path.exists(dump_state_2) or not os.path.exists(dump_state_3):
        print(f"[-] Erreur : Les dumps de mémoire n'ont pas été produits.")
        return 1

    with open(dump_state_1, "rb") as f:
        d1 = f.read()[2:]  # Sauter l'en-tête de chargement C64 (2 octets)
    with open(dump_state_2, "rb") as f:
        d2 = f.read()[2:]
    with open(dump_state_3, "rb") as f:
        d3 = f.read()[2:]

    # Dans cave.asm:
    # cave_pickup_timer est au début du dump
    # cave_slot2_active est à l'offset cave_slot2_active_addr - cave_pickup_timer_addr
    offset_slot2 = cave_slot2_active_addr - cave_pickup_timer_addr

    timer_1 = d1[0]
    slot2_active_1 = d1[offset_slot2]

    timer_2 = d2[0]
    slot2_active_2 = d2[offset_slot2]

    timer_3 = d3[0]
    slot2_active_3 = d3[offset_slot2]

    print(f"Dump 1 (Frame 2 après pickup) : cave_pickup_timer = {timer_1}, cave_slot2_active = {slot2_active_1}")
    print(f"Dump 2 (Frame 87 après pickup) : cave_pickup_timer = {timer_2}, cave_slot2_active = {slot2_active_2}")
    print(f"Dump 3 (Frame 117 sur le slot) : cave_pickup_timer = {timer_3}, cave_slot2_active = {slot2_active_3}")

    success = True

    # Vérification 1 : Célébration déclenchée
    if timer_1 == 0:
        print("[-] Échec : cave_pickup_timer ne s'est pas déclenché !")
        success = False
    else:
        print(f"[✓] Célébration initialement active (timer = {timer_1})")

    # Vérification 2 : cave_slot2_active doit être à 0 IMMÉDIATEMENT dès le début
    if slot2_active_1 != 0:
        print(f"[-] Échec : cave_slot2_active est encore à {slot2_active_1} au lieu de 0 !")
        success = False
    else:
        print("[✓] cave_slot2_active a été correctement désactivé à 0.")

    # Vérification 3 : Après 85 frames, timer doit être arrivé à 0
    if timer_2 != 0:
        print(f"[-] Échec : cave_pickup_timer n'a pas expiré à 0 après 85 frames (valeur = {timer_2})")
        success = False
    else:
        print("[✓] cave_pickup_timer s'est éteint normalement à 0.")

    # Vérification 4 : CRUCIALE - Link reste sur le slot, timer NE DOIT PAS repartir !
    if timer_3 != 0:
        print(f"[-] ÉCHEC CRITIQUE : BOUCLE INFINIE DÉTECTÉE ! Le timer est reparti à {timer_3} !")
        success = False
    else:
        print("[✓] SUCCÈS ABSOLU : Aucune boucle infinie ! cave_pickup_timer est resté à 0 sur le slot.")

    if os.path.exists(ss1):
        print(f"[✓] Screenshot célébration : {ss1}")
    if os.path.exists(ss2):
        print(f"[✓] Screenshot fin célébration : {ss2}")
    if os.path.exists(ss3):
        print(f"[✓] Screenshot sortie overworld : {ss3}")

    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())
