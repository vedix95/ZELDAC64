#!/usr/bin/env python3
"""
tools/extract_music.py - Extraction des données musicales de The Legend of Zelda (NES)

Extrait les tables de fréquences APU, tables de durées et séquences de notes
(Overworld & Underworld) depuis une ROM authentique 'zelda.nes' (Banque 0)
et les sauvegarde dans un format JSON propre ('assets/music_data.json').

Cela permet de compiler l'audio C64 sans avoir à versionner la ROM protégée sur Git.
"""

import os
import sys
import json
import argparse

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DEFAULT_ROM = os.path.join(BASE_DIR, "zelda.nes")
DEFAULT_OUT = os.path.join(BASE_DIR, "assets", "music_data.json")

def load_rom_bank0(rom_path):
    if not os.path.exists(rom_path):
        raise FileNotFoundError(
            f"ROM NES introuvable à l'emplacement '{rom_path}'.\n"
            f"Veuillez placer votre ROM 'zelda.nes' dans la racine du projet pour extraire la musique."
        )
    with open(rom_path, "rb") as f:
        data = f.read()

    if len(data) < 16 + 0x4000:
        raise ValueError(f"Taille de ROM invalide ({len(data)} octets). ROM iNES attendue.")

    # Saut du header iNES de 16 octets, Banque 0 = premiers 16 Ko (0x4000)
    rom_no_header = data[16:]
    return rom_no_header[0:0x4000]

def extract_music_data(rom_path=DEFAULT_ROM):
    b0 = load_rom_bank0(rom_path)

    # 1. Table des périodes APU NES à $9F00 (Offset $1F00 dans Bank 0)
    # Deux octets Big-Endian par note (64 notes)
    freq_table = [(b0[0x1F00 + i * 2] << 8) | b0[0x1F00 + i * 2 + 1] for i in range(64)]

    # 2. Tables de durée de notes (NoteLengthTable) à $9FD1 (Offset $1FD1 dans Bank 0)
    note_len_table = list(b0[0x1FD1 : 0x1FD1 + 32])

    # 3. Phrases Overworld de SongScriptOverworld0
    ow_phrase_defs = [
        ('P2', 0x8F0F, 0x16, 0x35, 0xCE),
        ('P3', 0x8F55, 0x26, 0x60, 0x88),
        ('P5', 0x8FE4, 0x1A, 0x3B, 0xF2),
        ('P4', 0x9032, 0x2D, 0x59, 0xA4),
    ]

    ow_scripts = {}
    for name, saddr, sq0, trg, noise in ow_phrase_defs:
        off = saddr - 0x8000
        ow_scripts[name] = {
            'addr': saddr,
            'sq0_off': sq0,
            'trg_off': trg,
            'noise_off': noise,
            'bytes': list(b0[off : off + noise])
        }

    # 4. Phrases Underworld de SongScriptUnderworld0
    uw_phrase_defs = [
        ('P1', 0x90DD, 0x22, 0x45, 0x5D),
        ('P2', 0x913A, 0x1C, 0x39, 0x6A)
    ]

    uw_scripts = {}
    for name, saddr, sq0, trg, end in uw_phrase_defs:
        off = saddr - 0x8000
        uw_scripts[name] = {
            'addr': saddr,
            'sq0_off': sq0,
            'trg_off': trg,
            'end_off': end,
            'bytes': list(b0[off : off + end])
        }

    # 5. Fanfare d'obtention d'objet (SongScriptItemTaken0 à $8E5D)
    item_off = 0x8E5D - 0x8000
    item_fanfare = {
        'addr': 0x8E5D,
        'sq0_off': 0x07,
        'trg_off': 0x0D,
        'end_off': 0x13,
        'bytes': list(b0[item_off : item_off + 0x13])
    }

    # 6. Fanfare de la Triforce / Fin de niveau (SongScriptEndLevel0 à $91A4)
    tri_off = 0x91A4 - 0x8000
    triforce_fanfare = {
        'addr': 0x91A4,
        'sq0_off': 0x22,
        'trg_off': 0x46,
        'end_off': 0x59,
        'bytes': list(b0[tri_off : tri_off + 0x59])
    }

    # 7. Thème authentique du Donjon 9 (Niveau 9 - Montagne de la Mort : SongScriptLastLevel0 à $91FD)
    d9_off = 0x91FD - 0x8000
    dungeon_final = {
        'addr': 0x91FD,
        'sq0_off': 0x53,
        'trg_off': 0xA5,
        'end_off': 0xCD,
        'bytes': list(b0[d9_off : d9_off + 0xCD])
    }

    data = {
        "_description": "Partitions musicales authentiques de The Legend of Zelda (NES, Banque 0)",
        "_generator": "tools/extract_music.py",
        "freq_table": freq_table,
        "note_len_table": note_len_table,
        "ow_phrase_order": ['P2', 'P3', 'P5', 'P2', 'P4', 'P5'],
        "ow_scripts": ow_scripts,
        "uw_scripts": uw_scripts,
        "item_fanfare": item_fanfare,
        "triforce_fanfare": triforce_fanfare,
        "dungeon_final": dungeon_final
    }

    return data

def main():
    parser = argparse.ArgumentParser(description="Extrait les données musicales de The Legend of Zelda (NES) vers JSON.")
    parser.add_argument("--rom", default=DEFAULT_ROM, help="Chemin vers la ROM zelda.nes")
    parser.add_argument("--out", default=DEFAULT_OUT, help="Chemin de sortie pour music_data.json")
    args = parser.parse_args()

    try:
        print(f"[*] Lecture de la ROM : {args.rom}")
        music_data = extract_music_data(args.rom)

        os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
        with open(args.out, "w", encoding="utf-8") as f:
            json.dump(music_data, f, indent=2)

        print(f"[+] Succès : {args.out} généré ({os.path.getsize(args.out)} octets).")
        print(f"    - Table fréquences APU : {len(music_data['freq_table'])} entrées")
        print(f"    - Table durées notes   : {len(music_data['note_len_table'])} entrées")
        print(f"    - Phrases Overworld    : {list(music_data['ow_scripts'].keys())}")
        print(f"    - Phrases Underworld   : {list(music_data['uw_scripts'].keys())}")
        print(f"    - Fanfare Objet        : {len(music_data['item_fanfare']['bytes'])} octets")
        print(f"    - Fanfare Triforce     : {len(music_data['triforce_fanfare']['bytes'])} octets")
        print(f"    - Thème Donjon 9 (Final) : {len(music_data['dungeon_final']['bytes'])} octets")
    except Exception as e:
        sys.exit(f"Erreur lors de l'extraction : {e}")

if __name__ == "__main__":
    main()
