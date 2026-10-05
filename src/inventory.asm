; ---------------------------------------------------------------------------
; inventory.asm : Sous-écran d'inventaire Zelda NES avec sprites d'objets,
;                 cadres bleus, curseur de sélection animé et Triforce.
;
; Inspiré fidèlement de l'écran d'inventaire de The Legend of Zelda (NES).
; ---------------------------------------------------------------------------

STATE_PLAYING   = 0
STATE_INVENTORY = 1

game_state:         !byte STATE_PLAYING
inv_frame_timer:    !byte 0

; Tables des sprites et couleurs des 4 armes sélectionnables
item_sprite_ptrs:
        !byte (sprite_link_item_boomerang / 64)
        !byte (sprite_link_item_bomb / 64)
        !byte (sprite_link_item_bow / 64)
        !byte (sprite_link_item_candle / 64)

item_colors:
        !byte COL_LIGHT_BLUE            ; Boomerang
        !byte COL_BLUE                  ; Bombe
        !byte COL_WHITE                 ; Arc & Flèche
        !byte COL_LIGHT_BLUE            ; Bougie

; Coordonnées X des 4 objets dans la boîte d'inventaire
; (Item 0=160, Item 1=200, Item 2=240, Item 3=280 -> 24 avec MSB)
item_x_coords:
        !byte 160, 200, 240, 24

; Couleurs de clignotement du cadre de sélection
flash_colors:
        !byte COL_YELLOW, COL_LIGHT_RED, COL_WHITE, COL_ORANGE

; ---------------------------------------------------------------------------
; open_inventory : affiche l'écran de sélection des armes avec sprites
; ---------------------------------------------------------------------------
open_inventory:
        lda #STATE_INVENTORY
        sta game_state

        ; Bip sonore d'ouverture de menu (style Zelda)
        lda #15
        sta SID_VOLUME
        lda #$00
        sta SID_V1_FREQ_LO
        lda #$20
        sta SID_V1_FREQ_HI
        lda #$05
        sta SID_V1_AD
        lda #$00
        sta SID_V1_SR
        lda #%00010001                  ; Triangle + Gate ON
        sta SID_V1_CTRL

        ; Fond d'écran et bordure en noir pur (style NES Zelda)
        lda #COL_BLACK
        sta VIC_BACKGROUND
        sta VIC_BORDER

        ; Efface les lignes 4 à 24 en noir (l'espace de jeu sous le HUD)
        ldx #0
.clr_inv:
        lda #32                         ; espace
        sta SCREEN_RAM+160,x
        sta SCREEN_RAM+160+$100,x
        sta SCREEN_RAM+160+$200,x
        lda #COL_WHITE
        sta COLOR_RAM+160,x
        sta COLOR_RAM+160+$100,x
        sta COLOR_RAM+160+$200,x
        inx
        bne .clr_inv

        ldx #0
.clr_inv_rem:
        lda #32
        sta SCREEN_RAM+160+$300,x
        lda #COL_WHITE
        sta COLOR_RAM+160+$300,x
        inx
        cpx #80                         ; lignes 22..24
        bne .clr_inv_rem

        ; Dessin du décor texte (cadres bleus, Triforce, textes NES)
        jsr draw_inv_frame

        ; -------------------------------------------------------------------
        ; Configuration des 6 sprites de l'inventaire :
        ;   Sprite 0 : Boomerang
        ;   Sprite 1 : Bombe
        ;   Sprite 2 : Arc & Flèche
        ;   Sprite 3 : Bougie
        ;   Sprite 4 : Arme équipée dans la boîte "USE B BUTTON"
        ;   Sprite 5 : Cadre de sélection animé autour de l'arme choisie
        ; -------------------------------------------------------------------
        lda #%00111111                  ; Active Sprites 0..5
        sta VIC_SPRITE_EN
        sta VIC_SPRITE_MC                  ; Sprites 0..5 en multicolore

        ; Pointeurs des sprites 0..3 (les 4 armes disponibles)
        lda #< (sprite_link_item_boomerang / 64)
        sta SPRITE_PTR0
        lda #< (sprite_link_item_bomb / 64)
        sta SPRITE_PTR1
        lda #< (sprite_link_item_bow / 64)
        sta SPRITE_PTR2
        lda #< (sprite_link_item_candle / 64)
        sta SPRITE_PTR3

        ; Pointeur sprite 5 : Cadre de sélection
        lda #< (sprite_link_item_frame / 64)
        sta SPRITE_PTR5

        ; Couleurs des sprites
        lda #COL_LIGHT_BLUE
        sta VIC_SPRITE_COL0
        lda #COL_BLUE
        sta VIC_SPRITE_COL1
        lda #COL_WHITE
        sta VIC_SPRITE_COL2
        lda #COL_LIGHT_BLUE
        sta VIC_SPRITE_COL3
        lda #COL_YELLOW
        sta VIC_SPRITE_COL5

        ; Coordonnées Y identiques pour tous les objets de sélection
        lda #102
        sta VIC_SPRITE_Y0
        sta VIC_SPRITE_Y1
        sta VIC_SPRITE_Y2
        sta VIC_SPRITE_Y3
        sta VIC_SPRITE_Y4
        sta VIC_SPRITE_Y5

        ; Coordonnées X des 4 objets dans la boîte de droite
        lda #160
        sta VIC_SPRITE_X0
        lda #200
        sta VIC_SPRITE_X1
        lda #240
        sta VIC_SPRITE_X2
        lda #24                         ; 280 - 256 (MSB bit 3)
        sta VIC_SPRITE_X3

        ; Coordonnées X de l'objet équipé dans la boîte de gauche
        lda #76
        sta VIC_SPRITE_X4

        ; Mise à jour de l'objet équipé et de la position du cadre de sélection
        jsr inv_update_cursor
        rts

; ---------------------------------------------------------------------------
; close_inventory : ferme le menu, masque les sprites et recharge le jeu
; ---------------------------------------------------------------------------
close_inventory:
        lda #STATE_PLAYING
        sta game_state

        ; Masque tous les sprites du menu
        lda #0
        sta VIC_SPRITE_EN
        sta VIC_SPRITE_MSB

        ; Restaure les couleurs et modes multicolores de Link et de l'épée
        lda #COL_GREEN
        sta VIC_SPRITE_COL0
        lda #COL_WHITE
        sta VIC_SPRITE_COL1
        lda #%00000011                  ; Link (0) et Épée (1) en multicolore
        sta VIC_SPRITE_MC

        ; Restaure la couleur de fond du monde et la bordure
        lda #MAP_BG_COLOR
        sta VIC_BACKGROUND
        lda #COL_BLACK
        sta VIC_BORDER

        ; Bip sonore de fermeture
        lda #%00010000                  ; Gate OFF
        sta SID_V1_CTRL

        ; Recharge la salle et redessine le HUD
        jsr load_room
        jsr hud_init
        jsr player_draw
        rts

; ---------------------------------------------------------------------------
; inventory_update : gestion de la navigation et animation du curseur
; ---------------------------------------------------------------------------
inventory_update:
        ; 1. Animation du cadre de sélection (clignotement jaune/orange/rouge/blanc)
        inc inv_frame_timer
        lda inv_frame_timer
        and #%00001100
        lsr
        lsr
        tax
        lda flash_colors,x
        sta VIC_SPRITE_COL5

        ; 2. Bouton C (Menu / Start / Espace) : fermer l'inventaire
        lda btn_c_pressed
        beq .check_btn_b
        jsr close_inventory
        rts

.check_btn_b:
        ; 3. Bouton B : cycle direct vers l'arme suivante
        lda btn_b_pressed
        beq .check_btn_a
        lda hud_selected_b
        cmp #3
        beq .wrap_b_min
        inc hud_selected_b
        jmp .b_changed
.wrap_b_min:
        lda #0
        sta hud_selected_b
.b_changed:
        jsr sound_select_item
        rts

.check_btn_a:
        ; 4. Bouton A (Feu) : valide et ferme le menu
        lda btn_a_pressed
        beq .check_joy
        jsr close_inventory
        rts

.check_joy:
        ; 5. Joystick Gauche / Haut : arme précédente
        lda joy
        and #(JOY_LEFT | JOY_UP)
        beq .no_prev
        lda joy_prev
        and #(JOY_LEFT | JOY_UP)
        bne .check_next                 ; évite l'auto-répétition trop rapide
        lda hud_selected_b
        beq .wrap_max
        dec hud_selected_b
        jmp .item_changed
.wrap_max:
        lda #3
        sta hud_selected_b
        jmp .item_changed

.no_prev:
.check_next:
        ; 6. Joystick Droite / Bas : arme suivante
        lda joy
        and #(JOY_RIGHT | JOY_DOWN)
        beq .inv_done
        lda joy_prev
        and #(JOY_RIGHT | JOY_DOWN)
        bne .inv_done
        lda hud_selected_b
        cmp #3
        beq .wrap_min
        inc hud_selected_b
        jmp .item_changed
.wrap_min:
        lda #0
        sta hud_selected_b

.item_changed:
        jsr sound_select_item

.inv_done:
        rts

sound_select_item:
        ; Bruitage de sélection
        lda #$00
        sta SID_V1_FREQ_LO
        lda #$30
        sta SID_V1_FREQ_HI
        lda #$04
        sta SID_V1_AD
        lda #%00010001
        sta SID_V1_CTRL
        jsr inv_update_cursor
        jsr hud_render
        rts

; ---------------------------------------------------------------------------
; inv_update_cursor : met à jour l'arme équipée et le cadre de sélection
; ---------------------------------------------------------------------------
inv_update_cursor:
        ldx hud_selected_b

        ; 1. Met à jour le sprite 4 (arme équipée dans la boîte de gauche)
        lda item_sprite_ptrs,x
        sta SPRITE_PTR4
        lda item_colors,x
        sta VIC_SPRITE_COL4

        ; 2. Positionne le sprite 5 (cadre de sélection) sur l'arme choisie
        lda item_x_coords,x
        sta VIC_SPRITE_X5

        ; 3. Gestion du 9e bit horizontal (MSB) :
        ;    - Sprite 3 (Bougie à X=280) a toujours le bit 3 = 1
        ;    - Sprite 5 (Cadre à X=280) a le bit 5 = 1 SI Bougie sélectionnée
        cpx #3
        beq .sel_candle
        lda #%00001000                  ; Bit 3 = 1 (Bougie)
        sta VIC_SPRITE_MSB
        rts
.sel_candle:
        lda #%00101000                  ; Bit 3 = 1 (Bougie), Bit 5 = 1 (Cadre)
        sta VIC_SPRITE_MSB
        rts

; ---------------------------------------------------------------------------
; draw_inv_frame : dessine les boîtes bleues, textes et la Triforce NES
; ---------------------------------------------------------------------------
draw_inv_frame:
        ; Ligne 4 : Titre "INVENTORY" en rouge clair NES
        ldx #0
.put_title:
        lda txt_inventory,x
        sta SCREEN_RAM+160+4,x
        lda #COL_LIGHT_RED
        sta COLOR_RAM+160+4,x
        inx
        cpx #9
        bne .put_title

        ; Lignes 5..9 : Boîte bleue de l'arme équipée (Cols 6..12)
        ldx #0
.box_eq_top:
        lda txt_box_top,x
        sta SCREEN_RAM+200+6,x
        sta SCREEN_RAM+360+6,x          ; bas ligne 9
        lda #COL_BLUE
        sta COLOR_RAM+200+6,x
        sta COLOR_RAM+360+6,x
        inx
        cpx #7
        bne .box_eq_top

        ; Côtés verticaux de la boîte de gauche (lignes 6, 7, 8)
        ldx #0
.box_eq_sides:
        lda #'|'
        sta SCREEN_RAM+240+6,x          ; ligne 6
        sta SCREEN_RAM+280+6,x          ; ligne 7
        sta SCREEN_RAM+320+6,x          ; ligne 8
        lda #COL_BLUE
        sta COLOR_RAM+240+6,x
        sta COLOR_RAM+280+6,x
        sta COLOR_RAM+320+6,x
        inx
        cpx #7
        beq +
        ldx #6                          ; va directement à la col 12
        jmp .box_eq_sides
+

        ; Lignes 5..9 : Grande boîte bleue des armes sélectionnables (Cols 16..38)
        ldx #0
.box_sel_top:
        lda txt_box_long,x
        sta SCREEN_RAM+200+16,x
        sta SCREEN_RAM+360+16,x         ; bas ligne 9
        lda #COL_BLUE
        sta COLOR_RAM+200+16,x
        sta COLOR_RAM+360+16,x
        inx
        cpx #23
        bne .box_sel_top

        ; Côtés verticaux de la boîte de sélection (lignes 6, 7, 8)
        lda #'|'
        sta SCREEN_RAM+240+16
        sta SCREEN_RAM+280+16
        sta SCREEN_RAM+320+16
        sta SCREEN_RAM+240+38
        sta SCREEN_RAM+280+38
        sta SCREEN_RAM+320+38
        lda #COL_BLUE
        sta COLOR_RAM+240+16
        sta COLOR_RAM+280+16
        sta COLOR_RAM+320+16
        sta COLOR_RAM+240+38
        sta COLOR_RAM+280+38
        sta COLOR_RAM+320+38

        ; Lignes 10..11 : "USE B BUTTON FOR THIS" sous la boîte de gauche
        ldx #0
.put_use_b:
        lda txt_use_b1,x
        sta SCREEN_RAM+400+3,x
        lda #COL_WHITE
        sta COLOR_RAM+400+3,x
        inx
        cpx #12
        bne .put_use_b

        ldx #0
.put_use_b2:
        lda txt_use_b2,x
        sta SCREEN_RAM+440+5,x
        lda #COL_WHITE
        sta COLOR_RAM+440+5,x
        inx
        cpx #8
        bne .put_use_b2

        ; Ligne 10 : Noms abrégés des armes sous les sprites
        ldx #0
.put_item_names:
        lda txt_item_names,x
        sta SCREEN_RAM+400+17,x
        lda #COL_CYAN
        sta COLOR_RAM+400+17,x
        inx
        cpx #22
        bne .put_item_names

        ; -------------------------------------------------------------------
        ; Lignes 13..16 : LA TRIFORCE NES (Triangle doré au centre)
        ; -------------------------------------------------------------------
        ; Ligne 13 : Sommet
        lda #'/'
        sta SCREEN_RAM+520+19
        lda #'\\'
        sta SCREEN_RAM+520+20
        lda #COL_YELLOW
        sta COLOR_RAM+520+19
        sta COLOR_RAM+520+20

        ; Ligne 14
        lda #'/'
        sta SCREEN_RAM+560+18
        lda #'\\'
        sta SCREEN_RAM+560+21
        lda #COL_YELLOW
        sta COLOR_RAM+560+18
        sta COLOR_RAM+560+21
        lda #'*'                        ; éclat doré
        sta SCREEN_RAM+560+19
        sta SCREEN_RAM+560+20
        sta COLOR_RAM+560+19
        sta COLOR_RAM+560+20

        ; Ligne 15
        lda #'/'
        sta SCREEN_RAM+600+17
        lda #'\\'
        sta SCREEN_RAM+600+22
        lda #COL_YELLOW
        sta COLOR_RAM+600+17
        sta COLOR_RAM+600+22
        ldx #0
.tri_fill1:
        lda #'*'
        sta SCREEN_RAM+600+18,x
        lda #COL_YELLOW
        sta COLOR_RAM+600+18,x
        inx
        cpx #4
        bne .tri_fill1

        ; Ligne 16 : Base de la Triforce
        lda #'/'
        sta SCREEN_RAM+640+16
        lda #'\\'
        sta SCREEN_RAM+640+23
        lda #COL_YELLOW
        sta COLOR_RAM+640+16
        sta COLOR_RAM+640+23
        ldx #0
.tri_fill2:
        lda #'='
        sta SCREEN_RAM+640+17,x
        lda #COL_YELLOW
        sta COLOR_RAM+640+17,x
        inx
        cpx #6
        bne .tri_fill2

        ; Ligne 17 : Texte "TRIFORCE" en rouge clair
        ldx #0
.put_tri_txt:
        lda txt_triforce_nes,x
        sta SCREEN_RAM+680+16,x
        lda #COL_LIGHT_RED
        sta COLOR_RAM+680+16,x
        inx
        cpx #8
        bne .put_tri_txt

        ; Ligne 19 : Séparateur
        ldx #0
.sep_bot:
        lda #'-'
        sta SCREEN_RAM+760,x
        lda #COL_BLUE
        sta COLOR_RAM+760,x
        inx
        cpx #40
        bne .sep_bot

        ; Ligne 21 : Équipement courant
        ldx #0
.put_eq1:
        lda txt_eq_row1,x
        sta SCREEN_RAM+840+2,x
        lda #COL_WHITE
        sta COLOR_RAM+840+2,x
        inx
        cpx #36
        bne .put_eq1

        ; Ligne 23 : Aide manette
        ldx #0
.put_help:
        lda txt_help_nes,x
        sta SCREEN_RAM+920+3,x
        lda #COL_LIGHT_GREEN
        sta COLOR_RAM+920+3,x
        inx
        cpx #34
        bne .put_help
        rts

; Textes de l'inventaire
txt_inventory:      !text "INVENTORY"
txt_box_top:        !text "+-----+"
txt_box_long:       !text "+---------------------+"
txt_use_b1:         !text "USE B BUTTON"
txt_use_b2:         !text "FOR THIS"
txt_item_names:     !text "BOOM  BOMB  BOW   CAND"
txt_triforce_nes:   !text "TRIFORCE"
txt_eq_row1:        !text "SWORD : WOODEN     SHIELD : SMALL   "
txt_help_nes:       !text "[JOY/B] CHOOSE    [START/A] CLOSE "
