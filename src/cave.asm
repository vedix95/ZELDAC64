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
CAVE_TYPE_NONE         = 0
CAVE_TYPE_SWORD_WOOD   = 1      ; Salle 119 (H-8, Départ)
CAVE_TYPE_SHOP_A       = 2      ; Salles 12, 31, 94, 102 (Bouclier 160, Clé 100, Bougie 60)
CAVE_TYPE_SHOP_B       = 3      ; Salles 37, 68, 74, 111 (Bouclier 130, Bombes 20, Flèches 80)
CAVE_TYPE_SHOP_SECRET  = 4      ; Salle 100 (Anneau Bleu 250, Viande 60, Cœur 10)
CAVE_TYPE_POTION_SHOP  = 5      ; Salles 14, 69, 116 (Vieille Femme: Potion Bleue 40, Rouge 68)
CAVE_TYPE_SWORD_WHITE  = 6      ; Salle 10 (Épée Blanche si max_hearts >= 5)
CAVE_TYPE_MOBLIN       = 7      ; Salles 34, 117 (Moblin secret +30 rubis)
CAVE_TYPE_HEART_CHOICE = 8      ; Salles 11, 47, 60 (Choix Cœur vs Potion)
CAVE_TYPE_HINT_1       = 9      ; Salle 4 (Mont du Péril)
CAVE_TYPE_HINT_2       = 10     ; Salle 15 (Arbres secrets)
CAVE_TYPE_HINT_3       = 11     ; Salle 55 (Cascade de l'Est)
CAVE_TYPE_GAMBLE       = 12     ; Salle 112 (Jeu de hasard)
CAVE_TYPE_DUNGEON_1    = 13     ; Entrée Donjon N1 (Niveau 1 : L'Aigle)
CAVE_TYPE_DUNGEON_2    = 14     ; Entrée Donjon N2 (Niveau 2 : La Lune)
CAVE_TYPE_DUNGEON_3    = 15     ; Entrée Donjon N3 (Niveau 3 : Le Manji)
CAVE_TYPE_DUNGEON_4    = 16     ; Entrée Donjon N4 (Niveau 4 : Le Serpent)
CAVE_TYPE_DUNGEON_5    = 17     ; Entrée Donjon N5 (Niveau 5 : Le Lézard)
CAVE_TYPE_DUNGEON_6    = 18     ; Entrée Donjon N6 (Niveau 6 : Le Dragon)
CAVE_TYPE_DUNGEON_7    = 19     ; Entrée Donjon N7 (Niveau 7 : Le Démon)
CAVE_TYPE_DUNGEON_8    = 20     ; Entrée Donjon N8 (Niveau 8 : Le Lion)
CAVE_TYPE_DUNGEON_9    = 21     ; Entrée Donjon N9 (Niveau 9 : La Montagne de la Mort)

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

; Variables du moteur des grottes
saved_overworld_x:      !word 0
saved_overworld_y:      !byte 0
current_cave_type:      !byte 0
cave_torch_tick:        !byte 0
cave_pickup_timer:      !byte 0
cave_jingle_tick:       !byte 0
cave_jingle_idx:        !byte 0

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

; Persistance des 128 salles (bits 0, 1, 2 = slots 1..3 pris ; bit 7 = événement fait)
cave_room_cleared:      !fill 128, 0

; Fanfare triomphale SID pour l'obtention d'un objet (8 notes arpégées)
cave_fanfare_lo:
        !byte $26, $9E, $B8, $4C, $3C, $70, $98, $78
cave_fanfare_hi:
        !byte $11, $15, $19, $22, $2B, $33, $44, $56

; ---------------------------------------------------------------------------
; cave_enter : appelé lorsque Link entre dans une grotte
; ---------------------------------------------------------------------------
cave_enter:
        ; 1. Sauvegarde la position de Link dans l'overworld
        lda player_x
        sta saved_overworld_x
        lda player_x+1
        sta saved_overworld_x+1
        lda player_y
        sta saved_overworld_y

        ; 2. Désactive les ennemis et projectiles extérieurs
        lda #0
        sta en_type
        sta en_type+1
        sta en_proj_active
        sta item_active
        sta player_attacking

        ; 3. Initialise l'état de la grotte
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
        cmp #CAVE_TYPE_DUNGEON_1
        bcc +
        cmp #(CAVE_TYPE_DUNGEON_9 + 1)
        bcs +
        jmp enter_dungeon
+

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
        lda #%10000000
        sta SID_V1_CTRL
        sta SID_V2_CTRL

        ; 6. Configure les emplacements d'objets selon le type de grotte
        jsr cave_setup_room_items

        ; 7. Dessine le décor complet et les textes
        jsr cave_draw_screen

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

+       cmp #CAVE_TYPE_HEART_CHOICE
        beq .do_choice
        rts
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
        ; Ajoute 30 rubis (max 255)
        lda hud_rupees
        clc
        adc #30
        bcc ++
        lda #255
++      sta hud_rupees
        jsr hud_render

        ; Jingle sonore de rubis
        lda #15
        sta SID_VOLUME
        lda #$00
        sta SID_V1_FREQ_LO
        lda #$38
        sta SID_V1_FREQ_HI
        lda #$02
        sta SID_V1_AD
        lda #$00
        sta SID_V1_SR
        lda #%00010001
        sta SID_V1_CTRL
+       rts

; Gabarit résident de 200 octets pour les 23 grottes de l'Overworld
cave_room_template:
        !byte 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5
        !byte 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5
        !byte 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5
        !byte 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5
        !byte 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5
        !byte 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 5
        !byte 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 5
        !byte 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 5
        !byte 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 5
        !byte 5, 5, 5, 5, 5, 5, 5, 5, 0, 6, 6, 0, 5, 5, 5, 5, 5, 5, 5, 5

; ---------------------------------------------------------------------------
; cave_draw_screen : dessine le décor, le PNJ, le texte et les prix
; ---------------------------------------------------------------------------
cave_draw_screen:
        lda #COL_BLACK
        sta VIC_BACKGROUND
        sta VIC_BORDER
        lda #COL_BROWN
        sta VIC_BG_MC1
        lda #COL_GREY
        sta VIC_BG_MC2

        ; 1. Décor de la salle de grotte résidente (200 octets)
        lda #<cave_room_template
        sta ZP_MAP
        lda #>cave_room_template
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

        ; Ligne 6 : 28 caractères
        ldy #0
-       lda (ZP_SRC),y
        beq +
        sta SCREEN_RAM+240+6,y
        lda #COL_WHITE
        sta COLOR_RAM+240+6,y
        iny
        cpy #28
        bne -
+
        ldx current_cave_type
        lda cave_txt2_lo,x
        sta ZP_SRC
        lda cave_txt2_hi,x
        sta ZP_SRC+1

        ; Ligne 8 : 28 caractères
        ldy #0
-       lda (ZP_SRC),y
        beq +
        sta SCREEN_RAM+320+6,y
        lda #COL_WHITE
        sta COLOR_RAM+320+6,y
        iny
        cpy #28
        bne -
+       rts

cave_render_prices:
        ; Efface la ligne 16 (colonnes 12..30)
        ldx #0
-       lda #' '
        sta SCREEN_RAM+640+12,x
        inx
        cpx #18
        bne -

        ; Slot 1 (X=136 -> Col 13..16)
        lda cave_slot1_active
        beq +
        lda cave_slot1_price
        beq +
        lda #HUD_CHAR_RUPEE
        sta SCREEN_RAM+640+13
        lda #COL_YELLOW
        sta COLOR_RAM+640+13
        lda cave_slot1_price
        jsr cave_print_price
        sta SCREEN_RAM+640+14
        stx SCREEN_RAM+640+15
        sty SCREEN_RAM+640+16
        lda #COL_YELLOW
        sta COLOR_RAM+640+14
        sta COLOR_RAM+640+15
        sta COLOR_RAM+640+16
+
        ; Slot 2 (X=176 -> Col 18..21)
        lda cave_slot2_active
        beq +
        lda cave_slot2_price
        beq +
        lda #HUD_CHAR_RUPEE
        sta SCREEN_RAM+640+18
        lda #COL_YELLOW
        sta COLOR_RAM+640+18
        lda cave_slot2_price
        jsr cave_print_price
        sta SCREEN_RAM+640+19
        stx SCREEN_RAM+640+20
        sty SCREEN_RAM+640+21
        lda #COL_YELLOW
        sta COLOR_RAM+640+19
        sta COLOR_RAM+640+20
        sta COLOR_RAM+640+21
+
        ; Slot 3 (X=216 -> Col 23..26)
        lda cave_slot3_active
        beq +
        lda cave_slot3_price
        beq +
        lda #HUD_CHAR_RUPEE
        sta SCREEN_RAM+640+23
        lda #COL_YELLOW
        sta COLOR_RAM+640+23
        lda cave_slot3_price
        jsr cave_print_price
        sta SCREEN_RAM+640+24
        stx SCREEN_RAM+640+25
        sty SCREEN_RAM+640+26
        lda #COL_YELLOW
        sta COLOR_RAM+640+24
        sta COLOR_RAM+640+25
        sta COLOR_RAM+640+26
+       rts

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
cave_update:
        inc cave_torch_tick

        ; Si Link est en train de célébrer l'obtention d'un objet
        lda cave_pickup_timer
        beq .normal_cave_controls
        dec cave_pickup_timer
        jsr cave_play_jingle
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
        cmp #162
        bcs ++
        lda #162
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
        ; Test de ramassage / achat des 3 objets (Y ~ 148..166)
        ; -------------------------------------------------------------------
        lda player_x+1
        bne .check_done
        lda player_y
        cmp #148
        bcc .check_done
        cmp #166
        bcs .check_done

        ; Test Slot 1 (X=136 -> contact 128..144)
        lda cave_slot1_active
        beq .test_slot2
        lda player_x
        cmp #128
        bcc .test_slot2
        cmp #144
        bcs .test_slot2
        jsr cave_buy_slot1
        rts

.test_slot2:
        ; Test Slot 2 (X=176 -> contact 168..184)
        lda cave_slot2_active
        beq .test_slot3
        lda player_x
        cmp #168
        bcc .test_slot3
        cmp #184
        bcs .test_slot3
        jsr cave_buy_slot2
        rts

.test_slot3:
        ; Test Slot 3 (X=216 -> contact 208..224)
        lda cave_slot3_active
        beq .check_done
        lda player_x
        cmp #208
        bcc .check_done
        cmp #224
        bcs .check_done
        jsr cave_buy_slot3
        rts

.check_done:
        rts

; ---------------------------------------------------------------------------
; Achats & Prises d'objets
; ---------------------------------------------------------------------------
cave_buy_slot1:
        lda cave_slot1_price
        beq .take_slot1
        ; Vérifie les rubis suffisants
        lda hud_rupees
        cmp cave_slot1_price
        bcs .pay_slot1
        jmp .cant_afford
.pay_slot1:
        sec
        sbc cave_slot1_price
        sta hud_rupees
        jsr hud_render

.take_slot1:
        lda cave_slot1_type
        jsr cave_grant_item
        lda #0
        sta cave_slot1_active

        ; Si Choix Vital : efface aussi le Slot 3
        lda current_cave_type
        cmp #CAVE_TYPE_HEART_CHOICE
        bne +
        lda #0
        sta cave_slot3_active
+
        ; Marque persistance
        ldx current_room_idx
        lda cave_room_cleared,x
        ora #1
        sta cave_room_cleared,x

        jsr cave_start_celebration
        jsr cave_render_prices
        rts

cave_buy_slot2:
        lda cave_slot2_price
        beq .take_slot2
        lda hud_rupees
        cmp cave_slot2_price
        bcs .pay_slot2
        jmp .cant_afford
.pay_slot2:
        sec
        sbc cave_slot2_price
        sta hud_rupees
        jsr hud_render

.take_slot2:
        lda cave_slot2_type
        jsr cave_grant_item
        lda #0
        sta cave_slot2_active

        ldx current_room_idx
        lda cave_room_cleared,x
        ora #2
        sta cave_room_cleared,x

        jsr cave_start_celebration
        jsr cave_render_prices
        rts

cave_buy_slot3:
        lda cave_slot3_price
        beq .take_slot3
        lda hud_rupees
        cmp cave_slot3_price
        bcs .pay_slot3
        jmp .cant_afford
.pay_slot3:
        sec
        sbc cave_slot3_price
        sta hud_rupees
        jsr hud_render

.take_slot3:
        lda cave_slot3_type
        jsr cave_grant_item
        lda #0
        sta cave_slot3_active

        ; Si Choix Vital : efface aussi le Slot 1
        lda current_cave_type
        cmp #CAVE_TYPE_HEART_CHOICE
        bne +
        lda #0
        sta cave_slot1_active
+
        ldx current_room_idx
        lda cave_room_cleared,x
        ora #4
        sta cave_room_cleared,x

        jsr cave_start_celebration
        jsr cave_render_prices
        rts

.cant_afford:
        ; Son d'échec / rebond
        lda #15
        sta SID_VOLUME
        lda #$00
        sta SID_V1_FREQ_LO
        lda #$12
        sta SID_V1_FREQ_HI
        lda #$05
        sta SID_V1_AD
        lda #$00
        sta SID_V1_SR
        lda #%10000001
        sta SID_V1_CTRL
        rts

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
        lda #90                         ; durée de célébration
        sta cave_pickup_timer
        lda #0
        sta cave_jingle_tick
        sta cave_jingle_idx
        jsr cave_play_note
        rts

; ---------------------------------------------------------------------------
; Fanfare triomphale SID
; ---------------------------------------------------------------------------
cave_play_jingle:
        inc cave_jingle_tick
        lda cave_jingle_tick
        cmp #8
        bcc .jingle_hold
        lda #0
        sta cave_jingle_tick
        lda cave_jingle_idx
        cmp #7
        bcs .jingle_hold
        inc cave_jingle_idx
        jsr cave_play_note
.jingle_hold:
        lda cave_pickup_timer
        cmp #1
        bne +
        lda #%00010000
        sta SID_V1_CTRL
+       rts

cave_play_note:
        ldx cave_jingle_idx
        lda cave_fanfare_lo,x
        sta SID_V1_FREQ_LO
        lda cave_fanfare_hi,x
        sta SID_V1_FREQ_HI
        lda #15
        sta SID_VOL
        lda #$13
        sta SID_V1_AD
        lda #$c4
        sta SID_V1_SR
        lda #%00010001
        sta SID_V1_CTRL
        rts

; ---------------------------------------------------------------------------
; cave_draw : configure et positionne tous les sprites de la grotte (0..7)
; ---------------------------------------------------------------------------
cave_draw:
        lda #PLAYER_SKIN
        sta VIC_SPRITE_MC1
        lda #COL_WHITE
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
        lda #(sprite_link_item_get >> 6)
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
        cmp #CAVE_TYPE_MOBLIN
        beq .set_moblin

        ; Défaut : Vieil Homme
        lda #(sprite_link_old_man / 64)
        sta SPRITE_PTR1
        lda #COL_RED
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
        jsr enemies_room_init
        rts

; ===========================================================================
; TEXTES OFFICIELS DES 23 GROTTES
; ===========================================================================
cave_txt1_lo:
        !byte <txt_dflt_1, <txt_sword_w_1, <txt_shop_a_1, <txt_shop_b_1
        !byte <txt_shop_s_1, <txt_pot_1, <txt_sword_wh_1, <txt_moblin_1
        !byte <txt_choice_1, <txt_hint1_1, <txt_hint2_1, <txt_hint3_1, <txt_gamble_1

cave_txt1_hi:
        !byte >txt_dflt_1, >txt_sword_w_1, >txt_shop_a_1, >txt_shop_b_1
        !byte >txt_shop_s_1, >txt_pot_1, >txt_sword_wh_1, >txt_moblin_1
        !byte >txt_choice_1, >txt_hint1_1, >txt_hint2_1, >txt_hint3_1, >txt_gamble_1

cave_txt2_lo:
        !byte <txt_dflt_2, <txt_sword_w_2, <txt_shop_a_2, <txt_shop_b_2
        !byte <txt_shop_s_2, <txt_pot_2, <txt_sword_wh_2, <txt_moblin_2
        !byte <txt_choice_2, <txt_hint1_2, <txt_hint2_2, <txt_hint3_2, <txt_gamble_2

cave_txt2_hi:
        !byte >txt_dflt_2, >txt_sword_w_2, >txt_shop_a_2, >txt_shop_b_2
        !byte >txt_shop_s_2, >txt_pot_2, >txt_sword_wh_2, >txt_moblin_2
        !byte >txt_choice_2, >txt_hint1_2, >txt_hint2_2, >txt_hint3_2, >txt_gamble_2

txt_dflt_1:     !text "BIENVENUE DANS MA GROTTE    ", 0
txt_dflt_2:     !text "REPOSE-TOI UN INSTANT.      ", 0

txt_sword_w_1:  !text "C'EST DANGEREUX D'Y ALLER   ", 0
txt_sword_w_2:  !text "TOUT SEUL ! PRENDS CECI.    ", 0

txt_shop_a_1:   !text "ACHETE DU MATERIEL QUAND    ", 0
txt_shop_a_2:   !text "TU VEUX. CHOISIS ET PAIE !  ", 0

txt_shop_b_1:   !text "DES ARMES ET DES MUNITIONS  ", 0
txt_shop_b_2:   !text "POUR TRIOMPHER DU MAL !     ", 0

txt_shop_s_1:   !text "OBJETS SPECIAUX ET RARES    ", 0
txt_shop_s_2:   !text "REGARDE CE QUE J'AI LA !    ", 0

txt_pot_1:      !text "PRENDS UNE BONNE POTION     ", 0
txt_pot_2:      !text "POUR RETROUVER TA FORCE.    ", 0

txt_sword_wh_1: !text "VOICI UNE LAME TRES FORTE ! ", 0
txt_sword_wh_2: !text "PRENDS L'EPEE BLANCHE !     ", 0

txt_moblin_1:   !text "C'EST UN SECRET POUR        ", 0
txt_moblin_2:   !text "TOUT LE MONDE. (+30 RUBIS)  ", 0

txt_choice_1:   !text "GARDE CECI SECRET.          ", 0
txt_choice_2:   !text "CHOISIS L'UN DES DEUX.      ", 0

txt_hint1_1:    !text "LE MONT DU PERIL RENFERME   ", 0
txt_hint1_2:    !text "LE REPAIRE DU CRUEL GANON.  ", 0

txt_hint2_1:    !text "LES ARBRES VERTS CACHENT    ", 0
txt_hint2_2:    !text "BIEN DES PASSAGES SECRETS.  ", 0

txt_hint3_1:    !text "VA VERS L'EST POUR TROUVER  ", 0
txt_hint3_2:    !text "LA CASCADE ET SES MYSTERES. ", 0

txt_gamble_1:   !text "TENTE TA CHANCE ICI !       ", 0
txt_gamble_2:   !text "CHOISIS UN SAC DE RUBIS.    ", 0

; ===========================================================================
; TABLE DES 128 SALLES DE L'OVERWORLD VERS LES 23 GROTTES
; ===========================================================================
room_cave_types:
        ; Rangée 0 (0..15 : A-1 .. P-1)
        ; Salle 5: N9 (Mont du Péril / Spectacle Rock), Salle 10: N5 (Cascade)
        !byte 0, 0, 0, 0, CAVE_TYPE_HINT_1, CAVE_TYPE_DUNGEON_9, 0, 0, 0, 0, CAVE_TYPE_DUNGEON_5, CAVE_TYPE_HEART_CHOICE, CAVE_TYPE_SHOP_A, 0, CAVE_TYPE_POTION_SHOP, CAVE_TYPE_HINT_2
        ; Rangée 1 (16..31 : A-2 .. P-2)
        ; Salle 20: N6 (Crâne du Cimetière)
        !byte 0, 0, 0, 0, CAVE_TYPE_DUNGEON_6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, CAVE_TYPE_SHOP_A
        ; Rangée 2 (32..47 : A-3 .. P-3)
        ; Salle 34: N7 (Étang asséché), Salle 35: N4 (Île du radeau)
        !byte 0, 0, CAVE_TYPE_DUNGEON_7, CAVE_TYPE_DUNGEON_4, 0, CAVE_TYPE_SHOP_B, 0, 0, 0, 0, 0, 0, 0, 0, 0, CAVE_TYPE_HEART_CHOICE
        ; Rangée 3 (48..63 : A-4 .. P-4)
        ; Salle 51: N2 (Forêt de l'Ouest), Salle 55: N1 (L'Aigle sur l'île), Salle 62: N8 (Buisson de la Côte)
        !byte 0, 0, 0, CAVE_TYPE_DUNGEON_2, 0, 0, 0, CAVE_TYPE_DUNGEON_1, 0, 0, 0, 0, 0, 0, CAVE_TYPE_DUNGEON_8, 0
        ; Rangée 4 (64..79 : A-5 .. P-5)
        ; Salle 70: N3 (Forêt du Manji)
        !byte 0, 0, 0, 0, CAVE_TYPE_SHOP_B, CAVE_TYPE_POTION_SHOP, CAVE_TYPE_DUNGEON_3, 0, 0, 0, CAVE_TYPE_SHOP_B, 0, 0, 0, 0, 0
        ; Rangée 5 (80..95 : A-6 .. P-6)
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, CAVE_TYPE_SHOP_A, 0
        ; Rangée 6 (96..111 : A-7 .. P-7)
        !byte 0, 0, 0, 0, CAVE_TYPE_SHOP_SECRET, 0, CAVE_TYPE_SHOP_A, 0, 0, 0, 0, 0, 0, 0, 0, CAVE_TYPE_SHOP_B
        ; Rangée 7 (112..127 : A-8 .. P-8)
        !byte CAVE_TYPE_GAMBLE, 0, 0, 0, CAVE_TYPE_POTION_SHOP, CAVE_TYPE_MOBLIN, 0, CAVE_TYPE_SWORD_WOOD, 0, 0, 0, 0, 0, 0, 0, 0
