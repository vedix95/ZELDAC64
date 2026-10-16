import struct
import math

def parse_track(chunk_data):
    p = 0; cur_time = 0; events = []; running_status = 0
    while p < len(chunk_data):
        delta = 0
        while True:
            b = chunk_data[p]; p += 1; delta = (delta << 7) | (b & 0x7f)
            if not (b & 0x80): break
        cur_time += delta
        if p >= len(chunk_data): break
        status = chunk_data[p]
        if status & 0x80: p += 1; running_status = status
        else: status = running_status
        if status == 0xff:
            meta_type = chunk_data[p]; p += 1; meta_len = 0
            while True:
                b = chunk_data[p]; p += 1; meta_len = (meta_len << 7) | (b & 0x7f)
                if not (b & 0x80): break
            p += meta_len
        elif (status & 0xf0) in (0x80, 0x90):
            note = chunk_data[p]; vel = chunk_data[p+1]; p += 2
            is_on = (status & 0xf0) == 0x90 and vel > 0
            events.append((cur_time, is_on, note, vel))
        elif (status & 0xf0) in (0xa0, 0xb0, 0xe0): p += 2
        elif (status & 0xf0) in (0xc0, 0xd0): p += 1
        elif status in (0xf0, 0xf7):
            while chunk_data[p] != 0xf7: p += 1
            p += 1
    return events

with open('assets/zelda_title_orig.mid', 'rb') as f: data = f.read()
idx = 14; tracks = []
while idx < len(data):
    chunk_type = data[idx:idx+4]; chunk_len = struct.unpack('>I', data[idx+4:idx+8])[0]
    idx += 8; chunk_data = data[idx:idx+chunk_len]; idx += chunk_len
    if chunk_type == b'MTrk': tracks.append(parse_track(chunk_data))

# Trouvons les pistes exactes du thème complet :
# Intro (t=0..1920) : arpèges montants
# t=0 à 1920 :
for tr_id, tr in enumerate(tracks):
    notes = [e for e in tr if e[1] and e[0] < 3840]
    if notes:
        print(f"Tr {tr_id+1}: {len(notes)} notes avant 3840, ex: {[n[2] for n in notes[:8]]}")
