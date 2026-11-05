#!/usr/bin/env python3
"""
tools/generate_game_audio.py - Extrait et compile les partitions authentiques
Overworld, Underworld (Donjons 1..8) et Donjon 9 (Death Mountain) depuis zelda.nes
pour le moteur sonore C64 (Single SID + Dual SID).
Génère :
  - src/music_data_low.inc : Tables de fréquences et fanfares (logées sous $2000)
  - src/music_data.inc     : Partitions BGM résolues sous $A000 avec tampon bgm_track_buffer
  - build/cart_audio.bin   : Banque cartouche 31 (CART_BANK_AUDIO = 8 Ko) pour streaming
"""

import os
import sys
import json

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DATA_PATH = os.path.join(BASE_DIR, "assets", "music_data.json")
ROM_PATH = os.path.join(BASE_DIR, "zelda.nes")
OUT_INC_PATH = os.path.join(BASE_DIR, "src", "music_data.inc")
OUT_LOW_INC_PATH = os.path.join(BASE_DIR, "src", "music_data_low.inc")
OUT_CART_AUDIO_PATH = os.path.join(BASE_DIR, "build", "cart_audio.bin")

def load_audio_source():
    if os.path.exists(DATA_PATH):
        with open(DATA_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    if os.path.exists(ROM_PATH):
        print(f"[*] assets/music_data.json introuvable, extraction depuis {ROM_PATH}...")
        sys.path.insert(0, os.path.dirname(__file__))
        from extract_music import extract_music_data
        data = extract_music_data(ROM_PATH)
        with open(DATA_PATH, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)
        return data
    sys.exit(
        f"Erreur : Ni '{DATA_PATH}' ni '{ROM_PATH}' n'ont été trouvés.\n"
        f"Pour compiler l'audio, 'assets/music_data.json' doit être présent dans le dépôt Git."
    )

def build_audio_data():
    data = load_audio_source()

    # Table des périodes APU NES
    freq_table = data["freq_table"]

    # Tables de durée de notes
    note_len_table = data["note_len_table"]
    ow_durs = note_len_table[16 : 24] # NoteLengthTable2 ($10) pour Overworld
    uw_durs = note_len_table[0 : 8]   # NoteLengthTable0 ($00) pour Underworld

    ow_scripts = data["ow_scripts"]
    uw_scripts = data["uw_scripts"]
    ow_phrase_order = data.get("ow_phrase_order", ['P2', 'P3', 'P5', 'P2', 'P4', 'P5'])

    def nes_note_to_sid(b, is_trg=False):
        if b == 0 or b == 8:
            return 0
        idx = b >> 1
        if idx >= len(freq_table):
            return 0
        period = freq_table[idx]
        if period > 0:
            divisor = 32.0 if is_trg else 16.0
            hz = 1789773.0 / (divisor * (period + 1))
            return int(round(hz * 17.0284))
        return 0

    # -----------------------------------------------------------------------
    # 1. Décodage Overworld
    # -----------------------------------------------------------------------
    def decode_ow_channel(script_bytes, start_off, end_off, max_ticks, is_trg=False):
        p = start_off
        t = 0
        cur_dur = ow_durs[0]
        evs = []
        loop_cnt = 0
        loop_start = 0
        while p < end_off and t < max_ticks:
            b = script_bytes[p]
            p += 1
            if b == 0:
                break
            if b < 0x80:
                evs.append((t, cur_dur, nes_note_to_sid(b, is_trg)))
                t += cur_dur
            elif b == 0xF0:
                loop_cnt -= 1
                if loop_cnt > 0:
                    p = loop_start
            elif b > 0xF0:
                loop_cnt = b - 0xF0
                loop_start = p
            else:
                cur_dur = ow_durs[b & 0x07]
                if p >= end_off:
                    break
                b2 = script_bytes[p]
                p += 1
                if b2 == 0:
                    break
                evs.append((t, cur_dur, nes_note_to_sid(b2, is_trg)))
                t += cur_dur
        return evs

    ow_c1 = []
    ow_c2 = []
    ow_c3 = []
    cur_t = 0

    for phrase_name in ow_phrase_order:
        p_def = ow_scripts[phrase_name]
        p_script = p_def["bytes"]
        sq0_off = p_def["sq0_off"]
        trg_off = p_def["trg_off"]
        noise_off = p_def["noise_off"]

        p_len = 0
        p = 0
        c_dur = ow_durs[0]
        while p < sq0_off:
            b = p_script[p]
            p += 1
            if b == 0:
                break
            if b < 0x80:
                p_len += c_dur
            elif b == 0xF0 or b > 0xF0:
                pass
            else:
                c_dur = ow_durs[b & 0x07]
                if p < sq0_off:
                    p_len += c_dur
                    p += 1
                else:
                    break

        ev1 = decode_ow_channel(p_script, 0, sq0_off, p_len, is_trg=False)
        ev2 = decode_ow_channel(p_script, sq0_off, trg_off, p_len, is_trg=False)
        ev3 = decode_ow_channel(p_script, trg_off, noise_off, p_len, is_trg=True)

        for t, dur, sid in ev1: ow_c1.append((cur_t + t, dur, sid))
        for t, dur, sid in ev2: ow_c2.append((cur_t + t, dur, sid))
        for t, dur, sid in ev3: ow_c3.append((cur_t + t, dur, sid))
        cur_t += p_len

    # -----------------------------------------------------------------------
    # 2. Décodage Underworld & Fanfares
    # -----------------------------------------------------------------------
    def decode_nes_track(script_bytes, start, end, durs, is_trg=False):
        p = start
        t = 0
        cur_dur = durs[0]
        evs = []
        rep_cnt = 0
        rep_start = 0
        while p < end:
            b = script_bytes[p]
            p += 1
            if b == 0:
                break
            if b < 0x80:
                evs.append((t, cur_dur, nes_note_to_sid(b, is_trg)))
                t += cur_dur
            elif b == 0xF0:
                rep_cnt -= 1
                if rep_cnt > 0:
                    p = rep_start
            elif b > 0xF0:
                rep_cnt = b - 0xF0
                rep_start = p
            else:
                cur_dur = durs[b & 0x07]
                if p >= end:
                    break
                b2 = script_bytes[p]
                p += 1
                if b2 == 0:
                    break
                evs.append((t, cur_dur, nes_note_to_sid(b2, is_trg)))
                t += cur_dur
        return evs, t

    # Underworld Donjons 1..8
    uw_p1 = uw_scripts["P1"]
    uw_p1_bytes = uw_p1["bytes"]
    uw_p1_c1, _ = decode_nes_track(uw_p1_bytes, 0, uw_p1["sq0_off"], uw_durs, is_trg=False)
    uw_p1_c2, _ = decode_nes_track(uw_p1_bytes, uw_p1["sq0_off"], uw_p1["trg_off"], uw_durs, is_trg=False)
    uw_p1_c3, _ = decode_nes_track(uw_p1_bytes, uw_p1["trg_off"], uw_p1["end_off"], uw_durs, is_trg=True)

    uw_p2 = uw_scripts["P2"]
    uw_p2_bytes = uw_p2["bytes"]
    uw_p2_c1, _ = decode_nes_track(uw_p2_bytes, 0, uw_p2["sq0_off"], uw_durs, is_trg=False)
    uw_p2_c2, _ = decode_nes_track(uw_p2_bytes, uw_p2["sq0_off"], uw_p2["trg_off"], uw_durs, is_trg=False)
    uw_p2_c3, _ = decode_nes_track(uw_p2_bytes, uw_p2["trg_off"], uw_p2["end_off"], uw_durs, is_trg=True)

    uw_c1 = uw_p1_c1 + [(640 + t, d, s) for t, d, s in uw_p2_c1]
    uw_c2 = uw_p1_c2 + [(640 + t, d, s) for t, d, s in uw_p2_c2]
    uw_c3 = uw_p1_c3 + [(640 + t, d, s) for t, d, s in uw_p2_c3]
    uw_total_ticks = 1160

    # Fanfare Objet (SongScriptItemTaken0)
    it_sc = data["item_fanfare"]
    it_bytes = it_sc["bytes"]
    it_c1, it_t1 = decode_nes_track(it_bytes, 0, it_sc["sq0_off"], ow_durs, is_trg=False)
    it_c2, it_t2 = decode_nes_track(it_bytes, it_sc["sq0_off"], it_sc["trg_off"], ow_durs, is_trg=False)
    it_c3, it_t3 = decode_nes_track(it_bytes, it_sc["trg_off"], it_sc["end_off"], ow_durs, is_trg=True)
    it_total_ticks = max(it_t1, it_t2, it_t3)

    # Fanfare Triforce / Fin de Niveau (SongScriptEndLevel0)
    tr_sc = data["triforce_fanfare"]
    tr_bytes = tr_sc["bytes"]
    tr_c1, tr_t1 = decode_nes_track(tr_bytes, 0, tr_sc["sq0_off"], ow_durs, is_trg=False)
    tr_c2, tr_t2 = decode_nes_track(tr_bytes, tr_sc["sq0_off"], tr_sc["trg_off"], ow_durs, is_trg=False)
    tr_c3, tr_t3 = decode_nes_track(tr_bytes, tr_sc["trg_off"], tr_sc["end_off"], ow_durs, is_trg=True)
    tr_total_ticks = max(tr_t1, tr_t2, tr_t3)

    # Donjon 9 (SongScriptLastLevel0 à $91FD) - Authentique NES Table 2 ($10)
    d9_sc = data["dungeon_final"]
    d9_bytes = d9_sc["bytes"]
    d9_c1, d9_t1 = decode_nes_track(d9_bytes, 0, d9_sc["sq0_off"], ow_durs, is_trg=False)
    d9_c2, d9_t2 = decode_nes_track(d9_bytes, d9_sc["sq0_off"], d9_sc["trg_off"], ow_durs, is_trg=False)
    d9_c3_pat, d9_t3_pat = decode_nes_track(d9_bytes, d9_sc["trg_off"], d9_sc["end_off"], ow_durs, is_trg=True)
    d9_total_ticks = max(d9_t1, d9_t2, d9_t3_pat)

    # Basse Triangle du Donjon 9 (alignée exactement sur 1344 ticks)
    if d9_t3_pat < d9_total_ticks and d9_t3_pat > 0:
        d9_c3 = []
        loop_t = 0
        while loop_t < d9_total_ticks:
            for t, dur, sid in d9_c3_pat:
                if loop_t + t < d9_total_ticks:
                    d9_c3.append((loop_t + t, min(dur, d9_total_ticks - (loop_t + t)), sid))
            loop_t += d9_t3_pat
    else:
        d9_c3 = d9_c3_pat

    # -----------------------------------------------------------------------
    # 3. Compilation chronologique en pas discrets PAL (50 Hz)
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
    item_steps = compile_timeline(it_c1, it_c2, it_c3, it_total_ticks)
    triforce_steps = compile_timeline(tr_c1, tr_c2, tr_c3, tr_total_ticks)
    d9_steps = compile_timeline(d9_c1, d9_c2, d9_c3, d9_total_ticks)

    # -----------------------------------------------------------------------
    # 4. Indexation de toutes les fréquences SID uniques
    # -----------------------------------------------------------------------
    freqs = set()
    for _, f1, f2, f3 in ow_p1 + ow_p2 + uw_steps + item_steps + triforce_steps + d9_steps:
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
    print(f"Underworld (D1..D8)   : {len(uw_steps)} pas")
    print(f"Donjon 9 (Final)      : {len(d9_steps)} pas")
    print(f"Fanfare Objet         : {len(item_steps)} pas")
    print(f"Fanfare Triforce      : {len(triforce_steps)} pas")

    # -----------------------------------------------------------------------
    # 5. Génération de src/music_data_low.inc (Logé sous $2000)
    # -----------------------------------------------------------------------
    lo_lines = []
    lo_lines.append("; ===========================================================================")
    lo_lines.append("; music_data_low.inc - Tables de frequences SID et fanfares sous $2000")
    lo_lines.append("; GENERE AUTOMATIQUEMENT par tools/generate_game_audio.py - NE PAS MODIFIER")
    lo_lines.append("; ===========================================================================")
    lo_lines.append("")
    lo_lines.append(f"MUSIC_NOTE_COUNT    = {len(sorted_freqs)}")
    lo_lines.append(f"MUSIC_ITEM_LEN      = {len(item_steps)}")
    lo_lines.append(f"MUSIC_TRIFORCE_LEN  = {len(triforce_steps)}")
    lo_lines.append("")

    lo_bytes = [0] + [f & 0xFF for f in sorted_freqs]
    hi_bytes = [0] + [(f >> 8) & 0xFF for f in sorted_freqs]

    lo_lines.append("; Table des frequences SID (Index 0 = Silence)")
    lo_lines.append("music_note_freq_lo:")
    for i in range(0, len(lo_bytes), 16):
        lo_lines.append("        !byte " + ", ".join(f"${b:02x}" for b in lo_bytes[i:i+16]))
    lo_lines.append("music_note_freq_hi:")
    for i in range(0, len(hi_bytes), 16):
        lo_lines.append("        !byte " + ", ".join(f"${b:02x}" for b in hi_bytes[i:i+16]))
    lo_lines.append("")

    def append_track(target_lines, name, steps, include_dur=True):
        durs = [s[0] for s in steps]
        v1s = [freq_to_idx[s[1]] for s in steps]
        v2s = [freq_to_idx[s[2]] for s in steps]
        v3s = [freq_to_idx[s[3]] for s in steps]

        target_lines.append(f"; --- {name} ({len(steps)} pas) ---")
        if include_dur:
            target_lines.append(f"{name}_dur:")
            for i in range(0, len(durs), 16):
                target_lines.append("        !byte " + ", ".join(f"{d:3d}" for d in durs[i:i+16]))
        target_lines.append(f"{name}_v1:")
        for i in range(0, len(v1s), 16):
            target_lines.append("        !byte " + ", ".join(f"${n:02x}" for n in v1s[i:i+16]))
        target_lines.append(f"{name}_v2:")
        for i in range(0, len(v2s), 16):
            target_lines.append("        !byte " + ", ".join(f"${n:02x}" for n in v2s[i:i+16]))
        target_lines.append(f"{name}_v3:")
        for i in range(0, len(v3s), 16):
            target_lines.append("        !byte " + ", ".join(f"${n:02x}" for n in v3s[i:i+16]))
        target_lines.append("")

    append_track(lo_lines, "music_item_fanfare", item_steps, include_dur=True)
    append_track(lo_lines, "music_triforce", triforce_steps, include_dur=True)

    with open(OUT_LOW_INC_PATH, "w", encoding="utf-8") as f:
        f.write("\n".join(lo_lines) + "\n")
    print(f"OK : {OUT_LOW_INC_PATH} généré avec succès !")

    # -----------------------------------------------------------------------
    # 6. Génération de src/music_data.inc (BGM résidente sous $A000)
    # -----------------------------------------------------------------------
    lines = []
    lines.append("; ===========================================================================")
    lines.append("; music_data.inc - Partitions BGM Overworld, Underworld et Donjon 9")
    lines.append("; GENERE AUTOMATIQUEMENT par tools/generate_game_audio.py - NE PAS MODIFIER")
    lines.append("; ===========================================================================")
    lines.append("")
    lines.append(f"MUSIC_OW_P1_LEN     = {len(ow_p1)}")
    lines.append(f"MUSIC_OW_P2_LEN     = {len(ow_p2)}")
    lines.append(f"MUSIC_UW_LEN        = {len(uw_steps)}")
    lines.append(f"MUSIC_D9_LEN        = {len(d9_steps)}")
    lines.append("")
    lines.append("; bgm_track_buffer : Tampon dynamique partage sous $A000")
    lines.append("bgm_track_buffer:")
    append_track(lines, "music_ow_p1", ow_p1, include_dur=True)
    append_track(lines, "music_ow_p2", ow_p2, include_dur=True)
    append_track(lines, "music_uw", uw_steps, include_dur=False) # music_uw_dur remplace par constante 8
    lines.append("bgm_track_buffer_end:")
    lines.append("")
    lines.append("; Equates pour le Donjon 9 (recoit les 2 pages streamees depuis Banque 31)")
    lines.append("music_d9_dur        = bgm_track_buffer")
    lines.append("music_d9_v1         = music_d9_dur + MUSIC_D9_LEN")
    lines.append("music_d9_v2         = music_d9_v1 + MUSIC_D9_LEN")
    lines.append("music_d9_v3         = music_d9_v2 + MUSIC_D9_LEN")
    lines.append("")

    with open(OUT_INC_PATH, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print(f"OK : {OUT_INC_PATH} généré avec succès !")

    # -----------------------------------------------------------------------
    # 7. Génération du binaire de la Banque Cartouche 31 (CART_BANK_AUDIO = 8 Ko)
    # -----------------------------------------------------------------------
    # Offset $0000 (Page 0..5, 6 pages = 1536 o) : Standard BGM (OW P1 + P2 + UW D1..8 = 1364 o)
    # Offset $0800 (Page 8..9, 2 pages = 512 o)  : Donjon 9 BGM (124 * 4 = 496 o)
    cart_bank = bytearray(8192)

    # Standard BGM bytes
    std_bytes = []
    # ow_p1
    std_bytes.extend([s[0] for s in ow_p1])
    std_bytes.extend([freq_to_idx[s[1]] for s in ow_p1])
    std_bytes.extend([freq_to_idx[s[2]] for s in ow_p1])
    std_bytes.extend([freq_to_idx[s[3]] for s in ow_p1])
    # ow_p2
    std_bytes.extend([s[0] for s in ow_p2])
    std_bytes.extend([freq_to_idx[s[1]] for s in ow_p2])
    std_bytes.extend([freq_to_idx[s[2]] for s in ow_p2])
    std_bytes.extend([freq_to_idx[s[3]] for s in ow_p2])
    # uw (v1, v2, v3)
    std_bytes.extend([freq_to_idx[s[1]] for s in uw_steps])
    std_bytes.extend([freq_to_idx[s[2]] for s in uw_steps])
    std_bytes.extend([freq_to_idx[s[3]] for s in uw_steps])

    if len(std_bytes) > 0x0800:
        sys.exit(f"Erreur : Standard BGM trop volumineux ({len(std_bytes)} > 2048 o)")
    cart_bank[0 : len(std_bytes)] = bytes(std_bytes)

    # Dungeon 9 bytes (124 pas * 4 = 496 octets)
    d9_raw = []
    d9_raw.extend([s[0] for s in d9_steps])
    d9_raw.extend([freq_to_idx[s[1]] for s in d9_steps])
    d9_raw.extend([freq_to_idx[s[2]] for s in d9_steps])
    d9_raw.extend([freq_to_idx[s[3]] for s in d9_steps])

    if len(d9_raw) > 0x0800:
        sys.exit(f"Erreur : Donjon 9 BGM trop volumineux ({len(d9_raw)} > 2048 o)")
    cart_bank[0x0800 : 0x0800 + len(d9_raw)] = bytes(d9_raw)

    os.makedirs(os.path.dirname(OUT_CART_AUDIO_PATH), exist_ok=True)
    with open(OUT_CART_AUDIO_PATH, "wb") as f:
        f.write(cart_bank)
    print(f"OK : {OUT_CART_AUDIO_PATH} généré avec succès (8192 octets, Banque 31) !")

if __name__ == "__main__":
    build_audio_data()
