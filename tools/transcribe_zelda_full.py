import math

def sid(m):
    if not m: return 0
    hz = 440.0 * (2.0 ** ((m - 69.0) / 12.0))
    return int(round(hz * 17.0284))

# Notes MIDI exactes
# Bb2=46, F2=41, C3=48, D3=50, Eb3=51, F3=53, Gb3=54, G3=55, Ab3=56, A3=57, Bb3=58
# C4=60, D4=62, Eb4=63, E4=64, F4=65, Gb4=66, G4=67, Ab4=68, A4=69, Bb4=70
# C5=72, D5=74, Eb5=75, E5=76, F5=77, Gb5=78, G5=79, Ab5=80, A5=81, Bb5=82

# =========================================================================
# 1. FANFARE D'INTRO DU TITLE SCREEN (4 mesures)
# =========================================================================
# Mesure 1 : Bb4 (tenue), puis triolet/croches F4, F4, Bb4, Ab4, Gb4, Ab4
# Mesure 2 : Bb4 (tenue), puis Gb4, Gb4, Bb4, A4, G4, A4
# Mesure 3 : Arpège descendant vers la marche...

# Vérifions les fréquences :
print("Bb4:", hex(sid(70))) # $1f02
print("F4: ", hex(sid(65))) # $173b
print("Ab4:", hex(sid(68))) # $1ba0
print("Gb4:", hex(sid(66))) # $189c
print("A4: ", hex(sid(69))) # $1d4a
print("G4: ", hex(sid(67))) # $1a15
print("C5: ", hex(sid(72))) # $22d0
print("D5: ", hex(sid(74))) # $271c
print("Eb5:", hex(sid(75))) # $2966
print("F5: ", hex(sid(77))) # $2e77
print("Bb5:", hex(sid(82))) # $3e04
