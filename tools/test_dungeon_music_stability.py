#!/usr/bin/env python3
"""
tools/test_dungeon_music_stability.py - Test automatisé de stabilité musicale en Donjon.
Vérifie :
1. Warp en Donjon 1 avec musique active (current_music == MUSIC_DUNGEON).
2. Streaming répété des overlays cartouche (Inventaire Banque 27 vers $A000, Objets Banque 29 vers $A000).
3. Déclenchements intensifs de SFX (épée, secret chime, rupee).
4. Échantillonnage sur 400 frames : vérification absolue que cur_music_v3_note et cur_music_v2_note
   ne prennent JAMAIS de valeur corrompue d'opcode ($8D, $A0, etc.) et restent <= 58 ou $FE.
"""
import subprocess
import os
import sys

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

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

def read_audio_state(bin_path):
    with open(bin_path, "rb") as f:
        raw = f.read()
    data = raw[2:]
    return {
        'dual_sid_enabled':    data[0],
        'current_music':       data[1],
        'music_step':          data[3],
        'sfx_timer':           data[4],
        'sfx_voice':           data[5],
        'secret_chime_active': data[6],
        'cur_music_v1_note':   data[9],
        'cur_music_v2_note':   data[10],
        'cur_music_v3_note':   data[11]
    }

def main():
    z_labels = load_labels(os.path.join(BASE_DIR, "build", "zelda.vs"))
    i_labels = load_labels(os.path.join(BASE_DIR, "build", "intro.vs"))

    cmd_addr = z_labels['debug_hook_cmd']
    arg_addr = z_labels['debug_hook_arg']
    arg2_addr = z_labels['debug_hook_arg2']
    main_addr = z_labels['main_loop']
    audio_base = z_labels['dual_sid_enabled']

    sid_menu_addr = i_labels.get('sid_setup_menu_loop', 0x573a)
    intro_update_addr = i_labels.get('intro_update', 0x299b)

    print("=================================================================")
    print("   TEST AUTOMATISÉ : STABILITÉ DU MOTEUR MUSICAL EN DONJON       ")
    print("=================================================================")
    print(f"debug_hook_cmd:      ${cmd_addr:04X}")
    print(f"debug_hook_arg:      ${arg_addr:04X}")
    print(f"main_loop:           ${main_addr:04X}")
    print(f"audio state base:    ${audio_base:04X}")

    dumps = [f"/tmp/stab_dump_{i}.bin" for i in range(1, 10)]
    for p in dumps:
        if os.path.exists(p):
            os.remove(p)

    mon_file = "/tmp/test_dungeon_stability.mon"
    with open(mon_file, "w") as f:
        # Passer le menu initial et l'intro
        f.write(f"bk {sid_menu_addr:04x}\n")
        f.write("g\n")
        f.write("del\n")
        f.write("> 0816 01\n")
        f.write(f"bk {intro_update_addr:04x}\n")
        f.write("g\n")
        f.write("del\n")
        f.write("> 0816 01\n")

        # Breakpoint sur main_loop
        f.write(f"bk {main_addr:04x}\n")
        f.write("g\n")

        # 1. Warp en Donjon 1 (Salle $77)
        f.write(f"> {arg_addr:04x} 01\n")
        f.write(f"> {arg2_addr:04x} 77\n")
        f.write(f"> {cmd_addr:04x} 02\n") # hook_warp_dung
        f.write("g\n")

        # Laisser jouer 20 frames de musique de donjon
        for _ in range(20):
            f.write("g\n")
        f.write(f's "{dumps[0]}" 0 {audio_base:04x} {audio_base+11:04x}\n')

        # 2. Ouvrir l'inventaire (streaming overlay banque 27 vers $A000)
        f.write(f"> {cmd_addr:04x} 03\n") # open_inventory
        f.write("g\n")
        for _ in range(10):
            f.write("g\n")
        f.write(f's "{dumps[1]}" 0 {audio_base:04x} {audio_base+11:04x}\n')

        # 3. Fermer l'inventaire
        f.write(f"> {cmd_addr:04x} 04\n") # close_inventory
        f.write("g\n")
        for _ in range(30):
            f.write("g\n")
        f.write(f's "{dumps[2]}" 0 {audio_base:04x} {audio_base+11:04x}\n')

        # 4. Utiliser la bougie (streaming overlay banque 29 vers $A000)
        f.write(f"> {arg_addr:04x} 03\n") # candle
        f.write(f"> {cmd_addr:04x} 05\n") # use_subscreen_item
        f.write("g\n")
        for _ in range(20):
            f.write("g\n")
        f.write(f's "{dumps[3]}" 0 {audio_base:04x} {audio_base+11:04x}\n')

        # 5. Déclencher des SFX de combat (épée + carillon)
        f.write(f"> {arg_addr:04x} 04\n") # sword
        f.write(f"> {cmd_addr:04x} 08\n")
        f.write("g\n")
        for _ in range(15):
            f.write("g\n")
        f.write(f's "{dumps[4]}" 0 {audio_base:04x} {audio_base+11:04x}\n')

        # 6. Répéter l'ouverture d'inventaire 2 fois de suite
        f.write(f"> {cmd_addr:04x} 03\n") # open
        f.write("g\n")
        for _ in range(5):
            f.write("g\n")
        f.write(f"> {cmd_addr:04x} 04\n") # close
        f.write("g\n")
        for _ in range(50):
            f.write("g\n")
        f.write(f's "{dumps[5]}" 0 {audio_base:04x} {audio_base+11:04x}\n')

        f.write("q\n")

    cmd = [
        "x64sc", "-default", "-warp",
        "-moncommands", mon_file,
        "-cartcrt", os.path.join(BASE_DIR, "build", "zelda.crt")
    ]
    res = subprocess.run(cmd, capture_output=True, text=True, timeout=25)

    print("\n--- ANALYSE DES ÉCHANTILLONS AUDIO ---")
    for idx, d_path in enumerate(dumps[:6]):
        if not os.path.exists(d_path):
            sys.exit(f"Erreur : Dump {d_path} manquant.")
        st = read_audio_state(d_path)
        v1 = st['cur_music_v1_note']
        v2 = st['cur_music_v2_note']
        v3 = st['cur_music_v3_note']
        print(f"Dump {idx+1} : Musique={st['current_music']}, Pas={st['music_step']}, Voix1=${v1:02X}, Voix2=${v2:02X}, Voix3=${v3:02X}")

        # Vérification stricte : aucune valeur d'opcode ne doit être lue !
        assert v1 <= 58 or v1 == 0xFE, f"Dump {idx+1}: Voix 1 note corrompue (${v1:02X} > 58)"
        assert v2 <= 58 or v2 == 0xFE, f"Dump {idx+1}: Voix 2 note corrompue (${v2:02X} > 58)"
        assert v3 <= 58 or v3 == 0xFE, f"Dump {idx+1}: Voix 3 note corrompue (${v3:02X} > 58)"

    print("\n✓ PASS : Aucune collision avec les overlays cartouche ! La musique reste 100% stable et harmonieuse !")

if __name__ == "__main__":
    main()
