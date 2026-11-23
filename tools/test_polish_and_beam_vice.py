#!/usr/bin/env python3
"""
Test live VICE (-moncommands sur cartouche build/zelda.crt) :
1. Sword Beam (ITEM_SWORD_BEAM) :
   - Tir gauche près du bord gauche (X=40) -> despawn propre à PLAYER_X_MIN (pas de wrap)
   - Tir droit depuis X=40 -> dépasse 50 frames (X>240) et despawn propre à PLAYER_X_MAX
2. HUD [A] dynamique :
   - Objet sélectionné non possédé (Boomerang=0) -> masqué (espace 32 en $043E)
   - Full gear (debug_hook_cmd=2) -> player_has_letter=1, Boomerang magique (char 101, col 14)
3. Game Over :
   - Lignes 0..3 ($0400..$049F) entièrement propres (espaces 32)
   - Rafraîchit docs/images/shot_gameover.png
"""

import os
import sys
import subprocess

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART_DIR = "/home/vedix/.gemini/antigravity-cli/brain/025c3075-0ed4-40fc-8d42-f4f0093bfcd7/polish_beam_qa"
os.makedirs(ART_DIR, exist_ok=True)


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


def read_dump(path):
    with open(path, "rb") as f:
        return f.read()[2:]


def main():
    crt_path = os.path.join(BASE_DIR, "build", "zelda.crt")
    lbl_z = load_labels(os.path.join(BASE_DIR, "build", "zelda.vs"))
    lbl_i = load_labels(os.path.join(BASE_DIR, "build", "intro.vs"))

    mon_file = os.path.join(ART_DIR, "polish_beam.mon")
    dumps = {k: os.path.join(ART_DIR, f"d_{k}.bin") for k in [
        "hud_masked", "beam_left", "beam_right_mid", "beam_right_end",
        "full_gear", "go_top"
    ]}
    for p in dumps.values():
        if os.path.exists(p):
            os.remove(p)

    shot_go = os.path.join(BASE_DIR, "docs", "images", "shot_gameover.png")
    shot_pcx = shot_go + ".pcx"
    for p in (shot_go, shot_pcx):
        if os.path.exists(p):
            os.remove(p)

    main_loop = lbl_z["main_loop"] + 6
    launch_game = lbl_i["launch_zelda_game"]
    open_go = lbl_z["open_gameover"]

    player_x = lbl_z["player_x"]
    player_y = lbl_z["player_y"]
    player_dir = lbl_z["player_dir"]
    player_has_sword = lbl_z["player_has_sword"]
    player_has_letter = lbl_z["player_has_letter"]
    hud_max_hearts = lbl_z["hud_max_hearts"]
    hud_cur_hearts = lbl_z["hud_cur_hearts"]
    btn_x_pressed = lbl_z["btn_x_pressed"]
    btn_b_pressed = lbl_z["btn_b_pressed"]
    hud_selected_b = lbl_z["hud_selected_b"]
    hud_bombs = lbl_z["hud_bombs"]
    player_has_blue_ring = lbl_z["player_has_blue_ring"]
    player_hurt_timer = lbl_z["player_hurt_timer"]
    en_state = lbl_z["en_state"]
    en_type = lbl_z["en_type"]
    en_x = lbl_z["en_x"]
    en_y = lbl_z["en_y"]
    item_active = lbl_z["item_active"]
    debug_hook_cmd = lbl_z["debug_hook_cmd"]

    mon_lines = [
        "break 080d",
        "g",
        f"g {launch_game:04x}",
        f"break {main_loop:04x}",
        "g",
        # Frame 1..25 : hud_selected_b=1 (Bombe) avec hud_bombs=0 -> ouvre+ferme inventaire -> [A] masqué
        f"> {hud_bombs:04x} 00",
        f"> {btn_b_pressed:04x} 01",
        "ignore 2 25",
        "g",
        f"> {btn_b_pressed:04x} 01",
        "ignore 2 25",
        "g",
        f's "{dumps["hud_masked"]}" 0 043e 043e',
        f"> {hud_bombs:04x} 04",

        # Test 1a : Sword Beam vers la gauche depuis X=40 -> doit despawn à PLAYER_X_MIN (24)
        f"> {player_x:04x} 28 00",
        f"> {player_y:04x} 8c",
        f"> {player_dir:04x} 02",
        f"> {player_has_sword:04x} 01",
        f"> {hud_max_hearts:04x} 03",
        f"> {hud_cur_hearts:04x} 0c",
        f"> {item_active:04x} 00",
        f"> {btn_x_pressed:04x} 01",
        "ignore 2 15",
        "g",
        f's "{dumps["beam_left"]}" 0 {item_active:04x} {item_active:04x}',

        # Test 1b : Sword Beam vers la droite depuis X=40 -> actif à 0x35 (53) frames, despawn après +0x20 frames
        f"> {player_x:04x} 28 00",
        f"> {player_y:04x} 8c",
        f"> {player_dir:04x} 03",
        f"> {item_active:04x} 00",
        f"> {btn_x_pressed:04x} 01",
        "ignore 2 35",
        "g",
        f's "{dumps["beam_right_mid"]}" 0 {item_active:04x} {item_active:04x}',
        "ignore 2 20",
        "g",
        f's "{dumps["beam_right_end"]}" 0 {item_active:04x} {item_active:04x}',

        # Test 2 : Full gear (debug_hook_cmd=7) -> player_has_letter=1, HUD [A] Boomerang Magique
        f"> {hud_selected_b:04x} 00",
        f"> {debug_hook_cmd:04x} 07",
        "ignore 2 2",
        "g",
        f's "{dumps["full_gear"]}.let" 0 {player_has_letter:04x} {player_has_letter:04x}',
        f's "{dumps["full_gear"]}.chr" 0 043e 043e',
        f's "{dumps["full_gear"]}.col" 0 d83e d83e',

        # Test 3 : Game Over naturel par contact ennemi -> lignes 0..3 propres + capture docs/images/shot_gameover.png
        f"> {player_has_blue_ring:04x} 00",
        f"> {hud_cur_hearts:04x} 01",
        f"> {player_hurt_timer:04x} 00",
        f"> {en_state:04x} 01",
        f"> {en_type:04x} 01",
        f"> {en_x:04x} a0 00",
        f"> {en_y:04x} 8c",
        f"> {player_x:04x} a0 00",
        f"> {player_y:04x} 8c",
        "ignore 2 20",
        "g",
        f's "{dumps["go_top"]}" 0 0400 049f',
        f'screenshot "{shot_go}" 2',
        "quit",
    ]

    with open(mon_file, "w", encoding="utf-8") as f:
        f.write("\n".join(mon_lines) + "\n")

    cmd = [
        "x64sc", "-console", "-warp", "-silent", "+sound", "+saveres",
        "-cartcrt", crt_path,
        "-moncommands", mon_file,
    ]
    proc = subprocess.run(cmd, cwd=BASE_DIR, capture_output=True, text=True, timeout=60)
    if proc.returncode != 0:
        print("VICE stderr:", proc.stderr)
        sys.exit(1)

    if os.path.exists(shot_pcx):
        subprocess.run(["magick", shot_pcx, shot_go], check=True)
        os.remove(shot_pcx)

    hud_masked = read_dump(dumps["hud_masked"])[0]
    beam_left = read_dump(dumps["beam_left"])[0]
    beam_right_mid = read_dump(dumps["beam_right_mid"])[0]
    beam_right_end = read_dump(dumps["beam_right_end"])[0]
    fg_let = read_dump(dumps["full_gear"] + ".let")[0]
    fg_chr = read_dump(dumps["full_gear"] + ".chr")[0]
    fg_col = read_dump(dumps["full_gear"] + ".col")[0] & 0x0F
    go_top = read_dump(dumps["go_top"])
    go_bad = [i for i, b in enumerate(go_top) if b != 32]

    print(f"hud_masked=$043E={hud_masked} (attendu 32)")
    print(f"beam_left item_active={beam_left} (attendu 0)")
    print(f"beam_right_mid item_active={beam_right_mid} (attendu 6)")
    print(f"beam_right_end item_active={beam_right_end} (attendu 0)")
    print(f"full_gear letter={fg_let} (attendu 1), [A] chr={fg_chr} (attendu 101), col={fg_col} (attendu 14)")
    print(f"go_top non-space count={len(go_bad)} (attendu 0)")

    assert hud_masked == 32, f"HUD [A] non masqué: {hud_masked}"
    assert beam_left == 0, f"Sword beam gauche n'a pas despawn: {beam_left}"
    assert beam_right_mid == 6, f"Sword beam droit coupé trop tôt: {beam_right_mid}"
    assert beam_right_end == 0, f"Sword beam droit n'a pas despawn: {beam_right_end}"
    assert fg_let == 1, f"player_has_letter != 1: {fg_let}"
    assert fg_chr == 101 and fg_col == 14, f"HUD [A] Boomerang Magique invalide: chr={fg_chr} col={fg_col}"
    assert len(go_bad) == 0, f"Lignes 0..3 Game Over sales aux offsets {go_bad[:10]}"
    assert os.path.exists(shot_go), "shot_gameover.png non généré"

    print("PASS: test_polish_and_beam_vice")


if __name__ == "__main__":
    main()
