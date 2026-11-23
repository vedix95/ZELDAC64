#!/usr/bin/env python3
"""
Test live VICE (-moncommands sur cartouche build/zelda.crt) :
1. Dégâts ennemis & couleur de tunique (Vert=5, Bleu/Blanc=1, Rouge=2) :
   - Octorok rouge (en_base_damage=2) : Vert -2, Bleu -1, Rouge alterné 0 / -1
   - Moblin bleu (en_base_damage=4) : Rouge -1
2. Drops au sol (loot_drop_active, Sprite 2 à (en_x, en_y), ramassage au contact) :
   - Rubis bleu (+5), Bombe (+4), Cœur (+4 quarts), Horloge (clock_freeze_active=1)
"""

import os
import sys
import subprocess

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART_DIR = "/home/vedix/.gemini/antigravity-cli/brain/025c3075-0ed4-40fc-8d42-f4f0093bfcd7/tunic_drops_qa"
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

    mon_file = os.path.join(ART_DIR, "tunic_drops.mon")
    dumps = {k: os.path.join(ART_DIR, f"d_{k}.bin") for k in [
        "green", "blue", "red0", "red1", "moblin_red",
        "drop_spr", "drop_rupee5", "drop_bomb", "drop_heart", "drop_clock"
    ]}
    ss_drop = os.path.join(ART_DIR, "01_loot_drop_rupee.png")

    for p in list(dumps.values()) + [ss_drop]:
        if os.path.exists(p):
            os.remove(p)

    main_loop = lbl_z["main_loop"] + 6
    launch_game = lbl_i["launch_zelda_game"]

    px = lbl_z["player_x"]
    py = lbl_z["player_y"]
    pinv = lbl_z["player_hurt_timer"]
    pring = lbl_z["player_has_blue_ring"]
    prhits = lbl_z["player_blue_ring_hits"]
    hcur = lbl_z["hud_cur_hearts"]
    hmax = lbl_z["hud_max_hearts"]
    hrup = lbl_z["hud_rupees"]
    hbomb = lbl_z["hud_bombs"]
    clk = lbl_z["clock_freeze_active"]

    etype = lbl_z["en_type"]
    estate = lbl_z["en_state"]
    ex = lbl_z["en_x"]
    ey = lbl_z["en_y"]
    ehp = lbl_z["en_hp"]

    lactive = lbl_z["loot_drop_active"]
    ltype = lbl_z["loot_drop_type"]
    lx = lbl_z["loot_drop_x"]
    ly = lbl_z["loot_drop_y"]
    ltmr = lbl_z["loot_drop_timer"]

    with open(mon_file, "w", encoding="utf-8") as f:
        # 1. Boot cartouche -> passer l'intro -> main_loop
        f.write("break 080d\n")
        f.write("g\n")
        f.write(f"g {launch_game:04x}\n")
        f.write(f"break {main_loop:04x}\n")
        f.write("g\n")

        # Place Link au centre (160, 140) avec 12 cœurs (48 quarts)
        f.write(f"> {hmax:04x} 0c\n")
        f.write(f"> {hcur:04x} 30\n")
        f.write(f"> {px:04x} a0 00\n")
        f.write(f"> {py:04x} 8c\n")

        # --- TEST 1a : Tunique Verte (ring=0) vs Octorok Rouge (dmg=2) ---
        f.write(f"> {pring:04x} 00\n")
        f.write(f"> {pinv:04x} 00\n")
        f.write(f"> {etype:04x} 01\n")          # TYPE_OCTOROK_RED = 1
        f.write(f"> {estate:04x} 01\n")         # EN_STATE_WALK = 1
        f.write(f"> {ehp:04x} 04\n")
        f.write(f"> {ex:04x} a0 00\n")
        f.write(f"> {ey:04x} 8c\n")
        f.write("g\n")
        f.write(f's "{dumps["green"]}" 0 {hcur:04x} {hcur:04x}\n')
        f.write(f's "{dumps["green"]}.col" 0 d027 d027\n')

        # --- TEST 1b : Tunique Bleue (ring=1) vs Octorok Rouge (dmg=2 -> 1) ---
        f.write(f"> {hcur:04x} 30\n")
        f.write(f"> {pring:04x} 01\n")
        f.write(f"> {pinv:04x} 00\n")
        f.write(f"> {ex:04x} a0 00\n")
        f.write(f"> {ey:04x} 8c\n")
        f.write("g\n")
        f.write(f's "{dumps["blue"]}" 0 {hcur:04x} {hcur:04x}\n')
        f.write(f's "{dumps["blue"]}.col" 0 d027 d027\n')

        # --- TEST 1c : Tunique Rouge (ring=2) vs Octorok Rouge (dmg=2 -> 0 puis 1) ---
        f.write(f"> {hcur:04x} 30\n")
        f.write(f"> {pring:04x} 02\n")
        f.write(f"> {prhits:04x} 00\n")
        f.write(f"> {pinv:04x} 00\n")
        f.write(f"> {ex:04x} a0 00\n")
        f.write(f"> {ey:04x} 8c\n")
        f.write("g\n")
        f.write(f's "{dumps["red0"]}" 0 {hcur:04x} {hcur:04x}\n')
        f.write(f's "{dumps["red0"]}.col" 0 d027 d027\n')

        f.write(f"> {pinv:04x} 00\n")
        f.write(f"> {ex:04x} a0 00\n")
        f.write(f"> {ey:04x} 8c\n")
        f.write("g\n")
        f.write(f's "{dumps["red1"]}" 0 {hcur:04x} {hcur:04x}\n')

        # --- TEST 1d : Tunique Rouge (ring=2) vs Moblin Bleu (type=4, dmg=4 -> 1) ---
        f.write(f"> {hcur:04x} 30\n")
        f.write(f"> {pinv:04x} 00\n")
        f.write(f"> {etype:04x} 04\n")          # TYPE_MOBLIN_BLUE = 4
        f.write(f"> {ex:04x} a0 00\n")
        f.write(f"> {ey:04x} 8c\n")
        f.write("g\n")
        f.write(f's "{dumps["moblin_red"]}" 0 {hcur:04x} {hcur:04x}\n')

        # Retire l'ennemi pour tester les drops au sol
        f.write(f"> {estate:04x} 00\n")
        f.write(f"> {pinv:04x} 00\n")

        # --- TEST 2a : Affichage Sprite 2 d'un Rubis Bleu (LOOT_RUPEE_5=3) à (200, 140) ---
        f.write(f"> {px:04x} 80 00\n")
        f.write(f"> {py:04x} 8c\n")
        f.write(f"> {lactive:04x} 01\n")
        f.write(f"> {ltype:04x} 03\n")
        f.write(f"> {lx:04x} c8 00\n")
        f.write(f"> {ly:04x} 8c\n")
        f.write(f"> {ltmr:04x} 90 01\n")
        f.write("g\n")
        f.write("g\n")
        f.write(f's "{dumps["drop_spr"]}" 0 d004 d029\n')
        f.write(f's "{dumps["drop_spr"]}.ptr" 0 07fa 07fa\n')
        f.write(f'sc "{ss_drop}" 2\n')

        # --- TEST 2b : Ramassage Rubis Bleu (+5) ---
        f.write(f"> {hrup:04x} 0a\n")
        f.write(f"> {px:04x} c8 00\n")
        f.write(f"> {py:04x} 8c\n")
        f.write("g\n")
        f.write("g\n")
        f.write(f's "{dumps["drop_rupee5"]}" 0 {hrup:04x} {hrup:04x}\n')
        f.write(f's "{dumps["drop_rupee5"]}.act" 0 {lactive:04x} {lactive:04x}\n')

        # --- TEST 2c : Ramassage Bombe (+4) ---
        f.write(f"> {hbomb:04x} 02\n")
        f.write(f"> {lactive:04x} 01\n")
        f.write(f"> {ltype:04x} 04\n")
        f.write(f"> {lx:04x} c8 00\n")
        f.write(f"> {ly:04x} 8c\n")
        f.write(f"> {ltmr:04x} 90 01\n")
        f.write("g\n")
        f.write("g\n")
        f.write(f's "{dumps["drop_bomb"]}" 0 {hbomb:04x} {hbomb:04x}\n')

        # --- TEST 2d : Ramassage Cœur (+4 quarts) ---
        f.write(f"> {hcur:04x} 20\n")
        f.write(f"> {lactive:04x} 01\n")
        f.write(f"> {ltype:04x} 01\n")
        f.write(f"> {ltmr:04x} 90 01\n")
        f.write("g\n")
        f.write("g\n")
        f.write(f's "{dumps["drop_heart"]}" 0 {hcur:04x} {hcur:04x}\n')

        # --- TEST 2e : Ramassage Horloge (clock_freeze_active=1) ---
        f.write(f"> {clk:04x} 00\n")
        f.write(f"> {lactive:04x} 01\n")
        f.write(f"> {ltype:04x} 06\n")
        f.write(f"> {ltmr:04x} 90 01\n")
        f.write("g\n")
        f.write("g\n")
        f.write(f's "{dumps["drop_clock"]}" 0 {clk:04x} {clk:04x}\n')

        f.write("quit\n")

    cmd = [
        "x64sc", "-console", "-warp", "+saveres", "-sound",
        "-cartcrt", crt_path, "-moncommands", mon_file
    ]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=45)
    if res.returncode != 0:
        print(res.stdout)
        sys.exit(1)

    if os.path.exists(ss_drop + ".pcx"):
        subprocess.run(["magick", ss_drop + ".pcx", ss_drop], check=True)
        os.remove(ss_drop + ".pcx")

    # Assertions
    g_hp = read_dump(dumps["green"])[0]
    g_col = read_dump(dumps["green"] + ".col")[0] & 0x0f
    b_hp = read_dump(dumps["blue"])[0]
    b_col = read_dump(dumps["blue"] + ".col")[0] & 0x0f
    r0_hp = read_dump(dumps["red0"])[0]
    r0_col = read_dump(dumps["red0"] + ".col")[0] & 0x0f
    r1_hp = read_dump(dumps["red1"])[0]
    m_hp = read_dump(dumps["moblin_red"])[0]

    assert g_hp == 46 and g_col == 5, f"Green tunic fail: hp={g_hp} (exp 46), col={g_col} (exp 5)"
    assert b_hp == 47 and b_col == 1, f"Blue tunic fail: hp={b_hp} (exp 47), col={b_col} (exp 1)"
    assert r0_hp == 48 and r0_col == 2, f"Red tunic hit 1 fail: hp={r0_hp} (exp 48), col={r0_col} (exp 2)"
    assert r1_hp == 47, f"Red tunic hit 2 fail: hp={r1_hp} (exp 47)"
    assert m_hp == 47, f"Red tunic vs Blue Moblin fail: hp={m_hp} (exp 47)"

    dspr = read_dump(dumps["drop_spr"])
    spr_x2, spr_y2 = dspr[0], dspr[1]
    spr_en = dspr[0x15 - 4]
    spr_col2 = dspr[0x29 - 4] & 0x0f
    spr_ptr2 = read_dump(dumps["drop_spr"] + ".ptr")[0]
    assert (spr_en & 0x04) != 0, f"Sprite 2 not enabled: VIC_SPRITE_EN={spr_en:#x}"
    assert spr_x2 == 200 and spr_y2 == 140, f"Sprite 2 pos fail: ({spr_x2}, {spr_y2})"
    assert spr_col2 == 6 and spr_ptr2 == 0xec, f"Sprite 2 ptr/col fail: ptr={spr_ptr2:#x}, col={spr_col2}"

    rup5 = read_dump(dumps["drop_rupee5"])[0]
    act = read_dump(dumps["drop_rupee5"] + ".act")[0]
    bomb = read_dump(dumps["drop_bomb"])[0]
    heart = read_dump(dumps["drop_heart"])[0]
    clock = read_dump(dumps["drop_clock"])[0]
    assert rup5 == 15 and act == 0, f"Rupee 5 pickup fail: rup={rup5}, active={act}"
    assert bomb == 6, f"Bomb +4 pickup fail: bomb={bomb}"
    assert heart == 36, f"Heart +4 pickup fail: heart={heart}"
    assert clock == 1, f"Clock freeze pickup fail: clock={clock}"

    print("[PASS] test_tunic_and_drops_vice: Tunics (Green/Blue/Red) + Ground Drops (Rupee5/Bomb/Heart/Clock) verified in VICE!")


if __name__ == "__main__":
    main()
