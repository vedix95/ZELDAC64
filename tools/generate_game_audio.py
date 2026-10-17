#!/usr/bin/env python3
"""
tools/generate_game_audio.py - Extrait et compile les partitions authentiques
Overworld et Underworld depuis zelda.nes pour le moteur sonore C64 (Single SID + Dual SID).
Génère src/music_data.inc avec une table de notes unifiée, gestion du prolongement TIE ($FE)
et des pas compacts (durée en frames PAL + 3 voix).

Formule SID pour PAL C64 :
  F_sid = int(round(F_hz * 17.0284))

Fréquences APU NES :
  Square : F_hz = 1789773.0 / (16.0 * (period + 1))
  Triangle: F_hz = 1789773.0 / (32.0 * (period + 1))   (1 octave plus bas que Square !)
"""

import os
import sys

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
ROM_PATH = os.path.join(BASE_DIR, "zelda.nes")
OUT_INC_PATH = os.path.join(BASE_DIR, "src", "music_data.inc")

def load_rom_bank0():
    if not os.path.exists(ROM_PATH):
        sys.exit(f"Erreur : '{ROM_PATH}' introuvable.")
    with open(ROM_PATH, "rb") as f:
        rom = f.read()[16:] # sauter le header iNES de 16 octets
    return rom[0:0x4000]

def build_audio_data():
    b0 = load_rom_bank0()

    # Table des périodes APU NES à $9F00 (Offset $1F00 dans Bank 0)
    # Deux octets Big-Endian par note (64 notes)
    freq_table = [(b0[0x1F00 + i*2] << 8) | b0[0x1F00 + i*2 + 1] for i in range(64)]

    # Tables de durée de notes (NoteLengthTable) à $9FD1 (Offset $1FD1 dans Bank 0)
    note_len_table = b0[0x1FD1 : 0x1FD1 + 32]
    ow_durs = note_len_table[16 : 24] # NoteLengthTable2 ($10) pour Overworld
    uw_durs = note_len_table[0 : 8]   # NoteLengthTable0 ($00) pour Underworld

    def nes_note_to_sid(b, is_trg=False):
        if b == 0 or b == 8:
            return 0
        idx = b >> 1
        if idx >= len(freq_table):
            return 0
        period = freq_table[idx]
        if period > 0:
            # Le canal Triangle NES a un séquenceur de 32 pas vs 16 pas pour Square :
            # pour la même valeur de période, Triangle joue exactement 1 octave plus bas !
            divisor = 32.0 if is_trg else 16.0
            hz = 1789773.0 / (divisor * (period + 1))
            return int(round(hz * 17.0284))
        return 0

    # -----------------------------------------------------------------------
    # 1. Extraction Overworld : Boucle principale d'aventure (sans fanfare intro)
    # Phrases 2, 3, 5, 2, 4, 5 de SongScriptOverworld0
    # -----------------------------------------------------------------------
    ow_phrases = [
        ('P2', 0x8F0F, 0x16, 0x35, 0xCE),
        ('P3', 0x8F55, 0x26, 0x60, 0x88),
        ('P5', 0x8FE4, 0x1A, 0x3B, 0xF2),
        ('P2', 0x8F0F, 0x16, 0x35, 0xCE),
        ('P4', 0x9032, 0x2D, 0x59, 0xA4),
        ('P5', 0x8FE4, 0x1A, 0x3B, 0xF2),
    ]

    def decode_ow_channel(script_addr, start_off, end_off, max_ticks, is_trg=False):
        script = b0[script_addr - 0x8000:]
        p = start_off
        t = 0
        cur_dur = ow_durs[0]
        evs = []
        loop_cnt = 0
        loop_start = 0
        while p < end_off and t < max_ticks:
            b = script[p]
            p += 1
            if b == 0:
                break
            if b < 0x80:
                evs.append((t, cur_dur, nes_note_to_sid(b, is_trg)))
                t += cur_dur
            elif is_trg and b == 0xF0:
                if loop_cnt > 1:
                    loop_cnt -= 1
                    p = loop_start
            elif is_trg and b > 0xF0:
                loop_cnt = b - 0xF0
                loop_start = p
            else:
                cur_dur = ow_durs[b & 0x07]
        return evs

    ow_c1, ow_c2, ow_c3 = [], [], []
    cur_t = 0
    for name, saddr, sq0_off, trg_off, noise_off in ow_phrases:
        p_script = b0[saddr - 0x8000:]
        p, p_len = 0, 0
        c_dur = ow_durs[0]
        while p < sq0_off:
            b = p_script[p]
            p += 1
            if b == 0:
                break
            if b < 0x80:
                p_len += c_dur
            else:
                c_dur = ow_durs[b & 0x07]
                if p_script[p] != 0:
                    p_len += c_dur
                    p += 1
                else:
                    break

        ev1 = decode_ow_channel(saddr, 0, sq0_off, p_len, is_trg=False)
        ev2 = decode_ow_channel(saddr, sq0_off, trg_off, p_len, is_trg=False)
        ev3 = decode_ow_channel(saddr, trg_off, noise_off, p_len, is_trg=True)

        for t, dur, sid in ev1: ow_c1.append((cur_t + t, dur, sid))
        for t, dur, sid in ev2: ow_c2.append((cur_t + t, dur, sid))
        for t, dur, sid in ev3: ow_c3.append((cur_t + t, dur, sid))
        cur_t += p_len

    # -----------------------------------------------------------------------
    # 2. Extraction Underworld : SongScriptUnderworld0 ($90DD et $913A)
    # Thème authentique culte des Donjons 1 à 8 en Sol mineur
    # Phrase 1 : 640 ticks APU
    # Phrase 2 : 520 ticks APU
    # Total boucle complète : 1160 ticks (~19.33 secondes)
    # -----------------------------------------------------------------------
    def decode_uw_track(script_addr, start, end, is_trg=False):
        script = b0[script_addr - 0x8000:]
        p = start
        t = 0
        cur_dur = uw_durs[0]
        evs = []
        while p < end:
            b = script[p]
            p += 1
            if b == 0:
                break
            if b < 0x80:
                evs.append((t, cur_dur, nes_note_to_sid(b, is_trg)))
                t += cur_dur
            else:
                cur_dur = uw_durs[b & 0x07]
                if p >= end:
                    break
                b2 = script[p]
                p += 1
                if b2 == 0:
                    break
                evs.append((t, cur_dur, nes_note_to_sid(b2, is_trg)))
                t += cur_dur
        return evs

    # Phrase 1 ($90DD) : 640 ticks
    # Sq1: 0..0x22, Sq0: 0x22..0x45, Trg: 0x45..0x5D
    uw_p1_c1 = decode_uw_track(0x90DD, 0, 0x22, is_trg=False)
    uw_p1_c2 = decode_uw_track(0x90DD, 0x22, 0x45, is_trg=False)
    uw_p1_c3 = decode_uw_track(0x90DD, 0x45, 0x5D, is_trg=True)

    # Phrase 2 ($913A) : 520 ticks
    # Sq1: 0..0x1C, Sq0: 0x1C..0x39, Trg: 0x39..0x6A
    uw_p2_c1 = decode_uw_track(0x913A, 0, 0x1C, is_trg=False)
    uw_p2_c2 = decode_uw_track(0x913A, 0x1C, 0x39, is_trg=False)
    uw_p2_c3 = decode_uw_track(0x913A, 0x39, 0x6A, is_trg=True)

    uw_c1 = uw_p1_c1 + [(640 + t, d, s) for t, d, s in uw_p2_c1]
    uw_c2 = uw_p1_c2 + [(640 + t, d, s) for t, d, s in uw_p2_c2]
    uw_c3 = uw_p1_c3 + [(640 + t, d, s) for t, d, s in uw_p2_c3]
    uw_total_ticks = 1160

    # -----------------------------------------------------------------------
    # Compilation chronologique en pas discrets PAL
    # -----------------------------------------------------------------------
    def compile_timeline(c1_events, c2_events, c3_events, total_ticks):
        times = set()
        for t, dur, sid in c1_events: times.add(t)
        for t, dur, sid in c2_events: times.add(t)
        for t, dur, sid in c3_events: times.add(t)
        sorted_times = sorted(list(times))

        onsets1 = {t: sid for t, dur, sid in c1_events}
        onsets2 = {t: sid for t, dur, sid in c2_events}
        onsets3 = {t: sid for t, dur, sid in c3_events}

        def is_active(evs, t):
            for s, dur, sid in evs:
                if s <= t < s + dur and sid > 0:
                    return True
            return False

        steps = []
        for i in range(len(sorted_times)):
            t = sorted_times[i]
            dt = sorted_times[i+1] - t if i+1 < len(sorted_times) else (total_ticks - t)
            if dt <= 0:
                dt = 12
            frames = int(round(dt * 50.0 / 60.0))
            if frames < 1:
                frames = 1

            if t in onsets1: v1 = onsets1[t]
            elif is_active(c1_events, t): v1 = 0xFE
            else: v1 = 0

            if t in onsets2: v2 = onsets2[t]
            elif is_active(c2_events, t): v2 = 0xFE
            else: v2 = 0

            if t in onsets3: v3 = onsets3[t]
            elif is_active(c3_events, t): v3 = 0xFE
            else: v3 = 0

            steps.append((frames, v1, v2, v3))

        return steps

    ow_steps = compile_timeline(ow_c1, ow_c2, ow_c3, cur_t)
    split_ow = len(ow_steps) // 2
    ow_p1 = ow_steps[:split_ow]
    ow_p2 = ow_steps[split_ow:]

    uw_steps = compile_timeline(uw_c1, uw_c2, uw_c3, uw_total_ticks)

    # -----------------------------------------------------------------------
    # Indexation de toutes les fréquences SID uniques
    # -----------------------------------------------------------------------
    freqs = set()
    for _, f1, f2, f3 in ow_p1 + ow_p2 + uw_steps:
        if f1 not in (0, 0xFE): freqs.add(f1)
        if f2 not in (0, 0xFE): freqs.add(f2)
        if f3 not in (0, 0xFE): freqs.add(f3)

    sorted_freqs = sorted(list(freqs))
    if len(sorted_freqs) > 120:
        sys.exit(f"Erreur : Trop de notes uniques ({len(sorted_freqs)} > 120).")

    freq_to_idx = {f: idx + 1 for idx, f in enumerate(sorted_freqs)}
    freq_to_idx[0] = 0
    freq_to_idx[0xFE] = 0xFE

    print(f"Notes uniques globales : {len(sorted_freqs)}")
    print(f"Overworld Partie 1    : {len(ow_p1)} pas")
    print(f"Overworld Partie 2    : {len(ow_p2)} pas")
    print(f"Underworld (Dungeon)  : {len(uw_steps)} pas")

    # -----------------------------------------------------------------------
    # Génération de src/music_data.inc
    # -----------------------------------------------------------------------
    lines = []
    lines.append("; ===========================================================================")
    lines.append("; music_data.inc - Partition authentique Overworld & Underworld pour Zelda C64")
    lines.append("; GENERE AUTOMATIQUEMENT par tools/generate_game_audio.py - NE PAS MODIFIER")
    lines.append("; ===========================================================================")
    lines.append("")
    lines.append(f"MUSIC_NOTE_COUNT = {len(sorted_freqs)}")
    lines.append(f"MUSIC_OW_P1_LEN  = {len(ow_p1)}")
    lines.append(f"MUSIC_OW_P2_LEN  = {len(ow_p2)}")
    lines.append(f"MUSIC_UW_LEN     = {len(uw_steps)}")
    lines.append("")

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

    def write_dataset(name, steps):
        durs = [s[0] for s in steps]
        v1s = [freq_to_idx[s[1]] for s in steps]
        v2s = [freq_to_idx[s[2]] for s in steps]
        v3s = [freq_to_idx[s[3]] for s in steps]

        lines.append(f"; --- {name} ({len(steps)} pas) ---")
        lines.append(f"{name}_dur:")
        for i in range(0, len(durs), 16):
            lines.append("        !byte " + ", ".join(f"{d:3d}" for d in durs[i:i+16]))
        lines.append(f"{name}_v1:")
        for i in range(0, len(v1s), 16):
            lines.append("        !byte " + ", ".join(f"${n:02x}" for n in v1s[i:i+16]))
        lines.append(f"{name}_v2:")
        for i in range(0, len(v2s), 16):
            lines.append("        !byte " + ", ".join(f"${n:02x}" for n in v2s[i:i+16]))
        lines.append(f"{name}_v3:")
        for i in range(0, len(v3s), 16):
            lines.append("        !byte " + ", ".join(f"${n:02x}" for n in v3s[i:i+16]))
        lines.append("")

    write_dataset("music_ow_p1", ow_p1)
    write_dataset("music_ow_p2", ow_p2)
    write_dataset("music_uw", uw_steps)

    with open(OUT_INC_PATH, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")

    print(f"OK : {OUT_INC_PATH} généré avec succès !")

if __name__ == "__main__":
    build_audio_data()
