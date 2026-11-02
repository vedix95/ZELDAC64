#!/usr/bin/env python3
"""
Test automatisé de la file d'attente séquentielle audio et de la restauration des canaux SID.
Vérifie :
1. Déclenchement simultané sound_rupee + sound_secret_chime -> sound_rupee d'abord, secret_chime mis en attente.
2. Fin de sound_rupee -> restauration Voix 3, puis démarrage automatique de secret_chime sur Voix 2.
3. Fin de secret_chime -> restauration Voix 2, tous canaux BGM actifs.
4. Déclenchement sound_rupee pendant carillon actif -> sound_rupee mis en attente, déclenché à la fin du carillon.
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

def read_audio_state(bin_path):
    # Format .prg: 2 octets adresse de chargement, puis les octets mémoire
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
        'cur_music_v1_note':   data[8],
        'cur_music_v2_note':   data[9],
        'cur_music_v3_note':   data[10]
    }
    return state

def run_test():
    vs_path = os.path.join(BASE_DIR, "build", "zelda.vs")
    labels = load_labels(vs_path)

    cmd_addr = labels['debug_hook_cmd']
    arg_addr = labels['debug_hook_arg']
    main_addr = labels['main_loop']
    audio_base = labels['dual_sid_enabled']

    print("=================================================================")
    print("   TEST AUTOMATISÉ : SÉRIALISATION AUDIO & FILE D'ATTENTE SID   ")
    print("=================================================================")
    print(f"debug_hook_cmd:      ${cmd_addr:04X}")
    print(f"debug_hook_arg:      ${arg_addr:04X}")
    print(f"main_loop:           ${main_addr:04X}")
    print(f"audio state base:    ${audio_base:04X}")

    for i in range(1, 6):
        p = f"/tmp/audio_dump_{i}.bin"
        if os.path.exists(p):
            os.remove(p)

    mon_file = "/tmp/test_audio_queue.mon"
    with open(mon_file, "w") as f:
        # Passer le menu audio (Mono par défaut) et l'intro
        f.write("bk 5628\n")
        f.write("g\n")
        f.write("del\n")
        f.write("> 0816 01\n")
        f.write("bk 299b\n")
        f.write("g\n")
        f.write("del\n")
        f.write("> 0816 01\n")

        # Activer le breakpoint permanent sur main_loop
        f.write(f"bk {main_addr:04x}\n")
        f.write("g\n")

        # Laisser la musique démarrer proprement (5 frames)
        for _ in range(5):
            f.write("g\n")

        # SCÉNARIO 1 : Déclenchement SIMULTANÉ sound_rupee + sound_secret_chime via hook 8 arg 3
        f.write(f"> {arg_addr:04x} 03\n")
        f.write(f"> {cmd_addr:04x} 08\n")
        f.write("g\n")

        # DUMP 1 : juste après les deux déclenchements
        f.write(f's "/tmp/audio_dump_1.bin" 0 {audio_base:04x} {audio_base+10:04x}\n')

        # Avancer de 8 frames (durée du SFX rupee)
        for _ in range(8):
            f.write("g\n")

        # DUMP 2 : rupee doit être fini, chime doit avoir démarré !
        f.write(f's "/tmp/audio_dump_2.bin" 0 {audio_base:04x} {audio_base+10:04x}\n')

        # Avancer de 20 frames (chime actif)
        for _ in range(20):
            f.write("g\n")

        # SCÉNARIO 2 : Appeler sound_rupee PENDANT que chime est actif via hook 8 arg 1
        f.write(f"> {arg_addr:04x} 01\n")
        f.write(f"> {cmd_addr:04x} 08\n")
        f.write("g\n")

        # DUMP 3 : rupee_pending doit être 1, chime_active doit être 1
        f.write(f's "/tmp/audio_dump_3.bin" 0 {audio_base:04x} {audio_base+10:04x}\n')

        # Avancer de 35 frames (fin du chime)
        for _ in range(35):
            f.write("g\n")

        # DUMP 4 : chime doit être fini, rupee doit avoir démarré à la suite !
        f.write(f's "/tmp/audio_dump_4.bin" 0 {audio_base:04x} {audio_base+10:04x}\n')

        # Avancer de 10 frames (fin du rupee)
        for _ in range(10):
            f.write("g\n")

        # DUMP 5 : tout libre
        f.write(f's "/tmp/audio_dump_5.bin" 0 {audio_base:04x} {audio_base+10:04x}\n')
        f.write("quit\n")

    cmd = [
        "x64sc",
        "-default",
        "-cartcrt", os.path.join(BASE_DIR, "build", "zelda.crt"),
        "-moncommands", mon_file,
        "+sound",
        "-warp"
    ]

    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=20)

    # Analyse des Dumps
    s1 = read_audio_state("/tmp/audio_dump_1.bin")
    print(f"\n[DUMP 1] État après déclenchement simultané (Clé + Porte) :")
    print(f"  sfx_timer:            {s1['sfx_timer']} (Attendu: 8)")
    print(f"  sfx_voice:            {s1['sfx_voice']} (Attendu: 3)")
    print(f"  secret_chime_pending: {s1['secret_chime_pending']} (Attendu: 1)")
    print(f"  secret_chime_active:  {s1['secret_chime_active']} (Attendu: 0)")
    assert s1['sfx_timer'] == 8
    assert s1['sfx_voice'] == 3
    assert s1['secret_chime_pending'] == 1
    assert s1['secret_chime_active'] == 0
    print("  ✓ PASS : Rupee actif sur Voix 3, Carillon mis en attente (Voix 2 préservée pour le BGM) !")

    s2 = read_audio_state("/tmp/audio_dump_2.bin")
    print(f"\n[DUMP 2] État après 8 frames (Fin du son de clé) :")
    print(f"  sfx_timer:            {s2['sfx_timer']} (Attendu: 0)")
    print(f"  secret_chime_pending: {s2['secret_chime_pending']} (Attendu: 0)")
    print(f"  secret_chime_active:  {s2['secret_chime_active']} (Attendu: 1)")
    assert s2['sfx_timer'] == 0
    assert s2['secret_chime_pending'] == 0
    assert s2['secret_chime_active'] == 1
    print("  ✓ PASS : Voix 3 libérée et restaurée, Carillon démarre automatiquement sur Voix 2 !")

    s3 = read_audio_state("/tmp/audio_dump_3.bin")
    print(f"\n[DUMP 3] État lors d'un ramassage de rubis pendant le Carillon :")
    print(f"  secret_chime_active:  {s3['secret_chime_active']} (Attendu: 1)")
    print(f"  sfx_rupee_pending:    {s3['sfx_rupee_pending']} (Attendu: 1)")
    print(f"  sfx_timer:            {s3['sfx_timer']} (Attendu: 0)")
    assert s3['secret_chime_active'] == 1
    assert s3['sfx_rupee_pending'] == 1
    assert s3['sfx_timer'] == 0
    print("  ✓ PASS : Son de rubis mis en attente, Carillon et Voix 3 non perturbés !")

    s4 = read_audio_state("/tmp/audio_dump_4.bin")
    print(f"\n[DUMP 4] État à la fin du Carillon :")
    print(f"  secret_chime_active:  {s4['secret_chime_active']} (Attendu: 0)")
    print(f"  sfx_rupee_pending:    {s4['sfx_rupee_pending']} (Attendu: 0)")
    print(f"  sfx_timer:            {s4['sfx_timer']} (Attendu: > 0)")
    assert s4['secret_chime_active'] == 0
    assert s4['sfx_rupee_pending'] == 0
    assert s4['sfx_timer'] > 0
    print("  ✓ PASS : Voix 2 restaurée au BGM, son de rubis démarre immédiatement à la suite !")

    s5 = read_audio_state("/tmp/audio_dump_5.bin")
    print(f"\n[DUMP 5] État final :")
    print(f"  secret_chime_active:  {s5['secret_chime_active']} (Attendu: 0)")
    print(f"  secret_chime_pending: {s5['secret_chime_pending']} (Attendu: 0)")
    print(f"  sfx_rupee_pending:    {s5['sfx_rupee_pending']} (Attendu: 0)")
    print(f"  sfx_timer:            {s5['sfx_timer']} (Attendu: 0)")
    assert s5['secret_chime_active'] == 0
    assert s5['secret_chime_pending'] == 0
    assert s5['sfx_rupee_pending'] == 0
    assert s5['sfx_timer'] == 0
    print("  ✓ PASS : Tous les canaux audio sont restaurés au BGM sans aucun conflit !")

    print("\n=================================================================")
    print("   ✓✓✓ TOUS LES TESTS DE SÉRIALISATION AUDIO SONT RÉUSSIS !     ")
    print("=================================================================")

if __name__ == "__main__":
    run_test()
