import struct

def parse_midi(filename):
    with open(filename, 'rb') as f: data = f.read()
    division = struct.unpack('>H', data[12:14])[0]
    idx = 14
    tracks = []
    while idx < len(data):
        ctype = data[idx:idx+4]
        clen = struct.unpack('>I', data[idx+4:idx+8])[0]
        idx += 8
        cdata = data[idx:idx+clen]
        idx += clen
        if ctype == b'MTrk':
            p = 0; cur = 0; evs = []; rstat = 0
            while p < len(cdata):
                delta = 0
                while True:
                    b = cdata[p]; p += 1; delta = (delta << 7) | (b & 0x7f)
                    if not (b & 0x80): break
                cur += delta
                if p >= len(cdata): break
                stat = cdata[p]
                if stat & 0x80: p += 1; rstat = stat
                else: stat = rstat
                if stat == 0xff:
                    mtype = cdata[p]; p += 1; mlen = 0
                    while True:
                        b = cdata[p]; p += 1; mlen = (mlen << 7) | (b & 0x7f)
                        if not (b & 0x80): break
                    p += mlen
                elif (stat & 0xf0) in (0x80, 0x90):
                    n = cdata[p]; v = cdata[p+1]; p += 2
                    evs.append((cur, (stat & 0xf0) == 0x90 and v > 0, n, v))
                elif (stat & 0xf0) in (0xa0, 0xb0, 0xe0): p += 2
                elif (stat & 0xf0) in (0xc0, 0xd0): p += 1
                elif stat in (0xf0, 0xf7):
                    while cdata[p] != 0xf7: p += 1
                    p += 1
            tracks.append(evs)
    return division, tracks

div, tracks = parse_midi('assets/zelda_title_orig.mid')
print("Ticks per quarter note (division):", div)
# Dans zelda_title_orig.mid:
# Track 2: Lead intro fanfare (t=0..1920)
# Track 5: Arpeggios intro (t=0..1920)
# Track 13: Main Melody (t=9600..)
# Track 10: Percussions
# Track 15: Bassline
print("Scanning Track 2 notes:")
tr2_on = [e for e in tracks[1] if e[1]]
print("Tr 2 total notes:", len(tr2_on), "First 15:", tr2_on[:15])

print("Scanning Track 13 notes (Lead):")
tr13_on = [e for e in tracks[12] if e[1]]
print("Tr 13 total notes:", len(tr13_on), "First 15:", tr13_on[:15])

print("Scanning Track 15 notes (Bass):")
tr15_on = [e for e in tracks[14] if e[1]]
print("Tr 15 total notes:", len(tr15_on), "First 15:", tr15_on[:15])

