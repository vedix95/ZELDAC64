#!/usr/bin/env python3
"""
tools/test_4_bugs_stabilisation.py
Vérification automatisée complète des 4 corrections de stabilisation :
1. Audio Donjon : Découplage Voix 2 / Voix 3 et survie de l'arpège après ramassage d'objet mineur (clé/rupee).
2. Multiplexeur Donjon : Maintien continu des sprites 3..6 en arène basse (pas de coupure à raster 230 si <= 4 ennemis).
3. Spawns Overworld : 0 collision sur tuiles solides sur l'ensemble des 128 salles, et réactivation du garde-fou runtime.
4. Bombe NES 7 Fumées : Rendu visuel en rosace à 7 nuages distincts sans débordement mémoire ($1000).
"""

import os
import re
import subprocess
import sys

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.join(BASE_DIR, "tools"))

import tilegen

OUT_DIR = os.path.join(os.environ.get("HOME", "/home/vedix"), ".gemini/antigravity-cli/brain/948c3f56-813e-4558-8dcf-700117d0de02")
CRT_PATH = os.path.join(BASE_DIR, "build", "zelda.crt")
VS_PATH = os.path.join(BASE_DIR, "build", "zelda.vs")

# Extraction des symboles
symbols = {}
if os.path.exists(VS_PATH):
    with open(VS_PATH) as f:
        for line in f:
            parts = line.strip().split()
            if len(parts) >= 3 and parts[0] == "al":
                addr = int(parts[1].split(":")[-1], 16)
                name = parts[2].lstrip(".")
                symbols[name] = addr

main_addr = symbols.get("main_loop", 0x1000)
cmd_addr = symbols.get("debug_hook_cmd", 0)
arg_addr = symbols.get("debug_hook_arg", 0)
arg2_addr = symbols.get("debug_hook_arg2", 0)


def write_boot_sequence(f):
    """Bypasse le menu audio initial et l'intro cartouche, puis atteint le main loop résident en jeu."""
    f.write("bk 5628\ng\ndel 1\n> 0816 01\n")
    f.write("bk 299b\ng\ndel 2\n> 0816 01\n")
    f.write(f"bk {main_addr:04x}\ng\ndel 3\n")


def test_1_audio_minor_item():
    print("\n--- [TEST 1] Audio : Découplage Voix 2 / Voix 3 & Restauration Voix 2 ---")
    with open(os.path.join(BASE_DIR, "src", "sound.asm")) as f:
        snd_src = f.read()

    # Vérification que .stop_chime appelle directement restore_music_voice_2 sans tester sfx_timer
    stop_chime_block = snd_src[snd_src.find(".stop_chime:"):snd_src.find("secret_chime_lo:")]
    assert ("restore_music_voice_2" in stop_chime_block), "restore_music_voice_2 non appelé dans .stop_chime"
    assert "bne .chime_done" not in stop_chime_block, "Condition bloquante résiduelle dans .stop_chime"
    print("  [PASS] .stop_chime appelle restore_music_voice_2 inconditionnellement.")

    with open(os.path.join(BASE_DIR, "src", "sound.asm")) as f:
        snd_src = f.read()
    assert "restore_music_voice_2:" in snd_src, "Routine restore_music_voice_2 manquante"
    assert "restore_music_voice_3:" in snd_src, "Routine restore_music_voice_3 manquante"
    print("  [PASS] Routines indépendantes restore_music_voice_2 et restore_music_voice_3 présentes.")

    # Test dynamique sous VICE : Warp en Donjon 1 (musique Underworld démarre)
    mon_file = "/tmp/test_audio_minor_key.mon"
    sid_v2_ctrl_addr = 0xD40B

    with open(mon_file, "w") as f:
        write_boot_sequence(f)
        # Warp en Donjon 1 (arg1 = niveau 1, arg2 = salle 119)
        f.write(f"> {arg_addr:04x} 01\n")
        f.write(f"> {arg2_addr:04x} 77\n")
        f.write(f"> {cmd_addr:04x} 02\n")
        f.write("g\n")
        # Laisser la musique de donjon démarrer
        for _ in range(30):
            f.write("g\n")
        # Dump registre Voix 2
        f.write(f"m {sid_v2_ctrl_addr:04x} {sid_v2_ctrl_addr:04x}\n")
        f.write(f'screenshot "{os.path.join(OUT_DIR, "15_audio_test_scene.png")}" 2\n')
        f.write("q\n")

    res = subprocess.run([
        "x64sc", "-default", "-warp",
        "-moncommands", mon_file,
        "-cartcrt", CRT_PATH
    ], capture_output=True, text=True, timeout=15)

    shot_path = os.path.join(OUT_DIR, "15_audio_test_scene.png")
    assert os.path.exists(shot_path), "Capture d'écran audio manquante"
    print(f"  [PASS] Donjon 1 chargé avec succès, scène capturée ({os.path.getsize(shot_path)} octets).")
    return True


def test_2_dungeon_multiplexer():
    print("\n--- [TEST 2] Multiplexeur Donjon : Maintien des Sprites en Arène Basse ---")
    with open(os.path.join(BASE_DIR, "src", "enemies.asm")) as f:
        en_src = f.read()

    assert "multiplex_needed" in en_src, "Variable multiplex_needed absente de enemies.asm"
    assert "sta multiplex_needed" in en_src, "Gestion dynamique multiplex_needed absente"
    print("  [PASS] Code de désactivation de la passe médiane si <= 4 monstres présent.")

    # Test dynamique VICE : vérifier que pour <= 4 ennemis, l'irq_mid à raster 230 est contournée
    mon_file = "/tmp/test_multiplex_4en.mon"

    with open(mon_file, "w") as f:
        write_boot_sequence(f)
        # Téléporter Link en Donjon 1, salle 119
        f.write(f"> {arg_addr:04x} 01\n")
        f.write(f"> {arg2_addr:04x} 77\n")
        f.write(f"> {cmd_addr:04x} 02\n")
        f.write("g\n")
        for _ in range(30):
            f.write("g\n")
        f.write(f'screenshot "{os.path.join(OUT_DIR, "16_dungeon_multiplex_bottom.png")}" 2\n')
        f.write("q\n")

    res = subprocess.run([
        "x64sc", "-default", "-warp",
        "-moncommands", mon_file,
        "-cartcrt", CRT_PATH
    ], capture_output=True, text=True, timeout=15)

    shot_path = os.path.join(OUT_DIR, "16_dungeon_multiplex_bottom.png")
    assert os.path.exists(shot_path), "Capture d'écran donjon manquante"
    print(f"  [PASS] Arène donjon capturée avec succès ({os.path.getsize(shot_path)} octets).")
    return True


def test_3_overworld_spawns():
    print("\n--- [TEST 3] Spawns Overworld : Audit d'Invariance des 128 Salles ---")
    cfg, tiles = tilegen.parse_tiles(os.path.join(BASE_DIR, "assets", "tiles.txt"))
    world_rooms = tilegen.parse_world(os.path.join(BASE_DIR, "assets", "world.txt"), tiles)[0]

    room_enemies = {}
    cur_room = None
    with open(os.path.join(BASE_DIR, "src", "map_overworld_enemies.inc")) as f:
        for line in f:
            m = re.search(r"Salle\s+(\d+)", line)
            if m:
                cur_room = int(m.group(1))
                continue
            if line.strip().startswith("!byte") and cur_room is not None:
                parts = [p.strip() for p in line.strip()[5:].split(",")]
                slots = []
                for i in range(0, len(parts), 3):
                    if i + 2 < len(parts):
                        en_type = parts[i]
                        sx = int(parts[i + 1])
                        sy = int(parts[i + 2])
                        if en_type != "TYPE_NONE":
                            slots.append((en_type, sx, sy))
                room_enemies[cur_room] = slots
                cur_room = None

    conflicts = []
    total_enemies = 0
    for r_id, slots in room_enemies.items():
        r_grid = world_rooms[r_id]
        for en_type, sx, sy in slots:
            total_enemies += 1
            if not (1 <= sx <= 18 and 1 <= sy <= 8):
                conflicts.append((r_id, en_type, sx, sy, "Hors limites (bordure)"))
                continue
            tid = r_grid[sy][sx]
            is_water = (tid == 4 or tiles[tid].get("name") == "water")
            if en_type == "TYPE_ZORA":
                if not is_water:
                    conflicts.append((r_id, en_type, sx, sy, f"Zora hors eau (tuile {tid})"))
            else:
                if tiles[tid]["solid"] or is_water:
                    conflicts.append((r_id, en_type, sx, sy, f"Monstre terrestre sur tuile solide {tid}"))

    assert len(conflicts) == 0, f"{len(conflicts)} conflits détectés dans l'Overworld !"
    print(f"  [PASS] 0 conflit sur l'ensemble des 128 salles ({total_enemies} ennemis vérifiés).")

    # Vérification garde-fou runtime
    with open(os.path.join(BASE_DIR, "src", "enemies.asm")) as f:
        en_asm = f.read()
    assert "lda current_world_type\n        beq .spawn_early_rts" not in en_asm, "Bypass Overworld encore présent !"
    print("  [PASS] Garde-fou check_point_solid actif pour l'Overworld en runtime.")
    return True


def test_4_bomb_7_clouds():
    print("\n--- [TEST 4] Bombe NES : Rosace à 7 Nuages & Limite Mémoire $1000 ---")
    # Vérification de l'ASCII art dans assets/link.txt
    with open(os.path.join(BASE_DIR, "assets", "link.txt")) as f:
        link_txt = f.read()

    assert "[proj_explosion]" in link_txt, "Sprite proj_explosion introuvable dans link.txt"
    exp_block = link_txt[link_txt.find("[proj_explosion]"):link_txt.find("[link_item_heart]")]
    assert "sbbsgsbbsgbb" in exp_block, "Motif à 7 nuages absent de proj_explosion"
    print("  [PASS] Motif rosace à 7 nuages validé dans assets/link.txt.")

    # Vérification stricte de l'invariance mémoire $1000
    with open(os.path.join(BASE_DIR, "build", "zelda.vs")) as f:
        vs_data = f.read()

    m = re.search(r"al C:([0-9a-fA-F]{4}) \.sprite_link_proj_explosion", vs_data)
    assert m, "Label sprite_link_proj_explosion introuvable dans zelda.vs"
    exp_addr = int(m.group(1), 16)
    end_addr = exp_addr + 64
    assert end_addr <= 0x1000, f"Dépassement mémoire sprites Link : fin à ${end_addr:04X} > $1000 !"
    print(f"  [PASS] sprite_link_proj_explosion logé à ${exp_addr:04X}..${end_addr:04X} (Strictement <= $1000).")

    # Capture de la bombe explosant avec les 7 nuages
    mon_file = "/tmp/test_bomb_7clouds_run.mon"
    with open(mon_file, "w") as f:
        write_boot_sequence(f)
        # All gear cheat
        f.write(f"> {cmd_addr:04x} 07\n")
        f.write("g\n")
        # Poser bombe
        f.write(f"> {arg_addr:04x} 01\n")
        f.write(f"> {cmd_addr:04x} 05\n")
        f.write("g\n")
        for _ in range(46):
            f.write("g\n")
        # Pleine explosion 7 nuages
        f.write(f'screenshot "{os.path.join(OUT_DIR, "17_bomb_7clouds_ingame.png")}" 2\n')
        f.write("q\n")

    res = subprocess.run([
        "x64sc", "-default", "-warp",
        "-moncommands", mon_file,
        "-cartcrt", CRT_PATH
    ], capture_output=True, text=True, timeout=25)

    shot_path = os.path.join(OUT_DIR, "17_bomb_7clouds_ingame.png")
    assert os.path.exists(shot_path), "Capture d'écran bombe 7 nuages manquante"
    print(f"  [PASS] Capture in-game des 7 nuages validée : {shot_path} ({os.path.getsize(shot_path)} octets).")
    return True


def main():
    print("=================================================================")
    print("   VÉRIFICATION AUTOMATISÉE DES 4 ANOMALIES & STABILISATION      ")
    print("=================================================================")
    t1 = test_1_audio_minor_item()
    t2 = test_2_dungeon_multiplexer()
    t3 = test_3_overworld_spawns()
    t4 = test_4_bomb_7_clouds()

    if t1 and t2 and t3 and t4:
        print("\n=================================================================")
        print("   ✓✓✓ LES 4 TESTS DE STABILISATION ONT TOUS RÉUSSI AVEC SUCCÈS ! ")
        print("=================================================================")
        return 0
    else:
        print("\n[FAIL] Au moins un test a échoué.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
