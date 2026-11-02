; ---------------------------------------------------------------------------
; inventory_draw.asm : Affichage graphique du menu d'inventaire en 4 pages
;   Page 0 : [1:ITEMS]     - Sélection Slot B (8 armes, descriptif, stock)
;   Page 1 : [2:TRIFORCE]  - La Triforce de la Sagesse (8 fragments assemblés)
;   Page 2 : [3:EQUIP]     - Équipement permanent (Épées, Boucliers, Anneau, Reliques)
;   Page 3 : [4:MAP]       - Carte du Monde 16x8 (Biomes réels, Link clignotant)
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

; Tables des sprites et couleurs des 8 armes sélectionnables (Slot B)
item_sprite_ptrs:
        !byte (sprite_link_item_boomerang / 64)
        !byte (sprite_link_item_bomb / 64)
        !byte (sprite_link_item_bow / 64)
        !byte (sprite_link_item_candle / 64)
        !byte (sprite_link_item_whistle / 64)
        !byte (sprite_link_item_food / 64)
        !byte (sprite_link_item_potion / 64)
        !byte (sprite_link_item_wand / 64)

item_colors:
        !byte COL_LIGHT_BLUE            ; 0: Boomerang
        !byte COL_BLUE                  ; 1: Bombe
        !byte COL_WHITE                 ; 2: Arc & Flèche
        !byte COL_LIGHT_BLUE            ; 3: Bougie
        !byte COL_YELLOW                ; 4: Flûte / Recorder
        !byte COL_BROWN                 ; 5: Viande / Appât
        !byte COL_RED                   ; 6: Potion
        !byte COL_LIGHT_BLUE            ; 7: Baguette Magique

; Coordonnées X des 8 objets dans la boîte (Cols 13..31, X=140, 172, 204, 236)
cursor_x_coords:
        !byte 140, 172, 204, 236        ; rangée 1 : Boomerang, Bombe, Arc, Bougie
        !byte 140, 172, 204, 236        ; rangée 2 : Flûte, Viande, Potion, Baguette

cursor_y_coords:
        !byte 118, 118, 118, 118        ; rangée 1 (Y=118)
        !byte 142, 142, 142, 142        ; rangée 2 (Y=142)

flash_colors:
        !byte COL_YELLOW, COL_LIGHT_RED, COL_WHITE, COL_ORANGE

map_row_scr_lo:
        !byte $18, $40, $68, $90, $b8, $e0, $08, $30
map_row_scr_hi:
        !byte $05, $05, $05, $05, $05, $05, $06, $06
map_row_col_hi:
        !byte $d9, $d9, $d9, $d9, $d9, $d9, $da, $da

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
; draw_tab_header : trace l'en-tête commun à onglets sur les lignes 4 et 5
; ---------------------------------------------------------------------------
draw_tab_header:
        ldx #39
-       lda txt_tabs_base,x
        sta SCREEN_RAM+160,x
        lda #COL_CYAN
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

        ; Colorie l'onglet actif en jaune étincelant
        jsr highlight_active_tab

        ; Ligne 5 : Frise héroïque supérieure (40 colonnes)
        ldx #0
-       lda #CHAR_HERO_TOP
        sta SCREEN_RAM+200,x
        lda #COL_BLUE
        sta COLOR_RAM+200,x
        inx
        cpx #40
        bne -

        ; Ligne 23 : Guide de navigation commun (40 colonnes)
        ldx #0
-       lda txt_footer_help,x
        sta SCREEN_RAM+920,x
        lda #COL_LIGHT_GREEN
        sta COLOR_RAM+920,x
        inx
        cpx #40
        bne -
        rts

highlight_active_tab:
        ldy inv_page
        ldx tab_start,y
-       lda #COL_YELLOW
        sta COLOR_RAM+160,x
        inx
        txa
        cmp tab_end,y
        bne -
        rts

; ===========================================================================
; PAGE 0 : OBJETS ACTIFS DU SLOT B & RELIQUES PASSIVES
; ===========================================================================
draw_page_0_items:
        ; 1. Boîte Arme équipée (Cols 2..10, Lignes 7..12)
        lda #CHAR_HERO_TL
        sta SCREEN_RAM+280+2
        lda #CHAR_HERO_TR
        sta SCREEN_RAM+280+10
        lda #CHAR_HERO_BL
        sta SCREEN_RAM+480+2
        lda #CHAR_HERO_BR
        sta SCREEN_RAM+480+10
        ldx #6
-       lda #CHAR_HERO_TOP
        sta SCREEN_RAM+280+2+1,x
        lda #CHAR_HERO_BOT
        sta SCREEN_RAM+480+2+1,x
        lda #COL_CYAN
        sta COLOR_RAM+280+2,x
        sta COLOR_RAM+480+2,x
        dex
        bpl -
        lda #COL_CYAN
        sta COLOR_RAM+280+10
        sta COLOR_RAM+480+10

        ; Bordures verticales pour la boîte équipée (Lignes 8..11)
        ldx #0
.v_p0_eq:
        lda p0_eq_v_lo,x
        sta ZP_SCR
        sta ZP_COL
        lda p0_eq_v_hi,x
        jsr inv_set_scr_col_hi

        lda #CHAR_HERO_VERT
        ldy #2
        sta (ZP_SCR),y
        ldy #10
        sta (ZP_SCR),y
        lda #COL_CYAN
        ldy #2
        sta (ZP_COL),y
        ldy #10
        sta (ZP_COL),y
        inx
        cpx #4
        bne .v_p0_eq

        ; 2. Boîte des 8 Armes sélectionnables (Cols 13..31, Lignes 8..15)
        lda #CHAR_HERO_TL
        sta SCREEN_RAM+320+13
        lda #CHAR_HERO_TR
        sta SCREEN_RAM+320+31
        lda #CHAR_HERO_BL
        sta SCREEN_RAM+600+13
        lda #CHAR_HERO_BR
        sta SCREEN_RAM+600+31

        ldx #16
-       lda #CHAR_HERO_TOP
        sta SCREEN_RAM+320+13+1,x
        lda #CHAR_HERO_BOT
        sta SCREEN_RAM+600+13+1,x
        lda #COL_CYAN
        sta COLOR_RAM+320+13,x
        sta COLOR_RAM+600+13,x
        dex
        bpl -
        lda #COL_CYAN
        sta COLOR_RAM+320+31
        sta COLOR_RAM+600+31

        ; Bordures verticales pour la boîte de l'arsenal (Lignes 9..14)
        ldx #0
.v_p0_ars:
        lda p0_ars_v_lo,x
        sta ZP_SCR
        sta ZP_COL
        lda p0_ars_v_hi,x
        jsr inv_set_scr_col_hi

        lda #CHAR_HERO_VERT
        ldy #13
        sta (ZP_SCR),y
        ldy #31
        sta (ZP_SCR),y
        lda #COL_CYAN
        ldy #13
        sta (ZP_COL),y
        ldy #31
        sta (ZP_COL),y
        inx
        cpx #6
        bne .v_p0_ars

        ; En-tête Ligne 5 : INVENTORY à gauche, PASSIVE RELICS à droite
        ldx #8
-       lda txt_p0_inv_hdr,x
        sta SCREEN_RAM+200+2,x
        lda #COL_YELLOW
        sta COLOR_RAM+200+2,x
        dex
        bpl -

        ldx #13
-       lda txt_p0_relics_hdr,x
        sta SCREEN_RAM+200+16,x
        lda #COL_YELLOW
        sta COLOR_RAM+200+16,x
        dex
        bpl -

        ; Ligne 6 : Affichage des 6 reliques passives
        jsr draw_p0_passive_relics

        ; Instructions B Button sous le cadre équipé (Lignes 13 et 14)
        ldx #11
-       lda txt_p0_use_b,x
        sta SCREEN_RAM+520+1,x
        lda #COL_CYAN
        sta COLOR_RAM+520+1,x
        dex
        bpl -

        ldx #9
-       lda txt_p0_for_this,x
        sta SCREEN_RAM+560+2,x
        lda #COL_CYAN
        sta COLOR_RAM+560+2,x
        dex
        bpl -

        ; Ligne 17 : Description de l'arme sélectionnée
        jsr draw_p0_description

        ; Ligne 19 : Compteurs d'inventaire
        jsr draw_p0_stock

        ; Ligne 21 : Astuce d'équipement
        ldx #0
-       lda txt_p0_tip,x
        sta SCREEN_RAM+840+2,x
        lda #COL_YELLOW
        sta COLOR_RAM+840+2,x
        inx
        cpx #36
        bne -

        ; Configure tous les sprites matériels
        jsr setup_p0_sprites
        rts

draw_p0_passive_relics:
        ; Radeau (Col 14)
        lda #120                        ; CHAR_RAFT
        sta SCREEN_RAM+240+14
        lda player_has_raft
        bne +
        lda #COL_DARK_GREY
        bne ++
+       lda #COL_BROWN
++      sta COLOR_RAM+240+14

        ; Livre (Col 17)
        lda #175                        ; CHAR_BOOK
        sta SCREEN_RAM+240+17
        lda player_has_book
        bne +
        lda #COL_DARK_GREY
        bne ++
+       lda #COL_LIGHT_BLUE
++      sta COLOR_RAM+240+17

        ; Anneau (Col 20)
        lda #173                        ; CHAR_RING
        sta SCREEN_RAM+240+20
        lda player_has_blue_ring
        bne +
        lda #COL_DARK_GREY
        bne ++
+       lda #COL_LIGHT_BLUE
++      sta COLOR_RAM+240+20

        ; Échelle (Col 23)
        lda #121                        ; CHAR_LADDER
        sta SCREEN_RAM+240+23
        lda player_has_stepladder
        bne +
        lda #COL_DARK_GREY
        bne ++
+       lda #COL_BROWN
++      sta COLOR_RAM+240+23

        ; Clé Magique (Col 26)
        lda #99                         ; CHAR_KEY
        sta SCREEN_RAM+240+26
        lda player_has_magic_key
        bne +
        lda #COL_DARK_GREY
        bne ++
+       lda #COL_YELLOW
++      sta COLOR_RAM+240+26

        ; Bracelet (Col 29)
        lda #122                        ; CHAR_BRACELET
        sta SCREEN_RAM+240+29
        lda player_has_bracelet
        bne +
        lda #COL_DARK_GREY
        bne ++
+       lda #COL_YELLOW
++      sta COLOR_RAM+240+29
        rts

setup_p0_sprites:
        lda #0
        sta VIC_SPRITE_EXP_X
        sta VIC_SPRITE_EXP_Y
        sta VIC_SPRITE_MSB
        lda #PLAYER_SKIN
        sta VIC_SPRITE_MC1
        lda #COL_WHITE
        sta VIC_SPRITE_MC2

        ; Sprite 0 : Arme actuellement équipée dans le cadre gauche (X=52, Y=100)
        ldx hud_selected_b
        lda item_sprite_ptrs,x
        sta SPRITE_PTR0
        lda item_colors,x
        sta VIC_SPRITE_COL0
        lda #52
        sta VIC_SPRITE_X0
        lda #100
        sta VIC_SPRITE_Y0

        ; Initialise la rangée 1 pour le démarrage
        jsr inv_p0_irq_row1

        ; Sprite 7 : Curseur cadre de sélection (clignotant)
        lda #(sprite_link_item_frame / 64)
        sta SPRITE_PTR7
        lda #COL_YELLOW
        sta VIC_SPRITE_COL7

        jsr inv_update_cursor

        lda #%10011111                  ; Sprites 0, 1, 2, 3, 4, 7 actifs
        sta VIC_SPRITE_EN
        lda #%00011111                  ; Sprites 0..4 multicolores, Sprite 7 haute résolution
        sta VIC_SPRITE_MC
        rts

p0_eq_v_lo:
        !byte <320, <360, <400, <440
p0_eq_v_hi:
        !byte >320, >360, >400, >440

p0_ars_v_lo:
        !byte <360, <400, <440, <480, <520, <560
p0_ars_v_hi:
        !byte >360, >400, >440, >480, >520, >560

; ---------------------------------------------------------------------------
; Multiplexeur raster pour la Page 0 de l'inventaire (grille 4x2 d'armes)
; ---------------------------------------------------------------------------
inv_p0_irq_row1:
        ; Sprites 1..4 (Rangée 1) : Boomerang, Bombe, Arc, Bougie (Y=118)
        lda #(sprite_link_item_boomerang / 64)
        sta SPRITE_PTR1
        lda #(sprite_link_item_bomb / 64)
        sta SPRITE_PTR2
        lda #(sprite_link_item_bow / 64)
        sta SPRITE_PTR3
        lda #(sprite_link_item_candle / 64)
        sta SPRITE_PTR4

        lda #COL_LIGHT_BLUE
        sta VIC_SPRITE_COL1
        lda #COL_BLUE
        sta VIC_SPRITE_COL2
        lda #COL_WHITE
        sta VIC_SPRITE_COL3
        lda #COL_LIGHT_BLUE
        sta VIC_SPRITE_COL4

        lda #140
        sta VIC_SPRITE_X1
        lda #172
        sta VIC_SPRITE_X2
        lda #204
        sta VIC_SPRITE_X3
        lda #236
        sta VIC_SPRITE_X4

        lda #118
        sta VIC_SPRITE_Y1
        sta VIC_SPRITE_Y2
        sta VIC_SPRITE_Y3
        sta VIC_SPRITE_Y4
        rts

irq_p0_row2:
        ; Sprites 1..4 (Rangée 2) : Flûte, Viande, Potion, Baguette (Y=142)
        lda #(sprite_link_item_whistle / 64)
        sta SPRITE_PTR1
        lda #(sprite_link_item_food / 64)
        sta SPRITE_PTR2
        lda #(sprite_link_item_potion / 64)
        sta SPRITE_PTR3
        lda #(sprite_link_item_wand / 64)
        sta SPRITE_PTR4

        lda #COL_YELLOW
        sta VIC_SPRITE_COL1
        lda #COL_BROWN
        sta VIC_SPRITE_COL2
        lda #COL_RED
        sta VIC_SPRITE_COL3
        lda #COL_LIGHT_BLUE
        sta VIC_SPRITE_COL4

        lda #140
        sta VIC_SPRITE_X1
        lda #172
        sta VIC_SPRITE_X2
        lda #204
        sta VIC_SPRITE_X3
        lda #236
        sta VIC_SPRITE_X4

        lda #142
        sta VIC_SPRITE_Y1
        sta VIC_SPRITE_Y2
        sta VIC_SPRITE_Y3
        sta VIC_SPRITE_Y4

        ; Prochaine interruption au bas de l'écran (raster 250)
        lda #250
        sta VIC_RASTER
        lda #< irq_bottom
        sta $0314
        lda #> irq_bottom
        sta $0315

        asl VIC_IRQ_FLAG
        jmp $ea81

inv_update_cursor:
        ldx hud_selected_b
        ; Met à jour l'arme équipée (Sprite 0)
        lda item_sprite_ptrs,x
        sta SPRITE_PTR0
        lda item_colors,x
        sta VIC_SPRITE_COL0

        ; Positionne le cadre de sélection (Sprite 7)
        lda cursor_x_coords,x
        sta VIC_SPRITE_X7
        lda cursor_y_coords,x
        sta VIC_SPRITE_Y7

        jsr draw_p0_description
        rts

draw_p0_description:
        ; Efface la ligne 17 (SCREEN_RAM+680)
        ldx #0
-       lda #' '
        sta SCREEN_RAM+680+2,x
        inx
        cpx #36
        bne -

        ldx hud_selected_b
        lda p0_desc_lo,x
        sta ZP_SRC
        lda p0_desc_hi,x
        sta ZP_SRC+1

        ldy #0
-       lda (ZP_SRC),y
        beq +
        sta SCREEN_RAM+680+14,y
        lda #COL_YELLOW
        sta COLOR_RAM+680+14,y
        iny
        cpy #24
        bne -
+       rts

draw_p0_stock:
        ldx #0
-       lda txt_p0_stock_line,x
        sta SCREEN_RAM+760+2,x
        lda #COL_WHITE
        sta COLOR_RAM+760+2,x
        inx
        cpx #36
        bne -

        lda hud_rupees
        ldy #9
        jsr p0_write_stat_val

        lda hud_keys
        ldy #21
        jsr p0_write_stat_val

        lda hud_bombs
        ldy #34
p0_write_stat_val:
        jsr print_2digits
        sta SCREEN_RAM+760,y
        txa
        iny
        sta SCREEN_RAM+760,y
        lda #COL_YELLOW
        sta COLOR_RAM+760,y
        dey
        sta COLOR_RAM+760,y
        rts

; ===========================================================================
; PAGE 1 : LA TRIFORCE DE LA SAGESSE (8 FRAGMENTS ASSEMBLES)
; ===========================================================================
draw_page_1_triforce:
        lda #0
        sta VIC_SPRITE_MSB
        sta VIC_SPRITE_EXP_X
        sta VIC_SPRITE_EXP_Y

        ; Ligne 6 : Titre orné
        ldx #0
-       lda txt_p1_title,x
        sta SCREEN_RAM+240+4,x
        lda #COL_YELLOW
        sta COLOR_RAM+240+4,x
        inx
        cpx #32
        bne -

        ; Lignes 7..12 : Cadre extérieur de la Grande Pyramide
        jsr draw_p1_pyramid_frame

        ; Ligne 14 : Label "TRIFORCE" centré sous la pyramide
        ldx #7
-       lda txt_tri_label,x
        sta SCREEN_RAM+560+16,x
        lda #COL_YELLOW
        sta COLOR_RAM+560+16,x
        dex
        bpl -

        ; Configuration matérielle des 8 sprites de fragments
        jsr setup_p1_triforce_sprites

        ; Ligne 17 : Compteur de fragments
        jsr draw_p1_counter

        ; Ligne 19 : Indicateurs des 8 donjons
        jsr draw_p1_dungeons

        ; Ligne 21 : Statut légendaire
        jsr draw_p1_status
        rts

draw_p1_pyramid_frame:
        ; Lignes 7..12 (SCREEN_RAM+280 .. +480)
        lda #'/'
        sta SCREEN_RAM+280+19
        lda #92
        sta SCREEN_RAM+280+20
        lda #'/'
        sta SCREEN_RAM+320+18
        lda #92
        sta SCREEN_RAM+320+21
        lda #'/'
        sta SCREEN_RAM+360+17
        lda #92
        sta SCREEN_RAM+360+22
        lda #'/'
        sta SCREEN_RAM+400+16
        lda #92
        sta SCREEN_RAM+400+23
        lda #'/'
        sta SCREEN_RAM+440+15
        lda #92
        sta SCREEN_RAM+440+24
        lda #'+'
        sta SCREEN_RAM+480+14
        sta SCREEN_RAM+480+25
        ldx #9
-       lda #'-'
        sta SCREEN_RAM+480+15,x
        lda #COL_DARK_GREY
        sta COLOR_RAM+480+15,x
        dex
        bpl -
        lda #COL_DARK_GREY
        sta COLOR_RAM+280+19
        sta COLOR_RAM+280+20
        sta COLOR_RAM+320+18
        sta COLOR_RAM+320+21
        sta COLOR_RAM+360+17
        sta COLOR_RAM+360+22
        sta COLOR_RAM+400+16
        sta COLOR_RAM+400+23
        sta COLOR_RAM+440+15
        sta COLOR_RAM+440+24
        sta COLOR_RAM+480+14
        sta COLOR_RAM+480+25
        rts

setup_p1_triforce_sprites:
        ; Configuration multicolore d'or pour tous les 8 sprites
        lda #PLAYER_SKIN
        sta VIC_SPRITE_MC1
        lda #COL_WHITE
        sta VIC_SPRITE_MC2
        lda #%11111111
        sta VIC_SPRITE_MC

        ; Pointeurs des 8 sprites de fragments
        lda #(sprite_tri_p1 / 64)       ; Piece 1 : Apex Sup Gauche
        sta SPRITE_PTR0
        lda #(sprite_tri_p2 / 64)       ; Piece 2 : Apex Sup Droit
        sta SPRITE_PTR1
        lda #(sprite_tri_p3 / 64)       ; Piece 3 : Base Inf Gauche Ext
        sta SPRITE_PTR2
        lda #(sprite_tri_p4 / 64)       ; Piece 4 : Base Inf Droit Ext
        sta SPRITE_PTR3
        lda #(sprite_tri_p5 / 64)       ; Piece 5 : Base Inf Gauche Int A
        sta SPRITE_PTR4
        lda #(sprite_tri_p6 / 64)       ; Piece 6 : Base Inf Gauche Int B
        sta SPRITE_PTR5
        lda #(sprite_tri_p7 / 64)       ; Piece 7 : Base Inf Droit Int A
        sta SPRITE_PTR6
        lda #(sprite_tri_p8 / 64)       ; Piece 8 : Base Inf Droit Int B
        sta SPRITE_PTR7

        ; Couleur d'or étincelant pour tous les 8 sprites
        ldx #7
-       lda #COL_YELLOW
        sta VIC_SPRITE_COL0,x
        dex
        bpl -

        ; Coordonnées X et Y des 8 fragments (Grand triangle 96x42 centré à X=184)
        ; Rangée Supérieure (Y=90)
        lda #160
        sta VIC_SPRITE_X0
        lda #184
        sta VIC_SPRITE_X1
        lda #90
        sta VIC_SPRITE_Y0
        sta VIC_SPRITE_Y1

        ; Rangée Inférieure (Y=111)
        lda #136
        sta VIC_SPRITE_X2
        lda #160
        sta VIC_SPRITE_X4
        lda #172
        sta VIC_SPRITE_X5
        lda #184
        sta VIC_SPRITE_X6
        lda #196
        sta VIC_SPRITE_X7
        lda #208
        sta VIC_SPRITE_X3

        lda #111
        sta VIC_SPRITE_Y2
        sta VIC_SPRITE_Y3
        sta VIC_SPRITE_Y4
        sta VIC_SPRITE_Y5
        sta VIC_SPRITE_Y6
        sta VIC_SPRITE_Y7

        ; Activation matérielle des fragments possédés dans player_triforce_pieces
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

        ldx #0
-       lda txt_p1_counter,x
        sta SCREEN_RAM+680+6,x
        lda #COL_WHITE
        sta COLOR_RAM+680+6,x
        inx
        cpx #28
        bne -

        lda #'0'
        clc
        adc ZP_TMP
        sta SCREEN_RAM+680+28
        lda #COL_YELLOW
        sta COLOR_RAM+680+28
        rts

draw_p1_dungeons:
        ldx #0
-       lda txt_p1_dungeons_line,x
        sta SCREEN_RAM+760+3,x
        lda #COL_WHITE
        sta COLOR_RAM+760+3,x
        inx
        cpx #34
        bne -

        ; Colorie chaque donjon selon possession
        ldx #0
.dung_col_loop:
        lda bit_powers,x
        and player_triforce_pieces
        beq .missing_dung
        lda #COL_YELLOW
        jmp .apply_dcol
.missing_dung:
        lda #COL_DARK_GREY
.apply_dcol:
        sta ZP_TMP

        txa
        asl
        asl                             ; * 4
        clc
        adc #14
        tay
        lda ZP_TMP
        sta COLOR_RAM+760+3,y
        iny
        sta COLOR_RAM+760+3,y
        iny
        sta COLOR_RAM+760+3,y

        inx
        cpx #8
        bne .dung_col_loop
        rts

draw_p1_status:
        lda player_triforce_pieces
        cmp #$ff
        beq .p1_full
        lda #<txt_p1_msg_seek
        ldx #>txt_p1_msg_seek
        ldy #COL_CYAN
        jmp .p1_draw
.p1_full:
        lda #<txt_p1_msg_full
        ldx #>txt_p1_msg_full
        ldy #COL_YELLOW
.p1_draw:
        sta ZP_SRC
        stx ZP_SRC+1
        sty ZP_BASE

        ldy #35
-       lda (ZP_SRC),y
        sta SCREEN_RAM+840+2,y
        lda ZP_BASE
        sta COLOR_RAM+840+2,y
        dey
        bpl -
        rts

; ===========================================================================
; PAGE 2 : EQUIPEMENT PERMANENT & RELIQUES HEROIQUES
; ===========================================================================
draw_page_2_equipment:
        lda #0
        sta VIC_SPRITE_EXP_X
        sta VIC_SPRITE_EXP_Y
        sta VIC_SPRITE_MSB

        ; Configuration multicolore des 8 sprites matériels
        lda #PLAYER_SKIN
        sta VIC_SPRITE_MC1
        lda #COL_WHITE
        sta VIC_SPRITE_MC2
        lda #%11111111
        sta VIC_SPRITE_MC

        ; Ligne 5 : Titre noble
        ldx #0
-       lda txt_p2_title,x
        sta SCREEN_RAM+200+3,x
        lda #COL_YELLOW
        sta COLOR_RAM+200+3,x
        inx
        cpx #34
        bne -

        ; Tracé des 8 boîtes d'équipement avec cadres héroïques
        jsr draw_p2_boxes

        ; Configuration des 8 sprites et de leurs statuts
        jsr setup_p2_slots

        ; Ligne 20 : Frise de séparation
        ldx #0
-       lda #CHAR_HERO_TOP
        sta SCREEN_RAM+800,x
        lda #COL_BLUE
        sta COLOR_RAM+800,x
        inx
        cpx #40
        bne -

        ; Ligne 21 : Message d'équipement
        ldx #0
-       lda txt_p2_tip,x
        sta SCREEN_RAM+840+2,x
        lda #COL_CYAN
        sta COLOR_RAM+840+2,x
        inx
        cpx #36
        bne -
        rts

draw_p2_boxes:
        ldx #0
.box_p2_loop:
        lda p2_box_offs_lo,x
        sta ZP_SCR
        sta ZP_COL
        lda p2_box_offs_hi,x
        jsr inv_set_scr_col_hi

        ; Coins héroïques du cadre de l'objet
        lda #CHAR_SLOT_TL
        ldy #0
        sta (ZP_SCR),y
        lda #CHAR_SLOT_TR
        ldy #7
        sta (ZP_SCR),y
        lda #CHAR_SLOT_BL
        ldy #200
        sta (ZP_SCR),y
        lda #CHAR_SLOT_BR
        ldy #207
        sta (ZP_SCR),y

        ; Rails horizontaux supérieur et inférieur
        ldy #1
-       lda #CHAR_SLOT_TH
        sta (ZP_SCR),y
        lda #CHAR_SLOT_BH
        tya
        clc
        adc #200
        tay
        sta (ZP_SCR),y
        tya
        sec
        sbc #200
        tay
        iny
        cpy #7
        bne -

        ; Rails verticaux
        lda #CHAR_SLOT_LV
        ldy #40
        sta (ZP_SCR),y
        ldy #80
        sta (ZP_SCR),y
        ldy #120
        sta (ZP_SCR),y
        ldy #160
        sta (ZP_SCR),y

        lda #CHAR_SLOT_RV
        ldy #47
        sta (ZP_SCR),y
        ldy #87
        sta (ZP_SCR),y
        ldy #127
        sta (ZP_SCR),y
        ldy #167
        sta (ZP_SCR),y

        ; Couleur bleue pour le cadre
        ldy #0
-       lda #COL_BLUE
        sta (ZP_COL),y
        iny
        cpy #8
        bne -

        ldy #200
-       lda #COL_BLUE
        sta (ZP_COL),y
        iny
        cpy #208
        bne -

        ldy #40
        lda #COL_BLUE
        sta (ZP_COL),y
        ldy #47
        sta (ZP_COL),y
        ldy #80
        sta (ZP_COL),y
        ldy #87
        sta (ZP_COL),y
        ldy #120
        sta (ZP_COL),y
        ldy #127
        sta (ZP_COL),y
        ldy #160
        sta (ZP_COL),y
        ldy #167
        sta (ZP_COL),y

        inx
        cpx #8
        beq +
        jmp .box_p2_loop
+       rts

p2_box_offs_lo:
        !byte <(240+2), <(240+11), <(240+20), <(240+29)
        !byte <(520+2), <(520+11), <(520+20), <(520+29)
p2_box_offs_hi:
        !byte >(240+2), >(240+11), >(240+20), >(240+29)
        !byte >(520+2), >(520+11), >(520+20), >(520+29)

setup_p2_slots:
        lda #0
        sta ZP_TMP                      ; masque VIC_SPRITE_EN

        ; Positions des 8 sprites centrés dans leurs cadres
        ; Rangée Supérieure (Y=96)
        lda #60
        sta VIC_SPRITE_X0
        sta VIC_SPRITE_X4
        lda #132
        sta VIC_SPRITE_X1
        sta VIC_SPRITE_X5
        lda #204
        sta VIC_SPRITE_X2
        sta VIC_SPRITE_X6
        lda #20                         ; 276 - 256 (MSB=1)
        sta VIC_SPRITE_X3
        sta VIC_SPRITE_X7

        lda #102
        sta VIC_SPRITE_Y0
        sta VIC_SPRITE_Y1
        sta VIC_SPRITE_Y2
        sta VIC_SPRITE_Y3

        ; Rangée Inférieure (Y=158)
        lda #158
        sta VIC_SPRITE_Y4
        sta VIC_SPRITE_Y5
        sta VIC_SPRITE_Y6
        sta VIC_SPRITE_Y7

        ; Sprites 3 et 7 sont à X > 255 (Col 29)
        lda #%10001000
        sta VIC_SPRITE_MSB

        ; Affiche les noms des 8 slots
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

inv_set_scr_col_hi:
        clc
        adc #>SCREEN_RAM
        sta ZP_SCR+1
        clc
        adc #$d4
        sta ZP_COL+1
        rts

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

txt_all_slot_names: !text " SWORDSHIELD RING BRACEL RAFT LADDER KEY   BOOK "
txt_p2_empty:       !text "[NONE]"
txt_p2_acquired:    !text "OWNED "

; ===========================================================================
; PAGE 3 : CARTE DU MONDE AUX VRAIES COULEURS DE BIOMES
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
        ; Ligne 5 : Colonnes A..P
        ldx #0
        ldy #0
.put_col_letters:
        txa
        clc
        adc #'A'
        sta SCREEN_RAM+200+4,y
        lda #' '
        sta SCREEN_RAM+200+5,y
        lda #COL_WHITE
        sta COLOR_RAM+200+4,y
        sta COLOR_RAM+200+5,y
        iny
        iny
        inx
        cpx #16
        bne .put_col_letters

        jsr draw_map_borders

        ; Lignes 7..14 : 8 rangées de salles
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

        ; Chiffre de ligne 1..8
        txa
        clc
        adc #'1'
        ldy #0
        sta (ZP_SCR),y
        lda #COL_WHITE
        sta (ZP_COL),y

        ; Bordures verticales colonnes 2 et 37
        lda #CHAR_HERO_VERT
        ldy #2
        sta (ZP_SCR),y
        ldy #37
        sta (ZP_SCR),y
        lda #COL_BLUE
        ldy #2
        sta (ZP_COL),y
        ldy #37
        sta (ZP_COL),y

        lda #0
        sta map_rx
.col_loop:
        ldx map_ry
        lda world_row_offset,x
        clc
        adc map_rx
        tax

        ; Couleur de biome réelle pour cette salle
        lda ow_room_biome_colors,x
        sta ZP_BASE

        lda map_rx
        cmp current_room_x
        bne .check_visited
        lda map_ry
        cmp current_room_y
        bne .check_visited

        ; Link clignotant (1 seule case)
        lda #HUD_MAP_ACTIVE
        sta ZP_TMP
        lda #' '
        sta ZP_TCOL
        lda map_link_color
        sta ZP_BASE
        jmp .render_cell

.check_visited:
        lda visited_rooms,x
        beq .cell_unseen

        ; Salle visitée : bloc plein avec la vraie couleur de biome (1 seule case) !
        lda #HUD_MAP_ACTIVE
        sta ZP_TMP
        lda #' '
        sta ZP_TCOL
        jmp .render_cell

.cell_unseen:
        ; Salle inexplorée : point discret gris sombre
        lda #HUD_MAP_EMPTY
        sta ZP_TMP
        lda #' '
        sta ZP_TCOL
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
        lda ZP_TCOL
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
        ; Ligne 17 : Coordonnées et progression
        ldx #0
-       lda txt_room_line,x
        sta SCREEN_RAM+680+2,x
        lda #COL_WHITE
        sta COLOR_RAM+680+2,x
        inx
        cpx #36
        bne -

        lda #'A'
        clc
        adc current_room_x
        sta SCREEN_RAM+680+13
        lda #'1'
        clc
        adc current_room_y
        sta SCREEN_RAM+680+15
        lda #COL_YELLOW
        sta COLOR_RAM+680+13
        sta COLOR_RAM+680+14
        sta COLOR_RAM+680+15

        ; Calcul et affichage du compteur de salles visitées
        jsr calc_visited_count
        lda visited_count
        cmp #100
        bcc .under100
        sec
        sbc #100
        jsr print_2digits
        sta ZP_TMP
        stx ZP_TMP+1
        lda #'1'
        jmp .write_vis
.under100:
        jsr print_2digits
        sta ZP_TMP
        stx ZP_TMP+1
        lda #' '
.write_vis:
        sta SCREEN_RAM+680+35
        lda ZP_TMP
        sta SCREEN_RAM+680+36
        lda ZP_TMP+1
        sta SCREEN_RAM+680+37

        lda #COL_YELLOW
        sta COLOR_RAM+680+35
        sta COLOR_RAM+680+36
        sta COLOR_RAM+680+37

        ; Ligne 19 : Légende Biomes 1
        ldx #0
-       lda txt_legend_b1,x
        sta SCREEN_RAM+760+2,x
        lda #COL_WHITE
        sta COLOR_RAM+760+2,x
        inx
        cpx #36
        bne -

        lda #HUD_MAP_ACTIVE
        sta SCREEN_RAM+760+11
        sta SCREEN_RAM+760+20
        sta SCREEN_RAM+760+30
        lda #COL_LIGHT_BLUE             ; EAU
        sta COLOR_RAM+760+11
        lda #COL_GREEN                  ; FORET
        sta COLOR_RAM+760+20
        lda #COL_BROWN                  ; MONTAGNE
        sta COLOR_RAM+760+30

        ; Ligne 21 : Légende Biomes 2
        ldx #0
-       lda txt_legend_b2,x
        sta SCREEN_RAM+840+2,x
        lda #COL_WHITE
        sta COLOR_RAM+840+2,x
        inx
        cpx #36
        bne -

        lda #HUD_MAP_ACTIVE
        sta SCREEN_RAM+840+11
        sta SCREEN_RAM+840+20
        sta SCREEN_RAM+840+30
        lda #COL_YELLOW                 ; DESERT
        sta COLOR_RAM+840+11
        lda #COL_DARK_GREY              ; CIMETIERE
        sta COLOR_RAM+840+20
        lda #COL_LIGHT_GREEN            ; PLAINE
        sta COLOR_RAM+840+30
        rts

; ---------------------------------------------------------------------------
; draw_page_3_dungeon_map : affiche la carte officielle du donjon en cours
; ---------------------------------------------------------------------------
draw_page_3_dungeon_map:
        lda #'0'
        clc
        adc current_dungeon_level
        sta txt_dtitle_pref+8

        ldy #0
-       lda txt_dtitle_pref,y
        beq +
        sta SCREEN_RAM+200+4,y
        lda #COL_YELLOW
        sta COLOR_RAM+200+4,y
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
        sta SCREEN_RAM+200+16,y
        lda #COL_YELLOW
        sta COLOR_RAM+200+16,y
        iny
        bne -
+
        ; Cadre centré 8x8 (Colonnes 11..28, Lignes 6 et 15)
        lda #CHAR_HERO_TL
        sta SCREEN_RAM+240+11
        lda #CHAR_HERO_TR
        sta SCREEN_RAM+240+28
        lda #CHAR_HERO_BL
        sta SCREEN_RAM+600+11
        lda #CHAR_HERO_BR
        sta SCREEN_RAM+600+28
        lda #COL_BLUE
        sta COLOR_RAM+240+11
        sta COLOR_RAM+240+28
        sta COLOR_RAM+600+11
        sta COLOR_RAM+600+28
        ldx #0
-       lda #CHAR_HERO_TOP
        sta SCREEN_RAM+240+12,x
        lda #CHAR_HERO_BOT
        sta SCREEN_RAM+600+12,x
        lda #COL_BLUE
        sta COLOR_RAM+240+12,x
        sta COLOR_RAM+600+12,x
        inx
        cpx #16
        bne -

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

        lda #CHAR_HERO_VERT
        ldy #11
        sta (ZP_SCR),y
        ldy #28
        sta (ZP_SCR),y
        lda #COL_BLUE
        ldy #11
        sta (ZP_COL),y
        ldy #28
        sta (ZP_COL),y

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

        lda $c016,x
        cmp $c016
        beq .d_no_room

        lda player_has_dungeon_map
        bne .d_room_revealed
        lda visited_uw_rooms,x
        bne .d_room_revealed

.d_no_room:
        lda #32
        sta ZP_TMP
        sta ZP_TMP+1
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
        sta ZP_TMP+1
        lda #COL_YELLOW
        sta ZP_BASE
        jmp .d_put_cell
+
        lda player_has_compass
        beq ++
        ldy current_dungeon_level
        dey
        cpy #9
        bcc +++
        ldy #0
+++     txa
        cmp dungeon_tri_rooms,y
        bne ++
        lda #HUD_MAP_ACTIVE
        sta ZP_TMP
        sta ZP_TMP+1
        lda #COL_LIGHT_RED
        sta ZP_BASE
        jmp .d_put_cell
++
        lda #HUD_MAP_VISITED
        sta ZP_TMP
        sta ZP_TMP+1
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
        lda ZP_TMP+1
        sta (ZP_SCR),y
        lda ZP_BASE
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
        ; Légende du donjon (Ligne 17)
        ldx #0
-       lda txt_dung_legend,x
        beq +
        sta SCREEN_RAM+680+4,x
        lda txt_dung_leg_col,x
        sta COLOR_RAM+680+4,x
        inx
        bne -
+       rts

dung_bank_x:
        !byte 0, 8, 8, 0, 0, 8, 8, 8, 0

dungeon_tri_rooms:
        !byte $36, $0d, $3d, $03, $14, $0c, $2b, $2c, $32

p3_dung_names_lo:
        !byte <p3_d1, <p3_d2, <p3_d3, <p3_d4, <p3_d5, <p3_d6, <p3_d7, <p3_d8, <p3_d9
p3_dung_names_hi:
        !byte >p3_d1, >p3_d2, >p3_d3, >p3_d4, >p3_d5, >p3_d6, >p3_d7, >p3_d8, >p3_d9

txt_dtitle_pref:    !text "LEVEL   1 : ", 0
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
        !byte HUD_MAP_ACTIVE
        !text " TRIFORCE  "
        !byte HUD_MAP_ACTIVE
        !text " LINK  "
        !byte HUD_MAP_VISITED
        !text " SEEN  ", 0

txt_dung_leg_col:
        !byte COL_LIGHT_RED
        !fill 11, COL_WHITE
        !byte COL_YELLOW
        !fill 7, COL_WHITE
        !byte COL_CYAN
        !fill 7, COL_WHITE
        !byte 0

draw_map_borders:
        lda #CHAR_HERO_TL
        sta SCREEN_RAM+240+2
        lda #CHAR_HERO_TR
        sta SCREEN_RAM+240+37
        lda #CHAR_HERO_BL
        sta SCREEN_RAM+600+2
        lda #CHAR_HERO_BR
        sta SCREEN_RAM+600+37
        lda #COL_BLUE
        sta COLOR_RAM+240+2
        sta COLOR_RAM+240+37
        sta COLOR_RAM+600+2
        sta COLOR_RAM+600+37
        ldx #0
-       lda #CHAR_HERO_TOP
        sta SCREEN_RAM+240+3,x
        lda #CHAR_HERO_BOT
        sta SCREEN_RAM+600+3,x
        lda #COL_BLUE
        sta COLOR_RAM+240+3,x
        sta COLOR_RAM+600+3,x
        inx
        cpx #34
        bne -
        rts

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
        ; Rangée 1 (A-1 à P-1) : Montagne de la Mort & Océan Est
        !byte COL_BROWN, COL_BROWN, COL_BROWN, COL_BROWN, COL_BROWN, COL_BROWN, COL_BROWN, COL_BROWN
        !byte COL_BROWN, COL_BROWN, COL_LIGHT_BLUE, COL_BROWN, COL_BROWN, COL_BROWN, COL_LIGHT_BLUE, COL_LIGHT_BLUE
        ; Rangée 2 (A-2 à P-2) : Roches volcaniques & Côte
        !byte COL_BROWN, COL_BROWN, COL_BROWN, COL_BROWN, COL_BROWN, COL_BROWN, COL_BROWN, COL_BROWN
        !byte COL_BROWN, COL_BROWN, COL_BROWN, COL_BROWN, COL_BROWN, COL_BROWN, COL_LIGHT_BLUE, COL_BROWN
        ; Rangée 3 (A-3 à P-3) : Cimetière, Plaines, Rivière & Désert
        !byte COL_DARK_GREY, COL_DARK_GREY, COL_BROWN, COL_BROWN, COL_LIGHT_GREEN, COL_LIGHT_GREEN, COL_LIGHT_BLUE, COL_LIGHT_BLUE
        !byte COL_LIGHT_BLUE, COL_YELLOW, COL_YELLOW, COL_YELLOW, COL_BROWN, COL_LIGHT_BLUE, COL_LIGHT_BLUE, COL_BROWN
        ; Rangée 4 (A-4 à P-4) : Cimetière, Lac Hylia, Désert & Bois
        !byte COL_DARK_GREY, COL_DARK_GREY, COL_BROWN, COL_BROWN, COL_LIGHT_BLUE, COL_LIGHT_BLUE, COL_LIGHT_BLUE, COL_LIGHT_BLUE
        !byte COL_LIGHT_BLUE, COL_LIGHT_BLUE, COL_YELLOW, COL_YELLOW, COL_BROWN, COL_GREEN, COL_LIGHT_BLUE, COL_LIGHT_BLUE
        ; Rangée 5 (A-5 à P-5) : Cimetière, Grand Lac, Clairière & Forêt Est
        !byte COL_DARK_GREY, COL_DARK_GREY, COL_LIGHT_BLUE, COL_LIGHT_BLUE, COL_LIGHT_BLUE, COL_LIGHT_BLUE, COL_LIGHT_BLUE, COL_LIGHT_BLUE
        !byte COL_LIGHT_BLUE, COL_GREEN, COL_LIGHT_GREEN, COL_GREEN, COL_BROWN, COL_GREEN, COL_GREEN, COL_LIGHT_BLUE
        ; Rangée 6 (A-6 à P-6) : Bois Perdus, Fleuve & Forêts
        !byte COL_BROWN, COL_GREEN, COL_GREEN, COL_GREEN, COL_LIGHT_BLUE, COL_LIGHT_BLUE, COL_LIGHT_BLUE, COL_GREEN
        !byte COL_GREEN, COL_GREEN, COL_LIGHT_BLUE, COL_GREEN, COL_GREEN, COL_GREEN, COL_BROWN, COL_LIGHT_BLUE
        ; Rangée 7 (A-7 à P-7) : Bois Perdus, Traversée du fleuve & Plaines
        !byte COL_GREEN, COL_GREEN, COL_GREEN, COL_GREEN, COL_LIGHT_GREEN, COL_LIGHT_BLUE, COL_BROWN, COL_BROWN
        !byte COL_GREEN, COL_LIGHT_BLUE, COL_LIGHT_BLUE, COL_GREEN, COL_GREEN, COL_GREEN, COL_GREEN, COL_LIGHT_BLUE
        ; Rangée 8 (A-8 à P-8) : Clairière de départ, Forêt du Sud & Océan
        !byte COL_BROWN, COL_LIGHT_GREEN, COL_GREEN, COL_GREEN, COL_BROWN, COL_LIGHT_BLUE, COL_LIGHT_GREEN, COL_BROWN
        !byte COL_GREEN, COL_BROWN, COL_BROWN, COL_LIGHT_BLUE, COL_LIGHT_BLUE, COL_LIGHT_BLUE, COL_LIGHT_BLUE, COL_LIGHT_BLUE

; ===========================================================================
; TEXTES DU MENU D'INVENTAIRE EN 4 PAGES
; ===========================================================================

txt_tabs_base:      !text " 1:ITEMS   2:TRIFORCE  3:EQUIP  4:MAP   "
tab_bracket_pos:    !byte 0, 9,  10, 21,  21, 30,  30, 39
tab_start:          !byte 0, 10, 22, 31
tab_end:            !byte 10, 22, 31, 40

txt_footer_help:    !text " [JOY] SELECT  [1-4] PAGE     [B] EXIT  "

; Textes Page 0
txt_p0_inv_hdr:     !text "INVENTORY"
txt_p0_relics_hdr:  !text "PASSIVE RELICS"
txt_p0_use_b:       !text "USE B BUTTON"
txt_p0_for_this:    !text " FOR THIS "
txt_p0_stock_line:  !text "RUPEES:     KEYS:       BOMBS:      "
txt_p0_tip:         !text "[JOY] SELECT            [A] EQUIP   "

p0_desc_lo:
        !byte <desc_boom, <desc_bomb, <desc_bow, <desc_cand, <desc_whistle, <desc_food, <desc_potion, <desc_wand
p0_desc_hi:
        !byte >desc_boom, >desc_bomb, >desc_bow, >desc_cand, >desc_whistle, >desc_food, >desc_potion, >desc_wand

desc_boom:          !text "BOOMERANG", 0
desc_bomb:          !text "BOMBS", 0
desc_bow:           !text "BOW AND ARROWS", 0
desc_cand:          !text "CANDLE", 0
desc_food:          !text "FOOD", 0
desc_potion:        !text "POTION", 0
desc_whistle:       !text "RECORDER", 0
desc_wand:          !text "MAGICAL ROD", 0

; Textes Page 1 (Triforce)
txt_p1_title:       !text "   THE TRIFORCE OF WISDOM       "
txt_tri_label:      !text "TRIFORCE"
txt_p1_counter:     !text "    TRIFORCE PIECES : 0 / 8 "
txt_p1_dungeons_line: !text "LEVELS : [1][2][3][4][5][6][7][8] "
txt_p1_msg_seek:    !text "    FIND THE 8 TRIFORCE PIECES!     "
txt_p1_msg_full:    !text "   THE TRIFORCE IS COMPLETE!        "

; Textes Page 2 (Équipement)
txt_p2_title:       !text "    LINK'S EQUIPMENT & RELICS     "
txt_p2_tip:         !text " PASSIVE RELICS & PERMANENT UPGRADES"

; Textes Page 3 (Carte du Monde)
txt_room_line:      !text "LOCATION : A-1         EXPLORED:   0"
txt_legend_b1:      !text "BIOMES :   WATER    FOREST    ROCK  "
txt_legend_b2:      !text "           DESERT   GRAVE     PLAIN "
