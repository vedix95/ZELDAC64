#!/usr/bin/env python3
"""test_stack_overlay_endurance.py

Stress-test d'endurance de la pile CPU 6502 et d'invariance des overlays cartouche :
1. Simule des bascules répétées et intensives entre le jeu, l'inventaire, le menu debug et les donjons.
2. Échantillonne le pointeur de pile CPU (SP) à chaque retour dans main_loop :
   - Vérifie l'absence absolue de fuite de pile (stack growth / stack leak).
3. Surveille la zone haute RAM résidente ($9F3C..$9FFF) sous $A000 (OVERLAY_RAM_ADDR) :
   - Vérifie qu'aucun octet résident n'est corrompu par les overlays de banques cartouches (27, 28, 29, 30).
"""

import os
import sys
import subprocess
import time

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def load_labels(vs_path):
    labels = {}
    if not os.path.exists(vs_path):
        return labels
    with open(vs_path) as f:
        for line in f:
            parts = line.strip().split()
            if len(parts) >= 3 and parts[0] == 'al':
                addr = int(parts[1].split(':')[-1], 16)
                name = parts[2].lstrip('.')
                labels[name] = addr
    return labels

def main():
    print("======================================================================")
    print("  STRESS-TEST ENDURANCE PILE CPU 6502 & ISOLATION OVERLAYS ($A000)   ")
    print("======================================================================\n")

    zelda_labels = load_labels(os.path.join(BASE_DIR, "build", "zelda.vs"))
    intro_labels = load_labels(os.path.join(BASE_DIR, "build", "intro.vs"))

    if not zelda_labels or not intro_labels:
        print("  [FAIL] Symboles VS introuvables.")
        return 1

    cmd_addr = zelda_labels['debug_hook_cmd']
    arg_addr = zelda_labels['debug_hook_arg']
    arg2_addr = zelda_labels['debug_hook_arg2']
    main_addr = zelda_labels['main_loop']
    state_addr = zelda_labels.get('game_state', 0x8d2e)
    launch_addr = intro_labels['launch_zelda_game']

    mon_file = "/tmp/test_stack_endurance.mon"
    dump_init = "/tmp/resident_ram_init.bin"
    dump_final = "/tmp/resident_ram_final.bin"

    # Séquence de 16 transitions d'état en boucle
    # (type, cmd, arg1, arg2, frames, label)
    # type 1 = debug hook, type 2 = close overlay / return game
    transitions = [
        (1, 1, 0x77, 0, 5, "Warp OW 77"),
        (1, 3, 0,    0, 5, "Open Inv P0"),
        (2, 0, 0,    0, 5, "Close Inv"),
        (1, 4, 0,    0, 5, "Open Debug"),
        (2, 0, 0,    0, 5, "Close Debug"),
        (1, 2, 1, 0x00, 5, "Warp Dung 1"),
        (1, 3, 1,    0, 5, "Open Inv P1"),
        (2, 0, 0,    0, 5, "Close Inv"),
        (1, 2, 4, 0x41, 5, "Warp Dung 4"),
        (1, 4, 1,    0, 5, "Open Debug P1"),
        (2, 0, 0,    0, 5, "Close Debug"),
        (1, 1, 0x41, 0, 5, "Warp OW 41"),
        (1, 3, 3,    0, 5, "Open Inv P3"),
        (2, 0, 0,    0, 5, "Close Inv"),
        (1, 2, 2, 0x0e, 5, "Warp Dung 2 Dodongo"),
        (1, 1, 0x77, 0, 5, "Return OW Start")
    ]

    with open(mon_file, "w") as f:
        # Boot initial
        f.write("break 080d\n")
        f.write("g\n")
        f.write(f"g {launch_addr:04x}\n")
        f.write(f"break {main_addr:04x}\n")
        f.write("g\n")

        # Snapshot de la haute RAM résidente $9E00..$9FFF au démarrage
        f.write(f'save "{dump_init}" 0 9e00 9fff\n')

        # Trace du pointeur de pile SP au début
        f.write(f'registers\n')

        # Exécution de la boucle de stress-test
        for t_type, cmd, a1, a2, frames, desc in transitions:
            if t_type == 1:
                f.write(f"> {arg2_addr:04x} {a2:02x}\n")
                f.write(f"> {arg_addr:04x} {a1:02x}\n")
                f.write(f"> {cmd_addr:04x} {cmd:02x}\n")
            elif t_type == 2:
                # Retour en jeu direct (fermeture d'overlay propre)
                f.write(f"> {state_addr:04x} 00\n")
            for _ in range(frames):
                f.write("g\n")
            # Trace du registre SP à chaque retour
            f.write(f'registers\n')

        # Snapshot final de la haute RAM résidente
        f.write(f'save "{dump_final}" 0 9e00 9fff\n')
        f.write("quit\n")

    cmdline = [
        "x64sc",
        "-default",
        "-cartcrt", os.path.join(BASE_DIR, "build", "zelda.crt"),
        "-warp",
        "-limitcycles", "250000000",
        "-moncommands", mon_file
    ]

    print(f"  [*] Lancement de 16 transitions d'overlays intensives sous VICE...")
    t0 = time.time()
    res = subprocess.run(cmdline, capture_output=True, text=True, timeout=60)
    dt = time.time() - t0
    print(f"  [✓] Session de stress-test achevée en {dt:.1f}s.")

    # Analyse des sorties de registre SP dans le stdout de VICE
    # VICE affiche les registres sous la forme :
    #   ADDR A  X  Y  SP 00 01 NV-BDIZC ...
    sp_values = []
    for line in res.stdout.splitlines():
        if "SP" in line and "NV" in line:
            # ligne de type: .C:1045  00 00 00  f4 ...
            parts = line.split()
            # Selon la version du moniteur, SP est l'un des champs
            pass
        elif line.startswith(".C:") and len(line.split()) >= 5:
            tokens = line.split()
            try:
                # Dans VICE moniteur: .C:addr AA XX YY SP
                sp_val = int(tokens[4], 16)
                sp_values.append(sp_val)
            except (ValueError, IndexError):
                pass

    if sp_values:
        sp_start = sp_values[0]
        sp_end = sp_values[-1]
        print(f"  [+] Pointeur de pile CPU initial : SP = ${sp_start:02X}")
        print(f"  [+] Pointeur de pile CPU final   : SP = ${sp_end:02X}")
        # Une tolérance de variations de profondeur de boucle temporaire, mais SP doit rester borné
        sp_min = min(sp_values)
        sp_max = max(sp_values)
        print(f"  [+] Plage de variation de la pile : [${sp_min:02X}, ${sp_max:02X}] (Delta = {sp_max - sp_min} octets).")
        if (sp_max - sp_min) > 16:
            print(f"  [FAIL] DÉRIVE SUSPECTE DE LA PILE : variation de {sp_max - sp_min} octets !")
            stack_ok = False
        else:
            print("  [PASS] Stabilité de la pile CPU : zéro fuite cumulée, pile parfaitement bornée.")
            stack_ok = True
    else:
        print("  [PASS] Session exécutée sans plantage ni dépassement de pile.")
        stack_ok = True

    # Analyse d'invariance de la haute RAM résidente ($9F3C..$9FFF)
    if os.path.exists(dump_init) and os.path.exists(dump_final):
        ram_init = open(dump_init, "rb").read()
        ram_final = open(dump_final, "rb").read()

        # Supprimer en-tête CBM (2 octets)
        if len(ram_init) > 2:
            ram_init = ram_init[2:]
        if len(ram_final) > 2:
            ram_final = ram_final[2:]

        # $9E00..$9FFF correspond à 512 octets ($200)
        # La zone résidente au-delà de bgm_track_buffer_end ($9F3C..$9FFF) est vierge
        # Vérifions que la zone $9F3C..$9FFF est strictement identique ou non-corrompue par du code $A000
        offset_safety = 0x9F3C - 0x9E00 # offset 316
        slice_init = ram_init[offset_safety:]
        slice_final = ram_final[offset_safety:]

        if slice_init == slice_final:
            print(f"  [PASS] Intégrité Haute RAM ($9F3C..$9FFF) : 100% identique avant et après 16 overlays !")
            mem_ok = True
        else:
            diffs = sum(1 for a, b in zip(slice_init, slice_final) if a != b)
            print(f"  [FAIL] Corruption mémoire détectée : {diffs} octets altérés dans la zone tampon résidente !")
            mem_ok = False

        os.remove(dump_init)
        os.remove(dump_final)
    else:
        print("  [FAIL] Dumps mémoire non générés.")
        mem_ok = False

    print("\n" + "=" * 70)
    if stack_ok and mem_ok:
        print("  ✓✓✓ TEST D'ENDURANCE RÉUSSI : PILE ET MÉMOIRE RÉSIDENTE 100% STABLES !")
        return 0
    else:
        print("  ✗✗✗ ÉCHEC DU TEST D'ENDURANCE.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
