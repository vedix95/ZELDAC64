#!/usr/bin/env python3
"""
tools/generate_game_audio.py - Extrait et compile les partitions Overworld et Underworld
pour le moteur sonore C64 (Single SID + Dual SID).
Génère src/music_data.inc avec une table de notes unifiée et des pas compacts (4 octets/pas).
"""

import os
import re
import sys

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
ROM_PATH = os.path.join(BASE_DIR, "zelda.nes")
INTRO_ASM_PATH = os.path.join(BASE_DIR, "src", "intro_music_data.asm")
OUT_INC_PATH = os.path.join(BASE_DIR, "src", "music_data.inc")

def parse_bytes(section_text):
    bytes_list = []
    for line in section_text.splitlines():
        line = line.strip()
        if line.startswith("!byte"):
            line = line[5:].strip()
            for item in line.split(","):
                item = item.strip()
                if not item:
                    continue
                if item.startswith("<$") or item.startswith(">$"):
                    bytes_list.append(int(item[2:], 16))
                elif item.startswith("$"):
                    bytes_list.append(int(item[1:], 16))
                else:
                    bytes_list.append(int(item))
    return bytes_list

def get_section(text, name):
    m = re.search(rf"{name}:\s*\n(.*?)(?=\n\w+:|\Z)", text, re.DOTALL)
    if not m:
        raise ValueError(f"Section {name} non trouvée dans {INTRO_ASM_PATH}")
    return parse_bytes(m.group(1))

def load_overworld():
    with open(INTRO_ASM_PATH, "r", encoding="utf-8") as f:
        text = f.read()

    p1_dur = get_section(text, "music_p1_dur")
    p1_v1_lo = get_section(text, "music_p1_v1_lo")
    p1_v1_hi = get_section(text, "music_p1_v1_hi")
    p1_v2_lo = get_section(text, "music_p1_v2_lo")
    p1_v2_hi = get_section(text, "music_p1_v2_hi")
    p1_v3_perc = get_section(text, "music_p1_v3_perc")

    p2_dur = get_section(text, "music_p2_dur")
    p2_v1_lo = get_section(text, "music_p2_v1_lo")
    p2_v1_hi = get_section(text, "music_p2_v1_hi")
    p2_v2_lo = get_section(text, "music_p2_v2_lo")
    p2_v2_hi = get_section(text, "music_p2_v2_hi")
    p2_v3_perc = get_section(text, "music_p2_v3_perc")

    # En jeu, la boucle d'Overworld démarre à loop_step = 26 de Part 1 (où débute le thème)
    # Part 1 : pas 26 à 236
    p1_steps = []
    for i in range(26, len(p1_dur)):
        f1 = p1_v1_lo[i] | (p1_v1_hi[i] << 8)
        f2 = p1_v2_lo[i] | (p1_v2_hi[i] << 8)
        p1_steps.append((p1_dur[i], f1, f2, p1_v3_perc[i]))

    # Part 2 : pas 0 à 237
    p2_steps = []
    for i in range(len(p2_dur)):
        f1 = p2_v1_lo[i] | (p2_v1_hi[i] << 8)
        f2 = p2_v2_lo[i] | (p2_v2_hi[i] << 8)
        p2_steps.append((p2_dur[i], f1, f2, p2_v3_perc[i]))

    return p1_steps, p2_steps

def load_underworld():
    if not os.path.exists(ROM_PATH):
        sys.exit(f"Erreur : {ROM_PATH} introuvable.")
    with open(ROM_PATH, "rb") as f:
        rom = f.read()[16:]
    b0 = rom[0:0x4000]

    dur_table = list(b0[0x1FD1 : 0x1FD1 + 16])
    freq_table = [b0[0x1F31 + i*2] | (b0[0x1F31 + i*2 + 1] << 8) for i in range(64)]

    def note_to_sid(n):
        if n == 0 or n == 8:
            return 0
        idx = (n >> 1)
        if idx < len(freq_table):
            period = freq_table[idx]
            if period > 0:
                hz = 1789773.0 / (16.0 * (period + 1))
                return int(round(hz * 17.0284))
        return 0

    def parse_ch(off, max_len):
        evs = []
        t = 0
        cur_dur = dur_table[4]
        i = 0
        while i < max_len:
            b = b0[off + i]
            if b == 0:
                break
            elif b & 0x80:
                cur_dur = dur_table[b & 0x07]
            elif b >= 0xF0:
                pass
            else:
                freq = note_to_sid(b)
                evs.append((t, cur_dur, freq))
                t += cur_dur
            i += 1
        return evs

    c1 = parse_ch(0x91FD - 0x8000, 0xA5)
    c2 = parse_ch(0x92A2 - 0x8000, 0x53)
    c3 = parse_ch(0x92F5 - 0x8000, 0xCD)

    def get_at(evs, t):
        tot = evs[-1][0] + evs[-1][1]
        if tot == 0:
            return 0
        t_mod = t % tot
        for s, d, f in evs:
            if s <= t_mod < s + d:
                return f
        return 0

    uw_steps = []
    for t, dur, f1 in c1:
        f2 = get_at(c2, t)
        f3 = get_at(c3, t)
        frames = int(round(dur * 1.5))
        if frames < 3:
            frames = 3
        if frames > 45:
            frames = 45
        uw_steps.append((frames, f1, f2, f3))

    return uw_steps

def main():
    ow_p1, ow_p2 = load_overworld()
    uw_steps = load_underworld()

    # Collecte de toutes les fréquences non nulles
    freqs = set()
    for _, f1, f2, _ in ow_p1 + ow_p2:
        if f1 > 0: freqs.add(f1)
        if f2 > 0: freqs.add(f2)
    for _, f1, f2, f3 in uw_steps:
        if f1 > 0: freqs.add(f1)
        if f2 > 0: freqs.add(f2)
        if f3 > 0: freqs.add(f3)

    sorted_freqs = sorted(list(freqs))
    freq_to_idx = {f: idx + 1 for idx, f in enumerate(sorted_freqs)}
    freq_to_idx[0] = 0

    print(f"Total notes uniques dans la table : {len(sorted_freqs)}")
    print(f"Overworld P1 : {len(ow_p1)} pas, P2 : {len(ow_p2)} pas")
    print(f"Underworld : {len(uw_steps)} pas")

    # Génération du fichier source ASM
    lines = []
    lines.append("; ===========================================================================")
    lines.append("; music_data.inc - Partition compacte Overworld & Underworld pour Zelda C64")
    lines.append("; GENERE AUTOMATIQUEMENT par tools/generate_game_audio.py - NE PAS MODIFIER")
    lines.append("; ===========================================================================")
    lines.append("")

    lines.append(f"MUSIC_NOTE_COUNT = {len(sorted_freqs)}")
    lines.append(f"MUSIC_OW_P1_LEN  = {len(ow_p1)}")
    lines.append(f"MUSIC_OW_P2_LEN  = {len(ow_p2)}")
    lines.append(f"MUSIC_UW_LEN     = {len(uw_steps)}")
    lines.append("")

    # Table des fréquences SID
    lo_bytes = [0] + [f & 0xFF for f in sorted_freqs]
    hi_bytes = [0] + [(f >> 8) & 0xFF for f in sorted_freqs]

    lines.append("; Table des frequences SID (Index 0 = Silence)")
    lines.append("music_note_freq_lo:")
    for i in range(0, len(lo_bytes), 16):
        lines.append("        !byte " + ", ".join(f"${b:02x}" for b in lo_bytes[i:i+16]))
    lines.append("music_note_freq_hi:")
    for i in range(0, len(hi_bytes), 16):
        lines.append("        !byte " + ", ".join(f"${b:02x}" for b in hi_bytes[i:i+16]))
    lines.append("")

    def write_dataset(name, steps, is_dungeon=False):
        durs = [s[0] for s in steps]
        v1s = [freq_to_idx[s[1]] for s in steps]
        v2s = [freq_to_idx[s[2]] for s in steps]
        if is_dungeon:
            # f3 est une fréquence de note basse
            v3s = [freq_to_idx[s[3]] for s in steps]
        else:
            # percussion : 0 = none, $80 = noise snare
            v3s = [0x80 if s[3] else 0 for s in steps]

        lines.append(f"; --- {name} ({len(steps)} pas) ---")
        lines.append(f"{name}_dur:")
        for i in range(0, len(durs), 16):
            lines.append("        !byte " + ", ".join(f"{d:3d}" for d in durs[i:i+16]))
        lines.append(f"{name}_v1:")
        for i in range(0, len(v1s), 16):
            lines.append("        !byte " + ", ".join(f"{n:3d}" for n in v1s[i:i+16]))
        lines.append(f"{name}_v2:")
        for i in range(0, len(v2s), 16):
            lines.append("        !byte " + ", ".join(f"{n:3d}" for n in v2s[i:i+16]))
        lines.append(f"{name}_v3:")
        for i in range(0, len(v3s), 16):
            lines.append("        !byte " + ", ".join(f"${n:02x}" for n in v3s[i:i+16]))
        lines.append("")

    write_dataset("music_ow_p1", ow_p1, is_dungeon=False)
    write_dataset("music_ow_p2", ow_p2, is_dungeon=False)
    write_dataset("music_uw", uw_steps, is_dungeon=True)

    with open(OUT_INC_PATH, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")

    print(f"OK : {OUT_INC_PATH} généré avec succès !")

if __name__ == "__main__":
    main()
