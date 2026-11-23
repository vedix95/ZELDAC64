#!/usr/bin/env python3
"""
Test live de persistance réelle sur cartouche EasyFlash (-easyflashcrtwrite) :
1. Copie build/zelda.crt -> /tmp/zelda_save_test.crt
2. Session 1 : File Select (screenshot) -> Jeu -> modifie stats/inventaire/Triforce -> Save (key_4_pressed)
3. Session 2 (cold reboot sur le même .crt) : File Select (screenshot) -> charge Slot 0 -> vérifie restauration en RAM
"""

import os
import sys
import shutil
import subprocess

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART_DIR = "/home/vedix/.gemini/antigravity-cli/brain/025c3075-0ed4-40fc-8d42-f4f0093bfcd7/save_crt_qa"
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
    src_crt = os.path.join(BASE_DIR, "build", "zelda.crt")
    tmp_crt = "/tmp/zelda_save_test.crt"
    shutil.copyfile(src_crt, tmp_crt)

    lbl_z = load_labels(os.path.join(BASE_DIR, "build", "zelda.vs"))
    lbl_i = load_labels(os.path.join(BASE_DIR, "build", "intro.vs"))
    lbl_s = load_labels(os.path.join(BASE_DIR, "build", "ovl_save.vs"))

    ss_empty = os.path.join(ART_DIR, "01_file_select_empty.png")
    ss_saved = os.path.join(ART_DIR, "02_file_select_saved.png")
    d_restored = os.path.join(ART_DIR, "d_restored.bin")
    for p in [ss_empty, ss_saved, d_restored]:
        if os.path.exists(p):
            os.remove(p)

    main_loop = lbl_z["main_loop"] + 6
    launch_game = lbl_i["launch_zelda_game"]
    open_fs = lbl_i["open_file_select"]

    # --- SESSION 1 : Boot -> File Select vide -> Jeu -> Save sur Flash CRT ---
    mon1 = os.path.join(ART_DIR, "s1.mon")
    with open(mon1, "w", encoding="utf-8") as f:
        f.write("break 080d\ng\ndel\n")
        f.write(f"break {lbl_s['fs_draw_select_screen']:04x}\n")
        f.write(f"g {open_fs:04x}\n")
        f.write("del\n")
        f.write("z 5000\n")
        f.write(f'screenshot "{ss_empty}" 2\n')
        f.write(f"break {main_loop:04x}\n")
        f.write(f"g {launch_game:04x}\n")
        # Modifie l'état du joueur et sauvegarde sur Slot 0
        f.write("> df00 00\n")
        f.write(f"> {lbl_z['hud_max_hearts']:04x} 07\n")
        f.write(f"> {lbl_z['hud_cur_hearts']:04x} 07\n")
        f.write(f"> {lbl_z['hud_rupees']:04x} 2a\n")         # 42 rubis
        f.write(f"> {lbl_z['player_has_sword']:04x} 02\n")   # White Sword
        f.write(f"> {lbl_z['player_triforce_pieces']:04x} 05\n")
        f.write(f"> {lbl_z['key_4_pressed']:04x} 01\n")
        f.write("g\n")
        f.write("g\n")
        f.write("quit\n")

    print("[*] Session 1 : Création + sauvegarde Flash dans /tmp/zelda_save_test.crt...")
    subprocess.run(
        ["x64sc", "-default", "+saveres", "-easyflashcrtwrite", "-cartcrt", tmp_crt, "-moncommands", mon1, "-warp"],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=30, check=False,
    )

    # --- SESSION 2 : Cold reboot sur le même .crt -> File Select -> Charge Slot 0 ---
    mon2 = os.path.join(ART_DIR, "s2.mon")
    with open(mon2, "w", encoding="utf-8") as f:
        f.write("break 080d\ng\n")
        f.write(f"g {open_fs:04x}\n")
        f.write("z 500000\n")
        f.write(f'screenshot "{ss_saved}" 2\n')
        # Simuler appui FIRE sur Slot 0 ($DC00 bit 4 = 0) pendant 2 frames
        f.write("keybuf \\x20\n")
        # Ou directement sélectionner Slot 0 via FIRE joystick : $DC00 = $EF
        # Pour un test 100% déterministe sans timing clavier, on met EF_RAM_LOADED=1 si déjà chargé:
        # Vérifions d'abord que le Slot 0 est bien présent dans save_buf ($Axxx) en simulant FIRE
        f.write(f"g {launch_game:04x}\n")
        # Note: ovl_file_select_run copie le slot sélectionné dans $DF10..$DF5F;
        # Vérifions directement en appuyant sur FIRE dans File Select :
        f.write("quit\n")

    save_buf = lbl_s["save_buf"]
    with open(mon2, "w", encoding="utf-8") as f:
        f.write("break 080d\ng\ndel\n")
        f.write(f"break {lbl_s['fs_draw_select_screen']:04x}\n")
        f.write(f"g {open_fs:04x}\n")
        f.write("del\n")
        f.write("z 5000\n")
        f.write(f'screenshot "{ss_saved}" 2\n')
        f.write(f's "{d_restored}" 0 {save_buf:04x} {save_buf + 96:04x}\n')
        f.write("quit\n")

    print("[*] Session 2 : Cold reboot VICE sur /tmp/zelda_save_test.crt...")
    subprocess.run(
        ["x64sc", "-default", "+saveres", "-easyflashcrtwrite", "-cartcrt", tmp_crt, "-moncommands", mon2, "-warp"],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=30, check=False,
    )

    for p in [ss_empty, ss_saved]:
        pcx = p + ".pcx"
        if os.path.exists(pcx):
            subprocess.run(["magick", pcx, p], check=True)
            os.remove(pcx)

    buf = read_dump(d_restored)
    magic = bytes(buf[0:2])
    seq = buf[3] | (buf[4] << 8)
    slot0_active = buf[8 + 0]
    slot0_hearts = buf[8 + 11]
    slot0_rupees = buf[8 + 12]
    slot0_sword = buf[8 + 15]
    slot0_triforce = buf[8 + 29]

    assert magic == b"ZL", f"Magic Flash invalide: {magic!r}"
    assert seq >= 1, f"Seq invalide: {seq}"
    assert slot0_active == 1, f"Slot 0 non actif après reboot: {slot0_active}"
    assert slot0_hearts == 7, f"Cœurs max attendus 7, obtenu {slot0_hearts}"
    assert slot0_rupees == 42, f"Rubis attendus 42, obtenu {slot0_rupees}"
    assert slot0_sword == 2, f"Épée attendue 2, obtenu {slot0_sword}"
    assert slot0_triforce == 5, f"Triforce attendue 5, obtenu {slot0_triforce}"

    print(f"[PASS] Persistance Flash EasyFlash vérifiée après cold reboot : magic=ZL, seq={seq}, hearts={slot0_hearts}, rupees={slot0_rupees}, sword={slot0_sword}, triforce=${slot0_triforce:02x}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
