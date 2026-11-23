#!/usr/bin/env python3
"""
Génère build/cart_link_shield.bin (Banque 33, 1536 octets) :
  - $0000..$02FF (768 o) : 12 sprites Link (Petit Bouclier, assets/link.txt)
  - $0300..$05FF (768 o) : 12 sprites Link (Bouclier Magique, assets/link_magic_shield.txt)
"""
import os
import sys

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(BASE_DIR, "tools"))
import sprgen

NAMES = [
    "down_0", "down_1", "up_0", "up_1",
    "left_0", "left_1", "right_0", "right_1",
    "attack_down", "attack_up", "attack_left", "attack_right",
]


def encode_set(txt_path):
    _, frames = sprgen.parse(txt_path)
    out = bytearray()
    for name in NAMES:
        entry = frames[name]
        if "mirror" in entry:
            src = frames[entry["mirror"]]
            grid = [row[::-1] for row in sprgen.to_grid(src)]
        else:
            grid = sprgen.to_grid(entry)
        sprgen.apply_shadow(grid, sprgen.shadow_style_for(name))
        for row_bytes in sprgen.encode(grid):
            out.extend(row_bytes)
        out.append(0)  # 64e octet de padding VIC-II
    assert len(out) == 12 * 64, f"Taille inattendue pour {txt_path}: {len(out)}"
    return bytes(out)


def main():
    small_data = encode_set(os.path.join(BASE_DIR, "assets", "link.txt"))
    magic_data = encode_set(os.path.join(BASE_DIR, "assets", "link_magic_shield.txt"))
    out_path = os.path.join(BASE_DIR, "build", "cart_link_shield.bin")
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "wb") as f:
        f.write(small_data)
        f.write(magic_data)
    print(f"OK : {out_path} ({len(small_data) + len(magic_data)} octets : Small 768o + Magic 768o)")


if __name__ == "__main__":
    main()
