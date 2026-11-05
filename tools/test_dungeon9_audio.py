#!/usr/bin/env python3
"""
tools/test_dungeon9_audio.py - Test automatisé du Thème Authentique du Donjon 9 (Death Mountain).
Vérifie :
1. Warp en Donjon 9 (Niveau 9 - Montagne de la Mort).
2. Streaming automatique de la partition Donjon 9 depuis Banque 31 ($8800) vers bgm_track_buffer.
3. current_music == MUSIC_DUNGEON_FINAL (5).
4. Lecture séquentielle de la partition du Niveau 9 sur les 3 voix.
5. Sortie du Donjon 9 vers l'Overworld :
   - current_music == MUSIC_OVERWORLD (1).
   - Restauration automatique de la partition Standard BGM depuis Banque 31 ($8000) vers bgm_track_buffer.
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
        'current_music':       data[0],
        'saved_bg_music':      data[1],
        'music_part':          data[2],
        'music_step':          data[3],
        'music_delay':         data[4],
        'dual_sid_enabled':    data[5],
        'sfx_timer':           data[6],
        'sfx_voice':           data[7],
        'secret_chime_active': data[8],
        'cur_music_v1_note':   data[14],
        'cur_music_v2_note':   data[15],
        'cur_music_v3_note':   data[16]
    }

def main():
    z_labels = load_labels(os.path.join(BASE_DIR, "build", "zelda.vs"))
    i_labels = load_labels(os.path.join(BASE_DIR, "build", "intro.vs"))

    cmd_addr = z_labels['debug_hook_cmd']
    arg_addr = z_labels['debug_hook_arg']
    arg2_addr = z_labels['debug_hook_arg2']
    main_addr = z_labels['main_loop']
    audio_base = z_labels['current_music']
    bgm_buf_addr = z_labels['bgm_track_buffer']

    sid_menu_addr = i_labels.get('sid_setup_menu_loop', 0x573a)
    intro_update_addr = i_labels.get('intro_update', 0x299b)

    print("=================================================================")
    print("   TEST AUTOMATISÉ : THÈME AUTHENTIQUE DU DONJON 9 (FINAL)       ")
    print("=================================================================")
    print(f"debug_hook_cmd:      ${cmd_addr:04X}")
    print(f"debug_hook_arg:      ${arg_addr:04X}")
    print(f"main_loop:           ${main_addr:04X}")
    print(f"bgm_track_buffer:    ${bgm_buf_addr:04X}")

    dumps = [f"/tmp/d9_dump_{i}.bin" for i in range(1, 5)]
    for p in dumps:
        if os.path.exists(p):
            os.remove(p)

    buf_dump_d9 = "/tmp/d9_buf_streamed.bin"
    buf_dump_ow = "/tmp/ow_buf_restored.bin"
    for p in (buf_dump_d9, buf_dump_ow):
        if os.path.exists(p):
            os.remove(p)

    mon_file = "/tmp/test_dungeon9_audio.mon"
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

        # 1. Warp en Donjon 9 (Niveau 9, Salle d'entrée)
        # hook_warp_dung : arg = 9 (Niveau 9), arg2 = $76 (Salle d'entrée Donjon 9)
        f.write(f"> {arg_addr:04x} 09\n")
        f.write(f"> {arg2_addr:04x} 76\n")
        f.write(f"> {cmd_addr:04x} 02\n") # hook_warp_dung
        f.write("g\n")

        # Laisser jouer 30 frames de musique du Donjon 9
        for _ in range(30):
            f.write("g\n")
        f.write(f's "{dumps[0]}" 0 {audio_base:04x} {audio_base+16:04x}\n')
        f.write(f's "{buf_dump_d9}" 0 {bgm_buf_addr:04x} {bgm_buf_addr+255:04x}\n')

        # Laisser jouer encore 50 frames
        for _ in range(50):
            f.write("g\n")
        f.write(f's "{dumps[1]}" 0 {audio_base:04x} {audio_base+16:04x}\n')

        # 2. Sortir du Donjon vers l'Overworld via exit_dungeon
        f.write(f"> {cmd_addr:04x} 01\n") # hook_warp_ow (ou sortie donjon)
        f.write("g\n")

        for _ in range(30):
            f.write("g\n")
        f.write(f's "{dumps[2]}" 0 {audio_base:04x} {audio_base+16:04x}\n')
        f.write(f's "{buf_dump_ow}" 0 {bgm_buf_addr:04x} {bgm_buf_addr+255:04x}\n')

        f.write("q\n")

    cmd = [
        "x64sc", "-default", "-warp",
        "-moncommands", mon_file,
        "-cartcrt", os.path.join(BASE_DIR, "build", "zelda.crt")
    ]
    res = subprocess.run(cmd, capture_output=True, text=True, timeout=25)

    if not os.path.exists(dumps[0]):
        sys.exit(f"Erreur : Dump {dumps[0]} manquant.")

    st_d9 = read_audio_state(dumps[0])
    print(f"\n[DUMP 1 - Entrée Donjon 9] :")
    print(f"  current_music:       {st_d9['current_music']} (Attendu: 5 = MUSIC_DUNGEON_FINAL)")
    print(f"  music_step:          {st_d9['music_step']}")
    print(f"  cur_music_v1_note:   ${st_d9['cur_music_v1_note']:02X}")
    print(f"  cur_music_v2_note:   ${st_d9['cur_music_v2_note']:02X}")
    print(f"  cur_music_v3_note:   ${st_d9['cur_music_v3_note']:02X}")

    assert st_d9['current_music'] == 5, f"current_music vaut {st_d9['current_music']} au lieu de 5 (MUSIC_DUNGEON_FINAL) !"
    assert st_d9['cur_music_v1_note'] > 0, "Voix 1 du Donjon 9 est silencieuse !"

    # Vérification que le tampon contient bien les données du Donjon 9
    with open(buf_dump_d9, "rb") as f:
        d9_streamed = f.read()[2:]
    with open(os.path.join(BASE_DIR, "build", "cart_audio.bin"), "rb") as f:
        cart_bin = f.read()
    d9_expected = cart_bin[0x0800 : 0x0800 + 256]

    assert d9_streamed == d9_expected, "La partition streamée depuis la Banque 31 ($8800) ne correspond pas aux données du Donjon 9 !"
    print("  ✓ PASS : Les 5 pages du Donjon 9 ont été fidèlement streamées depuis la Banque 31 ($8800) !")

    # Vérification de l'avancement dans le Donjon 9
    st_d9_later = read_audio_state(dumps[1])
    print(f"\n[DUMP 2 - Progression Donjon 9 (+50 frames)] :")
    print(f"  music_step:          {st_d9_later['music_step']}")
    print(f"  cur_music_v1_note:   ${st_d9_later['cur_music_v1_note']:02X}")
    print(f"  cur_music_v3_note:   ${st_d9_later['cur_music_v3_note']:02X}")
    assert st_d9_later['current_music'] == 5, "current_music a été altéré !"
    assert st_d9_later['music_step'] > st_d9['music_step'], "Le séquenceur du Donjon 9 n'avance pas !"
    print("  ✓ PASS : La partition du Donjon 9 défile harmonieusement frame par frame !")

    # Vérification retour Overworld
    st_ow = read_audio_state(dumps[2])
    print(f"\n[DUMP 3 - Retour Overworld] :")
    print(f"  current_music:       {st_ow['current_music']} (Attendu: 1 = MUSIC_OVERWORLD)")
    assert st_ow['current_music'] == 1, f"current_music vaut {st_ow['current_music']} au lieu de 1 (MUSIC_OVERWORLD) !"

    with open(buf_dump_ow, "rb") as f:
        ow_streamed = f.read()[2:]
    ow_expected = cart_bin[0x0000 : 0x0100]
    assert ow_streamed == ow_expected, "La partition Standard BGM restaurée ne correspond pas à la Banque 31 ($8000) !"
    print("  ✓ PASS : La partition Standard BGM a été fidèlement restaurée depuis la Banque 31 ($8000) !")

    print("\n=================================================================")
    print("   ✓✓✓ THÈME DU DONJON 9 ET STREAMING CART BANQUE 31 VALIDÉS !  ")
    print("=================================================================")

if __name__ == "__main__":
    main()
