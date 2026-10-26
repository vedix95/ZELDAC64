#!/usr/bin/env python3
"""
tools/build_sprite_banks.py : Génère les banques cartouche binaires de sprites
et la table des pointeurs de sprites (build/sprite_ptrs.inc)
  - build/sprites_ow.bin   : Banque 10 (Sprites Ennemis Overworld + Radeau)
  - build/sprites_dung.bin : Banque 11 (Sprites Ennemis Donjons + Bosses)
  - build/sprites_boss.bin : Banque 12 (Sprites Boss Donjons dédiés)
  - build/sprites_npc.bin  : Banque 13 (Sprites PNJs, Grottes, Trésors, Échelle)
Chaque banque fait exactement 8192 octets (1 banque cartouche Magic Desk).
"""

import os
import sys

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
ASSETS_DIR = os.path.join(BASE_DIR, "assets")
BLD_DIR = os.path.join(BASE_DIR, "build")
TOOLS_DIR = os.path.join(BASE_DIR, "tools")
sys.path.insert(0, TOOLS_DIR)

from sprgen import parse, to_grid, encode

BANK_SIZE = 8192
BASE_PTR = 0xA0 # $2800 / 64

# Sprites communs fixes aux slots 87..95 ($F7..$FF)
COMMON_SLOTS = {
    87: ('item_get', 'extra', 'SPR_COMMON_ITEM_GET'),
    88: ('enemy_death_0', 'enemies', 'SPR_COMMON_DEATH_0'),
    89: ('enemy_death_1', 'enemies', 'SPR_COMMON_DEATH_1'),
    90: ('proj_fireball', 'enemies', 'SPR_COMMON_FIREBALL'),
    91: ('proj_magic', 'enemies', 'SPR_COMMON_MAGIC'),
    92: ('proj_boom_en', 'enemies', 'SPR_COMMON_BOOM_EN'),
    93: ('item_heart', 'extra', 'SPR_COMMON_HEART'),
    94: ('item_key', 'extra', 'SPR_COMMON_KEY'),
    95: ('item_triforce', 'extra', 'SPR_COMMON_TRIFORCE'),
}

OW_NAMES = [
    'octo_down_0', 'octo_down_1', 'octo_up_0', 'octo_up_1',
    'octo_left_0', 'octo_left_1', 'octo_right_0', 'octo_right_1', 'octo_rock',
    'moblin_down_0', 'moblin_down_1', 'moblin_up_0', 'moblin_up_1',
    'moblin_left_0', 'moblin_left_1', 'moblin_right_0', 'moblin_right_1',
    'moblin_spear_h', 'moblin_spear_v',
    'tektite_0', 'tektite_1', 'leever_0', 'leever_1', 'peahat_0', 'peahat_1',
    'armos_0', 'armos_1', 'ghini_0', 'ghini_1', 'zora_0', 'zora_1', 'lynel_0', 'lynel_1',
    'item_raft',
]

DUNG_NAMES = [
    'keese_0', 'keese_1', 'zol_0', 'zol_1', 'gel',
    'rope_0', 'rope_1', 'stalfos_0', 'stalfos_1',
    'goriya_0', 'goriya_1', 'darknut_0', 'darknut_1',
    'wizzrobe_0', 'wizzrobe_1', 'wallmaster_0', 'wallmaster_1',
    'likelike_0', 'likelike_1', 'polsvoice_0', 'polsvoice_1',
    'gibdo_0', 'gibdo_1', 'vire_0', 'vire_1', 'bubble_0', 'bubble_1', 'trap',
    'lanmola_head', 'lanmola_body',
    # Bosses
    'aquamentus_0', 'aquamentus_1',
    'dodongo_0', 'dodongo_1',
    'manhandla_core', 'manhandla_jaw',
    'gleeok_0', 'gleeok_1',
    'digdogger',
    'gohma_closed', 'gohma_open',
    'patra_center', 'patra_orb',
    'ganon_0', 'ganon_1',
]

BOSS_NAMES = [
    'aquamentus_0', 'aquamentus_1',
    'dodongo_0', 'dodongo_1',
    'manhandla_core', 'manhandla_jaw',
    'gleeok_0', 'gleeok_1',
    'digdogger',
    'gohma_closed', 'gohma_open',
    'patra_center', 'patra_orb',
    'ganon_0', 'ganon_1',
]

NPC_NAMES = [
    'old_man', 'merchant', 'old_woman', 'moblin_down_0',
    'item_shield', 'item_ring',
    'item_food', 'item_potion', 'item_whistle', 'item_wand',
    'item_raft', 'item_stepladder'
]

def encode_sprite(frame):
    grid = to_grid(frame)
    data = bytearray()
    for b0, b1, b2 in encode(grid):
        data.extend([b0, b1, b2])
    data.append(0) # 64e octet
    return data

def build_bank(names, en_frames, ex_frames):
    bank = bytearray(BANK_SIZE)
    ptrs = {}

    # 1. Écrit les sprites spécifiques aux slots 0..N-1
    for slot, name in enumerate(names):
        frame = en_frames.get(name) or ex_frames.get(name)
        if not frame:
            raise ValueError(f"Sprite '{name}' introuvable !")
        spr_bytes = encode_sprite(frame)
        offset = slot * 64
        bank[offset : offset + 64] = spr_bytes
        ptrs[name] = BASE_PTR + slot

    # 2. Écrit les sprites communs aux slots fixes 87..95
    for slot, (name, src_kind, _) in COMMON_SLOTS.items():
        frames_dict = en_frames if src_kind == 'enemies' else ex_frames
        frame = frames_dict.get(name)
        if frame:
            spr_bytes = encode_sprite(frame)
            offset = slot * 64
            bank[offset : offset + 64] = spr_bytes

    return bank, ptrs

def main():
    os.makedirs(BLD_DIR, exist_ok=True)
    _, en_frames = parse(os.path.join(ASSETS_DIR, "enemies.txt"))
    _, ex_frames = parse(os.path.join(ASSETS_DIR, "extra.txt"))

    # 1. Overworld
    ow_bank, ow_ptrs = build_bank(OW_NAMES, en_frames, ex_frames)
    p_ow = os.path.join(BLD_DIR, "sprites_ow.bin")
    with open(p_ow, "wb") as f:
        f.write(ow_bank)
    print(f"  [+] Banque Sprites Overworld générée : {p_ow} ({len(OW_NAMES)} slots)")

    # 2. Donjon
    dung_bank, dung_ptrs = build_bank(DUNG_NAMES, en_frames, ex_frames)
    p_dung = os.path.join(BLD_DIR, "sprites_dung.bin")
    with open(p_dung, "wb") as f:
        f.write(dung_bank)
    print(f"  [+] Banque Sprites Donjon générée    : {p_dung} ({len(DUNG_NAMES)} slots)")

    # 3. Boss
    boss_bank, boss_ptrs = build_bank(BOSS_NAMES, en_frames, ex_frames)
    p_boss = os.path.join(BLD_DIR, "sprites_boss.bin")
    with open(p_boss, "wb") as f:
        f.write(boss_bank)
    print(f"  [+] Banque Sprites Boss générée      : {p_boss} ({len(BOSS_NAMES)} slots)")

    # 4. PNJ & Grottes
    npc_bank, npc_ptrs = build_bank(NPC_NAMES, en_frames, ex_frames)
    p_npc = os.path.join(BLD_DIR, "sprites_npc.bin")
    with open(p_npc, "wb") as f:
        f.write(npc_bank)
    print(f"  [+] Banque Sprites PNJ générée       : {p_npc} ({len(NPC_NAMES)} slots)")

    # 5. Génère sprite_ptrs.inc
    inc_lines = [
        "; ---------------------------------------------------------------------------\n",
        "; sprite_ptrs.inc : Constantes des pointeurs de sprites VIC-II Bank 0\n",
        "; GENERE AUTOMATIQUEMENT par tools/build_sprite_banks.py\n",
        "; Ne pas modifier manuellement.\n",
        "; ---------------------------------------------------------------------------\n\n",
        "; --- Sprites communs ($F7..$FF) valides dans toutes les banques ---\n"
    ]
    for slot, (name, _, sym) in sorted(COMMON_SLOTS.items()):
        ptr = BASE_PTR + slot
        inc_lines.append(f"{sym:32s} = ${ptr:02x}\n")

    inc_lines.append("\n; --- Sprites Overworld ($A0..$EF) ---\n")
    for name, ptr in sorted(ow_ptrs.items()):
        sym = f"SPR_OW_{name.upper()}"
        inc_lines.append(f"{sym:32s} = ${ptr:02x}\n")

    inc_lines.append("\n; --- Sprites Donjons & Bosses ($A0..$EF) ---\n")
    for name, ptr in sorted(dung_ptrs.items()):
        sym = f"SPR_DUNG_{name.upper()}"
        inc_lines.append(f"{sym:32s} = ${ptr:02x}\n")

    inc_lines.append("\n; --- Sprites PNJs & Grottes ($A0..$EF) ---\n")
    for name, ptr in sorted(npc_ptrs.items()):
        sym = f"SPR_NPC_{name.upper()}"
        inc_lines.append(f"{sym:32s} = ${ptr:02x}\n")

    inc_lines.append("\n; --- Alias de compatibilité d'adresses (Pointeur * 64) ---\n")
    compat = [
        ("sprite_link_item_triforce", "SPR_COMMON_TRIFORCE"),
        ("sprite_link_item_key", "SPR_COMMON_KEY"),
        ("sprite_link_item_heart", "SPR_COMMON_HEART"),
        ("sprite_link_item_ring", "SPR_NPC_ITEM_RING"),
        ("sprite_link_item_food", "SPR_NPC_ITEM_FOOD"),
        ("sprite_link_item_shield", "SPR_NPC_ITEM_SHIELD"),
        ("sprite_link_item_whistle", "SPR_NPC_ITEM_WHISTLE"),
        ("sprite_link_old_man", "SPR_NPC_OLD_MAN"),
        ("sprite_link_merchant", "SPR_NPC_MERCHANT"),
        ("sprite_link_old_woman", "SPR_NPC_OLD_WOMAN"),
        ("sprite_link_item_wand", "SPR_NPC_ITEM_WAND"),
        ("sprite_link_item_potion", "SPR_NPC_ITEM_POTION"),
        ("sprite_link_item_raft", "SPR_OW_ITEM_RAFT"),
        ("sprite_link_item_stepladder", "SPR_NPC_ITEM_STEPLADDER"),
        ("sprite_link_item_get", "SPR_COMMON_ITEM_GET"),
        ("sprite_enemies_moblin_down_0", "SPR_NPC_MOBLIN_DOWN_0"),
    ]
    for lbl, cst in compat:
        inc_lines.append(f"{lbl:32s} = {cst} * 64\n")

    p_inc = os.path.join(BLD_DIR, "sprite_ptrs.inc")
    with open(p_inc, "w", encoding="utf-8") as f:
        f.writelines(inc_lines)
    print(f"  [+] Fichier d'inclusion généré       : {p_inc}")

if __name__ == "__main__":
    main()
