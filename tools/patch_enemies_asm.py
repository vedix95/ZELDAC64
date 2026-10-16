#!/usr/bin/env python3
"""Générateur et intégrateur du nouveau src/enemies.asm avec tous les 44 ennemis officiels de Zelda 1.
"""
import re
from generate_enemies_asm import generate
from generate_enemy_tables import generate_asm as generate_tables

def main():
    hp, dmg, col, ai, proj, ptr_names = generate()
    tables_code = generate_tables()

    # Génération des tables d'octets
    hp_bytes = ", ".join(str(v) for v in hp)
    dmg_bytes = ", ".join(str(v) for v in dmg)
    col_bytes = ", ".join(c for c in col)
    ai_bytes = ", ".join(a for a in ai)
    proj_bytes = ", ".join(p for p in proj)
    
    lo_ptrs = ", ".join(f"<{name}" for name in ptr_names)
    hi_ptrs = ", ".join(f">{name}" for name in ptr_names)

    stat_tables = f"""
; ---------------------------------------------------------------------------
; Tables statistiques des 45 types d'ennemis Zelda (1986)
; ---------------------------------------------------------------------------
en_base_hp:
        !byte {hp_bytes}

en_base_damage:
        !byte {dmg_bytes}

en_base_color:
        !byte {col_bytes}

en_ai_type:
        !byte {ai_bytes}

en_proj_type_tbl:
        !byte {proj_bytes}

en_sprite_tbl_lo:
        !byte {lo_ptrs}

en_sprite_tbl_hi:
        !byte {hi_ptrs}

sword_cursed_timer:     !byte 0

{tables_code}

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
        ldy en_type,x
        lda en_base_color,y
        tay
        rts
"""

    with open("src/enemies.asm", "r", encoding="utf-8") as f:
        content = f.read()

    # 1. Remplacer les constantes en tête de fichier
    header_pattern = r"(MAX_ENEMIES\s*=\s*8\s*\n)(.*?)(; Variables globales des ennemis)"
    new_constants = """MAX_ENEMIES             = 8

; --- Identifiants officiels des ennemis de The Legend of Zelda (1986) ---
TYPE_NONE               = 0

; Overworld
TYPE_OCTO_RED           = 1             ; Octorok rouge (1 HP, rocher lent)
TYPE_OCTO_BLUE          = 2             ; Octorok bleu (2 HP, rocher rapide)
TYPE_MOBLIN_RED         = 3             ; Moblin rouge (2 HP, lance lente)
TYPE_MOBLIN_BLUE        = 4             ; Moblin bleu (3 HP, lance rapide)
TYPE_TEKTITE_RED        = 5             ; Tektite rouge (1 HP, sauts erratiques)
TYPE_TEKTITE_BLUE       = 6             ; Tektite bleu (1 HP, sauts agressifs)
TYPE_LEEVER_RED         = 7             ; Leever rouge (2 HP, fouisseur périodique)
TYPE_LEEVER_BLUE        = 8             ; Leever bleu (4 HP, embuscade rapide en groupe)
TYPE_PEAHAT             = 9             ; Peahat (2 HP, fleur hélice invincible en vol)
TYPE_ARMOS              = 10            ; Armos (3 HP, statue éveillée au contact)
TYPE_GHINI              = 11            ; Ghini (9 HP, fantôme du cimetière)
TYPE_ZORA               = 12            ; Zora (2 HP, cracheur de boules de feu dans l'eau)
TYPE_LYNEL_RED          = 13            ; Lynel rouge (4 HP, centaure lion redoutable)
TYPE_LYNEL_BLUE         = 14            ; Lynel bleu (6 HP, centaure lion d'élite)

; Donjons / Souterrains
TYPE_KEESE_RED          = 15            ; Keese rouge (1 HP, chauve-souris)
TYPE_KEESE_BLUE         = 16            ; Keese bleu (1 HP, chauve-souris)
TYPE_ZOL                = 17            ; Zol (2 HP, gros slime se divisant en 2 Gels)
TYPE_GEL                = 18            ; Gel (1 HP, petit slime)
TYPE_ROPE               = 19            ; Rope (1 HP, serpent chargeant à vue)
TYPE_STALFOS            = 20            ; Stalfos (2 HP, squelette à 2 épées)
TYPE_GORIYA_RED         = 21            ; Goriya rouge (3 HP, lanceur de boomerang)
TYPE_GORIYA_BLUE        = 22            ; Goriya bleu (5 HP, lanceur de boomerang)
TYPE_DARKNUT_RED        = 23            ; Darknut rouge (4 HP, chevalier à bouclier frontal)
TYPE_DARKNUT_BLUE       = 24            ; Darknut bleu (8 HP, chevalier d'élite)
TYPE_WIZZROBE_RED       = 25            ; Wizzrobe rouge (5 HP, sorcier téléporteur)
TYPE_WIZZROBE_BLUE      = 26            ; Wizzrobe bleu (10 HP, sorcier traversant les murs)
TYPE_WALLMASTER         = 27            ; Wallmaster (2 HP, main murale kidnappeuse)
TYPE_LIKE_LIKE          = 28            ; Like Like (9 HP, mangeur de bouclier)
TYPE_POLS_VOICE         = 29            ; Pols Voice (10 HP, oreilles vulnérables aux flèches)
TYPE_GIBDO              = 30            ; Gibdo (6 HP, momie résistante)
TYPE_VIRE               = 31            ; Vire (4 HP, démon ailé se scindant en Keeses)
TYPE_BUBBLE             = 32            ; Bubble (invincible, crâne maudissant l'épée)
TYPE_TRAP               = 33            ; Blade Trap (invincible, piège à lames fendant)
TYPE_LANMOLA_RED        = 34            ; Lanmola rouge (2 HP par segment)
TYPE_LANMOLA_BLUE       = 35            ; Lanmola bleu (4 HP par segment)

; Bosses officiels
TYPE_AQUAMENTUS         = 36            ; Boss Niveau 1 & 7 (6 HP, dragon cornu)
TYPE_DODONGO            = 37            ; Boss Niveau 2 (8 HP, dinosaure mangeur de bombes)
TYPE_MANHANDLA          = 38            ; Boss Niveau 3 (8 HP, plante carnivore à 4 mâchoires)
TYPE_GLEEOK             = 39            ; Boss Niveau 4 (8 HP, hydre multi-têtes)
TYPE_DIGDOGGER          = 40            ; Boss Niveau 5 (8 HP, oursin géant flûte)
TYPE_GOHMA_RED          = 41            ; Boss Niveau 6 (2 HP, œil flèche rouge)
TYPE_GOHMA_BLUE         = 42            ; Boss Niveau 6 (4 HP, œil flèche bleu)
TYPE_PATRA              = 43            ; Boss Niveau 8 (10 HP, œil ailé et orbes)
TYPE_GANON              = 44            ; Boss Niveau 9 (16 HP, démon cochon final)

TYPE_COUNT              = 45

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

"""

    content = re.sub(header_pattern, r"\1" + new_constants + r"\3", content, flags=re.DOTALL)

    # 2. Remplacer les anciennes tables octo_ptrs et moblin_ptrs par nos nouvelles tables complètes
    old_tables_pattern = r"(; Tables des pointeurs de sprites selon \(direction \* 2 \+ anim\)\s*\n)(.*?)(\n; ---------------------------------------------------------------------------\n; Table de spawn)"
    content = re.sub(old_tables_pattern, stat_tables + r"\3", content, flags=re.DOTALL)

    # 3. Remplacer l'assignation de HP dans enemies_spawn_room
    spawn_hp_pattern = r"lda en_type,x\s*\n\s*cmp #TYPE_OCTO\s*\n\s*bne \+\+\s*\n\s*lda #OCTO_HP\s*\n\s*jmp \+\+\+\s*\n\+\+\s*lda #MOBLIN_HP\s*\n\+\+\+\s*sta en_hp,x"
    new_spawn_hp = "ldy en_type,x\n        lda en_base_hp,y\n        sta en_hp,x"
    content = re.sub(spawn_hp_pattern, new_spawn_hp, content)

    # 4. Mettre à jour draw_virtual_to_spr3..6
    for spr_num, spr_col, spr_ptr, spr_mask in [
        (3, "VIC_SPRITE_COL3", "SPRITE_PTR3", "%00001000"),
        (4, "VIC_SPRITE_COL4", "SPRITE_PTR4", "%00010000"),
        (5, "VIC_SPRITE_COL5", "SPRITE_PTR5", "%00100000"),
        (6, "VIC_SPRITE_COL6", "SPRITE_PTR6", "%01000000")
    ]:
        old_spr_pattern = rf"draw_virtual_to_spr{spr_num}:.*?(rts\n)"
        # Trouver la partie après .s{spr_num}_msb0: ... +
        old_draw_inner = rf"(\+.*?lda en_state,x\s*\n\s*cmp #EN_STATE_DYING\s*\n\s*beq \.s{spr_num}_dying\s*\n\s*cmp #EN_STATE_HURT\s*\n\s*beq \.s{spr_num}_flash\s*\n)(.*?)(\.s{spr_num}_flash:)"
        new_draw_inner = rf"\1        jsr get_enemy_sprite_and_color\n        sta {spr_ptr}\n        sty {spr_col}\n        jmp .s{spr_num}_enable\n\n"
        content = re.sub(old_draw_inner, new_draw_inner + r"\3", content, flags=re.DOTALL)

    # 5. Mettre à jour le projectile (draw_proj_spr7)
    old_proj_draw = r"(\.pj_msb0:\s*\n\s*lda VIC_SPRITE_MSB\s*\n\s*and #%01111111\s*\n\s*sta VIC_SPRITE_MSB\s*\n\+)(.*?)(\.pj_enable:)"
    new_proj_draw = r"""\1
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
"""
    content = re.sub(old_proj_draw, new_proj_draw + r"\3", content, flags=re.DOTALL)

    # 6. Mettre à jour enemy_shoot pour utiliser en_proj_type_tbl
    old_shoot = r"enemy_shoot:\s*\n\s*ldx en_idx\s*\n\s*lda #1\s*\n\s*sta en_proj_active\s*\n\s*lda en_type,x\s*\n\s*sta en_proj_type"
    new_shoot = """enemy_shoot:
        ldx en_idx
        ldy en_type,x
        lda en_proj_type_tbl,y
        beq .no_proj_shot
        sta en_proj_type
        lda #1
        sta en_proj_active"""
    content = re.sub(old_shoot, new_shoot, content)
    content = content.replace("jsr sound_enemy_shoot\n        rts", "jsr sound_enemy_shoot\n.no_proj_shot:\n        rts")

    # 7. Mettre à jour check_projectile_hit_link (petit bouclier vs grand bouclier)
    old_proj_hit = r"(; Link pare-t-il avec son bouclier \?.*?; PARÉ AU BOUCLIER !\s*\n\s*lda #0\s*\n\s*sta en_proj_active\s*\n\s*jsr sound_shield_block\s*\n\s*rts)"
    new_proj_hit = """; Link pare-t-il avec son bouclier ?
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
        rts"""
    content = re.sub(old_proj_hit, new_proj_hit, content, flags=re.DOTALL)

    # 8. Mettre à jour sword hit : Darknut frontal shield, Dodongo/Gohma sword block, degats selon player_has_sword, Zol split
    old_sword_hit = r"(; --- TOUCHÉ PAR L'ÉPÉE ! ---\s*\n\s*ldx en_idx\s*\n\s*dec en_hp,x\s*\n\s*beq \.en_killed)"
    new_sword_hit = """; --- TOUCHÉ PAR L'ÉPÉE ! ---
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
        ; 5. Dégâts de l'épée de Link (Bois = 1, Blanche = 2, Magique = 4)
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
        rts"""
    content = re.sub(old_sword_hit, new_sword_hit, content)

    # 9. Zol / Vire split à la mort
    old_en_killed = r"\.en_killed:\s*\n\s*lda #EN_STATE_DYING"
    new_en_killed = """.en_killed:
        ldy en_type,x
        cpy #TYPE_ZOL
        bne +
        jsr split_zol_to_gels
+       cpy #TYPE_VIRE
        bne +
        jsr split_vire_to_keese
+       lda #EN_STATE_DYING"""
    content = re.sub(old_en_killed, new_en_killed, content)

    # 10. Contact Link dégâts selon en_base_damage + Like Like avale bouclier + Bubble maudit épée
    old_body_hit = r"(; Contact direct : Link est blessé\s*\n\s*jsr hurt_link)"
    new_body_hit = """; Contact direct : Link est blessé
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
        jsr hurt_link"""
    content = re.sub(old_body_hit, new_body_hit, content)

    # Ajouter les routines split_zol_to_gels et split_vire_to_keese à la fin
    split_routines = """
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
"""
    content += split_routines

    with open("src/enemies.asm", "w", encoding="utf-8") as f:
        f.write(content)
    print("src/enemies.asm mis a jour avec succes !")

if __name__ == "__main__":
    main()
