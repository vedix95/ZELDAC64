import struct
import math

def midi_note_to_sid_freq(midi_note):
    if midi_note is None or midi_note == 0:
        return 0
    # A4 = note 69 = 440 Hz
    # Freq(Hz) = 440.0 * 2^((note - 69) / 12)
    # Sur C64 PAL (clock = 985248 Hz) :
    # SID_FREQ = round(Freq(Hz) * 16777216 / 985248) = round(Freq(Hz) * 17.0284)
    freq_hz = 440.0 * math.pow(2.0, (midi_note - 69.0) / 12.0)
    sid_reg = int(round(freq_hz * 17.0284))
    return sid_reg

print("Bb4 (70):", hex(midi_note_to_sid_freq(70)))
print("F4  (65):", hex(midi_note_to_sid_freq(65)))
print("Ab4 (68):", hex(midi_note_to_sid_freq(68)))
print("Gb4 (66):", hex(midi_note_to_sid_freq(66)))
