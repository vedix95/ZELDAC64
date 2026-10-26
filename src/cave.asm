; ===========================================================================
; cave.asm : Moteur complet des 23 Grottes et Marchands de l'Overworld
; Fidèle au jeu original The Legend of Zelda (1986)
;
; Comprend :
;   - Table de mappage des 128 salles overworld vers les 23 grottes officielles
;   - Marchands réguliers (A, B) et Marchand secret (Anneau Bleu, Viande, Cœur)
;   - Boutiques de potions (Vieille Femme / Apothicaire)
;   - Grotte de départ (Vieil Homme & Épée de Bois)
;   - Grotte de l'Épée Blanche (Vieil Homme, requiert 5 conteneurs de cœur)
;   - Moblins secrets bienfaiteurs ("C'est un secret pour tout le monde", +30 ◆)
;   - Choix vital (Conteneur de cœur ou Potion rouge exclusif)
;   - Grottes aux indices et jeu de hasard
;   - Système d'achat complet avec prix en rubis et célébration "Item Get"
; ===========================================================================

!zone cave_module

; Types de grottes
!source "src/cave_defs.inc"

; Types d'objets en vente/au sol
ITEM_ID_NONE            = 0
ITEM_ID_SWORD_WOOD      = 1
ITEM_ID_SWORD_WHITE     = 2
ITEM_ID_SHIELD          = 3
ITEM_ID_KEY             = 4
ITEM_ID_CANDLE          = 5
ITEM_ID_BOMBS           = 6
ITEM_ID_BOW             = 7
ITEM_ID_RING_BLUE       = 8
ITEM_ID_FOOD            = 9
ITEM_ID_HEART           = 10
ITEM_ID_HEART_CONTAINER = 11
ITEM_ID_POTION_BLUE     = 12
ITEM_ID_POTION_RED      = 13
ITEM_ID_SWORD_MAGIC     = 14

; Variables du moteur des grottes
saved_overworld_x:      !word 0
saved_overworld_y:      !byte 0
cave_torch_tick:        !byte 0
cave_pickup_timer:      !byte 0
cave_jingle_tick:       !byte 0
cave_jingle_idx:        !byte 0
cave_price_col_cur:     !byte 0
cave_p_c:               !byte 0
cave_p_d:               !byte 0
cave_p_u:               !byte 0

; État des 3 emplacements de la salle active
cave_slot1_active:      !byte 0
cave_slot1_type:        !byte 0
cave_slot1_price:       !byte 0
cave_slot1_ptr:         !byte 0
cave_slot1_col:         !byte 0

cave_slot2_active:      !byte 0
cave_slot2_type:        !byte 0
cave_slot2_price:       !byte 0
cave_slot2_ptr:         !byte 0
cave_slot2_col:         !byte 0

cave_slot3_active:      !byte 0
cave_slot3_type:        !byte 0
cave_slot3_price:       !byte 0
cave_slot3_ptr:         !byte 0
cave_slot3_col:         !byte 0

cave_held_item_ptr:     !byte 0
cave_held_item_col:     !byte 0

; Fanfare triomphale SID pour l'obtention d'un objet (8 notes arpégées)
cave_fanfare_lo:
        !byte $26, $9E, $B8, $4C, $3C, $70, $98, $78
cave_fanfare_hi:
        !byte $11, $15, $19, $22, $2B, $33, $44, $56

; ---------------------------------------------------------------------------
; cave_enter : appelé lorsque Link entre dans une grotte
; ---------------------------------------------------------------------------
ovl_cave_enter:
        ; 1. Sauvegarde la position de Link dans l'overworld
        lda player_x
        sta saved_overworld_x
        lda player_x+1
        sta saved_overworld_x+1
        lda player_y
        sta saved_overworld_y

        ; 2. Désactive TOUS les ennemis (0..7) et projectiles extérieurs
        ldx #7
        lda #0
-       sta en_type,x
        sta en_state,x
        dex
        bpl -
        sta en_proj_active
        sta item_active
        sta player_attacking
        sta VIC_SPRITE_EN
        sta VIC_SPRITE_EXP_X
        sta VIC_SPRITE_EXP_Y
        sta VIC_SPRITE_MSB

        ; 2b. Nettoie complètement l'écran et réinitialise le HUD
        jsr clear_screen
        jsr hud_init
        jsr hud_render

        ; 3. Initialise l'état de la grotte et charge les sprites PNJ
        jsr cart_load_sprites_npc
        lda #STATE_CAVE
        sta game_state

        lda #0
        sta cave_pickup_timer
        sta cave_torch_tick
        sta cave_jingle_tick
        sta cave_jingle_idx

        ; 4. Détermine le type de grotte selon current_room_idx
        ldx current_room_idx
        lda room_cave_types,x
        sta current_cave_type

        ; 5. Positionne Link au seuil du bas
        lda #176
        sta player_x
        lda #0
        sta player_x+1
        lda #204
        sta player_y
        lda #DIR_UP
        sta player_dir
        lda #0
        sta player_walk_anim
        sta player_walk_tick

        ; Coupe le son SID
        jsr music_stop

        ; 6. Configure les emplacements d'objets selon le type de grotte
        jsr cave_setup_room_items

        ; 7. Dessine le décor complet et les textes
        jsr ovl_cave_draw_screen

        ; Événement spécial Moblin : don de +30 rubis immédiat
        lda current_cave_type
        cmp #CAVE_TYPE_MOBLIN
        bne +
        jsr cave_trigger_moblin
+       rts

; ---------------------------------------------------------------------------
; cave_setup_room_items : configure les 3 slots selon la grotte et la persistance
; ---------------------------------------------------------------------------
cave_setup_room_items:
        lda #0
        sta cave_slot1_active
        sta cave_slot2_active
        sta cave_slot3_active

        ldx current_room_idx
        lda cave_room_cleared,x
        sta ZP_TMP                      ; ZP_TMP = masque d'objets déjà pris

        lda current_cave_type
        cmp #CAVE_TYPE_SWORD_WOOD
        bne +
        ; Épée de Bois au centre (Slot 2)
        lda player_has_sword
        beq .set_w_sword
        rts
.set_w_sword:
        lda #1
        sta cave_slot2_active
        lda #ITEM_ID_SWORD_WOOD
        sta cave_slot2_type
        lda #0
        sta cave_slot2_price
        lda #(sprite_link_sword_up / 64)
        sta cave_slot2_ptr
        lda #COL_WHITE
        sta cave_slot2_col
        rts

+       cmp #CAVE_TYPE_SHOP_A
        bne +
        ; Magasin A : Bouclier (160), Clé (100), Bougie (60)
        lda ZP_TMP
        and #1
        bne .sk_a1
        lda #1
        sta cave_slot1_active
        lda #ITEM_ID_SHIELD
        sta cave_slot1_type
        lda #160
        sta cave_slot1_price
        lda #(sprite_link_item_shield / 64)
        sta cave_slot1_ptr
        lda #COL_BLUE
        sta cave_slot1_col
.sk_a1:
        lda ZP_TMP
        and #2
        bne .sk_a2
        lda #1
        sta cave_slot2_active
        lda #ITEM_ID_KEY
        sta cave_slot2_type
        lda #100
        sta cave_slot2_price
        lda #(sprite_link_item_key / 64)
        sta cave_slot2_ptr
        lda #COL_YELLOW
        sta cave_slot2_col
.sk_a2:
        lda ZP_TMP
        and #4
        beq .set_a3
        rts
.set_a3:
        lda #1
        sta cave_slot3_active
        lda #ITEM_ID_CANDLE
        sta cave_slot3_type
        lda #60
        sta cave_slot3_price
        lda #(sprite_link_item_candle / 64)
        sta cave_slot3_ptr
        lda #COL_LIGHT_BLUE
        sta cave_slot3_col
        rts

+       cmp #CAVE_TYPE_SHOP_B
        bne +
        ; Magasin B : Bouclier (130), Bombes (20), Flèches (80)
        lda ZP_TMP
        and #1
        bne .sk_b1
        lda #1
        sta cave_slot1_active
        lda #ITEM_ID_SHIELD
        sta cave_slot1_type
        lda #130
        sta cave_slot1_price
        lda #(sprite_link_item_shield / 64)
        sta cave_slot1_ptr
        lda #COL_BLUE
        sta cave_slot1_col
.sk_b1:
        lda ZP_TMP
        and #2
        bne .sk_b2
        lda #1
        sta cave_slot2_active
        lda #ITEM_ID_BOMBS
        sta cave_slot2_type
        lda #20
        sta cave_slot2_price
        lda #(sprite_link_item_bomb / 64)
        sta cave_slot2_ptr
        lda #COL_BLUE
        sta cave_slot2_col
.sk_b2:
        lda ZP_TMP
        and #4
        beq .set_b3
        rts
.set_b3:
        lda #1
        sta cave_slot3_active
        lda #ITEM_ID_BOW
        sta cave_slot3_type
        lda #80
        sta cave_slot3_price
        lda #(sprite_link_item_bow / 64)
        sta cave_slot3_ptr
        lda #COL_WHITE
        sta cave_slot3_col
        rts

+       cmp #CAVE_TYPE_SHOP_SECRET
        bne +
        ; Magasin Secret : Anneau Bleu (250), Viande (60), Cœur (10)
        lda player_has_blue_ring
        bne .sk_sec1
        lda #1
        sta cave_slot1_active
        lda #ITEM_ID_RING_BLUE
        sta cave_slot1_type
        lda #250
        sta cave_slot1_price
        lda #(sprite_link_item_ring / 64)
        sta cave_slot1_ptr
        lda #COL_CYAN
        sta cave_slot1_col
.sk_sec1:
        lda ZP_TMP
        and #2
        bne .sk_sec2
        lda #1
        sta cave_slot2_active
        lda #ITEM_ID_FOOD
        sta cave_slot2_type
        lda #60
        sta cave_slot2_price
        lda #(sprite_link_item_food / 64)
        sta cave_slot2_ptr
        lda #COL_BROWN
        sta cave_slot2_col
.sk_sec2:
        lda ZP_TMP
        and #4
        beq .set_sec3
        rts
.set_sec3:
        lda #1
        sta cave_slot3_active
        lda #ITEM_ID_HEART
        sta cave_slot3_type
        lda #10
        sta cave_slot3_price
        lda #(sprite_link_item_heart / 64)
        sta cave_slot3_ptr
        lda #COL_RED
        sta cave_slot3_col
        rts

+       cmp #CAVE_TYPE_POTION_SHOP
        bne +
        ; Potion Shop : Potion Bleue (40), Potion Rouge (68)
        lda ZP_TMP
        and #1
        bne .sk_pot1
        lda #1
        sta cave_slot1_active
        lda #ITEM_ID_POTION_BLUE
        sta cave_slot1_type
        lda #40
        sta cave_slot1_price
        lda #(sprite_link_item_potion / 64)
        sta cave_slot1_ptr
        lda #COL_LIGHT_BLUE
        sta cave_slot1_col
.sk_pot1:
        lda ZP_TMP
        and #4
        beq .set_pot3
        rts
.set_pot3:
        lda #1
        sta cave_slot3_active
        lda #ITEM_ID_POTION_RED
        sta cave_slot3_type
        lda #68
        sta cave_slot3_price
        lda #(sprite_link_item_potion / 64)
        sta cave_slot3_ptr
        lda #COL_RED
        sta cave_slot3_col
        rts

+       cmp #CAVE_TYPE_SWORD_WHITE
        bne +
        ; Épée Blanche : requiert 5 cœurs
        lda player_has_sword
        cmp #2
        bcs .sw_wh_ret
        lda hud_max_hearts
        cmp #5
        bcc .sw_wh_ret
        lda #1
        sta cave_slot2_active
        lda #ITEM_ID_SWORD_WHITE
        sta cave_slot2_type
        lda #0
        sta cave_slot2_price
        lda #(sprite_link_sword_up / 64)
        sta cave_slot2_ptr
        lda #COL_WHITE
        sta cave_slot2_col
.sw_wh_ret:
        rts

+       cmp #CAVE_TYPE_SWORD_MAGIC
        bne +
        ; Épée Magique : requiert 12 cœurs
        lda player_has_sword
        cmp #3
        bcs .sw_mg_ret
        lda hud_max_hearts
        cmp #12
        bcc .sw_mg_ret
        lda #1
        sta cave_slot2_active
        lda #ITEM_ID_SWORD_MAGIC
        sta cave_slot2_type
        lda #0
        sta cave_slot2_price
        lda #(sprite_link_sword_up / 64)
        sta cave_slot2_ptr
        lda #COL_LIGHT_RED              ; Lame magique rougeoyante
        sta cave_slot2_col
.sw_mg_ret:
        rts

+       cmp #CAVE_TYPE_HEART_CHOICE
        beq .do_choice
        cmp #CAVE_TYPE_FAIRY
        beq .do_fairy
        cmp #CAVE_TYPE_HEART_GIFT
        beq .do_gift
        rts

.do_fairy:
        ; Fontaine des Fées : soigne Link immédiatement à l'entrée !
        lda hud_max_hearts
        sta hud_cur_hearts
        jsr hud_render
        jsr sound_item_fanfare
        rts

.do_gift:
        ; Conteneur de Cœur gratuit au centre (Slot 2)
        lda ZP_TMP
        and #2
        bne +
        lda #1
        sta cave_slot2_active
        lda #ITEM_ID_HEART_CONTAINER
        sta cave_slot2_type
        lda #0
        sta cave_slot2_price
        lda #(sprite_link_item_heart / 64)
        sta cave_slot2_ptr
        lda #COL_RED
        sta cave_slot2_col
+       rts

.do_choice:
        ; Choix Vital : Conteneur de Cœur (Slot 1) ou Potion Rouge (Slot 3)
        lda ZP_TMP
        and #7
        beq .set_choice
        rts
.set_choice:
        lda #1
        sta cave_slot1_active
        lda #ITEM_ID_HEART_CONTAINER
        sta cave_slot1_type
        lda #0
        sta cave_slot1_price
        lda #(sprite_link_item_heart / 64)
        sta cave_slot1_ptr
        lda #COL_RED
        sta cave_slot1_col

        lda #1
        sta cave_slot3_active
        lda #ITEM_ID_POTION_RED
        sta cave_slot3_type
        lda #0
        sta cave_slot3_price
        lda #(sprite_link_item_potion / 64)
        sta cave_slot3_ptr
        lda #COL_RED
        sta cave_slot3_col
        rts

; ---------------------------------------------------------------------------
; cave_trigger_moblin : donne +30 rubis si pas encore réclamé
; ---------------------------------------------------------------------------
cave_trigger_moblin:
        ldx current_room_idx
        lda cave_room_cleared,x
        bne +
        lda #1
        sta cave_room_cleared,x
        ; Ajoute 30 rubis (ou 100 rubis en salle 15 / P-1)
        lda #30
        cpx #15
        bne ++
        lda #100
++      sta ZP_TMP
        lda hud_rupees
        clc
        adc ZP_TMP
        bcc +++
        lda #255
+++     sta hud_rupees
        jsr hud_render

        ; Jingle sonore de rubis
        jsr sound_rupee
+       rts

build_cave_room:
        ldx #199
        lda #0
-       sta room_buf,x
        dex
        bpl -

        ; Rangée 0 : 20 blocs solides
        ldx #19
        lda #5
-       sta room_buf,x
        dex
        bpl -

        ; Murs gauche (col 0) et droite (col 19)
        ldx #0
-       lda cave_wall_offsets,x
        tay
        lda #5
        sta room_buf,y
        inx
        cpx #16
        bne -

        ; Rangée 9 : murs du bas
        ldx #7
        lda #5
-       sta room_buf+180,x
        sta room_buf+192,x
        dex
        bpl -
        rts

cave_wall_offsets:
        !byte 20, 39, 40, 59, 60, 79, 80, 99, 100, 119, 120, 139, 140, 159, 160, 179

; ---------------------------------------------------------------------------
; cave_draw_screen : dessine le décor, le PNJ, le texte et les prix
; ---------------------------------------------------------------------------
ovl_cave_draw_screen:
        lda #COL_BLACK
        sta active_bg_color
        sta VIC_BACKGROUND
        sta VIC_BORDER
        lda #COL_BROWN
        sta VIC_BG_MC1
        lda #COL_GREY
        sta VIC_BG_MC2

        ; Initialise la palette de tuiles de la grotte (sol noir, murs bleu clair)
        lda #COL_BLACK
        sta active_tile_color+0
        lda #14                         ; 8 + 6 (Multicolore + Bleu Clair)
        sta active_tile_color+5

        ; 1. Décor de la salle de grotte résidente
        jsr build_cave_room
        lda #<room_buf
        sta ZP_MAP
        lda #>room_buf
        sta ZP_MAP+1
        jsr draw_map

        ; 2. Affiche les lignes de texte selon le type de grotte
        jsr cave_render_texts

        ; 3. Affiche les étiquettes de prix pour les marchands (Ligne 11)
        jsr cave_render_prices
        rts

cave_render_texts:
        ldx current_cave_type
        lda cave_txt1_lo,x
        sta ZP_SRC
        lda cave_txt1_hi,x
        sta ZP_SRC+1

        ; Ligne 6 : 28 caractères (colonnes 6..33)
        ldy #0
-       lda (ZP_SRC),y
        beq .pad_txt1
        sta SCREEN_RAM+240+6,y
        lda #COL_WHITE
        sta COLOR_RAM+240+6,y
        iny
        cpy #28
        bne -
        jmp +

.pad_txt1:
        cpy #28
        bcs +
        lda #' '
        sta SCREEN_RAM+240+6,y
        lda #COL_BLACK
        sta COLOR_RAM+240+6,y
        iny
        bne .pad_txt1
+
        ldx current_cave_type
        cpx #CAVE_TYPE_MOBLIN
        bne .set_def_txt2
        lda current_room_idx
        cmp #15
        bne .set_def_txt2
        lda #<txt_moblin_100_2
        sta ZP_SRC
        lda #>txt_moblin_100_2
        sta ZP_SRC+1
        jmp .draw_txt2_chars

.set_def_txt2:
        lda cave_txt2_lo,x
        sta ZP_SRC
        lda cave_txt2_hi,x
        sta ZP_SRC+1

.draw_txt2_chars:
        ; Ligne 8 : 28 caractères (colonnes 6..33)
        ldy #0
-       lda (ZP_SRC),y
        beq .pad_txt2
        sta SCREEN_RAM+320+6,y
        lda #COL_WHITE
        sta COLOR_RAM+320+6,y
        iny
        cpy #28
        bne -
        rts

.pad_txt2:
        cpy #28
        bcs ++
        lda #' '
        sta SCREEN_RAM+320+6,y
        lda #COL_BLACK
        sta COLOR_RAM+320+6,y
        iny
        bne .pad_txt2
++      rts

cave_render_prices:
        ; Efface la ligne 16 (colonnes 12..30)
        ldx #0
-       lda #' '
        sta SCREEN_RAM+640+12,x
        inx
        cpx #18
        bne -

        ldx #0
        jsr .print_slot_price
        ldx #5
        jsr .print_slot_price
        ldx #10
        jsr .print_slot_price
        rts

.print_slot_price:
        lda cave_slot1_active,x
        beq .psp_done
        lda cave_slot1_price,x
        beq .psp_done
        pha
        lda cave_price_cols,x
        sta cave_price_col_cur
        tay
        lda #HUD_CHAR_RUPEE
        sta SCREEN_RAM+640,y
        lda #COL_YELLOW
        sta COLOR_RAM+640,y
        pla
        jsr cave_print_price
        sta cave_p_c
        stx cave_p_d
        sty cave_p_u

        ldy cave_price_col_cur
        iny
        lda cave_p_c
        sta SCREEN_RAM+640,y
        lda #COL_YELLOW
        sta COLOR_RAM+640,y

        iny
        lda cave_p_d
        sta SCREEN_RAM+640,y
        lda #COL_YELLOW
        sta COLOR_RAM+640,y

        iny
        lda cave_p_u
        sta SCREEN_RAM+640,y
        lda #COL_YELLOW
        sta COLOR_RAM+640,y
.psp_done:
        rts

cave_price_cols:
        !byte 13, 0, 0, 0, 0, 18, 0, 0, 0, 0, 23

cave_print_price:
        ; Convertit A (0..255) en 3 caractères ASCII : A (centaines), X (dizaines), Y (unités)
        ldx #0                          ; centaines
.c_loop:
        cmp #100
        bcc .c_done
        sec
        sbc #100
        inx
        jmp .c_loop
.c_done:
        sta ZP_TMP                      ; reste < 100
        txa
        beq .zero_hundreds
        clc
        adc #'0'
        jmp +
.zero_hundreds:
        lda #' '                        ; espace si centaines == 0
+       sta ZP_BASE                     ; ASCII centaines

        lda ZP_TMP
        jsr print_2digits
        tay                             ; Y = dizaines ASCII
        txa                             ; A = unités ASCII
        pha                             ; push unités
        tya
        tax                             ; X = dizaines ASCII
        pla
        tay                             ; Y = unités ASCII
        lda ZP_BASE                     ; A = centaines ASCII
        rts

; ---------------------------------------------------------------------------
; cave_update : déplacement de Link et interaction avec les objets
; ---------------------------------------------------------------------------
ovl_cave_update:
        inc cave_torch_tick

        ; Si Link est en train de célébrer l'obtention d'un objet
        lda cave_pickup_timer
        beq .normal_cave_controls
        dec cave_pickup_timer
        rts

.normal_cave_controls:
        ; -------------------------------------------------------------------
        ; Déplacement de Link dans la grotte
        ; -------------------------------------------------------------------
        ldx #0

        ; GAUCHE
        lda joy
        and #JOY_LEFT
        beq +
        lda #DIR_LEFT
        sta player_dir
        sec
        lda player_x
        sbc #PLAYER_SPEED
        sta player_x
        bcs ++
        dec player_x+1
++      lda player_x+1
        bne ++
        lda player_x
        cmp #60
        bcs ++
        lda #60
        sta player_x
++      ldx #1
+
        ; DROITE
        lda joy
        and #JOY_RIGHT
        beq +
        lda #DIR_RIGHT
        sta player_dir
        clc
        lda player_x
        adc #PLAYER_SPEED
        sta player_x
        bcc ++
        inc player_x+1
++      lda player_x+1
        beq ++
        lda player_x
        cmp #44
        bcc ++
        lda #44
        sta player_x
++      ldx #1
+
        ; HAUT
        lda joy
        and #JOY_UP
        beq +
        lda #DIR_UP
        sta player_dir
        sec
        lda player_y
        sbc #PLAYER_SPEED
        sta player_y
        cmp #150
        bcs ++
        lda #150
        sta player_y
++      ldx #1
+
        ; BAS
        lda joy
        and #JOY_DOWN
        beq +
        lda #DIR_DOWN
        sta player_dir
        clc
        lda player_y
        adc #PLAYER_SPEED
        sta player_y

        ; Seuil de sortie (X ~ 166..196)
        lda player_x+1
        bne .bottom_wall_check
        lda player_x
        cmp #166
        bcc .bottom_wall_check
        cmp #196
        bcs .bottom_wall_check

        lda player_y
        cmp #214
        bcc ++
        jsr cave_exit
        rts

.bottom_wall_check:
        lda player_y
        cmp #204
        bcc ++
        lda #204
        sta player_y
++      ldx #1
+

        ; Animation des pas
        cpx #1
        bne .idle_cave
        inc player_walk_tick
        lda player_walk_tick
        cmp #WALK_TICK_MAX
        bcc .anim_cave_done
        lda #0
        sta player_walk_tick
        lda player_walk_anim
        eor #1
        sta player_walk_anim
        jmp .anim_cave_done
.idle_cave:
        lda #0
        sta player_walk_tick
        sta player_walk_anim
.anim_cave_done:

        ; -------------------------------------------------------------------
        ; Test de ramassage / achat des 3 objets (Y ~ 140..174)
        ; -------------------------------------------------------------------
        lda player_x+1
        bne .check_done
        lda player_y
        cmp #140
        bcc .check_done
        cmp #174
        bcs .check_done

        ; Test Slot 1 (X=136 -> contact 120..152)
        lda cave_slot1_active
        beq .test_slot2
        lda player_x
        cmp #120
        bcc .test_slot2
        cmp #152
        bcs .test_slot2
        jsr cave_buy_slot1
        rts

.test_slot2:
        ; Test Slot 2 (X=176 -> contact 156..196)
        lda cave_slot2_active
        beq .test_slot3
        lda player_x
        cmp #156
        bcc .test_slot3
        cmp #196
        bcs .test_slot3
        jsr cave_buy_slot2
        rts

.test_slot3:
        ; Test Slot 3 (X=216 -> contact 200..232)
        lda cave_slot3_active
        beq .check_done
        lda player_x
        cmp #200
        bcc .check_done
        cmp #232
        bcs .check_done
        jsr cave_buy_slot3
        rts

.check_done:
        rts

; ---------------------------------------------------------------------------
; Achats & Prises d'objets
; ---------------------------------------------------------------------------
cave_buy_slot1:
        ldx #0
        jmp cave_buy_slot_x
cave_buy_slot2:
        ldx #5
        jmp cave_buy_slot_x
cave_buy_slot3:
        ldx #10

cave_buy_slot_x:
        lda cave_slot1_price,x
        beq .take_slot_x
        lda hud_rupees
        cmp cave_slot1_price,x
        bcs .pay_slot_x
        jmp .cant_afford
.pay_slot_x:
        sec
        sbc cave_slot1_price,x
        sta hud_rupees
        jsr hud_render

.take_slot_x:
        lda cave_slot1_type,x
        jsr cave_grant_item
        lda #0
        sta cave_slot1_active,x

        ; Si Choix Vital : efface l'autre slot
        lda current_cave_type
        cmp #CAVE_TYPE_HEART_CHOICE
        bne +
        cpx #0
        bne ++
        sta cave_slot3_active
        jmp +
++      sta cave_slot1_active
+
        cpx #0
        bne ++
        lda #1
        jmp +++
++      cpx #5
        bne ++++
        lda #2
        jmp +++
++++    lda #4
+++     ldy current_room_idx
        ora cave_room_cleared,y
        sta cave_room_cleared,y

        jsr cave_start_celebration
        jsr cave_render_prices
        rts

.cant_afford:
        ; Son d'échec / rebond
        jmp sound_shield_block

; ---------------------------------------------------------------------------
; cave_grant_item : attribue l'objet selon son ID et choisit le sprite célébré
; ---------------------------------------------------------------------------
cave_grant_item:
        cmp #ITEM_ID_SWORD_WOOD
        bne +
        lda #1
        sta player_has_sword
        jsr hud_update_sword
        lda #(sprite_link_sword_up / 64)
        sta cave_held_item_ptr
        lda #COL_WHITE
        sta cave_held_item_col
        rts
+       cmp #ITEM_ID_SWORD_WHITE
        bne +
        lda #2
        sta player_has_sword
        jsr hud_update_sword
        lda #(sprite_link_sword_up / 64)
        sta cave_held_item_ptr
        lda #COL_WHITE
        sta cave_held_item_col
        rts
+       cmp #ITEM_ID_SWORD_MAGIC
        bne +
        lda #3
        sta player_has_sword
        jsr hud_update_sword
        lda #(sprite_link_sword_up / 64)
        sta cave_held_item_ptr
        lda #COL_LIGHT_RED
        sta cave_held_item_col
        rts
+       cmp #ITEM_ID_SHIELD
        bne +
        lda #2
        sta player_has_shield
        lda #(sprite_link_item_shield / 64)
        sta cave_held_item_ptr
        lda #COL_BLUE
        sta cave_held_item_col
        rts
+       cmp #ITEM_ID_KEY
        bne +
        inc hud_keys
        jsr hud_render
        lda #(sprite_link_item_key / 64)
        sta cave_held_item_ptr
        lda #COL_YELLOW
        sta cave_held_item_col
        rts
+       cmp #ITEM_ID_CANDLE
        bne +
        lda #1
        sta player_has_candle
        lda #(sprite_link_item_candle / 64)
        sta cave_held_item_ptr
        lda #COL_LIGHT_BLUE
        sta cave_held_item_col
        rts
+       cmp #ITEM_ID_BOMBS
        bne +
        lda hud_bombs
        clc
        adc #4
        sta hud_bombs
        jsr hud_render
        lda #(sprite_link_item_bomb / 64)
        sta cave_held_item_ptr
        lda #COL_BLUE
        sta cave_held_item_col
        rts
+       cmp #ITEM_ID_BOW
        bne +
        lda #1
        sta player_has_bow
        sta player_has_arrows
        lda #(sprite_link_item_bow / 64)
        sta cave_held_item_ptr
        lda #COL_WHITE
        sta cave_held_item_col
        rts
+       cmp #ITEM_ID_RING_BLUE
        bne +
        lda #1
        sta player_has_blue_ring
        lda #(sprite_link_item_ring / 64)
        sta cave_held_item_ptr
        lda #COL_CYAN
        sta cave_held_item_col
        rts
+       cmp #ITEM_ID_FOOD
        bne +
        lda #1
        sta player_has_food
        lda #(sprite_link_item_food / 64)
        sta cave_held_item_ptr
        lda #COL_BROWN
        sta cave_held_item_col
        rts
+       cmp #ITEM_ID_HEART
        bne +
        lda hud_cur_hearts
        cmp hud_max_hearts
        bcs .no_heal
        inc hud_cur_hearts
        jsr hud_render
.no_heal:
        lda #(sprite_link_item_heart / 64)
        sta cave_held_item_ptr
        lda #COL_RED
        sta cave_held_item_col
        rts
+       cmp #ITEM_ID_HEART_CONTAINER
        bne +
        inc hud_max_hearts
        lda hud_max_hearts
        sta hud_cur_hearts
        jsr hud_render
        lda #(sprite_link_item_heart / 64)
        sta cave_held_item_ptr
        lda #COL_RED
        sta cave_held_item_col
        rts
+       cmp #ITEM_ID_POTION_BLUE
        bne +
        lda #1
        sta player_has_potion
        lda #(sprite_link_item_potion / 64)
        sta cave_held_item_ptr
        lda #COL_LIGHT_BLUE
        sta cave_held_item_col
        rts
+       ; Potion Rouge
        lda #2
        sta player_has_potion
        lda #(sprite_link_item_potion / 64)
        sta cave_held_item_ptr
        lda #COL_RED
        sta cave_held_item_col
        rts

cave_start_celebration:
        lda #75                         ; durée de célébration (~1.5s)
        sta cave_pickup_timer
        jsr sound_item_fanfare
        rts

; ---------------------------------------------------------------------------
; cave_draw : configure et positionne tous les sprites de la grotte (0..7)
; ---------------------------------------------------------------------------
ovl_cave_draw:
        lda #PLAYER_SKIN
        sta VIC_SPRITE_MC1
        lda #PLAYER_BROWN
        sta VIC_SPRITE_MC2
        lda #%11111111                  ; Tous les 8 sprites en multicolore
        sta VIC_SPRITE_MC
        lda #0
        sta VIC_SPRITE_EXP_X
        sta VIC_SPRITE_EXP_Y

        lda player_x+1
        and #1
        sta VIC_SPRITE_MSB

        ; 1. Sprite 0 : Link
        lda player_x
        sta VIC_SPRITE_X0
        lda player_y
        sta VIC_SPRITE_Y0

        lda player_has_blue_ring
        beq +
        lda #COL_WHITE
        sta VIC_SPRITE_COL0
        jmp ++
+       lda #COL_GREEN
        sta VIC_SPRITE_COL0
++

        lda cave_pickup_timer
        beq .normal_link_spr

        ; Pose "Item Get"
        lda #SPR_COMMON_ITEM_GET
        sta SPRITE_PTR0

        ; Sprite 7 : Objet levé au-dessus de la tête
        lda cave_held_item_ptr
        sta SPRITE_PTR7
        lda player_x
        sta VIC_SPRITE_X7
        lda player_y
        sec
        sbc #14
        sta VIC_SPRITE_Y7
        lda cave_held_item_col
        sta VIC_SPRITE_COL7
        jmp .setup_actors

.normal_link_spr:
        lda player_dir
        asl
        ora player_walk_anim
        clc
        adc #(sprite_link_down_0 >> 6)
        sta SPRITE_PTR0

.setup_actors:
        ; 2. Sprite 1 : PNJ central (X=176, Y=130)
        lda #176
        sta VIC_SPRITE_X1
        lda #130
        sta VIC_SPRITE_Y1
        jsr setup_pnj_sprite

        ; 3. Sprites 2 & 3 : Torches gauche et droite (X=136, X=216, Y=130)
        lda #136
        sta VIC_SPRITE_X2
        lda #130
        sta VIC_SPRITE_Y2
        lda #COL_RED
        sta VIC_SPRITE_COL2

        lda #216
        sta VIC_SPRITE_X3
        lda #130
        sta VIC_SPRITE_Y3
        lda #COL_RED
        sta VIC_SPRITE_COL3

        lda cave_torch_tick
        and #8
        beq +
        lda #(sprite_link_proj_flame_0 >> 6)
        sta SPRITE_PTR2
        lda #(sprite_link_proj_flame_1 >> 6)
        sta SPRITE_PTR3
        jmp ++
+       lda #(sprite_link_proj_flame_1 >> 6)
        sta SPRITE_PTR2
        lda #(sprite_link_proj_flame_0 >> 6)
        sta SPRITE_PTR3
++

        ; 4. Sprites 4..6 : Objets au sol (X=136, 176, 216, Y=146)
        lda cave_slot1_ptr
        sta SPRITE_PTR4
        lda cave_slot1_col
        sta VIC_SPRITE_COL4
        lda #136
        sta VIC_SPRITE_X4
        lda #146
        sta VIC_SPRITE_Y4

        lda cave_slot2_ptr
        sta SPRITE_PTR5
        lda cave_slot2_col
        sta VIC_SPRITE_COL5
        lda #176
        sta VIC_SPRITE_X5
        lda #146
        sta VIC_SPRITE_Y5

        lda cave_slot3_ptr
        sta SPRITE_PTR6
        lda cave_slot3_col
        sta VIC_SPRITE_COL6
        lda #216
        sta VIC_SPRITE_X6
        lda #146
        sta VIC_SPRITE_Y6

        ; 5. Masque d'activation des sprites (VIC_SPRITE_EN)
        ; Base : Link (0), PNJ (1), Torche G (2), Torche D (3) = %00001111
        lda #%00001111
        sta ZP_TMP

        lda cave_slot1_active
        beq +
        lda ZP_TMP
        ora #%00010000                  ; Sprite 4
        sta ZP_TMP
+
        lda cave_slot2_active
        beq +
        lda ZP_TMP
        ora #%00100000                  ; Sprite 5
        sta ZP_TMP
+
        lda cave_slot3_active
        beq +
        lda ZP_TMP
        ora #%01000000                  ; Sprite 6
        sta ZP_TMP
+
        lda cave_pickup_timer
        beq +
        lda ZP_TMP
        ora #%10000000                  ; Sprite 7 (Item Get)
        sta ZP_TMP
+
        lda ZP_TMP
        sta VIC_SPRITE_EN
        rts

setup_pnj_sprite:
        lda current_cave_type
        cmp #CAVE_TYPE_SHOP_A
        beq .set_merchant
        cmp #CAVE_TYPE_SHOP_B
        beq .set_merchant
        cmp #CAVE_TYPE_SHOP_SECRET
        beq .set_merchant
        cmp #CAVE_TYPE_POTION_SHOP
        beq .set_old_woman
        cmp #CAVE_TYPE_FAIRY
        beq .set_fairy
        cmp #CAVE_TYPE_MOBLIN
        beq .set_moblin

        ; Défaut : Vieil Homme
        lda #(sprite_link_old_man / 64)
        sta SPRITE_PTR1
        lda #COL_RED
        sta VIC_SPRITE_COL1
        rts

.set_fairy:
        lda #(sprite_link_old_woman / 64)
        sta SPRITE_PTR1
        lda #COL_WHITE
        sta VIC_SPRITE_COL1
        rts

.set_merchant:
        lda #(sprite_link_merchant / 64)
        sta SPRITE_PTR1
        lda #COL_PURPLE
        sta VIC_SPRITE_COL1
        rts

.set_old_woman:
        lda #(sprite_link_old_woman / 64)
        sta SPRITE_PTR1
        lda #COL_LIGHT_RED
        sta VIC_SPRITE_COL1
        rts

.set_moblin:
        lda #(sprite_enemies_moblin_down_0 / 64)
        sta SPRITE_PTR1
        lda #COL_RED
        sta VIC_SPRITE_COL1
        rts

; ---------------------------------------------------------------------------
; cave_exit : replace Link à l'extérieur devant la grotte
; ---------------------------------------------------------------------------
cave_exit:
        lda #STATE_PLAYING
        sta game_state

        ; Clear sprites before returning to OW/Dungeon
        lda #0
        sta VIC_SPRITE_EN
        sta VIC_SPRITE_EXP_X
        sta VIC_SPRITE_EXP_Y
        sta VIC_SPRITE_MSB

        jsr clear_screen

        ; Rétablit les sprites selon le monde actif (Overworld ou Donjon)
        lda current_world_type
        bne +
        jsr cart_load_sprites_ow
        jmp ++
+       jsr cart_load_sprites_dung
++

        lda saved_overworld_x
        sta player_x
        lda saved_overworld_x+1
        sta player_x+1
        lda saved_overworld_y
        clc
        adc #16
        sta player_y
        lda #DIR_DOWN
        sta player_dir
        lda #0
        sta player_walk_anim
        sta player_walk_tick

        lda #MAP_BG_COLOR
        sta active_bg_color
        sta VIC_BACKGROUND
        lda #COL_BLACK
        sta VIC_BORDER
        lda #MAP_MC1_COLOR
        sta VIC_BG_MC1
        lda #MAP_MC2_COLOR
        sta VIC_BG_MC2
        lda #PLAYER_SKIN
        sta VIC_SPRITE_MC1
        lda #PLAYER_BROWN
        sta VIC_SPRITE_MC2

        jsr load_room
        jsr hud_init
        jsr hud_render
        jsr enemies_room_init

        lda current_world_type
        bne +
        lda #MUSIC_OVERWORLD
        bne ++
+       lda #MUSIC_DUNGEON
++      jsr music_play
        rts

; ===========================================================================
; TEXTES OFFICIELS DES 23 GROTTES
; ===========================================================================
cave_txt1_lo:
        !byte <txt_dflt_1, <txt_sword_w_1, <txt_shop_a_1, <txt_shop_b_1
        !byte <txt_shop_s_1, <txt_pot_1, <txt_sword_wh_1, <txt_moblin_1
        !byte <txt_choice_1, <txt_hint1_1, <txt_hint2_1, <txt_hint3_1, <txt_gamble_1
        !byte <txt_fairy_1, <txt_gift_1, <txt_sword_mg_1

cave_txt1_hi:
        !byte >txt_dflt_1, >txt_sword_w_1, >txt_shop_a_1, >txt_shop_b_1
        !byte >txt_shop_s_1, >txt_pot_1, >txt_sword_wh_1, >txt_moblin_1
        !byte >txt_choice_1, >txt_hint1_1, >txt_hint2_1, >txt_hint3_1, >txt_gamble_1
        !byte >txt_fairy_1, >txt_gift_1, >txt_sword_mg_1

cave_txt2_lo:
        !byte <txt_dflt_2, <txt_sword_w_2, <txt_shop_a_2, <txt_shop_b_2
        !byte <txt_shop_s_2, <txt_pot_2, <txt_sword_wh_2, <txt_moblin_2
        !byte <txt_choice_2, <txt_hint1_2, <txt_hint2_2, <txt_hint3_2, <txt_gamble_2
        !byte <txt_fairy_2, <txt_gift_2, <txt_sword_mg_2

cave_txt2_hi:
        !byte >txt_dflt_2, >txt_sword_w_2, >txt_shop_a_2, >txt_shop_b_2
        !byte >txt_shop_s_2, >txt_pot_2, >txt_sword_wh_2, >txt_moblin_2
        !byte >txt_choice_2, >txt_hint1_2, >txt_hint2_2, >txt_hint3_2, >txt_gamble_2
        !byte >txt_fairy_2, >txt_gift_2, >txt_sword_mg_2

txt_dflt_1:     !text "REPOSE-TOI UN INSTANT.", 0
txt_dflt_2:     !text "", 0

txt_sword_w_1:  !text "C'EST DANGEREUX D'Y ALLER", 0
txt_sword_w_2:  !text "TOUT SEUL ! PRENDS CECI.", 0

txt_shop_a_1:   !text "ACHETE DU MATERIEL", 0
txt_shop_a_2:   !text "TU VEUX. CHOISIS ET PAIE !", 0

txt_shop_b_1:   !text "ARMES ET MUNITIONS", 0
txt_shop_b_2:   !text "POUR TRIOMPHER DU MAL !", 0

txt_shop_s_1:   !text "OBJETS RARES", 0
txt_shop_s_2:   !text "REGARDE CE QUE J'AI LA !", 0

txt_pot_1:      !text "UNE BONNE POTION", 0
txt_pot_2:      !text "POUR TA FORCE.", 0

txt_sword_wh_1: !text "UNE LAME FORTE !", 0
txt_sword_wh_2: !text "L'EPEE BLANCHE !", 0

txt_sword_mg_1: !text "L'EPEE MAGIQUE !", 0
txt_sword_mg_2: !text "LIBERE HYRULE !", 0

txt_moblin_1:   !text "C'EST UN SECRET POUR", 0
txt_moblin_2:   !text "TOUT LE MONDE. (+30 RUBIS)", 0
txt_moblin_100_2: !text "TOUT LE MONDE. (+100 RUBIS)", 0

txt_choice_1:   !text "GARDE CECI SECRET.", 0
txt_choice_2:   !text "CHOISIS L'UN DES DEUX.", 0

txt_hint1_1:    !text "AU MONT DU PERIL GIT", 0
txt_hint1_2:    !text "LE REPAIRE DE GANON.", 0

txt_hint2_1:    !text "LES ARBRES CACHENT", 0
txt_hint2_2:    !text "DES PASSAGES SECRETS.", 0

txt_hint3_1:    !text "VA VERS L'EST TROUVER", 0
txt_hint3_2:    !text "LA CASCADE ET SES SECRETS.", 0

txt_gamble_1:   !text "TENTE TA CHANCE !", 0
txt_gamble_2:   !text "CHOISIS UN SAC.", 0

txt_fairy_1:    !text "JE TE SOIGNE !", 0
txt_fairy_2:    !text "FORCE RESTAUREE.", 0

txt_gift_1:     !text "PRENDS CECI.", 0
txt_gift_2:     !text "GARDE LE SECRET !", 0


