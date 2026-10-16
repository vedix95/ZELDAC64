import sys
import math
sys.path.insert(0, 'tools')
from midi_event_scanner import parse_midi

def sid_freq(m):
    if not m or m == 0: return 0
    hz = 440.0 * (2.0 ** ((m - 69.0) / 12.0))
    return int(round(hz * 17.0284))

div, tracks = parse_midi('assets/zelda1.mid')

# Lead : Tr 6 (Track idx 5) puis Tr 3 (Track idx 2)
lead_events = []
for e in tracks[5]:
    if e[1] and e[0] < 1617: lead_events.append((e[0], e[2]))
for e in tracks[2]:
    if e[1] and e[0] >= 1617: lead_events.append((e[0], e[2]))
lead_events.sort()

# Basse / Arpeggios : Tr 4 (Track idx 3)
bass_events = []
for e in tracks[3]:
    if e[1]: bass_events.append((e[0], e[2]))
bass_events.sort()

# Percussion : Tr 2 (Track idx 1)
perc_events = set()
for e in tracks[1]:
    if e[1]: perc_events.add(e[0])

all_times = sorted(list(set([e[0] for e in lead_events] + [e[0] for e in bass_events] + list(perc_events))))

cur_lead = 0
cur_bass = 0
lead_dict = dict(lead_events)
bass_dict = dict(bass_events)

score = []
for i in range(len(all_times) - 1):
    t = all_times[i]
    t_next = all_times[i+1]
    
    lead_trig = 0
    bass_trig = 0
    
    if t in lead_dict:
        cur_lead = lead_dict[t]
        lead_trig = 1
    if t in bass_dict:
        cur_bass = bass_dict[t]
        bass_trig = 1
    has_perc = 1 if t in perc_events else 0
    
    delta_t = t_next - t
    frames = int(round(delta_t / 3.4))
    if frames < 2: frames = 2
    if frames > 45: frames = 45
    
    score.append({
        't': t,
        'dur': frames,
        'v1_freq': sid_freq(cur_lead),
        'v1_trig': lead_trig,
        'v2_freq': sid_freq(cur_bass),
        'v2_trig': bass_trig,
        'v3_perc': has_perc
    })

print(f"Generated {len(score)} authentic musical steps.")

p1_len = len(score) // 2
p2_len = len(score) - p1_len
p1 = score[:p1_len]
p2 = score[p1_len:]

loop_step = 0
for idx, s in enumerate(p1):
    if s['t'] >= 1617:
        loop_step = idx
        break

print(f"Part 1: {p1_len} steps, Part 2: {p2_len} steps, Loop Step: {loop_step}")

def write_part(f, prefix, part):
    # Durées
    f.write(f"{prefix}_dur:\n")
    for i in range(0, len(part), 16):
        chunk = part[i:i+16]
        f.write("        !byte " + ", ".join(f"{s['dur']:2d}" for s in chunk) + "\n")
    f.write("\n")
    
    # V1 Freq Lo
    f.write(f"{prefix}_v1_lo:\n")
    for i in range(0, len(part), 8):
        chunk = part[i:i+8]
        f.write("        !byte " + ", ".join(f"<${s['v1_freq']:04x}" for s in chunk) + "\n")
    f.write("\n")
    
    # V1 Freq Hi
    f.write(f"{prefix}_v1_hi:\n")
    for i in range(0, len(part), 8):
        chunk = part[i:i+8]
        f.write("        !byte " + ", ".join(f">${s['v1_freq']:04x}" for s in chunk) + "\n")
    f.write("\n")
    
    # V1 Triggers
    f.write(f"{prefix}_v1_trig:\n")
    for i in range(0, len(part), 16):
        chunk = part[i:i+16]
        f.write("        !byte " + ", ".join(f"{s['v1_trig']}" for s in chunk) + "\n")
    f.write("\n")
    
    # V2 Freq Lo
    f.write(f"{prefix}_v2_lo:\n")
    for i in range(0, len(part), 8):
        chunk = part[i:i+8]
        f.write("        !byte " + ", ".join(f"<${s['v2_freq']:04x}" for s in chunk) + "\n")
    f.write("\n")
    
    # V2 Freq Hi
    f.write(f"{prefix}_v2_hi:\n")
    for i in range(0, len(part), 8):
        chunk = part[i:i+8]
        f.write("        !byte " + ", ".join(f">${s['v2_freq']:04x}" for s in chunk) + "\n")
    f.write("\n")
    
    # V2 Triggers
    f.write(f"{prefix}_v2_trig:\n")
    for i in range(0, len(part), 16):
        chunk = part[i:i+16]
        f.write("        !byte " + ", ".join(f"{s['v2_trig']}" for s in chunk) + "\n")
    f.write("\n")
    
    # V3 Percussion
    f.write(f"{prefix}_v3_perc:\n")
    for i in range(0, len(part), 16):
        chunk = part[i:i+16]
        f.write("        !byte " + ", ".join(f"{s['v3_perc']}" for s in chunk) + "\n")
    f.write("\n")

with open('src/intro_music_data.asm', 'w') as f:
    f.write("; ===========================================================================\n")
    f.write("; intro_music_data.asm : Partition officielle de The Legend of Zelda (NES)\n")
    f.write("; Transcrite et extraite directement du MIDI officiel de Koji Kondo\n")
    f.write(f"; Longueur totale : {len(score)} pas événementiels (Partie 1: {p1_len}, Partie 2: {p2_len})\n")
    f.write("; ===========================================================================\n\n")
    f.write(f"music_p1_len = {p1_len}\n")
    f.write(f"music_p2_len = {p2_len}\n")
    f.write(f"music_loop_step = {loop_step}\n\n")
    
    f.write("; --- PARTIE 1 : FANFARE ET PREMIERE SECTION DU THEME ---\n")
    write_part(f, "music_p1", p1)
    
    f.write("; --- PARTIE 2 : SECONDE SECTION HEROIQUE, VARIATIONS ET FINALE ---\n")
    write_part(f, "music_p2", p2)

print("Generated src/intro_music_data.asm successfully!")
