# Générons le code 6502 dans src/intro.asm qui reproduit fidèlement cet écran
with open('src/intro.asm', 'r') as f:
    text = f.read()

# Remplacer intro_draw_waterfall
p_start = text.find("intro_draw_waterfall:")
p_end = text.find("; ---------------------------------------------------------------------------", p_start)
if p_end == -1:
    p_end = text.find("intro_animate_water:", p_start)

new_func = """intro_draw_waterfall:
        lda #COL_BLACK
        sta VIC_BACKGROUND
        sta VIC_BORDER

        ; Efface l'écran (1000 caractères espace) et met les couleurs à noir
        ldx #0
.clr:
        lda #32                         ; Espace
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
        bne .clr

        ; --- 1. LOGO MAJESTUEUX "THE LEGEND OF ZELDA" ---
        ; "THE  LEGEND  OF" (Ligne 1, col 13)
        ldx #0
.tlo:
        lda txt_title_legend,x
        beq +
        sta SCREEN_RAM+40+13,x
        lda #COL_WHITE
        sta COLOR_RAM+40+13,x
        inx
        bne .tlo
+
        ; Grand logo 16x16 doré "Z E L D A" (Lignes 2..3, cols 13..27)
        ldx #0
.put_logo:
        lda zelda_logo_top,x
        beq +
        sta SCREEN_RAM+80+13,x
        lda #COL_YELLOW
        sta COLOR_RAM+80+13,x

        lda zelda_logo_bot,x
        sta SCREEN_RAM+120+13,x
        lda #COL_YELLOW
        sta COLOR_RAM+120+13,x
        inx
        bne .put_logo
+
        ; Grandes Triforces royales dorées encadrant le titre
        ; Gauche (Lignes 2..3, cols 7..8)
        lda #156
        sta SCREEN_RAM+80+7
        lda #157
        sta SCREEN_RAM+80+8
        lda #158
        sta SCREEN_RAM+120+7
        lda #159
        sta SCREEN_RAM+120+8

        lda #COL_YELLOW
        sta COLOR_RAM+80+7
        sta COLOR_RAM+80+8
        sta COLOR_RAM+120+7
        sta COLOR_RAM+120+8

        ; Droite (Lignes 2..3, cols 31..32)
        lda #156
        sta SCREEN_RAM+80+31
        lda #157
        sta SCREEN_RAM+80+32
        lda #158
        sta SCREEN_RAM+120+31
        lda #159
        sta SCREEN_RAM+120+32

        lda #COL_YELLOW
        sta COLOR_RAM+80+31
        sta COLOR_RAM+80+32
        sta COLOR_RAM+120+31
        sta COLOR_RAM+120+32

        ; Ligne de filet d'or sous le logo (Ligne 4, cols 6..33)
        ldx #0
.sep_gold:
        lda #115
        sta SCREEN_RAM+160+6,x
        lda #COL_YELLOW
        sta COLOR_RAM+160+6,x
        inx
        cpx #28
        bne .sep_gold

        ; --- 2. FALAISES ÉTAGÉES ET FORETS DE DEATH MOUNTAIN (Lignes 5..18) ---
        ldx #5
.cliff_loop:
        lda intro_scr_lo,x
        sta ZP_SCR
        lda intro_scr_hi,x
        sta ZP_SCR+1
        lda intro_col_hi,x
        sta ZP_COL+1
        lda ZP_SCR
        sta ZP_COL

        ; Largeurs gauche et droite
        lda cliff_left_width-5,x
        sta ZP_TMP                      ; largeur falaise gauche
        lda cliff_right_start-5,x
        sta ZP_ROW                      ; départ falaise droite

        ; Remplissage rocheux gauche
        ldy #0
.fill_cg:
        lda #128                        ; Pierre texturée
        sta (ZP_SCR),y
        lda #COL_GREY
        sta (ZP_COL),y
        iny
        cpy ZP_TMP
        bne .fill_cg

        ; Biseau gauche éclairé
        lda #130
        sta (ZP_SCR),y
        lda #COL_LGREY
        sta (ZP_COL),y

        ; Biseau droit ombré
        ldy ZP_ROW
        dey
        lda #131
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y
        iny

        ; Remplissage rocheux droit
.fill_cd:
        lda #128
        sta (ZP_SCR),y
        lda #COL_GREY
        sta (ZP_COL),y
        iny
        cpy #40
        bne .fill_cd

        inx
        cpx #19
        bne .cliff_loop

        ; Pins et sapins verts sur les paliers rocheux
        ldx #0
.put_trees:
        lda tree_row_tbl,x
        beq .trees_done
        tay
        lda intro_scr_lo,y
        sta ZP_SCR
        lda intro_scr_hi,y
        sta ZP_SCR+1
        lda intro_col_hi,y
        sta ZP_COL+1
        lda ZP_SCR
        sta ZP_COL

        lda tree_col_tbl,x
        tay
        lda #132                        ; Pin vert
        sta (ZP_SCR),y
        lda #COL_GREEN
        sta (ZP_COL),y

        inx
        bne .put_trees
.trees_done:

        ; --- 3. BASSIN D'EAU EN BAS (Lignes 19..20) ---
        ; Ligne 19 : Eau avec vagues sur les côtés
        ldx #0
.lake_waves1:
        lda #134                        ; Vagues
        sta SCREEN_RAM+760+6,x
        sta SCREEN_RAM+760+24,x
        lda #COL_BLUE
        sta COLOR_RAM+760+6,x
        sta COLOR_RAM+760+24,x
        inx
        cpx #10
        bne .lake_waves1

        ; Ligne 20 : Grand bassin d'eau étincelant
        ldx #0
.lake_main:
        lda #134
        sta SCREEN_RAM+800+4,x
        lda #COL_BLUE
        sta COLOR_RAM+800+4,x
        inx
        cpx #32
        bne .lake_main

        ; --- 4. MENTIONS DU BAS (Lignes 22..24) ---
        jsr intro_show_press_text

        ldx #0
.nint:
        lda txt_nintendo,x
        beq +
        sta SCREEN_RAM+960+13,x
        lda #COL_LGREY
        sta COLOR_RAM+960+13,x
        inx
        bne .nint
+
        jsr intro_animate_water
        rts

; Données du logo 16x16 Z E L D A
zelda_logo_top:
        !byte 136, 137, 32, 140, 141, 32, 144, 145, 32, 148, 149, 32, 152, 153, 0

zelda_logo_bot:
        !byte 138, 139, 32, 142, 143, 32, 146, 147, 32, 150, 151, 32, 154, 155, 0

; Tables de relief des falaises (pour lignes 5..18)
cliff_left_width:
        !byte 11, 12, 13, 14, 15, 15, 16, 16, 16, 16, 17, 17, 17, 17
cliff_right_start:
        !byte 29, 28, 27, 26, 25, 25, 24, 24, 24, 24, 23, 23, 23, 23

tree_row_tbl:
        !byte 5, 5, 8, 8, 12, 12, 0
tree_col_tbl:
        !byte 3, 36, 6, 33, 8, 31, 0

"""

text = text[:p_start] + new_func + text[p_end:]
with open('src/intro.asm', 'w') as f:
    f.write(text)

print("Updated src/intro.asm with masterpiece graphics routine!")
