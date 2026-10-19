; ---------------------------------------------------------------------------
; enemies.asm : Système complet d'ennemis Zelda (Octorok et Moblin)
;
; Gère :
;   - 2 ennemis simultanés par salle (Sprites VIC 3 et 4)
;   - 1 projectile ennemi (Rocher d'Octorok ou Lance de Moblin, Sprite VIC 5)
;   - Déplacements autonomes et évitement des collisions avec le décor
;   - Attaques à distance (crachat de rocher, lancer de lance)
;   - Système de parade au bouclier de Link (renvoi/blocage des tirs !)
;   - Réactions aux coups d'épée (recul, clignotement blanc, points de vie)
;   - Réactions aux armes secondaires (flèche mortelle, boomerang étourdissant,
;     déflagration 3x3 de bombe destructrice)
;   - Animation de mort en nuage de fumée rétro et butin (Rubis / Cœurs)
;   - Sons SID dédiés (coups, mort, tir, parade, ramassage)
; ---------------------------------------------------------------------------

MAX_ENEMIES             = 8

MAX_ENEMIES             = 8

!source "src/enemy_types.inc"

; Rétro-compatibilité
TYPE_OCTO               = TYPE_OCTO_RED
TYPE_MOBLIN             = TYPE_MOBLIN_RED

EN_STATE_DEAD           = 0
EN_STATE_WALK           = 1
EN_STATE_HURT           = 2             ; touché / recul / étourdi
EN_STATE_DYING          = 3             ; nuage de fumée de mort

; Types d'IA
AI_ROAM                 = 0             ; Marche 4 directions
AI_HOP                  = 1             ; Saut périodique (Tektite, Pols Voice)
AI_BURROW               = 2             ; Fouisseur / émergence (Leever)
AI_FLY                  = 3             ; Vol erratique (Keese, Peahat, Vire, Patra)
AI_RUSH                 = 4             ; Charge à vue dès alignement (Rope, Trap)
AI_SHIELD               = 5             ; Bouclier frontal invulnérable (Darknut)
AI_TELEPORT             = 6             ; Téléportation / apparition (Wizzrobe)
AI_WATER                = 7             ; Surgissement dans l'eau (Zora)
AI_STATUE               = 8             ; Statue endormie (Armos)
AI_SLIME                = 9             ; Glissement lent et division (Zol, Gel)
AI_BOSS                 = 10            ; Boss majeur (Aquamentus, Dodongo, Gohma, Ganon)

; Types de projectiles
PROJ_NONE               = 0
PROJ_ROCK               = 1             ; Rocher d'Octorok
PROJ_SPEAR              = 2             ; Lance de Moblin
PROJ_FIREBALL           = 3             ; Boule de feu (Zora, Bosses)
PROJ_MAGIC              = 4             ; Onde magique (Wizzrobe, Lynel)
PROJ_BOOMERANG          = 5             ; Boomerang ennemi (Goriya)

; Variables globales des ennemis (pour 8 slots d'ennemis : index 0..7)
en_type:                !byte 0, 0, 0, 0, 0, 0, 0, 0
en_state:               !byte 0, 0, 0, 0, 0, 0, 0, 0
en_hp:                  !byte 0, 0, 0, 0, 0, 0, 0, 0
en_x:                   !word 0, 0, 0, 0, 0, 0, 0, 0      ; position X (16 bits)
en_y:                   !byte 0, 0, 0, 0, 0, 0, 0, 0      ; position Y (8 bits)
en_dir:                 !byte 0, 0, 0, 0, 0, 0, 0, 0      ; DIR_DOWN, UP, LEFT, RIGHT
en_timer:               !byte 0, 0, 0, 0, 0, 0, 0, 0      ; compte à rebours d'action/changement
en_anim:                !byte 0, 0, 0, 0, 0, 0, 0, 0      ; image courante (0 ou 1)
en_anim_tick:           !byte 0, 0, 0, 0, 0, 0, 0, 0      ; temporisateur d'alternance des pas
en_hurt_timer:          !byte 0, 0, 0, 0, 0, 0, 0, 0      ; temporisateur d'invincibilité/recul

; Variables du multiplexeur de sprites VIC-II (Technique 1)
sort_idx:               !byte 0, 1, 2, 3, 4, 5, 6, 7
sort_eff_y:             !byte 0, 0, 0, 0, 0, 0, 0, 0
sort_swapped:           !byte 0
sort_tmp_y:             !byte 0
split_y3:               !byte 0
split_y4:               !byte 0
multiplex_split_line:   !byte 145
frame_ready:            !byte 0

; Projectile ennemi (1 seul actif à la fois, Sprite 7)
en_proj_active:         !byte 0
en_proj_type:           !byte 0         ; TYPE_OCTO (rocher) ou TYPE_MOBLIN (lance)
en_proj_x:              !word 0
en_proj_y:              !byte 0
en_proj_dir:            !byte 0

; Variables temporaires locales
en_idx:                 !byte 0
en_tmp_loop:            !byte 0
en_dx:                  !word 0
en_dy:                  !byte 0
en_tmp_x:               !word 0
en_tmp_y:               !byte 0
en_recul_dir:           !byte 0
en_global_frame:        !byte 0
en_cand_x:              !word 0
en_cand_y:              !byte 0
en_step_px:             !byte 0

; Invulnérabilité et clignotement de Link
player_hurt_timer:      !byte 0

; Générateur pseudo-aléatoire (LFSR 8 bits)
rand_seed:              !byte $a5


; ---------------------------------------------------------------------------
; Tables statistiques des 45 types d'ennemis Zelda (1986)
; ---------------------------------------------------------------------------
en_base_hp:
        !byte 0, 1, 2, 2, 3, 1, 1, 2, 4, 2, 3, 9, 2, 4, 6, 1, 1, 2, 1, 1, 2, 3, 5, 4, 8, 5, 10, 2, 9, 10, 6, 4, 255, 255, 2, 4, 6, 8, 8, 8, 8, 2, 4, 10, 16

en_base_damage:
        !byte 0, 1, 1, 1, 2, 1, 1, 1, 2, 1, 2, 2, 1, 4, 4, 1, 1, 2, 1, 1, 1, 1, 2, 2, 4, 2, 4, 1, 2, 2, 2, 2, 0, 2, 2, 4, 1, 2, 2, 2, 2, 2, 2, 2, 4

en_base_color:
        !byte COL_BLACK, COL_RED, COL_BLUE, COL_RED, COL_BLUE, COL_RED, COL_BLUE, COL_RED, COL_BLUE, COL_ORANGE, COL_BROWN, COL_CYAN, COL_GREEN, COL_RED, COL_BLUE, COL_RED, COL_BLUE, COL_GREY, COL_WHITE, COL_ORANGE, COL_WHITE, COL_RED, COL_BLUE, COL_RED, COL_BLUE, COL_RED, COL_BLUE, COL_LRED, COL_ORANGE, COL_WHITE, COL_LGREY, COL_BLUE, COL_PURPLE, COL_GREY, COL_RED, COL_BLUE, COL_GREEN, COL_BROWN, COL_GREEN, COL_GREEN, COL_ORANGE, COL_RED, COL_BLUE, COL_ORANGE, COL_PURPLE

en_ai_type:
        !byte AI_ROAM, AI_ROAM, AI_ROAM, AI_ROAM, AI_ROAM, AI_HOP, AI_HOP, AI_BURROW, AI_BURROW, AI_FLY, AI_STATUE, AI_FLY, AI_WATER, AI_ROAM, AI_ROAM, AI_FLY, AI_FLY, AI_SLIME, AI_SLIME, AI_RUSH, AI_ROAM, AI_ROAM, AI_ROAM, AI_SHIELD, AI_SHIELD, AI_TELEPORT, AI_TELEPORT, AI_ROAM, AI_ROAM, AI_HOP, AI_ROAM, AI_FLY, AI_FLY, AI_RUSH, AI_ROAM, AI_ROAM, AI_BOSS, AI_BOSS, AI_BOSS, AI_BOSS, AI_BOSS, AI_BOSS, AI_BOSS, AI_FLY, AI_BOSS

en_proj_type_tbl:
        !byte PROJ_NONE, PROJ_ROCK, PROJ_ROCK, PROJ_SPEAR, PROJ_SPEAR, PROJ_NONE, PROJ_NONE, PROJ_NONE, PROJ_NONE, PROJ_NONE, PROJ_NONE, PROJ_NONE, PROJ_FIREBALL, PROJ_MAGIC, PROJ_MAGIC, PROJ_NONE, PROJ_NONE, PROJ_NONE, PROJ_NONE, PROJ_NONE, PROJ_NONE, PROJ_BOOMERANG, PROJ_BOOMERANG, PROJ_NONE, PROJ_NONE, PROJ_MAGIC, PROJ_MAGIC, PROJ_NONE, PROJ_NONE, PROJ_NONE, PROJ_NONE, PROJ_NONE, PROJ_NONE, PROJ_NONE, PROJ_NONE, PROJ_NONE, PROJ_FIREBALL, PROJ_NONE, PROJ_FIREBALL, PROJ_FIREBALL, PROJ_NONE, PROJ_FIREBALL, PROJ_FIREBALL, PROJ_FIREBALL, PROJ_FIREBALL

en_sprite_tbl_lo:
        !byte <none_ptrs, <octo_ptrs, <octo_ptrs, <moblin_ptrs, <moblin_ptrs, <tektite_ptrs, <tektite_ptrs, <leever_ptrs, <leever_ptrs, <peahat_ptrs, <armos_ptrs, <ghini_ptrs, <zora_ptrs, <lynel_ptrs, <lynel_ptrs, <keese_ptrs, <keese_ptrs, <zol_ptrs, <gel_ptrs, <rope_ptrs, <stalfos_ptrs, <goriya_ptrs, <goriya_ptrs, <darknut_ptrs, <darknut_ptrs, <wizzrobe_ptrs, <wizzrobe_ptrs, <wallmaster_ptrs, <likelike_ptrs, <polsvoice_ptrs, <gibdo_ptrs, <vire_ptrs, <bubble_ptrs, <trap_ptrs, <lanmola_ptrs, <lanmola_ptrs, <aquamentus_ptrs, <dodongo_ptrs, <manhandla_ptrs, <gleeok_ptrs, <digdogger_ptrs, <gohma_ptrs, <gohma_ptrs, <patra_ptrs, <ganon_ptrs

en_sprite_tbl_hi:
        !byte >none_ptrs, >octo_ptrs, >octo_ptrs, >moblin_ptrs, >moblin_ptrs, >tektite_ptrs, >tektite_ptrs, >leever_ptrs, >leever_ptrs, >peahat_ptrs, >armos_ptrs, >ghini_ptrs, >zora_ptrs, >lynel_ptrs, >lynel_ptrs, >keese_ptrs, >keese_ptrs, >zol_ptrs, >gel_ptrs, >rope_ptrs, >stalfos_ptrs, >goriya_ptrs, >goriya_ptrs, >darknut_ptrs, >darknut_ptrs, >wizzrobe_ptrs, >wizzrobe_ptrs, >wallmaster_ptrs, >likelike_ptrs, >polsvoice_ptrs, >gibdo_ptrs, >vire_ptrs, >bubble_ptrs, >trap_ptrs, >lanmola_ptrs, >lanmola_ptrs, >aquamentus_ptrs, >dodongo_ptrs, >manhandla_ptrs, >gleeok_ptrs, >digdogger_ptrs, >gohma_ptrs, >gohma_ptrs, >patra_ptrs, >ganon_ptrs

sword_cursed_timer:     !byte 0

; --- Tables des pointeurs de sprites (8 octets par ennemi : 4 dir x 2 anim) ---
octo_ptrs:
        !byte < (sprite_enemies_octo_down_0 / 64), < (sprite_enemies_octo_down_1 / 64)
        !byte < (sprite_enemies_octo_up_0 / 64), < (sprite_enemies_octo_up_1 / 64)
        !byte < (sprite_enemies_octo_left_0 / 64), < (sprite_enemies_octo_left_1 / 64)
        !byte < (sprite_enemies_octo_right_0 / 64), < (sprite_enemies_octo_right_1 / 64)

moblin_ptrs:
        !byte < (sprite_enemies_moblin_down_0 / 64), < (sprite_enemies_moblin_down_1 / 64)
        !byte < (sprite_enemies_moblin_up_0 / 64), < (sprite_enemies_moblin_up_1 / 64)
        !byte < (sprite_enemies_moblin_left_0 / 64), < (sprite_enemies_moblin_left_1 / 64)
        !byte < (sprite_enemies_moblin_right_0 / 64), < (sprite_enemies_moblin_right_1 / 64)

tektite_ptrs:
        !byte < (sprite_enemies_tektite_0 / 64), < (sprite_enemies_tektite_1 / 64)
        !byte < (sprite_enemies_tektite_0 / 64), < (sprite_enemies_tektite_1 / 64)
        !byte < (sprite_enemies_tektite_0 / 64), < (sprite_enemies_tektite_1 / 64)
        !byte < (sprite_enemies_tektite_0 / 64), < (sprite_enemies_tektite_1 / 64)

leever_ptrs:
        !byte < (sprite_enemies_leever_0 / 64), < (sprite_enemies_leever_1 / 64)
        !byte < (sprite_enemies_leever_0 / 64), < (sprite_enemies_leever_1 / 64)
        !byte < (sprite_enemies_leever_0 / 64), < (sprite_enemies_leever_1 / 64)
        !byte < (sprite_enemies_leever_0 / 64), < (sprite_enemies_leever_1 / 64)

peahat_ptrs:
        !byte < (sprite_enemies_peahat_0 / 64), < (sprite_enemies_peahat_1 / 64)
        !byte < (sprite_enemies_peahat_0 / 64), < (sprite_enemies_peahat_1 / 64)
        !byte < (sprite_enemies_peahat_0 / 64), < (sprite_enemies_peahat_1 / 64)
        !byte < (sprite_enemies_peahat_0 / 64), < (sprite_enemies_peahat_1 / 64)

armos_ptrs:
        !byte < (sprite_enemies_armos_0 / 64), < (sprite_enemies_armos_1 / 64)
        !byte < (sprite_enemies_armos_0 / 64), < (sprite_enemies_armos_1 / 64)
        !byte < (sprite_enemies_armos_0 / 64), < (sprite_enemies_armos_1 / 64)
        !byte < (sprite_enemies_armos_0 / 64), < (sprite_enemies_armos_1 / 64)

ghini_ptrs:
        !byte < (sprite_enemies_ghini_0 / 64), < (sprite_enemies_ghini_1 / 64)
        !byte < (sprite_enemies_ghini_0 / 64), < (sprite_enemies_ghini_1 / 64)
        !byte < (sprite_enemies_ghini_0 / 64), < (sprite_enemies_ghini_1 / 64)
        !byte < (sprite_enemies_ghini_0 / 64), < (sprite_enemies_ghini_1 / 64)

zora_ptrs:
        !byte < (sprite_enemies_zora_0 / 64), < (sprite_enemies_zora_1 / 64)
        !byte < (sprite_enemies_zora_0 / 64), < (sprite_enemies_zora_1 / 64)
        !byte < (sprite_enemies_zora_0 / 64), < (sprite_enemies_zora_1 / 64)
        !byte < (sprite_enemies_zora_0 / 64), < (sprite_enemies_zora_1 / 64)

lynel_ptrs:
        !byte < (sprite_enemies_lynel_0 / 64), < (sprite_enemies_lynel_1 / 64)
        !byte < (sprite_enemies_lynel_0 / 64), < (sprite_enemies_lynel_1 / 64)
        !byte < (sprite_enemies_lynel_0 / 64), < (sprite_enemies_lynel_1 / 64)
        !byte < (sprite_enemies_lynel_0 / 64), < (sprite_enemies_lynel_1 / 64)

keese_ptrs:
        !byte < (sprite_enemies_keese_0 / 64), < (sprite_enemies_keese_1 / 64)
        !byte < (sprite_enemies_keese_0 / 64), < (sprite_enemies_keese_1 / 64)
        !byte < (sprite_enemies_keese_0 / 64), < (sprite_enemies_keese_1 / 64)
        !byte < (sprite_enemies_keese_0 / 64), < (sprite_enemies_keese_1 / 64)

zol_ptrs:
        !byte < (sprite_enemies_zol_0 / 64), < (sprite_enemies_zol_1 / 64)
        !byte < (sprite_enemies_zol_0 / 64), < (sprite_enemies_zol_1 / 64)
        !byte < (sprite_enemies_zol_0 / 64), < (sprite_enemies_zol_1 / 64)
        !byte < (sprite_enemies_zol_0 / 64), < (sprite_enemies_zol_1 / 64)

gel_ptrs:
        !byte < (sprite_enemies_gel / 64), < (sprite_enemies_gel / 64)
        !byte < (sprite_enemies_gel / 64), < (sprite_enemies_gel / 64)
        !byte < (sprite_enemies_gel / 64), < (sprite_enemies_gel / 64)
        !byte < (sprite_enemies_gel / 64), < (sprite_enemies_gel / 64)

rope_ptrs:
        !byte < (sprite_enemies_rope_0 / 64), < (sprite_enemies_rope_1 / 64)
        !byte < (sprite_enemies_rope_0 / 64), < (sprite_enemies_rope_1 / 64)
        !byte < (sprite_enemies_rope_0 / 64), < (sprite_enemies_rope_1 / 64)
        !byte < (sprite_enemies_rope_0 / 64), < (sprite_enemies_rope_1 / 64)

stalfos_ptrs:
        !byte < (sprite_enemies_stalfos_0 / 64), < (sprite_enemies_stalfos_1 / 64)
        !byte < (sprite_enemies_stalfos_0 / 64), < (sprite_enemies_stalfos_1 / 64)
        !byte < (sprite_enemies_stalfos_0 / 64), < (sprite_enemies_stalfos_1 / 64)
        !byte < (sprite_enemies_stalfos_0 / 64), < (sprite_enemies_stalfos_1 / 64)

goriya_ptrs:
        !byte < (sprite_enemies_goriya_0 / 64), < (sprite_enemies_goriya_1 / 64)
        !byte < (sprite_enemies_goriya_0 / 64), < (sprite_enemies_goriya_1 / 64)
        !byte < (sprite_enemies_goriya_0 / 64), < (sprite_enemies_goriya_1 / 64)
        !byte < (sprite_enemies_goriya_0 / 64), < (sprite_enemies_goriya_1 / 64)

darknut_ptrs:
        !byte < (sprite_enemies_darknut_0 / 64), < (sprite_enemies_darknut_1 / 64)
        !byte < (sprite_enemies_darknut_0 / 64), < (sprite_enemies_darknut_1 / 64)
        !byte < (sprite_enemies_darknut_0 / 64), < (sprite_enemies_darknut_1 / 64)
        !byte < (sprite_enemies_darknut_0 / 64), < (sprite_enemies_darknut_1 / 64)

wizzrobe_ptrs:
        !byte < (sprite_enemies_wizzrobe_0 / 64), < (sprite_enemies_wizzrobe_1 / 64)
        !byte < (sprite_enemies_wizzrobe_0 / 64), < (sprite_enemies_wizzrobe_1 / 64)
        !byte < (sprite_enemies_wizzrobe_0 / 64), < (sprite_enemies_wizzrobe_1 / 64)
        !byte < (sprite_enemies_wizzrobe_0 / 64), < (sprite_enemies_wizzrobe_1 / 64)

wallmaster_ptrs:
        !byte < (sprite_enemies_wallmaster_0 / 64), < (sprite_enemies_wallmaster_1 / 64)
        !byte < (sprite_enemies_wallmaster_0 / 64), < (sprite_enemies_wallmaster_1 / 64)
        !byte < (sprite_enemies_wallmaster_0 / 64), < (sprite_enemies_wallmaster_1 / 64)
        !byte < (sprite_enemies_wallmaster_0 / 64), < (sprite_enemies_wallmaster_1 / 64)

likelike_ptrs:
        !byte < (sprite_enemies_likelike_0 / 64), < (sprite_enemies_likelike_1 / 64)
        !byte < (sprite_enemies_likelike_0 / 64), < (sprite_enemies_likelike_1 / 64)
        !byte < (sprite_enemies_likelike_0 / 64), < (sprite_enemies_likelike_1 / 64)
        !byte < (sprite_enemies_likelike_0 / 64), < (sprite_enemies_likelike_1 / 64)

polsvoice_ptrs:
        !byte < (sprite_enemies_polsvoice_0 / 64), < (sprite_enemies_polsvoice_1 / 64)
        !byte < (sprite_enemies_polsvoice_0 / 64), < (sprite_enemies_polsvoice_1 / 64)
        !byte < (sprite_enemies_polsvoice_0 / 64), < (sprite_enemies_polsvoice_1 / 64)
        !byte < (sprite_enemies_polsvoice_0 / 64), < (sprite_enemies_polsvoice_1 / 64)

gibdo_ptrs:
        !byte < (sprite_enemies_gibdo_0 / 64), < (sprite_enemies_gibdo_1 / 64)
        !byte < (sprite_enemies_gibdo_0 / 64), < (sprite_enemies_gibdo_1 / 64)
        !byte < (sprite_enemies_gibdo_0 / 64), < (sprite_enemies_gibdo_1 / 64)
        !byte < (sprite_enemies_gibdo_0 / 64), < (sprite_enemies_gibdo_1 / 64)

vire_ptrs:
        !byte < (sprite_enemies_vire_0 / 64), < (sprite_enemies_vire_1 / 64)
        !byte < (sprite_enemies_vire_0 / 64), < (sprite_enemies_vire_1 / 64)
        !byte < (sprite_enemies_vire_0 / 64), < (sprite_enemies_vire_1 / 64)
        !byte < (sprite_enemies_vire_0 / 64), < (sprite_enemies_vire_1 / 64)

bubble_ptrs:
        !byte < (sprite_enemies_bubble_0 / 64), < (sprite_enemies_bubble_1 / 64)
        !byte < (sprite_enemies_bubble_0 / 64), < (sprite_enemies_bubble_1 / 64)
        !byte < (sprite_enemies_bubble_0 / 64), < (sprite_enemies_bubble_1 / 64)
        !byte < (sprite_enemies_bubble_0 / 64), < (sprite_enemies_bubble_1 / 64)

trap_ptrs:
        !byte < (sprite_enemies_trap / 64), < (sprite_enemies_trap / 64)
        !byte < (sprite_enemies_trap / 64), < (sprite_enemies_trap / 64)
        !byte < (sprite_enemies_trap / 64), < (sprite_enemies_trap / 64)
        !byte < (sprite_enemies_trap / 64), < (sprite_enemies_trap / 64)

lanmola_ptrs:
        !byte < (sprite_enemies_lanmola_head / 64), < (sprite_enemies_lanmola_body / 64)
        !byte < (sprite_enemies_lanmola_head / 64), < (sprite_enemies_lanmola_body / 64)
        !byte < (sprite_enemies_lanmola_head / 64), < (sprite_enemies_lanmola_body / 64)
        !byte < (sprite_enemies_lanmola_head / 64), < (sprite_enemies_lanmola_body / 64)

aquamentus_ptrs:
        !byte < (sprite_enemies_aquamentus_0 / 64), < (sprite_enemies_aquamentus_1 / 64)
        !byte < (sprite_enemies_aquamentus_0 / 64), < (sprite_enemies_aquamentus_1 / 64)
        !byte < (sprite_enemies_aquamentus_0 / 64), < (sprite_enemies_aquamentus_1 / 64)
        !byte < (sprite_enemies_aquamentus_0 / 64), < (sprite_enemies_aquamentus_1 / 64)

dodongo_ptrs:
        !byte < (sprite_enemies_dodongo_0 / 64), < (sprite_enemies_dodongo_1 / 64)
        !byte < (sprite_enemies_dodongo_0 / 64), < (sprite_enemies_dodongo_1 / 64)
        !byte < (sprite_enemies_dodongo_0 / 64), < (sprite_enemies_dodongo_1 / 64)
        !byte < (sprite_enemies_dodongo_0 / 64), < (sprite_enemies_dodongo_1 / 64)

manhandla_ptrs:
        !byte < (sprite_enemies_manhandla_core / 64), < (sprite_enemies_manhandla_jaw / 64)
        !byte < (sprite_enemies_manhandla_core / 64), < (sprite_enemies_manhandla_jaw / 64)
        !byte < (sprite_enemies_manhandla_core / 64), < (sprite_enemies_manhandla_jaw / 64)
        !byte < (sprite_enemies_manhandla_core / 64), < (sprite_enemies_manhandla_jaw / 64)

gleeok_ptrs:
        !byte < (sprite_enemies_gleeok_0 / 64), < (sprite_enemies_gleeok_1 / 64)
        !byte < (sprite_enemies_gleeok_0 / 64), < (sprite_enemies_gleeok_1 / 64)
        !byte < (sprite_enemies_gleeok_0 / 64), < (sprite_enemies_gleeok_1 / 64)
        !byte < (sprite_enemies_gleeok_0 / 64), < (sprite_enemies_gleeok_1 / 64)

digdogger_ptrs:
        !byte < (sprite_enemies_digdogger / 64), < (sprite_enemies_digdogger / 64)
        !byte < (sprite_enemies_digdogger / 64), < (sprite_enemies_digdogger / 64)
        !byte < (sprite_enemies_digdogger / 64), < (sprite_enemies_digdogger / 64)
        !byte < (sprite_enemies_digdogger / 64), < (sprite_enemies_digdogger / 64)

gohma_ptrs:
        !byte < (sprite_enemies_gohma_closed / 64), < (sprite_enemies_gohma_open / 64)
        !byte < (sprite_enemies_gohma_closed / 64), < (sprite_enemies_gohma_open / 64)
        !byte < (sprite_enemies_gohma_closed / 64), < (sprite_enemies_gohma_open / 64)
        !byte < (sprite_enemies_gohma_closed / 64), < (sprite_enemies_gohma_open / 64)

patra_ptrs:
        !byte < (sprite_enemies_patra_center / 64), < (sprite_enemies_patra_orb / 64)
        !byte < (sprite_enemies_patra_center / 64), < (sprite_enemies_patra_orb / 64)
        !byte < (sprite_enemies_patra_center / 64), < (sprite_enemies_patra_orb / 64)
        !byte < (sprite_enemies_patra_center / 64), < (sprite_enemies_patra_orb / 64)

ganon_ptrs:
        !byte < (sprite_enemies_ganon_0 / 64), < (sprite_enemies_ganon_1 / 64)
        !byte < (sprite_enemies_ganon_0 / 64), < (sprite_enemies_ganon_1 / 64)
        !byte < (sprite_enemies_ganon_0 / 64), < (sprite_enemies_ganon_1 / 64)
        !byte < (sprite_enemies_ganon_0 / 64), < (sprite_enemies_ganon_1 / 64)

none_ptrs:
        !byte 0, 0, 0, 0, 0, 0, 0, 0


; ---------------------------------------------------------------------------
; get_enemy_sprite_and_color : extrait le pointeur de sprite et la couleur VIC-II
; Entrée : X = en_idx
; Sortie : A = pointeur de sprite (adresse / 64), Y = couleur VIC-II
; ---------------------------------------------------------------------------
get_enemy_sprite_and_color:
        ldy en_type,x
        lda en_sprite_tbl_lo,y
        sta .lookup+1
        lda en_sprite_tbl_hi,y
        sta .lookup+2
        lda en_dir,x
        asl
        ora en_anim,x
        tay
.lookup:
        lda $ffff,y                     ; charge depuis la table de frames 8-octets
        pha                             ; préserve le pointeur de sprite
        ldy en_type,x
        lda en_base_color,y
        tay                             ; Y = couleur
        pla                             ; restaure A = pointeur de sprite
        rts

; ---------------------------------------------------------------------------
; Table de spawn des ennemis pour les 9 salles (indices 0..8)
; Format par salle :
;   Ennemi 0 : type, spawn_tile_x, spawn_tile_y
;   Ennemi 1 : type, spawn_tile_x, spawn_tile_y
; ---------------------------------------------------------------------------
; ---------------------------------------------------------------------------
; ---------------------------------------------------------------------------
; Table de spawn dynamique des ennemis de la carte active ()
; ---------------------------------------------------------------------------
map_enemies_ptr:        !word $b800
map_enemies             = $b800
world_enemies           = map_enemies
underworld_enemies      = map_enemies

; ---------------------------------------------------------------------------
; get_rand : nombre pseudo-aléatoire 8 bits dans A
; ---------------------------------------------------------------------------
get_rand:
        lda rand_seed
        asl
        bcc +
        eor #$1d
+       sta rand_seed
        rts

; ---------------------------------------------------------------------------
; ---------------------------------------------------------------------------
; enemies_clear : désactive et masque tous les ennemis et projectiles (transitions)
; ---------------------------------------------------------------------------
enemies_clear:
        lda #0
        sta en_proj_active
        ldx #MAX_ENEMIES-1
-       sta en_type,x
        sta en_state,x
        sta sort_eff_y,x
        dex
        bpl -
        lda #0
        sta VIC_SPRITE_EXP_X
        sta VIC_SPRITE_EXP_Y
        lda VIC_SPRITE_EN
        and #%00000011                  ; conserve uniquement Link (0) et arme (1)
        sta VIC_SPRITE_EN
        lda #$ff
        sta VIC_SPRITE_Y3
        sta VIC_SPRITE_Y4
        sta VIC_SPRITE_Y5
        sta VIC_SPRITE_Y6
        sta VIC_SPRITE_Y7
        rts

; ---------------------------------------------------------------------------
; enemies_init : initialisation globale au lancement du jeu
; ---------------------------------------------------------------------------
enemies_init:
        lda #0
        sta player_hurt_timer
        sta en_proj_active
        ldx #MAX_ENEMIES-1
-       sta en_type,x
        sta en_state,x
        dex
        bpl -
        jsr enemies_room_init
        rts

; ---------------------------------------------------------------------------
; enemies_room_init : fait apparaître les ennemis de la salle courante (8 slots)
; ---------------------------------------------------------------------------
enemies_room_init:
        lda #0
        sta en_proj_active              ; réinitialise les projectiles en vol
        sta VIC_SPRITE_EXP_X
        sta VIC_SPRITE_EXP_Y

        ; Index de la formation (room_enemy_idx) * 24 octets dans map_enemies
        ldx current_room_idx
        lda room_enemy_idx,x
        sta ZP_SRC
        lda #0
        sta ZP_SRC+1
        asl ZP_SRC                      ; * 2
        rol ZP_SRC+1
        asl ZP_SRC                      ; * 4
        rol ZP_SRC+1
        asl ZP_SRC                      ; * 8
        rol ZP_SRC+1                    ; ZP_SRC = idx * 8
        lda ZP_SRC
        sta ZP_DST
        lda ZP_SRC+1
        sta ZP_DST+1                    ; ZP_DST = idx * 8
        asl ZP_SRC                      ; * 16
        rol ZP_SRC+1
        clc
        lda ZP_SRC
        adc ZP_DST                      ; * 16 + * 8 = * 24
        sta ZP_SRC
        lda ZP_SRC+1
        adc ZP_DST+1
        sta ZP_SRC+1
        clc
        lda ZP_SRC
        adc map_enemies_ptr
        sta ZP_SRC
        lda ZP_SRC+1
        adc map_enemies_ptr+1
        sta ZP_SRC+1

        ldy #0
-       sty en_idx
        jsr init_slot_from_table
        ldy en_idx
        iny
        cpy #MAX_ENEMIES
        bcc -
        rts

init_slot_from_table:
        ; Calcul offset slot * 3 dans la table de la salle
        lda en_idx
        asl
        clc
        adc en_idx
        tay                             ; Y = en_idx * 3

        ldx en_idx
        lda (ZP_SRC),y                  ; type
        sta en_type,x
        bne +
.dead_slot:
        lda #EN_STATE_DEAD
        sta en_state,x
        lda #$ff
        sta en_y,x
        rts
+
        ; Donjon : si la salle a déjà été nettoyée, les monstres (sauf pièges) ne réapparaissent pas
        lda current_world_type
        cmp #WORLD_DUNGEON
        bne .do_spawn_enemy
        ldx current_room_idx
        lda dungeon_room_state,x
        and #DUNG_ROOM_CLEARED
        beq .do_spawn_enemy
        ldx en_idx
        lda en_type,x
        cmp #TYPE_TRAP
        beq .do_spawn_enemy
        jmp .dead_slot

.do_spawn_enemy:
        lda en_idx
        asl
        clc
        adc en_idx
        tay                             ; Restaure Y = en_idx * 3
        ldx en_idx
        lda #EN_STATE_WALK
        sta en_state,x
        jsr get_rand
        and #3
        sta en_dir,x                    ; direction initiale aléatoire
        lda #0
        sta en_anim,x
        sta en_anim_tick,x
        sta en_hurt_timer,x

        ; Initialiser un minuteur décalé pour éviter la synchronisation des ennemis
        jsr get_rand
        and #31
        clc
        adc #20
        sta en_timer,x

        ; Points de vie initiaux
        lda en_type,x
        tax
        lda en_base_hp,x
        ldx en_idx
        sta en_hp,x

        ; Calcul offset en_x (16 bits, offset = en_idx * 2)
        txa
        asl
        tax                             ; X = en_idx * 2

        ; Lecture spawn_tile_x (slot * 3 + 1)
        iny                             ; Y = en_idx * 3 + 1
        lda (ZP_SRC),y                  ; tile_x (0..19)
        sta en_cand_x
        lda #0
        sta en_cand_x+1
        ; 16-bit shift * 16 :
        asl en_cand_x
        rol en_cand_x+1
        asl en_cand_x
        rol en_cand_x+1
        asl en_cand_x
        rol en_cand_x+1
        asl en_cand_x
        rol en_cand_x+1
        ; Position sprite : X = 20 + tile_x * 16
        clc
        lda en_cand_x
        adc #20
        sta en_x,x
        lda en_cand_x+1
        adc #0
        sta en_x+1,x

        ; Lecture spawn_tile_y (slot * 3 + 2)
        iny                             ; Y = en_idx * 3 + 2
        lda (ZP_SRC),y                  ; tile_y (0..9)
        ; Position sprite : Y = 80 + tile_y * 16
        asl
        asl
        asl
        asl
        clc
        adc #80
        ldx en_idx
        sta en_y,x
        rts

; ---------------------------------------------------------------------------
; enemies_update : appelé à chaque frame de jeu
; ---------------------------------------------------------------------------
enemies_update:
        inc en_global_frame             ; cadence globale de mouvement

        ; Décompte de l'invincibilité de Link
        lda player_hurt_timer
        beq +
        dec player_hurt_timer
+
        ; Décompte de la malédiction de l'épée (Bubble)
        lda sword_cursed_timer
        beq +
        dec sword_cursed_timer
+
        ; Mise à jour de chaque ennemi (0..7)
        ldx #0
-       stx en_idx
        jsr update_single_enemy
        ldx en_idx
        inx
        cpx #MAX_ENEMIES
        bcc -

        ; Mise à jour du projectile ennemi
        jsr update_enemy_projectile

        ; Détection des interactions / combats
        jsr check_sword_hits
        jsr check_item_hits
        jsr check_link_body_hits

        rts

; ---------------------------------------------------------------------------
; update_single_enemy : logique IA d'un ennemi (index dans en_idx)
; ---------------------------------------------------------------------------
update_single_enemy:
        ldx en_idx
        lda en_state,x
        bne +
        rts                             ; Mort / Inactif
+
        cmp #EN_STATE_DYING
        bne +
        jmp .update_dying
+       cmp #EN_STATE_HURT
        bne +
        jmp .update_hurt
+
        ; --- ÉTAT NORMAL (EN_STATE_WALK) ---
        ldx en_idx
        ldy en_type,x
        lda en_ai_type,y
        cmp #AI_HOP
        bne +
        jmp .exec_ai_hop
+       cmp #AI_BURROW
        bne +
        jmp .exec_ai_burrow
+       cmp #AI_FLY
        bne +
        jmp .exec_ai_fly
+       cmp #AI_RUSH
        bne +
        jmp .exec_ai_rush
+       cmp #AI_WATER
        bne +
        jmp .exec_ai_water
+       cmp #AI_SLIME
        bne +
        jmp .exec_ai_slime
+       cmp #AI_TELEPORT
        bne +
        jmp .exec_ai_teleport
+       cmp #AI_BOSS
        bne +
        jmp .exec_ai_boss
+       jmp .exec_ai_roam

.update_hurt:
        ; Ennemi touché : recul et fin du flash
        ldx en_idx
        dec en_hurt_timer,x
        bne +
        lda #EN_STATE_WALK
        sta en_state,x
+       rts

.update_dying:
        ; Animation du nuage de fumée de mort
        ldx en_idx
        dec en_timer,x
        bne +
        lda #EN_STATE_DEAD
        sta en_state,x
        ; Récompense : chance de butin (Rubis ou Cœur)
        jsr spawn_loot
+       rts

; ===========================================================================
; IA 1 : AI_HOP (Tektite rouge & bleu, Pols Voice)
; ===========================================================================
.exec_ai_hop:
        lda en_anim,x
        bne .hop_airborne

        ; --- AU SOL (Immobile) ---
        dec en_timer,x
        bne .hop_done
        ; Déclenche un grand bond !
        lda #1
        sta en_anim,x                   ; frame en l'air
        lda #20
        sta en_timer,x                  ; durée du saut (20 frames)

        ; 50% de chance de sauter vers Link, 50% aléatoire
        jsr get_rand
        and #1
        beq +
        jsr ai_calc_dir_to_player
        sta en_dir,x
        jmp .hop_airborne
+       jsr get_rand
        and #3
        sta en_dir,x

.hop_airborne:
        ; --- EN L'AIR ---
        ; Bondit de 2 pixels par frame au-dessus des obstacles !
        lda #2
        sta en_step_px
        jsr calc_step_candidate
        jsr check_bounds_only
        bcs .hop_hit_border
        jsr commit_step
        jmp .hop_tick

.hop_hit_border:
        ; Bord d'écran touché : fin précoce du saut
        lda #1
        sta en_timer,x

.hop_tick:
        dec en_timer,x
        bne .hop_done
        ; Atterrissage au sol !
        lda #0
        sta en_anim,x                   ; frame au sol
        ; Minuteur d'attente au sol (30..61 frames)
        jsr get_rand
        and #31
        clc
        adc #30
        sta en_timer,x
        ; Si atterri sur un rocher solide, re-décolle quasi immédiatement
        lda en_idx
        asl
        tay
        clc
        lda en_x,y
        adc #11
        sta col_x
        lda en_x+1,y
        adc #0
        sta col_x+1
        ldx en_idx
        clc
        lda en_y,x
        adc #12
        sta col_y
        jsr check_point_solid
        bcc .hop_done
        lda #3
        sta en_timer,x                  ; re-décolle dans 3 frames

.hop_done:
        rts

; ===========================================================================
; IA 2 : AI_BURROW (Leever rouge & bleu)
; ===========================================================================
.exec_ai_burrow:
        ; Demi-vitesse pour Leever rouge
        ldy en_type,x
        cpy #TYPE_LEEVER_RED
        bne +
        lda en_global_frame
        eor en_idx
        and #1
        bne .burrow_anim_only
+
        ; Suivi périodique de Link
        dec en_timer,x
        bne .burrow_step
        jsr ai_calc_dir_to_player
        sta en_dir,x
        jsr get_rand
        and #31
        clc
        adc #35
        sta en_timer,x

.burrow_step:
        lda #1
        sta en_step_px
        jsr calc_step_candidate
        jsr test_enemy_move
        bcs .burrow_blocked
        jsr commit_step
        jmp .burrow_anim

.burrow_blocked:
        jsr pick_unblocked_dir

.burrow_anim:
.burrow_anim_only:
        ; Animation de vrille / fouissement (toutes les 6 frames)
        inc en_anim_tick,x
        lda en_anim_tick,x
        cmp #6
        bcc +
        lda #0
        sta en_anim_tick,x
        lda en_anim,x
        eor #1
        sta en_anim,x
+       rts

; ===========================================================================
; IA 3 : AI_FLY (Keese, Peahat, Ghini, Bubble)
; ===========================================================================
.exec_ai_fly:
        ; Vol au-dessus du décor (seuls les bords d'écran sont vérifiés)
        dec en_timer,x
        bne .fly_step
        jsr get_rand
        and #3
        sta en_dir,x
        jsr get_rand
        and #31
        clc
        adc #30
        sta en_timer,x

.fly_step:
        lda #1
        sta en_step_px
        jsr calc_step_candidate
        jsr check_bounds_only
        bcc .fly_move_ok
        ; Rebond contre le bord de l'écran
        lda en_dir,x
        eor #1
        sta en_dir,x
        jmp .fly_anim

.fly_move_ok:
        jsr commit_step

.fly_anim:
        ; Battement d'ailes rapide (toutes les 4 frames)
        inc en_anim_tick,x
        lda en_anim_tick,x
        cmp #4
        bcc +
        lda #0
        sta en_anim_tick,x
        lda en_anim,x
        eor #1
        sta en_anim,x
+       rts

; ===========================================================================
; IA 4 : AI_RUSH (Rope, Trap)
; ===========================================================================
.exec_ai_rush:
        ; Test d'alignement avec Link sur un axe (marge de 8 px)
        lda en_y,x
        sec
        sbc player_y
        bcs +
        eor #$ff
        adc #1
+       cmp #8
        bcs .rush_chk_x
        ; Aligné horizontalement : fonce vers Link à 2 px/frame !
        lda en_idx
        asl
        tay
        lda player_x+1
        cmp en_x+1,y
        bcc .rush_go_left
        bne .rush_go_right
        lda player_x
        cmp en_x,y
        bcc .rush_go_left
.rush_go_right:
        lda #DIR_RIGHT
        sta en_dir,x
        jmp .rush_dash
.rush_go_left:
        lda #DIR_LEFT
        sta en_dir,x
        jmp .rush_dash

.rush_chk_x:
        lda en_idx
        asl
        tay
        sec
        lda en_x,y
        sbc player_x
        sta en_dx
        lda en_x+1,y
        sbc player_x+1
        sta en_dx+1
        bpl +
        sec
        lda #0
        sbc en_dx
        sta en_dx
        lda #0
        sbc en_dx+1
        sta en_dx+1
+       lda en_dx+1
        bne .rush_normal_walk
        lda en_dx
        cmp #8
        bcs .rush_normal_walk
        ; Aligné verticalement : fonce vers Link !
        lda en_y,x
        cmp player_y
        bcs .rush_go_up
        lda #DIR_DOWN
        sta en_dir,x
        jmp .rush_dash
.rush_go_up:
        lda #DIR_UP
        sta en_dir,x

.rush_dash:
        lda #2                          ; Charge vive : 2 px / frame
        sta en_step_px
        jsr calc_step_candidate
        jsr test_enemy_move
        bcs .rush_dash_blocked
        jsr commit_step
        jmp .rush_anim
.rush_dash_blocked:
        jsr pick_unblocked_dir
        jmp .rush_anim

.rush_normal_walk:
        ; Marche d'attente à demi-vitesse
        lda en_global_frame
        eor en_idx
        and #1
        bne .rush_anim
        lda #1
        sta en_step_px
        jsr calc_step_candidate
        jsr test_enemy_move
        bcs .rush_walk_blocked
        jsr commit_step
        dec en_timer,x
        bne .rush_anim
        jsr get_rand
        and #3
        sta en_dir,x
        jsr get_rand
        and #31
        clc
        adc #30
        sta en_timer,x
        jmp .rush_anim
.rush_walk_blocked:
        jsr pick_unblocked_dir

.rush_anim:
        inc en_anim_tick,x
        lda en_anim_tick,x
        cmp #6
        bcc +
        lda #0
        sta en_anim_tick,x
        lda en_anim,x
        eor #1
        sta en_anim,x
+       rts

; ===========================================================================
; IA : AI_WATER (Zora des rivières cracheur de boules de feu)
;   en_anim_tick,x : 0 = Sous l'eau (invisible)
;                    1 = Surgissement (zora_0)
;                    2 = Émergé (zora_1, tir boule de feu)
;                    3 = Plongeon (zora_0)
; ===========================================================================
.exec_ai_water:
        lda en_anim_tick,x
        bne +
        jmp .water_submerged
+       cmp #1
        bne +
        jmp .water_surfacing
+       cmp #2
        bne +
        jmp .water_emerged

        ; --- Phase 3 : Plongeon ---
        dec en_timer,x
        beq +
        rts
+       ; Redevient sous l'eau
        lda #0
        sta en_anim_tick,x
        sta en_anim,x
        ; Reste sous l'eau pendant 60..123 frames (~1.2s à 2.5s)
        jsr get_rand
        and #63
        clc
        adc #60
        sta en_timer,x
        rts

.water_submerged:
        ; --- Phase 0 : Sous l'eau ---
        dec en_timer,x
        beq +
        rts
+       ; Début du surgissement !
        lda #1
        sta en_anim_tick,x
        lda #0
        sta en_anim,x                   ; frame zora_0
        lda #16                         ; 16 frames de surgissement
        sta en_timer,x
        ; S'oriente vers Link
        jsr ai_calc_dir_to_player
        sta en_dir,x
        rts

.water_surfacing:
        ; --- Phase 1 : Surgissement ---
        dec en_timer,x
        beq +
        rts
+       ; Pleinement émergé !
        lda #2
        sta en_anim_tick,x
        lda #1
        sta en_anim,x                   ; frame zora_1
        lda #40                         ; reste émergé pendant 40 frames (~0.8s)
        sta en_timer,x
        ; S'oriente vers Link
        jsr ai_calc_dir_to_player
        sta en_dir,x
        ; Crache une boule de feu (prioritaire sur les projectiles ordinaires)
        lda en_proj_active
        beq +
        lda en_proj_type
        cmp #PROJ_FIREBALL
        bne +                           ; remplace un projectile ordinaire
        rts                             ; boule de feu déjà en cours
+       lda #1
        sta en_proj_active
        lda #PROJ_FIREBALL
        sta en_proj_type
        lda en_dir,x
        sta en_proj_dir
        lda en_idx
        asl
        tay
        lda en_x,y
        clc
        adc #4
        sta en_proj_x
        lda en_x+1,y
        adc #0
        sta en_proj_x+1
        ldx en_idx
        lda en_y,x
        clc
        adc #4
        sta en_proj_y
        jsr sound_enemy_shoot
        rts

.water_emerged:
        ; --- Phase 2 : Émergé ---
        dec en_timer,x
        beq +
        rts
+       ; Commence à plonger
        lda #3
        sta en_anim_tick,x
        lda #0
        sta en_anim,x                   ; frame zora_0
        lda #16                         ; 16 frames de plongeon
        sta en_timer,x
        rts

; ===========================================================================
; IA : AI_SLIME (Zol, Gel)
; ===========================================================================
.exec_ai_slime:
        lda en_global_frame
        and #1
        beq .slime_anim
        jmp .exec_ai_roam
.slime_anim:
        inc en_anim_tick,x
        lda en_anim_tick,x
        cmp #16
        bcc +
        lda #0
        sta en_anim_tick,x
        lda en_anim,x
        eor #1
        sta en_anim,x
+       rts

; ===========================================================================
; IA : AI_TELEPORT (Wizzrobe)
; ===========================================================================
.exec_ai_teleport:
        dec en_timer,x
        bne +
        lda en_anim,x
        eor #1
        sta en_anim,x
        bne .wizz_emerge
        ; Disparaît : 30 frames
        lda #30
        sta en_timer,x
        rts
.wizz_emerge:
        ; Apparaît et tire
        lda #40
        sta en_timer,x
        jsr spawn_enemy_magic_proj
+       rts

spawn_enemy_magic_proj:
        lda en_proj_active
        bne +
        lda #1
        sta en_proj_active
        lda #PROJ_MAGIC
        sta en_proj_type
        lda player_dir
        sta en_proj_dir
        lda en_idx
        asl
        tay
        lda en_x,y
        sta en_proj_x
        lda en_x+1,y
        sta en_proj_x+1
        ldx en_idx
        lda en_y,x
        sta en_proj_y
        jsr sound_enemy_shoot
+       rts

; ===========================================================================
; IA : AI_BOSS (Aquamentus, Dodongo, Manhandla, Gleeok, Digdogger, Gohma, etc.)
; ===========================================================================
.exec_ai_boss:
        ldy en_type,x
        cpy #TYPE_AQUAMENTUS
        bne +
        jmp .boss_aquamentus
+       cpy #TYPE_DODONGO
        bne +
        jmp .boss_dodongo
+       cpy #TYPE_MANHANDLA
        bne +
        jmp .boss_manhandla
+       cpy #TYPE_GLEEOK
        bne +
        jmp .boss_gleeok
+       cpy #TYPE_DIGDOGGER
        bne +
        jmp .boss_digdogger
+       cpy #TYPE_GOHMA_RED
        bne +
        jmp .boss_gohma
+       cpy #TYPE_GOHMA_BLUE
        bne +
        jmp .boss_gohma
+       cpy #TYPE_PATRA
        bne +
        jmp .boss_patra
+       cpy #TYPE_GANON
        bne +
        jmp .boss_ganon
+       jmp .exec_ai_roam

.boss_aquamentus:
        lda en_idx
        asl
        tay
        lda en_dir,x
        cmp #DIR_LEFT
        beq .aqua_left
        ; Droite
        clc
        lda en_x,y
        adc #1
        sta en_x,y
        lda en_x+1,y
        adc #0
        sta en_x+1,y
        lda en_x,y
        cmp #220
        bcc .aqua_shoot
        lda #DIR_LEFT
        sta en_dir,x
        jmp .aqua_shoot
.aqua_left:
        sec
        lda en_x,y
        sbc #1
        sta en_x,y
        lda en_x+1,y
        sbc #0
        sta en_x+1,y
        lda en_x,y
        cmp #150
        bcs .aqua_shoot
        lda #DIR_RIGHT
        sta en_dir,x
.aqua_shoot:
        dec en_timer,x
        beq +
        jmp .boss_anim
+       lda #60
        sta en_timer,x
        jsr spawn_boss_fireball
        jmp .boss_anim

.boss_dodongo:
        ; Mange une bombe si à portée
        lda item_active
        cmp #ITEM_BOMB
        bne +
        lda item_state
        bne +
        lda en_idx
        asl
        tay
        sec
        lda item_x
        sbc en_x,y
        bcs ++
        eor #$ff
        adc #1
++      cmp #18
        bcs +
        ; Mange la bombe !
        lda #ITEM_NONE
        sta item_active
        lda #50
        sta en_timer,x
        lda #EN_STATE_HURT
        sta en_state,x
        sec
        lda en_hp,x
        sbc #4
        bcc .dodongo_dead
        beq .dodongo_dead
        sta en_hp,x
        jsr sound_enemy_hit
        rts
.dodongo_dead:
        jmp .en_killed
+       jmp .exec_ai_roam

.boss_manhandla:
        lda en_hp,x
        cmp #4
        bcs +
        jsr .exec_ai_roam
+       jmp .exec_ai_roam

.boss_gleeok:
        inc en_anim_tick,x
        lda en_anim_tick,x
        and #16
        lsr
        lsr
        lsr
        lsr
        sta en_anim,x
        dec en_timer,x
        bne +
        lda #45
        sta en_timer,x
        jsr spawn_boss_fireball
+       rts

.boss_digdogger:
        jmp .exec_ai_roam

.boss_gohma:
        dec en_timer,x
        bne +
        lda #40
        sta en_timer,x
        lda en_anim,x
        eor #1
        sta en_anim,x
+       jmp .exec_ai_roam

.boss_patra:
        jmp .exec_ai_roam

.boss_ganon:
        dec en_timer,x
        bne +
        lda #50
        sta en_timer,x
        lda en_idx
        asl
        tay
        jsr get_rand
        and #127
        clc
        adc #90
        sta en_x,y
        jsr get_rand
        and #63
        clc
        adc #110
        ldx en_idx
        sta en_y,x
        jsr spawn_boss_fireball
+       rts

.boss_anim:
        inc en_anim_tick,x
        lda en_anim_tick,x
        and #16
        lsr
        lsr
        lsr
        lsr
        sta en_anim,x
        rts

spawn_boss_fireball:
        lda en_proj_active
        bne +
        lda #1
        sta en_proj_active
        lda #PROJ_FIREBALL
        sta en_proj_type
        lda #DIR_LEFT
        sta en_proj_dir
        lda en_idx
        asl
        tay
        lda en_x,y
        sta en_proj_x
        lda en_x+1,y
        sta en_proj_x+1
        ldx en_idx
        lda en_y,x
        clc
        adc #10
        sta en_proj_y
        jsr sound_enemy_shoot
+       rts

; ===========================================================================
; IA 5 : AI_ROAM (Octorok, Moblin, Lynel, Stalfos, Darknut, etc.)
; ===========================================================================
.exec_ai_roam:
        ; 1. Cadence selon le type (rouge = demi-vitesse, bleu/lynel = pleine vitesse)
        ldy en_type,x
        cpy #TYPE_OCTO_RED
        beq .roam_half_speed
        cpy #TYPE_MOBLIN_RED
        bne .roam_full_speed
.roam_half_speed:
        lda en_global_frame
        eor en_idx
        and #1
        bne .roam_anim_only

.roam_full_speed:
        ; 2. Calcul du pas candidat (1 px)
        lda #1
        sta en_step_px
        jsr calc_step_candidate

        ; 3. Test de collision avec le décor et bords d'écran
        jsr test_enemy_move
        bcs .roam_blocked

        ; 4. Déplacement libre : valide la position !
        jsr commit_step

        ; 5. Décompte de la marche dans cette direction
        dec en_timer,x
        bne .roam_anim

        ; Fin du cycle de marche droite : chance de tirer un projectile !
        lda en_proj_active
        bne .roam_new_dir
        ldy en_type,x
        lda en_proj_type_tbl,y
        beq .roam_new_dir
        ; 1 chance sur 4 de tirer à la fin d'une ligne droite
        jsr get_rand
        and #3
        bne .roam_new_dir
        jsr enemy_shoot

.roam_new_dir:
        ; Choix d'une nouvelle direction et d'une nouvelle durée
        jsr get_rand
        and #3
        sta en_dir,x
        jsr get_rand
        and #63
        clc
        adc #30
        sta en_timer,x
        jmp .roam_anim

.roam_blocked:
        ; Obstacle rencontré : ne pénètre pas le mur !
        ; Choisit une direction libre différente de l'obstacle
        jsr pick_unblocked_dir

.roam_anim:
.roam_anim_only:
        ; Alternance des pattes / animation de marche (toutes les 8 frames)
        inc en_anim_tick,x
        lda en_anim_tick,x
        cmp #8
        bcc +
        lda #0
        sta en_anim_tick,x
        lda en_anim,x
        eor #1
        sta en_anim,x
+       rts

; ---------------------------------------------------------------------------
; calc_step_candidate : calcule en_cand_x / en_cand_y selon en_dir et en_step_px
; Entrée : X = en_idx, en_step_px
; ---------------------------------------------------------------------------
calc_step_candidate:
        txa
        asl
        tay
        lda en_x,y
        sta en_cand_x
        lda en_x+1,y
        sta en_cand_x+1
        lda en_y,x
        sta en_cand_y

        lda en_dir,x
        cmp #DIR_UP
        beq .csc_up
        cmp #DIR_DOWN
        beq .csc_dn
        cmp #DIR_LEFT
        beq .csc_lf

        ; DROITE (+en_step_px)
        clc
        lda en_cand_x
        adc en_step_px
        sta en_cand_x
        lda en_cand_x+1
        adc #0
        sta en_cand_x+1
        rts

.csc_lf:
        sec
        lda en_cand_x
        sbc en_step_px
        sta en_cand_x
        lda en_cand_x+1
        sbc #0
        sta en_cand_x+1
        rts

.csc_up:
        sec
        lda en_cand_y
        sbc en_step_px
        sta en_cand_y
        rts

.csc_dn:
        clc
        lda en_cand_y
        adc en_step_px
        sta en_cand_y
        rts

; ---------------------------------------------------------------------------
; commit_step : valide le pas candidat dans en_x / en_y
; Entrée : X = en_idx, en_cand_x, en_cand_y
; ---------------------------------------------------------------------------
commit_step:
        ldx en_idx
        txa
        asl
        tay
        lda en_cand_x
        sta en_x,y
        lda en_cand_x+1
        sta en_x+1,y
        lda en_cand_y
        sta en_y,x
        rts

; ---------------------------------------------------------------------------
; check_bounds_only : vérifie si en_cand_x / en_cand_y est dans l'écran
; Sortie : Carry = 0 si OK, Carry = 1 si hors limites
; ---------------------------------------------------------------------------
check_bounds_only:
        lda en_cand_y
        cmp #PLAYER_Y_MIN
        bcc .cbo_bad
        cmp #PLAYER_Y_MAX
        bcs .cbo_bad

        lda en_cand_x+1
        beq .cbo_x_lo
        cmp #1
        bne .cbo_bad                    ; > 511
        lda en_cand_x
        cmp #<PLAYER_X_MAX
        bcs .cbo_bad
        clc
        rts
.cbo_x_lo:
        lda en_cand_x
        cmp #PLAYER_X_MIN
        bcc .cbo_bad
        clc
        rts
.cbo_bad:
        sec
        rts

; ---------------------------------------------------------------------------
; test_enemy_solid : teste si le bord d'attaque de l'ennemi touche un obstacle
; Entrée : X = en_idx, en_cand_x, en_cand_y, en_dir
; Sortie : Carry = 1 si bloqué, Carry = 0 si libre
; ---------------------------------------------------------------------------
test_enemy_solid:
        lda en_dir,x
        cmp #DIR_UP
        bne +
        jmp .tes_up
+       cmp #DIR_DOWN
        bne +
        jmp .tes_down
+       cmp #DIR_LEFT
        beq .tes_left

        ; --- DROITE (DIR_RIGHT) ---
        clc
        lda en_cand_x
        adc #15
        sta col_x
        lda en_cand_x+1
        adc #0
        sta col_x+1
        lda en_cand_y
        clc
        adc #8
        sta col_y1
        lda en_cand_y
        clc
        adc #14
        sta col_y2
        jsr check_v_edge
        rts

.tes_left:
        ; --- GAUCHE (DIR_LEFT) ---
        clc
        lda en_cand_x
        adc #7
        sta col_x
        lda en_cand_x+1
        adc #0
        sta col_x+1
        lda en_cand_y
        clc
        adc #8
        sta col_y1
        lda en_cand_y
        clc
        adc #14
        sta col_y2
        jsr check_v_edge
        rts

.tes_up:
        ; --- HAUT (DIR_UP) ---
        lda en_cand_y
        clc
        adc #8
        sta col_y
        clc
        lda en_cand_x
        adc #8
        sta col_x1
        lda en_cand_x+1
        adc #0
        sta col_x1+1
        clc
        lda en_cand_x
        adc #14
        sta col_x2
        lda en_cand_x+1
        adc #0
        sta col_x2+1
        jsr check_h_edge
        rts

.tes_down:
        ; --- BAS (DIR_DOWN) ---
        lda en_cand_y
        clc
        adc #15
        sta col_y
        clc
        lda en_cand_x
        adc #8
        sta col_x1
        lda en_cand_x+1
        adc #0
        sta col_x1+1
        clc
        lda en_cand_x
        adc #14
        sta col_x2
        lda en_cand_x+1
        adc #0
        sta col_x2+1
        jsr check_h_edge
        rts

; ---------------------------------------------------------------------------
; test_enemy_move : vérifie écran + tuiles solides
; Sortie : Carry = 0 si libre, Carry = 1 si bloqué
; ---------------------------------------------------------------------------
test_enemy_move:
        jsr check_bounds_only
        bcs .tem_blocked
        ldy en_type,x
        lda en_ai_type,y
        cmp #AI_FLY
        beq .tem_free
        jsr test_enemy_solid
        bcs .tem_blocked
.tem_free:
        clc
        rts
.tem_blocked:
        sec
        rts

; ---------------------------------------------------------------------------
; pick_unblocked_dir : choisit une direction différente de la direction bloquée
; ---------------------------------------------------------------------------
pick_unblocked_dir:
        ldx en_idx
        jsr get_rand
        and #3
        beq +
        ; 1, 2, ou 3 : tourne à 90° ou 180°
        clc
        adc en_dir,x
        and #3
        sta en_dir,x
        jmp ++
+
        ; Demi-tour (inverse)
        lda en_dir,x
        eor #1
        sta en_dir,x
++
        jsr get_rand
        and #31
        clc
        adc #30                         ; 30..61 frames (~0.6s à 1.2s)
        sta en_timer,x
        rts

; ---------------------------------------------------------------------------
; ai_calc_dir_to_player : calcule la meilleure direction (0..3) vers Link
; Entrée : X = en_idx
; Sortie : A = DIR_UP, DIR_DOWN, DIR_LEFT ou DIR_RIGHT
; ---------------------------------------------------------------------------
ai_calc_dir_to_player:
        ldx en_idx
        ; Calcul de dx = abs(player_x - en_x)
        txa
        asl
        tay
        sec
        lda player_x
        sbc en_x,y
        sta en_dx
        lda player_x+1
        sbc en_x+1,y
        sta en_dx+1
        bpl +
        sec
        lda #0
        sbc en_dx
        sta en_dx
        lda #0
        sbc en_dx+1
        sta en_dx+1
+
        ; Calcul de dy = abs(player_y - en_y)
        sec
        lda player_y
        sbc en_y,x
        bcs +
        eor #$ff
        adc #1
+       sta en_dy

        ; Axe horizontal si dx >= dy ou si dx+1 != 0
        lda en_dx+1
        bne .dir_horizontal
        lda en_dx
        cmp en_dy
        bcs .dir_horizontal

        ; Axe vertical prioritaire
        lda player_y
        cmp en_y,x
        bcs .dir_down
        lda #DIR_UP
        rts
.dir_down:
        lda #DIR_DOWN
        rts

.dir_horizontal:
        lda en_idx
        asl
        tay
        lda player_x+1
        cmp en_x+1,y
        bcc .dir_left
        bne .dir_right
        lda player_x
        cmp en_x,y
        bcc .dir_left
.dir_right:
        lda #DIR_RIGHT
        rts
.dir_left:
        lda #DIR_LEFT
        rts

; ---------------------------------------------------------------------------
; enemy_shoot : fait tirer l'ennemi courant (index dans en_idx)
; ---------------------------------------------------------------------------
enemy_shoot:
        ldx en_idx
        ldy en_type,x
        lda en_proj_type_tbl,y
        beq .no_proj_shot
        sta en_proj_type
        lda #1
        sta en_proj_active
        lda en_dir,x
        sta en_proj_dir

        lda en_idx
        asl
        tay
        lda en_x,y
        clc
        adc #4
        sta en_proj_x
        lda en_x+1,y
        adc #0
        sta en_proj_x+1
        ldx en_idx
        lda en_y,x
        clc
        adc #4
        sta en_proj_y

        ; Bruitage de tir
        jsr sound_enemy_shoot
.no_proj_shot:
        rts

; ---------------------------------------------------------------------------
; update_enemy_projectile : avance le rocher ou la lance
; ---------------------------------------------------------------------------
update_enemy_projectile:
        lda en_proj_active
        bne +
        rts
+
        lda en_proj_dir
        cmp #DIR_UP
        beq .pj_up
        cmp #DIR_DOWN
        beq .pj_dn
        cmp #DIR_LEFT
        beq .pj_lf

        ; Droite (+2 px)
        clc
        lda en_proj_x
        adc #2
        sta en_proj_x
        lda en_proj_x+1
        adc #0
        sta en_proj_x+1
        jmp .pj_chk
.pj_lf:
        sec
        lda en_proj_x
        sbc #2
        sta en_proj_x
        lda en_proj_x+1
        sbc #0
        sta en_proj_x+1
        jmp .pj_chk
.pj_up:
        sec
        lda en_proj_y
        sbc #2
        sta en_proj_y
        jmp .pj_chk
.pj_dn:
        clc
        lda en_proj_y
        adc #2
        sta en_proj_y

.pj_chk:
        ; 1. Hors écran X ?
        lda en_proj_x+1
        beq .pj_chk_x_lo
        cmp #1
        bne .pj_kill
        lda en_proj_x
        cmp #<PLAYER_X_MAX
        bcs .pj_kill
        jmp .pj_check_bounds_y
.pj_chk_x_lo:
        lda en_proj_x
        cmp #PLAYER_X_MIN
        bcc .pj_kill

.pj_check_bounds_y:
        ; 2. Hors écran Y ?
        lda en_proj_y
        cmp #PLAYER_Y_MIN
        bcc .pj_kill
        cmp #PLAYER_Y_MAX
        bcs .pj_kill

        ; 3. Collision avec le décor (arbre, rocher, mur)
        ; Les boules de feu et ondes magiques volent dans les airs (survolent l'eau, arbres et rochers)
        lda en_proj_type
        cmp #PROJ_FIREBALL
        beq .pj_skip_solid
        cmp #PROJ_MAGIC
        beq .pj_skip_solid

        lda en_proj_x
        clc
        adc #4
        sta col_x
        lda en_proj_x+1
        adc #0
        sta col_x+1
        lda en_proj_y
        clc
        adc #4
        sta col_y
        jsr check_point_solid
        bcs .pj_kill

.pj_skip_solid:
        ; 4. Test de parade au bouclier de Link ou dégâts
        jsr check_projectile_hit_link
        rts

.pj_kill:
        lda #0
        sta en_proj_active
        rts


; ---------------------------------------------------------------------------
; check_projectile_hit_link : parade au bouclier ou blessure de Link
; ---------------------------------------------------------------------------
check_projectile_hit_link:
        ; Distance X (16 bits)
        sec
        lda en_proj_x
        sbc player_x
        sta en_dx
        lda en_proj_x+1
        sbc player_x+1
        cmp #0
        bne .pj_dx_neg
        lda en_dx
        cmp #12
        bcs .pj_no_hit
        jmp .pj_chk_y
.pj_dx_neg:
        cmp #$ff
        bne .pj_no_hit
        lda en_dx
        cmp #$f4
        bcc .pj_no_hit

.pj_chk_y:
        ; Distance Y
        sec
        lda en_proj_y
        sbc player_y
        bcs +
        eor #$ff
        adc #1
+       cmp #12
        bcs .pj_no_hit

        ; --- CONTACT AVEC LINK ---
        ; Link pare-t-il avec son bouclier ?
        ; Condition : Link n'attaque pas et fait face au projectile arrivant
        lda player_attacking
        bne .link_takes_proj_hit

        ; Direction opposée ?
        lda en_proj_dir
        eor #1                          ; inverse UP/DOWN ou LEFT/RIGHT
        cmp player_dir
        bne .link_takes_proj_hit

        ; Link a-t-il un bouclier ?
        lda player_has_shield
        beq .link_takes_proj_hit
        cmp #2
        bcs .do_shield_block            ; Bouclier Magique : bloque tout !

        ; Petit Bouclier : les boules de feu et rayons magiques le traversent !
        lda en_proj_type
        cmp #PROJ_FIREBALL
        beq .link_takes_proj_hit
        cmp #PROJ_MAGIC
        beq .link_takes_proj_hit

.do_shield_block:
        ; PARÉ AU BOUCLIER !
        lda #0
        sta en_proj_active
        jsr sound_shield_block
        rts

.link_takes_proj_hit:
        lda #0
        sta en_proj_active
        jsr hurt_link
.pj_no_hit:
        rts

; ---------------------------------------------------------------------------
; check_sword_hits : teste si l'épée de Link tranche un ennemi
; ---------------------------------------------------------------------------
check_sword_hits:
        lda player_attacking
        bne +
        rts
+
        ; Calcule le point central de l'épée selon la direction de Link
        lda player_dir
        cmp #DIR_UP
        beq .sw_up
        cmp #DIR_DOWN
        beq .sw_dn
        cmp #DIR_LEFT
        beq .sw_lf

        ; Droite (+16 px)
        clc
        lda player_x
        adc #16
        sta en_tmp_x
        lda player_x+1
        adc #0
        sta en_tmp_x+1
        lda player_y
        clc
        adc #4
        sta en_tmp_y
        jmp .test_enemies_sword
.sw_lf:
        sec
        lda player_x
        sbc #16
        sta en_tmp_x
        lda player_x+1
        sbc #0
        sta en_tmp_x+1
        lda player_y
        clc
        adc #4
        sta en_tmp_y
        jmp .test_enemies_sword
.sw_up:
        lda player_x
        sta en_tmp_x
        lda player_x+1
        sta en_tmp_x+1
        sec
        lda player_y
        sbc #16
        sta en_tmp_y
        jmp .test_enemies_sword
.sw_dn:
        lda player_x
        sta en_tmp_x
        lda player_x+1
        sta en_tmp_x+1
        clc
        lda player_y
        adc #16
        sta en_tmp_y

.test_enemies_sword:
        ldx #0
-       stx en_tmp_loop
        jsr test_sword_single
        ldx en_tmp_loop
        inx
        cpx #MAX_ENEMIES
        bcc -
        rts

test_sword_single:
        stx en_idx
        lda en_state,x
        cmp #EN_STATE_WALK
        beq +
        rts                             ; ne peut être touché que s'il marche
+
        ; Distance X
        lda en_idx
        asl
        tax
        sec
        lda en_tmp_x
        sbc en_x,x
        sta en_dx
        lda en_tmp_x+1
        sbc en_x+1,x

.sw_dx_eval:
        pha
        ldx en_idx
        lda en_type,x
        cmp #TYPE_AQUAMENTUS
        beq .sw_aqua
        pla
        cmp #0
        bne +
        lda en_dx
        cmp #16
        bcs .sw_miss_local
        jmp .sw_chk_y
+       cmp #$ff
        bne .sw_miss_local
        lda en_dx
        cmp #$f0                        ; -16
        bcc .sw_miss_local

.sw_chk_y:
        ldx en_idx
        sec
        lda en_tmp_y
        sbc en_y,x
        bcs +
        eor #$ff
        adc #1
+       cmp #16
        bcs .sw_miss_local
        jmp .sw_hit_check

.sw_aqua:
        pla
        cmp #0
        bne +
        lda en_dx
        cmp #48
        bcs .sw_miss_local
        jmp .sw_aqua_y
+       cmp #$ff
        bne .sw_miss_local
        lda en_dx
        cmp #$f4
        bcc .sw_miss_local
.sw_aqua_y:
        sec
        lda en_tmp_y
        sbc en_y,x
        bcs +
        eor #$ff
        adc #1
+       cmp #40
        bcs .sw_miss_local
        jmp .sw_hit_check

.sw_miss_local:
        rts

.sw_hit_check:
        ; --- TOUCHÉ PAR L'ÉPÉE ! ---
        ldx en_idx
        ldy en_type,x

        ; 1. Darknut : bouclier frontal invulnérable
        lda en_ai_type,y
        cmp #AI_SHIELD
        bne .sw_not_shield
        lda en_dir,x
        eor #1
        cmp player_dir
        bne .sw_not_shield
        jsr sound_shield_block
        rts
.sw_not_shield:

        ; 2. Dodongo / Gohma : insensibles à l'épée ordinaire
        cpy #TYPE_DODONGO
        beq .sw_boss_block
        cpy #TYPE_GOHMA_RED
        beq .sw_boss_block
        cpy #TYPE_GOHMA_BLUE
        bne +
.sw_boss_block:
        jsr sound_shield_block
        rts
+
        ; 3. Bubble & Blade Trap : totalement invulnérables
        cpy #TYPE_BUBBLE
        beq .sw_cant_harm
        cpy #TYPE_TRAP
        beq .sw_cant_harm

        ; 4. Peahat : invulnérable en vol (anim 1)
        cpy #TYPE_PEAHAT
        bne +
        lda en_anim,x
        bne .sw_cant_harm
+
        ; 5. Zora : invulnérable sous l'eau (anim_tick 0)
        cpy #TYPE_ZORA
        bne +
        lda en_anim_tick,x
        beq .sw_cant_harm
+
        ; 6. Dégâts de l'épée de Link (Bois = 1, Blanche = 2, Magique = 4)
        lda player_has_sword
        beq .sw_cant_harm
        cmp #1
        beq .sw_wood
        cmp #2
        beq .sw_white
        lda #4
        jmp .sw_apply_dmg
.sw_white:
        lda #2
        jmp .sw_apply_dmg
.sw_wood:
        lda #1
.sw_apply_dmg:
        sta en_dx
        sec
        lda en_hp,x
        sbc en_dx
        beq .en_killed
        bcc .en_killed
        sta en_hp,x

        ; Ennemi blessé : recul et clignotement
        lda #EN_STATE_HURT
        sta en_state,x
        lda #10
        sta en_hurt_timer,x
        jsr sound_enemy_hit
        rts

.sw_cant_harm:
        rts

.en_killed:
        ldy en_type,x
        cpy #TYPE_ZOL
        bne +
        jsr split_zol_to_gels
+       cpy #TYPE_VIRE
        bne +
        jsr split_vire_to_keese
+       lda en_ai_type,y
        cmp #AI_BOSS
        bne +
        jsr dungeon_spawn_boss_heart
+       lda #EN_STATE_DYING
        sta en_state,x
        lda #16                         ; durée du nuage de fumée
        sta en_timer,x
        jsr sound_enemy_die
.sw_miss:
        rts

; ---------------------------------------------------------------------------
; check_item_hits : interactions des armes secondaires avec les ennemis
; ---------------------------------------------------------------------------
check_item_hits:
        lda item_active
        bne +
        rts
+
        ldx #0
-       stx en_tmp_loop
        jsr test_item_single
        ldx en_tmp_loop
        inx
        cpx #MAX_ENEMIES
        bcc -
        rts

test_item_single:
        stx en_idx
        lda en_state,x
        cmp #EN_STATE_WALK
        beq +
        rts
+
        lda en_type,x
        cmp #TYPE_ZORA
        bne +
        lda en_anim_tick,x
        bne +
        rts
+
        ; Calcule distance X avec item_x
        lda en_idx
        asl
        tay
        sec
        lda item_x
        sbc en_x,y
        sta en_dx
        lda item_x+1
        sbc en_x+1,y

.it_dx_eval:
        pha
        ldx en_idx
        lda en_type,x
        cmp #TYPE_AQUAMENTUS
        beq .it_aqua
        pla
        cmp #0
        bne +
        lda en_dx
        cmp #16
        bcs .it_miss_loc
        jmp .it_chk_y
+       cmp #$ff
        bne .it_miss_loc
        lda en_dx
        cmp #$f0
        bcc .it_miss_loc

.it_chk_y:
        ldx en_idx
        sec
        lda item_y
        sbc en_y,x
        bcs +
        eor #$ff
        adc #1
+       cmp #16
        bcs .it_miss_loc
        jmp .it_hit_exec

.it_aqua:
        pla
        cmp #0
        bne +
        lda en_dx
        cmp #48
        bcs .it_miss_loc
        jmp .it_aqua_y
+       cmp #$ff
        bne .it_miss_loc
        lda en_dx
        cmp #$f4
        bcc .it_miss_loc
.it_aqua_y:
        sec
        lda item_y
        sbc en_y,x
        bcs +
        eor #$ff
        adc #1
+       cmp #40
        bcs .it_miss_loc
        jmp .it_hit_exec

.it_miss_loc:
        rts

.it_hit_exec:

        ; --- IMPACT DE L'ARME SECONDAIRE ---
        lda item_active
        cmp #ITEM_BOW
        beq .arrow_hit
        cmp #ITEM_BOOMERANG
        beq .boom_hit
        cmp #ITEM_BOMB
        beq .bomb_blast_hit
        rts

.arrow_hit:
        ; Flèche mortelle
        lda #ITEM_NONE
        sta item_active
        ldx en_idx
        lda #EN_STATE_DYING
        sta en_state,x
        lda #16
        sta en_timer,x
        jsr sound_enemy_die
        rts

.boom_hit:
        ; Boomerang : étourdit le Moblin ou élimine l'Octorok
        ldx en_idx
        lda en_type,x
        cmp #TYPE_OCTO
        beq .arrow_hit                  ; Octorok meurt immédiatement
        ; Moblin est étourdi pendant 1.5s
        lda #EN_STATE_HURT
        sta en_state,x
        lda #75
        sta en_hurt_timer,x
        lda #1
        sta item_state                  ; le boomerang fait demi-tour
        jsr sound_shield_block
        rts

.bomb_blast_hit:
        ; Déflagration de bombe : mort instantanée
        lda item_state
        beq .it_miss                    ; pas encore explosée
        ldx en_idx
        lda #EN_STATE_DYING
        sta en_state,x
        lda #16
        sta en_timer,x
        jsr sound_enemy_die
.it_miss:
        rts

; ---------------------------------------------------------------------------
; check_link_body_hits : contact direct du corps d'un ennemi avec Link
; ---------------------------------------------------------------------------
check_link_body_hits:
        ldx #0
-       stx en_tmp_loop
        jsr test_body_single
        ldx en_tmp_loop
        inx
        cpx #MAX_ENEMIES
        bcc -
        rts

test_body_single:
        stx en_idx
        lda en_state,x
        cmp #EN_STATE_WALK
        beq +
        rts
+
        lda en_type,x
        cmp #TYPE_ZORA
        bne +
        lda en_anim_tick,x
        bne +
        rts
+
        lda en_idx
        asl
        tax
        sec
        lda en_x,x
        sbc player_x
        sta en_dx
        lda en_x+1,x
        sbc player_x+1

.bd_dx_eval:
        pha
        ldx en_idx
        lda en_type,x
        cmp #TYPE_AQUAMENTUS
        beq .bd_aqua
        pla
        cmp #0
        bne +
        lda en_dx
        cmp #12
        bcs .bd_miss_loc
        jmp .bd_chk_y
+       cmp #$ff
        bne .bd_miss_loc
        lda en_dx
        cmp #$f4
        bcc .bd_miss_loc

.bd_chk_y:
        ldx en_idx
        sec
        lda en_y,x
        sbc player_y
        bcs +
        eor #$ff
        adc #1
+       cmp #12
        bcs .bd_miss_loc
        jmp .bd_contact

.bd_aqua:
        pla
        cmp #0
        bne +
        lda en_dx
        cmp #16
        bcs .bd_miss_loc
        jmp .bd_aqua_y
+       cmp #$ff
        bne .bd_miss_loc
        lda en_dx
        cmp #$d8                        ; -40
        bcc .bd_miss_loc
.bd_aqua_y:
        sec
        lda en_y,x
        sbc player_y
        bcs +
        eor #$ff
        adc #1
+       cmp #36
        bcs .bd_miss_loc
        jmp .bd_contact

.bd_miss_loc:
        rts

.bd_contact:

        ; Contact direct : Link est blessé
        ldx en_idx
        ldy en_type,x

        ; Like Like avale le grand bouclier
        cpy #TYPE_LIKE_LIKE
        bne +
        lda player_has_shield
        cmp #2
        bcc +
        lda #1                          ; rétrograde au petit bouclier
        sta player_has_shield
+
        ; Bubble maudit l'épée
        cpy #TYPE_BUBBLE
        bne +
        lda #250
        sta sword_cursed_timer
+
        ; Wallmaster ramène Link à l'entrée du donjon
        cpy #TYPE_WALLMASTER
        bne +
        lda current_world_type
        cmp #WORLD_DUNGEON
        bne +
        lda dungeon_entrance_room_x
        sta current_room_x
        lda dungeon_entrance_room_y
        sta current_room_y
        lda #180
        sta player_x
        lda #0
        sta player_x+1
        lda #190
        sta player_y
        jsr load_room
        jsr enemies_init
        jsr enemies_prep_multiplexer
        jsr sound_enemy_hit
        rts
+
        jsr hurt_link
.bd_miss:
        rts

; ---------------------------------------------------------------------------
; hurt_link : inflige des dégâts à Link, recul et bruitage
; ---------------------------------------------------------------------------
hurt_link:
        lda player_hurt_timer
        beq +
        rts                             ; encore invincible
+       lda #32                         ; ~0.6s d'invulnérabilité
        sta player_hurt_timer

        ; Protection Anneau Bleu : divise les dégâts par 2
        lda player_has_blue_ring
        beq .take_damage
        inc player_blue_ring_hits
        lda player_blue_ring_hits
        and #1
        bne .skip_heart_loss

.take_damage:
        lda hud_cur_hearts
        beq .dead_link
        dec hud_cur_hearts
        jsr hud_render

.skip_heart_loss:
.dead_link:
        ; Son de blessure Link (géré proprement sur Voix 3)
        jsr sound_link_hurt
        rts

; ---------------------------------------------------------------------------
; spawn_loot : récompense aléatoire à la mort d'un ennemi
; ---------------------------------------------------------------------------
spawn_loot:
        jsr get_rand
        and #3
        beq .give_heart                 ; 25% : Cœur de vie
        cmp #1
        beq .give_rupee                 ; 25% : Rubis
        cmp #2
        beq .give_rupee                 ; 25% : Rubis
        rts                             ; 25% : rien

.give_rupee:
        inc hud_rupees
        jsr hud_render
        jsr sound_rupee
        rts

.give_heart:
        lda hud_cur_hearts
        cmp hud_max_hearts
        bcs +
        inc hud_cur_hearts
        jsr hud_render
        jsr sound_rupee
+       rts

; ---------------------------------------------------------------------------
; enemies_draw : alias pour préparer le multiplexeur (main.asm & debug.asm)
; ---------------------------------------------------------------------------
enemies_draw:
        jsr enemies_prep_multiplexer
        rts

; ---------------------------------------------------------------------------
; enemies_prep_multiplexer : trie les ennemis par Y et calcule la ligne de split
; ---------------------------------------------------------------------------
enemies_prep_multiplexer:
        jsr sort_enemies_y
        jsr calc_split_line
        rts

; ---------------------------------------------------------------------------
; sort_enemies_y : tri à bulles de sort_idx[0..7] selon la position Y (sort_eff_y)
; ---------------------------------------------------------------------------
sort_enemies_y:
        ; 1. Initialise sort_eff_y pour chaque slot
        ldx #7
.sey_loop:
        lda en_state,x
        beq .sey_dead
        lda en_type,x
        beq .sey_dead
        cmp #TYPE_ZORA
        bne +
        lda en_anim_tick,x
        beq .sey_dead                   ; Zora sous l'eau envoyé tout en bas ($FF)
+       lda en_y,x
        sta sort_eff_y,x
        jmp ++
.sey_dead:
        lda #$ff                        ; Inactif/mort envoyé tout en bas ($FF)
        sta sort_eff_y,x
++      txa
        sta sort_idx,x                  ; sort_idx[x] = x
        dex
        bpl .sey_loop

        ; 2. Tri à bulles sur sort_idx[0..7]
.bsort_pass:
        lda #0
        sta sort_swapped
        ldy #0
.bsort_cmp:
        lda sort_idx,y
        tax                             ; slot A
        sty sort_tmp_y
        lda sort_idx+1,y                ; slot B
        tay                             ; Y = slot B
        lda sort_eff_y,x
        cmp sort_eff_y,y
        bcc .bsort_next
        beq .bsort_next

        ; Swap
        ldy sort_tmp_y
        lda sort_idx,y
        pha
        lda sort_idx+1,y
        sta sort_idx,y
        pla
        sta sort_idx+1,y
        lda #1
        sta sort_swapped

.bsort_next:
        ldy sort_tmp_y
        iny
        cpy #7
        bcc .bsort_cmp

        lda sort_swapped
        bne .bsort_pass
        rts

; ---------------------------------------------------------------------------
; calc_split_line : calcule la ligne de séparation raster optimale
; ---------------------------------------------------------------------------
calc_split_line:
        lda sort_idx+3
        tax
        lda sort_eff_y,x
        cmp #$ff
        bne +
        lda #230
        sta multiplex_split_line
        rts
+       sta split_y3

        lda sort_idx+4
        tax
        lda sort_eff_y,x
        cmp #$ff
        bne +
        lda #230
        sta multiplex_split_line
        rts
+       sta split_y4

        ; Y3 + 22
        lda split_y3
        clc
        adc #22
        cmp split_y4
        bcc .use_gap
        beq .use_y4
        ; Chevauchement : on coupe au début de Y4
        lda split_y4
        jmp .clamp

.use_gap:
        lda split_y3
        clc
        adc #21
        jmp .clamp

.use_y4:
        lda split_y4

.clamp:
        cmp #110
        bcs +
        lda #110
+       cmp #225
        bcc +
        lda #225
+       sta multiplex_split_line
        rts

; ---------------------------------------------------------------------------
; init_raster_irq : installe le multiplexeur par interruption raster VIC-II
; ---------------------------------------------------------------------------
init_raster_irq:
        sei
        lda #$7f
        sta CIA1_ICR
        sta CIA2_ICR
        lda CIA1_ICR
        lda CIA2_ICR

        lda VIC_CTRL1
        and #%01111111                  ; Raster bit 8 = 0
        sta VIC_CTRL1
        lda #82                         ; Raster 82 : fin du HUD / début bordure droite
        sta VIC_RASTER

        lda #< irq_top
        sta $0314
        lda #> irq_top
        sta $0315

        lda #%00000001                  ; Active IRQ raster VIC-II
        sta VIC_IRQ_ENABLE
        asl VIC_IRQ_FLAG

        lda #0
        sta frame_ready
        cli
        rts

; ---------------------------------------------------------------------------
; irq_top : phase haute (raster 70) - configure Sprites 3, 4, 5, 6 (ennemis 0..3)
; ---------------------------------------------------------------------------
irq_top:
        ; Attend la bordure droite de la scanline 82 (cycles 57..63)
        ; pour basculer sans glitch vers la couleur de fond de la zone de jeu
        nop
        nop
        nop
        nop
        nop
        nop
        lda active_bg_color
        sta VIC_BACKGROUND

        lda game_state
        cmp #STATE_INVENTORY
        bne .check_playing
        lda inv_page
        cmp #INV_PAGE_ITEMS
        bne .skip_top
        jsr inv_p0_irq_row1
        lda #122                        ; Raster entre Y=106 et Y=134
        sta VIC_RASTER
        lda #< irq_p0_row2
        sta $0314
        lda #> irq_p0_row2
        sta $0315
        asl VIC_IRQ_FLAG
        jmp $ea81

.check_playing:
        cmp #STATE_PLAYING
        bne .skip_top
        lda current_world_type
        cmp #WORLD_DUNGEON
        bne +
        lda current_room_idx
        cmp #$41
        beq .skip_top
+

        lda item_active
        cmp #ITEM_BOMB
        bne .do_top
        lda item_state
        bne .skip_top

.do_top:

        jsr apply_top_sprites
        jsr apply_proj_sprite7

        lda multiplex_split_line
        sta VIC_RASTER
        lda #< irq_mid
        sta $0314
        lda #> irq_mid
        sta $0315

        asl VIC_IRQ_FLAG
        jmp $ea81

.skip_top:
        lda #250
        sta VIC_RASTER
        lda #< irq_bottom
        sta $0314
        lda #> irq_bottom
        sta $0315

        asl VIC_IRQ_FLAG
        jmp $ea81

; ---------------------------------------------------------------------------
; irq_mid : phase médiane - reconfigure Sprites 3, 4, 5, 6 (ennemis 4..7)
; ---------------------------------------------------------------------------
irq_mid:
        jsr apply_bottom_sprites

        lda #250
        sta VIC_RASTER
        lda #< irq_bottom
        sta $0314
        lda #> irq_bottom
        sta $0315

        asl VIC_IRQ_FLAG
        jmp $ea81

; ---------------------------------------------------------------------------
; irq_bottom : phase basse (raster 250, VBlank) - signal nouvelle frame
; ---------------------------------------------------------------------------
irq_bottom:
        ; Restaure le fond noir du HUD (lignes 0..3) pendant le VBlank
        lda #COL_BLACK
        sta VIC_BACKGROUND

        lda #1
        sta frame_ready

        lda #82                         ; Prochaine IRQ sur raster 82
        sta VIC_RASTER
        lda #< irq_top
        sta $0314
        lda #> irq_top
        sta $0315

        jsr music_update

        asl VIC_IRQ_FLAG
        jmp $ea81

; ---------------------------------------------------------------------------
; apply_top_sprites : injecte les 4 premiers ennemis triés dans Sprites 3..6
; ---------------------------------------------------------------------------
apply_top_sprites:
        ldx sort_idx+0
        jsr draw_virtual_to_spr3
        ldx sort_idx+1
        jsr draw_virtual_to_spr4
        ldx sort_idx+2
        jsr draw_virtual_to_spr5
        ldx sort_idx+3
        jsr draw_virtual_to_spr6
        rts

; ---------------------------------------------------------------------------
; apply_bottom_sprites : injecte les 4 derniers ennemis triés dans Sprites 3..6
; ---------------------------------------------------------------------------
apply_bottom_sprites:
        ldx sort_idx+4
        jsr draw_virtual_to_spr3
        ldx sort_idx+5
        jsr draw_virtual_to_spr4
        ldx sort_idx+6
        jsr draw_virtual_to_spr5
        ldx sort_idx+7
        jsr draw_virtual_to_spr6
        rts

; ---------------------------------------------------------------------------
; draw_virtual_to_spr3..6 : configure un sprite physique VIC-II
; Entrée : X = index virtuel ennemi (0..7)
; ---------------------------------------------------------------------------
draw_virtual_to_spr3:
        lda en_state,x
        beq .s3_disable
        lda en_type,x
        cmp #TYPE_ZORA
        bne .s3_draw
        lda en_anim_tick,x
        bne .s3_draw
.s3_disable:
        lda VIC_SPRITE_EN
        and #%11110111
        sta VIC_SPRITE_EN
        lda VIC_SPRITE_EXP_X
        and #%11110111
        sta VIC_SPRITE_EXP_X
        lda VIC_SPRITE_EXP_Y
        and #%11110111
        sta VIC_SPRITE_EXP_Y
        rts

.s3_draw:
        txa
        asl
        tay
        lda en_x,y
        sta VIC_SPRITE_X3
        lda en_y,x
        sta VIC_SPRITE_Y3

        lda en_x+1,y
        beq .s3_msb0
        lda VIC_SPRITE_MSB
        ora #%00001000
        sta VIC_SPRITE_MSB
        jmp +
.s3_msb0:
        lda VIC_SPRITE_MSB
        and #%11110111
        sta VIC_SPRITE_MSB
+
        lda en_state,x
        cmp #EN_STATE_DYING
        beq .s3_dying
        cmp #EN_STATE_HURT
        beq .s3_flash

        jsr get_enemy_sprite_and_color
        sta SPRITE_PTR3
        sty VIC_SPRITE_COL3
        jmp .s3_enable

.s3_flash:
        jsr get_enemy_sprite_and_color
        sta SPRITE_PTR3
        lda #COL_WHITE
        sta VIC_SPRITE_COL3
        jmp .s3_enable

.s3_dying:
        lda #COL_WHITE
        sta VIC_SPRITE_COL3
        lda en_timer,x
        cmp #8
        bcc +
        lda #< (sprite_enemies_enemy_death_0 / 64)
        sta SPRITE_PTR3
        jmp .s3_enable
+       lda #< (sprite_enemies_enemy_death_1 / 64)
        sta SPRITE_PTR3

.s3_enable:
        lda VIC_SPRITE_EN
        ora #%00001000
        sta VIC_SPRITE_EN
        lda VIC_SPRITE_MC
        ora #%00001000
        sta VIC_SPRITE_MC
        lda en_type,x
        cmp #TYPE_AQUAMENTUS
        bne .s3_no_exp
        lda VIC_SPRITE_EXP_X
        ora #%00001000
        sta VIC_SPRITE_EXP_X
        lda VIC_SPRITE_EXP_Y
        ora #%00001000
        sta VIC_SPRITE_EXP_Y
        rts
.s3_no_exp:
        lda VIC_SPRITE_EXP_X
        and #%11110111
        sta VIC_SPRITE_EXP_X
        lda VIC_SPRITE_EXP_Y
        and #%11110111
        sta VIC_SPRITE_EXP_Y
        rts

draw_virtual_to_spr4:
        lda en_state,x
        beq .s4_disable
        lda en_type,x
        cmp #TYPE_ZORA
        bne .s4_draw
        lda en_anim_tick,x
        bne .s4_draw
.s4_disable:
        lda VIC_SPRITE_EN
        and #%11101111
        sta VIC_SPRITE_EN
        rts

.s4_draw:
        txa
        asl
        tay
        lda en_x,y
        sta VIC_SPRITE_X4
        lda en_y,x
        sta VIC_SPRITE_Y4

        lda en_x+1,y
        beq .s4_msb0
        lda VIC_SPRITE_MSB
        ora #%00010000
        sta VIC_SPRITE_MSB
        jmp +
.s4_msb0:
        lda VIC_SPRITE_MSB
        and #%11101111
        sta VIC_SPRITE_MSB
+
        lda en_state,x
        cmp #EN_STATE_DYING
        beq .s4_dying
        cmp #EN_STATE_HURT
        beq .s4_flash

        jsr get_enemy_sprite_and_color
        sta SPRITE_PTR4
        sty VIC_SPRITE_COL4
        jmp .s4_enable

.s4_flash:
        jsr get_enemy_sprite_and_color
        sta SPRITE_PTR4
        lda #COL_WHITE
        sta VIC_SPRITE_COL4
        jmp .s4_enable

.s4_dying:
        lda #COL_WHITE
        sta VIC_SPRITE_COL4
        lda en_timer,x
        cmp #8
        bcc +
        lda #< (sprite_enemies_enemy_death_0 / 64)
        sta SPRITE_PTR4
        jmp .s4_enable
+       lda #< (sprite_enemies_enemy_death_1 / 64)
        sta SPRITE_PTR4

.s4_enable:
        lda VIC_SPRITE_EN
        ora #%00010000
        sta VIC_SPRITE_EN
        lda VIC_SPRITE_MC
        ora #%00010000
        sta VIC_SPRITE_MC
        rts

draw_virtual_to_spr5:
        lda en_state,x
        beq .s5_disable
        lda en_type,x
        cmp #TYPE_ZORA
        bne .s5_draw
        lda en_anim_tick,x
        bne .s5_draw
.s5_disable:
        lda VIC_SPRITE_EN
        and #%11011111
        sta VIC_SPRITE_EN
        rts

.s5_draw:
        txa
        asl
        tay
        lda en_x,y
        sta VIC_SPRITE_X5
        lda en_y,x
        sta VIC_SPRITE_Y5

        lda en_x+1,y
        beq .s5_msb0
        lda VIC_SPRITE_MSB
        ora #%00100000
        sta VIC_SPRITE_MSB
        jmp +
.s5_msb0:
        lda VIC_SPRITE_MSB
        and #%11011111
        sta VIC_SPRITE_MSB
+
        lda en_state,x
        cmp #EN_STATE_DYING
        beq .s5_dying
        cmp #EN_STATE_HURT
        beq .s5_flash

        jsr get_enemy_sprite_and_color
        sta SPRITE_PTR5
        sty VIC_SPRITE_COL5
        jmp .s5_enable

.s5_flash:
        jsr get_enemy_sprite_and_color
        sta SPRITE_PTR5
        lda #COL_WHITE
        sta VIC_SPRITE_COL5
        jmp .s5_enable

.s5_dying:
        lda #COL_WHITE
        sta VIC_SPRITE_COL5
        lda en_timer,x
        cmp #8
        bcc +
        lda #< (sprite_enemies_enemy_death_0 / 64)
        sta SPRITE_PTR5
        jmp .s5_enable
+       lda #< (sprite_enemies_enemy_death_1 / 64)
        sta SPRITE_PTR5

.s5_enable:
        lda VIC_SPRITE_EN
        ora #%00100000
        sta VIC_SPRITE_EN
        lda VIC_SPRITE_MC
        ora #%00100000
        sta VIC_SPRITE_MC
        rts

draw_virtual_to_spr6:
        lda en_state,x
        beq .s6_disable
        lda en_type,x
        cmp #TYPE_ZORA
        bne .s6_draw
        lda en_anim_tick,x
        bne .s6_draw
.s6_disable:
        lda VIC_SPRITE_EN
        and #%10111111
        sta VIC_SPRITE_EN
        rts

.s6_draw:
        txa
        asl
        tay
        lda en_x,y
        sta VIC_SPRITE_X6
        lda en_y,x
        sta VIC_SPRITE_Y6

        lda en_x+1,y
        beq .s6_msb0
        lda VIC_SPRITE_MSB
        ora #%01000000
        sta VIC_SPRITE_MSB
        jmp +
.s6_msb0:
        lda VIC_SPRITE_MSB
        and #%10111111
        sta VIC_SPRITE_MSB
+
        lda en_state,x
        cmp #EN_STATE_DYING
        beq .s6_dying
        cmp #EN_STATE_HURT
        beq .s6_flash

        jsr get_enemy_sprite_and_color
        sta SPRITE_PTR6
        sty VIC_SPRITE_COL6
        jmp .s6_enable

.s6_flash:
        jsr get_enemy_sprite_and_color
        sta SPRITE_PTR6
        lda #COL_WHITE
        sta VIC_SPRITE_COL6
        jmp .s6_enable

.s6_dying:
        lda #COL_WHITE
        sta VIC_SPRITE_COL6
        lda en_timer,x
        cmp #8
        bcc +
        lda #< (sprite_enemies_enemy_death_0 / 64)
        sta SPRITE_PTR6
        jmp .s6_enable
+       lda #< (sprite_enemies_enemy_death_1 / 64)
        sta SPRITE_PTR6

.s6_enable:
        lda VIC_SPRITE_EN
        ora #%01000000
        sta VIC_SPRITE_EN
        lda VIC_SPRITE_MC
        ora #%01000000
        sta VIC_SPRITE_MC
        rts

; ---------------------------------------------------------------------------
; apply_proj_sprite7 : affiche le projectile ennemi sur Sprite 7
; ---------------------------------------------------------------------------
apply_proj_sprite7:
        lda en_proj_active
        bne .drw_proj_active
        lda VIC_SPRITE_EN
        and #%01111111                  ; désactive Sprite 7
        sta VIC_SPRITE_EN
        rts

.drw_proj_active:
        lda en_proj_x
        sta VIC_SPRITE_X7
        lda en_proj_y
        sta VIC_SPRITE_Y7

        lda en_proj_x+1
        beq .pj_msb0
        lda VIC_SPRITE_MSB
        ora #%10000000
        sta VIC_SPRITE_MSB
        jmp +
.pj_msb0:
        lda VIC_SPRITE_MSB
        and #%01111111
        sta VIC_SPRITE_MSB
+
        lda en_proj_type
        cmp #PROJ_ROCK
        beq .pj_rock
        cmp #PROJ_SPEAR
        beq .pj_spear
        cmp #PROJ_FIREBALL
        beq .pj_fireball
        cmp #PROJ_MAGIC
        beq .pj_magic
        cmp #PROJ_BOOMERANG
        beq .pj_boom
        jmp .pj_rock

.pj_rock:
        lda #< (sprite_enemies_octo_rock / 64)
        sta SPRITE_PTR7
        lda #COL_LRED
        sta VIC_SPRITE_COL7
        jmp .pj_enable

.pj_spear:
        lda en_proj_dir
        cmp #DIR_LEFT
        beq +
        cmp #DIR_RIGHT
        beq +
        lda #< (sprite_enemies_moblin_spear_v / 64)
        sta SPRITE_PTR7
        jmp ++
+       lda #< (sprite_enemies_moblin_spear_h / 64)
        sta SPRITE_PTR7
++      lda #COL_LRED
        sta VIC_SPRITE_COL7
        jmp .pj_enable

.pj_fireball:
        lda #< (sprite_enemies_proj_fireball / 64)
        sta SPRITE_PTR7
        lda #COL_RED
        sta VIC_SPRITE_COL7
        jmp .pj_enable

.pj_magic:
        lda #< (sprite_enemies_proj_magic / 64)
        sta SPRITE_PTR7
        lda #COL_BLUE
        sta VIC_SPRITE_COL7
        jmp .pj_enable

.pj_boom:
        lda #< (sprite_enemies_proj_boom_en / 64)
        sta SPRITE_PTR7
        lda #COL_BROWN
        sta VIC_SPRITE_COL7
        jmp .pj_enable
.pj_enable:
        lda VIC_SPRITE_EN
        ora #%10000000                  ; active Sprite 7
        sta VIC_SPRITE_EN
        lda VIC_SPRITE_MC
        ora #%10000000
        sta VIC_SPRITE_MC
        rts

; ---------------------------------------------------------------------------
; Effets sonores delegues a src/sound.asm

; ---------------------------------------------------------------------------
; split_zol_to_gels : divise un Zol en 2 Gels dans un slot libre
; ---------------------------------------------------------------------------
split_zol_to_gels:
        txa
        pha
        lda #TYPE_GEL
        sta en_type,x
        lda #1
        sta en_hp,x

        ; Cherche un slot d'ennemi inactif pour le 2e Gel
        ldy #0
-       lda en_state,y
        beq .found_free_gel
        iny
        cpy #MAX_ENEMIES
        bcc -
        pla
        tax
        rts

.found_free_gel:
        lda #TYPE_GEL
        sta en_type,y
        lda #EN_STATE_WALK
        sta en_state,y
        lda #1
        sta en_hp,y
        lda en_dir,x
        eor #1
        sta en_dir,y
        lda #30
        sta en_timer,y

        ; Positionne à côté
        lda en_y,x
        clc
        adc #8
        sta en_y,y

        tya
        asl
        tay
        txa
        asl
        tax
        lda en_x,x
        clc
        adc #8
        sta en_x,y
        lda en_x+1,x
        adc #0
        sta en_x+1,y

        pla
        tax
        rts

; ---------------------------------------------------------------------------
; split_vire_to_keese : transforme Vire en 2 Keeses rouges à sa mort
; ---------------------------------------------------------------------------
split_vire_to_keese:
        txa
        pha
        lda #TYPE_KEESE_RED
        sta en_type,x
        lda #1
        sta en_hp,x

        ldy #0
-       lda en_state,y
        beq .found_free_keese
        iny
        cpy #MAX_ENEMIES
        bcc -
        pla
        tax
        rts

.found_free_keese:
        lda #TYPE_KEESE_RED
        sta en_type,y
        lda #EN_STATE_WALK
        sta en_state,y
        lda #1
        sta en_hp,y
        lda #30
        sta en_timer,y

        lda en_y,x
        sec
        sbc #8
        sta en_y,y

        tya
        asl
        tay
        txa
        asl
        tax
        lda en_x,x
        sec
        sbc #8
        sta en_x,y
        lda en_x+1,x
        sbc #0
        sta en_x+1,y

        pla
        tax
        rts
