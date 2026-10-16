import math

def sid(m):
    if not m: return 0
    hz = 440.0 * (2.0 ** ((m - 69.0) / 12.0))
    return int(round(hz * 17.0284))

# Construisons la séquence musicale exacte, pas à pas.
# Vitesse : 1 pas (step) = 6 frames C64 (120 ms, soit 125 BPM pour des doubles croches).
# Chaque pas définit :
# v1_note (mélodie)
# v2_note (contre-chant / harmonie / basse)
# v3_type (0=mute, 1=kick/caisse claire militaire, ou arpège/noise)

# Voyons les mesures de l'intro et du thème :
# Mesures 1-4 : FANFARE MAJESTUEUSE D'INTRO
# V1 (Trompette / Pulse 50%) :
# Bb4 (tenu 6 pas), F4 (2 pas), F4 (1 pas), Bb4 (2 pas), Ab4 (1 pas), Gb4 (1 pas), Ab4 (6 pas)...
