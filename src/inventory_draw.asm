; ---------------------------------------------------------------------------
; inventory_draw.asm : Affichage graphique du menu d'inventaire en 4 pages
; Direction artistique inspirée de Link's Awakening Switch :
;   - En-tête à onglets parfaitement espacé + filets dorés haut/bas (lignes 5 & 22)
;   - Page 0 : [1:ITEMS]    - Carte [B] gauche, grille 4x2 individuelle + curseur 4 coins
;                             + description centrée sur 2 lignes + barre reliques
;   - Page 1 : [2:TRIFORCE] - Sanctuaire encadré + pyramide d'or 48x32 sans coutures
;   - Page 2 : [3:EQUIP]    - 8 cartes 8x6 propres (zéro chevauchement bordure/texte)
;   - Page 3 : [4:MAP]      - Carte Overworld 16x8 ou Carte Donjon 8x8 encadrée
; ---------------------------------------------------------------------------

!zone inventory_draw

; Codes des caractères de la frise et des cadres héroïques
CHAR_HERO_TL      = 232
CHAR_HERO_TOP     = 233
CHAR_HERO_TR      = 234
CHAR_HERO_VERT    = 235
CHAR_HERO_BL      = 236
CHAR_HERO_BOT     = 237
CHAR_HERO_BR      = 238
CHAR_HERO_DIV     = 239

CHAR_SLOT_TL      = 240
CHAR_SLOT_TR      = 241
CHAR_SLOT_BL      = 242
CHAR_SLOT_BR      = 243
CHAR_SLOT_TH      = 244
CHAR_SLOT_BH      = 245
CHAR_SLOT_LV      = 246
CHAR_SLOT_RV      = 247
CHAR_DIAMOND      = 248

; Tables des sprites des 8 armes sélectionnables (Slot B)
item_sprite_ptrs:
        !byte (sprite_link_item_boomerang / 64)
        !byte (sprite_link_item_bomb / 64)
        !byte (sprite_link_item_bow / 64)
        !byte (sprite_link_item_candle / 64)
        !byte (sprite_link_item_whistle / 64)
        !byte (sprite_link_item_food / 64)
        !byte (sprite_link_item_potion / 64)
        !byte (sprite_link_item_wand / 64)

; Coordonnées exactes VIC-II centrées dans les 8 cases 5x4 (cols 14..18, 20..24, 26..30, 32..36)
; Formule : sx = 24 + (colL+colR+1)*4 - 12 => 144, 192, 240, 288 ($120 -> lo=32, MSB=1)
cursor_x_coords:
        !byte 144, 192, 240, 32         ; rangée 1 : Boomerang, Bombe, Arc, Bougie
        !byte 144, 192, 240, 32         ; rangée 2 : Flûte, Viande, Potion, Baguette

cursor_x_msb:
        !byte 0, 0, 0, 1
        !byte 0, 0, 0, 1

; Rangée 1 (lignes 7..10) -> Y=112 ; Rangée 2 (lignes 12..15) -> Y=152
cursor_y_coords:
        !byte 112, 112, 112, 112
        !byte 152, 152, 152, 152

flash_colors:
        !byte COL_YELLOW, COL_WHITE, COL_YELLOW, COL_ORANGE

; Adresses écran des 8 rangées de carte (lignes texte 8..15 : SCREEN_RAM + 320 .. + 600)
map_row_scr_lo:
        !byte <($0400+320), <($0400+360), <($0400+400), <($0400+440)
        !byte <($0400+480), <($0400+520), <($0400+560), <($0400+600)
map_row_scr_hi:
        !byte >($0400+320), >($0400+360), >($0400+400), >($0400+440)
        !byte >($0400+480), >($0400+520), >($0400+560), >($0400+600)
map_row_col_hi:
        !byte >($d800+320), >($d800+360), >($d800+400), >($d800+440)
        !byte >($d800+480), >($d800+520), >($d800+560), >($d800+600)

; Table des 25 débuts de lignes écran (lignes 0..24) pour helpers génériques
inv_scr_row_lo:
        !for r, 0, 24 { !byte <(SCREEN_RAM + r * 40) }
inv_scr_row_hi:
        !for r, 0, 24 { !byte >(SCREEN_RAM + r * 40) }

; Paramètres du traceur générique de boîtes & texte centré
box_col:        !byte 0
box_row:        !byte 0
box_w:          !byte 0
box_h:          !byte 0
box_color:      !byte 0
box_cur_row:    !byte 0
box_rem_h:      !byte 0
p0_cur_msb:     !byte 0

; ---------------------------------------------------------------------------
; inv_display_current_page : efface et redessine la page active
; ---------------------------------------------------------------------------
ovl_inv_display_current_page:
        jsr clear_inv_area
        jsr draw_tab_header

        lda inv_page
        cmp #0
        bne +
        jmp draw_page_0_items
+       cmp #1
        bne +
        jmp draw_page_1_triforce
+       cmp #2
        bne +
        jmp draw_page_2_equipment
+       jmp draw_page_3_map

; ---------------------------------------------------------------------------
; clear_inv_area : efface les lignes 4 à 24
; ---------------------------------------------------------------------------
clear_inv_area:
        ldx #0
.clr_loop:
        lda #32
        sta SCREEN_RAM+160,x
        sta SCREEN_RAM+160+$100,x
        sta SCREEN_RAM+160+$200,x
        lda #COL_WHITE
        sta COLOR_RAM+160,x
        sta COLOR_RAM+160+$100,x
        sta COLOR_RAM+160+$200,x
        inx
        bne .clr_loop

        ldx #0
.clr_rem:
        lda #32
        sta SCREEN_RAM+160+$300,x
        lda #COL_WHITE
        sta COLOR_RAM+160+$300,x
        inx
        cpx #80
        bne .clr_rem
        rts

; ---------------------------------------------------------------------------
; Helpers génériques d'interface (cadres parfaits + texte centré sur 40 cols)
; ---------------------------------------------------------------------------

; inv_set_row_ptr : X = numéro de ligne (0..24) -> ZP_SCR & ZP_COL pointent en col 0
inv_set_row_ptr:
        lda inv_scr_row_lo,x
        sta ZP_SCR
        sta ZP_COL
        lda inv_scr_row_hi,x
        sta ZP_SCR+1
        clc
        adc #$d4
        sta ZP_COL+1
        rts

; inv_set_scr_col_hi : A = offset hi -> ZP_SCR+1 & ZP_COL+1
inv_set_scr_col_hi:
        clc
        adc #>SCREEN_RAM
        sta ZP_SCR+1
        clc
        adc #$d4
        sta ZP_COL+1
        rts

; draw_ui_box : trace un cadre CHAR_SLOT_* propre sans jamais oublier une couleur
; Entrée : box_col, box_row, box_w (>=2), box_h (>=2), box_color
draw_ui_box:
        ; 1. Bordure haute
        ldx box_row
        jsr inv_set_row_ptr
        ldy box_col
        lda #CHAR_SLOT_TL
        sta (ZP_SCR),y
        lda box_color
        sta (ZP_COL),y

        ldx box_w
        dex
        dex                             ; X = nombre de cases intérieures horizontales
        beq .dub_top_r
-       iny
        lda #CHAR_SLOT_TH
        sta (ZP_SCR),y
        lda box_color
        sta (ZP_COL),y
        dex
        bne -
.dub_top_r:
        iny
        lda #CHAR_SLOT_TR
        sta (ZP_SCR),y
        lda box_color
        sta (ZP_COL),y

        ; 2. Bordures verticales (lignes intermédiaires)
        lda box_row
        sta box_cur_row
        lda box_h
        sec
        sbc #2
        sta box_rem_h
        beq .dub_bottom

.dub_vert_loop:
        inc box_cur_row
        ldx box_cur_row
        jsr inv_set_row_ptr
        ldy box_col
        lda #CHAR_SLOT_LV
        sta (ZP_SCR),y
        lda box_color
        sta (ZP_COL),y

        tya
        clc
        adc box_w
        tay
        dey
        lda #CHAR_SLOT_RV
        sta (ZP_SCR),y
        lda box_color
        sta (ZP_COL),y

        dec box_rem_h
        bne .dub_vert_loop

.dub_bottom:
        ; 3. Bordure basse
        inc box_cur_row
        ldx box_cur_row
        jsr inv_set_row_ptr
        ldy box_col
        lda #CHAR_SLOT_BL
        sta (ZP_SCR),y
        lda box_color
        sta (ZP_COL),y

        ldx box_w
        dex
        dex
        beq .dub_bot_r
-       iny
        lda #CHAR_SLOT_BH
        sta (ZP_SCR),y
        lda box_color
        sta (ZP_COL),y
        dex
        bne -
.dub_bot_r:
        iny
        lda #CHAR_SLOT_BR
        sta (ZP_SCR),y
        lda box_color
        sta (ZP_COL),y
        rts

; inv_print_str_centered : affiche une chaîne 0-terminée centrée sur 40 colonnes
; Entrée : ZP_SRC = chaîne (0-terminée), X = ligne (0..24), A = couleur
inv_print_str_centered:
        sta box_color
        jsr inv_set_row_ptr
        ldy #0
-       lda (ZP_SRC),y
        beq +
        iny
        cpy #40
        bcc -
+       sty ZP_TMP
        lda #40
        sec
        sbc ZP_TMP
        lsr
        sta ZP_TCOL                     ; colonne de départ
        ldy #0
.ipsc_loop:
        lda (ZP_SRC),y
        beq .ipsc_done
        pha
        tya
        pha
        clc
        adc ZP_TCOL
        tay
        tsx
        lda $0102,x                     ; caractère sauvé sur la pile
        sta (ZP_SCR),y
        lda box_color
        sta (ZP_COL),y
        pla
        tay
        pla
        iny
        bne .ipsc_loop
.ipsc_done:
        rts

; ---------------------------------------------------------------------------
; draw_tab_header : bandeau onglets + filets dorés style Link's Awakening
; ---------------------------------------------------------------------------
draw_tab_header:
        ; Ligne 4 : Onglets espacés symétriquement
        ldx #39
-       lda txt_tabs_base,x
        sta SCREEN_RAM+160,x
        lda #COL_LIGHT_GREY
        sta COLOR_RAM+160,x
        dex
        bpl -

        lda inv_page
        asl
        tax
        ldy tab_bracket_pos,x
        lda #'['
        sta SCREEN_RAM+160,y
        ldy tab_bracket_pos+1,x
        lda #']'
        sta SCREEN_RAM+160,y

        ; Met en valeur l'onglet actif en jaune doré
        ldy inv_page
        ldx tab_start,y
-       lda #COL_YELLOW
        sta COLOR_RAM+160,x
        inx
        txa
        cmp tab_end,y
        bne -

        ; Ligne 5 : Filet doré fin supérieur (dégage 6 px noirs au-dessus des titres ligne 6)
        ldx #1
-       lda #CHAR_SLOT_TH
        sta SCREEN_RAM+200,x
        lda #COL_YELLOW
        sta COLOR_RAM+200,x
        inx
        cpx #39
        bne -
        lda #CHAR_DIAMOND
        sta SCREEN_RAM+200+1
        sta SCREEN_RAM+200+38
        lda #COL_ORANGE
        sta COLOR_RAM+200+1
        sta COLOR_RAM+200+38

        ; Ligne 22 : Filet doré fin inférieur (dégage 6 px noirs au-dessus de la barre d'aide)
        ldx #1
-       lda #CHAR_SLOT_TH
        sta SCREEN_RAM+880,x
        lda #COL_YELLOW
        sta COLOR_RAM+880,x
        inx
        cpx #39
        bne -
        lda #CHAR_DIAMOND
        sta SCREEN_RAM+880+1
        sta SCREEN_RAM+880+38
        lda #COL_ORANGE
        sta COLOR_RAM+880+1
        sta COLOR_RAM+880+38

        ; Ligne 23 : Barre de navigation unique et épurée
        ldx #39
-       lda txt_footer_help,x
        sta SCREEN_RAM+920,x
        lda #COL_LIGHT_GREEN
        sta COLOR_RAM+920,x
        dex
        bpl -
        rts

; ===========================================================================
; PAGE 0 : OBJETS ACTIFS DU SLOT B (Style Link's Awakening Switch)
; ===========================================================================
draw_page_0_items:
        ; 1. En-têtes Ligne 6 (sous la frise dorée intacte de la Ligne 5)
        ldx #7
-       lda txt_p0_b_hdr,x
        sta SCREEN_RAM+240+3,x
        lda #COL_LIGHT_GREEN
        sta COLOR_RAM+240+3,x
        dex
        bpl -

        ldx #12
-       lda txt_p0_grid_hdr,x
        sta SCREEN_RAM+240+19,x
        lda #COL_YELLOW
        sta COLOR_RAM+240+19,x
        dex
        bpl -

        ; 2. Carte gauche : Objet assigné au bouton [B] (Cols 3..10, Lignes 7..11)
        lda #3
        sta box_col
        lda #7
        sta box_row
        lda #8
        sta box_w
        lda #5
        sta box_h
        lda #COL_LIGHT_GREEN
        sta box_color
        jsr draw_ui_box

        ; Compteurs compacts sous le cadre [B] (Lignes 13..15, Cols 3..10)
        jsr draw_p0_stock

        ; 3. Grille droite 4x2 : 8 emplacements individuels 5x4 encadrés (Cols 14..36)
        ldx #0
.p0_grid_box_loop:
        txa
        pha
        lda p0_slot_cols,x
        sta box_col
        lda p0_slot_rows,x
        sta box_row
        lda #5
        sta box_w
        lda #4
        sta box_h
        jsr p0_is_item_owned
        beq .p0_box_dim
        lda #COL_CYAN
        bne .p0_box_draw
.p0_box_dim:
        lda #COL_DARK_GREY
.p0_box_draw:
        sta box_color
        jsr draw_ui_box
        pla
        tax
        inx
        cpx #8
        bne .p0_grid_box_loop

        ; 4. Description centrée sur 2 lignes (Lignes 17..18)
        jsr draw_p0_description

        ; 5. Barre compacte des 6 reliques passives (Ligne 20)
        jsr draw_p0_passive_relics

        ; 6. Configure les sprites matériels
        jsr setup_p0_sprites
        rts

p0_slot_cols:
        !byte 14, 20, 26, 32
        !byte 14, 20, 26, 32
p0_slot_rows:
        !byte 7, 7, 7, 7
        !byte 12, 12, 12, 12

; p0_is_item_owned : Entrée X = index arme (0..7). Sortie : A != 0 si possédée, X préservé.
p0_is_item_owned:
        cpx #0
        bne +
        lda player_has_boomerang
        rts
+       cpx #1
        bne +
        lda hud_bombs
        rts
+       cpx #2
        bne +
        lda player_has_bow
        rts
+       cpx #3
        bne +
        lda player_has_candle
        rts
+       cpx #4
        bne +
        lda player_has_whistle
        rts
+       cpx #5
        bne +
        lda player_has_food
        rts
+       cpx #6
        bne +
        lda player_has_potion
        rts
+       lda player_has_wand
        rts

; p0_get_item_color : Entrée X = index (0..7). Sortie : A = couleur dynamique (grisée si absent).
p0_get_item_color:
        cpx #0
        bne +
        lda player_has_boomerang
        beq .col_unowned
        cmp #2
        bcs .col_lblue
        lda #COL_ORANGE
        rts
+       cpx #1
        bne +
        lda hud_bombs
        beq .col_unowned
        lda #COL_LIGHT_BLUE
        rts
+       cpx #2
        bne +
        lda player_has_bow
        beq .col_unowned
        lda #COL_YELLOW
        rts
+       cpx #3
        bne +
        lda player_has_candle
        beq .col_unowned
        cmp #2
        bcs .col_red
        lda #COL_LIGHT_BLUE
        rts
+       cpx #4
        bne +
        lda player_has_whistle
        beq .col_unowned
        lda #COL_YELLOW
        rts
+       cpx #5
        bne +
        lda player_has_food
        beq .col_unowned
        lda #COL_RED
        rts
+       cpx #6
        bne +
        lda player_has_potion
        beq .col_unowned
        cmp #2
        bcs .col_red
        lda #COL_LIGHT_BLUE
        rts
+       lda player_has_wand
        beq .col_unowned
        lda #COL_CYAN
        rts
.col_unowned:
        lda #COL_DARK_GREY
        rts
.col_lblue:
        lda #COL_LIGHT_BLUE
        rts
.col_red:
        lda #COL_RED
        rts

draw_p0_stock:
        ; Ligne 13 : Rubis (3 chiffres 000..255, C4)
        lda #HUD_CHAR_RUPEE
        sta SCREEN_RAM+520+4
        lda #COL_YELLOW
        sta COLOR_RAM+520+4
        lda hud_rupees
        jsr print_3digits
        sta SCREEN_RAM+520+7
        stx SCREEN_RAM+520+8
        sty SCREEN_RAM+520+9
        lda #COL_WHITE
        sta COLOR_RAM+520+7
        sta COLOR_RAM+520+8
        sta COLOR_RAM+520+9

        ; Ligne 14 : Clés
        lda #HUD_CHAR_KEY
        sta SCREEN_RAM+560+4
        lda #COL_YELLOW
        sta COLOR_RAM+560+4
        lda hud_keys
        jsr print_2digits
        sta SCREEN_RAM+560+7
        stx SCREEN_RAM+560+8
        lda #COL_WHITE
        sta COLOR_RAM+560+7
        sta COLOR_RAM+560+8

        ; Ligne 15 : Bombes
        lda #HUD_CHAR_BOMB
        sta SCREEN_RAM+600+4
        lda #COL_LIGHT_BLUE
        sta COLOR_RAM+600+4
        lda hud_bombs
        jsr print_2digits
        sta SCREEN_RAM+600+7
        stx SCREEN_RAM+600+8
        lda #COL_WHITE
        sta COLOR_RAM+600+7
        sta COLOR_RAM+600+8
        rts

draw_p0_passive_relics:
        ; Ligne 20 (SCREEN_RAM+800) : "RELICS :" centré avec les 6 icônes
        ldx #7
-       lda txt_p0_relics_lbl,x
        sta SCREEN_RAM+800+7,x
        lda #COL_LIGHT_GREY
        sta COLOR_RAM+800+7,x
        dex
        bpl -

        ; Radeau (Col 17)
        lda #120
        sta SCREEN_RAM+800+17
        lda player_has_raft
        bne +
        lda #COL_DARK_GREY
        bne ++
+       lda #COL_BROWN
++      sta COLOR_RAM+800+17

        ; Livre (Col 20)
        lda #123
        sta SCREEN_RAM+800+20
        lda player_has_book
        bne +
        lda #COL_DARK_GREY
        bne ++
+       lda #COL_LIGHT_BLUE
++      sta COLOR_RAM+800+20

        ; Anneau (Col 23)
        lda #124
        sta SCREEN_RAM+800+23
        lda player_has_blue_ring
        bne .has_ring
        lda #COL_DARK_GREY
        jmp .set_ring_col
.has_ring:
        cmp #2
        beq .red_ring
        lda #COL_LIGHT_BLUE
        jmp .set_ring_col
.red_ring:
        lda #COL_RED
.set_ring_col:
        sta COLOR_RAM+800+23

        ; Échelle (Col 26)
        lda #121
        sta SCREEN_RAM+800+26
        lda player_has_stepladder
        bne +
        lda #COL_DARK_GREY
        bne ++
+       lda #COL_BROWN
++      sta COLOR_RAM+800+26

        ; Clé Magique (Col 29)
        lda #125
        sta SCREEN_RAM+800+29
        lda player_has_magic_key
        bne +
        lda #COL_DARK_GREY
        bne ++
+       lda #COL_YELLOW
++      sta COLOR_RAM+800+29

        ; Bracelet (Col 32)
        lda #122
        sta SCREEN_RAM+800+32
        lda player_has_bracelet
        bne +
        lda #COL_DARK_GREY
        bne ++
+       lda #COL_YELLOW
++      sta COLOR_RAM+800+32
        rts

setup_p0_sprites:
        lda #0
        sta VIC_SPRITE_EXP_X
        sta VIC_SPRITE_EXP_Y
        lda #PLAYER_SKIN
        sta VIC_SPRITE_MC1
        lda #COL_WHITE
        sta VIC_SPRITE_MC2

        ; Sprite 0 : Arme équipée centrée dans le cadre [B] gauche (X=68, Y=116)
        ldx hud_selected_b
        lda item_sprite_ptrs,x
        sta SPRITE_PTR0
        jsr p0_get_item_color
        sta VIC_SPRITE_COL0
        lda #68
        sta VIC_SPRITE_X0
        lda #116
        sta VIC_SPRITE_Y0

        ; Sprite 7 : Curseur 4 coins style Link's Awakening (multicolore!)
        lda #(sprite_link_item_frame / 64)
        sta SPRITE_PTR7
        lda #COL_YELLOW
        sta VIC_SPRITE_COL7

        jsr inv_update_cursor
        jsr inv_p0_irq_row1

        lda #%10011111                  ; Tous en multicolore (curseur 4 coins épais inclus!)
        sta VIC_SPRITE_MC
        rts

p0_row1_en:     !byte %10000000
p0_row2_en:     !byte %10000000

; Calcule les masques VIC_SPRITE_EN pour les 2 rangées : seuls les objets POSSÉDÉS s'affichent !
p0_build_en_masks:
        lda #%10000000                  ; Bit 7 (curseur) toujours actif
        sta p0_row1_en
        sta p0_row2_en
        ldx hud_selected_b
        jsr p0_is_item_owned
        beq +
        lda #%10000001                  ; Bit 7 (curseur) + Bit 0 (aperçu gauche)
        sta p0_row1_en
        sta p0_row2_en
+

        ; Rangée 1 (items 0..3 -> bits 1..4)
        ldx #0
        jsr p0_is_item_owned
        beq +
        lda p0_row1_en
        ora #%00000010
        sta p0_row1_en
+       ldx #1
        jsr p0_is_item_owned
        beq +
        lda p0_row1_en
        ora #%00000100
        sta p0_row1_en
+       ldx #2
        jsr p0_is_item_owned
        beq +
        lda p0_row1_en
        ora #%00001000
        sta p0_row1_en
+       ldx #3
        jsr p0_is_item_owned
        beq +
        lda p0_row1_en
        ora #%00010000
        sta p0_row1_en
+
        ; Rangée 2 (items 4..7 -> bits 1..4)
        ldx #4
        jsr p0_is_item_owned
        beq +
        lda p0_row2_en
        ora #%00000010
        sta p0_row2_en
+       ldx #5
        jsr p0_is_item_owned
        beq +
        lda p0_row2_en
        ora #%00000100
        sta p0_row2_en
+       ldx #6
        jsr p0_is_item_owned
        beq +
        lda p0_row2_en
        ora #%00001000
        sta p0_row2_en
+       ldx #7
        jsr p0_is_item_owned
        beq +
        lda p0_row2_en
        ora #%00010000
        sta p0_row2_en
+       rts

; ---------------------------------------------------------------------------
; Multiplexeur raster pour la Page 0 (grille 4x2 : Y=112 et Y=152, split à 140)
; ---------------------------------------------------------------------------
inv_p0_irq_row1:
        lda p0_row1_en
        sta VIC_SPRITE_EN

        lda #(sprite_link_item_boomerang / 64)
        sta SPRITE_PTR1
        lda #(sprite_link_item_bomb / 64)
        sta SPRITE_PTR2
        lda #(sprite_link_item_bow / 64)
        sta SPRITE_PTR3
        lda #(sprite_link_item_candle / 64)
        sta SPRITE_PTR4

        ldx #0
        jsr p0_get_item_color
        sta VIC_SPRITE_COL1
        ldx #1
        jsr p0_get_item_color
        sta VIC_SPRITE_COL2
        ldx #2
        jsr p0_get_item_color
        sta VIC_SPRITE_COL3
        ldx #3
        jsr p0_get_item_color
        sta VIC_SPRITE_COL4

        lda #144
        sta VIC_SPRITE_X1
        lda #192
        sta VIC_SPRITE_X2
        lda #240
        sta VIC_SPRITE_X3
        lda #32                         ; 288 - 256 (MSB bit 4 = 1)
        sta VIC_SPRITE_X4

        lda p0_cur_msb                  ; Bit 4 toujours à 1 + bit 7 selon curseur
        ora #%00010000
        sta VIC_SPRITE_MSB

        lda #112
        sta VIC_SPRITE_Y1
        sta VIC_SPRITE_Y2
        sta VIC_SPRITE_Y3
        sta VIC_SPRITE_Y4
        rts

irq_p0_row2:
        lda p0_row2_en
        sta VIC_SPRITE_EN

        lda #(sprite_link_item_whistle / 64)
        sta SPRITE_PTR1
        lda #(sprite_link_item_food / 64)
        sta SPRITE_PTR2
        lda #(sprite_link_item_potion / 64)
        sta SPRITE_PTR3
        lda #(sprite_link_item_wand / 64)
        sta SPRITE_PTR4

        ldx #4
        jsr p0_get_item_color
        sta VIC_SPRITE_COL1
        ldx #5
        jsr p0_get_item_color
        sta VIC_SPRITE_COL2
        ldx #6
        jsr p0_get_item_color
        sta VIC_SPRITE_COL3
        ldx #7
        jsr p0_get_item_color
        sta VIC_SPRITE_COL4

        lda #144
        sta VIC_SPRITE_X1
        lda #192
        sta VIC_SPRITE_X2
        lda #240
        sta VIC_SPRITE_X3
        lda #32                         ; 288 - 256 (MSB bit 4 = 1)
        sta VIC_SPRITE_X4

        lda p0_cur_msb
        ora #%00010000
        sta VIC_SPRITE_MSB

        lda #152
        sta VIC_SPRITE_Y1
        sta VIC_SPRITE_Y2
        sta VIC_SPRITE_Y3
        sta VIC_SPRITE_Y4

        ; Prochaine interruption au bas de l'écran (raster 251 = VBlank propre)
        lda #251
        sta VIC_RASTER
        lda #< irq_bottom
        sta $0314
        lda #> irq_bottom
        sta $0315

        asl VIC_IRQ_FLAG
        jmp $ea81

inv_update_cursor:
        ldx hud_selected_b
        lda item_sprite_ptrs,x
        sta SPRITE_PTR0
        jsr p0_get_item_color
        sta VIC_SPRITE_COL0

        lda cursor_x_coords,x
        sta VIC_SPRITE_X7
        lda cursor_y_coords,x
        sta VIC_SPRITE_Y7

        lda #0
        ldy cursor_x_msb,x
        beq +
        lda #%10000000
+       sta p0_cur_msb
        ora #%00010000
        sta VIC_SPRITE_MSB

        jsr p0_build_en_masks
        jsr draw_p0_description
        rts

draw_p0_description:
        ; Efface proprement les lignes 17 et 18
        ldx #39
        lda #' '
-       sta SCREEN_RAM+680,x
        sta SCREEN_RAM+720,x
        dex
        bpl -

        ; Si l'objet sous le curseur n'est pas encore trouvé : indique LOCKED
        ldx hud_selected_b
        jsr p0_is_item_owned
        bne .p0_desc_owned

        lda #<txt_p0_locked_t
        sta ZP_SRC
        lda #>txt_p0_locked_t
        sta ZP_SRC+1
        ldx #17
        lda #COL_DARK_GREY
        jsr inv_print_str_centered

        lda #<txt_p0_locked_s
        sta ZP_SRC
        lda #>txt_p0_locked_s
        sta ZP_SRC+1
        ldx #18
        lda #COL_DARK_GREY
        jmp inv_print_str_centered

.p0_desc_owned:
        ; Ligne 17 : Titre centré en jaune
        ldx hud_selected_b
        lda p0_desc_lo,x
        sta ZP_SRC
        lda p0_desc_hi,x
        sta ZP_SRC+1
        ldx #17
        lda #COL_YELLOW
        jsr inv_print_str_centered

        ; Ligne 18 : Phrase explicative centrée en blanc (style Link's Awakening)
        ldx hud_selected_b
        lda p0_sub_lo,x
        sta ZP_SRC
        lda p0_sub_hi,x
        sta ZP_SRC+1
        ldx #18
        lda #COL_WHITE
        jmp inv_print_str_centered

txt_p0_locked_t: !text "--- NOT FOUND ---", 0
txt_p0_locked_s: !text "FIND THIS ITEM IN HYRULE", 0

; ===========================================================================
; PAGE 1 : LA TRIFORCE DE LA SAGESSE (8 FRAGMENTS ASSEMBLÉS)
; ===========================================================================
draw_page_1_triforce:
        lda #0
        sta VIC_SPRITE_MSB
        sta VIC_SPRITE_EXP_X
        sta VIC_SPRITE_EXP_Y

        ; Ligne 6 : Titre centré sous la frise dorée
        lda #<txt_p1_title
        sta ZP_SRC
        lda #>txt_p1_title
        sta ZP_SRC+1
        ldx #6
        lda #COL_YELLOW
        jsr inv_print_str_centered

        ; Lignes 7..13, Cols 13..26 : Cadre Sanctuaire centré (14x7)
        lda #13
        sta box_col
        lda #7
        sta box_row
        lda #14
        sta box_w
        lda #7
        sta box_h
        lda player_triforce_pieces
        cmp #$ff
        beq +
        lda #COL_CYAN
        bne ++
+       lda #COL_YELLOW
++      sta box_color
        jsr draw_ui_box

        ; Configuration matérielle des 8 sprites d'or centrés dans le sanctuaire
        jsr setup_p1_triforce_sprites

        ; Ligne 15 : Compteur de fragments centré
        jsr draw_p1_counter

        ; Ligne 17 : Badges des 8 donjons [1]..[8] correctement coloriés (pas de 3)
        jsr draw_p1_dungeons

        ; Ligne 19 : Statut légendaire centré
        jsr draw_p1_status
        rts

setup_p1_triforce_sprites:
        lda #COL_ORANGE                 ; Biseau d'or chaud
        sta VIC_SPRITE_MC1
        lda #COL_WHITE                  ; Arêtes lumineuses
        sta VIC_SPRITE_MC2
        lda #%11111111
        sta VIC_SPRITE_MC

        lda #(sprite_tri_p1 / 64)
        sta SPRITE_PTR0
        lda #(sprite_tri_p2 / 64)
        sta SPRITE_PTR1
        lda #(sprite_tri_p3 / 64)
        sta SPRITE_PTR2
        lda #(sprite_tri_p4 / 64)
        sta SPRITE_PTR3
        lda #(sprite_tri_p5 / 64)
        sta SPRITE_PTR4
        lda #(sprite_tri_p6 / 64)
        sta SPRITE_PTR5
        lda #(sprite_tri_p7 / 64)
        sta SPRITE_PTR6
        lda #(sprite_tri_p8 / 64)
        sta SPRITE_PTR7

        ldx #7
-       lda #COL_YELLOW
        sta VIC_SPRITE_COL0,x
        dex
        bpl -

        ; Grand triangle 48x32 centré exactement à X=184 dans cols 13..26
        lda #160
        sta VIC_SPRITE_X0
        sta VIC_SPRITE_X2
        sta VIC_SPRITE_X4
        sta VIC_SPRITE_X6

        lda #184
        sta VIC_SPRITE_X1
        sta VIC_SPRITE_X3
        sta VIC_SPRITE_X5
        sta VIC_SPRITE_X7

        ; 4 étages centrés verticalement dans le sanctuaire (lignes 8..12 : Y=114..153)
        lda #118
        sta VIC_SPRITE_Y0
        sta VIC_SPRITE_Y1
        lda #126
        sta VIC_SPRITE_Y2
        sta VIC_SPRITE_Y3
        lda #134
        sta VIC_SPRITE_Y4
        sta VIC_SPRITE_Y5
        lda #142
        sta VIC_SPRITE_Y6
        sta VIC_SPRITE_Y7

        lda player_triforce_pieces
        sta VIC_SPRITE_EN
        rts

draw_p1_counter:
        lda #0
        sta ZP_TMP
        lda player_triforce_pieces
        ldx #8
.cnt_bits:
        lsr
        bcc +
        inc ZP_TMP
+       dex
        bne .cnt_bits

        lda #'0'
        clc
        adc ZP_TMP
        sta txt_p1_counter_val

        lda #<txt_p1_counter
        sta ZP_SRC
        lda #>txt_p1_counter
        sta ZP_SRC+1
        ldx #15
        lda #COL_WHITE
        jsr inv_print_str_centered

        ; Met le chiffre en jaune vif (col 26 sur "TRIFORCE PIECES : X / 8" centré à col 8)
        lda #COL_YELLOW
        sta COLOR_RAM+600+26
        rts

draw_p1_dungeons:
        ; "DUNGEONS : [1][2][3][4][5][6][7][8]" (35 car., départ col 2 -> [1] à col 13)
        ldx #0
-       lda txt_p1_dungeons_line,x
        beq +
        sta SCREEN_RAM+680+2,x
        lda #COL_WHITE
        sta COLOR_RAM+680+2,x
        inx
        bne -
+
        ; Colorie chaque badge [1]..[8] avec pas exact de 3 colonnes (cols 13, 16, 19, ...)
        ldx #0
        ldy #13
.dung_col_loop:
        lda bit_powers,x
        and player_triforce_pieces
        beq .missing_dung
        lda #COL_YELLOW
        bne .apply_dcol
.missing_dung:
        lda #COL_DARK_GREY
.apply_dcol:
        sta COLOR_RAM+680,y
        iny
        sta COLOR_RAM+680,y
        iny
        sta COLOR_RAM+680,y
        iny
        inx
        cpx #8
        bne .dung_col_loop
        rts

draw_p1_status:
        lda player_triforce_pieces
        cmp #$ff
        beq .p1_full
        lda #<txt_p1_msg_seek
        sta ZP_SRC
        lda #>txt_p1_msg_seek
        sta ZP_SRC+1
        lda #COL_CYAN
        jmp .p1_draw
.p1_full:
        lda #<txt_p1_msg_full
        sta ZP_SRC
        lda #>txt_p1_msg_full
        sta ZP_SRC+1
        lda #COL_YELLOW
.p1_draw:
        ldx #19
        jmp inv_print_str_centered

; ===========================================================================
; PAGE 2 : ÉQUIPEMENT PERMANENT & RELIQUES (8 cartes 8x6 propres)
; ===========================================================================
draw_page_2_equipment:
        lda #0
        sta VIC_SPRITE_EXP_X
        sta VIC_SPRITE_EXP_Y
        lda #PLAYER_SKIN
        sta VIC_SPRITE_MC1
        lda #COL_WHITE
        sta VIC_SPRITE_MC2
        lda #%11111111
        sta VIC_SPRITE_MC

        ; Ligne 6 : Titre centré sous la frise dorée
        lda #<txt_p2_title
        sta ZP_SRC
        lda #>txt_p2_title
        sta ZP_SRC+1
        ldx #6
        lda #COL_YELLOW
        jsr inv_print_str_centered

        ; Trace les 8 cartes 8x6 (bordures cyan si possédé, gris sombre sinon)
        jsr draw_p2_boxes

        ; Place les 8 sprites parfaitement centrés + noms & statuts à l'intérieur des cadres
        jsr setup_p2_slots

        ; Ligne 21 : Sous-titre centré au-dessus de la frise basse
        lda #<txt_p2_tip
        sta ZP_SRC
        lda #>txt_p2_tip
        sta ZP_SRC+1
        ldx #21
        lda #COL_LIGHT_GREY
        jmp inv_print_str_centered

draw_p2_boxes:
        ldx #0
.box_p2_loop:
        txa
        pha
        lda p2_card_cols,x
        sta box_col
        lda p2_card_rows,x
        sta box_row
        lda #8
        sta box_w
        lda #6
        sta box_h
        jsr p2_is_slot_owned
        beq .p2_dim_box
        lda #COL_CYAN
        bne .p2_col_box
.p2_dim_box:
        lda #COL_DARK_GREY
.p2_col_box:
        sta box_color
        jsr draw_ui_box
        pla
        tax
        inx
        cpx #8
        bne .box_p2_loop
        rts

p2_card_cols:
        !byte 2, 11, 20, 29
        !byte 2, 11, 20, 29
p2_card_rows:
        !byte 7, 7, 7, 7
        !byte 14, 14, 14, 14

p2_is_slot_owned:
        cpx #0
        bne +
        lda player_has_sword
        rts
+       cpx #1
        bne +
        lda player_has_shield
        rts
+       cpx #2
        bne +
        lda player_has_blue_ring
        rts
+       cpx #3
        bne +
        lda player_has_bracelet
        rts
+       cpx #4
        bne +
        lda player_has_raft
        rts
+       cpx #5
        bne +
        lda player_has_stepladder
        rts
+       cpx #6
        bne +
        lda player_has_magic_key
        rts
+       lda player_has_book
        rts

setup_p2_slots:
        lda #0
        sta ZP_TMP                      ; masque VIC_SPRITE_EN

        ; Positions exactes centrées dans les 8 cartes (cols 2..9, 11..18, 20..27, 29..36)
        ; X = 24 + (colL+colR+1)*4 - 12 => 60, 132, 204, 276 (20 + MSB)
        lda #60
        sta VIC_SPRITE_X0
        sta VIC_SPRITE_X4
        lda #132
        sta VIC_SPRITE_X1
        sta VIC_SPRITE_X5
        lda #204
        sta VIC_SPRITE_X2
        sta VIC_SPRITE_X6
        lda #20
        sta VIC_SPRITE_X3
        sta VIC_SPRITE_X7

        ; Rangée 1 (lignes 7..12, zone icône lignes 8..9 -> Y=112)
        lda #112
        sta VIC_SPRITE_Y0
        sta VIC_SPRITE_Y1
        sta VIC_SPRITE_Y2
        sta VIC_SPRITE_Y3

        ; Rangée 2 (lignes 14..19, zone icône lignes 15..16 -> Y=168)
        lda #168
        sta VIC_SPRITE_Y4
        sta VIC_SPRITE_Y5
        sta VIC_SPRITE_Y6
        sta VIC_SPRITE_Y7

        lda #%10001000
        sta VIC_SPRITE_MSB

        ; Affiche les 8 noms centrés (Ligne 10 et Ligne 17, 6 car. intérieurs)
        lda #<txt_all_slot_names
        sta ZP_SRC
        lda #>txt_all_slot_names
        sta ZP_SRC+1

        ldx #0
.p2_name_loop:
        lda p2_name_offs_lo,x
        sta ZP_SCR
        sta ZP_COL
        lda p2_name_offs_hi,x
        jsr inv_set_scr_col_hi

        ldy #5
-       lda (ZP_SRC),y
        sta (ZP_SCR),y
        lda #COL_WHITE
        sta (ZP_COL),y
        dey
        bpl -

        clc
        lda ZP_SRC
        adc #6
        sta ZP_SRC
        lda ZP_SRC+1
        adc #0
        sta ZP_SRC+1

        inx
        cpx #8
        bne .p2_name_loop

        ; --- Slot 0 : Épée ---
        ldx #0
        jsr p2_set_slot_ptr
        lda player_has_sword
        bne .p2_has_sword
        jsr p2_slot_empty
        jmp .p2_slot1

.p2_has_sword:
        lda ZP_TMP
        ora #%00000001
        sta ZP_TMP
        lda #(sprite_link_item_sword / 64)
        sta SPRITE_PTR0
        ldx player_has_sword
        lda p2_sword_colors,x
        sta VIC_SPRITE_COL0

        dex
        txa
        asl
        sta .p2_tmp_val
        asl
        clc
        adc .p2_tmp_val
        clc
        adc #<p2_sword_status
        sta ZP_SRC
        lda #>p2_sword_status
        adc #0
        sta ZP_SRC+1
        lda #COL_YELLOW
        jsr p2_print_status

.p2_slot1:
        ; --- Slot 1 : Bouclier ---
        ldx #1
        jsr p2_set_slot_ptr
        lda player_has_shield
        bne .p2_has_shield
        jsr p2_slot_empty
        jmp .p2_slot2

.p2_has_shield:
        lda ZP_TMP
        ora #%00000010
        sta ZP_TMP
        lda #(sprite_link_item_shield / 64)
        sta SPRITE_PTR1
        lda player_has_shield
        cmp #2
        bcs .p2_shield_mag
        lda #COL_BROWN
        sta VIC_SPRITE_COL1
        lda #<p2_shield_status
        sta ZP_SRC
        lda #>p2_shield_status
        sta ZP_SRC+1
        jmp .p2_shield_draw
.p2_shield_mag:
        lda #COL_LIGHT_RED
        sta VIC_SPRITE_COL1
        lda #<(p2_shield_status+6)
        sta ZP_SRC
        lda #>(p2_shield_status+6)
        sta ZP_SRC+1
.p2_shield_draw:
        lda #COL_YELLOW
        jsr p2_print_status

.p2_slot2:
        ; --- Slot 2 : Anneau ---
        ldx #2
        jsr p2_set_slot_ptr
        lda player_has_blue_ring
        bne .p2_has_ring
        jsr p2_slot_empty
        jmp .p2_slots_simple

.p2_has_ring:
        lda ZP_TMP
        ora #%00000100
        sta ZP_TMP
        lda #(sprite_link_item_ring / 64)
        sta SPRITE_PTR2
        lda player_has_blue_ring
        cmp #2
        bcs .p2_ring_red
        lda #COL_CYAN
        sta VIC_SPRITE_COL2
        lda #<p2_ring_status
        sta ZP_SRC
        lda #>p2_ring_status
        sta ZP_SRC+1
        jmp .p2_ring_draw
.p2_ring_red:
        lda #COL_LIGHT_RED
        sta VIC_SPRITE_COL2
        lda #<(p2_ring_status+6)
        sta ZP_SRC
        lda #>(p2_ring_status+6)
        sta ZP_SRC+1
.p2_ring_draw:
        lda #COL_YELLOW
        jsr p2_print_status

.p2_slots_simple:
        ldx #0
.p2_simp_loop:
        stx .p2_cur_idx
        txa
        clc
        adc #3
        tax
        jsr p2_set_slot_ptr

        ldx .p2_cur_idx
        lda p2_simp_flags_lo,x
        sta ZP_SRC
        lda p2_simp_flags_hi,x
        sta ZP_SRC+1
        ldy #0
        lda (ZP_SRC),y
        bne .p2_simp_has

        jsr p2_slot_empty
        jmp .p2_simp_next

.p2_simp_has:
        ldx .p2_cur_idx
        lda p2_simple_mask,x
        ora ZP_TMP
        sta ZP_TMP

        txa
        clc
        adc #3
        tay
        lda p2_simple_spr,x
        sta SPRITE_PTR0,y
        lda p2_simple_col,x
        sta VIC_SPRITE_COL0,y

        lda #<txt_p2_acquired
        sta ZP_SRC
        lda #>txt_p2_acquired
        sta ZP_SRC+1
        lda #COL_YELLOW
        jsr p2_print_status

.p2_simp_next:
        ldx .p2_cur_idx
        inx
        cpx #5
        bne .p2_simp_loop

        lda ZP_TMP
        sta VIC_SPRITE_EN
        rts

.p2_cur_idx:  !byte 0
.p2_tmp_val:  !byte 0

p2_set_slot_ptr:
        lda p2_stat_offs_lo,x
        sta ZP_SCR
        sta ZP_COL
        lda p2_stat_offs_hi,x
        jmp inv_set_scr_col_hi

p2_slot_empty:
        lda #<txt_p2_empty
        sta ZP_SRC
        lda #>txt_p2_empty
        sta ZP_SRC+1
        lda #COL_DARK_GREY
        jmp p2_print_status

p2_print_status:
        sta .p2_color_tmp
        ldy #5
-       lda (ZP_SRC),y
        sta (ZP_SCR),y
        lda .p2_color_tmp
        sta (ZP_COL),y
        dey
        bpl -
        rts
.p2_color_tmp: !byte 0

p2_simp_flags_lo:
        !byte <player_has_bracelet, <player_has_raft, <player_has_stepladder, <player_has_magic_key, <player_has_book
p2_simp_flags_hi:
        !byte >player_has_bracelet, >player_has_raft, >player_has_stepladder, >player_has_magic_key, >player_has_book
p2_simple_mask:
        !byte %00001000, %00010000, %00100000, %01000000, %10000000
p2_simple_spr:
        !byte (sprite_link_item_bracelet / 64)
        !byte (sprite_link_item_raft / 64)
        !byte (sprite_link_item_stepladder / 64)
        !byte (sprite_link_item_magic_key / 64)
        !byte (sprite_link_item_book / 64)
p2_simple_col:
        !byte COL_YELLOW, COL_BROWN, COL_BROWN, COL_YELLOW, COL_LIGHT_BLUE

; Lignes intérieures 10 (+400) & 17 (+680) pour les noms, 11 (+440) & 18 (+720) pour les statuts
; (bordures basses en lignes 12 & 19 totalement préservées !)
p2_name_offs_lo:
        !byte <(400+3), <(400+12), <(400+21), <(400+30)
        !byte <(680+3), <(680+12), <(680+21), <(680+30)
p2_name_offs_hi:
        !byte >(400+3), >(400+12), >(400+21), >(400+30)
        !byte >(680+3), >(680+12), >(680+21), >(680+30)

p2_stat_offs_lo:
        !byte <(440+3), <(440+12), <(440+21), <(440+30)
        !byte <(720+3), <(720+12), <(720+21), <(720+30)
p2_stat_offs_hi:
        !byte >(440+3), >(440+12), >(440+21), >(440+30)
        !byte >(720+3), >(720+12), >(720+21), >(720+30)

p2_sword_colors:    !byte COL_DARK_GREY, COL_BROWN, COL_WHITE, COL_CYAN
p2_sword_status:    !text " WOOD  WHITE MAGIC"
p2_shield_status:   !text " SMALL MAGIC"
p2_ring_status:     !text " BLUE   RED "

txt_all_slot_names: !text " SWORDSHIELD RING  POWER RAFT LADDER M.KEY BOOK "
txt_p2_empty:       !text " ---- "
txt_p2_acquired:    !text " OWNED"

; ===========================================================================
; PAGE 3 : CARTE DU MONDE OU DU DONJON (Encadrement épuré)
; ===========================================================================
draw_page_3_map:
        lda #0
        sta VIC_SPRITE_EN
        sta VIC_SPRITE_MSB
        sta VIC_SPRITE_EXP_X
        sta VIC_SPRITE_EXP_Y

        lda current_world_type
        cmp #WORLD_DUNGEON
        bne +
        jmp draw_page_3_dungeon_map
+
        ; --- OVERWORLD MAP (16x8) ---
        ; Ligne 6 : Colonnes A..P sous la frise dorée intacte de la Ligne 5
        ldx #0
        ldy #0
.put_col_letters:
        txa
        clc
        adc #'A'
        sta SCREEN_RAM+240+4,y
        lda #' '
        sta SCREEN_RAM+240+5,y
        lda #COL_YELLOW
        sta COLOR_RAM+240+4,y
        sta COLOR_RAM+240+5,y
        iny
        iny
        inx
        cpx #16
        bne .put_col_letters

        ; Cadre de carte (Cols 2..37, Lignes 7..16 -> 36x10)
        lda #2
        sta box_col
        lda #7
        sta box_row
        lda #36
        sta box_w
        lda #10
        sta box_h
        lda #COL_CYAN
        sta box_color
        jsr draw_ui_box

        ; Lignes 8..15 : 8 rangées de salles
        lda #0
        sta map_ry
.row_loop:
        ldx map_ry
        lda map_row_scr_lo,x
        sta ZP_SCR
        lda map_row_scr_hi,x
        sta ZP_SCR+1
        lda map_row_scr_lo,x
        sta ZP_COL
        lda map_row_col_hi,x
        sta ZP_COL+1

        ; Chiffre de ligne 1..8 (col 0)
        txa
        clc
        adc #'1'
        ldy #0
        sta (ZP_SCR),y
        lda #COL_YELLOW
        sta (ZP_COL),y

        lda #0
        sta map_rx
.col_loop:
        ldx map_ry
        lda world_row_offset,x
        clc
        adc map_rx
        tax

        lda ow_room_biome_colors,x
        sta ZP_BASE

        lda map_rx
        cmp current_room_x
        bne .check_visited
        lda map_ry
        cmp current_room_y
        bne .check_visited

        lda #HUD_MAP_ACTIVE
        sta ZP_TMP
        lda map_link_color
        sta ZP_BASE
        jmp .render_cell

.check_visited:
        lda visited_rooms,x
        beq .cell_unseen

        lda #HUD_MAP_ACTIVE
        sta ZP_TMP
        jmp .render_cell

.cell_unseen:
        lda #HUD_MAP_EMPTY
        sta ZP_TMP
        lda #COL_DARK_GREY
        sta ZP_BASE

.render_cell:
        lda map_rx
        asl
        clc
        adc #4
        tay
        lda ZP_TMP
        sta (ZP_SCR),y
        lda ZP_BASE
        sta (ZP_COL),y
        iny
        lda #' '
        sta (ZP_SCR),y
        lda #COL_BLACK
        sta (ZP_COL),y

        inc map_rx
        lda map_rx
        cmp #16
        bne .col_loop

        inc map_ry
        lda map_ry
        cmp #8
        beq +
        jmp .row_loop
+
        ; Ligne 18 : Coordonnées & progression centrées
        ldx #0
-       lda txt_room_line,x
        sta SCREEN_RAM+720+2,x
        lda #COL_WHITE
        sta COLOR_RAM+720+2,x
        inx
        cpx #36
        bne -

        lda #'A'
        clc
        adc current_room_x
        sta SCREEN_RAM+720+13
        lda #'1'
        clc
        adc current_room_y
        sta SCREEN_RAM+720+15
        lda #COL_YELLOW
        sta COLOR_RAM+720+13
        sta COLOR_RAM+720+14
        sta COLOR_RAM+720+15

        jsr calc_visited_count
        lda visited_count
        cmp #100
        bcc .under100
        sec
        sbc #100
        jsr print_2digits
        sta ZP_TMP
        stx ZP_TCOL
        lda #'1'
        jmp .write_vis
.under100:
        jsr print_2digits
        sta ZP_TMP
        stx ZP_TCOL
        lda #' '
.write_vis:
        sta SCREEN_RAM+720+31
        lda ZP_TMP
        sta SCREEN_RAM+720+32
        lda ZP_TCOL
        sta SCREEN_RAM+720+33
        lda #COL_YELLOW
        sta COLOR_RAM+720+31
        sta COLOR_RAM+720+32
        sta COLOR_RAM+720+33

        ; Lignes 20..21 : Légende des 6 biomes
        ldx #0
-       lda txt_legend_b1,x
        sta SCREEN_RAM+800+2,x
        lda #COL_LIGHT_GREY
        sta COLOR_RAM+800+2,x
        lda txt_legend_b2,x
        sta SCREEN_RAM+840+2,x
        lda #COL_LIGHT_GREY
        sta COLOR_RAM+840+2,x
        inx
        cpx #36
        bne -

        lda #HUD_MAP_ACTIVE
        sta SCREEN_RAM+800+11
        sta SCREEN_RAM+800+20
        sta SCREEN_RAM+800+30
        lda #COL_LIGHT_BLUE
        sta COLOR_RAM+800+11
        lda #COL_GREEN
        sta COLOR_RAM+800+20
        lda #COL_BROWN
        sta COLOR_RAM+800+30

        lda #HUD_MAP_ACTIVE
        sta SCREEN_RAM+840+11
        sta SCREEN_RAM+840+20
        sta SCREEN_RAM+840+30
        lda #COL_YELLOW
        sta COLOR_RAM+840+11
        lda #COL_DARK_GREY
        sta COLOR_RAM+840+20
        lda #COL_LIGHT_GREEN
        sta COLOR_RAM+840+30
        rts

; ---------------------------------------------------------------------------
; draw_page_3_dungeon_map : carte officielle du donjon actif (8x8 encadrée)
; ---------------------------------------------------------------------------
draw_page_3_dungeon_map:
        ; Ligne 6 : "LEVEL X : <NOM>" sous la frise dorée intacte
        lda #'0'
        clc
        adc current_dungeon_level
        sta txt_dtitle_pref+6

        ldy #0
-       lda txt_dtitle_pref,y
        beq +
        sta SCREEN_RAM+240+12,y
        lda #COL_YELLOW
        sta COLOR_RAM+240+12,y
        iny
        bne -
+
        ldx current_dungeon_level
        dex
        cpx #9
        bcc +
        ldx #0
+       lda p3_dung_names_lo,x
        sta ZP_SRC
        lda p3_dung_names_hi,x
        sta ZP_SRC+1

        ldy #0
-       lda (ZP_SRC),y
        beq +
        sta SCREEN_RAM+240+22,y
        lda #COL_WHITE
        sta COLOR_RAM+240+22,y
        iny
        bne -
+
        ; Cadre centré 8x8 (Cols 11..28, Lignes 7..16 -> 18x10)
        lda #11
        sta box_col
        lda #7
        sta box_row
        lda #18
        sta box_w
        lda #10
        sta box_h
        lda #COL_CYAN
        sta box_color
        jsr draw_ui_box

        lda #0
        sta map_ry
.d_row_loop:
        ldx map_ry
        lda map_row_scr_lo,x
        sta ZP_SCR
        lda map_row_scr_hi,x
        sta ZP_SCR+1
        lda map_row_scr_lo,x
        sta ZP_COL
        lda map_row_col_hi,x
        sta ZP_COL+1

        lda #0
        sta map_rx
.d_col_loop:
        ldy current_dungeon_level
        dey
        cpy #9
        bcc +
        ldy #0
+       lda dung_bank_x,y
        clc
        adc map_rx
        sta ZP_TMP

        lda map_ry
        asl
        asl
        asl
        asl
        clc
        adc ZP_TMP
        tax

        ; Détection rigoureuse 16-bit des salles scellées ($C012..$C013)
        lda $c016,x
        cmp $c012
        bne .d_room_check_vis
        lda $c096,x
        cmp $c013
        beq .d_no_room

.d_room_check_vis:
        lda player_has_dungeon_map
        bne .d_room_revealed
        lda visited_uw_rooms,x
        bne .d_room_revealed

.d_no_room:
        lda #32
        sta ZP_TMP
        lda #COL_BLACK
        sta ZP_BASE
        jmp .d_put_cell

.d_room_revealed:
        lda map_ry
        cmp current_room_y
        bne +
        lda map_rx
        ldy current_dungeon_level
        dey
        cpy #9
        bcc ++
        ldy #0
++      clc
        adc dung_bank_x,y
        cmp current_room_x
        bne +
        lda #HUD_MAP_ACTIVE
        sta ZP_TMP
        lda map_link_color
        sta ZP_BASE
        jmp .d_put_cell
+
        lda player_has_compass
        beq .d_regular_room
        ldy current_dungeon_level
        dey
        cpy #9
        bcc +++
        ldy #0
+++     txa
        cmp dungeon_tri_rooms,y
        bne .check_room_secret
        lda #HUD_MAP_ACTIVE
        sta ZP_TMP
        lda #COL_LIGHT_RED
        sta ZP_BASE
        jmp .d_put_cell

.check_room_secret:
        txa
        ldy current_room_idx
        sty inv_saved_rid
        sta current_room_idx
        jsr dungeon_get_room_drop_type
        ldy inv_saved_rid
        sty current_room_idx
        cmp #DROP_NONE
        beq .chk_cellar_sec
        lda dungeon_room_state,x
        and #DUNG_ITEM_COLLECTED
        beq .has_secret_gem
        jmp .d_regular_room

.chk_cellar_sec:
        ldy #8
-       txa
        cmp d_cellar_rooms,y
        beq .test_cellar_collected
        dey
        bpl -
        lda current_dungeon_level
        cmp #1
        bne .d_regular_room
        cpx #$42
        bne .d_regular_room
        lda dungeon_room_state,x
        and #DUNG_SECRET_REVEALED
        beq .has_secret_gem
        jmp .d_regular_room

.test_cellar_collected:
        lda dungeon_room_state,x
        and #(DUNG_ITEM_COLLECTED | DUNG_SECRET_REVEALED)
        cmp #(DUNG_ITEM_COLLECTED | DUNG_SECRET_REVEALED)
        bne .has_secret_gem
        jmp .d_regular_room

.has_secret_gem:
        lda #HUD_CHAR_RUPEE
        sta ZP_TMP
        lda #COL_YELLOW
        sta ZP_BASE
        jmp .d_put_cell

.d_regular_room:
        lda #HUD_MAP_VISITED
        sta ZP_TMP
        lda #COL_CYAN
        sta ZP_BASE

.d_put_cell:
        lda map_rx
        asl
        clc
        adc #12
        tay
        lda ZP_TMP
        sta (ZP_SCR),y
        lda ZP_BASE
        sta (ZP_COL),y
        iny
        lda #32
        sta (ZP_SCR),y
        lda #COL_BLACK
        sta (ZP_COL),y

        inc map_rx
        lda map_rx
        cmp #8
        beq +
        jmp .d_col_loop
+
        inc map_ry
        lda map_ry
        cmp #8
        beq +
        jmp .d_row_loop
+
        ; Ligne 18 : Légende du donjon centrée (23 car. -> col 8)
        ldx #0
-       lda txt_dung_legend,x
        beq +
        sta SCREEN_RAM+720+8,x
        lda txt_dung_leg_col,x
        sta COLOR_RAM+720+8,x
        inx
        bne -
+
        ; Ligne 20 : Badges MAP & COMPASS
        ldx #0
-       lda txt_dung_gear,x
        beq +
        sta SCREEN_RAM+800+6,x
        lda #COL_DARK_GREY
        sta COLOR_RAM+800+6,x
        inx
        bne -
+       lda player_has_dungeon_map
        beq .chk_cmp_badge
        ldx #0
-       lda #COL_YELLOW
        sta COLOR_RAM+800+6,x
        inx
        cpx #8
        bne -
.chk_cmp_badge:
        lda player_has_compass
        beq .done_dmap
        ldx #0
-       lda #COL_LIGHT_RED
        sta COLOR_RAM+800+20,x
        inx
        cpx #12
        bne -
.done_dmap:
        rts

dung_bank_x:
        !byte 0, 8, 8, 0, 0, 8, 8, 8, 0

dungeon_tri_rooms:
        !byte $36, $0d, $3d, $03, $14, $0c, $2b, $2c, $32

inv_saved_rid:
        !byte 0
d_cellar_rooms:
        !byte $22, $6a, $32, $36, $08, $4a, $6f, $23, $45

p3_dung_names_lo:
        !byte <p3_d1, <p3_d2, <p3_d3, <p3_d4, <p3_d5, <p3_d6, <p3_d7, <p3_d8, <p3_d9
p3_dung_names_hi:
        !byte >p3_d1, >p3_d2, >p3_d3, >p3_d4, >p3_d5, >p3_d6, >p3_d7, >p3_d8, >p3_d9

txt_dtitle_pref:    !text "LEVEL 1 : ", 0
p3_d1:  !text "EAGLE", 0
p3_d2:  !text "MOON", 0
p3_d3:  !text "MANJI", 0
p3_d4:  !text "SNAKE", 0
p3_d5:  !text "LIZARD", 0
p3_d6:  !text "DRAGON", 0
p3_d7:  !text "DEMON", 0
p3_d8:  !text "LION", 0
p3_d9:  !text "DEATH MOUNTAIN", 0

txt_dung_legend:
        !byte HUD_CHAR_RUPEE
        !text " SECRET   "
        !byte HUD_MAP_ACTIVE
        !text " TRI   "
        !byte HUD_MAP_ACTIVE
        !text " LINK", 0

txt_dung_leg_col:
        !byte COL_YELLOW
        !fill 10, COL_WHITE
        !byte COL_LIGHT_RED
        !fill 7, COL_WHITE
        !byte COL_YELLOW
        !fill 5, COL_WHITE
        !byte 0

txt_dung_gear:
        !text "[MAP OK]      [COMPASS OK]", 0

calc_visited_count:
        lda #0
        sta visited_count
        ldx #0
.count_loop:
        lda visited_rooms,x
        beq +
        inc visited_count
+       inx
        cpx #128
        bne .count_loop
        rts

; ===========================================================================
; TABLE DES VRAIES COULEURS DE BIOMES DE L'OVERWORLD (128 SALLES)
; ===========================================================================
ow_room_biome_colors:
        ; Rangée 1 (A-1 à P-1)
        !byte COL_BROWN, COL_BROWN, COL_BROWN, COL_BROWN, COL_BROWN, COL_BROWN, COL_BROWN, COL_BROWN
        !byte COL_BROWN, COL_BROWN, COL_LIGHT_BLUE, COL_BROWN, COL_BROWN, COL_BROWN, COL_LIGHT_BLUE, COL_LIGHT_BLUE
        ; Rangée 2 (A-2 à P-2)
        !byte COL_BROWN, COL_BROWN, COL_BROWN, COL_BROWN, COL_BROWN, COL_BROWN, COL_BROWN, COL_BROWN
        !byte COL_BROWN, COL_BROWN, COL_BROWN, COL_BROWN, COL_BROWN, COL_BROWN, COL_LIGHT_BLUE, COL_BROWN
        ; Rangée 3 (A-3 à P-3)
        !byte COL_DARK_GREY, COL_DARK_GREY, COL_BROWN, COL_BROWN, COL_LIGHT_GREEN, COL_LIGHT_GREEN, COL_LIGHT_BLUE, COL_LIGHT_BLUE
        !byte COL_LIGHT_BLUE, COL_YELLOW, COL_YELLOW, COL_YELLOW, COL_BROWN, COL_LIGHT_BLUE, COL_LIGHT_BLUE, COL_BROWN
        ; Rangée 4 (A-4 à P-4)
        !byte COL_DARK_GREY, COL_DARK_GREY, COL_BROWN, COL_BROWN, COL_LIGHT_BLUE, COL_LIGHT_BLUE, COL_LIGHT_BLUE, COL_LIGHT_BLUE
        !byte COL_LIGHT_BLUE, COL_LIGHT_BLUE, COL_YELLOW, COL_YELLOW, COL_BROWN, COL_GREEN, COL_LIGHT_BLUE, COL_LIGHT_BLUE
        ; Rangée 5 (A-5 à P-5)
        !byte COL_DARK_GREY, COL_DARK_GREY, COL_LIGHT_BLUE, COL_LIGHT_BLUE, COL_LIGHT_BLUE, COL_LIGHT_BLUE, COL_LIGHT_BLUE, COL_LIGHT_BLUE
        !byte COL_LIGHT_BLUE, COL_GREEN, COL_LIGHT_GREEN, COL_GREEN, COL_BROWN, COL_GREEN, COL_GREEN, COL_LIGHT_BLUE
        ; Rangée 6 (A-6 à P-6)
        !byte COL_BROWN, COL_GREEN, COL_GREEN, COL_GREEN, COL_LIGHT_BLUE, COL_LIGHT_BLUE, COL_LIGHT_BLUE, COL_GREEN
        !byte COL_GREEN, COL_GREEN, COL_LIGHT_BLUE, COL_GREEN, COL_GREEN, COL_GREEN, COL_BROWN, COL_LIGHT_BLUE
        ; Rangée 7 (A-7 à P-7)
        !byte COL_GREEN, COL_GREEN, COL_GREEN, COL_GREEN, COL_LIGHT_GREEN, COL_LIGHT_BLUE, COL_BROWN, COL_BROWN
        !byte COL_GREEN, COL_LIGHT_BLUE, COL_LIGHT_BLUE, COL_GREEN, COL_GREEN, COL_GREEN, COL_GREEN, COL_LIGHT_BLUE
        ; Rangée 8 (A-8 à P-8)
        !byte COL_BROWN, COL_LIGHT_GREEN, COL_GREEN, COL_GREEN, COL_BROWN, COL_LIGHT_BLUE, COL_LIGHT_GREEN, COL_BROWN
        !byte COL_GREEN, COL_BROWN, COL_BROWN, COL_LIGHT_BLUE, COL_LIGHT_BLUE, COL_LIGHT_BLUE, COL_LIGHT_BLUE, COL_LIGHT_BLUE

; ===========================================================================
; TEXTES DU MENU D'INVENTAIRE (40 colonnes symétriques)
; ===========================================================================
; Cols:  0123456789012345678901234567890123456789
txt_tabs_base:      !text "  1:ITEMS   2:TRIFORCE  3:EQUIP  4:MAP  "
tab_bracket_pos:    !byte 1, 9,  11, 22,  23, 31,  32, 38
tab_start:          !byte 1, 11, 23, 32
tab_end:            !byte 10, 23, 32, 39

txt_footer_help:    !text " [JOY] MOVE  [A] EQUIP  [1-4] TAB [B] OK"

; Page 0
txt_p0_b_hdr:       !text "[A] ITEM"
txt_p0_grid_hdr:    !text "SELECT WEAPON"
txt_p0_relics_lbl:  !text "RELICS :"

p0_desc_lo:
        !byte <desc_boom, <desc_bomb, <desc_bow, <desc_cand, <desc_whistle, <desc_food, <desc_potion, <desc_wand
p0_desc_hi:
        !byte >desc_boom, >desc_bomb, >desc_bow, >desc_cand, >desc_whistle, >desc_food, >desc_potion, >desc_wand

p0_sub_lo:
        !byte <sub_boom, <sub_bomb, <sub_bow, <sub_cand, <sub_whistle, <sub_food, <sub_potion, <sub_wand
p0_sub_hi:
        !byte >sub_boom, >sub_bomb, >sub_bow, >sub_cand, >sub_whistle, >sub_food, >sub_potion, >sub_wand

desc_boom:          !text "BOOMERANG", 0
desc_bomb:          !text "BOMBS", 0
desc_bow:           !text "BOW AND ARROWS", 0
desc_cand:          !text "CANDLE", 0
desc_whistle:       !text "RECORDER", 0
desc_food:          !text "MONSTER BAIT", 0
desc_potion:        !text "LIFE POTION", 0
desc_wand:          !text "MAGICAL ROD", 0

sub_boom:           !text "STUNS FOES AND FETCHES ITEMS", 0
sub_bomb:           !text "BLASTS CRACKED WALLS AND ENEMIES", 0
sub_bow:            !text "FIRES ARROWS USING RUPEES", 0
sub_cand:           !text "LIGHTS DARKNESS AND BURNS BUSHES", 0
sub_whistle:        !text "PLAYS A TUNE TO WARP OR DRAIN", 0
sub_food:           !text "LURES HUNGRY FOES IN DUNGEONS", 0
sub_potion:         !text "RESTORES ALL LOST HEARTS", 0
sub_wand:           !text "CASTS POWERFUL MAGIC WAVES", 0

; Page 1 (Triforce)
txt_p1_title:       !text "THE TRIFORCE OF WISDOM", 0
txt_p1_counter:     !text "TRIFORCE PIECES : "
txt_p1_counter_val: !text "0 / 8", 0
txt_p1_dungeons_line: !text "DUNGEONS : [1][2][3][4][5][6][7][8]", 0
txt_p1_msg_seek:    !text "FIND ALL 8 TRIFORCE FRAGMENTS!", 0
txt_p1_msg_full:    !text "THE TRIFORCE OF WISDOM IS COMPLETE!", 0

; Page 2 (Équipement)
txt_p2_title:       !text "EQUIPMENT & RELICS", 0
txt_p2_tip:         !text "PERMANENT ARSENAL & PASSIVE RELICS", 0

; Page 3 (Carte du Monde)
txt_room_line:      !text "LOCATION : A-1    EXPLORED :   0/128"
txt_legend_b1:      !text "BIOMES :   WATER    FOREST    ROCK  "
txt_legend_b2:      !text "           DESERT   GRAVE     PLAIN "
