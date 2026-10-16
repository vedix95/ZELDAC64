#!/usr/bin/env python3
"""
extract_nes_sprites.py
Extrait fidèlement les sprites originaux de The Legend of Zelda (NES 1986)
depuis la ROM 'zelda.nes' et les convertit en sprites C64 multicolores (8x16).

Génère / met à jour :
  - assets/link.txt
  - assets/enemies.txt
  - assets/extra.txt
"""

import os
import sys

def load_rom(path="zelda.nes"):
    if not os.path.exists(path):
        sys.exit(f"Erreur: '{path}' introuvable.")
    with open(path, "rb") as f:
        header = f.read(16)
        if header[:4] != b"NES\x1a":
            sys.exit(f"Erreur: '{path}' n'est pas une ROM iNES valide.")
        rom = f.read()
    return rom

# Tables de tuiles dans PRG-ROM
# Bank 2: 0x08000..0x0BFFF
# Bank 3: 0x0C000..0x0FFFF
def make_tile_readers(rom):
    def get_tile(base_offset, idx):
        off = base_offset + idx * 16
        tb = rom[off : off + 16]
        grid = []
        for y in range(8):
            row = []
            low = tb[y]
            high = tb[y + 8]
            for x in range(8):
                bit = 7 - x
                col = ((low >> bit) & 1) | (((high >> bit) & 1) << 1)
                row.append(col)
            grid.append(row)
        return grid

    # Bank 2: Common sprites (Link, items) à $807F
    b2_base = 0x807F
    # Bank 3: Surface sprites à $915B ($115B dans Bank 3 -> 0xC000 + 0x115B)
    b3_surface = 0xC000 + 0x115B - 0x8E * 16
    # Bank 3: Dungeon common sprites à $9CBB ($1CBB dans Bank 3 -> 0xC000 + 0x1CBB)
    b3_dungeon = 0xC000 + 0x1CBB - 0x8E * 16
    # Bank 3: Dungeon 127 sprites à $9DBB ($1DBB dans Bank 3 -> 0xC000 + 0x1DBB)
    b3_d127 = 0xC000 + 0x1DBB - 0x8E * 16
    # Bank 3: Dungeon 358 sprites à $987B ($187B dans Bank 3 -> 0xC000 + 0x187B)
    b3_d358 = 0xC000 + 0x187B - 0x8E * 16
    # Bank 3: Dungeon 469 sprites à $9A9B ($1A9B dans Bank 3 -> 0xC000 + 0x1A9B)
    b3_d469 = 0xC000 + 0x1A9B - 0x8E * 16

    return {
        "b2": lambda idx: get_tile(b2_base, idx),
        "surface": lambda idx: get_tile(b3_surface, idx),
        "dungeon": lambda idx: get_tile(b3_dungeon, idx),
        "d127": lambda idx: get_tile(b3_d127, idx),
        "d358": lambda idx: get_tile(b3_d358, idx),
        "d469": lambda idx: get_tile(b3_d469, idx),
    }

def hflip(tile):
    return [r[::-1] for r in tile]

def vflip(tile):
    return tile[::-1]

def assemble(tl, tr, bl, br):
    return [tl[y] + tr[y] for y in range(8)] + [bl[y] + br[y] for y in range(8)]

def convert_16x16_to_8x16(s16):
    """
    Convertit un sprite NES 16x16 en grille C64 multicolore 8x16.
    Chaque paire de pixels horizontaux (2k, 2k+1) est condensée en 1 pixel C64 multicolore.
    Priorité des couleurs non-transparentes : 3 (détail/contour) > 2 (peau/visage) > 1 (corps/tunique).
    """
    CODE_MAP = {0: ".", 1: "g", 2: "s", 3: "b"}
    grid = []
    for row in s16:
        row8 = []
        for k in range(8):
            p0, p1 = row[2 * k], row[2 * k + 1]
            if p0 == p1:
                res = p0
            elif p0 == 0:
                res = p1
            elif p1 == 0:
                res = p0
            else:
                # Priorité aux détails visibles
                if 3 in (p0, p1) and 2 in (p0, p1):
                    res = 3 # pupille / contour sur peau
                elif 3 in (p0, p1) and 1 in (p0, p1):
                    res = 3 # ceinture / bordure sur corps
                elif 2 in (p0, p1) and 1 in (p0, p1):
                    res = 2 # visage / peau sur tunique
                else:
                    res = max(p0, p1)
            row8.append(CODE_MAP[res])
        grid.append("".join(row8))
    return grid

def main():
    rom = load_rom("zelda.nes")
    readers = make_tile_readers(rom)
    b2 = readers["b2"]
    sur = readers["surface"]
    dun = readers["dungeon"]
    d127 = readers["d127"]
    d358 = readers["d358"]
    d469 = readers["d469"]

    print("Extraction des sprites Link...")
    # Link Down
    link_down_0 = convert_16x16_to_8x16(assemble(b2(8), b2(10), b2(9), b2(11)))
    link_down_1 = convert_16x16_to_8x16(assemble(b2(8), b2(10), hflip(b2(11)), hflip(b2(9))))
    # Link Up
    link_up_0 = convert_16x16_to_8x16(assemble(b2(12), b2(14), b2(13), b2(15)))
    link_up_1 = convert_16x16_to_8x16(assemble(b2(12), b2(14), hflip(b2(15)), hflip(b2(13))))
    # Link Left (HFlip de Right)
    link_right_0_raw = assemble(b2(0), b2(2), b2(1), b2(3))
    link_right_1_raw = assemble(b2(16), b2(18), b2(17), b2(19))
    link_left_0 = convert_16x16_to_8x16([r[::-1] for r in link_right_0_raw])
    link_left_1 = convert_16x16_to_8x16([r[::-1] for r in link_right_1_raw])
    # Link Attack
    link_atk_down = convert_16x16_to_8x16(assemble(b2(8), b2(10), b2(9), b2(11))) # posture d'attaque face
    link_atk_up = convert_16x16_to_8x16(assemble(b2(12), b2(14), b2(13), b2(15)))   # posture d'attaque dos
    link_atk_right_raw = assemble(b2(0x14), b2(0x16), b2(0x15), b2(0x17))
    link_atk_left = convert_16x16_to_8x16([r[::-1] for r in link_atk_right_raw])

    # Lecture du fichier link.txt existant pour conserver les armes/objets pad 0 0
    link_frames = {
        "down_0": link_down_0,
        "down_1": link_down_1,
        "up_0": link_up_0,
        "up_1": link_up_1,
        "left_0": link_left_0,
        "left_1": link_left_1,
        "attack_down": link_atk_down,
        "attack_up": link_atk_up,
        "attack_left": link_atk_left,
    }

    # Mise à jour assets/link.txt
    update_asset_file("assets/link.txt", link_frames)
    print("  -> assets/link.txt mis à jour.")

    # -------------------------------------------------------------
    # Extraction des ennemis
    print("Extraction des sprites Ennemis...")
    enemy_frames = {}

    # Octorok
    octo_d0 = convert_16x16_to_8x16(assemble(sur(0xB0), hflip(sur(0xB0)), sur(0xB1), hflip(sur(0xB1))))
    octo_d1 = convert_16x16_to_8x16(assemble(sur(0xB2), hflip(sur(0xB2)), sur(0xB3), hflip(sur(0xB3))))
    # Vue de dos Octorok (corps uni sans yeux ni trompe)
    octo_u0 = [r.replace("s", "g").replace("b", "g") if i < 12 else r for i, r in enumerate(octo_d0)]
    octo_u1 = [r.replace("s", "g").replace("b", "g") if i < 12 else r for i, r in enumerate(octo_d1)]
    # Profil gauche
    octo_l0 = convert_16x16_to_8x16(assemble(sur(0xB4), sur(0xB6), sur(0xB5), sur(0xB7)))
    octo_l1 = convert_16x16_to_8x16(assemble(sur(0xB8), sur(0xBA), sur(0xB9), sur(0xBB)))
    enemy_frames["octo_down_0"] = octo_d0
    enemy_frames["octo_down_1"] = octo_d1
    enemy_frames["octo_up_0"] = octo_u0
    enemy_frames["octo_up_1"] = octo_u1
    enemy_frames["octo_left_0"] = octo_l0
    enemy_frames["octo_left_1"] = octo_l1

    # Moblin
    mob_d0 = convert_16x16_to_8x16(assemble(sur(0xF0), sur(0xF2), sur(0xF1), sur(0xF3)))
    mob_d1 = convert_16x16_to_8x16(assemble(sur(0xF4), sur(0xF6), sur(0xF5), sur(0xF7)))
    mob_u0 = [r.replace("s", "g").replace("b", "g") if i < 10 else r for i, r in enumerate(mob_d0)]
    mob_u1 = [r.replace("s", "g").replace("b", "g") if i < 10 else r for i, r in enumerate(mob_d1)]
    mob_l0 = convert_16x16_to_8x16(assemble(sur(0xF8), sur(0xFA), sur(0xF9), sur(0xFB)))
    mob_l1 = convert_16x16_to_8x16(assemble(sur(0xFC), sur(0xFE), sur(0xFD), sur(0xFF)))
    enemy_frames["moblin_down_0"] = mob_d0
    enemy_frames["moblin_down_1"] = mob_d1
    enemy_frames["moblin_up_0"] = mob_u0
    enemy_frames["moblin_up_1"] = mob_u1
    enemy_frames["moblin_left_0"] = mob_l0
    enemy_frames["moblin_left_1"] = mob_l1

    # Tektite
    tek_0 = convert_16x16_to_8x16(assemble(sur(0xCA), hflip(sur(0xCA)), sur(0xCB), hflip(sur(0xCB))))
    tek_1 = convert_16x16_to_8x16(assemble(sur(0xCC), hflip(sur(0xCC)), sur(0xCD), hflip(sur(0xCD))))
    enemy_frames["tektite_0"] = tek_0
    enemy_frames["tektite_1"] = tek_1

    # Leever (tournoiement actif, tuiles C2/C3 et C4/C5)
    leever_0 = convert_16x16_to_8x16(assemble(sur(0xC2), hflip(sur(0xC2)), sur(0xC3), hflip(sur(0xC3))))
    leever_1 = convert_16x16_to_8x16(assemble(sur(0xC4), hflip(sur(0xC4)), sur(0xC5), hflip(sur(0xC5))))
    enemy_frames["leever_0"] = leever_0
    enemy_frames["leever_1"] = leever_1

    # Peahat
    pea_0 = convert_16x16_to_8x16(assemble(sur(0xC6), hflip(sur(0xC6)), sur(0xC7), hflip(sur(0xC7))))
    pea_1 = convert_16x16_to_8x16(assemble(sur(0xC8), hflip(sur(0xC8)), sur(0xC9), hflip(sur(0xC9))))
    enemy_frames["peahat_0"] = pea_0
    enemy_frames["peahat_1"] = pea_1

    # Armos
    arm_0 = convert_16x16_to_8x16(assemble(sur(0xA0), sur(0xA2), sur(0xA1), sur(0xA3)))
    arm_1 = convert_16x16_to_8x16(assemble(sur(0xA4), sur(0xA6), sur(0xA5), sur(0xA7)))
    enemy_frames["armos_0"] = arm_0
    enemy_frames["armos_1"] = arm_1

    # Ghini
    ghi_0 = convert_16x16_to_8x16(assemble(sur(0xE0), sur(0xE2), sur(0xE1), sur(0xE3)))
    ghi_1 = convert_16x16_to_8x16(assemble(sur(0xE4), sur(0xE6), sur(0xE5), sur(0xE7)))
    enemy_frames["ghini_0"] = ghi_0
    enemy_frames["ghini_1"] = ghi_1

    # Zora
    zora_0 = convert_16x16_to_8x16(assemble(sur(0xEC), hflip(sur(0xEC)), sur(0xED), hflip(sur(0xED))))
    zora_1 = convert_16x16_to_8x16(assemble(sur(0xEE), hflip(sur(0xEE)), sur(0xEF), hflip(sur(0xEF))))
    enemy_frames["zora_0"] = zora_0
    enemy_frames["zora_1"] = zora_1

    # Lynel (Face CE/D0/CF/D1 et Profil D6/D8/D7/D9)
    lynel_0 = convert_16x16_to_8x16(assemble(sur(0xD6), sur(0xD8), sur(0xD7), sur(0xD9))) # Face
    lynel_1 = convert_16x16_to_8x16(assemble(sur(0xCE), sur(0xD0), sur(0xCF), sur(0xD1))) # Profil galop
    enemy_frames["lynel_0"] = lynel_0
    enemy_frames["lynel_1"] = lynel_1

    # Donjon : Keese
    keese_0 = convert_16x16_to_8x16(assemble(dun(0x9A), hflip(dun(0x9A)), dun(0x9B), hflip(dun(0x9B))))
    keese_1 = convert_16x16_to_8x16(assemble(dun(0x9C), hflip(dun(0x9C)), dun(0x9D), hflip(dun(0x9D))))
    enemy_frames["keese_0"] = keese_0
    enemy_frames["keese_1"] = keese_1

    # Donjon : Trap
    trap = convert_16x16_to_8x16(assemble(dun(0x96), hflip(dun(0x96)), dun(0x97), hflip(dun(0x97))))
    enemy_frames["trap"] = trap

    # Donjon : Rope
    rope_0 = convert_16x16_to_8x16(assemble(d127(0xA0), d127(0xA2), d127(0xA1), d127(0xA3)))
    rope_1 = convert_16x16_to_8x16(assemble(d127(0xA4), d127(0xA6), d127(0xA5), d127(0xA7)))
    enemy_frames["rope_0"] = rope_0
    enemy_frames["rope_1"] = rope_1

    # Donjon : Stalfos
    stalfos_0 = convert_16x16_to_8x16(assemble(d127(0xA8), d127(0xAA), d127(0xA9), d127(0xAB)))
    stalfos_1 = [r[::-1] for r in stalfos_0]
    enemy_frames["stalfos_0"] = stalfos_0
    enemy_frames["stalfos_1"] = stalfos_1

    # Donjon : Darknut
    dk_0 = convert_16x16_to_8x16(assemble(d358(0xAC), d358(0xAE), d358(0xAD), d358(0xAF)))
    dk_1 = convert_16x16_to_8x16(assemble(d358(0xB0), d358(0xB2), d358(0xB1), d358(0xB3)))
    enemy_frames["darknut_0"] = dk_0
    enemy_frames["darknut_1"] = dk_1

    # Donjon : Pols Voice
    pv_0 = convert_16x16_to_8x16(assemble(d358(0xA0), hflip(d358(0xA0)), d358(0xA1), hflip(d358(0xA1))))
    pv_1 = convert_16x16_to_8x16(assemble(d358(0xA2), hflip(d358(0xA2)), d358(0xA3), hflip(d358(0xA3))))
    enemy_frames["polsvoice_0"] = pv_0
    enemy_frames["polsvoice_1"] = pv_1

    # Donjon : Gibdo
    gb_0 = convert_16x16_to_8x16(assemble(d358(0xA4), d358(0xA6), d358(0xA5), d358(0xA7)))
    gb_1 = [r[::-1] for r in gb_0]
    enemy_frames["gibdo_0"] = gb_0
    enemy_frames["gibdo_1"] = gb_1

    # Donjon : Like Like
    ll_0 = convert_16x16_to_8x16(assemble(d469(0xA2), hflip(d469(0xA2)), d469(0xA3), hflip(d469(0xA3))))
    ll_1 = convert_16x16_to_8x16(assemble(d469(0xA4), hflip(d469(0xA4)), d469(0xA5), hflip(d469(0xA5))))
    enemy_frames["likelike_0"] = ll_0
    enemy_frames["likelike_1"] = ll_1

    # Donjon : Vire
    vire_0 = convert_16x16_to_8x16(assemble(d469(0xAC), hflip(d469(0xAC)), d469(0xAD), hflip(d469(0xAD))))
    vire_1 = convert_16x16_to_8x16(assemble(d469(0xAE), hflip(d469(0xAE)), d469(0xAF), hflip(d469(0xAF))))
    enemy_frames["vire_0"] = vire_0
    enemy_frames["vire_1"] = vire_1

    # Donjon : Wizzrobe
    wz_0 = convert_16x16_to_8x16(assemble(d469(0xB4), d469(0xB6), d469(0xB5), d469(0xB7)))
    wz_1 = convert_16x16_to_8x16(assemble(d469(0xB8), d469(0xBA), d469(0xB9), d469(0xBB)))
    enemy_frames["wizzrobe_0"] = wz_0
    enemy_frames["wizzrobe_1"] = wz_1

    # Mise à jour assets/enemies.txt
    update_asset_file("assets/enemies.txt", enemy_frames)
    print("  -> assets/enemies.txt mis à jour.")

    # -------------------------------------------------------------
    # Extraction des extras (Old Man, Merchant, Old Woman)
    print("Extraction des sprites Extra...")
    extra_frames = {}
    old_man = convert_16x16_to_8x16(assemble(sur(0x98), hflip(sur(0x98)), sur(0x99), hflip(sur(0x99))))
    merchant = convert_16x16_to_8x16(assemble(sur(0x9C), hflip(sur(0x9C)), sur(0x9D), hflip(sur(0x9D))))
    old_woman = convert_16x16_to_8x16(assemble(sur(0x9A), hflip(sur(0x9A)), sur(0x9B), hflip(sur(0x9B))))

    extra_frames["old_man"] = old_man
    extra_frames["merchant"] = merchant
    extra_frames["old_woman"] = old_woman

    update_asset_file("assets/extra.txt", extra_frames)
    print("  -> assets/extra.txt mis à jour.")

    print("Extraction terminée avec succès !")

def update_asset_file(path, replacements):
    """
    Met à jour les blocs d'images [nom] dans un fichier .txt d'assets,
    en préservant les lignes de commentaires, pad, mirror, et les blocs non remplacés.
    """
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    lines = content.splitlines()
    out = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.startswith("["):
            head, _, rest = line.partition("]")
            name = head[1:].strip()
            tokens = rest.split()
            # Si cette image a un remplacement
            if name in replacements:
                # Écrire l'en-tête (avec mirror ou pad si existant)
                out.append(line)
                # Sauter les anciennes lignes de données d'image jusqu'à une ligne vide ou un nouveau [
                i += 1
                while i < len(lines) and lines[i].strip() and not lines[i].startswith("[") and not lines[i].startswith("#"):
                    i += 1
                # Écrire les nouvelles lignes
                for r in replacements[name]:
                    out.append(r)
                continue
        out.append(line)
        i += 1

    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")

if __name__ == "__main__":
    main()
