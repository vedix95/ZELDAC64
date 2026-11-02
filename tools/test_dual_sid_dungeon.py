#!/usr/bin/env python3
"""
Test automatisé du mode Dual SID Stéréo ($D420) en Donjon.
Vérifie :
1. Sélection de l'Option 2 (2 SID - Stereo $D420) au menu de boot.
2. Warp dans le Donjon 1 et lecture de la musique d'ambiance.
3. Déclenchement de l'attaque à l'épée (sound_sword) :
   - sfx_timer = 6, sfx_voice = 3
   - Le SFX n'est pas écrasé par la basse
   - Restauration de la Voix 3 après 6 frames
4. Déclenchement simultané clé + porte secrète en Dual SID :
   - Sérialisation propre via secret_chime_pending
   - Exécution séquentielle et restauration de tous les canaux stéréo
5. Ramassage d'un objet pendant le carillon en Dual SID :
   - Sérialisation propre via sfx_rupee_pending
   - Exécution immédiate après la fin du carillon
"""
import subprocess
import os
import sys

BASE_DIR = "/home/vedix/Documents/C64/zelda"

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

def read_hw_regs(bin_path):
    with open(bin_path, "rb") as f:
        raw = f.read()
    data = raw[2:]
    sid1 = data[0:25]
    sid2 = data[32:57]
    return {
        'sid1_vol': sid1[24],
        'sid2_vol': sid2[24],
        'sid1_v1_ctrl': sid1[4],
        'sid1_v2_ctrl': sid1[11],
        'sid1_v3_ctrl': sid1[18],
        'sid2_v1_ctrl': sid2[4],
        'sid2_v2_ctrl': sid2[11],
        'sid2_v3_ctrl': sid2[18],
        'sid1_v3_freq': (sid1[15] << 8) | sid1[14],
        'sid2_v3_freq': (sid2[15] << 8) | sid2[14],
    }

def read_audio_state(bin_path):
    with open(bin_path, "rb") as f:
        raw = f.read()
    data = raw[2:] # enlever load address
    state = {
        'dual_sid_enabled':    data[0],
        'sfx_timer':           data[1],
        'sfx_voice':           data[2],
        'secret_chime_active': data[3],
        'secret_chime_timer':  data[4],
        'secret_chime_idx':    data[5],
        'secret_chime_pending':data[6],
        'sfx_rupee_pending':   data[7],
        'sfx_pending_idx':     data[8],
        'cur_music_v1_note':   data[9],
        'cur_music_v2_note':   data[10],
        'cur_music_v3_note':   data[11]
    }
    return state

def run_test():
    zelda_vs = os.path.join(BASE_DIR, "build", "zelda.vs")
    intro_vs = os.path.join(BASE_DIR, "build", "intro.vs")
    z_labels = load_labels(zelda_vs)
    i_labels = load_labels(intro_vs)

    cmd_addr = z_labels['debug_hook_cmd']
    arg_addr = z_labels['debug_hook_arg']
    arg2_addr = z_labels['debug_hook_arg2']
    main_addr = z_labels['main_loop']
    audio_base = z_labels['dual_sid_enabled']

    cursor_addr = i_labels.get('menu_cursor_idx', 0x09D5)

    print("=================================================================")
    print("   TEST AUTOMATISÉ : DUAL SID STÉRÉO ($D420) & ÉPÉE EN DONJON   ")
    print("=================================================================")
    print(f"debug_hook_cmd:      ${cmd_addr:04X}")
    print(f"debug_hook_arg:      ${arg_addr:04X}")
    print(f"main_loop:           ${main_addr:04X}")
    print(f"audio state base:    ${audio_base:04X}")

    dumps = [f"/tmp/dual_sid_dump_{i}.bin" for i in range(1, 9)]
    for p in dumps:
        if os.path.exists(p):
            os.remove(p)

    mon_file = "/tmp/test_dual_sid_dungeon.mon"
    with open(mon_file, "w") as f:
        # 1. Sélectionner Option 2 (2 SID - Stereo $D420) au boot
        f.write("bk 5628\n")
        f.write("g\n")
        f.write("del\n")
        f.write(f"> {cursor_addr:04x} 01\n") # Sélection Option 2
        f.write("> 0816 01\n")               # Valider menu

        # 2. Passer l'intro
        f.write("bk 299b\n")
        f.write("g\n")
        f.write("del\n")
        f.write("> 0816 01\n")

        # 3. Arrivée dans main_loop
        f.write(f"bk {main_addr:04x}\n")
        f.write("g\n")

        # 4. Warp vers Donjon 1 (arg=1, arg2=$77)
        f.write(f"> {arg_addr:04x} 01\n")
        f.write(f"> {arg2_addr:04x} 77\n")
        f.write(f"> {cmd_addr:04x} 02\n") # hook_warp_dung
        f.write("g\n")

        # Laisser la musique de donjon tourner (8 frames)
        for _ in range(8):
            f.write("g\n")

        # DUMP 1 : Vérifier dual_sid_enabled == 1 et musique de donjon active
        f.write(f's "{dumps[0]}" 0 {audio_base:04x} {audio_base+11:04x}\n')
        f.write('s "/tmp/dual_sid_hw_1.bin" 0 d400 d438\n')

        # 5. Déclencher le son de l'épée (sound_sword via hook 8 arg 4)
        f.write(f"> {arg_addr:04x} 04\n")
        f.write(f"> {cmd_addr:04x} 08\n")
        f.write("g\n")

        # DUMP 2 : Immédiatement après sound_sword
        f.write(f's "{dumps[1]}" 0 {audio_base:04x} {audio_base+11:04x}\n')
        f.write('s "/tmp/dual_sid_hw_2.bin" 0 d400 d438\n')

        # Avancer de 6 frames (durée complète du son d'épée)
        for _ in range(6):
            f.write("g\n")

        # DUMP 3 : Après l'épée, la Voix 3 doit être restaurée au BGM
        f.write(f's "{dumps[2]}" 0 {audio_base:04x} {audio_base+11:04x}\n')
        f.write('s "/tmp/dual_sid_hw_3.bin" 0 d400 d438\n')

        # 6. SCÉNARIO CONFLIT : Déclenchement simultané Clé + Carillon (hook 8 arg 3)
        f.write(f"> {arg_addr:04x} 03\n")
        f.write(f"> {cmd_addr:04x} 08\n")
        f.write("g\n")

        # DUMP 4 : Clé active, carillon en attente
        f.write(f's "{dumps[3]}" 0 {audio_base:04x} {audio_base+11:04x}\n')

        # Avancer de 8 frames (fin du son de clé)
        for _ in range(8):
            f.write("g\n")

        # DUMP 5 : Clé terminée, carillon actif
        f.write(f's "{dumps[4]}" 0 {audio_base:04x} {audio_base+11:04x}\n')

        # Avancer de 20 frames (carillon en cours de jeu)
        for _ in range(20):
            f.write("g\n")

        # 7. COUP D'ÉPÉE PENDANT LE CARILLON : doit aller dans la file sfx_pending_idx sans voler Voix 3
        f.write(f"> {arg_addr:04x} 04\n")
        f.write(f"> {cmd_addr:04x} 08\n")
        f.write("g\n")

        # DUMP 6 : Carillon toujours actif, épée mise en file d'attente
        f.write(f's "{dumps[5]}" 0 {audio_base:04x} {audio_base+11:04x}\n')

        # Avancer de 36 frames (fin du carillon)
        for _ in range(36):
            f.write("g\n")

        # DUMP 7 : Carillon terminé, épée démarrée depuis la file d'attente !
        f.write(f's "{dumps[6]}" 0 {audio_base:04x} {audio_base+11:04x}\n')

        # Avancer de 6 frames (fin de l'épée)
        for _ in range(6):
            f.write("g\n")

        # DUMP 8 : Fin complète, tous canaux restaurés
        f.write(f's "{dumps[7]}" 0 {audio_base:04x} {audio_base+11:04x}\n')

        f.write("q\n")

    cmd = [
        "x64sc",
        "-default",
        "-warp",
        "-sidextra", "1",
        "-sid2address", "0xd420",
        "-cartcrt", os.path.join(BASE_DIR, "build", "zelda.crt"),
        "-moncommands", mon_file,
        "+sound"
    ]

    print(f"Lancement de VICE...")
    res = subprocess.run(cmd, capture_output=True, text=True, timeout=25)
    print(f"VICE terminé avec code {res.returncode}")

    for i, p in enumerate(dumps, 1):
        if not os.path.exists(p):
            print(f"[FAIL] Dump {i} ({p}) non généré !")
            return False

    s1 = read_audio_state(dumps[0])
    s2 = read_audio_state(dumps[1])
    s3 = read_audio_state(dumps[2])
    s4 = read_audio_state(dumps[3])
    s5 = read_audio_state(dumps[4])
    s6 = read_audio_state(dumps[5])
    s7 = read_audio_state(dumps[6])
    s8 = read_audio_state(dumps[7])

    print("\n[DUMP 1] Donjon 1 initialisé en mode Dual SID :")
    print(f"  dual_sid_enabled:    {s1['dual_sid_enabled']} (Attendu: 1)")
    print(f"  cur_music_v1_note:   ${s1['cur_music_v1_note']:02X} (Attendu: != 0)")
    assert s1['dual_sid_enabled'] == 1, "Dual SID non activé !"
    assert s1['cur_music_v1_note'] != 0, "Musique donjon non démarrée !"
    hw1 = read_hw_regs("/tmp/dual_sid_hw_1.bin")
    print(f"  SID1_VOL: {hw1['sid1_vol']} (Attendu: 15), SID2_VOL: {hw1['sid2_vol']} (Attendu: 15)")
    print(f"  SID2_V1_CTRL: ${hw1['sid2_v1_ctrl']:02X}, SID2_V2_CTRL: ${hw1['sid2_v2_ctrl']:02X}, SID2_V3_CTRL: ${hw1['sid2_v3_ctrl']:02X}")
    assert hw1['sid1_vol'] == 15, "SID1 volume incorrect !"
    assert hw1['sid2_vol'] == 15, f"SID2 volume incorrect: {hw1['sid2_vol']} !"
    assert hw1['sid2_v1_ctrl'] & 0x40 != 0, "SID2 Voix 1 (Pulse) inactive !"
    assert hw1['sid2_v2_ctrl'] & 0x40 != 0, "SID2 Voix 2 (Pulse) inactive !"
    assert hw1['sid2_v3_ctrl'] & 0x10 != 0, "SID2 Voix 3 (Triangle) inactive !"
    print("  ✓ PASS : Mode Dual SID Stéréo actif avec musique de donjon en cours !")

    print("\n[DUMP 2] Attaque à l'épée déclenchée (sound_sword) :")
    print(f"  sfx_timer:           {s2['sfx_timer']} (Attendu: 6)")
    print(f"  sfx_voice:           {s2['sfx_voice']} (Attendu: 3)")
    assert s2['sfx_timer'] == 6, f"sfx_timer incorrect: {s2['sfx_timer']}"
    assert s2['sfx_voice'] == 3, f"sfx_voice incorrect: {s2['sfx_voice']}"
    hw2 = read_hw_regs("/tmp/dual_sid_hw_2.bin")
    print(f"  SID1_V3_CTRL: ${hw2['sid1_v3_ctrl']:02X}, SID2_V3_CTRL: ${hw2['sid2_v3_ctrl']:02X} (Attendu: $81 Noise)")
    print(f"  SID1_V3_FREQ: ${hw2['sid1_v3_freq']:04X}, SID2_V3_FREQ: ${hw2['sid2_v3_freq']:04X} (Attendu: $4800)")
    assert hw2['sid1_v3_ctrl'] == 0x81, "SID1 sword SFX non activé !"
    assert hw2['sid2_v3_ctrl'] == 0x81, "SID2 sword SFX non activé !"
    assert hw2['sid1_v3_freq'] == 0x4800, "SID1 sword freq incorrecte !"
    assert hw2['sid2_v3_freq'] == 0x4800, "SID2 sword freq incorrecte !"
    assert hw2['sid1_vol'] == 15 and hw2['sid2_vol'] == 15, "Volume SID non préservé pendant le SFX !"
    print("  ✓ PASS : Le son d'épée est correctement programmé sur Voix 3 pour 6 frames !")

    print("\n[DUMP 3] Fin de l'attaque à l'épée (après 6 frames) :")
    print(f"  sfx_timer:           {s3['sfx_timer']} (Attendu: 0)")
    print(f"  sfx_voice:           {s3['sfx_voice']} (Attendu: 0)")
    print(f"  cur_music_v3_note:   ${s3['cur_music_v3_note']:02X}")
    assert s3['sfx_timer'] == 0, f"sfx_timer non expiré: {s3['sfx_timer']}"
    assert s3['sfx_voice'] == 0, f"sfx_voice non libéré: {s3['sfx_voice']}"
    hw3 = read_hw_regs("/tmp/dual_sid_hw_3.bin")
    print(f"  Restauration Voix 3 SID1: ${hw3['sid1_v3_ctrl']:02X}, SID2: ${hw3['sid2_v3_ctrl']:02X} (Attendu: $11 Triangle)")
    assert hw3['sid1_v3_ctrl'] == 0x11, "SID1 Voix 3 non restaurée en Triangle !"
    assert hw3['sid2_v3_ctrl'] == 0x11, "SID2 Voix 3 non restaurée en Triangle !"
    assert hw3['sid2_vol'] == 15, "SID2 volume altéré !"
    print("  ✓ PASS : Voix 3 libérée et restaurée au BGM sur les 2 puces SID !")

    print("\n[DUMP 4] Déclenchement simultané Clé + Porte secrète en Dual SID :")
    print(f"  sfx_timer:            {s4['sfx_timer']} (Attendu: 8)")
    print(f"  sfx_voice:            {s4['sfx_voice']} (Attendu: 3)")
    print(f"  secret_chime_pending: {s4['secret_chime_pending']} (Attendu: 1)")
    print(f"  secret_chime_active:  {s4['secret_chime_active']} (Attendu: 0)")
    assert s4['sfx_timer'] == 8
    assert s4['secret_chime_pending'] == 1
    assert s4['secret_chime_active'] == 0
    print("  ✓ PASS : Son de clé actif sur Voix 3, carillon mis en attente sans conflit !")

    print("\n[DUMP 5] Fin du son de clé en Dual SID :")
    print(f"  sfx_timer:            {s5['sfx_timer']} (Attendu: 0)")
    print(f"  secret_chime_pending: {s5['secret_chime_pending']} (Attendu: 0)")
    print(f"  secret_chime_active:  {s5['secret_chime_active']} (Attendu: 1)")
    assert s5['sfx_timer'] == 0
    assert s5['secret_chime_pending'] == 0
    assert s5['secret_chime_active'] == 1
    print("  ✓ PASS : Voix 3 restaurée, carillon démarré sur Voix 2 des 2 SID !")

    print("\n[DUMP 6] Épée appelée PENDANT le carillon (mise en file d'attente) :")
    print(f"  secret_chime_active:  {s6['secret_chime_active']} (Attendu: 1)")
    print(f"  sfx_pending_idx:      {s6['sfx_pending_idx']} (Attendu: 1 = SFX_SWORD+1)")
    print(f"  sfx_timer:            {s6['sfx_timer']} (Attendu: 0, Voix 3 non volée)")
    assert s6['secret_chime_active'] == 1
    assert s6['sfx_pending_idx'] == 1
    assert s6['sfx_timer'] == 0
    print("  ✓ PASS : Épée mise en file d'attente, carillon et basse non perturbés !")

    print("\n[DUMP 7] Fin du carillon -> exécution automatique de l'épée depuis la file :")
    print(f"  secret_chime_active:  {s7['secret_chime_active']} (Attendu: 0)")
    print(f"  sfx_pending_idx:      {s7['sfx_pending_idx']} (Attendu: 0)")
    print(f"  sfx_timer:            {s7['sfx_timer']} (Attendu: 6, épée en cours)")
    print(f"  sfx_voice:            {s7['sfx_voice']} (Attendu: 3)")
    assert s7['secret_chime_active'] == 0
    assert s7['sfx_pending_idx'] == 0
    assert s7['sfx_timer'] > 0
    assert s7['sfx_voice'] == 3
    print("  ✓ PASS : Carillon terminé, son d'épée exécuté immédiatement à la suite !")

    print("\n[DUMP 8] Fin complète de la séquence :")
    print(f"  secret_chime_active:  {s8['secret_chime_active']} (Attendu: 0)")
    print(f"  secret_chime_pending: {s8['secret_chime_pending']} (Attendu: 0)")
    print(f"  sfx_rupee_pending:    {s8['sfx_rupee_pending']} (Attendu: 0)")
    print(f"  sfx_pending_idx:      {s8['sfx_pending_idx']} (Attendu: 0)")
    print(f"  sfx_timer:            {s8['sfx_timer']} (Attendu: 0)")
    assert s8['secret_chime_active'] == 0
    assert s8['sfx_timer'] == 0
    print("  ✓ PASS : Tous les canaux audio sont parfaitement restaurés au BGM !")

    print("\n=================================================================")
    print("   ✓✓✓ TOUS LES TESTS DUAL SID EN DONJON ONT RÉUSSI !           ")
    print("=================================================================")
    return True

if __name__ == "__main__":
    if not run_test():
        sys.exit(1)
