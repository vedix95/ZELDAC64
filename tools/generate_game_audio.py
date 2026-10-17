#!/usr/bin/env python3
"""
tools/generate_game_audio.py - Extrait et compile les partitions authentiques Overworld et Underworld
pour le moteur sonore C64 (Single SID + Dual SID).
Génère src/music_data.inc avec une table de notes unifiée, gestion du prolongement TIE ($FE)
et des pas compacts (4 octets/pas).
"""

import os
import struct
import sys

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
ROM_PATH = os.path.join(BASE_DIR, "zelda.nes")
MIDI_PATH = os.path.join(BASE_DIR, "assets", "zelda1.mid")
OUT_INC_PATH = os.path.join(BASE_DIR, "src", "music_data.inc")

def parse_midi(filename):
    with open(filename, "rb") as f:
        data = f.read()
    division = struct.unpack(">H", data[12:14])[0]
    idx = 14
    tracks = []
    while idx < len(data):
        ctype = data[idx:idx+4]
        clen = struct.unpack(">I", data[idx+4:idx+8])[0]
        idx += 8
        cdata = data[idx:idx+clen]
        idx += clen
        if ctype == b"MTrk":
            p = 0
            cur = 0
            evs = []
            rstat = 0
            while p < len(cdata):
                delta = 0
                while True:
                    b = cdata[p]
                    p += 1
                    delta = (delta << 7) | (b & 0x7f)
                    if not (b & 0x80):
                        break
                cur += delta
                if p >= len(cdata):
                    break
                stat = cdata[p]
                if stat & 0x80:
                    p += 1
                    rstat = stat
                else:
                    stat = rstat
                if stat == 0xff:
                    mtype = cdata[p]
                    p += 1
                    mlen = 0
                    while True:
                        b = cdata[p]
                        p += 1
                        mlen = (mlen << 7) | (b & 0x7f)
                        if not (b & 0x80):
                            break
                    p += mlen
                elif (stat & 0xf0) in (0x80, 0x90):
                    n = cdata[p]
                    v = cdata[p+1]
                    p += 2
                    evs.append((cur, (stat & 0xf0) == 0x90 and v > 0, n, v))
                elif (stat & 0xf0) in (0xa0, 0xb0, 0xe0):
                    p += 2
                elif (stat & 0xf0) in (0xc0, 0xd0):
                    p += 1
                elif stat in (0xf0, 0xf7):
                    while cdata[p] != 0xf7:
                        p += 1
                    p += 1
            tracks.append(evs)
    return division, tracks

def sid_freq(m):
    if not m or m == 0:
        return 0
    hz = 440.0 * (2.0 ** ((m - 69.0) / 12.0))
    return int(round(hz * 17.0284))

def load_overworld():
    if not os.path.exists(MIDI_PATH):
        sys.exit(f"Erreur : {MIDI_PATH} introuvable.")
    div, tracks = parse_midi(MIDI_PATH)

    # Thème principal authentique : débute à t = 2425 (Bb4 F4 Bb4 Bb4 C5 D5 Eb5 F5)
    # et boucle à t = 11975
    t_start = 2425
    t_end = 11975

    def get_spans(tr_events):
        spans = []
        cur_n = None
        cur_t = None
        for t, on, note, vel in tr_events:
            if t < t_start or t >= t_end:
                continue
            if on:
                if cur_n is not None:
                    spans.append((cur_t, t, cur_n))
                cur_n = note
                cur_t = t
            else:
                if cur_n == note:
                    spans.append((cur_t, t, cur_n))
                    cur_n = None
                    cur_t = None
        return spans

    lead_spans = get_spans(tracks[2]) # Track 3 = Lead Melody
    bass_spans = get_spans(tracks[4]) # Track 5 = Bassline
    perc_onsets = set(t for t, on, note, vel in tracks[1] if on and t_start <= t < t_end) # Track 2 = Percussion

    times = set()
    for s, e, n in lead_spans:
        times.add(s)
    for s, e, n in bass_spans:
        times.add(s)
    for p in perc_onsets:
        times.add(p)
    all_times = sorted(list(times))

    lead_onsets = {s: n for s, e, n in lead_spans}
    bass_onsets = {s: n for s, e, n in bass_spans}

    def get_active(spans, t):
        for s, e, n in spans:
            if s <= t < e:
                return n
        return 0

    ow_steps = []
    for i in range(len(all_times)):
        t = all_times[i]
        dt = all_times[i+1] - t if i+1 < len(all_times) else 50
        frames = int(round(dt * 0.2))
        if frames < 2:
            frames = 2

        if t in lead_onsets:
            v1 = sid_freq(lead_onsets[t])
        elif get_active(lead_spans, t) > 0:
            v1 = 0xFE # TIE / Prolongement
        else:
            v1 = 0

        if t in bass_onsets:
            v2 = sid_freq(bass_onsets[t])
        elif get_active(bass_spans, t) > 0:
            v2 = 0xFE # TIE / Prolongement
        else:
            v2 = 0

        p = 1 if t in perc_onsets else 0
        ow_steps.append((frames, v1, v2, p))

    split_idx = len(ow_steps) // 2
    ow_p1 = ow_steps[:split_idx]
    ow_p2 = ow_steps[split_idx:]
    return ow_p1, ow_p2

def load_underworld():
    if not os.path.exists(ROM_PATH):
        sys.exit(f"Erreur : {ROM_PATH} introuvable.")
    with open(ROM_PATH, "rb") as f:
        rom = f.read()[16:]
    b0 = rom[0:0x4000]

    dur_table = [3, 10, 1, 20, 5, 40, 60, 112]
    # Table des fréquences APU de Zelda 1 en Bank 0 à $9F00 (Offset $1F00)
    # Deux octets Big-Endian par note : High byte en 0x1F00+i, Low byte en 0x1F01+i
    freq_table = [(b0[0x1F00 + i*2] << 8) | b0[0x1F00 + i*2 + 1] for i in range(64)]

    def nes_note_to_sid(b):
        if b == 0 or b == 8:
            return 0
        idx = b >> 1
        period = freq_table[idx]
        if period > 0:
            hz = 1789773.0 / (16.0 * (period + 1))
            return int(round(hz * 17.0284))
        return 0

    def run_channel(off, max_len):
        evs = []
        p = 0
        loop_cnt = 0
        loop_start = 0
        cur_dur = 5
        t = 0
        steps = 0
        while p < max_len and steps < 5000:
            steps += 1
            b = b0[off + p]
            p += 1
            if b == 0:
                break
            elif b < 0x80:
                sid = nes_note_to_sid(b)
                evs.append((t, cur_dur, sid, b))
                t += cur_dur
            elif b == 0xF0:
                if loop_cnt > 1:
                    loop_cnt -= 1
                    p = loop_start
            elif b > 0xF0:
                loop_cnt = b - 0xF0
                loop_start = p
            elif 0x80 <= b < 0xF0:
                cur_dur = dur_table[b & 0x07]
        return evs

    c1 = run_channel(0x91FD - 0x8000, 0xA5)
    c2 = run_channel(0x91FD - 0x8000 + 0xA5, 0x53)
    c3 = run_channel(0x91FD - 0x8000 + 0xA5 + 0x53, 0xCD)

    tot1 = 1373 # 1 cycle complet du thème de donjon emblématique en Si mineur
    tot2 = sum(x[1] for x in c2)
    tot3 = sum(x[1] for x in c3)

    def expand_channel(evs, tot, target_tot):
        spans = []
        t_off = 0
        while t_off < target_tot:
            for t, dur, sid, b in evs:
                s = t_off + t
                e = s + dur
                if s >= target_tot:
                    break
                if e > target_tot:
                    e = target_tot
                spans.append((s, e, sid))
            t_off += tot
        return spans

    spans1 = [(t, t+dur, sid) for t, dur, sid, b in c1 if t < tot1]
    spans2 = expand_channel(c2, tot2, tot1)
    spans3 = expand_channel(c3, tot3, tot1)

    times_uw = set()
    for s, e, sid in spans1:
        times_uw.add(s)
    for s, e, sid in spans2:
        times_uw.add(s)
    for s, e, sid in spans3:
        times_uw.add(s)
    all_times_uw = sorted(list(times_uw))

    onsets1 = {s: sid for s, e, sid in spans1}
    onsets2 = {s: sid for s, e, sid in spans2}
    onsets3 = {s: sid for s, e, sid in spans3}

    def get_active_uw(spans, t):
        for s, e, sid in spans:
            if s <= t < e:
                return sid
        return 0

    uw_steps = []
    for i in range(len(all_times_uw)):
        t = all_times_uw[i]
        dt = all_times_uw[i+1] - t if i+1 < len(all_times_uw) else 20
        frames = int(round(dt * 50.0 / 60.0))
        if frames < 2:
            frames = 2

        if t in onsets1:
            v1 = onsets1[t]
        elif get_active_uw(spans1, t) > 0:
            v1 = 0xFE
        else:
            v1 = 0

        if t in onsets2:
            v2 = onsets2[t]
        elif get_active_uw(spans2, t) > 0:
            v2 = 0xFE
        else:
            v2 = 0

        if t in onsets3:
            v3 = onsets3[t]
        elif get_active_uw(spans3, t) > 0:
            v3 = 0xFE
        else:
            v3 = 0

        uw_steps.append((frames, v1, v2, v3))

    return uw_steps

def main():
    ow_p1, ow_p2 = load_overworld()
    uw_steps = load_underworld()

    # Collecte de toutes les fréquences non nulles et différentes de TIE ($FE)
    freqs = set()
    for _, f1, f2, _ in ow_p1 + ow_p2:
        if f1 not in (0, 0xFE): freqs.add(f1)
        if f2 not in (0, 0xFE): freqs.add(f2)
    for _, f1, f2, f3 in uw_steps:
        if f1 not in (0, 0xFE): freqs.add(f1)
        if f2 not in (0, 0xFE): freqs.add(f2)
        if f3 not in (0, 0xFE): freqs.add(f3)

    sorted_freqs = sorted(list(freqs))
    if len(sorted_freqs) > 120:
        sys.exit(f"Erreur : Trop de notes ({len(sorted_freqs)} > 120).")

    freq_to_idx = {f: idx + 1 for idx, f in enumerate(sorted_freqs)}
    freq_to_idx[0] = 0
    freq_to_idx[0xFE] = 0xFE

    print(f"Total notes uniques dans la table : {len(sorted_freqs)}")
    print(f"Overworld P1 : {len(ow_p1)} pas, P2 : {len(ow_p2)} pas")
    print(f"Underworld : {len(uw_steps)} pas")

    # Génération du fichier source ASM
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
            v3s = [freq_to_idx[s[3]] for s in steps]
        else:
            v3s = [0x80 if s[3] else 0 for s in steps]

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

    write_dataset("music_ow_p1", ow_p1, is_dungeon=False)
    write_dataset("music_ow_p2", ow_p2, is_dungeon=False)
    write_dataset("music_uw", uw_steps, is_dungeon=True)

    with open(OUT_INC_PATH, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")

    print(f"OK : {OUT_INC_PATH} généré avec succès !")

if __name__ == "__main__":
    main()
