from PIL import Image

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
screen = [32] * 1000
colors = [0] * 1000

def put_str(r, c, text, col):
    for i, ch in enumerate(text):
        idx = r * 40 + c + i
        if 0 <= idx < 1000:
            screen[idx] = ord(ch)
            colors[idx] = col

# =========================================================================
# L1: "THE  LEGEND  OF"
put_str(1, 13, "THE  LEGEND  OF", 1)

# L2 & L3: Grand logo Z E L D A 16x16 doré authentique
# Lettres : Z (136..139), E (140..143), L (144..147), D (148..151), A (152..155)
letters = [
    (136, 137, 138, 139), # Z
    (140, 141, 142, 143), # E
    (144, 145, 146, 147), # L
    (148, 149, 150, 151), # D
    (152, 153, 154, 155), # A
]

start_col = 13
for i, (tl, tr, bl, br) in enumerate(letters):
    col = start_col + i * 3
    screen[2 * 40 + col]     = tl; colors[2 * 40 + col]     = 7 # Or
    screen[2 * 40 + col + 1] = tr; colors[2 * 40 + col + 1] = 7
    screen[3 * 40 + col]     = bl; colors[3 * 40 + col]     = 7
    screen[3 * 40 + col + 1] = br; colors[3 * 40 + col + 1] = 7

# Grandes Triforces royales dorées (156..159)
screen[2 * 40 + 7] = 156; colors[2 * 40 + 7] = 7
screen[2 * 40 + 8] = 157; colors[2 * 40 + 8] = 7
screen[3 * 40 + 7] = 158; colors[3 * 40 + 7] = 7
screen[3 * 40 + 8] = 159; colors[3 * 40 + 8] = 7

screen[2 * 40 + 31] = 156; colors[2 * 40 + 31] = 7
screen[2 * 40 + 32] = 157; colors[2 * 40 + 32] = 7
screen[3 * 40 + 31] = 158; colors[3 * 40 + 31] = 7
screen[3 * 40 + 32] = 159; colors[3 * 40 + 32] = 7

# Ligne d'or sous le logo (L4)
for c in range(6, 34):
    screen[4 * 40 + c] = 115
    colors[4 * 40 + c] = 7

# Falaises étagées avec texture et relief (L5..L18)
left_widths =  [11, 12, 13, 14, 15, 15, 16, 16, 16, 16, 17, 17, 17, 17]
right_starts = [29, 28, 27, 26, 25, 25, 24, 24, 24, 24, 23, 23, 23, 23]

for idx, r in enumerate(range(5, 19)):
    lw = left_widths[idx]
    rs = right_starts[idx]
    
    # Falaise gauche
    for c in range(0, lw):
        screen[r * 40 + c] = 128
        colors[r * 40 + c] = 12 # Gris pierre
    screen[r * 40 + lw] = 130 # Biseau éclairé
    colors[r * 40 + lw] = 15

    # Falaise droite
    screen[r * 40 + rs - 1] = 131 # Biseau ombré
    colors[r * 40 + rs - 1] = 11
    for c in range(rs, 40):
        screen[r * 40 + c] = 128
        colors[r * 40 + c] = 12

    # Bosquets de pins verts sur les corniches
    if r in [5, 6]:
        screen[r * 40 + 3] = 132; colors[r * 40 + 3] = 5
        screen[r * 40 + 36] = 132; colors[r * 40 + 36] = 5
    if r in [8, 9]:
        screen[r * 40 + 6] = 132; colors[r * 40 + 6] = 5
        screen[r * 40 + 33] = 132; colors[r * 40 + 33] = 5
    if r in [12, 13]:
        screen[r * 40 + 8] = 132; colors[r * 40 + 8] = 5
        screen[r * 40 + 31] = 132; colors[r * 40 + 31] = 5

    # Cascade vivante (colonnes 17..22)
    for c in range(17, 23):
        screen[r * 40 + c] = 124
        colors[r * 40 + c] = 1 if (c in [18, 21]) else 14

# L19: Écume bouillonnante
for c in range(16, 24):
    screen[19 * 40 + c] = 135
    colors[19 * 40 + c] = 1

# L19..L20: Eau du lac avec reflets
for c in range(6, 16):
    screen[19 * 40 + c] = 134; colors[19 * 40 + c] = 6
for c in range(24, 34):
    screen[19 * 40 + c] = 134; colors[19 * 40 + c] = 6

for c in range(4, 36):
    screen[20 * 40 + c] = 134 if (c % 2 == 0) else 108
    colors[20 * 40 + c] = 6

put_str(22, 10, "PRESS BUTTON TO PLAY", 7)
put_str(24, 13, "@ 1986 NINTENDO", 15)

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
img_scaled.save('build/masterpiece_intro_preview.png')
print("Saved build/masterpiece_intro_preview.png")
