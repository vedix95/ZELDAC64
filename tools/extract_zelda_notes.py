import sys
sys.path.insert(0, 'tools')
from midi_event_scanner import parse_midi
import math

def midi_to_sid(note):
    if not note: return 0
    freq_hz = 440.0 * math.pow(2.0, (note - 69.0) / 12.0)
    return int(round(freq_hz * 17.0284))

# Analysons zelda1.mid
div, tracks = parse_midi('assets/zelda1.mid')

# Dans zelda1.mid:
# division = 120 ticks/quarter
# La fanfare (Tr 6):
# t=30 (Bb4), t=280 (F4), t=330 (F4), t=380 (Bb4), t=430 (Ab4), t=455 (Gb4), t=480 (Ab4)
# En steps de 25 ticks (~1/16 note de triolet ou 1/32 note):
# Voyons la cadence en ticks.
for i in [5, 2, 3]: # Tr 6, Tr 3, Tr 4
    print(f"--- TRACK {i+1} ---")
    evs = [e for e in tracks[i] if e[1]]
    for e in evs[:20]:
        print(f"t={e[0]:5d}, note={e[2]}")
