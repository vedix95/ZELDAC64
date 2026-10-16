# Mettons à jour src/intro.asm avec :
# 1. intro_draw_story_bg : Dessine le magnifique cadre du parchemin d'Hyrule
# 2. intro_scroll_story_step : Fait défiler le texte de bas en haut (lignes 4..21, cols 5..34)
#    en copiant les caractères et en appliquant COL_WHITE (ou COL_YELLOW)
#    et en insérant la nouvelle ligne sur la ligne 21 sans toucher aux bords du parchemin !
# 3. intro_draw_treasures_bg & intro_scroll_treasure_step : Parchemin royal des trésors !
# 4. Défilement plus dynamique et fluide (timing raccourci de la cascade à 7s pour démarrer plus vite)

with open('src/intro.asm', 'r') as f:
    text = f.read()

# 1. Raccourcir le timeout de la cascade : passer à 6 secondes (300 frames) pour voir le parchemin défiler rapidement
text = text.replace("lda intro_timer+1\n        cmp #2\n        bcc .wf_done\n        lda intro_timer\n        cmp #88",
                    "lda intro_timer+1\n        cmp #1\n        bcc .wf_done\n        lda intro_timer\n        cmp #44")

# 2. Remplacer intro_draw_story_bg et intro_scroll_story_step
p_story = text.find("; DESSIN ET DEFILEMENT DU PROLOGUE DE L'HISTOIRE")
p_treasures = text.find("; DESSIN ET DEFILEMENT DES TRESORS DE ZELDA 1")

new_story_section = """; DESSIN ET DEFILEMENT DU PROLOGUE DE L'HISTOIRE (PARCHEMIN ROYAL)
; ---------------------------------------------------------------------------
intro_draw_story_bg:
        jsr intro_clear_scroll_area

        ; --- 1. HAUT DU ROULEAU DE PARCHEMIN (Ligne 1) ---
        lda #160                        ; Coin HG
        sta SCREEN_RAM+40+3
        lda #COL_YELLOW
        sta COLOR_RAM+40+3

        ldx #0
.roll_top:
        lda #161                        ; Bord haut enroulé
        sta SCREEN_RAM+40+4,x
        lda #COL_YELLOW
        sta COLOR_RAM+40+4,x
        inx
        cpx #32
        bne .roll_top

        lda #162                        ; Coin HD
        sta SCREEN_RAM+40+36
        lda #COL_YELLOW
        sta COLOR_RAM+40+36

        ; Titre doré centré (Ligne 2)
        ldx #0
.ttl:
        lda txt_story_title,x
        beq +
        sta SCREEN_RAM+80+11,x
        lda #COL_YELLOW
        sta COLOR_RAM+80+11,x
        inx
        bne .ttl
+
        ; Filet d'or sous le titre (Ligne 3)
        ldx #0
.sep2:
        lda #115
        sta SCREEN_RAM+120+10,x
        lda #COL_YELLOW
        sta COLOR_RAM+120+10,x
        inx
        cpx #20
        bne .sep2

        ; --- 2. BORDS DÉROULÉS DU PARCHEMIN (Lignes 2..21) ---
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
        bne .roll_sides

        ; --- 3. BAS DU ROULEAU DE PARCHEMIN (Ligne 22) ---
        lda #165                        ; Coin BG
        sta SCREEN_RAM+880+3
        lda #COL_YELLOW
        sta COLOR_RAM+880+3

        ldx #0
.roll_bot:
        lda #166                        ; Bord bas enroulé
        sta SCREEN_RAM+880+4,x
        lda #COL_YELLOW
        sta COLOR_RAM+880+4,x
        inx
        cpx #32
        bne .roll_bot

        lda #167                        ; Coin BD
        sta SCREEN_RAM+880+36
        lda #COL_YELLOW
        sta COLOR_RAM+880+36

        ; Mention clignotante du bas (Ligne 24)
        jsr intro_show_press_text_parchment
        rts

intro_clear_scroll_area:
        lda #COL_BLACK
        sta VIC_BACKGROUND
        sta VIC_BORDER
        ldx #0
.clra:
        lda #32
        sta SCREEN_RAM,x
        sta SCREEN_RAM+$100,x
        sta SCREEN_RAM+$200,x
        sta SCREEN_RAM+$2e8,x
        lda #COL_BLACK
        sta COLOR_RAM,x
        sta COLOR_RAM+$100,x
        sta COLOR_RAM+$200,x
        sta COLOR_RAM+$2e8,x
        inx
        bne .clra
        rts

intro_show_press_text_parchment:
        ldx #0
.spp:
        lda txt_press_button,x
        beq +
        sta SCREEN_RAM+960+10,x
        lda #COL_YELLOW
        sta COLOR_RAM+960+10,x
        inx
        bne .spp
+       rts

intro_scroll_story_step:
        ; Décale vers le haut les lignes de texte du parchemin (lignes 4 à 21, cols 5 à 34)
        ldx #4
.scroll_up:
        lda intro_scr_lo,x
        sta ZP_DST
        lda intro_scr_hi,x
        sta ZP_DST+1

        inx
        lda intro_scr_lo,x
        sta ZP_SRC
        lda intro_scr_hi,x
        sta ZP_SRC+1

        ldy #5
.shift_line:
        lda (ZP_SRC),y
        sta (ZP_DST),y
        iny
        cpy #35
        bne .shift_line

        cpx #21
        bne .scroll_up

        ; Injecte la nouvelle ligne sur la ligne 21 du parchemin
        lda intro_scroll_line
        cmp #story_line_count
        bcs .blank_line

        asl
        tax
        lda story_ptrs,x
        sta ZP_SRC
        lda story_ptrs+1,x
        sta ZP_SRC+1

        ; Nettoie la zone de texte de la ligne 21
        ldy #5
        lda #32
.clr21:
        sta SCREEN_RAM+840,y
        iny
        cpy #35
        bne .clr21

        ; Copie le texte centré sur la ligne 21 avec couleur BLANC ÉCLATANT
        ldy #0
.put_line:
        lda (ZP_SRC),y
        beq .line_done
        sta SCREEN_RAM+840+5,y
        lda #COL_WHITE
        sta COLOR_RAM+840+5,y
        iny
        cpy #30
        bne .put_line
.line_done:
        rts

.blank_line:
        ldy #5
        lda #32
.clrb:  sta SCREEN_RAM+840,y
        iny
        cpy #35
        bne .clrb
        rts

"""

# 3. Mettre à jour également les Trésors dans le même parchemin
new_treasures_section = """; DESSIN ET DEFILEMENT DES TRESORS DE ZELDA 1 (PARCHEMIN DES TRÉSORS)
; ---------------------------------------------------------------------------
intro_draw_treasures_bg:
        jsr intro_clear_scroll_area

        ; Haut du rouleau
        lda #160
        sta SCREEN_RAM+40+3
        lda #COL_YELLOW
        sta COLOR_RAM+40+3
        ldx #0
.rttr:
        lda #161
        sta SCREEN_RAM+40+4,x
        lda #COL_YELLOW
        sta COLOR_RAM+40+4,x
        inx
        cpx #32
        bne .rttr
        lda #162
        sta SCREEN_RAM+40+36
        lda #COL_YELLOW
        sta COLOR_RAM+40+36

        ; Titre
        ldx #0
.ttltr:
        lda txt_treasures_title,x
        beq +
        sta SCREEN_RAM+80+10,x
        lda #COL_YELLOW
        sta COLOR_RAM+80+10,x
        inx
        bne .ttltr
+
        ldx #0
.sep3:
        lda #115
        sta SCREEN_RAM+120+10,x
        lda #COL_YELLOW
        sta COLOR_RAM+120+10,x
        inx
        cpx #20
        bne .sep3

        ; Bords déroulés
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
        bne .roll_sides_tr

        ; Bas du rouleau
        lda #165
        sta SCREEN_RAM+880+3
        lda #COL_YELLOW
        sta COLOR_RAM+880+3
        ldx #0
.rbtr:
        lda #166
        sta SCREEN_RAM+880+4,x
        lda #COL_YELLOW
        sta COLOR_RAM+880+4,x
        inx
        cpx #32
        bne .rbtr
        lda #167
        sta SCREEN_RAM+880+36
        lda #COL_YELLOW
        sta COLOR_RAM+880+36

        jsr intro_show_press_text_parchment
        rts

intro_scroll_treasure_step:
        ; Décale vers le haut les lignes 4..21 à l'intérieur du parchemin
        ldx #4
.scroll_tr_up:
        lda intro_scr_lo,x
        sta ZP_DST
        lda intro_scr_hi,x
        sta ZP_DST+1

        inx
        lda intro_scr_lo,x
        sta ZP_SRC
        lda intro_scr_hi,x
        sta ZP_SRC+1

        ldy #5
.shift_tr:
        lda (ZP_SRC),y
        sta (ZP_DST),y
        iny
        cpy #35
        bne .shift_tr

        cpx #21
        bne .scroll_tr_up

        ; Injecte le trésor sur la ligne 21
        lda intro_scroll_line
        cmp #treasure_count
        bcs .tr_blank

        tax
        lda treasure_icons,x
        sta ZP_TMP
        lda treasure_colors,x
        sta ZP_ROW

        txa
        asl
        tax
        lda treasure_ptrs,x
        sta ZP_SRC
        lda treasure_ptrs+1,x
        sta ZP_SRC+1

        ldy #5
        lda #32
.clr_tr21:
        sta SCREEN_RAM+840,y
        iny
        cpy #35
        bne .clr_tr21

        ; Dessine l'icône de l'objet à la colonne 6
        lda ZP_TMP
        sta SCREEN_RAM+840+6
        lda ZP_ROW
        sta COLOR_RAM+840+6

        ; Tiret
        lda #'-'
        sta SCREEN_RAM+840+8
        lda #COL_GREY
        sta COLOR_RAM+840+8

        ; Nom de l'objet à partir de la colonne 10
        ldy #0
.put_tr:
        lda (ZP_SRC),y
        beq .tr_done_line
        sta SCREEN_RAM+840+10,y
        lda #COL_WHITE
        sta COLOR_RAM+840+10,y
        iny
        cpy #24
        bne .put_tr
.tr_done_line:
        rts

.tr_blank:
        ldy #5
        lda #32
.clrtb: sta SCREEN_RAM+840,y
        iny
        cpy #35
        bne .clrtb
        rts

"""

p_music = text.find("; ===========================================================================", p_treasures)

text = text[:p_story] + new_story_section + new_treasures_section + text[p_music:]

with open('src/intro.asm', 'w') as f:
    f.write(text)

print("Generated royal parchment scrolling engine!")
