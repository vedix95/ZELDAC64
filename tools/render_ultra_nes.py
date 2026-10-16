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
# COMPOSITION NES OFFICIELLE FIDÈLE
# =========================================================================

# 1. HAUTEUR DE LOGO (Lignes 1..4)
put_str(1, 13, "THE  LEGEND  OF", 1)

# "Z  E  L  D  A" équilibré
put_str(2, 11, "Z   E   L   D   A", 7)
put_str(3, 11, "=================", 7)

# Triforces
screen[2 * 40 + 6] = 116; colors[2 * 40 + 6] = 7
screen[2 * 40 + 33] = 116; colors[2 * 40 + 33] = 7

# 2. PROFIL DES FALAISES DE DEATH MOUNTAIN (Lignes 5..18)
# Au lieu d'un damier grossier, de vraies falaises étagées avec corniches et verdure
# Découpage :
# Lignes 5..7 : Haut des montagnes avec sapins
# Lignes 8..18 : Parois rocheuses verticales avec cascade au centre

# Profil de largeur gauche pour chaque ligne (5..18) :
left_widths =  [10, 11, 12, 13, 14, 15, 15, 16, 16, 16, 16, 17, 17, 17]
right_starts = [30, 29, 28, 27, 26, 25, 25, 24, 24, 24, 24, 23, 23, 23]

for idx, r in enumerate(range(5, 19)):
    lw = left_widths[idx]
    rs = right_starts[idx]
    
    # Falaise gauche
    for c in range(0, lw):
        # Corps de la falaise en pierre grise unie avec fissures subtiles
        screen[r * 40 + c] = 108
        colors[r * 40 + c] = 12 # Gris moyen uniforme et propre
    
    # Corniche avec sapin sur le bord
    screen[r * 40 + lw] = 130 # Biseau
    colors[r * 40 + lw] = 15 # Lumière
    
    # Falaise droite
    screen[r * 40 + rs - 1] = 131 # Biseau
    colors[r * 40 + rs - 1] = 11 # Ombre
    for c in range(rs, 40):
        screen[r * 40 + c] = 108
        colors[r * 40 + c] = 12

    # Bosquets de pins verts naturels sur les paliers
    if r in [5, 6]:
        screen[r * 40 + 3] = 132; colors[r * 40 + 3] = 5
        screen[r * 40 + 36] = 132; colors[r * 40 + 36] = 5
    if r in [8, 9]:
        screen[r * 40 + 6] = 132; colors[r * 40 + 6] = 5
        screen[r * 40 + 33] = 132; colors[r * 40 + 33] = 5
    if r in [12, 13]:
        screen[r * 40 + 8] = 132; colors[r * 40 + 8] = 5
        screen[r * 40 + 31] = 132; colors[r * 40 + 31] = 5

    # Cascade centrale (colonnes lw+1 .. rs-2)
    # Flux d'eau vive (lignes 5 à 18)
    for c in range(17, 23):
        screen[r * 40 + c] = 124
        # Nuance d'eau vive
        colors[r * 40 + c] = 1 if (c in [18, 21]) else 14

# Ligne 19 : Écume blanche au pied de la cascade
for c in range(16, 24):
    screen[19 * 40 + c] = 135
    colors[19 * 40 + c] = 1 # Blanc pur

# Lignes 19..20 : Lac bleu profond
for c in range(6, 16):
    screen[19 * 40 + c] = 108; colors[19 * 40 + c] = 6
for c in range(24, 34):
    screen[19 * 40 + c] = 108; colors[19 * 40 + c] = 6

for c in range(4, 36):
    screen[20 * 40 + c] = 108; colors[20 * 40 + c] = 6

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
img_scaled.save('build/ultra_nes_preview.png')
print("Saved build/ultra_nes_preview.png")
