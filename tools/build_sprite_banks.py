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

# Sprites communs fixes aux slots 75..95 ($EB..$FF) présents dans TOUTES les banques
COMMON_SLOTS = {
    75: ('moblin_down_0', 'enemies', 'SPR_NPC_MOBLIN_DOWN_0'),
    76: ('old_man', 'extra', 'SPR_NPC_OLD_MAN'),
    77: ('merchant', 'extra', 'SPR_NPC_MERCHANT'),
    78: ('old_woman', 'extra', 'SPR_NPC_OLD_WOMAN'),
    79: ('item_shield', 'extra', 'SPR_NPC_ITEM_SHIELD'),
    80: ('item_ring', 'extra', 'SPR_NPC_ITEM_RING'),
    81: ('item_food', 'extra', 'SPR_NPC_ITEM_FOOD'),
    82: ('item_potion', 'extra', 'SPR_NPC_ITEM_POTION'),
    83: ('item_whistle', 'extra', 'SPR_NPC_ITEM_WHISTLE'),
    84: ('item_wand', 'extra', 'SPR_NPC_ITEM_WAND'),
    85: ('item_raft', 'extra', 'SPR_NPC_ITEM_RAFT'),
    86: ('item_stepladder', 'extra', 'SPR_NPC_ITEM_STEPLADDER'),
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
    'armos_0', 'armos_1', 'ghini_0', 'ghini_1', 'zora_0', 'zora_1',
    'lynel_down_0', 'lynel_down_1', 'lynel_up_0', 'lynel_up_1',
    'lynel_left_0', 'lynel_left_1', 'lynel_right_0', 'lynel_right_1',
    'item_raft',
]

DUNG_NAMES = [
    'keese_0', 'keese_1', 'zol_0', 'zol_1', 'gel',
    'rope_0', 'rope_1', 'stalfos_0', 'stalfos_1',
    'goriya_down_0', 'goriya_down_1',
    'goriya_up_0', 'goriya_up_1',
    'goriya_left_0', 'goriya_left_1',
    'goriya_right_0', 'goriya_right_1',
    'darknut_down_0', 'darknut_down_1',
    'darknut_up_0', 'darknut_up_1',
    'darknut_left_0', 'darknut_left_1',
    'darknut_right_0', 'darknut_right_1',
    'wizzrobe_0', 'wizzrobe_1', 'wallmaster_0', 'wallmaster_1',
    'likelike_0', 'likelike_1', 'polsvoice_0', 'polsvoice_1',
    'gibdo_0', 'gibdo_1', 'vire_0', 'vire_1', 'bubble_0', 'bubble_1', 'trap',
    'lanmola_head', 'lanmola_body',
    # Bosses
    'aquamentus_0', 'aquamentus_1',
    'aquamentus_bot_0', 'aquamentus_bot_1',
    'dodongo_0', 'dodongo_1',
    'dodongo_back_0', 'dodongo_back_1',
    'dodongo_right_0', 'dodongo_right_1',
    'dodongo_right_f_0', 'dodongo_right_f_1',
    'dodongo_bloated_f', 'dodongo_bloated_b',
    'dodongo_bloated_r_f', 'dodongo_bloated_r_b',
    'manhandla_core', 'manhandla_jaw',
    'gleeok_0', 'gleeok_1',
    'digdogger',
    'gohma_closed', 'gohma_open',
    'patra_center', 'patra_orb',
    'ganon_tl_0', 'ganon_tr_0', 'ganon_bl_0', 'ganon_br_0',
    'ganon_tl_1', 'ganon_tr_1', 'ganon_bl_1', 'ganon_br_1',
]

BOSS_NAMES = [
    'aquamentus_0', 'aquamentus_1',
    'aquamentus_bot_0', 'aquamentus_bot_1',
    'dodongo_0', 'dodongo_1',
    'dodongo_back_0', 'dodongo_back_1',
    'dodongo_right_0', 'dodongo_right_1',
    'dodongo_right_f_0', 'dodongo_right_f_1',
    'dodongo_bloated_f', 'dodongo_bloated_b',
    'dodongo_bloated_r_f', 'dodongo_bloated_r_b',
    'manhandla_core', 'manhandla_jaw',
    'gleeok_0', 'gleeok_1',
    'digdogger',
    'gohma_closed', 'gohma_open',
    'patra_center', 'patra_orb',
    'ganon_tl_0', 'ganon_tr_0', 'ganon_bl_0', 'ganon_br_0',
    'ganon_tl_1', 'ganon_tr_1', 'ganon_bl_1', 'ganon_br_1',
]

NPC_NAMES = [
    'old_man', 'merchant', 'old_woman', 'moblin_down_0',
    'item_shield', 'item_ring',
    'item_food', 'item_potion', 'item_whistle', 'item_wand',
    'item_raft', 'item_stepladder',
    'item_sword', 'item_bracelet', 'item_book', 'item_magic_key',
    'tri_p1', 'tri_p2', 'tri_p3', 'tri_p4', 'tri_p5', 'tri_p6', 'tri_p7', 'tri_p8'
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
    inc_lines.append(f"{'SPR_OW_LYNEL_0':32s} = SPR_OW_LYNEL_DOWN_0\n")
    inc_lines.append(f"{'SPR_OW_LYNEL_1':32s} = SPR_OW_LYNEL_DOWN_1\n")

    inc_lines.append("\n; --- Sprites Donjons & Bosses ($A0..$EF) ---\n")
    for name, ptr in sorted(dung_ptrs.items()):
        sym = f"SPR_DUNG_{name.upper()}"
        inc_lines.append(f"{sym:32s} = ${ptr:02x}\n")
    inc_lines.append(f"{'SPR_DUNG_DARKNUT_0':32s} = SPR_DUNG_DARKNUT_DOWN_0\n")
    inc_lines.append(f"{'SPR_DUNG_DARKNUT_1':32s} = SPR_DUNG_DARKNUT_DOWN_1\n")
    inc_lines.append(f"{'SPR_DUNG_GANON_0':32s} = SPR_DUNG_GANON_TL_0\n")
    inc_lines.append(f"{'SPR_DUNG_GANON_1':32s} = SPR_DUNG_GANON_TL_1\n")

    common_syms = set(sym for _, _, sym in COMMON_SLOTS.values())
    inc_lines.append("\n; --- Sprites PNJ, Objets & Inventaire ($A0..$EF) ---\n")
    for name, ptr in sorted(npc_ptrs.items()):
        sym = f"SPR_NPC_{name.upper()}"
        if sym not in common_syms:
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
        ("sprite_link_item_raft", "SPR_NPC_ITEM_RAFT"),
        ("sprite_link_item_stepladder", "SPR_NPC_ITEM_STEPLADDER"),
        ("sprite_link_item_sword", "SPR_NPC_ITEM_SWORD"),
        ("sprite_link_item_bracelet", "SPR_NPC_ITEM_BRACELET"),
        ("sprite_link_item_book", "SPR_NPC_ITEM_BOOK"),
        ("sprite_link_item_magic_key", "SPR_NPC_ITEM_MAGIC_KEY"),
        ("sprite_tri_p1", "SPR_NPC_TRI_P1"),
        ("sprite_tri_p2", "SPR_NPC_TRI_P2"),
        ("sprite_tri_p3", "SPR_NPC_TRI_P3"),
        ("sprite_tri_p4", "SPR_NPC_TRI_P4"),
        ("sprite_tri_p5", "SPR_NPC_TRI_P5"),
        ("sprite_tri_p6", "SPR_NPC_TRI_P6"),
        ("sprite_tri_p7", "SPR_NPC_TRI_P7"),
        ("sprite_tri_p8", "SPR_NPC_TRI_P8"),
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
