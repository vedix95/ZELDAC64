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
# RENDU DU PARCHEMIN D'HYRULE
# =========================================================================

# Ligne 1 : Haut du rouleau
screen[1 * 40 + 3] = 160; colors[1 * 40 + 3] = 7 # Coin HG
for c in range(4, 36):
    screen[1 * 40 + c] = 161; colors[1 * 40 + c] = 7
screen[1 * 40 + 36] = 162; colors[1 * 40 + 36] = 7 # Coin HD

# Titre du parchemin
put_str(2, 12, "HISTOIRE  D'HYRULE", 7)
put_str(3, 10, "====================", 7)

# Lignes 4 à 21 : Corps du parchemin avec bordures latérales
for r in range(4, 22):
    screen[r * 40 + 3] = 163; colors[r * 40 + 3] = 7 # Bord G
    screen[r * 40 + 36] = 164; colors[r * 40 + 36] = 7 # Bord D

# Bas du rouleau (Ligne 22)
screen[22 * 40 + 3] = 165; colors[22 * 40 + 3] = 7 # Coin BG
for c in range(4, 36):
    screen[22 * 40 + c] = 166; colors[22 * 40 + c] = 7
screen[22 * 40 + 36] = 167; colors[22 * 40 + 36] = 7 # Coin BD

# Texte en défilement à l'intérieur du parchemin (colonnes 5 à 34, lignes 5 à 20)
story_sample = [
    "IL Y A BIEN LONGTEMPS, DANS LE",
    "ROYAUME D'HYRULE...",
    "",
    "UNE LEGENDE SE TRANSMETTAIT",
    "DE GENERATION EN GENERATION.",
    "",
    "UN JOUR, LE PRINCE DES TENEBRES",
    "GANON ENVAHIT LE ROYAUME",
    "AVEC SON ARMEE DE MONSTRES,",
    "ET S'EMPARA DE LA TRIFORCE",
    "DE LA FORCE !",
    "",
    "CRAIGNANT SES DESSEINS DIABOLIQUES,",
    "LA PRINCESSE ZELDA BRISA",
    "LA TRIFORCE DE LA SAGESSE",
    "EN HUIT FRAGMENTS QU'ELLE CACHA"
]

for idx, line in enumerate(story_sample):
    put_str(5 + idx, 5, line, 1) # Blanc éclatant sur fond sombre

put_str(24, 10, "PRESS BUTTON TO PLAY", 7)

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
img_scaled.save('build/parchment_preview.png')
print("Saved build/parchment_preview.png")
