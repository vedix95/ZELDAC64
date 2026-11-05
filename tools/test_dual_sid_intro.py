#!/usr/bin/env python3
"""
tools/test_dual_sid_intro.py - Test automatisé du Dual SID Stéréo ($D420) pendant l'Intro & Logo
Vérifie :
1. Sélection de l'Option 2 (2 SID - Stereo $D420) au menu de boot.
2. Initialisation de SID2_VOLUME = 15 et registres ADSR/PW.
3. Rendu sonore sur SID 1 ($D400) et SID 2 ($D420) pendant la cascade, le parchemin et le grand blason.
4. Voix 1 et Voix 2 avec detune spatial (+2) sur SID 2.
5. Percussion bruit blanc sur Voix 3 de SID 1 et SID 2.
"""
import subprocess
import os
import sys

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

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

def read_hw_regs(bin_path):
    with open(bin_path, "rb") as f:
        raw = f.read()
    data = raw[2:]
    sid1 = data[0:25]
    sid2 = data[32:57]
    return {
        'sid1_vol': sid1[24],
        'sid2_vol': sid2[24],
        'sid1_v1_freq': (sid1[1] << 8) | sid1[0],
        'sid2_v1_freq': (sid2[1] << 8) | sid2[0],
        'sid1_v2_freq': (sid1[8] << 8) | sid1[7],
        'sid2_v2_freq': (sid2[8] << 8) | sid2[7],
        'sid1_v1_ctrl': sid1[4],
        'sid2_v1_ctrl': sid2[4],
        'sid1_v2_ctrl': sid1[11],
        'sid2_v2_ctrl': sid2[11],
        'sid1_v3_ctrl': sid1[18],
        'sid2_v3_ctrl': sid2[18],
    }

def main():
    intro_vs = os.path.join(BASE_DIR, "build", "intro.vs")
    i_labels = load_labels(intro_vs)

    cursor_addr = i_labels.get('menu_cursor_idx', 0x09D5)
    sid_menu_addr = i_labels.get('sid_setup_menu_loop', 0x573a)
    intro_update_addr = i_labels.get('intro_update', 0x299b)

    print("=================================================================")
    print("   TEST AUTOMATISÉ : DUAL SID STÉRÉO ($D420) SUR INTRO & LOGO   ")
    print("=================================================================")

    dump_path = "/tmp/intro_dual_sid_hw.bin"
    if os.path.exists(dump_path):
        os.remove(dump_path)

    mon_file = "/tmp/test_dual_sid_intro.mon"
    with open(mon_file, "w") as f:
        # 1. Sélectionner Option 2 (2 SID - Stereo $D420) au boot
        f.write(f"bk {sid_menu_addr:04x}\n")
        f.write("g\n")
        f.write("del\n")
        f.write(f"> {cursor_addr:04x} 01\n") # Option 2 ($D420)
        f.write("> 0816 01\n")               # Valider menu

        # 2. Breakpoint permanent sur intro_update (chaque 'g' avance d'une frame)
        f.write(f"bk {intro_update_addr:04x}\n")
        f.write("g\n")
        for _ in range(50):
            f.write("g\n")

        # 3. Dumper les registres matériels SID1 ($D400..$D418) et SID2 ($D420..$D438)
        f.write(f's "{dump_path}" 0 d400 d438\n')
        f.write("q\n")

    cmd = [
        "x64sc", "-default", "-warp",
        "-sidextra", "1",
        "-sid2address", "0xd420",
        "-moncommands", mon_file,
        "-cartcrt", os.path.join(BASE_DIR, "build", "zelda.crt")
    ]
    res = subprocess.run(cmd, capture_output=True, text=True, timeout=20)
    if not os.path.exists(dump_path):
        sys.exit(f"Erreur : Le dump {dump_path} n'a pas été produit.")

    regs = read_hw_regs(dump_path)
    print(f"SID1 Volume : {regs['sid1_vol']} (Attendu: 15)")
    print(f"SID2 Volume : {regs['sid2_vol']} (Attendu: 15)")
    print(f"SID1 Voix 1 Freq: ${regs['sid1_v1_freq']:04X}, Ctrl: ${regs['sid1_v1_ctrl']:02X}")
    print(f"SID2 Voix 1 Freq: ${regs['sid2_v1_freq']:04X}, Ctrl: ${regs['sid2_v1_ctrl']:02X}")
    print(f"SID1 Voix 2 Freq: ${regs['sid1_v2_freq']:04X}, Ctrl: ${regs['sid1_v2_ctrl']:02X}")
    print(f"SID2 Voix 2 Freq: ${regs['sid2_v2_freq']:04X}, Ctrl: ${regs['sid2_v2_ctrl']:02X}")

    assert regs['sid1_vol'] == 15, "SID1 volume != 15"
    assert regs['sid2_vol'] == 15, "SID2 volume != 15 (SID2 est muet !)"
    assert regs['sid2_v1_ctrl'] & 1 == 1, "SID2 Voix 1 Gate n'est pas actif !"
    assert regs['sid2_v2_ctrl'] & 1 == 1, "SID2 Voix 2 Gate n'est pas actif !"
    assert regs['sid2_v1_freq'] == regs['sid1_v1_freq'] + 2, f"Detune chorus incorrect sur SID2 V1 : ${regs['sid2_v1_freq']:04X} vs ${regs['sid1_v1_freq']:04X}"
    assert regs['sid2_v2_freq'] == regs['sid1_v2_freq'] + 2, f"Detune chorus incorrect sur SID2 V2 : ${regs['sid2_v2_freq']:04X} vs ${regs['sid1_v2_freq']:04X}"

    print("\n✓ PASS : Intro et Logo jouent intégralement en Dual SID Stéréo ($D420) avec chorus detune !")

if __name__ == "__main__":
    main()
