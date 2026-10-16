with open('assets/zelda1.mid', 'rb') as f: data = f.read()
import struct
# Trouver les meta event tempo (0xFF 0x51 0x03)
idx = 0
while idx < len(data) - 5:
    if data[idx:idx+3] == b'\xff\x51\x03':
        us = struct.unpack('>I', b'\x00' + data[idx+3:idx+6])[0]
        bpm = 60000000 / us
        print(f"Tempo found at offset {idx}: {us} us/quarter -> {bpm:.1f} BPM")
    idx += 1
