; ---------------------------------------------------------------------------
; inventory_draw.asm : Affichage graphique du menu d'inventaire en 4 pages
;   Page 0 : [1:OBJETS]     - Sélection Slot B (6 objets, descriptif, stock)
;   Page 1 : [2:TRIFORCE]   - La Triforce de la Sagesse (8 fragments numérotés)
;   Page 2 : [3:EQUIPEMENT] - Équipement permanent (Épées, Boucliers, Anneau, Reliques)
;   Page 3 : [4:CARTE]      - Carte du Monde 16x8 (128 salles, Link clignotant)
; ---------------------------------------------------------------------------

!zone inventory_draw

; Tables des sprites et couleurs des 8 armes sélectionnables (Slot B)
item_sprite_ptrs:
        !byte (sprite_link_item_boomerang / 64)
        !byte (sprite_link_item_bomb / 64)
        !byte (sprite_link_item_bow / 64)
        !byte (sprite_link_item_candle / 64)
        !byte (sprite_link_item_food / 64)
        !byte (sprite_link_item_potion / 64)
        !byte (sprite_link_item_whistle / 64)
        !byte (sprite_link_item_wand / 64)

item_colors:
        !byte COL_LIGHT_BLUE            ; 0: Boomerang
        !byte COL_BLUE                  ; 1: Bombe
        !byte COL_WHITE                 ; 2: Arc & Flèche
        !byte COL_LIGHT_BLUE            ; 3: Bougie
        !byte COL_BROWN                 ; 4: Viande / Appât
        !byte COL_RED                   ; 5: Potion
        !byte COL_YELLOW                ; 6: Flûte
        !byte COL_LIGHT_BLUE            ; 7: Baguette Magique

; Coordonnées X des 8 objets (2 rangées de 4 colonnes)
cursor_x_coords:
        !byte 148, 178, 208, 238        ; rangée 1 : Boomerang, Bombe, Arc, Bougie
        !byte 148, 178, 208, 238        ; rangée 2 : Viande, Potion, Flûte, Baguette

cursor_y_coords:
        !byte 106, 106, 106, 106        ; rangée 1
        !byte 134, 134, 134, 134        ; rangée 2

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
; PAGE 0 : OBJETS ACTIFS DU SLOT B
; ===========================================================================
draw_page_0_items:
        ; 1. Boîte Arme équipée (Cols 3..10, Lignes 6..11)
        ldx #7
-       lda txt_box_small,x
        sta SCREEN_RAM+240+3,x
        sta SCREEN_RAM+440+3,x
        lda #COL_BLUE
        sta COLOR_RAM+240+3,x
        sta COLOR_RAM+440+3,x
        dex
        bpl -

        ; 2. Boîte des 8 Objets sélectionnables (Cols 14..30, Lignes 6..12)
        ldx #16
-       lda txt_box_p0_grid,x
        sta SCREEN_RAM+240+14,x
        sta SCREEN_RAM+480+14,x
        lda #COL_BLUE
        sta COLOR_RAM+240+14,x
        sta COLOR_RAM+480+14,x
        dex
        bpl -

        ; Bordures verticales pour les deux boîtes
        ldx #0
.v_p0_loop:
        lda p0_v_scr_lo,x
        sta ZP_SCR
        sta ZP_COL
        lda p0_v_scr_hi,x
        jsr inv_set_scr_col_hi

        lda #164
        ldy p0_v_c1,x
        sta (ZP_SCR),y
        ldy p0_v_c2,x
        sta (ZP_SCR),y
        lda #COL_BLUE
        ldy p0_v_c1,x
        sta (ZP_COL),y
        ldy p0_v_c2,x
        sta (ZP_COL),y
        inx
        cpx #9
        bne .v_p0_loop

        ; En-têtes Ligne 5 (EQUIPE & ARSENAL)
        ldx #5
-       lda txt_p0_equipe,x
        sta SCREEN_RAM+200+4,x
        lda #COL_YELLOW
        sta COLOR_RAM+200+4,x
        dex
        bpl -
        ldx #6
-       lda txt_p0_arsenal,x
        sta SCREEN_RAM+200+19,x
        lda #COL_YELLOW
        sta COLOR_RAM+200+19,x
        dex
        bpl -

        ; Labels Arme active
        ldx #7
-       lda txt_p0_active,x
        sta SCREEN_RAM+480+3,x
        lda #COL_WHITE
        sta COLOR_RAM+480+3,x
        lda txt_p0_slot_b,x
        sta SCREEN_RAM+520+3,x
        lda #COL_CYAN
        sta COLOR_RAM+520+3,x
        dex
        bpl -
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
        lda #0
        sta VIC_SPRITE_EXP_X
        sta VIC_SPRITE_EXP_Y
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

        ; Initialise la rangée 1 pour le démarrage
        jsr inv_p0_irq_row1

        ; Sprite 7 : Curseur cadre de sélection (clignotant)
        lda #(sprite_link_item_frame / 64)
        sta SPRITE_PTR7
        lda #COL_YELLOW
        sta VIC_SPRITE_COL7

        jsr inv_update_cursor

        lda #0
        sta VIC_SPRITE_MSB
        lda #%10011111                  ; Sprites 0, 1, 2, 3, 4, 7 actifs
        sta VIC_SPRITE_EN
        lda #%00011111                  ; Sprites 0..4 multicolores, Sprite 7 haute résolution
        sta VIC_SPRITE_MC
        rts

p0_v_scr_lo:
        !byte <280, <320, <360, <400
        !byte <280, <320, <360, <400, <440
p0_v_scr_hi:
        !byte >280, >320, >360, >400
        !byte >280, >320, >360, >400, >440
p0_v_c1:
        !byte 3, 3, 3, 3
        !byte 14, 14, 14, 14, 14
p0_v_c2:
        !byte 10, 10, 10, 10
        !byte 30, 30, 30, 30, 30

; ---------------------------------------------------------------------------
; Multiplexeur raster pour la Page 0 de l'inventaire (grille 4x2 d'objets)
; ---------------------------------------------------------------------------
inv_p0_irq_row1:
        ; Sprites 1..4 (Rangée 1) : Boomerang, Bombe, Arc, Bougie (Y=106)
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

        lda #148
        sta VIC_SPRITE_X1
        lda #178
        sta VIC_SPRITE_X2
        lda #208
        sta VIC_SPRITE_X3
        lda #238
        sta VIC_SPRITE_X4

        lda #106
        sta VIC_SPRITE_Y1
        sta VIC_SPRITE_Y2
        sta VIC_SPRITE_Y3
        sta VIC_SPRITE_Y4
        rts

irq_p0_row2:
        ; Sprites 1..4 (Rangée 2) : Viande, Potion, Flûte, Baguette (Y=134)
        lda #(sprite_link_item_food / 64)
        sta SPRITE_PTR1
        lda #(sprite_link_item_potion / 64)
        sta SPRITE_PTR2
        lda #(sprite_link_item_whistle / 64)
        sta SPRITE_PTR3
        lda #(sprite_link_item_wand / 64)
        sta SPRITE_PTR4

        lda #COL_BROWN
        sta VIC_SPRITE_COL1
        lda #COL_RED
        sta VIC_SPRITE_COL2
        lda #COL_YELLOW
        sta VIC_SPRITE_COL3
        lda #COL_LIGHT_BLUE
        sta VIC_SPRITE_COL4

        lda #148
        sta VIC_SPRITE_X1
        lda #178
        sta VIC_SPRITE_X2
        lda #208
        sta VIC_SPRITE_X3
        lda #238
        sta VIC_SPRITE_X4

        lda #134
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
        sta SCREEN_RAM+640,y
        txa
        iny
        sta SCREEN_RAM+640,y
        lda #COL_YELLOW
        sta COLOR_RAM+640,y
        dey
        sta COLOR_RAM+640,y
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
        lda #<txt_tri_all
        sta ZP_SRC
        lda #>txt_tri_all
        sta ZP_SRC+1
        lda #<(SCREEN_RAM+328)
        sta ZP_DST
        lda #>(SCREEN_RAM+328)
        sta ZP_DST+1

        ldx #8
.tri_row:
        lda ZP_DST
        sta ZP_COL
        lda ZP_DST+1
        clc
        adc #($d8 - $04)
        sta ZP_COL+1

        ldy #23
-       lda (ZP_SRC),y
        sta (ZP_DST),y
        lda #COL_YELLOW
        sta (ZP_COL),y
        dey
        bpl -

        clc
        lda ZP_SRC
        adc #24
        sta ZP_SRC
        lda ZP_SRC+1
        adc #0
        sta ZP_SRC+1

        clc
        lda ZP_DST
        adc #40
        sta ZP_DST
        lda ZP_DST+1
        adc #0
        sta ZP_DST+1

        dex
        bne .tri_row
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
        lda bit_powers,x
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
        lda #<txt_p1_msg_seek
        ldx #>txt_p1_msg_seek
        ldy #COL_CYAN
        lda player_triforce_pieces
        cmp #$ff
        bne +
        lda #<txt_p1_msg_full
        ldx #>txt_p1_msg_full
        ldy #COL_YELLOW
+       sta ZP_SRC
        stx ZP_SRC+1
        sty ZP_BASE

        ldy #35
-       lda (ZP_SRC),y
        sta SCREEN_RAM+800+2,y
        lda ZP_BASE
        sta COLOR_RAM+800+2,y
        dey
        bpl -
        rts

; ===========================================================================
; PAGE 2 : EQUIPEMENT PERMANENT & RELIQUES HEROIQUES
; ===========================================================================
draw_page_2_equipment:
        ; Désactive l'agrandissement pour des sprites nets et non déformés
        lda #0
        sta VIC_SPRITE_EXP_X
        sta VIC_SPRITE_EXP_Y
        sta VIC_SPRITE_MSB

        ; Configuration multicolore des 8 sprites
        lda #PLAYER_SKIN
        sta VIC_SPRITE_MC1
        lda #COL_WHITE
        sta VIC_SPRITE_MC2
        lda #%11111111
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

        ; Tracé des 8 boîtes visuelles
        jsr draw_p2_boxes

        ; Configuration des 8 sprites et de leurs statuts
        jsr setup_p2_slots

        ; Ligne 20 : Séparateur
        ldx #0
-       lda #'-'
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

; ---------------------------------------------------------------------------
; draw_p2_boxes : trace les 8 cadres de l'arsenal
; ---------------------------------------------------------------------------
draw_p2_boxes:
        ldx #0
.box_loop:
        lda p2_box_offs_lo,x
        sta ZP_SCR
        sta ZP_COL
        lda p2_box_offs_hi,x
        jsr inv_set_scr_col_hi

        ; Coins '+'
        lda #'+'
        ldy #0
        sta (ZP_SCR),y
        ldy #5
        sta (ZP_SCR),y
        ldy #120
        sta (ZP_SCR),y
        ldy #125
        sta (ZP_SCR),y

        ; Horizontales '-'
        lda #'-'
        ldy #1
-       sta (ZP_SCR),y
        iny
        cpy #5
        bne -
        ldy #121
-       sta (ZP_SCR),y
        iny
        cpy #125
        bne -

        ; Verticales (barre char 164)
        lda #164
        ldy #40
        sta (ZP_SCR),y
        ldy #45
        sta (ZP_SCR),y
        ldy #80
        sta (ZP_SCR),y
        ldy #85
        sta (ZP_SCR),y

        ; Couleur bleue pour le cadre
        lda #COL_BLUE
        ldy #0
-       sta (ZP_COL),y
        iny
        cpy #6
        bne -
        ldy #120
-       sta (ZP_COL),y
        iny
        cpy #126
        bne -
        ldy #40
        sta (ZP_COL),y
        ldy #45
        sta (ZP_COL),y
        ldy #80
        sta (ZP_COL),y
        ldy #85
        sta (ZP_COL),y

        inx
        cpx #8
        bne .box_loop
        rts

p2_box_offs_lo:
        !byte <(280+3), <(280+11), <(280+19), <(280+27)
        !byte <(520+3), <(520+11), <(520+19), <(520+27)
p2_box_offs_hi:
        !byte >(280+3), >(280+11), >(280+19), >(280+27)
        !byte >(520+3), >(520+11), >(520+19), >(520+27)

; ---------------------------------------------------------------------------
; setup_p2_slots : initialise les sprites et textes pour chaque objet
; ---------------------------------------------------------------------------
setup_p2_slots:
        lda #0
        sta ZP_TMP                      ; masque VIC_SPRITE_EN

        ; Positions fixes des 8 sprites matériels
        lda #60
        sta VIC_SPRITE_X0
        sta VIC_SPRITE_X4
        lda #124
        sta VIC_SPRITE_X1
        sta VIC_SPRITE_X5
        lda #188
        sta VIC_SPRITE_X2
        sta VIC_SPRITE_X6
        lda #252
        sta VIC_SPRITE_X3
        sta VIC_SPRITE_X7

        lda #108
        sta VIC_SPRITE_Y0
        sta VIC_SPRITE_Y1
        sta VIC_SPRITE_Y2
        sta VIC_SPRITE_Y3
        lda #156
        sta VIC_SPRITE_Y4
        sta VIC_SPRITE_Y5
        sta VIC_SPRITE_Y6
        sta VIC_SPRITE_Y7

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

        ; --- Slot 0 : Épée (Sprite 0, Col 3, Ligne 12) ---
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
        lda #(sprite_link_sword_up / 64)
        sta SPRITE_PTR0
        ldx player_has_sword
        lda p2_sword_colors,x
        sta VIC_SPRITE_COL0

        ; Offset = (sword-1) * 6
        dex
        txa
        asl
        sta .p2_tmp_val
        asl
        clc
        adc .p2_tmp_val                 ; A = (sword-1)*6
        clc
        adc #<p2_sword_status
        sta ZP_SRC
        lda #>p2_sword_status
        adc #0
        sta ZP_SRC+1
        lda #COL_YELLOW
        jsr p2_print_status

.p2_slot1:
        ; --- Slot 1 : Bouclier (Sprite 1, Col 11) ---
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
        ; --- Slot 2 : Anneau (Sprite 2, Col 19) ---
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
        ldx #0                          ; index 0..4 (correspond aux slots 3..7)
.p2_simp_loop:
        stx .p2_cur_idx

        ; Positionnement du pointeur écran pour ce slot (X = idx + 3)
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

; Helpers d'affichage pour la page 2
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
        !byte (sprite_link_item_ring / 64)
        !byte (sprite_link_item_food / 64)
        !byte (sprite_link_item_wand / 64)
        !byte (sprite_link_item_key / 64)
        !byte (sprite_link_item_wand / 64)
p2_simple_col:
        !byte COL_YELLOW, COL_BROWN, COL_BROWN, COL_YELLOW, COL_LIGHT_BLUE

p2_name_offs_lo:
        !byte <(440+3), <(440+11), <(440+19), <(440+27)
        !byte <(680+3), <(680+11), <(680+19), <(680+27)
p2_name_offs_hi:
        !byte >(440+3), >(440+11), >(440+19), >(440+27)
        !byte >(680+3), >(680+11), >(680+19), >(680+27)

p2_stat_offs_lo:
        !byte <(480+3), <(480+11), <(480+19), <(480+27)
        !byte <(720+3), <(720+11), <(720+19), <(720+27)
p2_stat_offs_hi:
        !byte >(480+3), >(480+11), >(480+19), >(480+27)
        !byte >(720+3), >(720+11), >(720+19), >(720+27)

p2_sword_colors:    !byte COL_DARK_GREY, COL_BROWN, COL_WHITE, COL_CYAN
p2_sword_status:    !text " BOIS BLANC MAGIQ "
p2_shield_status:   !text " PETIT MAGIQ "
p2_ring_status:     !text " BLEU  ROUGE "

txt_all_slot_names: !text " EPEE BOUCL.ANNEAUBRACELRADEAUECHEL. CLEF  LIVRE"
txt_p2_empty:       !text "[VIDE]"
txt_p2_acquired:    !text "ACQUIS"

; ===========================================================================
; PAGE 3 : CARTE (OVERWORLD OU DONJON DYNAMIQUE)
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

        txa
        clc
        adc #'1'
        ldy #0
        sta (ZP_SCR),y
        lda #COL_WHITE
        sta (ZP_COL),y

        lda #164
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

; ---------------------------------------------------------------------------
; draw_page_3_dungeon_map : affiche la carte officielle du donjon en cours
; ---------------------------------------------------------------------------
draw_page_3_dungeon_map:
        ; Ligne 5 : Titre du Donjon (Ex: "DONJON N1 : AIGLE")
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
        lda #'+'
        sta SCREEN_RAM+240+11
        sta SCREEN_RAM+240+28
        sta SCREEN_RAM+600+11
        sta SCREEN_RAM+600+28
        lda #COL_BLUE
        sta COLOR_RAM+240+11
        sta COLOR_RAM+240+28
        sta COLOR_RAM+600+11
        sta COLOR_RAM+600+28
        ldx #0
-       lda #'-'
        sta SCREEN_RAM+240+12,x
        sta SCREEN_RAM+600+12,x
        lda #COL_BLUE
        sta COLOR_RAM+240+12,x
        sta COLOR_RAM+600+12,x
        inx
        cpx #16
        bne -

        ; Lignes 7..14 : 8 rangées de salles (8 colonnes chacune)
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

        ; Bordures verticales colonnes 11 et 28
        lda #164
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
        sta map_rx                      ; rel_rx (0..7)
.d_col_loop:
        ; Calcule colonne réelle = dung_bank_x + rel_rx
        ldy current_dungeon_level
        dey
        cpy #9
        bcc +
        ldy #0
+       lda dung_bank_x,y
        clc
        adc map_rx
        sta ZP_TMP                      ; col réelle

        ; Calcule index de salle = map_ry * 16 + col
        lda map_ry
        asl
        asl
        asl
        asl
        clc
        adc ZP_TMP
        tax                             ; X = index salle 0..127

        ; Vérifie si la salle existe dans ce donjon ($C016,x != $C016)
        lda $c016,x
        cmp $c016
        beq .d_no_room

        ; La salle existe : est-elle révélée ?
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
        ; 1. Link dans cette salle ?
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
        ; 2. Salle Triforce avec Boussole ?
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
        ; Salle normale explorée
        lda #HUD_MAP_VISITED
        sta ZP_TMP
        sta ZP_TMP+1
        lda #COL_CYAN
        sta ZP_BASE

.d_put_cell:
        lda map_rx                      ; rel_rx (0..7)
        asl
        clc
        adc #12                         ; Colonnes 12, 14, 16..26
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

        ; Légende élégante centrée (Ligne 17)
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

txt_dtitle_pref:    !text "DONJON N1 : ", 0
p3_d1:  !text "AIGLE", 0
p3_d2:  !text "LUNE", 0
p3_d3:  !text "MANJI", 0
p3_d4:  !text "GNOU", 0
p3_d5:  !text "LEZARD", 0
p3_d6:  !text "DRAGON", 0
p3_d7:  !text "DEMON", 0
p3_d8:  !text "LION", 0
p3_d9:  !text "M. DE LA MORT", 0

txt_dung_legend:
        !byte HUD_MAP_ACTIVE
        !text " TRIFORCE  "
        !byte HUD_MAP_ACTIVE
        !text " LINK  "
        !byte HUD_MAP_VISITED
        !text " VISITE", 0

txt_dung_leg_col:
        !byte COL_LIGHT_RED
        !fill 11, COL_WHITE
        !byte COL_YELLOW
        !fill 7, COL_WHITE
        !byte COL_CYAN
        !fill 7, COL_WHITE
        !byte 0

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

; En-tête d'onglets unique et tables d'encadrement
txt_tabs_base:      !text " 1:OBJETS  2:TRIFORCE  3:EQUIP  4:CARTE "
tab_bracket_pos:    !byte 0, 9,  10, 21,  21, 30,  30, 39
tab_start:          !byte 0, 10, 22, 31
tab_end:            !byte 10, 22, 31, 40

txt_footer_help:    !text " [JOY] CHOIX   [1-4] ONGLET   [B] RETOUR "

; Textes Page 0
txt_box_small:      !text "+------+"
txt_box_p0_grid:    !text "+--------------+"
txt_p0_equipe:      !text "EQUIPE"
txt_p0_arsenal:     !text "ARSENAL"
txt_p0_active:      !text "OBJET  B"
txt_p0_slot_b:      !text "EQUIPE  "
txt_p0_stock_line:  !text "RUBIS:      CLEFS:      BOMBES:     "
txt_p0_tip:         !text "[GAUCHE/DROITE] CHOISIR  [A] EQUIPER"

; Descriptifs des 8 armes (exactement 36 caractères)
p0_desc_lo:
        !byte <desc_boom, <desc_bomb, <desc_bow, <desc_cand, <desc_food, <desc_potion, <desc_whistle, <desc_wand
p0_desc_hi:
        !byte >desc_boom, >desc_bomb, >desc_bow, >desc_cand, >desc_food, >desc_potion, >desc_whistle, >desc_wand

desc_boom:          !text "BOOMERANG", 0
desc_bomb:          !text "BOMBES", 0
desc_bow:           !text "ARC ET FLECHES", 0
desc_cand:          !text "BOUGIE", 0
desc_food:          !text "APPAT", 0
desc_potion:        !text "POTION", 0
desc_whistle:       !text "FLUTE", 0
desc_wand:          !text "BAGUETTE", 0

; Textes Page 1 (Triforce)
txt_p1_title:       !text "  LA TRIFORCE DE LA SAGESSE   "
txt_tri_all:
        !text "           /\\           "
        !text "          /  \\          "
        !text "         / 12 \\         "
        !text "        /------\\        "
        !text "       /\\ 3  4 /\\       "
        !text "      / 5\\ /\\ /6 \\      "
        !text "     / 7 \\/--\\/ 8 \\     "
        !text "    /--------------\\    "
txt_p1_counter:     !text "FRAGMENTS : 0 / 8", 0
txt_p1_dungeons_line: !text "DONJONS: [1][2][3][4][5][6][7][8] "
txt_p1_msg_seek:    !text "CHERCHE LES FRAGMENTS", 0
txt_p1_msg_full:    !text "TRIFORCE REUNIE !", 0

; Textes Page 2 (Équipement)
txt_p2_title:       !text "ARSENAL DE LINK", 0
txt_p2_tip:         !text "EQUIPEMENTS ACQUIS", 0

; Textes Page 3 (Carte du Monde)
txt_room_line:      !text "SALLE COURANTE : A-1  (X:  , Y:  )  "
txt_expl_line:      !text "EXPLOREES :    0 / 128 SALLES       "
txt_legend_line:    !text "LEGENDE:    LINK     VU    - INCONNU"
