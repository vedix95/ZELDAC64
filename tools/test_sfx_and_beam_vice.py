#!/usr/bin/env python3
"""
Test live VICE (-moncommands sur cartouche build/zelda.crt) :
1. SFX_LINK_HURT (13) : déclenché par hurt_link_dmg, CTRL=$21, descente de fréquence sfx_curr_freq_hi
2. Alerte vie basse (SFX_LOW_HP = 19) quand hud_cur_hearts <= 4
3. Pose de bombe (SFX_INV_FLIP = 16)
4. Jeté de l'épée à vie pleine (ITEM_SWORD_BEAM = 6, SFX_SWORD_BEAM = 21) vs vie partielle
   + impact et dégâts (2 avec Épée Blanche) sur un Octorok Rouge
"""

import os
import sys
import subprocess

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART_DIR = "/home/vedix/.gemini/antigravity-cli/brain/025c3075-0ed4-40fc-8d42-f4f0093bfcd7/sfx_beam_qa"
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

    mon_file = os.path.join(ART_DIR, "sfx_beam.mon")
    dumps = {k: os.path.join(ART_DIR, f"d_{k}.bin") for k in [
        "hurt1", "hurt2", "lowhp", "bomb", "nobeam", "beam", "beam_hit"
    ]}
    for p in dumps.values():
        if os.path.exists(p):
            os.remove(p)

    main_loop = lbl_z["main_loop"] + 6
    launch_game = lbl_i["launch_zelda_game"]

    px = lbl_z["player_x"]
    py = lbl_z["player_y"]
    pdir = lbl_z["player_dir"]
    pinv = lbl_z["player_hurt_timer"]
    psword = lbl_z["player_has_sword"]
    patt = lbl_z["player_attacking"]
    hcur = lbl_z["hud_cur_hearts"]
    hmax = lbl_z["hud_max_hearts"]
    hbomb = lbl_z["hud_bombs"]
    hselb = lbl_z["hud_selected_b"]
    btna = lbl_z["btn_a_pressed"]
    btnx = lbl_z["btn_x_pressed"]

    iact = lbl_z["item_active"]
    sfx_id = lbl_z["sfx_active_id"]
    sfx_tmr = lbl_z["sfx_timer"]
    sfx_fhi = lbl_z["sfx_curr_freq_hi"]
    low_tmr = lbl_z["low_hp_beep_timer"]

    etype = lbl_z["en_type"]
    estate = lbl_z["en_state"]
    ex = lbl_z["en_x"]
    ey = lbl_z["en_y"]
    ehp = lbl_z["en_hp"]

    with open(mon_file, "w", encoding="utf-8") as f:
        f.write("break 080d\n")
        f.write("g\n")
        f.write(f"g {launch_game:04x}\n")
        f.write(f"break {main_loop:04x}\n")
        f.write("g\n")

        # 1. Test SFX_LINK_HURT (13) + sweep descendant
        f.write(f"> {hmax:04x} 0c\n")
        f.write(f"> {hcur:04x} 30\n")
        f.write(f"> {px:04x} a0 00\n")
        f.write(f"> {py:04x} 8c\n")
        f.write(f"> {pinv:04x} 00\n")
        f.write(f"> {etype:04x} 01\n")          # TYPE_OCTOROK_RED
        f.write(f"> {estate:04x} 01\n")         # EN_STATE_WALK
        f.write(f"> {ehp:04x} 04\n")
        f.write(f"> {ex:04x} a0 00\n")
        f.write(f"> {ey:04x} 8c\n")
        f.write("g\n")
        f.write(f's "{dumps["hurt1"]}" 0 {sfx_id:04x} {sfx_id:04x}\n')
        f.write(f's "{dumps["hurt1"]}.tmr" 0 {sfx_tmr:04x} {sfx_tmr:04x}\n')
        f.write(f's "{dumps["hurt1"]}.fhi" 0 {sfx_fhi:04x} {sfx_fhi:04x}\n')
        f.write(f"> {estate:04x} 00\n")         # retire ennemi
        f.write("g\n")
        f.write("g\n")
        f.write(f's "{dumps["hurt2"]}.fhi" 0 {sfx_fhi:04x} {sfx_fhi:04x}\n')

        # 2. Test Alerte Vie Basse (SFX_LOW_HP = 19)
        f.write(f"> {sfx_tmr:04x} 00\n")
        f.write(f"> {hcur:04x} 03\n")           # 3 quarts (< 1 cœur)
        f.write(f"> {low_tmr:04x} 01\n")
        f.write("g\n")
        f.write(f's "{dumps["lowhp"]}" 0 {sfx_id:04x} {sfx_id:04x}\n')

        # 3. Test Pose de Bombe (SFX_INV_FLIP = 16)
        f.write(f"> {hcur:04x} 20\n")           # 8 cœurs (pas de bip vie basse)
        f.write(f"> {sfx_tmr:04x} 00\n")
        f.write(f"> {iact:04x} 00\n")
        f.write(f"> {hbomb:04x} 04\n")
        f.write(f"> {hselb:04x} 01\n")          # Bombe
        f.write(f"> {btna:04x} 01\n")
        f.write("g\n")
        f.write(f's "{dumps["bomb"]}" 0 {sfx_id:04x} {sfx_id:04x}\n')
        f.write(f's "{dumps["bomb"]}.act" 0 {iact:04x} {iact:04x}\n')

        # 4a. Test Épée à vie partielle -> PAS de jeté (item_active=0, sfx_id=0)
        f.write(f"> {iact:04x} 00\n")
        f.write(f"> {patt:04x} 00\n")
        f.write(f"> {psword:04x} 02\n")         # Épée Blanche (2 dmg)
        f.write(f"> {pdir:04x} 03\n")           # DIR_RIGHT
        f.write(f"> {hcur:04x} 20\n")           # vie partielle
        f.write(f"> {btnx:04x} 01\n")
        f.write("g\n")
        f.write(f's "{dumps["nobeam"]}" 0 {iact:04x} {iact:04x}\n')
        f.write(f's "{dumps["nobeam"]}.sfx" 0 {sfx_id:04x} {sfx_id:04x}\n')

        # 4b. Test Épée à vie pleine -> JETÉ D'ÉPÉE (item_active=6, sfx_id=21)
        f.write(f"> {patt:04x} 00\n")
        f.write(f"> {iact:04x} 00\n")
        f.write(f"> {hcur:04x} 30\n")           # vie pleine (12*4 = 48)
        f.write(f"> {btnx:04x} 01\n")
        f.write("g\n")
        f.write(f's "{dumps["beam"]}" 0 {iact:04x} {iact:04x}\n')
        f.write(f's "{dumps["beam"]}.sfx" 0 {sfx_id:04x} {sfx_id:04x}\n')
        f.write(f's "{dumps["beam"]}.en" 0 d015 d015\n')

        # 4c. Place un Octorok Rouge (hp=2) devant Link à (196, 140) et laisse le jeté le frapper
        f.write(f"> {etype:04x} 01\n")
        f.write(f"> {estate:04x} 01\n")
        f.write(f"> {ehp:04x} 02\n")
        f.write(f"> {ex:04x} c4 00\n")
        f.write(f"> {ey:04x} 8c\n")
        for _ in range(8):
            f.write("g\n")
        f.write(f's "{dumps["beam_hit"]}" 0 {estate:04x} {estate:04x}\n')
        f.write(f's "{dumps["beam_hit"]}.act" 0 {iact:04x} {iact:04x}\n')

        f.write("quit\n")

    cmd = [
        "x64sc", "-console", "-warp", "+saveres", "-sound",
        "-cartcrt", crt_path, "-moncommands", mon_file
    ]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=45)
    if res.returncode != 0:
        print(res.stdout)
        sys.exit(1)

    h1_id = read_dump(dumps["hurt1"])[0]
    h1_tmr = read_dump(dumps["hurt1"] + ".tmr")[0]
    h1_fhi = read_dump(dumps["hurt1"] + ".fhi")[0]
    h2_fhi = read_dump(dumps["hurt2"] + ".fhi")[0]
    assert h1_id == 13, f"SFX_LINK_HURT id fail: {h1_id} (exp 13)"
    assert h1_tmr > 0 and h2_fhi < h1_fhi, f"SFX_LINK_HURT sweep fail: tmr={h1_tmr}, fhi1={h1_fhi:#x}, fhi2={h2_fhi:#x}"

    lhp = read_dump(dumps["lowhp"])[0]
    assert lhp == 19, f"SFX_LOW_HP fail: {lhp} (exp 19)"

    b_sfx = read_dump(dumps["bomb"])[0]
    b_act = read_dump(dumps["bomb"] + ".act")[0]
    assert b_sfx == 16 and b_act == 2, f"Bomb SFX fail: sfx={b_sfx}, act={b_act}"

    nb_act = read_dump(dumps["nobeam"])[0]
    nb_sfx = read_dump(dumps["nobeam"] + ".sfx")[0]
    assert nb_act == 0 and nb_sfx == 0, f"Partial HP should not fire beam: act={nb_act}, sfx={nb_sfx}"

    bm_act = read_dump(dumps["beam"])[0]
    bm_sfx = read_dump(dumps["beam"] + ".sfx")[0]
    bm_en = read_dump(dumps["beam"] + ".en")[0]
    assert bm_act == 6 and bm_sfx == 21 and (bm_en & 0x04) != 0, (
        f"Full HP sword beam fail: act={bm_act}, sfx={bm_sfx}, spr_en={bm_en:#x}"
    )

    bh_st = read_dump(dumps["beam_hit"])[0]
    bh_act = read_dump(dumps["beam_hit"] + ".act")[0]
    assert bh_st in (0, 3) and bh_act == 0, f"Sword beam hit fail: en_state={bh_st}, item_active={bh_act}"

    print("[PASS] test_sfx_and_beam_vice: SFX_LINK_HURT sweep + Low-HP beep + Bomb SFX + Full-HP Sword Beam verified in VICE!")


if __name__ == "__main__":
    main()
