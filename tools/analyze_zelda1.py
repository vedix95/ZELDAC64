import sys
sys.path.insert(0, 'tools')
from midi_event_scanner import parse_midi
div, tracks = parse_midi('assets/zelda1.mid')
print("zelda1.mid division:", div)
for i, tr in enumerate(tracks):
    on = [e for e in tr if e[1]]
    if on:
        print(f"Tr {i+1}: {len(on)} notes, range=[{min(e[0] for e in on)}, {max(e[0] for e in on)}], pitch=[{min(e[2] for e in on)}, {max(e[2] for e in on)}]")
        print(f"   First 10 notes: {[(e[0], e[2]) for e in on[:10]]}")
