#!/usr/bin/env python3
"""
tools/export_assets_sheet.py - Générateur d'atlas graphique et planches de contact
pour Zelda C64 (MOS 6510 / VIC-II / Magic Desk CRT 512 KB).

Extrait et assemble en planches PNG haute fidélité avec légendes :
  1. Tuiles de l'Overworld (16 tuiles en 5 palettes régionales)
  2. Tuiles des Donjons Underworld (16 tuiles authentiques NES)
  3. Sprites du Héros Link (déplacements, attaques, armes secondaires)
  4. Bestiaire complet des Ennemis & Boss (Overworld & Donjons)
  5. Objets d'inventaire, reliques, trésors, PNJs et Triforce
  6. Décomposition séquentielle de TOUS les cycles d'animation

Sorties générées :
  - build/atlas_all_assets.png       : Planche maîtresse consolidée complète
  - build/sheet_tiles.png            : Planche dédiée Tuiles Monde & Donjons
  - build/sheet_sprites_link.png     : Planche dédiée Link & Armes
  - build/sheet_sprites_enemies.png  : Planche dédiée Monstres & Bosses
  - build/sheet_sprites_items.png    : Planche dédiée Objets, Reliques & PNJs
  - build/sheet_animations.png       : Planche dédiée Cycles d'Animation
"""

import argparse
import os
import sys
import time

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
TOOLS_DIR = os.path.join(BASE_DIR, "tools")
ASSETS_DIR = os.path.join(BASE_DIR, "assets")
BUILD_DIR = os.path.join(BASE_DIR, "build")

sys.path.insert(0, TOOLS_DIR)

from sprgen import parse, to_grid, write_png
from tilegen import (
    PALETTE, PIX, parse_tiles,
    ZONE_BG, ZONE_MC1, ZONE_MC2, ZONE_TILE_COLORS
)
from render_maps import FONT_5X7
from render_dungeon1_full import TILES_ART

# -----------------------------------------------------------------------------
# PALETTES ET COULEURS C64
# -----------------------------------------------------------------------------
C_BLACK      = PALETTE[0]
C_WHITE      = PALETTE[1]
C_RED        = PALETTE[2]
C_CYAN       = PALETTE[3]
C_PURPLE     = PALETTE[4]
C_GREEN      = PALETTE[5]
C_BLUE       = PALETTE[6]
C_YELLOW     = PALETTE[7]
C_ORANGE     = PALETTE[8]
C_BROWN      = PALETTE[9]
C_LIGHT_RED  = PALETTE[10]
C_DARK_GREY  = PALETTE[11]
C_GREY       = PALETTE[12]
C_LIGHT_GREEN= PALETTE[13]
C_LIGHT_BLUE = PALETTE[14]
C_LIGHT_GREY = PALETTE[15]

# Couleurs d'interface de la planche
UI_BG_DARK   = (12, 14, 20)        # Fond général nuit profonde
UI_CARD_BG   = (18, 22, 32)        # Fond des cellules
UI_CARD_BORD = (34, 42, 58)        # Bordure subtile des cellules
UI_BOX_BG1   = (15, 18, 26)        # Fond damier 1
UI_BOX_BG2   = (22, 27, 38)        # Fond damier 2
UI_TITLE_GOLD= (255, 208, 64)      # Titre or Triforce
UI_ACCENT    = (240, 180, 40)      # Ligne d'accent or
UI_SUBTITLE  = (112, 164, 178)     # Sous-titre cyan VIC-II
UI_TEXT_PRI  = (240, 244, 250)     # Texte principal blanc doux
UI_TEXT_SEC  = (135, 150, 170)     # Métadonnées gris ardoise
UI_BADGE_BG  = (28, 36, 52)        # Badge fond neutre
UI_BADGE_TXT = (210, 230, 255)     # Badge texte neutre
UI_ARROW     = (255, 185, 45)      # Flèche de transition jaune-or

# -----------------------------------------------------------------------------
# MOTEUR DE DESSIN BITMAP PUR (SANS DÉPENDANCES EXTERNES)
# -----------------------------------------------------------------------------
def make_canvas(w, h, bg=UI_BG_DARK):
    return [[bg] * w for _ in range(h)]

def draw_rect(canvas, x, y, w, h, fill=None, border=None):
    H = len(canvas)
    W = len(canvas[0])
    x0, y0 = max(0, x), max(0, y)
    x1, y1 = min(W, x + w), min(H, y + h)
    if fill:
        for cy in range(y0, y1):
            for cx in range(x0, x1):
                canvas[cy][cx] = fill
    if border:
        for cx in range(x0, x1):
            if 0 <= y < H: canvas[y][cx] = border
            if 0 <= y + h - 1 < H: canvas[y + h - 1][cx] = border
        for cy in range(y0, y1):
            if 0 <= x < W: canvas[cy][x] = border
            if 0 <= x + w - 1 < W: canvas[cy][x + w - 1] = border

def draw_checkered_box(canvas, x, y, w, h, col1=UI_BOX_BG1, col2=UI_BOX_BG2, step=4):
    H, W = len(canvas), len(canvas[0])
    for cy in range(max(0, y), min(H, y + h)):
        for cx in range(max(0, x), min(W, x + w)):
            checker = (((cx - x) // step) + ((cy - y) // step)) % 2
            canvas[cy][cx] = col2 if checker else col1

def draw_char(canvas, ch, x0, y0, scale=1, fg=UI_TEXT_PRI):
    glyph = FONT_5X7.get(ch, FONT_5X7.get('?'))
    H, W = len(canvas), len(canvas[0])
    for r_idx, row_bits in enumerate(glyph):
        for c_idx in range(5):
            if row_bits & (1 << (4 - c_idx)):
                px = x0 + c_idx * scale
                py = y0 + r_idx * scale
                for sy in range(scale):
                    for sx in range(scale):
                        iy = py + sy
                        ix = px + sx
                        if 0 <= iy < H and 0 <= ix < W:
                            canvas[iy][ix] = fg

def draw_text(canvas, text, x0, y0, scale=1, fg=UI_TEXT_PRI):
    cur_x = x0
    char_w = 6 * scale
    for ch in text:
        draw_char(canvas, ch, cur_x, y0, scale=scale, fg=fg)
        cur_x += char_w
    return cur_x

def draw_centered_text(canvas, text, center_x, y0, scale=1, fg=UI_TEXT_PRI):
    total_w = len(text) * 6 * scale - scale
    x0 = center_x - total_w // 2
    draw_text(canvas, text, x0, y0, scale=scale, fg=fg)
    return x0

def draw_badge(canvas, text, x, y, fg=UI_BADGE_TXT, bg=UI_BADGE_BG, border=None, scale=1):
    pad_x, pad_y = 3, 2
    txt_w = len(text) * 6 * scale - scale
    txt_h = 7 * scale
    w = txt_w + pad_x * 2
    h = txt_h + pad_y * 2
    draw_rect(canvas, x, y, w, h, fill=bg, border=border or bg)
    draw_text(canvas, text, x + pad_x, y + pad_y, scale=scale, fg=fg)
    return w, h

def draw_arrow(canvas, x, y, length=12, color=UI_ARROW):
    H, W = len(canvas), len(canvas[0])
    cy = y
    for dx in range(length):
        if 0 <= cy < H and 0 <= x + dx < W:
            canvas[cy][x + dx] = color
            if 0 <= cy - 1 < H: canvas[cy - 1][x + dx] = color
    # Tête de flèche
    tip_x = x + length
    for step in range(4):
        for dy in range(-step, step + 1):
            iy = cy + dy
            ix = tip_x - (3 - step)
            if 0 <= iy < H and 0 <= ix < W:
                canvas[iy][ix] = color

# -----------------------------------------------------------------------------
# RENDU DES TUILES ET SPRITES
# -----------------------------------------------------------------------------
def render_tile_pixels(rows, palette_map, scale=2):
    """
    Rend une tuile 16x16 (8 colonnes multicolores x 16 scanlines)
    En scale=2 : 8*4=32 px de large, 16*2=32 px de haut (ratio 1:1 parfait)
    """
    out = []
    for row in rows:
        wide_row = []
        for ch in row:
            col_val = palette_map.get(ch, C_BLACK)
            # Chaque pixel multicolore fait 4 pixels de large (2 screen dots x scale=2)
            for _ in range(4):
                wide_row.append(col_val)
        # Répété scale=2 fois verticalement
        for _ in range(scale):
            out.append(list(wide_row))
    return out

def render_sprite_pixels(grid, palette_map, scale=2, trans_bg=None):
    """
    Rend un sprite 12 cols x 21 lignes.
    En scale=2 : 12*4=48 px de large, 21*2=42 px de haut (ratio C64 24x21 fidèle)
    """
    out = []
    for row in grid:
        wide_row = []
        for val in row:
            if val == 0 and trans_bg is not None:
                color = trans_bg
            else:
                color = palette_map.get(val, C_BLACK)
            for _ in range(4):
                wide_row.append(color)
        for _ in range(scale):
            out.append(list(wide_row))
    return out

def blit(canvas, x0, y0, pixels):
    H, W = len(canvas), len(canvas[0])
    for py, row in enumerate(pixels):
        cy = y0 + py
        if 0 <= cy < H:
            for px, color in enumerate(row):
                cx = x0 + px
                if 0 <= cx < W and color is not None:
                    canvas[cy][cx] = color

# -----------------------------------------------------------------------------
# EXTRACTION DES DONNÉES DU JEU
# -----------------------------------------------------------------------------
def load_all_assets():
    # 1. Tuiles Overworld
    cfg, tiles = parse_tiles(os.path.join(ASSETS_DIR, "tiles.txt"))
    # 2. Sprites Link
    link_order, link_frames = parse(os.path.join(ASSETS_DIR, "link.txt"))
    # 3. Sprites Monstres
    en_order, en_frames = parse(os.path.join(ASSETS_DIR, "enemies.txt"))
    # 4. Sprites Items/Extra
    extra_order, extra_frames = parse(os.path.join(ASSETS_DIR, "extra.txt"))

    return {
        'tiles_cfg': cfg,
        'tiles': tiles,
        'link_order': link_order,
        'link_frames': link_frames,
        'en_order': en_order,
        'en_frames': en_frames,
        'extra_order': extra_order,
        'extra_frames': extra_frames,
    }

def get_sprite_palette(source, name, variant="default"):
    """
    Retourne la palette C64 4-couleurs {0: fond, 1: MC1, 2: Propre, 3: MC2}
    fidèle au rendu VIC-II officiel du jeu.
    """
    # 1. LINK
    if source == 'link':
        if "sword" in name:
            return {0: None, 1: (0xB8, 0x69, 0x62), 2: C_WHITE, 3: C_BROWN}
        elif variant == "blue":
            return {0: None, 1: (0xB8, 0x69, 0x62), 2: C_CYAN, 3: C_BROWN}
        elif variant == "red":
            return {0: None, 1: (0xB8, 0x69, 0x62), 2: C_RED, 3: C_BROWN}
        else:
            return {0: None, 1: (0xB8, 0x69, 0x62), 2: C_GREEN, 3: C_BROWN}

    # 2. EXTRA / ITEMS / NPCS
    elif source == 'extra':
        if name in ('old_man', 'merchant', 'old_woman'):
            col = C_RED if name == 'old_man' else (C_BLUE if name == 'merchant' else C_PURPLE)
            return {0: None, 1: (0xB8, 0x69, 0x62), 2: col, 3: C_WHITE}
        elif 'triforce' in name or name.startswith('tri_p'):
            return {0: None, 1: (0xB8, 0x69, 0x62), 2: C_YELLOW, 3: C_ORANGE}
        elif 'heart' in name:
            return {0: None, 1: C_WHITE, 2: C_RED, 3: C_BROWN}
        elif 'key' in name:
            return {0: None, 1: (0xB8, 0x69, 0x62), 2: C_YELLOW, 3: C_BROWN}
        elif 'ring' in name:
            return {0: None, 1: C_WHITE, 2: C_CYAN if variant == 'blue' else C_RED, 3: C_BROWN}
        elif 'potion' in name:
            return {0: None, 1: C_WHITE, 2: C_LIGHT_BLUE if variant == 'blue' else C_RED, 3: C_BROWN}
        elif 'stepladder' in name or 'raft' in name:
            return {0: None, 1: (0xB8, 0x69, 0x62), 2: C_BROWN, 3: C_DARK_GREY}
        elif 'shield' in name:
            return {0: None, 1: C_WHITE, 2: C_BROWN, 3: C_DARK_GREY}
        else:
            return {0: None, 1: (0xB8, 0x69, 0x62), 2: C_YELLOW, 3: C_BROWN}

    # 3. MONSTRES & BOSSES
    else:
        # Base MC1 et MC2 pour les ennemis
        mc1 = (0xB8, 0x69, 0x62)
        mc2 = C_BROWN

        # Cas particuliers d'ennemis blancs, verts, violets, etc.
        if any(k in name for k in ('stalfos', 'keese', 'bubble', 'polsvoice')):
            ind_col = C_WHITE
        elif any(k in name for k in ('aquamentus', 'zora', 'manhandla', 'gleeok')):
            ind_col = C_GREEN
        elif 'ganon' in name or 'patra' in name:
            ind_col = C_PURPLE
        elif any(k in name for k in ('dodongo', 'armos', 'gibdo')):
            ind_col = C_BROWN
        elif any(k in name for k in ('trap', 'death', 'zol')):
            ind_col = C_GREY
        elif any(k in name for k in ('peahat', 'digdogger')):
            ind_col = C_ORANGE
        elif variant == 'blue' or 'blue' in name:
            ind_col = C_LIGHT_BLUE
        else:
            ind_col = C_RED

        return {0: None, 1: mc1, 2: ind_col, 3: mc2}

# -----------------------------------------------------------------------------
# RENDU DE LA SECTION 1 : TUILES OVERWORLD
# -----------------------------------------------------------------------------
def draw_section_header(canvas, y0, title, subtitle):
    W = len(canvas[0])
    draw_rect(canvas, 30, y0, W - 60, 48, fill=(18, 24, 34), border=(45, 58, 80))
    draw_rect(canvas, 30, y0, 6, 48, fill=UI_ACCENT)
    draw_text(canvas, title, 50, y0 + 10, scale=2, fg=UI_TITLE_GOLD)
    draw_text(canvas, subtitle, 50, y0 + 30, scale=1, fg=UI_SUBTITLE)
    return y0 + 58

def render_sheet_tiles(assets, canvas=None, start_y=30):
    tiles = assets['tiles']
    tiles_cfg = assets['tiles_cfg']
    W = 1920
    # 16 tuiles. Espacement : cartes de 108 px
    card_w = 108
    card_h = 100
    margin_x = 42
    gap_x = 8

    # Si canvas non fourni (planche individuelle), le créer
    total_h = start_y + 60 + 5 * (card_h + 30) + 40
    if canvas is None:
        canvas = make_canvas(W, total_h)

    y = start_y
    y = draw_section_header(
        canvas, y,
        "SECTION 1 : TUILES DU MONDE OVERWORLD (16 TUILES & PALETTES REGIONALES)",
        "Structure 16x16 pixels multicolore C64 (4 caracteres VIC-II). "
        "Chaque tuile est presentee dans les 4 zones geographiques d'Hyrule."
    )

    zones_info = [
        ("ZONE 2 : PLAINES & FORETS D'HYRULE (PALETTE STANDARD OVERWORLD)", 2),
        ("ZONE 1 : MONTAGNE DE LA MORT / DEATH MOUNTAIN (ROCHES VOLCANIQUES)", 1),
        ("ZONE 3 : COTES, RIVIERES ET LACS (EAU VIVE & EMBRUNS)", 3),
        ("ZONE 0 : CIMETIERE DES HEROS (TERRE SOMBRE & TOMBES BLANCHES)", 0),
    ]

    for zone_title, zone_idx in zones_info:
        draw_text(canvas, zone_title, margin_x, y, scale=1, fg=UI_TITLE_GOLD)
        y += 14

        bg_col = PALETTE[ZONE_BG[zone_idx]]
        mc1_col = PALETTE[ZONE_MC1[zone_idx]]
        mc2_col = PALETTE[ZONE_MC2[zone_idx]]

        for i, tile in enumerate(tiles):
            cx = margin_x + i * (card_w + gap_x)
            draw_rect(canvas, cx, y, card_w, card_h, fill=UI_CARD_BG, border=UI_CARD_BORD)

            # Palette de la tuile
            ram_col = PALETTE[ZONE_TILE_COLORS[zone_idx][i]]
            pal_map = {'.': bg_col, '1': mc1_col, '2': mc2_col, 'c': ram_col}

            # Zone d'affichage tuile 32x32 au centre
            bx = cx + (card_w - 32) // 2
            by = y + 8
            draw_checkered_box(canvas, bx - 2, by - 2, 36, 36)
            draw_rect(canvas, bx - 2, by - 2, 36, 36, border=(50, 60, 80))
            tile_pix = render_tile_pixels(tile['rows'], pal_map, scale=2)
            blit(canvas, bx, by, tile_pix)

            # Légendes
            draw_centered_text(canvas, tile['name'][:14], cx + card_w // 2, y + 48, scale=1, fg=UI_TEXT_PRI)
            idx_str = f"#{i:02d} [{tile['symbol']}]"
            draw_centered_text(canvas, idx_str, cx + card_w // 2, y + 60, scale=1, fg=UI_TEXT_SEC)

            # Badge solide / traversable
            solid = tile['solid']
            badge_txt = "SOLID" if solid else ("WATER" if i == 4 else "PASS")
            badge_bg = (60, 20, 20) if solid else ((20, 40, 60) if i == 4 else (20, 50, 25))
            badge_fg = (255, 100, 100) if solid else ((100, 200, 255) if i == 4 else (100, 240, 120))
            draw_badge(canvas, badge_txt, cx + (card_w - len(badge_txt)*6) // 2 - 2, y + 74, fg=badge_fg, bg=badge_bg)

        y += card_h + 16

    return canvas, y

# -----------------------------------------------------------------------------
# RENDU DE LA SECTION 2 : TUILES DE DONJON (UNDERWORLD)
# -----------------------------------------------------------------------------
def render_sheet_dungeon_tiles(assets, canvas=None, start_y=30):
    W = 1920
    card_w = 108
    card_h = 104
    margin_x = 42
    gap_x = 8

    total_h = start_y + 60 + card_h + 60
    if canvas is None:
        canvas = make_canvas(W, total_h)

    y = start_y
    y = draw_section_header(
        canvas, y,
        "SECTION 2 : TUILES DE DONJON AUTHENTIQUES NES (UNDERWORLD LEVEL 1 A 9)",
        "Dalles de sol, murs bevelles, biseaux 45 deg, blocs 3D, statues dragons, "
        "escaliers et 4 types de portes (ouverte, verrouillee, volets, bombee)."
    )

    dung_pal = {
        '.': C_BLACK,        # Sol donjon noir profond
        '1': C_CYAN,         # MC1 Cyan donjon Level 1
        '2': C_LIGHT_BLUE,   # MC2 Bleu clair reflets
        'c': C_BLUE,         # Color RAM Bleu contours
    }

    dung_names = [
        ("sol", "Dalle Sol", False),
        ("mur_haut", "Mur Nord", True),
        ("mur_bas", "Mur Sud", True),
        ("mur_gauche", "Mur Ouest", True),
        ("mur_droit", "Mur Est", True),
        ("diamant", "Bloc 3D", True),
        ("dragon", "Statue Drg", True),
        ("escalier", "Escalier", False),
        ("bis_hg", "Biseau HG", True),
        ("bis_hd", "Biseau HD", True),
        ("bis_bg", "Biseau BG", True),
        ("bis_bd", "Biseau BD", True),
        ("porte_ouv", "Porte Ouv.", False),
        ("porte_ver", "Serrure", True),
        ("porte_vol", "Grille", True),
        ("porte_bom", "Fissure", True),
    ]

    for i in range(16):
        cx = margin_x + i * (card_w + gap_x)
        draw_rect(canvas, cx, y, card_w, card_h, fill=UI_CARD_BG, border=UI_CARD_BORD)

        # Rendu tuile 32x32
        bx = cx + (card_w - 32) // 2
        by = y + 8
        draw_checkered_box(canvas, bx - 2, by - 2, 36, 36)
        draw_rect(canvas, bx - 2, by - 2, 36, 36, border=(50, 60, 80))

        tile_data = TILES_ART.get(i, ["........"] * 16)
        tile_pix = render_tile_pixels(tile_data, dung_pal, scale=2)
        blit(canvas, bx, by, tile_pix)

        slug, label, is_solid = dung_names[i]
        draw_centered_text(canvas, label, cx + card_w // 2, y + 48, scale=1, fg=UI_TEXT_PRI)
        draw_centered_text(canvas, f"DUNG #{i:02d}", cx + card_w // 2, y + 60, scale=1, fg=UI_TEXT_SEC)

        badge_txt = "SOLID" if is_solid else "PASS"
        badge_bg = (60, 20, 20) if is_solid else (20, 50, 25)
        badge_fg = (255, 100, 100) if is_solid else (100, 240, 120)
        draw_badge(canvas, badge_txt, cx + (card_w - len(badge_txt)*6) // 2 - 2, y + 74, fg=badge_fg, bg=badge_bg)

    y += card_h + 20
    return canvas, y

# -----------------------------------------------------------------------------
# RENDU DE LA SECTION 3 : SPRITES DE LINK & ARMES
# -----------------------------------------------------------------------------
def render_sheet_link_sprites(assets, canvas=None, start_y=30):
    W = 1920
    link_order = assets['link_order']
    link_frames = assets['link_frames']
    card_w = 108
    card_h = 120
    margin_x = 42
    gap_x = 8

    # 31 sprites Link -> 2 rangées de 16
    rows_cnt = (len(link_order) + 15) // 16
    total_h = start_y + 60 + rows_cnt * (card_h + 16) + 40
    if canvas is None:
        canvas = make_canvas(W, total_h)

    y = start_y
    y = draw_section_header(
        canvas, y,
        "SECTION 3 : SPRITES DU HEROS LINK & ARMES (BANQUE 0 VIC-II SOUS $1000)",
        "Marche 4 directions (frames 0 & 1), attaques a l'epee, port d'items, "
        "arcs, boomerangs 360 deg, flammes de bougie et explosion de bombe en 3 phases."
    )

    for idx, name in enumerate(link_order):
        row = idx // 16
        col = idx % 16
        cx = margin_x + col * (card_w + gap_x)
        cy = y + row * (card_h + 16)

        draw_rect(canvas, cx, cy, card_w, card_h, fill=UI_CARD_BG, border=UI_CARD_BORD)

        # Boîte d'affichage du sprite 48x42
        bx = cx + (card_w - 48) // 2
        by = cy + 8
        draw_checkered_box(canvas, bx - 2, by - 2, 52, 46)
        draw_rect(canvas, bx - 2, by - 2, 52, 46, border=(50, 60, 80))

        grid = to_grid(link_frames[name])
        pal = get_sprite_palette('link', name)
        spr_pix = render_sprite_pixels(grid, pal, scale=2)
        blit(canvas, bx, by, spr_pix)

        # Légende
        short_name = name.replace("link_", "").replace("proj_", "p_")
        draw_centered_text(canvas, short_name[:14], cx + card_w // 2, cy + 60, scale=1, fg=UI_TEXT_PRI)
        draw_centered_text(canvas, f"ID #{idx:02d}", cx + card_w // 2, cy + 74, scale=1, fg=UI_TEXT_SEC)

        # Catégorie
        cat = "HERO"
        if "sword" in name or "att" in name: cat = "WEAPON"
        elif "proj" in name or "arrow" in name or "boom" in name: cat = "PROJ"
        elif "item" in name or "bomb" in name: cat = "ITEM"
        draw_badge(canvas, cat, cx + (card_w - len(cat)*6) // 2 - 2, cy + 90, fg=UI_BADGE_TXT, bg=UI_BADGE_BG)

    y += rows_cnt * (card_h + 16) + 20
    return canvas, y

# -----------------------------------------------------------------------------
# RENDU DE LA SECTION 4 : BESTIAIRE COMPLET (MONSTRES & BOSSES)
# -----------------------------------------------------------------------------
def render_sheet_enemy_sprites(assets, canvas=None, start_y=30):
    W = 1920
    en_order = assets['en_order']
    en_frames = assets['en_frames']
    card_w = 108
    card_h = 120
    margin_x = 42
    gap_x = 8

    # 89 sprites monstres -> 6 rangées de 16
    rows_cnt = (len(en_order) + 15) // 16
    total_h = start_y + 60 + rows_cnt * (card_h + 16) + 40
    if canvas is None:
        canvas = make_canvas(W, total_h)

    y = start_y
    y = draw_section_header(
        canvas, y,
        "SECTION 4 : BESTIAIRE COMPLET HYRULE & SOUTERRAINS (89 SPRITES D'ENNEMIS & BOSS)",
        "Overworld (Octorok, Moblin, Tektite, Leever, Peahat, Armos, Ghini, Zora, Lynel) "
        "et Donjons (Keese, Stalfos, Goriya 4 dir, Darknut, Wizzrobe, Boss Aquamentus, Dodongo, Ganon...)."
    )

    for idx, name in enumerate(en_order):
        row = idx // 16
        col = idx % 16
        cx = margin_x + col * (card_w + gap_x)
        cy = y + row * (card_h + 16)

        draw_rect(canvas, cx, cy, card_w, card_h, fill=UI_CARD_BG, border=UI_CARD_BORD)

        # Boîte d'affichage sprite
        bx = cx + (card_w - 48) // 2
        by = cy + 8
        draw_checkered_box(canvas, bx - 2, by - 2, 52, 46)
        draw_rect(canvas, bx - 2, by - 2, 52, 46, border=(50, 60, 80))

        # Déterminer la variante de couleur
        var = "blue" if "_1" in name and not any(k in name for k in ('octo', 'moblin', 'goriya')) else "default"
        pal = get_sprite_palette('enemies', name, variant=var)
        grid = to_grid(en_frames[name])
        spr_pix = render_sprite_pixels(grid, pal, scale=2)
        blit(canvas, bx, by, spr_pix)

        # Légendes
        short_name = name.replace("enemy_", "e_").replace("proj_", "p_")
        draw_centered_text(canvas, short_name[:14], cx + card_w // 2, cy + 60, scale=1, fg=UI_TEXT_PRI)
        draw_centered_text(canvas, f"EN #{idx:02d}", cx + card_w // 2, cy + 74, scale=1, fg=UI_TEXT_SEC)

        # Badge catégorie
        if any(k in name for k in ('aquamentus', 'dodongo', 'manhandla', 'gleeok', 'digdogger', 'gohma', 'patra', 'ganon')):
            b_txt, b_fg, b_bg = "BOSS", (255, 220, 100), (60, 45, 15)
        elif any(k in name for k in ('proj', 'rock', 'spear', 'fireball', 'magic', 'death')):
            b_txt, b_fg, b_bg = "FX/SHOT", (150, 220, 255), (20, 40, 60)
        elif any(k in name for k in ('keese', 'zol', 'rope', 'stalfos', 'goriya', 'darknut', 'wizzrobe', 'wallmaster', 'likelike', 'polsvoice', 'gibdo', 'vire', 'bubble', 'trap', 'lanmola')):
            b_txt, b_fg, b_bg = "DUNG", (180, 255, 180), (20, 50, 30)
        else:
            b_txt, b_fg, b_bg = "OVERW", (255, 180, 150), (55, 30, 20)

        draw_badge(canvas, b_txt, cx + (card_w - len(b_txt)*6) // 2 - 2, cy + 90, fg=b_fg, bg=b_bg)

    y += rows_cnt * (card_h + 16) + 20
    return canvas, y

# -----------------------------------------------------------------------------
# RENDU DE LA SECTION 5 : OBJETS, RELIQUES, TRIFORCE & PNJS
# -----------------------------------------------------------------------------
def render_sheet_item_sprites(assets, canvas=None, start_y=30):
    W = 1920
    extra_order = assets['extra_order']
    extra_frames = assets['extra_frames']
    card_w = 108
    card_h = 120
    margin_x = 42
    gap_x = 8

    rows_cnt = (len(extra_order) + 15) // 16
    total_h = start_y + 60 + rows_cnt * (card_h + 16) + 40
    if canvas is None:
        canvas = make_canvas(W, total_h)

    y = start_y
    y = draw_section_header(
        canvas, y,
        "SECTION 5 : OBJETS D'INVENTAIRE, RELIQUES, PNJS & TRIFORCE DE LA SAGESSE",
        "Epees, boucliers, reliques passives deplacement (radeau, echelle), fragments de Triforce "
        "biseautes pour pyramide complete et PNJs (Vieil Homme, Marchand, Vieille Femme)."
    )

    for idx, name in enumerate(extra_order):
        row = idx // 16
        col = idx % 16
        cx = margin_x + col * (card_w + gap_x)
        cy = y + row * (card_h + 16)

        draw_rect(canvas, cx, cy, card_w, card_h, fill=UI_CARD_BG, border=UI_CARD_BORD)

        # Boîte d'affichage sprite
        bx = cx + (card_w - 48) // 2
        by = cy + 8
        draw_checkered_box(canvas, bx - 2, by - 2, 52, 46)
        draw_rect(canvas, bx - 2, by - 2, 52, 46, border=(50, 60, 80))

        pal = get_sprite_palette('extra', name)
        grid = to_grid(extra_frames[name])
        spr_pix = render_sprite_pixels(grid, pal, scale=2)
        blit(canvas, bx, by, spr_pix)

        # Légendes
        short_name = name.replace("item_", "").replace("tri_", "tri_")
        draw_centered_text(canvas, short_name[:14], cx + card_w // 2, cy + 60, scale=1, fg=UI_TEXT_PRI)
        draw_centered_text(canvas, f"SLOT #{idx:02d}", cx + card_w // 2, cy + 74, scale=1, fg=UI_TEXT_SEC)

        # Catégorie
        if name in ('old_man', 'merchant', 'old_woman'):
            b_txt, b_fg, b_bg = "NPC", (255, 200, 150), (50, 30, 20)
        elif name.startswith('tri_') or name == 'item_triforce':
            b_txt, b_fg, b_bg = "TRIFORCE", (255, 225, 80), (60, 50, 15)
        elif name in ('item_raft', 'item_stepladder', 'item_ring', 'item_bracelet', 'item_book', 'item_magic_key'):
            b_txt, b_fg, b_bg = "RELIC", (150, 220, 255), (20, 40, 60)
        else:
            b_txt, b_fg, b_bg = "EQUIP", (200, 255, 180), (20, 50, 25)

        draw_badge(canvas, b_txt, cx + (card_w - len(badge_txt if 'badge_txt' in locals() else b_txt)*6) // 2 - 2, cy + 90, fg=b_fg, bg=b_bg)

    # Carte spéciale vitrine : Triforce de la Sagesse Complète Assemblée (8 fragments)
    tri_card_w = card_w * 2 + gap_x
    tri_cx = margin_x + (len(extra_order) % 16) * (card_w + gap_x)
    tri_cy = y + (len(extra_order) // 16) * (card_h + 16)
    draw_rect(canvas, tri_cx, tri_cy, tri_card_w, card_h, fill=(24, 28, 42), border=(80, 70, 30))

    # Assemblage des 4 étages de la pyramide (96x64 px)
    tri_comp = [[0] * 24 for _ in range(32)]
    tiers = [
        ('tri_p1', 'tri_p2', 0),
        ('tri_p3', 'tri_p4', 8),
        ('tri_p5', 'tri_p6', 16),
        ('tri_p7', 'tri_p8', 24),
    ]
    for left_n, right_n, y_off in tiers:
        grid_l = to_grid(extra_frames[left_n])
        grid_r = to_grid(extra_frames[right_n])
        for ty in range(8):
            for tx in range(12):
                if grid_l[ty][tx]: tri_comp[y_off + ty][tx] = grid_l[ty][tx]
                if grid_r[ty][tx]: tri_comp[y_off + ty][12 + tx] = grid_r[ty][tx]

    tri_pal = {0: None, 1: (0xFF, 0xE0, 0x80), 2: (0xFF, 0xD0, 0x00), 3: (0xD0, 0x80, 0x00)}
    tri_pix = render_sprite_pixels(tri_comp, tri_pal, scale=2)
    # tri_pix fait 24*4 = 96 px de large, 32*2 = 64 px de haut
    tri_bx = tri_cx + (tri_card_w - 96) // 2
    tri_by = tri_cy + 8
    draw_checkered_box(canvas, tri_bx - 4, tri_by - 2, 104, 68, (20, 22, 32), (30, 34, 48))
    draw_rect(canvas, tri_bx - 4, tri_by - 2, 104, 68, border=(100, 85, 35))
    blit(canvas, tri_bx, tri_by, tri_pix)

    draw_centered_text(canvas, "Triforce Sagesse", tri_cx + tri_card_w // 2, tri_cy + 80, scale=1, fg=UI_TITLE_GOLD)
    draw_centered_text(canvas, "Pyramide 8 Pieces Assemblee", tri_cx + tri_card_w // 2, tri_cy + 92, scale=1, fg=UI_SUBTITLE)
    draw_badge(canvas, "8 PIECES - QUETE FINALE", tri_cx + (tri_card_w - 23*6) // 2, tri_cy + 104, fg=(255, 230, 100), bg=(60, 50, 15))

    y += rows_cnt * (card_h + 16) + 20
    return canvas, y

# -----------------------------------------------------------------------------
# RENDU DE LA SECTION 6 : CYCLES D'ANIMATION DECOMPOSES
# -----------------------------------------------------------------------------
ANIMATIONS_CATALOG = [
    # Titre, source, frames_list, timing, badges_list, color_variant
    ("Link Marche Bas", "link", ["down_0", "down_1"], "2 Frames @ 8 FPS", ["F0", "F1"], "default"),
    ("Link Marche Haut", "link", ["up_0", "up_1"], "2 Frames @ 8 FPS", ["F0", "F1"], "default"),
    ("Link Marche Gauche", "link", ["left_0", "left_1"], "2 Frames @ 8 FPS", ["F0", "F1"], "default"),
    ("Link Marche Droite", "link", ["right_0", "right_1"], "2 Frames @ 8 FPS", ["F0", "F1"], "default"),
    ("Link Coup d'Epee Bas", "link", ["down_0", "attack_down"], "Estoc & lame", ["Repos", "Frappe"], "default"),
    ("Link Coup d'Epee Haut", "link", ["up_0", "attack_up"], "Estoc & lame", ["Repos", "Frappe"], "default"),
    ("Link Coup d'Epee Droite", "link", ["right_0", "attack_right"], "Estoc & lame", ["Repos", "Frappe"], "default"),
    ("Boomerang Rotation", "link", ["proj_boom_0", "proj_boom_1", "proj_boom_2", "proj_boom_3"], "Rotation 360 deg", ["0 deg", "90 deg", "180 deg", "270 deg"], "default"),
    ("Bougie / Flamme", "link", ["proj_flame_0", "proj_flame_1"], "Vacillement", ["F0", "F1"], "default"),
    ("Explosion Bombe (3 Ph.)", "mixed", [("link", "item_bomb"), ("link", "proj_explosion"), ("enemies", "enemy_death_1")], "Cycle de vie 24 ticks", ["Posee", "Deflagration", "Fumee"], "default"),
    ("Fumee Mort Monstre", "enemies", ["enemy_death_0", "enemy_death_1"], "Dispersion rapide", ["Impact", "Souffle"], "default"),
    ("Octorok Rouge Marche", "enemies", ["octo_down_0", "octo_down_1"], "Alternance tentacules", ["F0", "F1"], "default"),
    ("Moblin Rouge Marche", "enemies", ["moblin_down_0", "moblin_down_1"], "Pas lourd lance", ["F0", "F1"], "default"),
    ("Tektite Saut / Bond", "enemies", ["tektite_0", "tektite_1"], "Accroupi -> Saut", ["Terre", "En vol"], "default"),
    ("Leever Sortie / Vrille", "enemies", ["leever_0", "leever_1"], "Forage sous-sol", ["Sortie", "Vrille"], "default"),
    ("Peahat Vol Stationnaire", "enemies", ["peahat_0", "peahat_1"], "Palmes tournoyantes", ["F0", "F1"], "default"),
    ("Armos Statue Animee", "enemies", ["armos_0", "armos_1"], "Marche de pierre", ["F0", "F1"], "default"),
    ("Ghini Spectre Flottant", "enemies", ["ghini_0", "ghini_1"], "Ondulation fantome", ["F0", "F1"], "default"),
    ("Zora Emergence & Plongee", "enemies", ["zora_0", "zora_1"], "Sortie eau / Tir", ["Surface", "Plongeon"], "default"),
    ("Lynel Marche Centaure", "enemies", ["lynel_0", "lynel_1"], "Galop monstrueux", ["F0", "F1"], "default"),
    ("Keese Chauve-Souris", "enemies", ["keese_0", "keese_1"], "Battement d'ailes", ["Fermees", "Deployees"], "default"),
    ("Zol Slime Pulsation", "enemies", ["zol_0", "zol_1"], "Etirement fluide", ["Bas", "Haut"], "default"),
    ("Rope Serpent Reptation", "enemies", ["rope_0", "rope_1"], "Charge reptilienne", ["F0", "F1"], "default"),
    ("Stalfos Squelette", "enemies", ["stalfos_0", "stalfos_1"], "Marche osseuse", ["F0", "F1"], "default"),
    ("Goriya Rouge Chien", "enemies", ["goriya_down_0", "goriya_down_1"], "Marche & boomerang", ["F0", "F1"], "default"),
    ("Darknut Chevalier", "enemies", ["darknut_0", "darknut_1"], "Bouclier & pas", ["F0", "F1"], "default"),
    ("Wizzrobe Magicien", "enemies", ["wizzrobe_0", "wizzrobe_1"], "Incantation", ["F0", "F1"], "default"),
    ("Wallmaster Main Murale", "enemies", ["wallmaster_0", "wallmaster_1"], "Attaque du plafond", ["Ouverte", "Fermee"], "default"),
    ("Like Like Glouton", "enemies", ["likelike_0", "likelike_1"], "Ondulation bouclier", ["F0", "F1"], "default"),
    ("Pols Voice Lapin", "enemies", ["polsvoice_0", "polsvoice_1"], "Rebonds vifs", ["Sol", "Bond"], "default"),
    ("Gibdo Momie Lente", "enemies", ["gibdo_0", "gibdo_1"], "Marche funebre", ["F0", "F1"], "default"),
    ("Aquamentus Dragon", "enemies", ["aquamentus_0", "aquamentus_1"], "Cracheur de feu", ["Repos", "Souffle"], "default"),
    ("Dodongo Dinosaure", "enemies", ["dodongo_0", "dodongo_1"], "Marche cuirassier", ["F0", "F1"], "default"),
    ("Gohma Oeil Cyclope", "enemies", ["gohma_closed", "gohma_open"], "Clignement oeil", ["Ferme", "Vulnerable"], "default"),
    ("Ganon Prince Tenebres", "enemies", ["ganon_0", "ganon_1"], "Forme de combat", ["F0", "F1"], "default"),
    ("Triforce Scintillement", "extra", ["item_triforce", "item_triforce"], "Aura dorée mystique", ["Or Pur", "Eclat"], "default"),
]

def render_sheet_animations(assets, canvas=None, start_y=30):
    W = 1920
    link_frames = assets['link_frames']
    en_frames = assets['en_frames']
    extra_frames = assets['extra_frames']

    # On organise en cartes d'animation de 290 px de large, 118 px de haut
    # 6 animations par ligne -> 6 * 300 = 1800 px
    card_w = 296
    card_h = 118
    margin_x = 42
    gap_x = 10
    cols_cnt = 6

    total_cards = len(ANIMATIONS_CATALOG)
    rows_cnt = (total_cards + cols_cnt - 1) // cols_cnt
    total_h = start_y + 60 + rows_cnt * (card_h + 14) + 40
    if canvas is None:
        canvas = make_canvas(W, total_h)

    y = start_y
    y = draw_section_header(
        canvas, y,
        "SECTION 6 : CYCLES D'ANIMATION DECOMPOSES & SEQUENCES TEMPORELLES",
        "Visualisation frame par frame avec cadencement, fleches de transition "
        "et badges de synchronisation motrice."
    )

    for idx, item in enumerate(ANIMATIONS_CATALOG):
        title, src, f_names, timing, badges, variant = item
        row = idx // cols_cnt
        col = idx % cols_cnt
        cx = margin_x + col * (card_w + gap_x)
        cy = y + row * (card_h + 14)

        draw_rect(canvas, cx, cy, card_w, card_h, fill=UI_CARD_BG, border=UI_CARD_BORD)

        # En-tête de la carte
        draw_text(canvas, title, cx + 8, cy + 8, scale=1, fg=UI_TITLE_GOLD)
        draw_text(canvas, timing, cx + 8, cy + 20, scale=1, fg=UI_TEXT_SEC)

        # Disposition horizontale des frames
        nb_frames = len(f_names)
        spr_w, spr_h = 48, 42
        avail_w = card_w - 16
        spacing = avail_w // nb_frames

        for f_idx, fname in enumerate(f_names):
            if src == "mixed":
                actual_src, actual_fname = fname
            else:
                actual_src, actual_fname = src, fname

            # Récupération de la frame
            if actual_src == "link":
                fr_entry = link_frames[actual_fname]
            elif actual_src == "enemies":
                fr_entry = en_frames[actual_fname]
            else:
                fr_entry = extra_frames[actual_fname]

            grid = to_grid(fr_entry)
            var = "blue" if (f_idx == 1 and title == "Triforce Scintillement") else variant
            pal = get_sprite_palette(actual_src, actual_fname, variant=var)
            if title == "Triforce Scintillement" and f_idx == 1:
                pal = {0: None, 1: C_WHITE, 2: C_ORANGE, 3: C_RED}

            spr_pix = render_sprite_pixels(grid, pal, scale=2)

            bx = cx + 8 + f_idx * spacing + (spacing - spr_w) // 2
            by = cy + 36

            # Fond sous le sprite
            draw_checkered_box(canvas, bx - 2, by - 2, spr_w + 4, spr_h + 4)
            draw_rect(canvas, bx - 2, by - 2, spr_w + 4, spr_h + 4, border=(50, 60, 80))
            blit(canvas, bx, by, spr_pix)

            # Badge sous la frame
            badge_lbl = badges[f_idx] if f_idx < len(badges) else f"F{f_idx}"
            draw_badge(canvas, badge_lbl, bx + (spr_w - len(badge_lbl)*6)//2 - 2, by + spr_h + 6, fg=UI_BADGE_TXT, bg=UI_BADGE_BG)

            # Flèche vers la frame suivante
            if f_idx < nb_frames - 1:
                arrow_x = bx + spr_w + 4
                arrow_y = by + spr_h // 2
                draw_arrow(canvas, arrow_x, arrow_y, length=spacing - spr_w - 8, color=UI_ARROW)

    y += rows_cnt * (card_h + 14) + 20
    return canvas, y

# -----------------------------------------------------------------------------
# PLANCHE MAÎTRESSE GLOBALE (MASTER ATLAS)
# -----------------------------------------------------------------------------
def build_master_atlas(assets):
    print("[1/6] Calcul de la taille de la planche maîtresse...")
    W = 1920

    # Estimation précise de la hauteur totale :
    # Header global : 110 px
    # Section 1 (Tiles Overworld) : ~580 px
    # Section 2 (Dungeon Tiles)   : ~240 px
    # Section 3 (Link Sprites)    : ~370 px
    # Section 4 (Enemy Sprites)   : ~950 px
    # Section 5 (Items & NPCs)    : ~370 px
    # Section 6 (Animations)      : ~880 px
    # Footer global               : ~60 px
    total_H = 3580

    canvas = make_canvas(W, total_H)

    # 1. Bannière Principale d'en-tête
    draw_rect(canvas, 30, 20, W - 60, 80, fill=(16, 22, 34), border=(60, 80, 110))
    draw_rect(canvas, 30, 20, 8, 80, fill=UI_TITLE_GOLD)
    draw_text(canvas, "THE LEGEND OF ZELDA — COMMODORE 64 GRAPHICS ATLAS", 55, 32, scale=2, fg=UI_TITLE_GOLD)
    draw_text(canvas, "PLANCHE MAITRESSE COMPLETE : TUILES OVERWORLD & DONJONS, SPRITES ET ANIMATIONS", 55, 54, scale=1, fg=UI_SUBTITLE)
    draw_text(canvas, "Format VIC-II Multicolore (160x200 / Aspect 2:1) - Cartouche Magic Desk 512 Ko (64 Banques) - Moteur MOS 6510", 55, 72, scale=1, fg=UI_TEXT_SEC)

    cur_y = 115

    # 2. Section 1 : Tuiles Overworld
    print("[2/6] Rendu Section 1 : Tuiles Overworld...")
    _, cur_y = render_sheet_tiles(assets, canvas=canvas, start_y=cur_y)

    # 3. Section 2 : Tuiles Donjons
    print("[3/6] Rendu Section 2 : Tuiles Donjons...")
    _, cur_y = render_sheet_dungeon_tiles(assets, canvas=canvas, start_y=cur_y)

    # 4. Section 3 : Sprites Link
    print("[4/6] Rendu Section 3 : Sprites Link...")
    _, cur_y = render_sheet_link_sprites(assets, canvas=canvas, start_y=cur_y)

    # 5. Section 4 : Sprites Monstres & Bosses
    print("[5/6] Rendu Section 4 : Monstres & Bosses...")
    _, cur_y = render_sheet_enemy_sprites(assets, canvas=canvas, start_y=cur_y)

    # 6. Section 5 : Objets, Reliques & PNJs
    print("[6/6] Rendu Section 5 : Objets, Reliques & PNJs...")
    _, cur_y = render_sheet_item_sprites(assets, canvas=canvas, start_y=cur_y)

    # 7. Section 6 : Animations
    print("      Rendu Section 6 : Cycles d'Animation...")
    _, cur_y = render_sheet_animations(assets, canvas=canvas, start_y=cur_y)

    # Footer
    draw_rect(canvas, 30, cur_y + 10, W - 60, 40, fill=(16, 20, 30), border=(40, 50, 70))
    draw_centered_text(canvas, "THE LEGEND OF ZELDA C64 — PROJET OPEN-SOURCE ET PORTAGE FIDÈLE DU CLASSIQUE NES — TOUS DROITS RESERVES", W // 2, cur_y + 24, scale=1, fg=UI_TEXT_SEC)

    # Rognage si nécessaire à la hauteur réelle
    final_canvas = canvas[:cur_y + 60]
    return final_canvas

# -----------------------------------------------------------------------------
# PROGRAMME PRINCIPAL & EXPORT PNG
# -----------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(description="Exporteur d'atlas et planches graphiques Zelda C64")
    parser.add_argument("--all", action="store_true", help="Génère la planche maîtresse ET toutes les planches spécialisées")
    parser.add_argument("--master", action="store_true", help="Génère uniquement la planche maîtresse build/atlas_all_assets.png")
    parser.add_argument("--tiles", action="store_true", help="Génère uniquement la planche des tuiles")
    parser.add_argument("--link", action="store_true", help="Génère uniquement la planche Link")
    parser.add_argument("--enemies", action="store_true", help="Génère uniquement la planche monstres")
    parser.add_argument("--items", action="store_true", help="Génère uniquement la planche objets & reliques")
    parser.add_argument("--animations", action="store_true", help="Génère uniquement la planche animations")
    parser.add_argument("--out-dir", default=BUILD_DIR, help="Dossier de destination (défaut: build/)")

    args = parser.parse_args()
    os.makedirs(args.out_dir, exist_ok=True)

    # Par défaut si aucun drapeau n'est passé : --all
    run_all = args.all or not any([args.master, args.tiles, args.link, args.enemies, args.items, args.animations])

    t0 = time.time()
    print("=" * 70)
    print("      EXTRACTION ET EXPORT DE L'ATLAS GRAPHIQUE ZELDA C64")
    print("=" * 70)

    assets = load_all_assets()
    print(f"Chargement terminé : {len(assets['tiles'])} tuiles monde, {len(assets['link_order'])} sprites Link, "
          f"{len(assets['en_order'])} sprites monstres, {len(assets['extra_order'])} sprites items/PNJs.")

    # 1. Planche Maîtresse
    if run_all or args.master:
        print("\n--- Génération de la Planche Maîtresse Consolidée ---")
        master_img = build_master_atlas(assets)
        out_path = os.path.join(args.out_dir, "atlas_all_assets.png")
        print(f"Compression et écriture PNG : {out_path} ({len(master_img[0])}x{len(master_img)} px)...")
        write_png(out_path, master_img)
        print(f"✓ {out_path} généré avec succès ({os.path.getsize(out_path):,} octets) !")

    # 2. Planches Dédiées
    if run_all or args.tiles:
        print("\n--- Génération de la Planche Spécialisée Tuiles (Overworld & Donjons) ---")
        canvas_t = make_canvas(1920, 1100)
        _, cur_y = render_sheet_tiles(assets, canvas=canvas_t, start_y=30)
        _, cur_y = render_sheet_dungeon_tiles(assets, canvas=canvas_t, start_y=cur_y + 10)
        img_t = canvas_t[:cur_y + 30]
        out_path = os.path.join(args.out_dir, "sheet_tiles.png")
        write_png(out_path, img_t)
        print(f"✓ {out_path} généré ({os.path.getsize(out_path):,} octets).")

    if run_all or args.link:
        print("\n--- Génération de la Planche Spécialisée Link & Armes ---")
        img_l, _ = render_sheet_link_sprites(assets)
        out_path = os.path.join(args.out_dir, "sheet_sprites_link.png")
        write_png(out_path, img_l)
        print(f"✓ {out_path} généré ({os.path.getsize(out_path):,} octets).")

    if run_all or args.enemies:
        print("\n--- Génération de la Planche Spécialisée Monstres & Bosses ---")
        img_e, _ = render_sheet_enemy_sprites(assets)
        out_path = os.path.join(args.out_dir, "sheet_sprites_enemies.png")
        write_png(out_path, img_e)
        print(f"✓ {out_path} généré ({os.path.getsize(out_path):,} octets).")

    if run_all or args.items:
        print("\n--- Génération de la Planche Spécialisée Objets, Reliques & PNJs ---")
        img_i, _ = render_sheet_item_sprites(assets)
        out_path = os.path.join(args.out_dir, "sheet_sprites_items.png")
        write_png(out_path, img_i)
        print(f"✓ {out_path} généré ({os.path.getsize(out_path):,} octets).")

    if run_all or args.animations:
        print("\n--- Génération de la Planche Spécialisée Cycles d'Animation ---")
        img_a, _ = render_sheet_animations(assets)
        out_path = os.path.join(args.out_dir, "sheet_animations.png")
        write_png(out_path, img_a)
        print(f"✓ {out_path} généré ({os.path.getsize(out_path):,} octets).")

    print("\n" + "=" * 70)
    print(f"✓✓✓ ATLAS GRAPHIQUE GENERE ENTIEREMENT AVEC SUCCES EN {time.time() - t0:.2f}s !")
    print("=" * 70)

if __name__ == "__main__":
    main()
