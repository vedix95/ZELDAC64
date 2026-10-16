from tools.midi_event_scanner import parse_midi
div, tracks = parse_midi('assets/zelda_title_orig.mid')
for i in [1, 2, 3, 4, 7, 8, 9, 10, 11, 12, 13, 14]:
    evs = [e for e in tracks[i] if e[1] and 1920 <= e[0] < 9600]
    if evs:
        print(f"Tr {i+1}: {len(evs)} notes in [1920, 9600): ex={[(e[0], e[2]) for e in evs[:5]]}")
