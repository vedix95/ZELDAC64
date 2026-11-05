#!/usr/bin/env python3
"""
tools/cartgen.py : Générateur d'image cartouche C64 Magic Desk (Type 19)
Convertit Zelda C64 en cartouche 256 Ko (.crt) avec intro et streaming instantané.
Banques 8 Ko :
  - Banque 0     : Bootloader cartouche (vecteurs CBM80, déballage intro, init)
  - Banques 1..3  : Intro PRG ($0800..$6800)
  - Banques 4..9  : Moteur résident zelda.prg ($0800..$C800)
  - Banques 10..13: Chunks Overworld OW0..OW3 (streaming instantané vers $C000)
  - Banques 14..22: Donjons 1 à 9 DUNG1..DUNG9 (streaming instantané vers $C000)
  - Banques 23..31: Réservées pour extensions / sons / graphismes
"""

import os
import sys
import subprocess
import re

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
BLD_DIR = os.path.join(BASE_DIR, "build")
SRC_DIR = os.path.join(BASE_DIR, "src")

BANK_SIZE = 8192
TOTAL_BANKS = 64

def parse_labels(vs_path):
    labels = {}
    if not os.path.exists(vs_path):
        return labels
    with open(vs_path, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            m = re.match(r'al C:([0-9a-fA-F]+) \.([a-zA-Z0-9_]+)', line)
            if m:
                labels[m.group(2)] = int(m.group(1), 16)
    return labels

def main():
    vs_path = os.path.join(BLD_DIR, "zelda.vs")
    labels = parse_labels(vs_path)

    cart_present_addr = labels.get("cart_present", 0x0810)
    start_addr = labels.get("start", 0x080D)

    print(f"[*] Configuration Cartouche :")
    print(f"    - cart_present = ${cart_present_addr:04X}")
    print(f"    - start        = ${start_addr:04X}")

    # 1. Compile cart_boot.asm pour la Banque 0
    boot_asm = os.path.join(SRC_DIR, "cart_boot.asm")
    boot_bin = os.path.join(BLD_DIR, "cart_boot.bin")
    cmd_acme = [
        "acme",
        "-f", "plain",
        "-o", boot_bin,
        boot_asm
    ]
    res = subprocess.run(cmd_acme, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"Erreur compilation cart_boot.asm :\n{res.stderr}")
        sys.exit(1)

    banks = []

    # Banque 0 : Bootloader
    with open(boot_bin, "rb") as f:
        b0_data = f.read()
    b0 = bytearray(BANK_SIZE)
    b0[:len(b0_data)] = b0_data
    banks.append(b0)
    print(f"  [+] Banque 00 : Bootloader cartouche ({len(b0_data)} octets)")

    # Banques 1..3 : intro.prg ($0800..$6800)
    intro_prg = os.path.join(BLD_DIR, "intro.prg")
    if not os.path.exists(intro_prg):
        print(f"Erreur : intro.prg introuvable à {intro_prg}")
        sys.exit(1)

    with open(intro_prg, "rb") as f:
        i_raw = f.read()
    i_payload = i_raw[2:]
    i_ram = bytearray(0x10000)
    i_ram[0x0801 : 0x0801 + len(i_payload)] = i_payload

    for b in range(1, 4):
        start_ram = (b - 1) * BANK_SIZE + 0x0800
        end_ram = start_ram + BANK_SIZE
        chunk = i_ram[start_ram:end_ram]
        banks.append(chunk)
        print(f"  [+] Banque {b:02d} : intro.prg RAM ${start_ram:04X}..${end_ram-1:04X}")

    # Banques 4..9 : zelda.prg ($0800..$C800)
    zelda_prg = os.path.join(BLD_DIR, "zelda.prg")
    if not os.path.exists(zelda_prg):
        print(f"Erreur : zelda.prg introuvable à {zelda_prg}")
        sys.exit(1)

    with open(zelda_prg, "rb") as f:
        z_raw = f.read()
    z_payload = z_raw[2:]
    z_ram = bytearray(0x10000)
    z_ram[0x0801 : 0x0801 + len(z_payload)] = z_payload

    for b in range(4, 10):
        start_ram = (b - 4) * BANK_SIZE + 0x0800
        end_ram = start_ram + BANK_SIZE
        chunk = z_ram[start_ram:end_ram]
        banks.append(chunk)
        print(f"  [+] Banque {b:02d} : zelda.prg RAM ${start_ram:04X}..${end_ram-1:04X}")

    # Banques 10..13 : Banques de Sprites dédiées (streaming vers $2800)
    sprite_files = [
        ("sprites_ow.bin", "Sprites Ennemis Overworld"),
        ("sprites_dung.bin", "Sprites Ennemis Donjons"),
        ("sprites_boss.bin", "Sprites Boss Donjons"),
        ("sprites_npc.bin", "Sprites PNJs, Grottes & Objets"),
    ]
    for fn, desc in sprite_files:
        p = os.path.join(BLD_DIR, fn)
        if not os.path.exists(p):
            subprocess.run([sys.executable, os.path.join(TOOLS_DIR, "build_sprite_banks.py")], check=True)
        with open(p, "rb") as f:
            b_data = f.read()
        b_spr = bytearray(BANK_SIZE)
        b_spr[:len(b_data)] = b_data[:BANK_SIZE]
        banks.append(b_spr)
        print(f"  [+] Banque {len(banks)-1:02d} : {desc} ({len(b_data)} octets)")

    # Banques 14..17 : Chunks Overworld OW0..OW3 (streaming vers $C000)
    for i in range(4):
        ow_path = os.path.join(BLD_DIR, f"ow{i}.dat")
        with open(ow_path, "rb") as f:
            ow_raw = f.read()
        ow_data = ow_raw[2:] # Retire header $00 $C0
        b_ow = bytearray(BANK_SIZE)
        b_ow[:len(ow_data)] = ow_data
        banks.append(b_ow)
        print(f"  [+] Banque {len(banks)-1:02d} : Overworld Chunk {i} ({len(ow_data)} octets)")

    # Banques 18..26 : Donjons 1..9 (streaming vers $C000)
    for i in range(1, 10):
        dung_path = os.path.join(BLD_DIR, f"dung{i}.dat")
        with open(dung_path, "rb") as f:
            dung_raw = f.read()
        dung_data = dung_raw[2:] # Retire header $00 $C0
        b_dung = bytearray(BANK_SIZE)
        b_dung[:len(dung_data)] = dung_data
        banks.append(b_dung)
        print(f"  [+] Banque {len(banks)-1:02d} : Donjon {i} ({len(dung_data)} octets)")

    # Banques 27..30 : Overlays de Code ($A000..$BFFF)
    overlays = [
        ("ovl_inv.dat", "Overlay Inventaire & Minimap"),
        ("ovl_cave.dat", "Overlay Cavernes & Échoppes"),
        ("ovl_items.dat", "Overlay Logiques d'Objets Spéciaux"),
        ("ovl_debug.dat", "Overlay Menu Debug"),
    ]
    for fn, desc in overlays:
        p = os.path.join(BLD_DIR, fn)
        b_ovl = bytearray(BANK_SIZE)
        if os.path.exists(p):
            with open(p, "rb") as f:
                ovl_data = f.read()
            b_ovl[:len(ovl_data)] = ovl_data[:BANK_SIZE]
            print(f"  [+] Banque {len(banks):02d} : {desc} ({len(ovl_data)} octets)")
        else:
            print(f"  [!] Banque {len(banks):02d} : {desc} (non trouvé, initialisé vide)")
        banks.append(b_ovl)

    # Banque 31 : Musiques et sons étendus (CART_BANK_AUDIO)
    audio_path = os.path.join(BLD_DIR, "cart_audio.bin")
    b_audio = bytearray(BANK_SIZE)
    if os.path.exists(audio_path):
        with open(audio_path, "rb") as f:
            a_data = f.read()
        b_audio[:len(a_data)] = a_data[:BANK_SIZE]
        print(f"  [+] Banque {len(banks):02d} : Musiques et sons étendus CART_BANK_AUDIO ({len(a_data)} octets)")
    else:
        print(f"  [!] Banque {len(banks):02d} : cart_audio.bin non trouvé, initialisé vide")
    banks.append(b_audio)

    # Remplir jusqu'à TOTAL_BANKS (64 banques = 512 Ko)
    while len(banks) < TOTAL_BANKS:
        banks.append(bytearray(BANK_SIZE))

    # Concaténer toutes les banques
    raw_bin_path = os.path.join(BLD_DIR, "zelda_banks.bin")
    with open(raw_bin_path, "wb") as f:
        for b in banks:
            f.write(b)

    total_bytes = os.path.getsize(raw_bin_path)
    print(f"[*] Fichier binaire brut généré : {raw_bin_path} ({total_bytes} octets, {len(banks)} banques)")

    # Conversion en CRT Magic Desk via cartconv
    crt_path = os.path.join(BLD_DIR, "zelda.crt")
    cmd_cartconv = [
        "cartconv",
        "-t", "md",
        "-i", raw_bin_path,
        "-o", crt_path,
        "-n", "THE LEGEND OF ZELDA"
    ]
    res_cc = subprocess.run(cmd_cartconv, capture_output=True, text=True)
    if res_cc.returncode != 0:
        print(f"Erreur cartconv :\n{res_cc.stderr}")
        sys.exit(1)

    print(f"[✓] Image Cartouche CRT prête : {crt_path} ({os.path.getsize(crt_path)} octets)")

if __name__ == "__main__":
    main()
