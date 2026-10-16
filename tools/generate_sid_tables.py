import math

# Calculateur de fréquences C64 PAL
# Clock PAL = 985248 Hz
# F_SID = round(F_Hz * 16777216 / 985248) = round(F_Hz * 17.0284)
def midi_freq(midi_num):
    if midi_num is None or midi_num == 0:
        return 0
    hz = 440.0 * (2.0 ** ((midi_num - 69.0) / 12.0))
    return int(round(hz * 17.0284))

# Liste complète de la partition Zelda 1 fidèle :
# Structure :
# PHASE 1 : FANFARE D'OUVERTURE (4 mesures)
# - V1 (Lead Fanfare) : Bb4, F4, F4, Bb4, Ab4, Gb4, Ab4, Bb4...
# - V2 (Arpèges / contre-chant) : Arpèges montants Bb3, F3, etc.
# - V3 (Basse solennelle)
#
# PHASE 2 : LE GRAND THEME HEROIQUE (Thème principal complet de Zelda 1)
# - V1 (Lead Mélodie épique)
# - V2 (Basse de marche militaire et contre-chant)
# - V3 (Rythme caisse claire / noise et percussions)

