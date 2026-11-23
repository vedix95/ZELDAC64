#!/usr/bin/env python3
"""
Test live VICE (-moncommands sur cartouche build/zelda.crt) pour Piste C :
1. Rideau d'entrée de donjon (key_2_pressed -> enter_dungeon -> ovl_enter_dungeon + ovl_curtain_close)
2. Pols Voice (TYPE_POLS_VOICE = 29) éliminé par la Flûte (hud_selected_b=4 + btn_b_pressed=1)
3. Horloge (clock_freeze_active=1 gèle les ennemis 25 frames)
4. Pose « objet brandi » sur drop majeur en donjon (DROP_HEART_CONTAINER -> dungeon_pickup_timer)
5. Rideau de sortie de donjon (key_1_pressed -> exit_dungeon -> ovl_exit_dungeon + ovl_curtain_close)
"""

import os
import sys
import subprocess

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART_DIR = "/home/vedix/.gemini/antigravity-cli/brain/025c3075-0ed4-40fc-8d42-f4f0093bfcd7/piste_c_qa"
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

    mon_file = os.path.join(ART_DIR, "piste_c.mon")
    d_enter = os.path.join(ART_DIR, "d_enter.bin")
    d_pols = os.path.join(ART_DIR, "d_pols.bin")
    d_clock = os.path.join(ART_DIR, "d_clock.bin")
    d_pick1 = os.path.join(ART_DIR, "d_pick1.bin")
    d_pick2 = os.path.join(ART_DIR, "d_pick2.bin")
    d_exit = os.path.join(ART_DIR, "d_exit.bin")
    ss_pick = os.path.join(ART_DIR, "01_dungeon_pickup_pose.png")
    ss_exit = os.path.join(ART_DIR, "02_after_curtain_exit.png")

    for p in [d_enter, d_pols, d_clock, d_pick1, d_pick2, d_exit, ss_pick, ss_exit]:
        if os.path.exists(p):
            os.remove(p)

    main_loop = lbl_z["main_loop"] + 6
    launch_game = lbl_i["launch_zelda_game"]
    intro_loop = lbl_i["intro_main_loop"]

    with open(mon_file, "w", encoding="utf-8") as f:
        # 1. Boot cartouche -> passer l'intro -> main_loop
        f.write("break 080d\n")
        f.write("g\n")
        f.write(f"g {launch_game:04x}\n")
        f.write(f"break {main_loop:04x}\n")
        f.write("g\n")

        # 2. Entrée Donjon 5 via key_2_pressed (déclenche enter_dungeon + ovl_curtain_close)
        f.write(f"> {lbl_z['current_dungeon_level']:04x} 05\n")
        f.write(f"> {lbl_z['key_2_pressed']:04x} 01\n")
        f.write("g\n")
        f.write("g\n")
        f.write(f's "{d_enter}" 0 {lbl_z["current_world_type"]:04x} {lbl_z["current_world_type"]:04x}\n')

        # 3. Pols Voice (slot 0) tué par la Flûte
        f.write(f"> {lbl_z['en_type']:04x} 1d\n")     # TYPE_POLS_VOICE = 29
        f.write(f"> {lbl_z['en_state']:04x} 01\n")    # EN_STATE_WALK = 1
        f.write(f"> {lbl_z['en_hp']:04x} 08\n")
        f.write(f"> {lbl_z['player_has_whistle']:04x} 01\n")
        f.write(f"> {lbl_z['hud_selected_b']:04x} 04\n")
        f.write(f"> {lbl_z['btn_a_pressed']:04x} 01\n")
        f.write("g\n")
        f.write(f's "{d_pols}" 0 {lbl_z["en_state"]:04x} {lbl_z["en_state"]:04x}\n')

        # 4. Horloge : clock_freeze_active=1 fige un ennemi actif (slot 1)
        f.write(f"> {lbl_z['clock_freeze_active']:04x} 01\n")
        f.write(f"> {lbl_z['en_type'] + 1:04x} 01\n")
        f.write(f"> {lbl_z['en_state'] + 1:04x} 01\n")
        f.write(f"> {lbl_z['en_x'] + 1:04x} a0\n")
        f.write(f"> {lbl_z['en_y'] + 1:04x} 8c\n")
        f.write(f"> {lbl_z['en_timer'] + 1:04x} 01\n")
        for _ in range(25):
            f.write("g\n")
        f.write(f's "{d_clock}" 0 {lbl_z["en_x"]:04x} {lbl_z["en_y"] + 1:04x}\n')

        # 5. Pose objet brandi sur DROP_HEART_CONTAINER en donjon
        # En D5 entrée, Link est à (176, 180) = ($b0, $b4)
        f.write(f"> {lbl_z['dungeon_drop_type']:04x} 02\n")
        f.write(f"> {lbl_z['dungeon_drop_active']:04x} 01\n")
        f.write(f"> {lbl_z['dungeon_drop_x']:04x} b0 00\n")
        f.write(f"> {lbl_z['dungeon_drop_y']:04x} b4\n")
        f.write(f"> {lbl_z['dungeon_drop_cooldown']:04x} 00\n")
        for _ in range(4):
            f.write("g\n")
        f.write(f's "{d_pick1}" 0 {lbl_z["dungeon_pickup_timer"]:04x} {lbl_z["dungeon_pickup_timer"]:04x}\n')
        f.write(f'screenshot "{ss_pick}" 2\n')
        for _ in range(65):
            f.write("g\n")
        f.write(f's "{d_pick2}" 0 {lbl_z["dungeon_pickup_timer"]:04x} {lbl_z["dungeon_pickup_timer"]:04x}\n')

        # 6. Sortie Donjon via key_1_pressed (exit_dungeon + ovl_curtain_close)
        f.write(f"> {lbl_z['key_1_pressed']:04x} 01\n")
        f.write("g\n")
        f.write("g\n")
        f.write(f's "{d_exit}" 0 {lbl_z["current_world_type"]:04x} {lbl_z["current_world_type"]:04x}\n')
        f.write(f'screenshot "{ss_exit}" 2\n')
        f.write("quit\n")

    cmd = [
        "x64sc",
        "-default",
        "+saveres",
        "-cartcrt", crt_path,
        "-moncommands", mon_file,
        "-warp",
    ]
    print("[*] Exécution VICE (-moncommands) pour Piste C...")
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=45)
    if res.returncode != 0:
        print("VICE stderr:", res.stderr.decode("latin-1", errors="replace"))

    for p in [ss_pick, ss_exit]:
        pcx = p + ".pcx"
        if os.path.exists(pcx):
            subprocess.run(["magick", pcx, p], check=True)
            os.remove(pcx)

    w_enter = read_dump(d_enter)[0]
    assert w_enter == 1, f"Entrée Donjon 5 KO: world={w_enter}"
    print("[PASS] 1. Rideau + Entrée Donjon 5 OK (world=1)")

    pols_st = read_dump(d_pols)[0]
    assert pols_st == 3, f"Pols Voice non tué par Flûte: en_state[0]={pols_st}"
    print("[PASS] 2. Pols Voice tué par la Flûte (EN_STATE_DYING=3)")

    clk_dump = read_dump(d_clock)
    en_x_off = 1
    en_y_off = (lbl_z["en_y"] - lbl_z["en_x"]) + 1
    ex, ey = clk_dump[en_x_off], clk_dump[en_y_off]
    assert ex == 160 and ey == 140, f"Ennemi a bougé malgré Horloge: ({ex}, {ey})"
    print("[PASS] 3. Horloge : ennemi figé 25 frames à (160, 140)")

    t1 = read_dump(d_pick1)[0]
    t2 = read_dump(d_pick2)[0]
    assert t1 > 0 and t2 == 0, f"dungeon_pickup_timer KO: t1={t1}, t2={t2}"
    print(f"[PASS] 4. Pose objet brandi en donjon OK (timer={t1} -> {t2})")

    w_exit = read_dump(d_exit)[0]
    assert w_exit == 0, f"Sortie Donjon KO: world={w_exit}"
    print("[PASS] 5. Rideau + Sortie Donjon OK (world=0)")

    print("\n=== TOUS LES TESTS PISTE C SONT PASSÉS (5/5) ===")
    return 0


if __name__ == "__main__":
    sys.exit(main())
