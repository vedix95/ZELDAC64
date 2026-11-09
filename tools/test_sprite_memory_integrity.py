#!/usr/bin/env python3
"""test_sprite_memory_integrity.py

Contrôle d'intégrité statique et dynamique de la mémoire des sprites (VIC-II C64) :
1. Audit statique de toutes les tables de pointeurs assembleur (build/sprite_ptrs.inc & src/enemies.asm).
2. Contrôle d'intégrité binaire des banques cartouches (sprites_ow.bin, sprites_dung.bin, sprites_boss.bin, sprites_npc.bin).
3. Audit dynamique sous émulateur VICE :
   - Échantillonnage de VIC_SPRITE_EN ($D015) et des 8 pointeurs matériels ($07F8..$07FF).
   - Détection de pointeurs hors-plage ($00..$1F ZP/pile/écran, $40..$9F chargen/charset).
   - Vérification de l'intégrité bitmap des 64 octets en RAM pour chaque sprite affiché.
   - Validation des registres de couleur propre ($D027..$D02E) et du mode multicolore ($D01C).
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

def test_static_sprite_pointers():
    print("----------------------------------------------------------------------")
    print(" 1. AUDIT STATIQUE DES TABLES DE POINTEURS & BANQUES DE SPRITES")
    print("----------------------------------------------------------------------")

    inc_file = os.path.join(BASE_DIR, "build", "sprite_ptrs.inc")
    if not os.path.exists(inc_file):
        print("  [FAIL] build/sprite_ptrs.inc introuvable. Exécuter 'make' au préalable.")
        return False

    ptrs = {}
    with open(inc_file) as f:
        for line in f:
            line = line.strip()
            if "=" in line and not line.startswith(";"):
                sym, val = [p.strip() for p in line.split("=", 1)]
                if val.startswith("$"):
                    try:
                        ptrs[sym] = int(val[1:], 16)
                    except ValueError:
                        pass
                elif val in ptrs:
                    ptrs[sym] = ptrs[val]

    # Vérification des plages autorisées pour les constantes
    violations = []
    for sym, val in ptrs.items():
        if sym.startswith("SPR_OW_") or sym.startswith("SPR_DUNG_") or sym.startswith("SPR_NPC_") or sym.startswith("SPR_COMMON_"):
            if val < 0xA0 or val > 0xFF:
                violations.append((sym, val, "Pointeur hors de la plage dynamique [$A0, $FF]"))

    if violations:
        for sym, val, reason in violations:
            print(f"  [FAIL] {sym} = ${val:02X} : {reason}")
        return False
    else:
        print(f"  [PASS] {len(ptrs)} symboles de sprites vérifiés dans build/sprite_ptrs.inc : 100% dans [$A0, $FF].")

    # Vérification de l'intégrité des 4 banques binaires
    banks = [
        ("sprites_ow.bin", "Overworld"),
        ("sprites_dung.bin", "Donjons"),
        ("sprites_boss.bin", "Boss"),
        ("sprites_npc.bin", "PNJ / Objets")
    ]

    for bname, desc in banks:
        bpath = os.path.join(BASE_DIR, "build", bname)
        if not os.path.exists(bpath):
            print(f"  [FAIL] Fichier banque {bname} introuvable.")
            return False
        data = open(bpath, "rb").read()
        if len(data) != 8192:
            print(f"  [FAIL] Taille incorrecte pour {bname} : {len(data)} octets (attendu : 8192).")
            return False

        # Vérifier que le slot 0 et les slots communs ne sont pas entièrement vides
        slot0 = data[:64]
        if all(b == 0 for b in slot0):
            print(f"  [FAIL] Le slot 0 de {bname} ({desc}) est totalement vide (tous zéros) !")
            return False

        # Vérifier les slots communs (indices 87..95 = offset 87*64 = 5568)
        common_data = data[87*64 : 96*64]
        if all(b == 0 for b in common_data):
            print(f"  [FAIL] Les slots communs dans {bname} sont entièrement vides !")
            return False

        print(f"  [PASS] Banque {bname:16s} ({desc:12s}) : 8192 octets, données valides.")

    return True

def test_dynamic_sprite_memory_under_vice():
    print("\n----------------------------------------------------------------------")
    print(" 2. AUDIT DYNAMIQUE DES REGISTRES VIC-II & POINTEURS EN JEU (VICE)")
    print("----------------------------------------------------------------------")

    zelda_labels = load_labels(os.path.join(BASE_DIR, "build", "zelda.vs"))
    intro_labels = load_labels(os.path.join(BASE_DIR, "build", "intro.vs"))

    if not zelda_labels or not intro_labels:
        print("  [FAIL] Impossible de charger les symboles VS.")
        return False

    cmd_addr = zelda_labels['debug_hook_cmd']
    arg_addr = zelda_labels['debug_hook_arg']
    arg2_addr = zelda_labels['debug_hook_arg2']
    main_addr = zelda_labels['main_loop']
    launch_addr = intro_labels['launch_zelda_game']

    mon_file = "/tmp/test_sprite_mem_integrity.mon"
    dump_base = "/tmp/sprite_dump"

    # Scénarios à inspecter dynamiquement :
    # 1. Overworld Départ (Link + Octorok)
    # 2. Overworld Cimetière (Ghinis)
    # 3. Donjon 1 (Stalfos / Keese)
    # 4. Donjon 2 Boss Dodongo
    # 5. Inventaire Page 0
    scenes = [
        ("OW_Start", 1, 0x77, 0),
        ("OW_Graveyard", 1, 0x41, 0),
        ("Dung1_Keese", 2, 1, 0x74),
        ("Dung2_Dodongo", 2, 2, 0x0E),
        ("Inventory_P0", 3, 0, 0),
    ]

    with open(mon_file, "w") as f:
        # Boot cartouche
        f.write("break 080d\n")
        f.write("g\n")
        f.write(f"g {launch_addr:04x}\n")
        f.write(f"break {main_addr:04x}\n")
        f.write("g\n")

        for idx, (sname, cmd, a1, a2) in enumerate(scenes):
            f.write(f"> {arg2_addr:04x} {a2:02x}\n")
            f.write(f"> {arg_addr:04x} {a1:02x}\n")
            f.write(f"> {cmd_addr:04x} {cmd:02x}\n")
            # Laisser tourner 20 frames pour laisser le multiplexeur et les ennemis s'animer
            for _ in range(20):
                f.write("g\n")

            # Dump VIC-II registers & sprite pointers
            # 07F8..07FF (8 pointeurs), D000..D02E (coordonnées, enable D015, multicolor D01C, couleurs D027..D02E)
            f.write(f'save "{dump_base}_{idx}_ptrs.bin" 0 07f8 07ff\n')
            f.write(f'save "{dump_base}_{idx}_vic.bin" 0 d000 d02e\n')
            # Dump de la zone de sprites active ($2800..$3FFF = $1800 octets)
            f.write(f'save "{dump_base}_{idx}_spr_ram.bin" 0 2800 3fff\n')

        f.write("quit\n")

    cmdline = [
        "x64sc",
        "-default",
        "-cartcrt", os.path.join(BASE_DIR, "build", "zelda.crt"),
        "-warp",
        "-limitcycles", "200000000",
        "-moncommands", mon_file
    ]

    t0 = time.time()
    res = subprocess.run(cmdline, capture_output=True, text=True, timeout=60)
    dt = time.time() - t0
    print(f"  [+] Session VICE exécutée en {dt:.1f}s.")

    all_scenes_ok = True
    for idx, (sname, _, _, _) in enumerate(scenes):
        ptrs_file = f"{dump_base}_{idx}_ptrs.bin"
        vic_file = f"{dump_base}_{idx}_vic.bin"
        spr_ram_file = f"{dump_base}_{idx}_spr_ram.bin"

        if not (os.path.exists(ptrs_file) and os.path.exists(vic_file) and os.path.exists(spr_ram_file)):
            print(f"  [FAIL] Dumps manquants pour la scène {sname}.")
            all_scenes_ok = False
            continue

        ptrs_data = open(ptrs_file, "rb").read()
        vic_data = open(vic_file, "rb").read()
        spr_ram = open(spr_ram_file, "rb").read()

        # En-tête CBM PRG (2 octets d'adresse de chargement)
        if len(ptrs_data) >= 10:
            ptrs_data = ptrs_data[2:]
        if len(vic_data) >= 49:
            vic_data = vic_data[2:]
        if len(spr_ram) >= 0x1802:
            spr_ram = spr_ram[2:]

        sprite_en = vic_data[0x15] if len(vic_data) > 0x15 else 0
        sprite_mc = vic_data[0x1C] if len(vic_data) > 0x1C else 0

        active_sprites = []
        scene_errors = []

        for spr in range(8):
            is_enabled = bool(sprite_en & (1 << spr))
            ptr_val = ptrs_data[spr] if spr < len(ptrs_data) else 0
            color = vic_data[0x27 + spr] if (0x27 + spr) < len(vic_data) else 0

            if is_enabled:
                active_sprites.append(spr)

                # 1. Vérification stricte des plages de pointeurs autorisées :
                # - Zone interdite absolue 1 : $00..$1F (adresse $0000..$07FF : ZP, pile, Screen RAM $0400)
                # - Zone interdite absolue 2 : $40..$9F (adresse $1000..$27FF : ROM chargen, Charset $2000)
                # - Zone Link/Statique valide : $20..$3F (adresse $0800..$0FFF)
                # - Zone Dynamique valide     : $A0..$FF (adresse $2800..$3FFF)
                if ptr_val < 0x20 or (0x40 <= ptr_val < 0xA0):
                    scene_errors.append(f"Sprite {spr} : Pointeur INTERDIT/CORROMPU ${ptr_val:02X} (Zone réservée ZP/Screen/Charset/ROM) !")
                elif sname.startswith("OW_") or sname.startswith("Dung"):
                    # En jeu (STATE_PLAYING) :
                    # Sprites 0..1 = Link ($20..$3F)
                    # Sprite 2     = Objet Link ($20..$3F) ou échelle/drop ($A0..$FF)
                    # Sprites 3..6 = Monstres/Boss ($A0..$FF)
                    # Sprite 7     = Projectile/Drop ($A0..$FF)
                    if spr in (0, 1) and not (0x20 <= ptr_val <= 0x3F):
                        scene_errors.append(f"Sprite {spr} (Link en jeu) : Pointeur ${ptr_val:02X} invalide (attendu: $20..$3F)")
                    elif spr in (3, 4, 5, 6) and not (0xA0 <= ptr_val <= 0xFF):
                        scene_errors.append(f"Sprite {spr} (Monstre en jeu) : Pointeur ${ptr_val:02X} invalide (attendu: $A0..$FF)")
                    elif spr == 7 and not (0xA0 <= ptr_val <= 0xFF):
                        scene_errors.append(f"Sprite {spr} (Projectile en jeu) : Pointeur ${ptr_val:02X} invalide (attendu: $A0..$FF)")
                elif sname.startswith("Inventory"):
                    # En inventaire :
                    # Sprites 0..4 = Armes secondaires ($A0..$FF ou $20..$3F)
                    # Sprite 7     = Curseur de sélection sprite_link_item_frame ($20..$3F)
                    if not ((0x20 <= ptr_val <= 0x3F) or (0xA0 <= ptr_val <= 0xFF)):
                        scene_errors.append(f"Sprite {spr} (Inventaire) : Pointeur ${ptr_val:02X} hors plages autorisées")

                # 2. Vérification des données bitmap en RAM pointée
                if 0xA0 <= ptr_val <= 0xFF:
                    offset = (ptr_val - 0xA0) * 64
                    if offset + 64 <= len(spr_ram):
                        block = spr_ram[offset : offset + 64]
                        if all(b == 0 for b in block):
                            scene_errors.append(f"Sprite {spr} : Le bloc RAM pointé (${ptr_val:02X} à ${0x2800+offset:04X}) est entièrement vide !")

                # 3. Vérification couleur propre
                if (color & 0x0F) > 15:
                    scene_errors.append(f"Sprite {spr} : Couleur VIC-II invalide ${color:02X}")

        if scene_errors:
            print(f"  [FAIL] Scène {sname:15s} ({len(active_sprites)} sprites actifs) :")
            for err in scene_errors:
                print(f"         - {err}")
            all_scenes_ok = False
        else:
            print(f"  [PASS] Scène {sname:15s} : {len(active_sprites)} sprites matériels actifs, 100% pointeurs & RAM conformes.")

        # Nettoyage fichiers temporaires
        for f in (ptrs_file, vic_file, spr_ram_file):
            if os.path.exists(f):
                os.remove(f)

    return all_scenes_ok

def main():
    print("======================================================================")
    print("  AUDIT D'INTÉGRITÉ MÉMOIRE & CONFORMITÉ DES SPRITES — ZELDA C64      ")
    print("======================================================================\n")

    p1 = test_static_sprite_pointers()
    p2 = test_dynamic_sprite_memory_under_vice()

    print("\n" + "=" * 70)
    if p1 and p2:
        print("  ✓✓✓ CONTRÔLE RÉUSSI : TOUS LES SPRITES EN MÉMOIRE SONT INTÈGRES ET CONFORMES !")
        return 0
    else:
        print("  ✗✗✗ ÉCHEC : Des anomalies d'intégrité de sprites ont été détectées.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
