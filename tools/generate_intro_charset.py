# Generator for src/intro_charset.asm with authentic NES Zelda tiles
import re

with open('zelda.nes', 'rb') as f:
    rom = f.read()

b1 = rom[16 + 1*0x4000 : 16 + 2*0x4000]
common_bg = b1[0x877F-0x8000 : 0x877F-0x8000+0x700]
demo_bg = b1[0x96B4-0x8000 : 0x96B4-0x8000+0x900]
all_bg = common_bg + demo_bg

b6 = rom[16 + 6*0x4000 : 16 + 7*0x4000]
idx = 0xA869 - 0x8000
nt = [0x24] * 1024

while idx < len(b6):
    vram_hi = b6[idx]
    if vram_hi == 0xFF: break
    vram_lo = b6[idx+1]
    count_byte = b6[idx+2]
    idx += 3
    is_rle = (count_byte & 0x40) != 0
    count = count_byte & 0x3F
    addr = ((vram_hi << 8) | vram_lo) - 0x2000
    if is_rle:
        val = b6[idx]
        idx += 1
        for i in range(count):
            if 0 <= addr + i < 1024: nt[addr + i] = val
    else:
        for i in range(count):
            if 0 <= addr + i < 1024: nt[addr + i] = b6[idx + i]
        idx += count

# Collect unique shield tiles in rows 5..16, cols 5..26
shield_tiles = []
for r in range(5, 17):
    for c in range(5, 27):
        t = nt[r*32 + c]
        if t != 0x24:
            shield_tiles.append(t)

uniq_shield = sorted(set(shield_tiles))

def convert_tile_to_c64(t):
    bytes8 = []
    for py in range(8):
        p0 = all_bg[t * 16 + py]
        p1 = all_bg[t * 16 + 8 + py]
        b = 0
        for px in range(8):
            b0 = (p0 >> (7 - px)) & 1
            b1 = (p1 >> (7 - px)) & 1
            c = b0 | (b1 << 1)
            # Ribbon text
            if 0x70 <= t <= 0x73:
                is_fg = (c == 3)
            elif 0x74 <= t <= 0x7B:
                is_fg = (c == 2)
            elif 0x7C <= t <= 0xD3 or 0xE8 <= t <= 0xEC:
                is_fg = (c in (1, 2))
            else:
                is_fg = (c > 0)
            if is_fg:
                b |= (1 << (7 - px))
        bytes8.append(b)
    return bytes8

# Read existing charset.asm for base ASCII and items
with open('src/charset.asm') as f:
    charset_src = f.read()

char_defs = {}
for m in re.finditer(r'!byte\s+([^;\n]+);\s+char\s+(\d+)', charset_src):
    c_bytes = [int(x.strip().replace('%', ''), 2) for x in m.group(1).split(',')]
    c_idx = int(m.group(2))
    char_defs[c_idx] = c_bytes

# Construct 256 characters for intro_charset
intro_charset = {}
for i in range(256):
    intro_charset[i] = char_defs.get(i, [0]*8)

# Characters 128..130: Animated Waterfall Stream (Frame 0, 1, 2)
intro_charset[128] = [0b10010010, 0b01001001, 0b00100100, 0b10010010, 0b01001001, 0b00100100, 0b10010010, 0b01001001]
intro_charset[129] = [0b01001001, 0b00100100, 0b10010010, 0b01001001, 0b00100100, 0b10010010, 0b01001001, 0b00100100]
intro_charset[130] = [0b00100100, 0b10010010, 0b01001001, 0b00100100, 0b10010010, 0b01001001, 0b00100100, 0b10010010]

# Character 131: Waterfall Crest / Lip Foam
intro_charset[131] = [0b11111111, 0b01111110, 0b00111100, 0b10010010, 0b01001001, 0b00100100, 0b10010010, 0b01001001]

# Character 132: Water Splash / Foam at Lake Basin
intro_charset[132] = [0b01000010, 0b10100101, 0b01011010, 0b00100100, 0b11111111, 0b01111110, 0b00111100, 0b00011000]

# Character 133: Lake Wave Ripple
intro_charset[133] = [0b00000000, 0b01000100, 0b10101010, 0b00010001, 0b00000000, 0b00100010, 0b01010101, 0b10001000]

# Character 134: Cliff Rock Face (cracked stone)
intro_charset[134] = [0b10101010, 0b01010101, 0b10000010, 0b01000001, 0b10101010, 0b00010100, 0b00101000, 0b01010101]

# Character 135: Cliff Edge Left
intro_charset[135] = [0b00001111, 0b00011111, 0b00111111, 0b01111111, 0b01111111, 0b00111111, 0b00011111, 0b00001111]

# Character 136: Cliff Edge Right
intro_charset[136] = [0b11110000, 0b11111000, 0b11111100, 0b11111110, 0b11111110, 0b11111100, 0b11111000, 0b11110000]

# Character 137: Pine Tree Top
intro_charset[137] = [0b00011000, 0b00111100, 0b01111110, 0b00111100, 0b01111110, 0b11111111, 0b01111110, 0b11111111]

# Character 138: Star Dot Ornament (★ / ·)
intro_charset[138] = [0b00000000, 0b00011000, 0b00111100, 0b01111110, 0b01111110, 0b00111100, 0b00011000, 0b00000000]

# Character 139: Copyright symbol (©)
intro_charset[139] = [0b00111100, 0b01000010, 0b10011101, 0b10100001, 0b10100001, 0b10011101, 0b01000010, 0b00111100]

# Characters 140..248: THE 109 NES SHIELD TILES!
for i, t in enumerate(uniq_shield):
    intro_charset[140 + i] = convert_tile_to_c64(t)

# Write src/intro_charset.asm
with open('src/intro_charset.asm', 'w') as f:
    f.write('; ============================================================================\n')
    f.write('; intro_charset.asm : Jeu de caracteres dedie a l\'introduction de Zelda (1986)\n')
    f.write('; Contient les polices ASCII, icones de tresors, decors de falaise/cascade,\n')
    f.write('; et les 109 tuiles authentiques du grand blason NES The Legend of Zelda.\n')
    f.write('; ============================================================================\n\n')
    f.write('intro_charset:\n')
    for i in range(256):
        b_str = ', '.join(f'%{b:08b}' for b in intro_charset[i])
        f.write(f'        !byte {b_str}   ; char {i}\n')

print(f'Successfully wrote src/intro_charset.asm with 256 characters (including 109 NES shield tiles)!')
