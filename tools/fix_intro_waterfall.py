#!/usr/bin/env python3
"""
tools/fix_intro_waterfall.py :
Injecte le code 100% fidèle NES pour l'écran titre et la cascade,
sans aucune expansion de variable bash ($100, $200, $300, etc.).
"""

with open("src/intro.asm", "r") as f:
    text = f.read()

start_marker = "intro_draw_waterfall:\n"
end_marker = "intro_show_press_text:\n"

p1 = text.find(start_marker)
p2 = text.find(end_marker)
assert p1 != -1 and p2 != -1, f"Markers not found: {p1}, {p2}"

new_code = """intro_draw_waterfall:
        lda #COL_BLACK
        sta VIC_BACKGROUND
        sta VIC_BORDER

        ; 1. Remplissage initial :
        ;    - Ciel rose/peche NES (CHAR_SOLID 154, COL_LRED) sur lignes 0..17 (720 octets)
        ;    - Noir (32, COL_BLACK) sur lignes 18..24 (280 octets)
        ldx #0
.clrwf1:
        lda #154                        ; CHAR_SOLID (bloc plein pour ciel rose)
        sta SCREEN_RAM,x
        sta SCREEN_RAM+$100,x
        lda #COL_LRED                   ; Ciel rose au lever du jour
        sta COLOR_RAM,x
        sta COLOR_RAM+$100,x
        inx
        bne .clrwf1

        ldx #0
.clrwf2:
        lda #154
        sta SCREEN_RAM+$200,x
        lda #COL_LRED
        sta COLOR_RAM+$200,x
        inx
        cpx #208                        ; 512 + 208 = 720 octets (lignes 0..17)
        bne .clrwf2

        ; Reste de l'ecran (lignes 18..24, 280 octets) : noir / espace
-       lda #32
        sta SCREEN_RAM+$200,x
        lda #COL_BLACK
        sta COLOR_RAM+$200,x
        inx
        bne -

        ldx #0
-       lda #32
        sta SCREEN_RAM+$300,x
        lda #COL_BLACK
        sta COLOR_RAM+$300,x
        inx
        cpx #232                        ; 768 + 232 = 1000 octets
        bne -

        ; 2. Falaise discrete haute (Ligne 1, coin superieur droit)
        lda #CHAR_CLIFF_EDG_R
        sta SCREEN_RAM+40+38
        lda #COL_GREY
        sta COLOR_RAM+40+38
        lda #CHAR_CLIFF_FACE
        sta SCREEN_RAM+40+39
        lda #COL_DGREY
        sta COLOR_RAM+40+39

        ; 3. Piliers rocheux lateraux du haut (Lignes 2..13, cols 0..1 et 38..39)
        ldx #2
.wf_upper_pillars:
        lda intro_scr_lo,x
        sta ZP_SCR
        lda intro_scr_hi,x
        sta ZP_SCR+1
        lda intro_col_hi,x
        sta ZP_COL+1
        lda ZP_SCR
        sta ZP_COL

        ; Pilier gauche (col 0..1)
        ldy #0
        lda #CHAR_CLIFF_FACE
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y
        iny
        lda #CHAR_CLIFF_EDG_L
        sta (ZP_SCR),y
        lda #COL_GREY
        sta (ZP_COL),y

        ; Pilier droit (col 38..39)
        ldy #38
        lda #CHAR_CLIFF_EDG_R
        sta (ZP_SCR),y
        lda #COL_GREY
        sta (ZP_COL),y
        iny
        lda #CHAR_CLIFF_FACE
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y

        inx
        cpx #14
        bne .wf_upper_pillars

        ; 4. Grand Blason ZELDA NES (Lignes 2..13, Cols 9..30)
        lda #<shield_chars_data
        sta ZP_SRC
        lda #>shield_chars_data
        sta ZP_SRC+1

        lda #<shield_colors_data
        sta ZP_DST
        lda #>shield_colors_data
        sta ZP_DST+1

        ldx #0                          ; ligne 0..11 du blason
.sh_row_loop:
        stx ZP_ROW
        txa
        clc
        adc #2                          ; ligne ecran C64 (2..13)
        tay
        lda intro_scr_lo,y
        sta ZP_SCR
        lda intro_scr_hi,y
        sta ZP_SCR+1
        lda intro_col_hi,y
        sta ZP_COL+1
        lda ZP_SCR
        sta ZP_COL

        ldy #0                          ; col 0..21 du blason
.sh_col_loop:
        lda (ZP_SRC),y
        tax
        tya
        clc
        adc #9                          ; col ecran C64 (9..30)
        tay
        txa
        sta (ZP_SCR),y
        tya
        sec
        sbc #9
        tay
        lda (ZP_DST),y
        tax
        tya
        clc
        adc #9
        tay
        txa
        sta (ZP_COL),y
        tya
        sec
        sbc #9
        tay

        iny
        cpy #22
        bne .sh_col_loop

        ; Avance pointeurs de 22 octets
        lda ZP_SRC
        clc
        adc #22
        sta ZP_SRC
        bcc +
        inc ZP_SRC+1
+       lda ZP_DST
        clc
        adc #22
        sta ZP_DST
        bcc +
        inc ZP_DST+1
+
        ldx ZP_ROW
        inx
        cpx #12
        beq +
        jmp .sh_row_loop
+

        ; 5. Chute d'eau sous le blason & falaises moyennes (Lignes 14..17)
        ldx #14
.wf_mid_loop:
        lda intro_scr_lo,x
        sta ZP_SCR
        lda intro_scr_hi,x
        sta ZP_SCR+1
        lda intro_col_hi,x
        sta ZP_COL+1
        lda ZP_SCR
        sta ZP_COL

        ; Falaise gauche (cols 0..2)
        ldy #0
        lda #CHAR_CLIFF_FACE
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y
        iny
        lda #CHAR_CLIFF_FACE
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y
        iny
        lda #CHAR_CLIFF_EDG_L
        sta (ZP_SCR),y
        lda #COL_GREY
        sta (ZP_COL),y

        ; Chute centrale (cols 16..23)
        ldy #16
-       lda #CHAR_WATER_0
        cpx #14
        bne +
        lda #CHAR_WATER_CREST
+       sta (ZP_SCR),y
        lda #COL_CYAN
        cpx #14
        bne +
        lda #COL_WHITE
+       sta (ZP_COL),y
        iny
        cpy #24
        bne -

        ; Falaise droite (cols 37..39)
        ldy #37
        lda #CHAR_CLIFF_EDG_R
        sta (ZP_SCR),y
        lda #COL_GREY
        sta (ZP_COL),y
        iny
        lda #CHAR_CLIFF_FACE
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y
        iny
        lda #CHAR_CLIFF_FACE
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y

        inx
        cpx #18
        bne .wf_mid_loop

        ; 6. Plateau rocheux inferieur (Lignes 18..20)
        ; Ligne 18 :
        lda intro_scr_lo+18
        sta ZP_SCR
        lda intro_scr_hi+18
        sta ZP_SCR+1
        lda intro_col_hi+18
        sta ZP_COL+1
        lda ZP_SCR
        sta ZP_COL

        ldy #0
-       lda #CHAR_CLIFF_FACE
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y
        iny
        cpy #5
        bne -
        lda #CHAR_CLIFF_EDG_L
        sta (ZP_SCR),y
        lda #COL_GREY
        sta (ZP_COL),y

        ldy #16
-       lda #CHAR_WATER_0
        sta (ZP_SCR),y
        lda #COL_CYAN
        sta (ZP_COL),y
        iny
        cpy #24
        bne -

        ldy #34
        lda #CHAR_CLIFF_EDG_R
        sta (ZP_SCR),y
        lda #COL_GREY
        sta (ZP_COL),y
        iny
-       lda #CHAR_CLIFF_FACE
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y
        iny
        cpy #40
        bne -

        ; Ligne 19 : avec pins verts
        lda intro_scr_lo+19
        sta ZP_SCR
        lda intro_scr_hi+19
        sta ZP_SCR+1
        lda intro_col_hi+19
        sta ZP_COL+1
        lda ZP_SCR
        sta ZP_COL

        ldy #0
-       lda #CHAR_CLIFF_FACE
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y
        iny
        cpy #11
        bne -
-       lda #CHAR_TREE_TOP
        sta (ZP_SCR),y
        lda #COL_GREEN
        sta (ZP_COL),y
        iny
        cpy #16
        bne -

        ; Cascade
-       lda #CHAR_WATER_0
        sta (ZP_SCR),y
        lda #COL_CYAN
        sta (ZP_COL),y
        iny
        cpy #24
        bne -

        ; Falaise droite
-       lda #CHAR_CLIFF_FACE
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y
        iny
        cpy #40
        bne -

        ; Ligne 20 :
        lda intro_scr_lo+20
        sta ZP_SCR
        lda intro_scr_hi+20
        sta ZP_SCR+1
        lda intro_col_hi+20
        sta ZP_COL+1
        lda ZP_SCR
        sta ZP_COL

        ldy #0
-       lda #CHAR_CLIFF_FACE
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y
        iny
        cpy #16
        bne -
-       lda #CHAR_WATER_0
        sta (ZP_SCR),y
        lda #COL_CYAN
        sta (ZP_COL),y
        iny
        cpy #24
        bne -
-       lda #CHAR_CLIFF_FACE
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y
        iny
        cpy #40
        bne -

        ; 7. Bassin d'eau & ecume (Ligne 21)
        ldy #0
-       lda #CHAR_CLIFF_FACE
        sta SCREEN_RAM+840,y
        lda #COL_DGREY
        sta COLOR_RAM+840,y
        iny
        cpy #4
        bne -
-       lda #CHAR_LAKE_WAVE
        sta SCREEN_RAM+840,y
        lda #COL_BLUE
        sta COLOR_RAM+840,y
        iny
        cpy #16
        bne -
-       lda #CHAR_WATER_FOAM
        sta SCREEN_RAM+840,y
        lda #COL_WHITE
        sta COLOR_RAM+840,y
        iny
        cpy #24
        bne -
-       lda #CHAR_LAKE_WAVE
        sta SCREEN_RAM+840,y
        lda #COL_BLUE
        sta COLOR_RAM+840,y
        iny
        cpy #36
        bne -
-       lda #CHAR_CLIFF_FACE
        sta SCREEN_RAM+840,y
        lda #COL_DGREY
        sta COLOR_RAM+840,y
        iny
        cpy #40
        bne -

        ; 8. Textes "PUSH START BUTTON" et copyright
        jsr intro_show_press_text

        ldx #0
.nint:
        lda txt_nintendo,x
        beq +
        sta SCREEN_RAM+960+12,x
        lda #COL_WHITE
        sta COLOR_RAM+960+12,x
        inx
        bne .nint
+

        ; 9. Sprites de vagues et etincelle
        lda #SPR_BLOCK_WAVE
        sta SPRITE_PTR1
        sta SPRITE_PTR2
        sta SPRITE_PTR3
        sta SPRITE_PTR4
        lda #COL_WHITE
        sta VIC_SPRITE_COL1
        sta VIC_SPRITE_COL2
        sta VIC_SPRITE_COL3
        sta VIC_SPRITE_COL4
        lda VIC_SPRITE_EXP_X
        and #%11100001
        sta VIC_SPRITE_EXP_X
        lda VIC_SPRITE_EXP_Y
        and #%11100001
        sta VIC_SPRITE_EXP_Y
        lda VIC_SPRITE_MC
        and #%11100001
        sta VIC_SPRITE_MC
        lda VIC_SPRITE_MSB
        and #%11100001
        sta VIC_SPRITE_MSB
        lda VIC_SPRITE_EN
        ora #%00011110                  ; Active Sprites 1..4
        sta VIC_SPRITE_EN

        jsr intro_animate_water
        rts

; Animation du flux d'eau central dans les cols 16..23
intro_animate_water:
        ; Animation etincelle scintillante sur le blason (Sprite 0)
        inc intro_blink_timer
        lda intro_blink_timer
        and #%00011111                  ; Periode de 32 frames
        cmp #12                         ; Activee pendant 12 frames
        bcs .glint_off

        ; Etoile visible
        lda intro_blink_timer
        lsr
        lsr
        lsr
        lsr
        lsr
        and #%00000011                  ; Index 0..3
        tax
        lda glint_x_tbl,x
        sta VIC_SPRITE_X0
        lda glint_y_tbl,x
        sta VIC_SPRITE_Y0
        lda #SPR_BLOCK_GLINT
        sta SPRITE_PTR0
        lda #COL_WHITE
        sta VIC_SPRITE_COL0
        lda VIC_SPRITE_EN
        ora #%00000001
        sta VIC_SPRITE_EN
        jmp .glint_done

.glint_off:
        lda VIC_SPRITE_EN
        and #%11111110
        sta VIC_SPRITE_EN
.glint_done:
        ldx intro_water_frame
        lda water_char_cycle,x
        sta ZP_TMP

        ldx #15
.wf_anim_line:
        lda intro_scr_lo,x
        sta ZP_SCR
        lda intro_scr_hi,x
        sta ZP_SCR+1

        ldy #16
.wf_anim_col:
        lda ZP_TMP
        sta (ZP_SCR),y
        iny
        cpy #24
        bne .wf_anim_col

        inx
        cpx #21
        bne .wf_anim_line
        rts

water_char_cycle: !byte CHAR_WATER_0, CHAR_WATER_1, CHAR_WATER_2
glint_x_tbl: !byte 120, 160, 200, 160
glint_y_tbl: !byte 72,  88,  72,  115

intro_apply_pal_colors:
        ldx intro_pal_step
        cpx #16
        bcc +
        rts
+       lda pal_bg_colors,x
        sta VIC_BACKGROUND

        ; Pointeur vers debut de SCREEN_RAM ($0400) et COLOR_RAM ($D800)
        lda #<SCREEN_RAM
        sta ZP_SCR
        lda #>SCREEN_RAM
        sta ZP_SCR+1
        lda #<COLOR_RAM
        sta ZP_COL
        lda #>COLOR_RAM
        sta ZP_COL+1

        lda intro_pal_step
        sta ZP_TMP                      ; etape de palette active

        lda #4
        sta ZP_ROW                      ; compteur de 4 pages

.pal_page_loop:
        ldy #0
.pal_tile_loop:
        lda (ZP_SCR),y
        cmp #154                        ; Ciel rose/peche NES
        bne +
        ldx ZP_TMP
        lda pal_bg_colors,x
        sta (ZP_COL),y
        jmp .pal_tile_next

+       cmp #CHAR_CLIFF_FACE
        beq .pal_tile_cliff
        cmp #CHAR_CLIFF_EDG_L
        beq .pal_tile_cliff
        cmp #CHAR_CLIFF_EDG_R
        bne +
.pal_tile_cliff:
        ldx ZP_TMP
        lda pal_cliff_colors,x
        sta (ZP_COL),y
        jmp .pal_tile_next

+       cmp #CHAR_TREE_TOP
        bne +
        ldx ZP_TMP
        lda pal_tree_colors,x
        sta (ZP_COL),y
        jmp .pal_tile_next

+       cmp #CHAR_WATER_0
        bcc .pal_tile_next
        cmp #CHAR_LAKE_WAVE+1
        bcs .pal_tile_next
        ldx ZP_TMP
        lda pal_water_colors,x
        sta (ZP_COL),y

.pal_tile_next:
        iny
        lda ZP_ROW
        cmp #1                          ; Derniere page ($0700) ?
        bne +
        cpy #232                        ; Limite exacte a 1000 octets d'ecran
        beq .pal_pages_done
+       cpy #0
        bne .pal_tile_loop

        inc ZP_SCR+1
        inc ZP_COL+1
        dec ZP_ROW
        bne .pal_page_loop

.pal_pages_done:
        ; Maj couleur vagues sprites
        ldx ZP_TMP
        lda pal_water_colors,x
        sta VIC_SPRITE_COL1
        sta VIC_SPRITE_COL2
        sta VIC_SPRITE_COL3
        sta VIC_SPRITE_COL4

        cpx #8
        bcc .pal_done
        lda #COL_WHITE
        ldy #0
-       lda txt_nintendo,y
        beq .pal_done
        sta COLOR_RAM+960+12,y
        iny
        bne -
.pal_done:
        rts

nes_pal_delays:
        !byte 8, 8, 6, 5, 4, 3, 2, 2, 2, 192, 6, 4, 192, 3, 4, 4
pal_bg_colors:
        !byte COL_LRED,   COL_LRED,   COL_LRED,   COL_PURPLE, COL_CYAN
        !byte COL_LBLUE,  COL_BLUE,   COL_BLUE,   COL_DGREY,  COL_BLACK
        !byte COL_BLACK,  COL_BLACK,  COL_BLACK,  COL_BLACK,  COL_BLACK, COL_BLACK
pal_cliff_colors:
        !byte COL_DGREY,  COL_DGREY,  COL_DGREY,  COL_DGREY,  COL_DGREY
        !byte COL_DGREY,  COL_DGREY,  COL_DGREY,  COL_DGREY,  COL_BLACK
        !byte COL_BLACK,  COL_BLACK,  COL_BLACK,  COL_BLACK,  COL_BLACK, COL_BLACK
pal_water_colors:
        !byte COL_CYAN,   COL_CYAN,   COL_CYAN,   COL_CYAN,   COL_CYAN
        !byte COL_LBLUE,  COL_BLUE,   COL_BLUE,   COL_BLUE,   COL_BLUE
        !byte COL_BLUE,   COL_BLACK,  COL_BLACK,  COL_BLACK,  COL_BLACK, COL_BLACK
pal_tree_colors:
        !byte COL_GREEN,  COL_GREEN,  COL_GREEN,  COL_GREEN,  COL_GREEN
        !byte COL_DGREY,  COL_DGREY,  COL_BLACK,  COL_BLACK,  COL_BLACK
        !byte COL_BLACK,  COL_BLACK,  COL_BLACK,  COL_BLACK,  COL_BLACK, COL_BLACK

"""

updated = text[:p1] + new_code + text[p2:]
with open("src/intro.asm", "w") as f:
    f.write(updated)

print("SUCCESS: Fixed intro.asm with exact assembly syntax!")
