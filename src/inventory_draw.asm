; ---------------------------------------------------------------------------
; inventory_draw.asm : Affichage graphique du menu d'inventaire en 4 pages
;   Page 0 : [1:OBJETS]     - Sélection Slot B (6 objets, descriptif, stock)
;   Page 1 : [2:TRIFORCE]   - La Triforce de la Sagesse (8 fragments numérotés)
;   Page 2 : [3:EQUIPEMENT] - Équipement permanent (Épées, Boucliers, Anneau, Reliques)
;   Page 3 : [4:CARTE]      - Carte du Monde 16x8 (128 salles, Link clignotant)
; ---------------------------------------------------------------------------

!zone inventory_draw

; Tables des sprites et couleurs des 6 armes sélectionnables (Slot B)
item_sprite_ptrs:
        !byte (sprite_link_item_boomerang / 64)
        !byte (sprite_link_item_bomb / 64)
        !byte (sprite_link_item_bow / 64)
        !byte (sprite_link_item_candle / 64)
        !byte (sprite_link_item_food / 64)
        !byte (sprite_link_item_potion / 64)

item_colors:
        !byte COL_LIGHT_BLUE            ; 0: Boomerang
        !byte COL_BLUE                  ; 1: Bombe
        !byte COL_WHITE                 ; 2: Arc & Flèche
        !byte COL_LIGHT_BLUE            ; 3: Bougie
        !byte COL_BROWN                 ; 4: Viande / Appât
        !byte COL_RED                   ; 5: Potion

; Coordonnées X des 6 objets (2 rangées de 3 colonnes)
cursor_x_coords:
        !byte 152, 196, 240             ; rangée 1 : Boomerang, Bombe, Arc
        !byte 152, 196, 240             ; rangée 2 : Bougie, Viande, Potion

cursor_y_coords:
        !byte 106, 106, 106             ; rangée 1
        !byte 134, 134, 134             ; rangée 2

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
inv_display_current_page:
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
        ; Sélectionne le texte de l'en-tête selon inv_page
        lda inv_page
        cmp #0
        bne +
        lda #<txt_tabs_p0
        sta ZP_SRC
        lda #>txt_tabs_p0
        sta ZP_SRC+1
        jmp .put_tabs
+       cmp #1
        bne +
        lda #<txt_tabs_p1
        sta ZP_SRC
        lda #>txt_tabs_p1
        sta ZP_SRC+1
        jmp .put_tabs
+       cmp #2
        bne +
        lda #<txt_tabs_p2
        sta ZP_SRC
        lda #>txt_tabs_p2
        sta ZP_SRC+1
        jmp .put_tabs
+       lda #<txt_tabs_p3
        sta ZP_SRC
        lda #>txt_tabs_p3
        sta ZP_SRC+1

.put_tabs:
        ldy #0
-       lda (ZP_SRC),y
        sta SCREEN_RAM+160,y
        lda #COL_CYAN
        sta COLOR_RAM+160,y
        iny
        cpy #40
        bne -

        ; Colorie l'onglet actif en jaune étincelant
        jsr highlight_active_tab

        ; Ligne 5 : Séparateur bleu
        ldx #0
-       lda #'-'
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
        lda inv_page
        cmp #0
        bne +
        ; Tab 0 : cols 0..9 ([1:OBJETS])
        ldx #0
-       lda #COL_YELLOW
        sta COLOR_RAM+160,x
        inx
        cpx #10
        bne -
        rts
+       cmp #1
        bne +
        ; Tab 1 : cols 10..21 ([2:TRIFORCE])
        ldx #10
-       lda #COL_YELLOW
        sta COLOR_RAM+160,x
        inx
        cpx #22
        bne -
        rts
+       cmp #2
        bne +
        ; Tab 2 : cols 22..30 ([3:EQUIP])
        ldx #22
-       lda #COL_YELLOW
        sta COLOR_RAM+160,x
        inx
        cpx #31
        bne -
        rts
+       ; Tab 3 : cols 31..39 ([4:CARTE])
        ldx #31
-       lda #COL_YELLOW
        sta COLOR_RAM+160,x
        inx
        cpx #40
        bne -
        rts

; ===========================================================================
; PAGE 0 : OBJETS ACTIFS DU SLOT B
; ===========================================================================
draw_page_0_items:
        ; 1. Boîte Arme équipée (Cols 3..10, Lignes 6..11)
        ldx #0
-       lda txt_box_small,x
        sta SCREEN_RAM+240+3,x
        sta SCREEN_RAM+440+3,x
        lda #COL_BLUE
        sta COLOR_RAM+240+3,x
        sta COLOR_RAM+440+3,x
        inx
        cpx #8
        bne -

        ldx #0
-       lda #'|'
        sta SCREEN_RAM+280+3,x
        sta SCREEN_RAM+320+3,x
        sta SCREEN_RAM+360+3,x
        sta SCREEN_RAM+400+3,x
        lda #COL_BLUE
        sta COLOR_RAM+280+3,x
        sta COLOR_RAM+320+3,x
        sta COLOR_RAM+360+3,x
        sta COLOR_RAM+400+3,x
        inx
        cpx #8
        beq +
        ldx #7
        jmp -
+
        ; Labels Arme active
        ldx #0
-       lda txt_p0_active,x
        sta SCREEN_RAM+480+3,x
        lda #COL_WHITE
        sta COLOR_RAM+480+3,x
        inx
        cpx #8
        bne -

        ldx #0
-       lda txt_p0_slot_b,x
        sta SCREEN_RAM+520+3,x
        lda #COL_CYAN
        sta COLOR_RAM+520+3,x
        inx
        cpx #8
        bne -

        ; 2. Boîte des 6 Objets sélectionnables (Cols 14..37, Lignes 6..12)
        ldx #0
-       lda txt_box_p0_grid,x
        sta SCREEN_RAM+240+14,x
        sta SCREEN_RAM+480+14,x
        lda #COL_BLUE
        sta COLOR_RAM+240+14,x
        sta COLOR_RAM+480+14,x
        inx
        cpx #24
        bne -

        ldx #0
-       lda #'|'
        sta SCREEN_RAM+280+14,x
        sta SCREEN_RAM+320+14,x
        sta SCREEN_RAM+360+14,x
        sta SCREEN_RAM+400+14,x
        sta SCREEN_RAM+440+14,x
        lda #COL_BLUE
        sta COLOR_RAM+280+14,x
        sta COLOR_RAM+320+14,x
        sta COLOR_RAM+360+14,x
        sta COLOR_RAM+400+14,x
        sta COLOR_RAM+440+14,x
        inx
        cpx #24
        beq +
        ldx #23
        jmp -
+
        ; Ligne 14 : Description de l'objet pointé
        jsr draw_p0_description

        ; Ligne 16 : Compteurs d'inventaire
        jsr draw_p0_stock

        ; Ligne 18 : Astuce d'équipement
        ldx #0
-       lda txt_p0_tip,x
        sta SCREEN_RAM+720+2,x
        lda #COL_YELLOW
        sta COLOR_RAM+720+2,x
        inx
        cpx #36
        bne -

        ; Configure tous les 8 sprites matériels
        jsr setup_p0_sprites
        rts

setup_p0_sprites:
        lda #PLAYER_SKIN
        sta VIC_SPRITE_MC1
        lda #COL_WHITE
        sta VIC_SPRITE_MC2

        ; Sprite 0 : Arme actuellement équipée (X=64, Y=106)
        ldx hud_selected_b
        lda item_sprite_ptrs,x
        sta SPRITE_PTR0
        lda item_colors,x
        sta VIC_SPRITE_COL0
        lda #64
        sta VIC_SPRITE_X0
        lda #106
        sta VIC_SPRITE_Y0

        ; Sprites 1..3 (Rangée 1) : Boomerang, Bombe, Arc (Y=106)
        lda #(sprite_link_item_boomerang / 64)
        sta SPRITE_PTR1
        lda #(sprite_link_item_bomb / 64)
        sta SPRITE_PTR2
        lda #(sprite_link_item_bow / 64)
        sta SPRITE_PTR3

        lda #COL_LIGHT_BLUE
        sta VIC_SPRITE_COL1
        lda #COL_BLUE
        sta VIC_SPRITE_COL2
        lda #COL_WHITE
        sta VIC_SPRITE_COL3

        lda #152
        sta VIC_SPRITE_X1
        lda #196
        sta VIC_SPRITE_X2
        lda #240
        sta VIC_SPRITE_X3

        lda #106
        sta VIC_SPRITE_Y1
        sta VIC_SPRITE_Y2
        sta VIC_SPRITE_Y3

        ; Sprites 4..6 (Rangée 2) : Bougie, Viande, Potion (Y=134)
        lda #(sprite_link_item_candle / 64)
        sta SPRITE_PTR4
        lda #(sprite_link_item_food / 64)
        sta SPRITE_PTR5
        lda #(sprite_link_item_potion / 64)
        sta SPRITE_PTR6

        lda #COL_LIGHT_BLUE
        sta VIC_SPRITE_COL4
        lda #COL_BROWN
        sta VIC_SPRITE_COL5
        lda #COL_RED
        sta VIC_SPRITE_COL6

        lda #152
        sta VIC_SPRITE_X4
        lda #196
        sta VIC_SPRITE_X5
        lda #240
        sta VIC_SPRITE_X6

        lda #134
        sta VIC_SPRITE_Y4
        sta VIC_SPRITE_Y5
        sta VIC_SPRITE_Y6

        ; Sprite 7 : Curseur cadre de sélection (clignotant)
        lda #(sprite_link_item_frame / 64)
        sta SPRITE_PTR7
        lda #COL_YELLOW
        sta VIC_SPRITE_COL7

        jsr inv_update_cursor

        lda #0
        sta VIC_SPRITE_MSB
        lda #%11111111                  ; Tous les 8 sprites actifs
        sta VIC_SPRITE_EN
        lda #%01111111                  ; Sprites 0..6 multicolores, Sprite 7 haute résolution
        sta VIC_SPRITE_MC
        rts

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
        ; Efface la ligne 14 (SCREEN_RAM+560)
        ldx #0
-       lda #' '
        sta SCREEN_RAM+560+2,x
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
        sta SCREEN_RAM+560+2,y
        lda #COL_CYAN
        sta COLOR_RAM+560+2,y
        iny
        cpy #36
        bne -
+       rts

draw_p0_stock:
        ldx #0
-       lda txt_p0_stock_line,x
        sta SCREEN_RAM+640+2,x
        lda #COL_WHITE
        sta COLOR_RAM+640+2,x
        inx
        cpx #36
        bne -

        ; Affiche Rubis
        lda hud_rupees
        jsr print_2digits
        sta SCREEN_RAM+640+9
        stx SCREEN_RAM+640+10
        lda #COL_YELLOW
        sta COLOR_RAM+640+9
        sta COLOR_RAM+640+10

        ; Affiche Clefs
        lda hud_keys
        jsr print_2digits
        sta SCREEN_RAM+640+21
        stx SCREEN_RAM+640+22
        lda #COL_YELLOW
        sta COLOR_RAM+640+21
        sta COLOR_RAM+640+22

        ; Affiche Bombes
        lda hud_bombs
        jsr print_2digits
        sta SCREEN_RAM+640+34
        stx SCREEN_RAM+640+35
        lda #COL_YELLOW
        sta COLOR_RAM+640+34
        sta COLOR_RAM+640+35
        rts

; ===========================================================================
; PAGE 1 : LA TRIFORCE DE LA SAGESSE (8 FRAGMENTS)
; ===========================================================================
draw_page_1_triforce:
        lda #0
        sta VIC_SPRITE_EN
        sta VIC_SPRITE_MSB

        ; Ligne 6 : Titre
        ldx #0
-       lda txt_p1_title,x
        sta SCREEN_RAM+240+5,x
        lda #COL_YELLOW
        sta COLOR_RAM+240+5,x
        inx
        cpx #30
        bne -

        ; Lignes 8..14 : Le Grand Triangle de la Triforce à 8 fragments
        jsr draw_triforce_triangle

        ; Ligne 16 : Compteur de fragments
        jsr draw_p1_counter

        ; Ligne 18 : Indicateurs de donjons [1] .. [8]
        jsr draw_p1_dungeons

        ; Ligne 20 : Statut légendaire
        jsr draw_p1_status
        rts

draw_triforce_triangle:
        ldx #0
-       lda txt_tri_l8,x
        sta SCREEN_RAM+320+8,x
        lda txt_tri_l9,x
        sta SCREEN_RAM+360+8,x
        lda txt_tri_l10,x
        sta SCREEN_RAM+400+8,x
        lda txt_tri_l11,x
        sta SCREEN_RAM+440+8,x
        lda txt_tri_l12,x
        sta SCREEN_RAM+480+8,x
        lda txt_tri_l13,x
        sta SCREEN_RAM+520+8,x
        lda txt_tri_l14,x
        sta SCREEN_RAM+560+8,x
        lda txt_tri_l15,x
        sta SCREEN_RAM+600+8,x

        lda #COL_YELLOW
        sta COLOR_RAM+320+8,x
        sta COLOR_RAM+360+8,x
        sta COLOR_RAM+400+8,x
        sta COLOR_RAM+440+8,x
        sta COLOR_RAM+480+8,x
        sta COLOR_RAM+520+8,x
        sta COLOR_RAM+560+8,x
        sta COLOR_RAM+600+8,x
        inx
        cpx #24
        bne -
        rts

draw_p1_counter:
        ; Compte les fragments possédés
        lda #0
        sta ZP_TMP
        lda player_triforce_pieces
        ldx #8
.count_bits:
        lsr
        bcc +
        inc ZP_TMP
+       dex
        bne .count_bits

        ldx #0
-       lda txt_p1_counter,x
        sta SCREEN_RAM+640+6,x
        lda #COL_WHITE
        sta COLOR_RAM+640+6,x
        inx
        cpx #28
        bne -

        lda #'0'
        clc
        adc ZP_TMP
        sta SCREEN_RAM+640+28
        lda #COL_YELLOW
        sta COLOR_RAM+640+28
        rts

draw_p1_dungeons:
        ldx #0
-       lda txt_p1_dungeons_line,x
        sta SCREEN_RAM+720+3,x
        lda #COL_WHITE
        sta COLOR_RAM+720+3,x
        inx
        cpx #34
        bne -

        ; Colorie chaque donjon selon possession
        ldx #0
.dungeon_col_loop:
        txa
        tay
        lda #1
.shift_bit:
        cpy #0
        beq .got_mask
        asl
        dey
        jmp .shift_bit
.got_mask:
        and player_triforce_pieces
        beq .missing_dungeon

        lda #COL_YELLOW
        jmp .apply_dcol
.missing_dungeon:
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
        sta COLOR_RAM+720+3,y
        iny
        sta COLOR_RAM+720+3,y
        iny
        sta COLOR_RAM+720+3,y

        inx
        cpx #8
        bne .dungeon_col_loop
        rts

draw_p1_status:
        lda player_triforce_pieces
        cmp #$ff
        beq .complete
        ldx #0
-       lda txt_p1_msg_seek,x
        sta SCREEN_RAM+800+2,x
        lda #COL_CYAN
        sta COLOR_RAM+800+2,x
        inx
        cpx #36
        bne -
        rts
.complete:
        ldx #0
-       lda txt_p1_msg_full,x
        sta SCREEN_RAM+800+2,x
        lda #COL_YELLOW
        sta COLOR_RAM+800+2,x
        inx
        cpx #36
        bne -
        rts

; ===========================================================================
; PAGE 2 : EQUIPEMENT PERMANENT & RELIQUES HEROIQUES
; ===========================================================================
draw_page_2_equipment:
        ; Sprites pour l'arsenal visuel de Link (Sprite 0: Épée, Sprite 1: Bouclier, Sprite 2: Bague)
        lda #(sprite_link_sword_up / 64)
        sta SPRITE_PTR0
        lda #(sprite_link_item_shield / 64)
        sta SPRITE_PTR1
        lda #(sprite_link_item_ring / 64)
        sta SPRITE_PTR2

        lda #COL_WHITE
        sta VIC_SPRITE_COL0
        lda #COL_BLUE
        sta VIC_SPRITE_COL1
        lda #COL_CYAN
        sta VIC_SPRITE_COL2

        lda #42
        sta VIC_SPRITE_X0
        sta VIC_SPRITE_X1
        sta VIC_SPRITE_X2

        lda #116
        sta VIC_SPRITE_Y0
        lda #142
        sta VIC_SPRITE_Y1
        lda #168
        sta VIC_SPRITE_Y2

        lda #0
        sta VIC_SPRITE_MSB
        lda #%00000111                  ; Sprites 0, 1, 2
        sta VIC_SPRITE_EN
        sta VIC_SPRITE_MC

        ; Ligne 6 : Titre
        ldx #0
-       lda txt_p2_title,x
        sta SCREEN_RAM+240+2,x
        lda #COL_YELLOW
        sta COLOR_RAM+240+2,x
        inx
        cpx #36
        bne -

        ; --- COLONNE GAUCHE (Cols 6..20) : ARSENAL ---
        ; Épée
        ldx #0
-       lda txt_p2_lbl_sword,x
        sta SCREEN_RAM+320+6,x
        lda #COL_WHITE
        sta COLOR_RAM+320+6,x
        inx
        cpx #15
        bne -

        jsr draw_p2_sword_val

        ; Bouclier
        ldx #0
-       lda txt_p2_lbl_shield,x
        sta SCREEN_RAM+440+6,x
        lda #COL_WHITE
        sta COLOR_RAM+440+6,x
        inx
        cpx #15
        bne -

        jsr draw_p2_shield_val

        ; Protection
        ldx #0
-       lda txt_p2_lbl_ring,x
        sta SCREEN_RAM+560+6,x
        lda #COL_WHITE
        sta COLOR_RAM+560+6,x
        inx
        cpx #15
        bne -

        jsr draw_p2_ring_val

        ; Vitalité
        ldx #0
-       lda txt_p2_lbl_life,x
        sta SCREEN_RAM+680+6,x
        lda #COL_WHITE
        sta COLOR_RAM+680+6,x
        inx
        cpx #15
        bne -

        jsr draw_p2_life_val

        ; --- COLONNE DROITE (Cols 22..38) : RELIQUES HEROIQUES ---
        ldx #0
-       lda txt_p2_lbl_relics,x
        sta SCREEN_RAM+320+22,x
        lda #COL_YELLOW
        sta COLOR_RAM+320+22,x
        inx
        cpx #17
        bne -

        ; Bracelet (Ligne 9)
        ldx #0
-       lda txt_p2_lbl_bracelet,x
        sta SCREEN_RAM+360+22,x
        lda #COL_WHITE
        sta COLOR_RAM+360+22,x
        inx
        cpx #14
        bne -

        lda player_has_bracelet
        jsr draw_p2_relic_inline
        sta SCREEN_RAM+360+37
        stx SCREEN_RAM+360+38
        sty COLOR_RAM+360+37
        sty COLOR_RAM+360+38

        ; Radeau (Ligne 11)
        ldx #0
-       lda txt_p2_lbl_raft,x
        sta SCREEN_RAM+440+22,x
        lda #COL_WHITE
        sta COLOR_RAM+440+22,x
        inx
        cpx #15
        bne -

        lda player_has_raft
        jsr draw_p2_relic_inline
        sta SCREEN_RAM+440+37
        stx SCREEN_RAM+440+38
        sty COLOR_RAM+440+37
        sty COLOR_RAM+440+38

        ; Échelle (Ligne 13)
        ldx #0
-       lda txt_p2_lbl_ladder,x
        sta SCREEN_RAM+520+22,x
        lda #COL_WHITE
        sta COLOR_RAM+520+22,x
        inx
        cpx #13
        bne -

        lda player_has_stepladder
        jsr draw_p2_relic_inline
        sta SCREEN_RAM+520+37
        stx SCREEN_RAM+520+38
        sty COLOR_RAM+520+37
        sty COLOR_RAM+520+38

        ; Passe-partout (Ligne 15)
        ldx #0
-       lda txt_p2_lbl_key,x
        sta SCREEN_RAM+600+22,x
        lda #COL_WHITE
        sta COLOR_RAM+600+22,x
        inx
        cpx #12
        bne -

        lda player_has_magic_key
        jsr draw_p2_relic_inline
        sta SCREEN_RAM+600+37
        stx SCREEN_RAM+600+38
        sty COLOR_RAM+600+37
        sty COLOR_RAM+600+38

        ; Ligne 19 : Séparateur
        ldx #0
-       lda #'-'
        sta SCREEN_RAM+760+2,x
        lda #COL_BLUE
        sta COLOR_RAM+760+2,x
        inx
        cpx #36
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

draw_p2_sword_val:
        lda player_has_sword
        bne +
        ldx #0
-       lda txt_p2_sword_0,x
        sta SCREEN_RAM+360+6,x
        lda #COL_DARK_GREY
        sta COLOR_RAM+360+6,x
        inx
        cpx #15
        bne -
        rts
+       cmp #1
        bne +
        ldx #0
-       lda txt_p2_sword_1,x
        sta SCREEN_RAM+360+6,x
        lda #COL_BROWN
        sta COLOR_RAM+360+6,x
        inx
        cpx #15
        bne -
        rts
+       cmp #2
        bne +
        ldx #0
-       lda txt_p2_sword_2,x
        sta SCREEN_RAM+360+6,x
        lda #COL_WHITE
        sta COLOR_RAM+360+6,x
        inx
        cpx #15
        bne -
        rts
+       ldx #0
-       lda txt_p2_sword_3,x
        sta SCREEN_RAM+360+6,x
        lda #COL_CYAN
        sta COLOR_RAM+360+6,x
        inx
        cpx #15
        bne -
        rts

draw_p2_shield_val:
        lda player_has_shield
        cmp #2
        bcs .mag_shield
        ldx #0
-       lda txt_p2_shield_1,x
        sta SCREEN_RAM+480+6,x
        lda #COL_BROWN
        sta COLOR_RAM+480+6,x
        inx
        cpx #15
        bne -
        rts
.mag_shield:
        ldx #0
-       lda txt_p2_shield_2,x
        sta SCREEN_RAM+480+6,x
        lda #COL_LIGHT_RED
        sta COLOR_RAM+480+6,x
        inx
        cpx #15
        bne -
        rts

draw_p2_ring_val:
        lda player_has_blue_ring
        bne .blue_ring
        ldx #0
-       lda txt_p2_ring_0,x
        sta SCREEN_RAM+600+6,x
        lda #COL_GREEN
        sta COLOR_RAM+600+6,x
        inx
        cpx #15
        bne -
        rts
.blue_ring:
        ldx #0
-       lda txt_p2_ring_1,x
        sta SCREEN_RAM+600+6,x
        lda #COL_CYAN
        sta COLOR_RAM+600+6,x
        inx
        cpx #15
        bne -
        rts

draw_p2_life_val:
        lda hud_max_hearts
        jsr print_2digits
        sta SCREEN_RAM+720+6
        stx SCREEN_RAM+720+7
        ldx #0
-       lda txt_p2_life_sfx,x
        sta SCREEN_RAM+720+8,x
        lda #COL_LIGHT_RED
        sta COLOR_RAM+720+6,x
        sta COLOR_RAM+720+7,x
        sta COLOR_RAM+720+8,x
        inx
        cpx #13
        bne -
        rts

draw_p2_relic_inline:
        bne .has_relic_inline
        lda #'-'
        ldx #'-'
        ldy #COL_DARK_GREY
        rts
.has_relic_inline:
        lda #'O'
        ldx #'K'
        ldy #COL_YELLOW
        rts

; ===========================================================================
; PAGE 3 : CARTE DU MONDE 16x8
; ===========================================================================
draw_page_3_map:
        lda #0
        sta VIC_SPRITE_EN
        sta VIC_SPRITE_MSB

        ; Ligne 5 : Colonnes A..P
        ldx #0
.put_col_letters:
        txa
        clc
        adc #'A'
        tay
        txa
        asl
        tax
        tya
        sta SCREEN_RAM+200+4,x
        lda #' '
        sta SCREEN_RAM+200+5,x
        lda #COL_WHITE
        sta COLOR_RAM+200+4,x
        sta COLOR_RAM+200+5,x
        txa
        lsr
        tax
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

        txa
        clc
        adc #'1'
        ldy #0
        sta (ZP_SCR),y
        lda #COL_WHITE
        sta (ZP_COL),y

        lda #'|'
        ldy #2
        sta (ZP_SCR),y
        ldy #36
        sta (ZP_SCR),y
        lda #COL_BLUE
        ldy #2
        sta (ZP_COL),y
        ldy #36
        sta (ZP_COL),y

        lda #0
        sta map_rx
.col_loop:
        ldx map_ry
        lda world_row_offset,x
        clc
        adc map_rx
        tax

        lda map_rx
        cmp current_room_x
        bne .check_visited
        lda map_ry
        cmp current_room_y
        bne .check_visited

        ; Link
        lda #HUD_MAP_ACTIVE
        sta ZP_TMP
        sta ZP_TMP+1
        lda #COL_YELLOW
        sta ZP_BASE
        jmp .render_cell

.check_visited:
        lda visited_rooms,x
        beq .cell_unseen

        lda #HUD_MAP_VISITED
        sta ZP_TMP
        sta ZP_TMP+1
        lda #COL_LIGHT_GREEN
        sta ZP_BASE
        jmp .render_cell

.cell_unseen:
        lda #HUD_MAP_EMPTY
        sta ZP_TMP
        lda #' '
        sta ZP_TMP+1
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
        lda ZP_TMP+1
        sta (ZP_SCR),y
        lda ZP_BASE
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
        ; Ligne 17 : Coordonnées
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
        sta SCREEN_RAM+680+19
        lda #'1'
        clc
        adc current_room_y
        sta SCREEN_RAM+680+21
        lda #COL_YELLOW
        sta COLOR_RAM+680+19
        sta COLOR_RAM+680+20
        sta COLOR_RAM+680+21

        lda current_room_x
        jsr print_2digits
        sta SCREEN_RAM+680+27
        stx SCREEN_RAM+680+28
        lda #COL_YELLOW
        sta COLOR_RAM+680+27
        sta COLOR_RAM+680+28

        lda current_room_y
        jsr print_2digits
        sta SCREEN_RAM+680+33
        stx SCREEN_RAM+680+34
        lda #COL_YELLOW
        sta COLOR_RAM+680+33
        sta COLOR_RAM+680+34

        ; Ligne 19 : Exploration
        ldx #0
-       lda txt_expl_line,x
        sta SCREEN_RAM+760+2,x
        lda #COL_WHITE
        sta COLOR_RAM+760+2,x
        inx
        cpx #36
        bne -

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
        sta SCREEN_RAM+760+14
        lda ZP_TMP
        sta SCREEN_RAM+760+15
        lda ZP_TMP+1
        sta SCREEN_RAM+760+16

        lda #COL_YELLOW
        sta COLOR_RAM+760+14
        sta COLOR_RAM+760+15
        sta COLOR_RAM+760+16

        ; Ligne 21 : Légende
        ldx #0
-       lda txt_legend_line,x
        sta SCREEN_RAM+840+2,x
        lda #COL_WHITE
        sta COLOR_RAM+840+2,x
        inx
        cpx #36
        bne -

        lda #HUD_MAP_ACTIVE
        sta SCREEN_RAM+840+11
        sta SCREEN_RAM+840+12
        lda #COL_YELLOW
        sta COLOR_RAM+840+11
        sta COLOR_RAM+840+12

        lda #HUD_MAP_VISITED
        sta SCREEN_RAM+840+20
        sta SCREEN_RAM+840+21
        lda #COL_LIGHT_GREEN
        sta COLOR_RAM+840+20
        sta COLOR_RAM+840+21

        lda #HUD_MAP_EMPTY
        sta SCREEN_RAM+840+27
        lda #COL_DARK_GREY
        sta COLOR_RAM+840+27
        rts

draw_map_borders:
        lda #'+'
        sta SCREEN_RAM+240+2
        sta SCREEN_RAM+240+36
        sta SCREEN_RAM+600+2
        sta SCREEN_RAM+600+36
        lda #COL_BLUE
        sta COLOR_RAM+240+2
        sta COLOR_RAM+240+36
        sta COLOR_RAM+600+2
        sta COLOR_RAM+600+36
        ldx #0
-       lda #'-'
        sta SCREEN_RAM+240+3,x
        sta SCREEN_RAM+600+3,x
        lda #COL_BLUE
        sta COLOR_RAM+240+3,x
        sta COLOR_RAM+600+3,x
        inx
        cpx #33
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
; TEXTES DU MENU D'INVENTAIRE EN 4 PAGES
; ===========================================================================

; En-têtes d'onglets (exactement 40 caractères chacun)
txt_tabs_p0:        !text "[1:OBJETS] 2:TRIFORCE  3:EQUIP  4:CARTE "
txt_tabs_p1:        !text " 1:OBJETS [2:TRIFORCE] 3:EQUIP  4:CARTE "
txt_tabs_p2:        !text " 1:OBJETS  2:TRIFORCE [3:EQUIP] 4:CARTE "
txt_tabs_p3:        !text " 1:OBJETS  2:TRIFORCE  3:EQUIP [4:CARTE]"

txt_footer_help:    !text " [JOY] CHOIX   [1-4] ONGLET   [B] RETOUR "

; Textes Page 0
txt_box_small:      !text "+------+"
txt_box_p0_grid:    !text "+----------------------+"
txt_p0_active:      !text "OBJET  B"
txt_p0_slot_b:      !text "EQUIPE  "
txt_p0_items_r1:    !text "BOOM    BOMB    ARC "
txt_p0_items_r2:    !text "BOUG    VIAN    POTI"
txt_p0_stock_line:  !text "RUBIS:      CLEFS:      BOMBES:     "
txt_p0_tip:         !text "[GAUCHE/DROITE] CHOISIR  [A] EQUIPER"

; Descriptifs des 6 armes (exactement 36 caractères)
p0_desc_lo:
        !byte <desc_boom, <desc_bomb, <desc_bow, <desc_cand, <desc_food, <desc_potion
p0_desc_hi:
        !byte >desc_boom, >desc_bomb, >desc_bow, >desc_cand, >desc_food, >desc_potion

desc_boom:          !text "BOOMERANG (ETOURDIT LES ENNEMIS)    ", 0
desc_bomb:          !text "BOMBES (EXPLOSIONS ET DEBRIS)       ", 0
desc_bow:           !text "ARC ET FLECHES (ATTAQUE A DISTANCE) ", 0
desc_cand:          !text "BOUGIE BLEUE (FLAMMES ET SECRETS)   ", 0
desc_food:          !text "APPAT (ATTRACTEUR POUR MONSTRES)    ", 0
desc_potion:        !text "POTION DE VIE (RESTAURE LES COEURS) ", 0

; Textes Page 1 (Triforce)
txt_p1_title:       !text "  LA TRIFORCE DE LA SAGESSE   "
txt_tri_l8:         !text "           /\\           "
txt_tri_l9:         !text "          /  \\          "
txt_tri_l10:        !text "         / 12 \\         "
txt_tri_l11:        !text "        /------\\        "
txt_tri_l12:        !text "       /\\ 3  4 /\\       "
txt_tri_l13:        !text "      / 5\\ /\\ /6 \\      "
txt_tri_l14:        !text "     / 7 \\/--\\/ 8 \\     "
txt_tri_l15:        !text "    /--------------\\    "
txt_p1_counter:     !text "FRAGMENTS RECUPERES : 0 / 8 "
txt_p1_dungeons_line: !text "DONJONS: [1][2][3][4][5][6][7][8] "
txt_p1_msg_seek:    !text "CHERCHE LES FRAGMENTS DANS LES DONJ."
txt_p1_msg_full:    !text "LA TRIFORCE EST TOTALEMENT REUNIE ! "

; Textes Page 2 (Équipement)
txt_p2_title:       !text "ARSENAL DE LINK & RELIQUES DE QUETE "
txt_p2_lbl_sword:   !text "EPEE COURANTE :"
txt_p2_sword_0:     !text "SANS EPEE      "
txt_p2_sword_1:     !text "EPEE DE BOIS   "
txt_p2_sword_2:     !text "EPEE BLANCHE   "
txt_p2_sword_3:     !text "EPEE MAGIQUE   "

txt_p2_lbl_shield:  !text "BOUCLIER ACTIF:"
txt_p2_shield_1:    !text "PETIT BOUCLIER "
txt_p2_shield_2:    !text "BOUCLIER MAGIQ."

txt_p2_lbl_ring:    !text "TUNIQUE / RANG:"
txt_p2_ring_0:      !text "TUNIQUE VERTE  "
txt_p2_ring_1:      !text "ANNEAU BLEU (/2)"

txt_p2_lbl_life:    !text "VITALITE MAX : "
txt_p2_life_sfx:    !text " / 16 COEURS "

txt_p2_lbl_relics:  !text "RELIQUES HEROES  "
txt_p2_lbl_bracelet:!text "BRACELET FORCE"
txt_p2_lbl_raft:    !text "RADEAU DES MERS"
txt_p2_lbl_ladder:  !text "ECHELLE D'EAU "
txt_p2_lbl_key:     !text "CLEF MAGIQUE  "
txt_p2_tip:         !text "LES EQUIPEMENTS RESTENT ACQUIS A VIE"

; Textes Page 3 (Carte du Monde)
txt_room_line:      !text "SALLE COURANTE : A-1  (X:  , Y:  )  "
txt_expl_line:      !text "EXPLOREES :    0 / 128 SALLES       "
txt_legend_line:    !text "LEGENDE:    LINK     VU    - INCONNU"
