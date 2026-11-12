#!/usr/bin/env python3
"""
tools/generate_intro_items_sprites.py
Génère src/intro_items_sprites.asm contenant l'intégralité des 27 motifs de sprites
d'objets authentiques (16x16 convertis en 24x21 C64 multicolores, 64 octets par bloc)
et les tables de pointeurs/couleurs pour le défilé des 35 trésors de l'introduction.
"""
import os
import sys

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
ASSETS_DIR = os.path.join(BASE_DIR, "assets")
SRC_DIR = os.path.join(BASE_DIR, "src")
TOOLS_DIR = os.path.join(BASE_DIR, "tools")
sys.path.insert(0, TOOLS_DIR)

from sprgen import parse, to_grid, encode

# Palette C64 codes:
# . = 0 (transp), s = 1 (MC1 = COL_WHITE), g = 2 (VIC_SPRITE_COL), b = 3 (MC2 = COL_BROWN / COL_BLACK)

# 1. Objets existants dans assets/extra.txt et assets/link.txt
_, extra_frames = parse(os.path.join(ASSETS_DIR, "extra.txt"))
_, link_frames = parse(os.path.join(ASSETS_DIR, "link.txt"))

# 2. Objets sur mesure dessinés au pixel près selon la ROM NES zelda.nes (format 8x16, proportions carrées 1:1)
custom_ascii = {
    "item_heart_cont": [
        "..bb..bb",
        ".bggbbgb",
        "bggssggb",
        "bgs..sgb",
        "bgssssgb",
        "bgssssgb",
        ".bgssgb.",
        "..bggb..",
        "...bb..."
    ],
    "item_fairy": [
        "..ssss..",
        ".ssssss.",
        "bbssssbb",
        "bb.ss.bb",
        "b..ss..b",
        "b.gggg.b",
        "..gggg..",
        ".gssssg.",
        ".gssssg.",
        "g..ss..g",
        "...ss..."
    ],
    "item_clock": [
        "..bbbb..",
        ".bssssb.",
        "bssssssb",
        "bsssggsb",
        "bsssggsb",
        "bssggggb",
        "bssssssb",
        "bssssssb",
        ".bssssb.",
        "..bbbb.."
    ],
    "item_rupee": [
        "..bbbb..",
        ".bggggb.",
        "bggssggb",
        "bgssssgb",
        "bgssssgb",
        "bgssssgb",
        "bgssssgb",
        "bgssssgb",
        "bggssggb",
        ".bggggb.",
        "..bbbb.."
    ],
    "item_letter": [
        ".bbbbbb.",
        "bssssssb",
        "bsbbsssb",
        "bs.bb.sb",
        "bs..b.sb",
        "bs.bb.sb",
        "bssssssb",
        ".bbbbbb."
    ],
    "item_map": [
        ".bbbbbb.",
        "bssssssb",
        "bsbbbbsb",
        "bsb..bsb",
        "bsbbbbsb",
        "bs....sb",
        "bssssssb",
        ".bbbbbb."
    ],
    "item_compass": [
        "..bbbb..",
        ".bssssb.",
        "bssssssb",
        "bssbbssb",
        "bsbggbsb",
        "bsbggbsb",
        "bssbbssb",
        "bssssssb",
        ".bssssb.",
        "..bbbb.."
    ]
}

# Nettoie les 'h' de frappe éventuels
for k in custom_ascii:
    custom_ascii[k] = [r.replace('h', 's') for r in custom_ascii[k]]

# Dictionnaire complet des 27 formes uniques d'objets
ITEM_SHAPES = [
    ("item_heart_cont", "custom"),
    ("item_heart",      "extra"),
    ("item_fairy",      "custom"),
    ("item_clock",      "custom"),
    ("item_rupee",      "custom"),
    ("item_potion",     "extra"),
    ("item_letter",     "custom"),
    ("item_food",       "extra"),
    ("item_sword",      "extra"),
    ("item_shield",     "extra"),
    ("item_boomerang",  "link"),
    ("item_bomb",       "link"),
    ("item_bow",        "link"),
    ("proj_arrow_v",    "link"),
    ("item_candle",     "link"),
    ("item_ring",       "extra"),
    ("item_bracelet",   "extra"),
    ("item_whistle",    "extra"),
    ("item_raft",       "extra"),
    ("item_stepladder", "extra"),
    ("item_wand",       "extra"),
    ("item_book",       "extra"),
    ("item_key",        "extra"),
    ("item_magic_key",  "extra"),
    ("item_map",        "custom"),
    ("item_compass",    "custom"),
    ("item_triforce",   "extra"),
]

def get_shape_bytes(name, source):
    if source == "custom":
        rows = custom_ascii[name]
        w = len(rows[0])
        h = len(rows)
        grid = to_grid({"rows": rows, "pad": ((12 - w) // 2, 2)})
    elif source == "extra":
        entry = dict(extra_frames[name])
        rows = entry["rows"]
        w = len(rows[0])
        h = len(rows)
        entry["pad"] = ((12 - w) // 2, 2)
        grid = to_grid(entry)
    elif source == "link":
        entry = dict(link_frames[name])
        rows = entry["rows"]
        w = len(rows[0])
        h = len(rows)
        entry["pad"] = ((12 - w) // 2, 2)
        grid = to_grid(entry)
    encoded_rows = encode(grid) # 21 rows of 3 bytes = 63 bytes
    flat = []
    for r in encoded_rows:
        flat.extend(r)
    while len(flat) < 64:
        flat.append(0)
    return flat

def main():
    out_path = os.path.join(SRC_DIR, "intro_items_sprites.asm")
    lines = []
    lines.append("; ===========================================================================")
    lines.append("; intro_items_sprites.asm : 27 Motifs de Sprites Authentiques des Tresors")
    lines.append("; Généré automatiquement par tools/generate_intro_items_sprites.py")
    lines.append("; Placés en RAM $2800..$2EBF (Blocs de Sprites VIC-II $A0..$BA)")
    lines.append("; ===========================================================================")
    lines.append("")
    lines.append("* = $2800")
    lines.append("intro_item_sprites_start:")
    lines.append("")

    shape_block_map = {}
    base_block = 0xA0  # $2800 / 64 = 160 ($A0)

    for idx, (name, src) in enumerate(ITEM_SHAPES):
        block_idx = base_block + idx
        shape_block_map[name] = block_idx
        b_data = get_shape_bytes(name, src)
        lines.append(f"; --- Motif {idx:02d}: {name} (Bloc ${block_idx:02X}) ---")
        lines.append(f"spr_item_{name}:")
        for r in range(0, 64, 8):
            chunk = b_data[r:r+8]
            lines.append("        !byte " + ", ".join([f"${b:02x}" for b in chunk]))
        lines.append("")

    lines.append(f"!if * > $3000 {{ !error \"intro_items_sprites deborde au-dela de $3000\" }}")
    lines.append("")

    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")

    tr_l_entries = [
        ("item_heart_cont", "COL_RED"),
        ("item_fairy",      "COL_WHITE"),
        ("item_rupee",      "COL_YELLOW"),
        ("item_potion",     "COL_CYAN"),
        ("item_letter",     "COL_WHITE"),
        ("item_sword",      "COL_BROWN"),
        ("item_sword",      "COL_CYAN"),
        ("item_boomerang",  "COL_CYAN"),
        ("item_bomb",       "COL_GREY"),
        ("proj_arrow_v",    "COL_CYAN"),
        ("item_candle",     "COL_RED"),
        ("item_ring",       "COL_RED"),
        ("item_bracelet",   "COL_ORANGE"),
        ("item_raft",       "COL_BROWN"),
        ("item_wand",       "COL_CYAN"),
        ("item_magic_key",  "COL_YELLOW"),
        ("item_map",        "COL_YELLOW"),
        ("item_triforce",   "COL_YELLOW"),
    ]

    tr_r_entries = [
        ("item_heart",      "COL_RED"),
        ("item_clock",      "COL_YELLOW"),
        ("item_rupee",      "COL_CYAN"),
        ("item_potion",     "COL_RED"),
        ("item_food",       "COL_BROWN"),
        ("item_sword",      "COL_WHITE"),
        ("item_shield",     "COL_RED"),
        ("item_boomerang",  "COL_YELLOW"),
        ("item_bow",        "COL_BROWN"),
        ("proj_arrow_v",    "COL_BROWN"),
        ("item_candle",     "COL_CYAN"),
        ("item_ring",       "COL_CYAN"),
        ("item_whistle",    "COL_CYAN"),
        ("item_stepladder", "COL_GREY"),
        ("item_book",       "COL_ORANGE"),
        ("item_key",        "COL_GREY"),
        ("item_compass",    "COL_CYAN"),
        ("item_triforce",   "COL_YELLOW"),
    ]

    tbl_path = os.path.join(SRC_DIR, "intro_items_tables.inc")
    tbl_lines = [
        "; ===========================================================================",
        "; intro_items_tables.inc : Tables de sprites et couleurs pour les 35 tresors",
        "; ===========================================================================",
        "",
        "tr_l_spr_blocks:",
        "        !byte " + ", ".join([f"${shape_block_map[s]:02X}" for s, c in tr_l_entries]),
        "tr_l_spr_colors:",
        "        !byte " + ", ".join([c for s, c in tr_l_entries]),
        "",
        "tr_r_spr_blocks:",
        "        !byte " + ", ".join([f"${shape_block_map[s]:02X}" for s, c in tr_r_entries]),
        "tr_r_spr_colors:",
        "        !byte " + ", ".join([c for s, c in tr_r_entries]),
        ""
    ]
    with open(tbl_path, "w", encoding="utf-8") as f:
        f.write("\n".join(tbl_lines) + "\n")

    print(f"[✓] {out_path} et {tbl_path} générés avec succès ({len(ITEM_SHAPES)} sprites).")

if __name__ == "__main__":
    main()
