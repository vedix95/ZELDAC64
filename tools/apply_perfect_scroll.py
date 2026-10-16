with open('src/intro.asm', 'r') as f:
    text = f.read()

# 1. Dans intro_draw_story_bg :
# Initialiser TOUTE la zone intérieure du parchemin (lignes 4..21, cols 4..35) avec la couleur COL_WHITE
# dans COLOR_RAM !
target_draw_story = """; --- 2. BORDS DÉROULÉS DU PARCHEMIN (Lignes 2..21) ---
        ldx #2
.roll_sides:
        lda intro_scr_lo,x
        sta ZP_SCR
        lda intro_scr_hi,x
        sta ZP_SCR+1
        lda intro_col_hi,x
        sta ZP_COL+1
        lda ZP_SCR
        sta ZP_COL

        ldy #3
        lda #163                        ; Bord gauche
        sta (ZP_SCR),y
        lda #COL_YELLOW
        sta (ZP_COL),y

        ldy #36
        lda #164                        ; Bord droit
        sta (ZP_SCR),y
        lda #COL_YELLOW
        sta (ZP_COL),y

        inx
        cpx #22
        bne .roll_sides"""

replacement_draw_story = """; --- 2. BORDS DÉROULÉS DU PARCHEMIN ET INTÉRIEUR LISIBLE ---
        ldx #2
.roll_sides:
        lda intro_scr_lo,x
        sta ZP_SCR
        lda intro_scr_hi,x
        sta ZP_SCR+1
        lda intro_col_hi,x
        sta ZP_COL+1
        lda ZP_SCR
        sta ZP_COL

        ldy #3
        lda #163                        ; Bord gauche
        sta (ZP_SCR),y
        lda #COL_YELLOW
        sta (ZP_COL),y

        ldy #36
        lda #164                        ; Bord droit
        sta (ZP_SCR),y
        lda #COL_YELLOW
        sta (ZP_COL),y

        ; Initialise la couleur de lecture intérieure en BLANC ÉCLATANT
        cpx #4
        bcc +
        cpx #22
        bcs +
        ldy #4
.init_col_white:
        lda #COL_WHITE
        sta (ZP_COL),y
        iny
        cpy #36
        bne .init_col_white
+
        inx
        cpx #22
        bne .roll_sides"""

text = text.replace(target_draw_story, replacement_draw_story)

# Même chose pour intro_draw_treasures_bg
target_draw_tr = """; Bords déroulés
        ldx #2
.roll_sides_tr:
        lda intro_scr_lo,x
        sta ZP_SCR
        lda intro_scr_hi,x
        sta ZP_SCR+1
        lda intro_col_hi,x
        sta ZP_COL+1
        lda ZP_SCR
        sta ZP_COL

        ldy #3
        lda #163
        sta (ZP_SCR),y
        lda #COL_YELLOW
        sta (ZP_COL),y

        ldy #36
        lda #164
        sta (ZP_SCR),y
        lda #COL_YELLOW
        sta (ZP_COL),y

        inx
        cpx #22
        bne .roll_sides_tr"""

replacement_draw_tr = """; Bords déroulés
        ldx #2
.roll_sides_tr:
        lda intro_scr_lo,x
        sta ZP_SCR
        lda intro_scr_hi,x
        sta ZP_SCR+1
        lda intro_col_hi,x
        sta ZP_COL+1
        lda ZP_SCR
        sta ZP_COL

        ldy #3
        lda #163
        sta (ZP_SCR),y
        lda #COL_YELLOW
        sta (ZP_COL),y

        ldy #36
        lda #164
        sta (ZP_SCR),y
        lda #COL_YELLOW
        sta (ZP_COL),y

        cpx #4
        bcc +
        cpx #22
        bcs +
        ldy #4
.init_col_tr_white:
        lda #COL_WHITE
        sta (ZP_COL),y
        iny
        cpy #36
        bne .init_col_tr_white
+
        inx
        cpx #22
        bne .roll_sides_tr"""

text = text.replace(target_draw_tr, replacement_draw_tr)

# 2. Rendre intro_pan_down_step instantané et direct :
# Pour descendre la cascade vers le parchemin :
# Remplacer intro_pan_down_step par un glissement propre sans corruption de RAM :
target_pan_func = text[text.find("intro_pan_down_step:"):text.find("intro_draw_story_bg:")]
new_pan_func = """intro_pan_down_step:
        ; Décalage fluide de 40 colonnes vers le haut de SCREEN_RAM et COLOR_RAM (lignes 0..23)
        ldx #0
.pan_loop:
        lda SCREEN_RAM+40,x
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

        lda SCREEN_RAM+40+$2c0,x
        sta SCREEN_RAM+$2c0,x
        lda COLOR_RAM+40+$2c0,x
        sta COLOR_RAM+$2c0,x
        inx
        bne .pan_loop

        ; Injecte sur la ligne 24 le parchemin qui entre par le bas
        ldx intro_pan_step
        cpx #3
        bcs +
        ; Eau du lac
        ldy #0
.inj_l: lda #134
        sta SCREEN_RAM+960,y
        lda #COL_BLUE
        sta COLOR_RAM+960,y
        iny
        cpy #40
        bne .inj_l
        rts
+       bne +
        ; Haut du rouleau
        ldy #0
.cl_r24:
        lda #32
        sta SCREEN_RAM+960,y
        lda #COL_BLACK
        sta COLOR_RAM+960,y
        iny
        cpy #40
        bne .cl_r24
        lda #160
        sta SCREEN_RAM+960+3
        lda #COL_YELLOW
        sta COLOR_RAM+960+3
        ldy #4
.inj_rt:
        lda #161
        sta SCREEN_RAM+960,y
        lda #COL_YELLOW
        sta COLOR_RAM+960,y
        iny
        cpy #36
        bne .inj_rt
        lda #162
        sta SCREEN_RAM+960+36
        lda #COL_YELLOW
        sta COLOR_RAM+960+36
        rts
+       cpx #4
        bne +
        ; Titre
        ldy #0
.cl_t24:
        lda #32
        sta SCREEN_RAM+960,y
        lda #COL_BLACK
        sta COLOR_RAM+960,y
        iny
        cpy #40
        bne .cl_t24
        lda #163
        sta SCREEN_RAM+960+3
        lda #164
        sta SCREEN_RAM+960+36
        lda #COL_YELLOW
        sta COLOR_RAM+960+3
        sta COLOR_RAM+960+36
        ldx #0
.inj_stt:
        lda txt_story_title,x
        beq ++
        sta SCREEN_RAM+960+11,x
        lda #COL_YELLOW
        sta COLOR_RAM+960+11,x
        inx
        bne .inj_stt
++      rts
+       cpx #5
        bne +
        ; Filet
        ldy #0
.cl_s24:
        lda #32
        sta SCREEN_RAM+960,y
        lda #COL_BLACK
        sta COLOR_RAM+960,y
        iny
        cpy #40
        bne .cl_s24
        lda #163
        sta SCREEN_RAM+960+3
        lda #164
        sta SCREEN_RAM+960+36
        lda #COL_YELLOW
        sta COLOR_RAM+960+3
        sta COLOR_RAM+960+36
        ldx #0
.inj_sep2:
        lda #115
        sta SCREEN_RAM+960+10,x
        lda #COL_YELLOW
        sta COLOR_RAM+960+10,x
        inx
        cpx #20
        bne .inj_sep2
        rts
+       cpx #23
        bne +
        ; Bas rouleau
        ldy #0
.cl_b24:
        lda #32
        sta SCREEN_RAM+960,y
        lda #COL_BLACK
        sta COLOR_RAM+960,y
        iny
        cpy #40
        bne .cl_b24
        lda #165
        sta SCREEN_RAM+960+3
        lda #COL_YELLOW
        sta COLOR_RAM+960+3
        ldy #4
.inj_rb:
        lda #166
        sta SCREEN_RAM+960,y
        lda #COL_YELLOW
        sta COLOR_RAM+960,y
        iny
        cpy #36
        bne .inj_rb
        lda #167
        sta SCREEN_RAM+960+36
        lda #COL_YELLOW
        sta COLOR_RAM+960+36
        rts
+
        ; Corps déroulé
        ldy #0
.cl_c24:
        lda #32
        sta SCREEN_RAM+960,y
        lda #COL_WHITE
        sta COLOR_RAM+960,y
        iny
        cpy #40
        bne .cl_c24
        lda #163
        sta SCREEN_RAM+960+3
        lda #164
        sta SCREEN_RAM+960+36
        lda #COL_YELLOW
        sta COLOR_RAM+960+3
        sta COLOR_RAM+960+36
        rts

"""

text = text.replace(target_pan_func, new_pan_func)

with open('src/intro.asm', 'w') as f:
    f.write(text)

print("Applied perfect scrolling and pan-down fix!")
