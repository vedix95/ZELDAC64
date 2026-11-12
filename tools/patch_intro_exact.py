#!/usr/bin/env python3
import sys

with open('src/intro.asm', 'r') as f:
    code = f.read()

# 1. Variables et constantes
assert 'intro_sub_timer' not in code
code = code.replace(
    'intro_timer:         !word 0\n',
    'intro_timer:         !word 0\nintro_sub_timer:     !word 0\n'
)

code = code.replace(
    'intro_text_color:    !byte COL_BLACK\n',
    'intro_text_color:    !byte COL_WHITE\n'
)

frame_consts = """CHAR_CANDLE     = 103

; Glyphes de bordures officielles NES
CHAR_FRAME_TL   = 249
CHAR_FRAME_TR   = 250
CHAR_FRAME_BL   = 251
CHAR_FRAME_BR   = 252
CHAR_FRAME_H    = 253
CHAR_FRAME_V    = 254
CHAR_FRAME_X    = 255
"""
code = code.replace('CHAR_CANDLE     = 103\n', frame_consts)

code = code.replace(
    'SPR_BLOCK_LINK = (intro_link_spr_data / 64)\n',
    'SPR_BLOCK_LINK = (intro_link_spr_data / 64)\nSPR_BLOCK_TRIFORCE = (spr_triforce_triangle / 64)\n'
)

# 2. Couleurs de intro_draw_waterfall
code = code.replace(
    'intro_draw_waterfall:\n        lda #COL_ORANGE\n        sta VIC_BACKGROUND\n        sta VIC_BORDER\n',
    'intro_draw_waterfall:\n        lda #COL_BLACK\n        sta VIC_BACKGROUND\n        sta VIC_BORDER\n'
)

code = code.replace(
    '        lda txt_nintendo,x\n        beq +\n        sta SCREEN_RAM+960+12,x\n        lda #COL_BLACK\n        sta COLOR_RAM+960+12,x',
    '        lda txt_nintendo,x\n        beq +\n        sta SCREEN_RAM+960+12,x\n        lda #COL_WHITE\n        sta COLOR_RAM+960+12,x'
)

# Remplacer les falaises COL_GREY par COL_BROWN dans intro_draw_waterfall
# (lignes 550..770)
code = code.replace(
    '        lda #CHAR_CLIFF_FACE\n        sta (ZP_SCR),y\n        lda #COL_GREY\n',
    '        lda #CHAR_CLIFF_FACE\n        sta (ZP_SCR),y\n        lda #COL_BROWN\n'
)

# 3. Palettes crepuscule/nuit restant sur fond noir pur
old_palettes = """pal_bg_colors:
        !byte COL_ORANGE, COL_ORANGE, COL_ORANGE, COL_ORANGE, COL_ORANGE
        !byte COL_ORANGE, COL_BROWN,  COL_BROWN,  COL_BLACK,  COL_BLACK
        !byte COL_BLACK,  COL_BLACK,  COL_BLACK,  COL_BLACK,  COL_BLACK, COL_BLACK
pal_cliff_colors:
        !byte COL_GREY,   COL_GREY,   COL_GREY,   COL_GREY,   COL_DGREY
        !byte COL_DGREY,  COL_DGREY,  COL_DGREY,  COL_BLACK,  COL_BLACK
        !byte COL_BLACK,  COL_BLACK,  COL_BLACK,  COL_BLACK,  COL_BLACK, COL_BLACK
pal_water_colors:
        !byte COL_CYAN,   COL_CYAN,   COL_CYAN,  COL_LBLUE, COL_LBLUE
        !byte COL_LBLUE,  COL_CYAN,   COL_CYAN,  COL_CYAN,  COL_LBLUE
        !byte COL_BLUE,   COL_BLACK,  COL_BLACK, COL_BLACK, COL_BLACK, COL_BLACK
pal_tree_colors:
        !byte COL_GREEN,  COL_GREEN,  COL_GREEN, COL_GREEN, COL_GREEN
        !byte COL_DGREY,  COL_DGREY,  COL_BLACK, COL_BLACK, COL_BLACK
        !byte COL_BLACK,  COL_BLACK,  COL_BLACK, COL_BLACK, COL_BLACK, COL_BLACK"""

new_palettes = """pal_bg_colors:
        !byte COL_BLACK,  COL_BLACK,  COL_BLACK,  COL_BLACK,  COL_BLACK
        !byte COL_BLACK,  COL_BLACK,  COL_BLACK,  COL_BLACK,  COL_BLACK
        !byte COL_BLACK,  COL_BLACK,  COL_BLACK,  COL_BLACK,  COL_BLACK, COL_BLACK
pal_cliff_colors:
        !byte COL_BROWN,  COL_BROWN,  COL_BROWN,  COL_BROWN,  COL_ORANGE
        !byte COL_ORANGE, COL_BROWN,  COL_BROWN,  COL_DGREY,  COL_DGREY
        !byte COL_DGREY,  COL_BLUE,   COL_BLUE,   COL_BLACK,  COL_BLACK, COL_BLACK
pal_water_colors:
        !byte COL_LBLUE,  COL_LBLUE,  COL_CYAN,   COL_CYAN,   COL_CYAN
        !byte COL_LBLUE,  COL_BLUE,   COL_BLUE,   COL_BLUE,   COL_BLUE
        !byte COL_BLUE,   COL_BLACK,  COL_BLACK,  COL_BLACK,  COL_BLACK, COL_BLACK
pal_tree_colors:
        !byte COL_GREEN,  COL_GREEN,  COL_GREEN,  COL_GREEN,  COL_GREEN
        !byte COL_DGREY,  COL_DGREY,  COL_BLACK,  COL_BLACK,  COL_BLACK
        !byte COL_BLACK,  COL_BLACK,  COL_BLACK,  COL_BLACK,  COL_BLACK, COL_BLACK"""

assert old_palettes in code, "old_palettes introuvable"
code = code.replace(old_palettes, new_palettes)

# 4. Machine a etats dans intro_update : de .update_fade_story a .update_fade_water
state_start = code.find('.update_fade_story:\n')
state_end = code.find('.update_fade_water:\n')
assert state_start != -1 and state_end != -1, "Bornes machine a etats introuvables"

new_state_machine = """.update_fade_story:
        inc intro_fade_tick
        lda intro_fade_tick
        cmp #4
        bcc +
        lda #0
        sta intro_fade_tick
        jsr intro_fade_step
        inc intro_fade_step_idx
        lda intro_fade_step_idx
        cmp #4
        bcc +
        lda #INTRO_PHASE_STORY
        sta intro_phase
        lda #0
        sta intro_scroll_line
        sta intro_scroll_tick
        sta intro_sub_timer
        sta intro_sub_timer+1
        jsr intro_clear_scroll_area
+       rts

; --- 3. STORY SCROLL UNIFIE 1:1 NES ---
.update_story:
        lda intro_scroll_line
        cmp #22                         ; Pause Link quand le cadre est au centre
        bne .st_chk_end

        ; Link brandit la Triforce d'Or au centre
        lda intro_sub_timer
        ora intro_sub_timer+1
        bne +
        jsr intro_setup_link_triforce
+       inc intro_sub_timer
        bne +
        inc intro_sub_timer+1
+       lda intro_sub_timer+1
        bne .st_link_done
        lda intro_sub_timer
        cmp #140                        ; Pause de 2.8s
        bcc .story_ret

.st_link_done:
        lda #0
        sta VIC_SPRITE_EN               ; Eteint Link et Triforce
        inc intro_scroll_line           ; Reprend le defilement
        lda #0
        sta intro_sub_timer
        sta intro_sub_timer+1
        rts

.st_chk_end:
        lda intro_scroll_line
        cmp #story_total_steps
        bcs .story_all_done

        ; Defilement montant regulier (1 ligne toutes les 8 frames)
        inc intro_scroll_tick
        lda intro_scroll_tick
        cmp #8
        bcc .story_ret
        lda #0
        sta intro_scroll_tick

        jsr intro_scroll_up_one_line
        jsr intro_inject_story_line
        inc intro_scroll_line
.story_ret:
        rts

.story_all_done:
        lda #INTRO_PHASE_TREASURES
        sta intro_phase
        lda #0
        sta intro_scroll_line
        sta intro_scroll_tick
        sta intro_sub_timer
        sta intro_sub_timer+1
        rts

.update_fade_treas:
        lda #INTRO_PHASE_TREASURES
        sta intro_phase
        lda #0
        sta intro_scroll_line
        sta intro_scroll_tick
        sta intro_sub_timer
        sta intro_sub_timer+1
        rts

; --- 4. ALL OF TREASURES SHOWCASE SCROLL ---
.update_treasures:
        lda intro_scroll_line
        cmp #29                         ; Pause Link tenant la pancarte au centre
        bne .tr_chk_end

        lda intro_sub_timer
        ora intro_sub_timer+1
        bne +
        jsr intro_setup_link_sign
+       inc intro_sub_timer
        bne +
        inc intro_sub_timer+1
+       lda intro_sub_timer+1
        bne .tr_sign_done
        lda intro_sub_timer
        cmp #140                        ; Pause de 2.8s
        bcc .tr_ret

.tr_sign_done:
        lda #0
        sta VIC_SPRITE_EN
        inc intro_scroll_line
        lda #0
        sta intro_sub_timer
        sta intro_sub_timer+1
        rts

.tr_chk_end:
        lda intro_scroll_line
        cmp #treasure_total_steps
        bcs .treasures_all_done

        inc intro_scroll_tick
        lda intro_scroll_tick
        cmp #8
        bcc .tr_ret
        lda #0
        sta intro_scroll_tick

        jsr intro_scroll_up_one_line
        jsr intro_inject_treasure_step
        inc intro_scroll_line
.tr_ret:
        rts

.treasures_all_done:
        lda #INTRO_PHASE_MONSTERS
        sta intro_phase
        lda #0
        sta intro_scroll_line
        sta intro_scroll_tick
        sta intro_sub_timer
        sta intro_sub_timer+1
        rts

.update_fade_monsters:
        lda #INTRO_PHASE_MONSTERS
        sta intro_phase
        lda #0
        sta intro_scroll_line
        sta intro_scroll_tick
        sta intro_sub_timer
        sta intro_sub_timer+1
        rts

; --- 5. ALL OF MONSTERS SHOWCASE SCROLL ---
.update_monsters:
        ; Animation du monstre courant (ailes/pas)
        inc intro_mon_anim_tick
        lda intro_mon_anim_tick
        cmp #10
        bcc +
        lda #0
        sta intro_mon_anim_tick
        lda intro_mon_frame
        eor #1
        sta intro_mon_frame
        jsr intro_copy_monster_sprite_frame
+
        lda intro_scroll_line
        cmp #monster_total_steps
        bcs .monsters_done

        inc intro_scroll_tick
        lda intro_scroll_tick
        cmp #10
        bcc .mon_ret
        lda #0
        sta intro_scroll_tick

        jsr intro_scroll_up_one_line
        jsr intro_inject_monster_step
        inc intro_scroll_line
.mon_ret:
        rts

.monsters_done:
        lda #0
        sta VIC_SPRITE_EN
        lda #INTRO_PHASE_FADE_WATER
        sta intro_phase
        lda #0
        sta intro_fade_step_idx
        sta intro_fade_tick
        rts

"""

code = code[:state_start] + new_state_machine + code[state_end:]

# 5. Remplacement des routines de parchemin (de intro_draw_parchment_frame: jusqu'à avant ; MOTEUR SONORE)
pos_parch = code.find('intro_draw_parchment_frame:\n')
pos_sound = code.find('; MOTEUR SONORE ET MUSIQUE AUTHENTIQUE')
assert pos_parch != -1 and pos_sound != -1, "Bornes parchemin introuvables"

new_routines = """; ===========================================================================
; MOTEUR DE DEFILEMENT VERTICAL CONTINU (SCROLLING 1:1 NES)
; ===========================================================================

; Decale tout l'ecran de 1 ligne vers le haut (lignes 1..24 vers 0..23)
; et nettoie la ligne 24 (SCREEN_RAM+960..999) a l'espace noir (32, COL_BLACK)
intro_scroll_up_one_line:
        ldx #0
.scu1:  lda SCREEN_RAM+40,x
        sta SCREEN_RAM,x
        lda COLOR_RAM+40,x
        sta COLOR_RAM,x

        lda SCREEN_RAM+40+$100,x
        sta SCREEN_RAM+$100,x
        lda COLOR_RAM+40+$100,x
        sta COLOR_RAM+$100,x

        lda SCREEN_RAM+40+$200,x
        sta SCREEN_RAM+$200,x
        lda COLOR_RAM+40+$200,x
        sta COLOR_RAM+$200,x
        inx
        bne .scu1

        ; Copie les 192 derniers octets (960 - 768 = 192)
        ldx #0
.scu2:  lda SCREEN_RAM+40+$300,x
        sta SCREEN_RAM+$300,x
        lda COLOR_RAM+40+$300,x
        sta COLOR_RAM+$300,x
        inx
        cpx #192
        bne .scu2

        ; Efface la ligne 24
        lda #32
        ldx #0
.sc_clr24:
        sta SCREEN_RAM+960,x
        lda #COL_BLACK
        sta COLOR_RAM+960,x
        lda #32
        inx
        cpx #40
        bne .sc_clr24
        rts

; Injecte une ligne de 40 colonnes pointee par ZP_SRC sur la ligne 24
; avec coloration automatique :
; - Cadre (>= 249) : COL_LBLUE
; - Espace (== 32) : COL_BLACK
; - Etoile (== CHAR_STAR_DOT) : COL_YELLOW
; - Texte courant : intro_text_color (COL_WHITE)
intro_inject_text_line_24:
        ldy #0
.inj_l: lda (ZP_SRC),y
        beq .inj_pad
        sta SCREEN_RAM+960,y
        cmp #CHAR_FRAME_TL
        bcs .is_frm
        cmp #CHAR_STAR_DOT
        beq .is_star
        cmp #32
        beq .is_spc
        lda intro_text_color
        bne .set_col
.is_star:
        lda #COL_YELLOW
        bne .set_col
.is_frm:
        lda #COL_LBLUE
        bne .set_col
.is_spc:
        lda #COL_BLACK
.set_col:
        sta COLOR_RAM+960,y
        iny
        cpy #40
        bne .inj_l
        rts
.inj_pad:
        lda #32
-       sta SCREEN_RAM+960,y
        lda #COL_BLACK
        sta COLOR_RAM+960,y
        lda #32
        iny
        cpy #40
        bne -
        rts

; Injecte la ligne d'histoire correspondant a intro_scroll_line
intro_inject_story_line:
        lda intro_scroll_line
        cmp #story_total_steps
        bcs .st_inj_done
        asl
        tax
        lda story_ptrs,x
        sta ZP_SRC
        lda story_ptrs+1,x
        sta ZP_SRC+1
        jsr intro_inject_text_line_24
.st_inj_done:
        rts

; Configure Link (Sprite 0) brandissant la Triforce d'Or (Sprite 1) au centre
intro_setup_link_triforce:
        lda #SPR_BLOCK_LINK
        sta SPRITE_PTR0
        lda #160                        ; Centre horizontal X=160
        sta VIC_SPRITE_X0
        lda #145                        ; Centre vertical Y=145
        sta VIC_SPRITE_Y0

        lda #SPR_BLOCK_TRIFORCE
        sta SPRITE_PTR1
        lda #160                        ; Au-dessus de Link X=160
        sta VIC_SPRITE_X1
        lda #114                        ; Y=114
        sta VIC_SPRITE_Y1

        lda VIC_SPRITE_MSB
        and #%11111100
        sta VIC_SPRITE_MSB

        ; Link (Sprite 0) : 2x multi-couleur
        lda VIC_SPRITE_EXP_X
        ora #%00000001
        and #%11111101                  ; Triforce non etendue en X
        sta VIC_SPRITE_EXP_X

        lda VIC_SPRITE_EXP_Y
        ora #%00000001
        and #%11111101
        sta VIC_SPRITE_EXP_Y

        lda VIC_SPRITE_MC
        ora #%00000001                  ; Sprite 0 multicolore
        and #%11111101                  ; Sprite 1 haute resolution
        sta VIC_SPRITE_MC

        lda #COL_GREEN
        sta VIC_SPRITE_MC1
        lda #COL_BROWN
        sta VIC_SPRITE_MC2
        lda #COL_YELLOW
        sta VIC_SPRITE_COL0
        lda #COL_YELLOW
        sta VIC_SPRITE_COL1

        lda VIC_SPRITE_EN
        ora #%00000011                  ; Active Sprites 0 et 1
        sta VIC_SPRITE_EN
        rts

; Injecte un pas du defile des 35 tresors
intro_inject_treasure_step:
        lda intro_scroll_line
        cmp #2
        bne +
        jmp .inj_tr_head
+       cmp #23
        bne +
        jmp .inj_tr_foot
+       cmp #26
        bne +
        jmp .inj_tr_sign0
+       cmp #27
        bne +
        jmp .inj_tr_sign1
+       cmp #28
        bne +
        jmp .inj_tr_sign2
+       cmp #29
        bne +
        jmp .inj_tr_sign3
+
        ; Rangees de tresors (4..21 -> index 0..17)
        cmp #4
        bcc .inj_tr_done
        cmp #22
        bcs .inj_tr_done

        sec
        sbc #4
        tax

        ; Colonne Gauche : Icone col 6, Nom col 8
        lda tr_l_icons,x
        sta SCREEN_RAM+960+6
        lda tr_l_colors,x
        sta COLOR_RAM+960+6

        txa
        asl
        tay
        lda tr_l_ptrs,y
        sta ZP_SRC
        lda tr_l_ptrs+1,y
        sta ZP_SRC+1
        ldy #0
-       lda (ZP_SRC),y
        beq +
        sta SCREEN_RAM+960+8,y
        lda #COL_WHITE
        sta COLOR_RAM+960+8,y
        iny
        cpy #13
        bne -
+
        ; Colonne Droite : Icone col 22, Nom col 24
        ldx intro_scroll_line
        sec
        sbc #4
        tax
        lda tr_r_icons,x
        beq .inj_tr_done
        sta SCREEN_RAM+960+22
        lda tr_r_colors,x
        sta COLOR_RAM+960+22

        txa
        asl
        tay
        lda tr_r_ptrs,y
        sta ZP_SRC
        lda tr_r_ptrs+1,y
        sta ZP_SRC+1
        ldy #0
-       lda (ZP_SRC),y
        beq +
        sta SCREEN_RAM+960+24,y
        lda #COL_WHITE
        sta COLOR_RAM+960+24,y
        iny
        cpy #13
        bne -
+
.inj_tr_done:
        rts

.inj_tr_head:
        lda #<txt_treasures_header
        sta ZP_SRC
        lda #>txt_treasures_header
        sta ZP_SRC+1
        jmp intro_inject_text_line_24

.inj_tr_foot:
        lda #<txt_treasures_footer
        sta ZP_SRC
        lda #>txt_treasures_footer
        sta ZP_SRC+1
        jmp intro_inject_text_line_24

.inj_tr_sign0:
        lda #<txt_sign_0
        sta ZP_SRC
        lda #>txt_sign_0
        sta ZP_SRC+1
        jmp intro_inject_text_line_24

.inj_tr_sign1:
        lda #<txt_sign_1
        sta ZP_SRC
        lda #>txt_sign_1
        sta ZP_SRC+1
        jmp intro_inject_text_line_24

.inj_tr_sign2:
        lda #<txt_sign_2
        sta ZP_SRC
        lda #>txt_sign_2
        sta ZP_SRC+1
        jmp intro_inject_text_line_24

.inj_tr_sign3:
        lda #<txt_sign_3
        sta ZP_SRC
        lda #>txt_sign_3
        sta ZP_SRC+1
        jmp intro_inject_text_line_24

; Configure Link tenant la pancarte du manuel
intro_setup_link_sign:
        lda #SPR_BLOCK_LINK
        sta SPRITE_PTR0
        lda #160
        sta VIC_SPRITE_X0
        lda #165                        ; Positionne sous la pancarte
        sta VIC_SPRITE_Y0
        lda VIC_SPRITE_MSB
        and #%11111110
        sta VIC_SPRITE_MSB
        lda VIC_SPRITE_EXP_X
        ora #%00000001
        sta VIC_SPRITE_EXP_X
        lda VIC_SPRITE_EXP_Y
        ora #%00000001
        sta VIC_SPRITE_EXP_Y
        lda VIC_SPRITE_MC
        ora #%00000001
        sta VIC_SPRITE_MC
        lda #COL_GREEN
        sta VIC_SPRITE_MC1
        lda #COL_BROWN
        sta VIC_SPRITE_MC2
        lda #COL_YELLOW
        sta VIC_SPRITE_COL0
        lda #%00000001
        sta VIC_SPRITE_EN
        rts

; Injecte un pas du defile des 15 monstres
intro_inject_monster_step:
        lda intro_scroll_line
        cmp #2
        bne +
        jmp .inj_mon_head
+       cmp #34
        bne +
        jmp .inj_mon_foot
+
        ; Rangees monstres (4..33 -> 15 monstres, 2 pas par monstre)
        cmp #4
        bcc .inj_mon_skip
        cmp #34
        bcs .inj_mon_skip

        ; Test pas pair
        lsr
        bcs .inj_mon_skip               ; Pas impair : ligne vide

        sec
        sbc #2                          ; A = index 0..14
        sta intro_mon_idx
        tax

        ; Affiche le nom du monstre a col 16
        txa
        asl
        tay
        lda intro_mon_name_ptrs,y
        sta ZP_SRC
        lda intro_mon_name_ptrs+1,y
        sta ZP_SRC+1
        ldy #0
-       lda (ZP_SRC),y
        beq +
        sta SCREEN_RAM+960+16,y
        lda #COL_WHITE
        sta COLOR_RAM+960+16,y
        iny
        cpy #16
        bne -
+
        ; Configure le sprite du monstre au centre gauche
        ldx intro_mon_idx
        lda intro_mon_colors,x
        sta VIC_SPRITE_COL0

        lda #0
        sta intro_mon_frame
        jsr intro_copy_monster_sprite_frame

        lda #108                        ; Col 13 (X=108)
        sta VIC_SPRITE_X0
        lda #136                        ; Y=136 au centre de l'ecran
        sta VIC_SPRITE_Y0
        lda VIC_SPRITE_MSB
        and #%11111110
        sta VIC_SPRITE_MSB
        lda VIC_SPRITE_EXP_X
        ora #%00000001
        sta VIC_SPRITE_EXP_X
        lda VIC_SPRITE_EXP_Y
        ora #%00000001
        sta VIC_SPRITE_EXP_Y
        lda VIC_SPRITE_MC
        ora #%00000001
        sta VIC_SPRITE_MC
        lda #COL_LRED
        sta VIC_SPRITE_MC1
        lda #COL_BROWN
        sta VIC_SPRITE_MC2
        lda #SPR_BLOCK_MON
        sta SPRITE_PTR0
        lda VIC_SPRITE_EN
        ora #%00000001
        sta VIC_SPRITE_EN
.inj_mon_skip:
        rts

.inj_mon_head:
        lda #<txt_monsters_header
        sta ZP_SRC
        lda #>txt_monsters_header
        sta ZP_SRC+1
        jmp intro_inject_text_line_24

.inj_mon_foot:
        lda #<txt_treasures_footer
        sta ZP_SRC
        lda #>txt_treasures_footer
        sta ZP_SRC+1
        jmp intro_inject_text_line_24

intro_copy_monster_sprite_frame:
        ldx intro_mon_idx
        txa
        asl
        tax
        lda intro_mon_frame
        bne .mon_f1
        lda intro_mon_f0_ptrs,x
        sta ZP_SRC
        lda intro_mon_f0_ptrs+1,x
        sta ZP_SRC+1
        jmp .do_cpy
.mon_f1:
        lda intro_mon_f1_ptrs,x
        sta ZP_SRC
        lda intro_mon_f1_ptrs+1,x
        sta ZP_SRC+1
.do_cpy:
        ldy #63
-       lda (ZP_SRC),y
        sta intro_spr_buffer,y
        dey
        bpl -
        rts

"""

# Retenir les 2 lignes de commentaire avant MOTEUR SONORE
code = code[:pos_parch] + new_routines + code[pos_sound:]

# 6. Remplacement des tables de textes en fin de fichier
pos_text_start = code.find('; TEXTES OFFICIELS DE L\'HISTOIRE')
assert pos_text_start != -1, "TEXTES OFFICIELS DE L'HISTOIRE introuvable"

new_text_tables = """; TEXTES OFFICIELS DE L'HISTOIRE (NES 1986)
; ===========================================================================
txt_press_button:   !text "PUSH START BUTTON", 0
txt_nintendo:       !byte CHAR_COPYRIGHT : !text " 1986 NINTENDO", 0

s_line_blank: !fill 40, 32 : !byte 0

s_line_00: !text "      ", CHAR_FRAME_TL, CHAR_FRAME_H, CHAR_FRAME_H, CHAR_FRAME_X, " THE LEGEND OF ZELDA ", CHAR_FRAME_X, CHAR_FRAME_H, CHAR_FRAME_TR, "      ", 0
s_line_01: !text "      ", CHAR_FRAME_V, "                          ", CHAR_FRAME_V, "      ", 0
s_line_02: !text "      ", CHAR_FRAME_V, "  MANY YEARS AGO PRINCE   ", CHAR_FRAME_V, "      ", 0
s_line_03: !text "      ", CHAR_FRAME_V, "  DARKNESS GANNON STOLE   ", CHAR_FRAME_V, "      ", 0
s_line_04: !text "      ", CHAR_FRAME_V, "  ONE OF THE TRIFORCE WITH", CHAR_FRAME_V, "      ", 0
s_line_05: !text "      ", CHAR_FRAME_V, "  POWER. PRINCESS ZELDA   ", CHAR_FRAME_V, "      ", 0
s_line_06: !text "      ", CHAR_FRAME_V, "  HAD ONE OF THE TRIFORCE ", CHAR_FRAME_V, "      ", 0
s_line_07: !text "      ", CHAR_FRAME_V, "  WITH WISDOM. SHE DIVIDED", CHAR_FRAME_V, "      ", 0
s_line_08: !text "      ", CHAR_FRAME_V, "  IT INTO 8 UNITS TO HIDE ", CHAR_FRAME_V, "      ", 0
s_line_09: !text "      ", CHAR_FRAME_V, "  IT FROM GANNON BEFORE   ", CHAR_FRAME_V, "      ", 0
s_line_10: !text "      ", CHAR_FRAME_V, "  SHE WAS CAPTURED.       ", CHAR_FRAME_V, "      ", 0
s_line_11: !text "      ", CHAR_FRAME_V, "                          ", CHAR_FRAME_V, "      ", 0
s_line_12: !text "      ", CHAR_FRAME_V, "    GO FIND THE 8 UNITS   ", CHAR_FRAME_V, "      ", 0
s_line_13: !text "      ", CHAR_FRAME_V, "    LINK TO SAVE HER.     ", CHAR_FRAME_V, "      ", 0
s_line_14: !text "      ", CHAR_FRAME_V, "                          ", CHAR_FRAME_V, "      ", 0
s_line_15: !text "      ", CHAR_FRAME_V, "                          ", CHAR_FRAME_V, "      ", 0
s_line_16: !text "      ", CHAR_FRAME_V, "                          ", CHAR_FRAME_V, "      ", 0
s_line_17: !text "      ", CHAR_FRAME_V, "                          ", CHAR_FRAME_V, "      ", 0
s_line_18: !text "      ", CHAR_FRAME_V, "                          ", CHAR_FRAME_V, "      ", 0
s_line_19: !text "      ", CHAR_FRAME_BL
           !fill 26, CHAR_FRAME_H
           !byte CHAR_FRAME_BR
           !text "      ", 0

story_line_count = 20
story_total_steps = 38

story_ptrs:
        !word s_line_blank, s_line_blank
        !word s_line_00, s_line_01, s_line_02, s_line_03, s_line_04, s_line_05
        !word s_line_06, s_line_07, s_line_08, s_line_09, s_line_10, s_line_11
        !word s_line_12, s_line_13, s_line_14, s_line_15, s_line_16, s_line_17
        !word s_line_18, s_line_19
        !word s_line_blank, s_line_blank, s_line_blank, s_line_blank
        !word s_line_blank, s_line_blank, s_line_blank, s_line_blank
        !word s_line_blank, s_line_blank, s_line_blank, s_line_blank
        !word s_line_blank, s_line_blank, s_line_blank, s_line_blank

; ===========================================================================
; DEFILE OFFICIEL DES TRESORS DE ZELDA 1 (2 COLONNES)
; ===========================================================================
txt_treasures_header: !text "      ", CHAR_STAR_DOT, CHAR_STAR_DOT, " ALL OF TREASURES ", CHAR_STAR_DOT, CHAR_STAR_DOT, "      ", 0
txt_treasures_footer: !text "                ", CHAR_STAR_DOT, CHAR_STAR_DOT, "                ", 0

txt_sign_0: !text "      ", CHAR_FRAME_TL : !fill 26, CHAR_FRAME_H : !byte CHAR_FRAME_TR : !text "      ", 0
txt_sign_1: !text "      ", CHAR_FRAME_V, "    PLEASE LOOK UP THE    ", CHAR_FRAME_V, "      ", 0
txt_sign_2: !text "      ", CHAR_FRAME_V, "    MANUAL FOR DETAILS.   ", CHAR_FRAME_V, "      ", 0
txt_sign_3: !text "      ", CHAR_FRAME_BL : !fill 26, CHAR_FRAME_H : !byte CHAR_FRAME_BR : !text "      ", 0

treasure_total_steps = 36

tr_l_name_00: !text "HEART CONT.", 0
tr_r_name_00: !text "HEART", 0
tr_l_name_01: !text "FAIRY", 0
tr_r_name_01: !text "CLOCK", 0
tr_l_name_02: !text "RUPY", 0
tr_r_name_02: !text "5 RUPIES", 0
tr_l_name_03: !text "LIFE POTION", 0
tr_r_name_03: !text "2ND POTION", 0
tr_l_name_04: !text "LETTER", 0
tr_r_name_04: !text "FOOD", 0
tr_l_name_05: !text "SWORD", 0
tr_r_name_05: !text "WHITE SWORD", 0
tr_l_name_06: !text "MAGICAL SWORD", 0
tr_r_name_06: !text "MAG. SHIELD", 0
tr_l_name_07: !text "BOOMERANG", 0
tr_r_name_07: !text "MAG. BOOMER.", 0
tr_l_name_08: !text "BOMB", 0
tr_r_name_08: !text "BOW", 0
tr_l_name_09: !text "ARROW", 0
tr_r_name_09: !text "SILVER ARROW", 0
tr_l_name_10: !text "BLUE CANDLE", 0
tr_r_name_10: !text "RED CANDLE", 0
tr_l_name_11: !text "BLUE RING", 0
tr_r_name_11: !text "RED RING", 0
tr_l_name_12: !text "POWER BRAC.", 0
tr_r_name_12: !text "RECORDER", 0
tr_l_name_13: !text "RAFT", 0
tr_r_name_13: !text "STEPLADDER", 0
tr_l_name_14: !text "MAGICAL ROD", 0
tr_r_name_14: !text "BOOK OF MAGIC", 0
tr_l_name_15: !text "KEY", 0
tr_r_name_15: !text "MAGICAL KEY", 0
tr_l_name_16: !text "MAP", 0
tr_r_name_16: !text "COMPASS", 0
tr_l_name_17: !text "TRIFORCE", 0
tr_r_name_17: !text "OF WISDOM", 0

tr_l_icons:
        !byte CHAR_HEART_CONT, CHAR_FAIRY, CHAR_RUPEE, CHAR_POTION, CHAR_LETTER, CHAR_SWORD, CHAR_SWORD, CHAR_BOOMERANG, CHAR_BOMB, CHAR_ARROW, CHAR_CANDLE, CHAR_RING, CHAR_BRACELET, CHAR_RAFT, CHAR_ROD, CHAR_KEY, CHAR_MAP, CHAR_TRIFORCE
tr_l_colors:
        !byte COL_RED, COL_WHITE, COL_YELLOW, COL_CYAN, COL_WHITE, COL_BROWN, COL_CYAN, COL_YELLOW, COL_CYAN, COL_BROWN, COL_CYAN, COL_CYAN, COL_ORANGE, COL_BROWN, COL_CYAN, COL_GREY, COL_YELLOW, COL_YELLOW
tr_l_ptrs:
        !word tr_l_name_00, tr_l_name_01, tr_l_name_02, tr_l_name_03, tr_l_name_04, tr_l_name_05
        !word tr_l_name_06, tr_l_name_07, tr_l_name_08, tr_l_name_09, tr_l_name_10, tr_l_name_11
        !word tr_l_name_12, tr_l_name_13, tr_l_name_14, tr_l_name_15, tr_l_name_16, tr_l_name_17

tr_r_icons:
        !byte CHAR_HEART, CHAR_CLOCK, CHAR_RUPEE, CHAR_POTION, CHAR_FOOD, CHAR_SWORD, CHAR_SHIELD, CHAR_BOOMERANG, CHAR_BOW, CHAR_ARROW, CHAR_CANDLE, CHAR_RING, CHAR_FLUTE, CHAR_LADDER, CHAR_BOOK, CHAR_KEY, CHAR_COMPASS, CHAR_TRIFORCE
tr_r_colors:
        !byte COL_RED, COL_YELLOW, COL_CYAN, COL_RED, COL_BROWN, COL_WHITE, COL_RED, COL_CYAN, COL_BROWN, COL_CYAN, COL_RED, COL_RED, COL_CYAN, COL_GREY, COL_ORANGE, COL_YELLOW, COL_CYAN, COL_YELLOW
tr_r_ptrs:
        !word tr_r_name_00, tr_r_name_01, tr_r_name_02, tr_r_name_03, tr_r_name_04, tr_r_name_05
        !word tr_r_name_06, tr_r_name_07, tr_r_name_08, tr_r_name_09, tr_r_name_10, tr_r_name_11
        !word tr_r_name_12, tr_r_name_13, tr_r_name_14, tr_r_name_15, tr_r_name_16, tr_r_name_17

; ===========================================================================
; DEFILE DES 15 MONSTRES D'HYRULE
; ===========================================================================
txt_monsters_header: !text "       ", CHAR_STAR_DOT, CHAR_STAR_DOT, " ALL OF MONSTERS ", CHAR_STAR_DOT, CHAR_STAR_DOT, "      ", 0

monster_total_steps = 56
"""

code = code[:pos_text_start] + new_text_tables

with open('src/intro.asm', 'w') as f:
    f.write(code)

print("patch_intro_exact.py terminé avec succès !")
