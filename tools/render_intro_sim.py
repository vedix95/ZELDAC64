from PIL import Image
import os

PALETTE = {
    0: (0, 0, 0),        # Noir
    1: (255, 255, 255),  # Blanc
    2: (136, 0, 0),      # Rouge
    3: (170, 255, 238),  # Cyan
    4: (204, 68, 204),   # Violet
    5: (0, 204, 85),     # Vert
    6: (0, 0, 170),      # Bleu
    7: (238, 238, 119),  # Jaune
    8: (221, 136, 85),   # Orange
    9: (102, 68, 0),     # Marron
    10: (255, 119, 119), # Rouge clair
    11: (51, 51, 51),    # Gris foncé
    12: (119, 119, 119), # Gris moyen
    13: (170, 255, 102), # Vert clair
    14: (0, 136, 255),   # Bleu clair
    15: (187, 187, 187)  # Gris clair
}

def load_charset():
    chars = {}
    with open('src/charset.asm', 'r') as f:
        lines = f.readlines()
    for line in lines:
        line = line.strip()
        if line.startswith('!byte ') and '; char ' in line:
            parts = line.split('; char ')
            char_id = int(parts[1].strip().split()[0])
            bytes_str = parts[0].replace('!byte ', '').split(',')
            byte_vals = []
            for b in bytes_str:
                b = b.strip()
                if b.startswith('%'): val = int(b[1:], 2)
                elif b.startswith('$'): val = int(b[1:], 16)
                else: val = int(b)
                byte_vals.append(val)
            chars[char_id] = byte_vals
    return chars

chars = load_charset()
print("Loaded chars:", len(chars))

screen = [32] * (40 * 25)
colors = [0] * (40 * 25)

def put_str(row, col, text, color):
    for i, c in enumerate(text):
        idx = row * 40 + col + i
        if 0 <= idx < 1000:
            screen[idx] = ord(c)
            colors[idx] = color

# Logo
put_str(1, 8, "THE  LEGEND  OF", 1) # Blanc
put_str(2, 13, "Z E L D A", 7)      # Jaune
screen[2*40 + 6] = 116; colors[2*40 + 6] = 7  # Triforce
screen[2*40 + 33] = 116; colors[2*40 + 33] = 7 # Triforce
for c in range(6, 34):
    screen[3*40 + c] = 115; colors[3*40 + c] = 7

# Falaises
cliff_left_width = [14, 15, 15, 16, 16, 17, 17, 17, 17, 17, 17, 17, 17, 17]
cliff_right_start = [26, 25, 25, 24, 24, 23, 23, 23, 23, 23, 23, 23, 23, 23]
for r_idx, r in enumerate(range(5, 19)):
    lw = cliff_left_width[r_idx]
    rs = cliff_right_start[r_idx]
    for c in range(0, lw):
        screen[r*40 + c] = 108
        colors[r*40 + c] = 12 # Gris
    screen[r*40 + lw - 1] = ord('T')
    colors[r*40 + lw - 1] = 5 # Vert
    
    screen[r*40 + rs] = ord('T')
    colors[r*40 + rs] = 5
    for c in range(rs + 1, 40):
        screen[r*40 + c] = 108
        colors[r*40 + c] = 12

# Cascade
for r in range(5, 19):
    for c in range(17, 23):
        screen[r*40 + c] = 124
        colors[r*40 + c] = 14 # Bleu clair

# Ecume
for c in range(16, 24):
    screen[19*40 + c] = 127
    colors[19*40 + c] = 1 # Blanc

# Lac
for c in range(8, 32):
    screen[19*40 + c] = 108; colors[19*40 + c] = 6 # Bleu
for c in range(6, 34):
    screen[20*40 + c] = 108; colors[20*40 + c] = 6

put_str(22, 10, "PRESS BUTTON TO PLAY", 7)
put_str(24, 13, "@ 1986 NINTENDO", 12)

img = Image.new('RGB', (320, 200), (0, 0, 0))
pixels = img.load()

for row in range(25):
    for col in range(40):
        ch = screen[row * 40 + col]
        fg_col = PALETTE.get(colors[row * 40 + col], (255, 255, 255))
        bg_col = (0, 0, 0)
        ch_bytes = chars.get(ch, [0]*8)
        for y in range(8):
            b = ch_bytes[y]
            for x in range(8):
                is_set = (b >> (7 - x)) & 1
                px_color = fg_col if is_set else bg_col
                pixels[col * 8 + x, row * 8 + y] = px_color

img_scaled = img.resize((640, 400), Image.NEAREST)
img_scaled.save('build/rendered_intro_preview.png')
print("Rendered preview saved to build/rendered_intro_preview.png")
