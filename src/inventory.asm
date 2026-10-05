; ---------------------------------------------------------------------------
; inventory.asm : écran de sous-menu d'inventaire et choix des armes
; Accessible en appuyant sur ESPACE en cours de jeu.
; Permet de sélectionner l'arme secondaire affectée au bouton B.
; ---------------------------------------------------------------------------

STATE_PLAYING   = 0
STATE_INVENTORY = 1

game_state:     !byte STATE_PLAYING

inv_item_desc:
        !text "< BOOMERANG >  "
        !text "< BOMBS (4) >  "
        !text "< BOW & ARROW >"
        !text "< BLUE CANDLE >"

; ---------------------------------------------------------------------------
; open_inventory : affiche l'écran de sélection des armes
; ---------------------------------------------------------------------------
open_inventory:
        lda #STATE_INVENTORY
        sta game_state

        ; Masque les sprites pendant le menu
        lda #0
        sta VIC_SPRITE_EN

        ; Bip sonore d'ouverture de menu
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

        ; Efface les lignes 4 à 23 en noir
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

        ; 32 octets restants pour atteindre 800 octets (lignes 4..23 = 20 lignes)
        ldx #0
.clr_inv_rem:
        lda #32
        sta SCREEN_RAM+160+$300,x
        lda #COL_WHITE
        sta COLOR_RAM+160+$300,x
        inx
        cpx #32
        bne .clr_inv_rem

        ; Dessin du cadre et du texte de l'inventaire
        jsr draw_inv_frame
        jsr inv_update_cursor
        rts

; ---------------------------------------------------------------------------
; close_inventory : ferme le menu et recharge la carte active
; ---------------------------------------------------------------------------
close_inventory:
        lda #STATE_PLAYING
        sta game_state

        ; Bip sonore de fermeture
        lda #%00010000                  ; Gate OFF
        sta SID_V1_CTRL

        ; Recharge la salle et redessine la carte
        jsr load_room
        jsr hud_init
        jsr player_draw
        rts

; ---------------------------------------------------------------------------
; inventory_update : gestion de la navigation dans le menu
; ---------------------------------------------------------------------------
inventory_update:
        ; 1. Bouton C (Menu / Espace) : fermer l'inventaire
        lda btn_c_pressed
        beq .check_btn_b
        jsr close_inventory
        rts

.check_btn_b:
        ; 2. Bouton B : cycle direct vers l'arme suivante
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
        ; 3. Bouton A (Feu) : valide et ferme le menu
        lda btn_a_pressed
        beq .check_joy
        jsr close_inventory
        rts

.check_joy:
        ; 4. Joystick Gauche / Haut : arme précédente
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
        ; Joystick Droite / Bas : arme suivante
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
; draw_inv_frame : dessine les textes fixes du menu d'inventaire
; ---------------------------------------------------------------------------
draw_inv_frame:
        ; Ligne 4 : Cadre supérieur
        ldx #0
.top_bdr:
        lda #'='
        sta SCREEN_RAM+160,x
        lda #COL_CYAN
        sta COLOR_RAM+160,x
        inx
        cpx #40
        bne .top_bdr

        ; Ligne 5 : Titre "I N V E N T O R Y"
        ldx #0
.put_title:
        lda txt_inventory,x
        sta SCREEN_RAM+200+11,x
        lda #COL_YELLOW
        sta COLOR_RAM+200+11,x
        inx
        cpx #17
        bne .put_title

        ; Ligne 6 : Séparateur
        ldx #0
.mid_bdr:
        lda #'-'
        sta SCREEN_RAM+240,x
        lda #COL_CYAN
        sta COLOR_RAM+240,x
        inx
        cpx #40
        bne .mid_bdr

        ; Ligne 7 : "USE B BUTTON FOR THIS WEAPON:"
        ldx #0
.put_use_b:
        lda txt_use_b,x
        sta SCREEN_RAM+280+2,x
        lda #COL_WHITE
        sta COLOR_RAM+280+2,x
        inx
        cpx #29
        bne .put_use_b

        ; Ligne 9 : [1] BOOMERANG     [2] BOMBS
        ldx #0
.put_w12:
        lda txt_weapons_1,x
        sta SCREEN_RAM+360+4,x
        lda #COL_WHITE
        sta COLOR_RAM+360+4,x
        inx
        cpx #32
        bne .put_w12

        ; Ligne 11 : [3] BOW & ARROW   [4] CANDLE
        ldx #0
.put_w34:
        lda txt_weapons_2,x
        sta SCREEN_RAM+440+4,x
        lda #COL_WHITE
        sta COLOR_RAM+440+4,x
        inx
        cpx #32
        bne .put_w34

        ; Ligne 13 : "EQUIPPED :"
        ldx #0
.put_eq_lbl:
        lda txt_equipped,x
        sta SCREEN_RAM+520+2,x
        lda #COL_WHITE
        sta COLOR_RAM+520+2,x
        inx
        cpx #18
        bne .put_eq_lbl

        ; Ligne 15 : Séparateur
        ldx #0
.sep2:  lda #'-'
        sta SCREEN_RAM+600,x
        lda #COL_CYAN
        sta COLOR_RAM+600,x
        inx
        cpx #40
        bne .sep2

        ; Ligne 16 : "EQUIPMENT:"
        ldx #0
.put_eq_title:
        lda txt_eq_title,x
        sta SCREEN_RAM+640+2,x
        lda #COL_YELLOW
        sta COLOR_RAM+640+2,x
        inx
        cpx #19
        bne .put_eq_title

        ; Ligne 17 : "SWORD  : WOODEN SWORD"
        ldx #0
.put_sw:
        lda txt_sword,x
        sta SCREEN_RAM+680+4,x
        lda #COL_WHITE
        sta COLOR_RAM+680+4,x
        inx
        cpx #21
        bne .put_sw

        ; Ligne 18 : "SHIELD : SMALL SHIELD"
        ldx #0
.put_sh:
        lda txt_shield,x
        sta SCREEN_RAM+720+4,x
        lda #COL_WHITE
        sta COLOR_RAM+720+4,x
        inx
        cpx #21
        bne .put_sh

        ; Ligne 19 : "TRIFORCE : [ * * * - - - - - ]"
        ldx #0
.put_tri:
        lda txt_triforce,x
        sta SCREEN_RAM+760+4,x
        lda #COL_YELLOW
        sta COLOR_RAM+760+4,x
        inx
        cpx #30
        bne .put_tri

        ; Ligne 21 : " [JOY] CHOOSE   [SPACE / FIRE] RETURN"
        ldx #0
.put_help:
        lda txt_help,x
        sta SCREEN_RAM+840+2,x
        lda #COL_GREEN
        sta COLOR_RAM+840+2,x
        inx
        cpx #36
        bne .put_help

        ; Ligne 22 : Bord inférieur
        ldx #0
.bot_bdr:
        lda #'='
        sta SCREEN_RAM+880,x
        lda #COL_CYAN
        sta COLOR_RAM+880,x
        inx
        cpx #40
        bne .bot_bdr
        rts

; ---------------------------------------------------------------------------
; inv_update_cursor : met à jour le nom et la mise en surbrillance de l'arme
; ---------------------------------------------------------------------------
inv_update_cursor:
        ; Remet les 4 armes en blanc
        ldx #0
.clr_w:
        lda #COL_WHITE
        sta COLOR_RAM+360+4,x           ; item 0
        sta COLOR_RAM+360+22,x          ; item 1
        sta COLOR_RAM+440+4,x           ; item 2
        sta COLOR_RAM+440+22,x          ; item 3
        inx
        cpx #14
        bne .clr_w

        ; Met en surbrillance jaune l'arme sélectionnée
        lda hud_selected_b
        cmp #0
        bne +
        ldx #0
-       lda #COL_YELLOW
        sta COLOR_RAM+360+4,x
        inx
        cpx #13
        bne -
        jmp .do_desc
+       cmp #1
        bne +
        ldx #0
-       lda #COL_YELLOW
        sta COLOR_RAM+360+22,x
        inx
        cpx #9
        bne -
        jmp .do_desc
+       cmp #2
        bne +
        ldx #0
-       lda #COL_YELLOW
        sta COLOR_RAM+440+4,x
        inx
        cpx #15
        bne -
        jmp .do_desc
+       ldx #0
-       lda #COL_YELLOW
        sta COLOR_RAM+440+22,x
        inx
        cpx #10
        bne -

.do_desc:
        ; Affiche la description de l'arme courante à la ligne 13, col 20
        lda hud_selected_b
        asl
        asl
        asl
        asl                             ; index * 16
        tax
        ldy #0
.put_desc:
        lda inv_item_desc,x
        sta SCREEN_RAM+520+20,y
        lda #COL_YELLOW
        sta COLOR_RAM+520+20,y
        inx
        iny
        cpy #15
        bne .put_desc
        rts

; Textes de l'inventaire
txt_inventory:  !text "I N V E N T O R Y"
txt_use_b:      !text "USE B BUTTON FOR THIS WEAPON:"
txt_weapons_1:  !text "[1] BOOMERANG     [2] BOMBS     "
txt_weapons_2:  !text "[3] BOW & ARROW   [4] CANDLE    "
txt_equipped:   !text "SELECTED WEAPON : "
txt_eq_title:   !text "CURRENT EQUIPMENT: "
txt_sword:      !text "SWORD  : WOODEN SWORD"
txt_shield:     !text "SHIELD : SMALL SHIELD"
txt_triforce:   !text "TRIFORCE : [ * * * - - - - - ]"
txt_help:       !text "[JOY/B] CHOOSE     [A/C/SPACE] CLOSE"
