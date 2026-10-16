#!/usr/bin/env python3
"""Générateur d'intégration complète des 44 monstres et boss de Zelda 1 (1986) dans enemies.asm.
"""

def generate_asm():
    code = []
    
    # Tables de pointeurs de sprites 8-octets
    code.append("; --- Tables des pointeurs de sprites (8 octets par ennemi : 4 dir x 2 anim) ---")
    
    tables = {
        "octo_ptrs": """
        !byte < (sprite_enemies_octo_down_0 / 64), < (sprite_enemies_octo_down_1 / 64)
        !byte < (sprite_enemies_octo_up_0 / 64), < (sprite_enemies_octo_up_1 / 64)
        !byte < (sprite_enemies_octo_left_0 / 64), < (sprite_enemies_octo_left_1 / 64)
        !byte < (sprite_enemies_octo_right_0 / 64), < (sprite_enemies_octo_right_1 / 64)""",
        
        "moblin_ptrs": """
        !byte < (sprite_enemies_moblin_down_0 / 64), < (sprite_enemies_moblin_down_1 / 64)
        !byte < (sprite_enemies_moblin_up_0 / 64), < (sprite_enemies_moblin_up_1 / 64)
        !byte < (sprite_enemies_moblin_left_0 / 64), < (sprite_enemies_moblin_left_1 / 64)
        !byte < (sprite_enemies_moblin_right_0 / 64), < (sprite_enemies_moblin_right_1 / 64)""",
        
        "tektite_ptrs": """
        !byte < (sprite_enemies_tektite_0 / 64), < (sprite_enemies_tektite_1 / 64)
        !byte < (sprite_enemies_tektite_0 / 64), < (sprite_enemies_tektite_1 / 64)
        !byte < (sprite_enemies_tektite_0 / 64), < (sprite_enemies_tektite_1 / 64)
        !byte < (sprite_enemies_tektite_0 / 64), < (sprite_enemies_tektite_1 / 64)""",

        "leever_ptrs": """
        !byte < (sprite_enemies_leever_0 / 64), < (sprite_enemies_leever_1 / 64)
        !byte < (sprite_enemies_leever_0 / 64), < (sprite_enemies_leever_1 / 64)
        !byte < (sprite_enemies_leever_0 / 64), < (sprite_enemies_leever_1 / 64)
        !byte < (sprite_enemies_leever_0 / 64), < (sprite_enemies_leever_1 / 64)""",

        "peahat_ptrs": """
        !byte < (sprite_enemies_peahat_0 / 64), < (sprite_enemies_peahat_1 / 64)
        !byte < (sprite_enemies_peahat_0 / 64), < (sprite_enemies_peahat_1 / 64)
        !byte < (sprite_enemies_peahat_0 / 64), < (sprite_enemies_peahat_1 / 64)
        !byte < (sprite_enemies_peahat_0 / 64), < (sprite_enemies_peahat_1 / 64)""",

        "armos_ptrs": """
        !byte < (sprite_enemies_armos_0 / 64), < (sprite_enemies_armos_1 / 64)
        !byte < (sprite_enemies_armos_0 / 64), < (sprite_enemies_armos_1 / 64)
        !byte < (sprite_enemies_armos_0 / 64), < (sprite_enemies_armos_1 / 64)
        !byte < (sprite_enemies_armos_0 / 64), < (sprite_enemies_armos_1 / 64)""",

        "ghini_ptrs": """
        !byte < (sprite_enemies_ghini_0 / 64), < (sprite_enemies_ghini_1 / 64)
        !byte < (sprite_enemies_ghini_0 / 64), < (sprite_enemies_ghini_1 / 64)
        !byte < (sprite_enemies_ghini_0 / 64), < (sprite_enemies_ghini_1 / 64)
        !byte < (sprite_enemies_ghini_0 / 64), < (sprite_enemies_ghini_1 / 64)""",

        "zora_ptrs": """
        !byte < (sprite_enemies_zora_0 / 64), < (sprite_enemies_zora_1 / 64)
        !byte < (sprite_enemies_zora_0 / 64), < (sprite_enemies_zora_1 / 64)
        !byte < (sprite_enemies_zora_0 / 64), < (sprite_enemies_zora_1 / 64)
        !byte < (sprite_enemies_zora_0 / 64), < (sprite_enemies_zora_1 / 64)""",

        "lynel_ptrs": """
        !byte < (sprite_enemies_lynel_0 / 64), < (sprite_enemies_lynel_1 / 64)
        !byte < (sprite_enemies_lynel_0 / 64), < (sprite_enemies_lynel_1 / 64)
        !byte < (sprite_enemies_lynel_0 / 64), < (sprite_enemies_lynel_1 / 64)
        !byte < (sprite_enemies_lynel_0 / 64), < (sprite_enemies_lynel_1 / 64)""",

        "keese_ptrs": """
        !byte < (sprite_enemies_keese_0 / 64), < (sprite_enemies_keese_1 / 64)
        !byte < (sprite_enemies_keese_0 / 64), < (sprite_enemies_keese_1 / 64)
        !byte < (sprite_enemies_keese_0 / 64), < (sprite_enemies_keese_1 / 64)
        !byte < (sprite_enemies_keese_0 / 64), < (sprite_enemies_keese_1 / 64)""",

        "zol_ptrs": """
        !byte < (sprite_enemies_zol_0 / 64), < (sprite_enemies_zol_1 / 64)
        !byte < (sprite_enemies_zol_0 / 64), < (sprite_enemies_zol_1 / 64)
        !byte < (sprite_enemies_zol_0 / 64), < (sprite_enemies_zol_1 / 64)
        !byte < (sprite_enemies_zol_0 / 64), < (sprite_enemies_zol_1 / 64)""",

        "gel_ptrs": """
        !byte < (sprite_enemies_gel / 64), < (sprite_enemies_gel / 64)
        !byte < (sprite_enemies_gel / 64), < (sprite_enemies_gel / 64)
        !byte < (sprite_enemies_gel / 64), < (sprite_enemies_gel / 64)
        !byte < (sprite_enemies_gel / 64), < (sprite_enemies_gel / 64)""",

        "rope_ptrs": """
        !byte < (sprite_enemies_rope_0 / 64), < (sprite_enemies_rope_1 / 64)
        !byte < (sprite_enemies_rope_0 / 64), < (sprite_enemies_rope_1 / 64)
        !byte < (sprite_enemies_rope_0 / 64), < (sprite_enemies_rope_1 / 64)
        !byte < (sprite_enemies_rope_0 / 64), < (sprite_enemies_rope_1 / 64)""",

        "stalfos_ptrs": """
        !byte < (sprite_enemies_stalfos_0 / 64), < (sprite_enemies_stalfos_1 / 64)
        !byte < (sprite_enemies_stalfos_0 / 64), < (sprite_enemies_stalfos_1 / 64)
        !byte < (sprite_enemies_stalfos_0 / 64), < (sprite_enemies_stalfos_1 / 64)
        !byte < (sprite_enemies_stalfos_0 / 64), < (sprite_enemies_stalfos_1 / 64)""",

        "goriya_ptrs": """
        !byte < (sprite_enemies_goriya_0 / 64), < (sprite_enemies_goriya_1 / 64)
        !byte < (sprite_enemies_goriya_0 / 64), < (sprite_enemies_goriya_1 / 64)
        !byte < (sprite_enemies_goriya_0 / 64), < (sprite_enemies_goriya_1 / 64)
        !byte < (sprite_enemies_goriya_0 / 64), < (sprite_enemies_goriya_1 / 64)""",

        "darknut_ptrs": """
        !byte < (sprite_enemies_darknut_0 / 64), < (sprite_enemies_darknut_1 / 64)
        !byte < (sprite_enemies_darknut_0 / 64), < (sprite_enemies_darknut_1 / 64)
        !byte < (sprite_enemies_darknut_0 / 64), < (sprite_enemies_darknut_1 / 64)
        !byte < (sprite_enemies_darknut_0 / 64), < (sprite_enemies_darknut_1 / 64)""",

        "wizzrobe_ptrs": """
        !byte < (sprite_enemies_wizzrobe_0 / 64), < (sprite_enemies_wizzrobe_1 / 64)
        !byte < (sprite_enemies_wizzrobe_0 / 64), < (sprite_enemies_wizzrobe_1 / 64)
        !byte < (sprite_enemies_wizzrobe_0 / 64), < (sprite_enemies_wizzrobe_1 / 64)
        !byte < (sprite_enemies_wizzrobe_0 / 64), < (sprite_enemies_wizzrobe_1 / 64)""",

        "wallmaster_ptrs": """
        !byte < (sprite_enemies_wallmaster_0 / 64), < (sprite_enemies_wallmaster_1 / 64)
        !byte < (sprite_enemies_wallmaster_0 / 64), < (sprite_enemies_wallmaster_1 / 64)
        !byte < (sprite_enemies_wallmaster_0 / 64), < (sprite_enemies_wallmaster_1 / 64)
        !byte < (sprite_enemies_wallmaster_0 / 64), < (sprite_enemies_wallmaster_1 / 64)""",

        "likelike_ptrs": """
        !byte < (sprite_enemies_likelike_0 / 64), < (sprite_enemies_likelike_1 / 64)
        !byte < (sprite_enemies_likelike_0 / 64), < (sprite_enemies_likelike_1 / 64)
        !byte < (sprite_enemies_likelike_0 / 64), < (sprite_enemies_likelike_1 / 64)
        !byte < (sprite_enemies_likelike_0 / 64), < (sprite_enemies_likelike_1 / 64)""",

        "polsvoice_ptrs": """
        !byte < (sprite_enemies_polsvoice_0 / 64), < (sprite_enemies_polsvoice_1 / 64)
        !byte < (sprite_enemies_polsvoice_0 / 64), < (sprite_enemies_polsvoice_1 / 64)
        !byte < (sprite_enemies_polsvoice_0 / 64), < (sprite_enemies_polsvoice_1 / 64)
        !byte < (sprite_enemies_polsvoice_0 / 64), < (sprite_enemies_polsvoice_1 / 64)""",

        "gibdo_ptrs": """
        !byte < (sprite_enemies_gibdo_0 / 64), < (sprite_enemies_gibdo_1 / 64)
        !byte < (sprite_enemies_gibdo_0 / 64), < (sprite_enemies_gibdo_1 / 64)
        !byte < (sprite_enemies_gibdo_0 / 64), < (sprite_enemies_gibdo_1 / 64)
        !byte < (sprite_enemies_gibdo_0 / 64), < (sprite_enemies_gibdo_1 / 64)""",

        "vire_ptrs": """
        !byte < (sprite_enemies_vire_0 / 64), < (sprite_enemies_vire_1 / 64)
        !byte < (sprite_enemies_vire_0 / 64), < (sprite_enemies_vire_1 / 64)
        !byte < (sprite_enemies_vire_0 / 64), < (sprite_enemies_vire_1 / 64)
        !byte < (sprite_enemies_vire_0 / 64), < (sprite_enemies_vire_1 / 64)""",

        "bubble_ptrs": """
        !byte < (sprite_enemies_bubble_0 / 64), < (sprite_enemies_bubble_1 / 64)
        !byte < (sprite_enemies_bubble_0 / 64), < (sprite_enemies_bubble_1 / 64)
        !byte < (sprite_enemies_bubble_0 / 64), < (sprite_enemies_bubble_1 / 64)
        !byte < (sprite_enemies_bubble_0 / 64), < (sprite_enemies_bubble_1 / 64)""",

        "trap_ptrs": """
        !byte < (sprite_enemies_trap / 64), < (sprite_enemies_trap / 64)
        !byte < (sprite_enemies_trap / 64), < (sprite_enemies_trap / 64)
        !byte < (sprite_enemies_trap / 64), < (sprite_enemies_trap / 64)
        !byte < (sprite_enemies_trap / 64), < (sprite_enemies_trap / 64)""",

        "lanmola_ptrs": """
        !byte < (sprite_enemies_lanmola_head / 64), < (sprite_enemies_lanmola_body / 64)
        !byte < (sprite_enemies_lanmola_head / 64), < (sprite_enemies_lanmola_body / 64)
        !byte < (sprite_enemies_lanmola_head / 64), < (sprite_enemies_lanmola_body / 64)
        !byte < (sprite_enemies_lanmola_head / 64), < (sprite_enemies_lanmola_body / 64)""",

        "aquamentus_ptrs": """
        !byte < (sprite_enemies_aquamentus_0 / 64), < (sprite_enemies_aquamentus_1 / 64)
        !byte < (sprite_enemies_aquamentus_0 / 64), < (sprite_enemies_aquamentus_1 / 64)
        !byte < (sprite_enemies_aquamentus_0 / 64), < (sprite_enemies_aquamentus_1 / 64)
        !byte < (sprite_enemies_aquamentus_0 / 64), < (sprite_enemies_aquamentus_1 / 64)""",

        "dodongo_ptrs": """
        !byte < (sprite_enemies_dodongo_0 / 64), < (sprite_enemies_dodongo_1 / 64)
        !byte < (sprite_enemies_dodongo_0 / 64), < (sprite_enemies_dodongo_1 / 64)
        !byte < (sprite_enemies_dodongo_0 / 64), < (sprite_enemies_dodongo_1 / 64)
        !byte < (sprite_enemies_dodongo_0 / 64), < (sprite_enemies_dodongo_1 / 64)""",

        "manhandla_ptrs": """
        !byte < (sprite_enemies_manhandla_core / 64), < (sprite_enemies_manhandla_jaw / 64)
        !byte < (sprite_enemies_manhandla_core / 64), < (sprite_enemies_manhandla_jaw / 64)
        !byte < (sprite_enemies_manhandla_core / 64), < (sprite_enemies_manhandla_jaw / 64)
        !byte < (sprite_enemies_manhandla_core / 64), < (sprite_enemies_manhandla_jaw / 64)""",

        "gleeok_ptrs": """
        !byte < (sprite_enemies_gleeok_0 / 64), < (sprite_enemies_gleeok_1 / 64)
        !byte < (sprite_enemies_gleeok_0 / 64), < (sprite_enemies_gleeok_1 / 64)
        !byte < (sprite_enemies_gleeok_0 / 64), < (sprite_enemies_gleeok_1 / 64)
        !byte < (sprite_enemies_gleeok_0 / 64), < (sprite_enemies_gleeok_1 / 64)""",

        "digdogger_ptrs": """
        !byte < (sprite_enemies_digdogger / 64), < (sprite_enemies_digdogger / 64)
        !byte < (sprite_enemies_digdogger / 64), < (sprite_enemies_digdogger / 64)
        !byte < (sprite_enemies_digdogger / 64), < (sprite_enemies_digdogger / 64)
        !byte < (sprite_enemies_digdogger / 64), < (sprite_enemies_digdogger / 64)""",

        "gohma_ptrs": """
        !byte < (sprite_enemies_gohma_closed / 64), < (sprite_enemies_gohma_open / 64)
        !byte < (sprite_enemies_gohma_closed / 64), < (sprite_enemies_gohma_open / 64)
        !byte < (sprite_enemies_gohma_closed / 64), < (sprite_enemies_gohma_open / 64)
        !byte < (sprite_enemies_gohma_closed / 64), < (sprite_enemies_gohma_open / 64)""",

        "patra_ptrs": """
        !byte < (sprite_enemies_patra_center / 64), < (sprite_enemies_patra_orb / 64)
        !byte < (sprite_enemies_patra_center / 64), < (sprite_enemies_patra_orb / 64)
        !byte < (sprite_enemies_patra_center / 64), < (sprite_enemies_patra_orb / 64)
        !byte < (sprite_enemies_patra_center / 64), < (sprite_enemies_patra_orb / 64)""",

        "ganon_ptrs": """
        !byte < (sprite_enemies_ganon_0 / 64), < (sprite_enemies_ganon_1 / 64)
        !byte < (sprite_enemies_ganon_0 / 64), < (sprite_enemies_ganon_1 / 64)
        !byte < (sprite_enemies_ganon_0 / 64), < (sprite_enemies_ganon_1 / 64)
        !byte < (sprite_enemies_ganon_0 / 64), < (sprite_enemies_ganon_1 / 64)""",

        "none_ptrs": """
        !byte 0, 0, 0, 0, 0, 0, 0, 0"""
    }

    for name, tbl in tables.items():
        code.append(f"{name}:{tbl}\n")

    return "\n".join(code)

if __name__ == "__main__":
    print(generate_asm()[:300])
