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

# L1: "THE  LEGEND  OF"
put_str(1, 13, "THE  LEGEND  OF", 1)

# L2 & L3: Grand logo Z E L D A double hauteur (8x16)
# Z: 136, 137 | E: 138, 139 | L: 140, 141 | D: 142, 143 | A: 144, 145
logo_top = [136, 32, 138, 32, 140, 32, 142, 32, 144]
logo_bot = [137, 32, 139, 32, 141, 32, 143, 32, 145]

start_col = 15
for i, ch in enumerate(logo_top):
    screen[2 * 40 + start_col + i] = ch
    colors[2 * 40 + start_col + i] = 7 # Jaune or
for i, ch in enumerate(logo_bot):
    screen[3 * 40 + start_col + i] = ch
    colors[3 * 40 + start_col + i] = 7

# Grandes Triforces royales à gauche et droite
screen[2 * 40 + 8] = 146; colors[2 * 40 + 8] = 7
screen[2 * 40 + 9] = 147; colors[2 * 40 + 9] = 7
screen[3 * 40 + 8] = 116; colors[3 * 40 + 8] = 7
screen[3 * 40 + 9] = 116; colors[3 * 40 + 9] = 7

screen[2 * 40 + 30] = 146; colors[2 * 40 + 30] = 7
screen[2 * 40 + 31] = 147; colors[2 * 40 + 31] = 7
screen[3 * 40 + 30] = 116; colors[3 * 40 + 30] = 7
screen[3 * 40 + 31] = 116; colors[3 * 40 + 31] = 7

# Ligne séparatrice d'or
for c in range(6, 34):
    screen[4 * 40 + c] = 115
    colors[4 * 40 + c] = 7

# Falaises rocheuses avec relief et texture craquelée
# Lignes 5 à 18
for r in range(5, 19):
    # Côté gauche
    for c in range(0, 16):
        # Texture rocheuse
        screen[r * 40 + c] = 128 if ((r + c) % 2 == 0) else 108
        colors[r * 40 + c] = 11 if (c < 4) else 12 # Dégradé gris foncé -> gris
    # Bordure falaise gauche
    screen[r * 40 + 16] = 130 # Bord biseauté
    colors[r * 40 + 16] = 15 # Éclairage gris clair

    # Côté droit
    screen[r * 40 + 23] = 131 # Bord biseauté droit
    colors[r * 40 + 23] = 11 # Ombrage falaise
    for c in range(24, 40):
        screen[r * 40 + c] = 128 if ((r + c) % 2 == 0) else 108
        colors[r * 40 + c] = 12 if (c < 36) else 11

    # Arbres / pins verts sur les falaises
    if r in [5, 7, 9, 12, 15]:
        screen[r * 40 + 2] = 132; colors[r * 40 + 2] = 5
        screen[(r+1) * 40 + 2] = 133; colors[(r+1) * 40 + 2] = 5
        screen[r * 40 + 9] = 132; colors[r * 40 + 9] = 13
        screen[(r+1) * 40 + 9] = 133; colors[(r+1) * 40 + 9] = 5

        screen[r * 40 + 30] = 132; colors[r * 40 + 30] = 5
        screen[(r+1) * 40 + 30] = 133; colors[(r+1) * 40 + 30] = 5
        screen[r * 40 + 36] = 132; colors[r * 40 + 36] = 13
        screen[(r+1) * 40 + 36] = 133; colors[(r+1) * 40 + 36] = 5

    # Cascade centrale (colonnes 17..22)
    for c in range(17, 23):
        screen[r * 40 + c] = 124
        # Alternance de teintes d'eau
        colors[r * 40 + c] = 1 if (c in [18, 21]) else 14 # Bleu clair et reflets blancs

# Écume bouillonnante (Ligne 19)
for c in range(16, 24):
    screen[19 * 40 + c] = 135
    colors[19 * 40 + c] = 1 # Blanc pur

# Lac avec vagues (Lignes 19..20)
for c in range(4, 16):
    screen[19 * 40 + c] = 134; colors[19 * 40 + c] = 6 # Bleu
for c in range(24, 36):
    screen[19 * 40 + c] = 134; colors[19 * 40 + c] = 6

for c in range(2, 38):
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
img_scaled.save('build/enhanced_intro_preview.png')
print("Saved build/enhanced_intro_preview.png")
