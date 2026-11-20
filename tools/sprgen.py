#!/usr/bin/env python3
"""Convertit un fichier d'images ASCII (assets/*.txt) en sprites C64 multicolores.

Usage : sprgen.py assets/link.txt -o src/sprites.asm [--preview apercu.png]

Sortie : un bloc de 64 octets par image, étiqueté sprite_<prefixe>_<nom>.
Les blocs sont consécutifs : le premier doit être aligné sur 64 octets.
Supporte les images 8x16 (Link, avec padding 2,2) et 12x21 (taille complète du sprite),
ainsi que [nom pad X Y] et [nom mirror autre].
"""
import argparse
import os
import struct
import sys
import zlib

SPR_W, SPR_H = 12, 21         # taille d'un sprite multicolore (12 cols x 21 lignes)
CODES = {".": 0, "s": 1, "g": 2, "b": 3}   # 00 transp., 01 MC1, 10 propre, 11 MC2

# Palette C64 "pepto" pour aperçu PNG
PREVIEW_LINK = {
    0: (0x35, 0x28, 0x79),      # fond bleu C64
    1: (0xB8, 0x69, 0x62),      # peau / or = rouge clair ($0a)
    2: (0x58, 0x8D, 0x43),      # vert = vert Link ($05)
    3: (0x6F, 0x4F, 0x25),      # marron ($09)
}

PREVIEW_SWORD = {
    0: (0x35, 0x28, 0x79),      # fond bleu C64
    1: (0xB8, 0x69, 0x62),      # garde dorée ($0a)
    2: (0xEE, 0xEE, 0xEE),      # lame blanche brillante ($01)
    3: (0x6F, 0x4F, 0x25),      # poignée marron ($09)
}

PREVIEW_ENEMY = {
    0: (0x35, 0x28, 0x79),      # fond bleu C64
    1: (0xB8, 0x69, 0x62),      # rose/or/peau = rouge clair ($0a)
    2: (0x9F, 0x47, 0x3E),      # rouge vif ennemi ($02)
    3: (0x6F, 0x4F, 0x25),      # marron ($09)
}


def parse(path):
    frames = {}                 # nom -> {'rows': [...], 'pad': (px, py), 'mirror': name}
    order = []
    current = None
    with open(path, encoding="utf-8") as f:
        for n, raw in enumerate(f, 1):
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            if line.startswith("["):
                head, _, rest = line.partition("]")
                current = head[1:].strip()
                order.append(current)
                tokens = rest.split()
                if tokens[:1] == ["mirror"]:
                    frames[current] = {"mirror": tokens[1], "rows": []}
                elif tokens[:1] == ["pad"] and len(tokens) == 3:
                    frames[current] = {"pad": (int(tokens[1]), int(tokens[2])), "rows": []}
                else:
                    frames[current] = {"rows": []}
                continue
            if current is None or "mirror" in frames[current]:
                sys.exit(f"{path}:{n}: ligne hors image : {line!r}")
            if any(c not in CODES for c in line):
                sys.exit(f"{path}:{n}: caractere invalide dans {line!r}")
            frames[current]["rows"].append(line)

    for name in order:
        entry = frames[name]
        if "mirror" in entry:
            tgt = entry["mirror"]
            if tgt not in frames or "mirror" in frames[tgt]:
                sys.exit(f"[{name}] : mirror vers image inconnue ({tgt})")
            ref = frames[tgt]
            entry["rows"] = [r[::-1] for r in ref["rows"]]
            entry["pad"] = ref.get("pad")
        rows = entry["rows"]
        h = len(rows)
        w = len(rows[0]) if h > 0 else 0
        if any(len(r) != w for r in rows):
            sys.exit(f"[{name}] : les lignes ont des largeurs differentes")
        if w > SPR_W or h > SPR_H:
            sys.exit(f"[{name}] : dimension {w}x{h} depasse le sprite 12x21")
        if "pad" not in entry or entry["pad"] is None:
            if w == 8 and h == 16:
                entry["pad"] = (2, 2)
            elif w == SPR_W and h == SPR_H:
                entry["pad"] = (0, 0)
            else:
                entry["pad"] = ((SPR_W - w) // 2, (SPR_H - h) // 2)
    return order, frames


def to_grid(entry):
    rows = entry["rows"]
    px, py = entry["pad"]
    grid = [[0] * SPR_W for _ in range(SPR_H)]
    for y, row in enumerate(rows):
        for x, c in enumerate(row):
            if 0 <= y + py < SPR_H and 0 <= x + px < SPR_W:
                grid[y + py][x + px] = CODES[c]
    return grid


# Classification des sprites recevant une ombre portée (code 3 = b = VIC_SPRITE_MC2 = COL_BROWN)
# dans les lignes libres basses (18..20) du cadre matériel 12x21, sans sprite VIC-II supplémentaire.
SHADOW_GROUND_EXACT = {
    "down_0", "down_1", "up_0", "up_1", "left_0", "left_1", "right_0", "right_1",
    "attack_down", "attack_up", "attack_left", "attack_right",
    "item_get", "old_man", "merchant", "old_woman",
    "tektite_0", "polsvoice_0", "gel",
    "lanmola_head", "lanmola_body",
    "manhandla_core", "patra_center",
}
SHADOW_GROUND_PREFIXES = (
    "octo_down", "octo_up", "octo_left", "octo_right",
    "moblin_down", "moblin_up", "moblin_left", "moblin_right",
    "lynel_", "leever_", "armos_",
    "zol_", "rope_", "stalfos_", "goriya_", "darknut_",
    "wizzrobe_", "wallmaster_", "likelike_", "gibdo_",
)
SHADOW_AIR_EXACT = {
    "tektite_1", "polsvoice_1", "patra_orb",
}
SHADOW_AIR_PREFIXES = (
    "keese_", "peahat_", "ghini_", "vire_",
)
SHADOW_WIDE_EXACT = {
    "digdogger", "gohma_closed", "gohma_open",
}
SHADOW_WIDE_PREFIXES = (
    "dodongo_", "ganon_bl_", "ganon_br_",
)


def shadow_style_for(name):
    if name in SHADOW_AIR_EXACT or name.startswith(SHADOW_AIR_PREFIXES):
        return "air"
    if name in SHADOW_WIDE_EXACT or name.startswith(SHADOW_WIDE_PREFIXES):
        return "wide"
    if name in SHADOW_GROUND_EXACT or name.startswith(SHADOW_GROUND_PREFIXES):
        return "ground"
    return None


def apply_shadow(grid, style):
    """Ajoute une ombre elliptique subtile (MC2 = COL_BROWN) uniquement sur pixels transparents."""
    if not style:
        return grid
    if style == "ground":
        spans = ((18, range(3, 9)), (19, range(4, 8)))
    elif style == "air":
        spans = ((19, range(4, 8)), (20, range(5, 7)))
    elif style == "wide":
        spans = ((18, range(2, 10)), (19, range(3, 9)))
    else:
        return grid
    for y, xs in spans:
        for x in xs:
            if grid[y][x] == 0:
                grid[y][x] = 3
    return grid


def encode(grid):
    out = []
    for row in grid:
        bits = "".join(f"{p:02b}" for p in row)
        out.append([int(bits[i:i + 8], 2) for i in range(0, 24, 8)])
    return out


def write_png(path, pixels):
    h, w = len(pixels), len(pixels[0])
    raw = b"".join(b"\x00" + bytes(c for px in row for c in px) for row in pixels)

    def chunk(tag, data):
        body = tag + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body))

    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)))
        f.write(chunk(b"IDAT", zlib.compress(raw, 9)))
        f.write(chunk(b"IEND", b""))


def preview(path, order, grids, scale=12, prefix=""):
    gap = 2
    width = len(order) * (SPR_W + gap) + gap
    cells = [[PREVIEW_LINK[0]] * width for _ in range(SPR_H + 2 * gap)]
    for i, name in enumerate(order):
        if "sword" in name:
            palette = PREVIEW_SWORD
        elif prefix == "enemies":
            palette = dict(PREVIEW_ENEMY)
            if "stalfos" in name or "keese" in name or "polsvoice" in name:
                palette[2] = (0xEE, 0xEE, 0xEE) # Blanc C64
            elif "aquamentus" in name or "zora" in name or "manhandla" in name:
                palette[2] = (0x58, 0x8D, 0x43) # Vert C64
            elif "ganon" in name:
                palette[2] = (0x67, 0x39, 0xB0) # Violet C64
            elif "dodongo" in name or "armos" in name or "gibdo" in name:
                palette[2] = (0x6F, 0x4F, 0x25) # Marron C64
            elif "trap" in name or "death" in name:
                palette[2] = (0x80, 0x80, 0x80) # Gris C64
            elif "bubble" in name:
                palette[2] = (0xEE, 0xEE, 0xEE)
            else:
                palette[2] = (0x9F, 0x47, 0x3E) # Rouge vif ennemi
        else:
            palette = PREVIEW_LINK
        for y in range(SPR_H):
            for x in range(SPR_W):
                cells[y + gap][gap + i * (SPR_W + gap) + x] = palette[grids[name][y][x]]
    pix = []
    for row in cells:
        wide = [px for px in row for _ in range(2 * scale)]   # pixel MC = 2x1
        pix.extend([wide] * scale)
    write_png(path, pix)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("source")
    ap.add_argument("-o", "--output", required=True)
    ap.add_argument("--preview")
    ap.add_argument("--prefix", default=None, help="Prefix for sprite labels")
    ap.add_argument("--shadows", action="store_true", help="Ajoute les ombres portées sous les personnages")
    a = ap.parse_args()

    order, frames = parse(a.source)
    grids = {}
    for n in order:
        g = to_grid(frames[n])
        if a.shadows:
            apply_shadow(g, shadow_style_for(n))
        grids[n] = g
    prefix = a.prefix if a.prefix is not None else os.path.splitext(os.path.basename(a.source))[0]

    with open(a.output, "w", encoding="utf-8") as f:
        f.write(f"; GENERE par tools/sprgen.py depuis {a.source} - ne pas editer a la main.\n")
        f.write("; Sprites multicolores 12x21, 64 octets chacun, blocs consecutifs.\n")
        f.write("; Le premier doit etre aligne sur 64 octets (voir main.asm).\n")
        for name in order:
            f.write(f"sprite_{prefix}_{name}:\n")
            for b0, b1, b2 in encode(grids[name]):
                f.write(f"        !byte %{b0:08b}, %{b1:08b}, %{b2:08b}\n")
            f.write("        !byte 0                         ; remplissage a 64 octets\n")
    if a.preview:
        preview(a.preview, order, grids, prefix=prefix)


if __name__ == "__main__":
    main()
