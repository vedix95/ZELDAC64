#!/usr/bin/env python3
"""Génère les tables complètes des statistiques, IA et pointeurs de sprites
pour tous les 44 ennemis officiels de Zelda 1 NES pour C64.
"""

def generate():
    out = []
    
    # Tables de stats
    # 0: None
    # 1: Octo R, 2: Octo B
    # 3: Moblin R, 4: Moblin B
    # 5: Tektite R, 6: Tektite B
    # 7: Leever R, 8: Leever B
    # 9: Peahat
    # 10: Armos
    # 11: Ghini
    # 12: Zora
    # 13: Lynel R, 14: Lynel B
    # 15: Keese R, 16: Keese B
    # 17: Zol, 18: Gel
    # 19: Rope
    # 20: Stalfos
    # 21: Goriya R, 22: Goriya B
    # 23: Darknut R, 24: Darknut B
    # 25: Wizzrobe R, 26: Wizzrobe B
    # 27: Wallmaster
    # 28: Like Like
    # 29: Pols Voice
    # 30: Gibdo
    # 31: Vire
    # 32: Bubble
    # 33: Trap
    # 34: Lanmola R, 35: Lanmola B
    # 36: Aquamentus
    # 37: Dodongo
    # 38: Manhandla
    # 39: Gleeok
    # 40: Digdogger
    # 41: Gohma R, 42: Gohma B
    # 43: Patra
    # 44: Ganon

    hp = [
        0,
        1, 2,  # Octo R/B
        2, 3,  # Moblin R/B
        1, 1,  # Tektite R/B
        2, 4,  # Leever R/B
        2,     # Peahat
        3,     # Armos
        9,     # Ghini
        2,     # Zora
        4, 6,  # Lynel R/B
        1, 1,  # Keese R/B
        2, 1,  # Zol, Gel
        1,     # Rope
        2,     # Stalfos
        3, 5,  # Goriya R/B
        4, 8,  # Darknut R/B
        5, 10, # Wizzrobe R/B
        2,     # Wallmaster
        9,     # Like Like
        10,    # Pols Voice
        6,     # Gibdo
        4,     # Vire
        255,   # Bubble (invincible)
        255,   # Trap (invincible)
        2, 4,  # Lanmola R/B
        6,     # Aquamentus
        8,     # Dodongo
        8,     # Manhandla
        8,     # Gleeok
        8,     # Digdogger
        2, 4,  # Gohma R/B
        10,    # Patra
        16     # Ganon
    ]

    dmg = [
        0,
        1, 1,  # Octo R/B
        1, 2,  # Moblin R/B
        1, 1,  # Tektite R/B
        1, 2,  # Leever R/B
        1,     # Peahat
        2,     # Armos
        2,     # Ghini
        1,     # Zora
        4, 4,  # Lynel R/B (2 cœurs)
        1, 1,  # Keese R/B
        2, 1,  # Zol, Gel
        1,     # Rope
        1,     # Stalfos
        1, 2,  # Goriya R/B
        2, 4,  # Darknut R/B
        2, 4,  # Wizzrobe R/B
        1,     # Wallmaster
        2,     # Like Like
        2,     # Pols Voice
        2,     # Gibdo
        2,     # Vire
        0,     # Bubble (malédiction)
        2,     # Trap
        2, 4,  # Lanmola R/B
        1,     # Aquamentus
        2,     # Dodongo
        2,     # Manhandla
        2,     # Gleeok
        2,     # Digdogger
        2, 2,  # Gohma R/B
        2,     # Patra
        4      # Ganon
    ]

    col = [
        "COL_BLACK",
        "COL_RED", "COL_BLUE",    # Octo R/B
        "COL_RED", "COL_BLUE",    # Moblin R/B
        "COL_RED", "COL_BLUE",    # Tektite R/B
        "COL_RED", "COL_BLUE",    # Leever R/B
        "COL_ORANGE",             # Peahat
        "COL_BROWN",              # Armos
        "COL_CYAN",               # Ghini
        "COL_GREEN",              # Zora
        "COL_RED", "COL_BLUE",    # Lynel R/B
        "COL_RED", "COL_BLUE",    # Keese R/B
        "COL_GREY", "COL_WHITE",  # Zol, Gel
        "COL_ORANGE",             # Rope
        "COL_WHITE",              # Stalfos
        "COL_RED", "COL_BLUE",    # Goriya R/B
        "COL_RED", "COL_BLUE",    # Darknut R/B
        "COL_RED", "COL_BLUE",    # Wizzrobe R/B
        "COL_LRED",               # Wallmaster
        "COL_ORANGE",             # Like Like
        "COL_WHITE",              # Pols Voice
        "COL_LGREY",              # Gibdo
        "COL_BLUE",               # Vire
        "COL_PURPLE",             # Bubble
        "COL_GREY",               # Trap
        "COL_RED", "COL_BLUE",    # Lanmola R/B
        "COL_GREEN",              # Aquamentus
        "COL_BROWN",              # Dodongo
        "COL_GREEN",              # Manhandla
        "COL_GREEN",              # Gleeok
        "COL_ORANGE",             # Digdogger
        "COL_RED", "COL_BLUE",    # Gohma R/B
        "COL_ORANGE",             # Patra
        "COL_PURPLE"              # Ganon
    ]

    ai = [
        "AI_ROAM",
        "AI_ROAM", "AI_ROAM",     # Octo R/B
        "AI_ROAM", "AI_ROAM",     # Moblin R/B
        "AI_HOP", "AI_HOP",       # Tektite R/B
        "AI_BURROW", "AI_BURROW", # Leever R/B
        "AI_FLY",                 # Peahat
        "AI_STATUE",              # Armos
        "AI_FLY",                 # Ghini
        "AI_WATER",               # Zora
        "AI_ROAM", "AI_ROAM",     # Lynel R/B
        "AI_FLY", "AI_FLY",       # Keese R/B
        "AI_SLIME", "AI_SLIME",   # Zol, Gel
        "AI_RUSH",                # Rope
        "AI_ROAM",                # Stalfos
        "AI_ROAM", "AI_ROAM",     # Goriya R/B
        "AI_SHIELD", "AI_SHIELD", # Darknut R/B
        "AI_TELEPORT", "AI_TELEPORT", # Wizzrobe R/B
        "AI_ROAM",                # Wallmaster
        "AI_ROAM",                # Like Like
        "AI_HOP",                 # Pols Voice
        "AI_ROAM",                # Gibdo
        "AI_FLY",                 # Vire
        "AI_FLY",                 # Bubble
        "AI_RUSH",                # Trap
        "AI_ROAM", "AI_ROAM",     # Lanmola R/B
        "AI_BOSS",                # Aquamentus
        "AI_BOSS",                # Dodongo
        "AI_BOSS",                # Manhandla
        "AI_BOSS",                # Gleeok
        "AI_BOSS",                # Digdogger
        "AI_BOSS", "AI_BOSS",     # Gohma R/B
        "AI_FLY",                 # Patra
        "AI_BOSS"                 # Ganon
    ]

    proj = [
        "PROJ_NONE",
        "PROJ_ROCK", "PROJ_ROCK",       # Octo
        "PROJ_SPEAR", "PROJ_SPEAR",     # Moblin
        "PROJ_NONE", "PROJ_NONE",       # Tektite
        "PROJ_NONE", "PROJ_NONE",       # Leever
        "PROJ_NONE",                    # Peahat
        "PROJ_NONE",                    # Armos
        "PROJ_NONE",                    # Ghini
        "PROJ_FIREBALL",                # Zora
        "PROJ_MAGIC", "PROJ_MAGIC",     # Lynel
        "PROJ_NONE", "PROJ_NONE",       # Keese
        "PROJ_NONE", "PROJ_NONE",       # Zol, Gel
        "PROJ_NONE",                    # Rope
        "PROJ_NONE",                    # Stalfos
        "PROJ_BOOMERANG", "PROJ_BOOMERANG", # Goriya
        "PROJ_NONE", "PROJ_NONE",       # Darknut
        "PROJ_MAGIC", "PROJ_MAGIC",     # Wizzrobe
        "PROJ_NONE",                    # Wallmaster
        "PROJ_NONE",                    # Like Like
        "PROJ_NONE",                    # Pols Voice
        "PROJ_NONE",                    # Gibdo
        "PROJ_NONE",                    # Vire
        "PROJ_NONE",                    # Bubble
        "PROJ_NONE",                    # Trap
        "PROJ_NONE", "PROJ_NONE",       # Lanmola
        "PROJ_FIREBALL",                # Aquamentus
        "PROJ_NONE",                    # Dodongo
        "PROJ_FIREBALL",                # Manhandla
        "PROJ_FIREBALL",                # Gleeok
        "PROJ_NONE",                    # Digdogger
        "PROJ_FIREBALL", "PROJ_FIREBALL", # Gohma
        "PROJ_FIREBALL",                # Patra
        "PROJ_FIREBALL"                 # Ganon
    ]

    ptr_names = [
        "none_ptrs",
        "octo_ptrs", "octo_ptrs",
        "moblin_ptrs", "moblin_ptrs",
        "tektite_ptrs", "tektite_ptrs",
        "leever_ptrs", "leever_ptrs",
        "peahat_ptrs",
        "armos_ptrs",
        "ghini_ptrs",
        "zora_ptrs",
        "lynel_ptrs", "lynel_ptrs",
        "keese_ptrs", "keese_ptrs",
        "zol_ptrs", "gel_ptrs",
        "rope_ptrs",
        "stalfos_ptrs",
        "goriya_ptrs", "goriya_ptrs",
        "darknut_ptrs", "darknut_ptrs",
        "wizzrobe_ptrs", "wizzrobe_ptrs",
        "wallmaster_ptrs",
        "likelike_ptrs",
        "polsvoice_ptrs",
        "gibdo_ptrs",
        "vire_ptrs",
        "bubble_ptrs",
        "trap_ptrs",
        "lanmola_ptrs", "lanmola_ptrs",
        "aquamentus_ptrs",
        "dodongo_ptrs",
        "manhandla_ptrs",
        "gleeok_ptrs",
        "digdogger_ptrs",
        "gohma_ptrs", "gohma_ptrs",
        "patra_ptrs",
        "ganon_ptrs"
    ]

    print(f"Total enemy types: {len(hp)}")
    assert len(hp) == 45
    assert len(dmg) == 45
    assert len(col) == 45
    assert len(ai) == 45
    assert len(proj) == 45
    assert len(ptr_names) == 45

    return hp, dmg, col, ai, proj, ptr_names

if __name__ == "__main__":
    generate()
