#!/usr/bin/env python3
"""
Test live VICE (-moncommands sur cartouche build/zelda.crt) :
1. Ramassage DROP_HEART_CONTAINER en D1 -> hud_max_hearts 3->4, heart_dung_mask |= $01
2. Plafond strict à 16 cœurs sur le cœur du quai (salle 95) -> reste à 16, pas de débordement
3. debug_hook_cmd = 2 (Full Stuff) -> hud_max_hearts=16, heart_dung_mask=$ff, heart_ow_mask=$7f, cave_room_cleared[95] & 7
"""

import os
import sys
import subprocess

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART_DIR = "/home/vedix/.gemini/antigravity-cli/brain/025c3075-0ed4-40fc-8d42-f4f0093bfcd7/heart_cap_qa"
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

    mon_file = os.path.join(ART_DIR, "heart_cap.mon")
    dumps = {k: os.path.join(ART_DIR, f"d_{k}.bin") for k in [
        "d1_pick", "cap16", "dbg_full"
    ]}
    for p in dumps.values():
        if os.path.exists(p):
            os.remove(p)

    main_loop = lbl_z["main_loop"] + 6
    launch_game = lbl_i["launch_zelda_game"]

    hmax = lbl_z["hud_max_hearts"]
    hcur = lbl_z["hud_cur_hearts"]
    hdung = lbl_z["heart_dung_mask"]
    how = lbl_z["heart_ow_mask"]
    dact = lbl_z["dungeon_drop_active"]
    dtype = lbl_z["dungeon_drop_type"]
    dx = lbl_z["dungeon_drop_x"]
    dy = lbl_z["dungeon_drop_y"]
    dcd = lbl_z["dungeon_drop_cooldown"]
    dlvl = lbl_z["current_dungeon_level"]
    dridx = lbl_z["current_room_idx"]
    crc = lbl_z["cave_room_cleared"]
    px = lbl_z["player_x"]
    py = lbl_z["player_y"]
    plad = lbl_z["player_has_stepladder"]
    wt = lbl_z["current_world_type"]
    k2 = lbl_z["key_2_pressed"]
    k1 = lbl_z["key_1_pressed"]
    dhc = lbl_z["debug_hook_cmd"]

    with open(mon_file, "w", encoding="utf-8") as f:
        f.write("break 080d\ng\n")
        f.write(f"g {launch_game:04x}\n")
        f.write(f"break {main_loop:04x}\n")
        f.write("g\n")

        # 1. Entre en Donjon 1 et ramasse DROP_HEART_CONTAINER (2)
        f.write(f"> {dlvl:04x} 01\n")
        f.write(f"> {k2:04x} 01\n")
        f.write("g\n")
        f.write("g\n")
        f.write(f"> {hmax:04x} 03\n")
        f.write(f"> {hdung:04x} 00\n")
        f.write(f"> {dridx:04x} 35\n")
        f.write(f"> {dact:04x} 01\n")
        f.write(f"> {dtype:04x} 02\n")
        f.write(f"> {dcd:04x} 00\n")
        f.write(f"> {dx:04x} b0 00\n")
        f.write(f"> {dy:04x} b4\n")
        f.write(f"> {px:04x} b0 00\n")
        f.write(f"> {py:04x} b4\n")
        f.write("g\n")
        f.write("g\n")
        f.write(f's "{dumps["d1_pick"]}" 0 {hmax:04x} {hmax:04x}\n')
        f.write(f's "{dumps["d1_pick"]}.msk" 0 {hdung:04x} {hdung:04x}\n')

        # 2. Sort en Overworld et teste le plafond à 16 cœurs sur le quai salle 95
        f.write(f"> {lbl_z['dungeon_pickup_timer']:04x} 00\n")
        f.write(f"> {k1:04x} 01\n")
        f.write("g\n")
        f.write("g\n")
        f.write(f"> {wt:04x} 00\n")
        f.write(f"> {dridx:04x} 5f\n")          # 95 = $5f
        f.write(f"> {plad:04x} 01\n")
        f.write(f"> {how:04x} 00\n")
        f.write(f"> {crc + 95:04x} 00\n")
        f.write(f"> {hmax:04x} 10\n")           # déjà 16 cœurs
        f.write(f"> {hcur:04x} 30\n")           # 48 quarts
        f.write(f"> {px:04x} dc 00\n")          # X=220
        f.write(f"> {py:04x} 8c\n")             # Y=140
        f.write("g\n")
        f.write("g\n")
        f.write(f's "{dumps["cap16"]}" 0 {hmax:04x} {hcur:04x}\n')
        f.write(f's "{dumps["cap16"]}.ow" 0 {how:04x} {how:04x}\n')

        # 3. Full Stuff Debug via debug_hook_cmd = 7
        f.write(f"> {hdung:04x} 00\n")
        f.write(f"> {how:04x} 00\n")
        f.write(f"> {crc + 95:04x} 00\n")
        f.write(f"> {dhc:04x} 07\n")
        f.write("g\n")
        f.write("g\n")
        f.write(f's "{dumps["dbg_full"]}" 0 {hmax:04x} {hcur:04x}\n')
        f.write(f's "{dumps["dbg_full"]}.msk" 0 {hdung:04x} {how:04x}\n')
        f.write(f's "{dumps["dbg_full"]}.c95" 0 {crc + 95:04x} {crc + 95:04x}\n')

        f.write("quit\n")

    cmd = [
        "x64sc", "-console", "-warp", "+saveres", "-sound",
        "-cartcrt", crt_path, "-moncommands", mon_file
    ]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=45)
    if res.returncode != 0:
        print(res.stdout)
        sys.exit(1)

    p1 = read_dump(dumps["d1_pick"])[0]
    p1m = read_dump(dumps["d1_pick"] + ".msk")[0]
    assert p1 == 4 and p1m == 1, f"D1 heart pickup fail: max={p1}, mask={p1m}"

    c16 = read_dump(dumps["cap16"])
    cow = read_dump(dumps["cap16"] + ".ow")[0]
    assert c16[0] == 16 and c16[1] == 64 and cow == 1, f"Cap 16 fail: max={c16[0]}, cur={c16[1]}, ow={cow}"

    df = read_dump(dumps["dbg_full"])
    dfm = read_dump(dumps["dbg_full"] + ".msk")
    c95 = read_dump(dumps["dbg_full"] + ".c95")[0]
    assert df[0] == 16 and df[1] == 64, f"Debug full gear hearts fail: {df[0]}/{df[1]}"
    assert dfm[0] == 0xff and dfm[1] == 0x7f and (c95 & 7) != 0, (
        f"Debug full gear masks fail: dung={dfm[0]:#x}, ow={dfm[1]:#x}, c95={c95:#x}"
    )

    print("[PASS] test_heart_containers_vice: D1 Heart Mask + Cap 16 + Debug Full Stuff masks verified in VICE!")


if __name__ == "__main__":
    main()
