import sys
sys.path.insert(0, 'tools')
from midi_event_scanner import parse_midi
import math

# Charger zelda1.mid
div, tracks = parse_midi('assets/zelda1.mid')

# Dans zelda1.mid :
# Division = 120 ticks par noire.
# A tempo = 120-150 BPM, une double croche (16th note) = 30 ticks.
# Regardons la vitesse en ticks :
# Dans Tr 6 (Fanfare) :
# t=30 (Bb4), t=280 (dur=250 = ~2 noires), t=280(F4, dur=50), t=330(F4, dur=50), t=380(Bb4, dur=50), t=430(Ab4, dur=25), t=455(Gb4, dur=25), t=480(Ab4, dur=350)...
# Une unité de base (step) = 25 ou 30 ticks, ou disons 6 frames à 50Hz (environ 120ms).
