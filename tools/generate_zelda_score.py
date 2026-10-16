import sys
import math
sys.path.insert(0, 'tools')
from midi_event_scanner import parse_midi

def sid_freq(m):
    if not m or m == 0: return 0
    hz = 440.0 * (2.0 ** ((m - 69.0) / 12.0))
    return int(round(hz * 17.0284))

div, tracks = parse_midi('assets/zelda1.mid')

# Reconstruisons les événements séquentiels de façon propre et musicale.
# zelda1.mid :
# 1/16 note = 30 ticks (à 120 ticks/noire).
# Dans zelda1.mid, les deltas sont souvent des multiples de 25 ou 30 ticks.
# A 50 FPS C64, fixons 1 unité temporelle = 4 frames (80 ms) ou 5 frames (100 ms).
# A 120 BPM, une double croche = 125 ms (6.25 frames), une triple croche = 3 frames.
# Utilisons un séquenceur d'événements à durée variable : (duree_frames, v1_note, v2_note, v3_perc)

# Décodons directement les événements ordonnés :
# Pistes :
# Lead: Tr 6 (t < 1617), puis Tr 3 (t >= 1617)
lead_events = []
for e in tracks[5]: # Tr 6
    if e[1] and e[0] < 1617: lead_events.append((e[0], e[2]))
for e in tracks[2]: # Tr 3
    if e[1] and e[0] >= 1617 and e[0] < 8500: lead_events.append((e[0], e[2]))
lead_events.sort()

# Harmonie / Basse : Tr 4
bass_events = []
for e in tracks[3]: # Tr 4
    if e[1] and e[0] < 8500: bass_events.append((e[0], e[2]))
bass_events.sort()

# Percussion : Tr 2
perc_events = []
for e in tracks[1]: # Tr 2
    if e[1] and e[0] < 8500: perc_events.append(e[0])
perc_events = set(perc_events)

print(f"Lead notes: {len(lead_events)}, Bass notes: {len(bass_events)}, Perc events: {len(perc_events)}")

# Trouvons tous les timestamps uniques
all_times = sorted(list(set([e[0] for e in lead_events] + [e[0] for e in bass_events] + list(perc_events))))
print(f"Total unique time slices: {len(all_times)}")

# Construisons la timeline
# Conversion tick -> frames C64 :
# Dans zelda1.mid, t=1617 correspond à environ 10 secondes (Fanfare de 4 mesures à ~75-80 BPM).
# Ratio : 1617 ticks / 500 frames = ~3.2 ticks par frame.
# Donc dur_frames = round(delta_ticks / 3.2). Si delta == 0 -> 1 frame.
score = []
cur_lead = 0
cur_bass = 0

lead_dict = dict(lead_events)
bass_dict = dict(bass_events)

for i in range(len(all_times) - 1):
    t = all_times[i]
    t_next = all_times[i+1]
    if t in lead_dict: cur_lead = lead_dict[t]
    if t in bass_dict: cur_bass = bass_dict[t]
    has_perc = 1 if t in perc_events else 0
    
    delta_t = t_next - t
    # frames : au moins 2 frames
    frames = int(round(delta_t / 3.5))
    if frames < 2: frames = 2
    if frames > 40: frames = 40
    
    score.append((frames, cur_lead, cur_bass, has_perc))

print(f"Generated score with {len(score)} steps.")
print("Sample first 10 steps:")
for s in score[:10]:
    print(f"  dur={s[0]:2d} frames, v1={s[1]:2d} ({hex(sid_freq(s[1]))}), v2={s[2]:2d} ({hex(sid_freq(s[2]))}), perc={s[3]}")

