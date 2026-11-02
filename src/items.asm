; ---------------------------------------------------------------------------
; items.asm : Gestion complète des armes secondaires en cours de jeu (Bouton B)
;   - Boomerang   : Forme en V affûtée, rotation 4 angles, suit le joueur en vol
;                   et le poursuit en tête chercheuse au retour !
;   - Bombe       : Posée au sol, mèche puis DÉFLAGRATION 3x3 géante (5 sprites)
;   - Arc         : Flèche rapide orientée selon la direction de tir
;   - Bougie      : Flamme vacillante projetée devant Link qui brûle au sol
; ---------------------------------------------------------------------------

!zone items

ITEM_NONE       = 0
ITEM_BOOMERANG  = 1
ITEM_BOMB       = 2
ITEM_BOW        = 3
ITEM_CANDLE     = 4
ITEM_WAND       = 5

item_active:    !byte ITEM_NONE         ; type d'arme active (0 = aucune)
item_x:         !word 0                 ; position X en pixels sprite (16 bits)
item_y:         !byte 0                 ; position Y en pixels sprite (8 bits)
item_dir:       !byte 0                 ; direction de propagation (DIR_*)
item_state:     !byte 0                 ; phase (0 = aller/pose, 1 = retour/explosion)
item_timer:     !byte 0                 ; compte à rebours de vie/phase
item_anim:      !byte 0                 ; compteur de pas d'animation

; Table des 4 angles de rotation du boomerang
boom_ptrs:
        !byte < (sprite_link_proj_boom_0 / 64)
        !byte < (sprite_link_proj_boom_1 / 64)
        !byte < (sprite_link_proj_boom_2 / 64)
        !byte < (sprite_link_proj_boom_3 / 64)

; Couleurs scintillantes de l'explosion
exp_colors:
        !byte COL_WHITE, COL_YELLOW, COL_LIGHT_RED, COL_ORANGE
bomb_jitter_x:
        !byte 0, 1, 255, 0
bomb_jitter_y:
        !byte 0, 255, 0, 1

; ---------------------------------------------------------------------------
; items_init : réinitialise l'état des projectiles et masque les sprites 2..6
; ---------------------------------------------------------------------------
items_init:
        lda #ITEM_NONE
        sta item_active
        sta item_state
        sta item_timer
        sta secret_chime_active
        sta secret_chime_timer
        sta secret_chime_idx
        ; Masque tous les sprites de projectiles (bits 2..6)
        lda VIC_SPRITE_EN
        and #%10000011                  ; préserve Link (0) et Épée (1)
        sta VIC_SPRITE_EN
        lda VIC_SPRITE_EXP_X
        and #%11111011
        sta VIC_SPRITE_EXP_X
        lda VIC_SPRITE_EXP_Y
        and #%11111011
        sta VIC_SPRITE_EXP_Y
        lda VIC_SPRITE_MSB
        and #%10000011
        sta VIC_SPRITE_MSB
        rts

; ---------------------------------------------------------------------------
; items_use_b : point d'entrée quand Link appuie sur le bouton B
; ---------------------------------------------------------------------------
items_use_b:
        ; Si un objet est déjà actif, on ne peut pas en lancer un second
        lda item_active
        beq +
        rts
+
        lda hud_selected_b
        cmp #0
        bne +
        jmp spawn_boomerang
+       cmp #1
        bne +
        jmp spawn_bomb
+       cmp #2
        bne +
        jmp spawn_bow
+       cmp #3
        bne +
        jmp spawn_candle
+       cmp #4
        bne +
        jmp use_food
+       cmp #5
        bne +
        jmp use_potion
+       cmp #6
        bne +
        jmp use_whistle
+       jmp use_wand

use_food:
        lda player_has_food
        bne +
        rts
+       lda #0
        sta player_has_food
        jsr sound_food
        rts

use_potion:
        lda player_has_potion
        bne +
        rts
+       lda hud_max_hearts
        sta hud_cur_hearts
        jsr hud_render
        jsr sound_potion
        dec player_has_potion
        rts

use_whistle:
        lda player_has_whistle
        bne +
        rts
+       lda #CART_BANK_OVL_ITEMS
        ldx #4
        jsr cart_load_overlay
        jmp $a000                      ; ovl_item_whistle_exec

use_wand:
        lda player_has_wand
        bne +
        rts
+
        lda #ITEM_WAND
        sta item_active
        lda player_dir
        sta item_dir
        lda #0
        sta item_state
        lda #28                         ; 28 frames de portée
        sta item_timer
        jsr set_spawn_coords


        ; Son d'onde magique
        jsr sound_wand
        rts

; ---------------------------------------------------------------------------
; 1. BOOMERANG : part devant Link, suit Link en vol et revient vers lui
; ---------------------------------------------------------------------------
spawn_boomerang:
        lda #ITEM_BOOMERANG
        sta item_active
        lda player_dir
        sta item_dir
        lda #0
        sta item_state                  ; phase 0 = aller
        lda player_has_boomerang
        cmp #2
        beq .magic_boom
        lda #28                         ; ~84 pixels de portée aller
        bne .set_boom_timer
.magic_boom:
        lda #70                         ; portée magique (traverse l'écran)
.set_boom_timer:
        sta item_timer

        jsr set_spawn_coords
        jsr sound_boomerang
        rts

; ---------------------------------------------------------------------------
; 2. BOMBE : posée devant Link, mèche puis DÉFLAGRATION 3x3 (5 sprites)
; ---------------------------------------------------------------------------
spawn_bomb:
        lda hud_bombs
        bne +
        rts
+       dec hud_bombs
        jsr hud_render

        lda #ITEM_BOMB
        sta item_active
        lda player_dir
        sta item_dir
        lda #0
        sta item_state                  ; phase 0 = posée / mèche
        lda #45                         ; ~0.9 seconde avant détonation
        sta item_timer

        jsr set_spawn_coords
        rts

; ---------------------------------------------------------------------------
; 3. ARC & FLÈCHE : tir rapide dans la direction de Link
; ---------------------------------------------------------------------------
spawn_bow:
        lda hud_rupees
        bne +
        rts
+       dec hud_rupees
        jsr hud_render

        lda #ITEM_BOW
        sta item_active
        lda player_dir
        sta item_dir
        lda #0
        sta item_state
        lda #60                         ; portée maximale
        sta item_timer

        jsr set_spawn_coords

        ; Sifflement rapide de la flèche
        jsr sound_arrow
        rts

; ---------------------------------------------------------------------------
; 4. BOUGIE : projette une flamme courte qui brûle sur place
; ---------------------------------------------------------------------------
spawn_candle:
        lda #ITEM_CANDLE
        sta item_active
        lda player_dir
        sta item_dir
        lda #0
        sta item_state
        lda #14                         ; avance de 14 pixels
        sta item_timer

        jsr set_spawn_coords

        ; Crépitement de la flamme
        jsr sound_candle
        rts

; ---------------------------------------------------------------------------
; set_spawn_coords : place l'objet devant Link selon player_dir
; ---------------------------------------------------------------------------
set_spawn_coords:
        lda player_x
        sta item_x
        lda player_x+1
        sta item_x+1
        lda player_y
        sta item_y

        lda player_dir
        cmp #DIR_UP
        beq .sp_up
        cmp #DIR_DOWN
        beq .sp_down
        cmp #DIR_LEFT
        beq .sp_left

        ; Droite
        clc
        lda item_x
        adc #16
        sta item_x
        lda item_x+1
        adc #0
        sta item_x+1
        rts
.sp_left:
        sec
        lda item_x
        sbc #12
        sta item_x
        lda item_x+1
        sbc #0
        sta item_x+1
        rts
.sp_up:
        sec
        lda item_y
        sbc #14
        sta item_y
        rts
.sp_down:
        clc
        lda item_y
        adc #16
        sta item_y
        rts

; ---------------------------------------------------------------------------
; items_update : mis à jour à chaque frame en jeu
; ---------------------------------------------------------------------------
items_update:
        lda secret_chime_active
        beq +
        jsr update_secret_chime
+
        lda item_active
        bne +
        rts
+       inc item_anim

        cmp #ITEM_BOOMERANG
        bne +
        jmp update_boomerang
+       cmp #ITEM_BOMB
        bne +
        jmp update_bomb
+       cmp #ITEM_BOW
        bne +
        jmp update_bow
+       cmp #ITEM_CANDLE
        bne +
        jmp update_candle
+       jmp update_wand

; ---------------------------------------------------------------------------
; Mise à jour Boomerang (suit le joueur en vol aller et tête chercheuse au retour)
; ---------------------------------------------------------------------------
update_boomerang:
        lda item_state
        beq +
        jmp .boom_return
+

        ; --- PHASE 0 : ALLER (3 pixels / frame) + SUIVI DU JOUEUR ---
        lda item_dir
        cmp #DIR_UP
        beq .bm_up
        cmp #DIR_DOWN
        beq .bm_dn
        cmp #DIR_LEFT
        beq .bm_lf

        ; --- Vol vers la DROITE ---
        clc
        lda item_x
        adc #3
        sta item_x
        lda item_x+1
        adc #0
        sta item_x+1
        ; Suit le joueur sur l'axe Y (vertical)
        jsr follow_player_y
        jmp .bm_check

.bm_lf:
        ; --- Vol vers la GAUCHE ---
        sec
        lda item_x
        sbc #3
        sta item_x
        lda item_x+1
        sbc #0
        sta item_x+1
        ; Suit le joueur sur l'axe Y (vertical)
        jsr follow_player_y
        jmp .bm_check

.bm_up:
        ; --- Vol vers le HAUT ---
        sec
        lda item_y
        sbc #3
        sta item_y
        ; Suit le joueur sur l'axe X (horizontal)
        jsr follow_player_x
        jmp .bm_check

.bm_dn:
        ; --- Vol vers le BAS ---
        clc
        lda item_y
        adc #3
        sta item_y
        ; Suit le joueur sur l'axe X (horizontal)
        jsr follow_player_x

.bm_check:
        ; Collision tuile solide
        lda item_x
        sta col_x
        lda item_x+1
        sta col_x+1
        lda item_y
        sta col_y
        jsr check_point_solid
        bcs .bm_turn                    ; obstacle : fait demi-tour immédiat

        ; Décompte de portée aller
        dec item_timer
        bne .bm_done
.bm_turn:
        lda #1                          ; passe en phase 1 : retour vers Link
        sta item_state
.bm_done:
        rts

; Ajuste la position du boomerang vers le joueur sur l'axe Y (1 px / frame)
follow_player_y:
        lda item_y
        cmp player_y
        bcc +
        beq .fpy_end
        dec item_y
        rts
+       inc item_y
.fpy_end:
        rts

; Ajuste la position du boomerang vers le joueur sur l'axe X (1 px / frame)
follow_player_x:
        lda item_x+1
        cmp player_x+1
        bcc .fpx_r
        bne .fpx_l
        lda item_x
        cmp player_x
        bcc .fpx_r
        beq .fpx_end
.fpx_l:
        sec
        lda item_x
        sbc #1
        sta item_x
        lda item_x+1
        sbc #0
        sta item_x+1
        rts
.fpx_r:
        clc
        lda item_x
        adc #1
        sta item_x
        lda item_x+1
        adc #0
        sta item_x+1
.fpx_end:
        rts

.boom_return:
        ; --- PHASE 1 : RETOUR VERS LINK (Homing rapide 4 px / frame) ---
        ; Rapprochement horizontal
        lda item_x+1
        cmp player_x+1
        bcc .bm_ret_right
        bne .bm_ret_left
        lda item_x
        cmp player_x
        bcc .bm_ret_right
        beq .bm_ret_y
.bm_ret_left:
        sec
        lda item_x
        sbc #4
        sta item_x
        lda item_x+1
        sbc #0
        sta item_x+1
        jmp .bm_ret_y
.bm_ret_right:
        clc
        lda item_x
        adc #4
        sta item_x
        lda item_x+1
        adc #0
        sta item_x+1

.bm_ret_y:
        ; Rapprochement vertical
        lda item_y
        cmp player_y
        bcc .bm_ret_down
        beq .bm_check_caught
        sec
        sbc #4
        sta item_y
        jmp .bm_check_caught
.bm_ret_down:
        clc
        adc #4
        sta item_y

.bm_check_caught:
        ; Link attrape le boomerang s'il est proche (< 12 px)
        ; Calcul de (item_x - player_x) sur 16 bits
        sec
        lda item_x
        sbc player_x
        sta ZP_TMP
        lda item_x+1
        sbc player_x+1
        cmp #0
        bne +
        ; Différence >= 0 : ZP_TMP doit être < 12
        lda ZP_TMP
        cmp #12
        bcs .bm_ret_done
        jmp .check_y
+       cmp #$ff
        bne .bm_ret_done
        ; Différence < 0 : ZP_TMP doit être >= 256-12 ($f4)
        lda ZP_TMP
        cmp #$f4
        bcc .bm_ret_done

.check_y:
        ; Distance Y (axe 8 bits)
        sec
        lda item_y
        sbc player_y
        bcs +
        eor #$ff
        adc #1
+       cmp #12
        bcs .bm_ret_done

        ; Attrapé !
        lda #ITEM_NONE
        sta item_active
.bm_ret_done:
        rts

; ---------------------------------------------------------------------------
; Mise à jour Bombe (mèche puis déflagration 3x3)
; ---------------------------------------------------------------------------
update_bomb:
        lda item_state
        bne .bomb_explode

        ; --- PHASE 0 : MÈCHE QUI BRÛLE ---
        dec item_timer
        bne .bmb_done

        ; Détonation ! Passe en phase 1
        lda #1
        sta item_state
        lda #24                         ; durée de la déflagration 3x3
        sta item_timer
        jsr bomb_check_secret_wall
        jsr dungeon_on_bomb_explode

        ; Déclenche le son d'explosion puissante
        jsr sound_bomb_explode
.bmb_done:
        rts

.bomb_explode:
        ; --- PHASE 1 : SOUFFLE D'EXPLOSION ---
        dec item_timer
        bne .exp_done
        lda #ITEM_NONE
        sta item_active
        ; Éteint le sprite 2 de l'explosion et réinitialise l'expansion
        lda VIC_SPRITE_EN
        and #%11111011                  ; désactive Sprite 2 seul
        sta VIC_SPRITE_EN
        lda VIC_SPRITE_EXP_X
        and #%11111011
        sta VIC_SPRITE_EXP_X
        lda VIC_SPRITE_EXP_Y
        and #%11111011
        sta VIC_SPRITE_EXP_Y
.exp_done:
        rts

; ---------------------------------------------------------------------------
; Mise à jour Arc & Flèche
; ---------------------------------------------------------------------------
update_bow:
        lda item_dir
        cmp #DIR_UP
        beq .arr_up
        cmp #DIR_DOWN
        beq .arr_dn
        cmp #DIR_LEFT
        beq .arr_lf

        ; Droite
        clc
        lda item_x
        adc #4
        sta item_x
        lda item_x+1
        adc #0
        sta item_x+1
        jmp .arr_check
.arr_lf:
        sec
        lda item_x
        sbc #4
        sta item_x
        lda item_x+1
        sbc #0
        sta item_x+1
        jmp .arr_check
.arr_up:
        sec
        lda item_y
        sbc #4
        sta item_y
        jmp .arr_check
.arr_dn:
        clc
        lda item_y
        adc #4
        sta item_y

.arr_check:
        ; Vérifie les bords de l'écran
        lda item_y
        cmp #PLAYER_Y_MIN
        bcc .arr_destroy
        cmp #PLAYER_Y_MAX
        bcs .arr_destroy

        lda item_x+1
        bne .arr_chk_r
        lda item_x
        cmp #PLAYER_X_MIN
        bcc .arr_destroy
        jmp .arr_chk_sol
.arr_chk_r:
        lda item_x
        cmp #<(PLAYER_X_MAX + 1)
        bcs .arr_destroy

.arr_chk_sol:
        ; Collision tuile solide
        lda item_x
        sta col_x
        lda item_x+1
        sta col_x+1
        lda item_y
        sta col_y
        jsr check_point_solid
        bcs .arr_destroy
        rts

.arr_destroy:
        lda #ITEM_NONE
        sta item_active
        rts

; ---------------------------------------------------------------------------
; Mise à jour Bougie
; ---------------------------------------------------------------------------
update_candle:
        lda item_state
        bne .candle_burn

        ; --- PHASE 0 : AVANCE LENTE (1 px / frame) ---
        lda item_dir
        cmp #DIR_UP
        beq .cnd_up
        cmp #DIR_DOWN
        beq .cnd_dn
        cmp #DIR_LEFT
        beq .cnd_lf

        ; Droite
        clc
        lda item_x
        adc #1
        sta item_x
        lda item_x+1
        adc #0
        sta item_x+1
        jmp .cnd_chk
.cnd_lf:
        sec
        lda item_x
        sbc #1
        sta item_x
        lda item_x+1
        sbc #0
        sta item_x+1
        jmp .cnd_chk
.cnd_up:
        dec item_y
        jmp .cnd_chk
.cnd_dn:
        inc item_y

.cnd_chk:
        dec item_timer
        bne .cnd_done
        ; S'arrête et brûle sur place
        lda #1
        sta item_state
        lda #60                         ; brûle pendant ~1.2 seconde
        sta item_timer
.cnd_done:
        rts

.candle_burn:
        ; --- PHASE 1 : BRÛLE SUR PLACE ---
        lda current_world_type
        bne +
        lda item_timer
        cmp #60
        bne +
        lda #CART_BANK_OVL_ITEMS
        ldx #4
        jsr cart_load_overlay
        jsr $a003                      ; ovl_item_candle_exec
        bcs .burn_done
+       dec item_timer
        bne .burn_done
        lda #ITEM_NONE
        sta item_active
.burn_done:
        rts

; ---------------------------------------------------------------------------
; update_wand : déplace l'onde magique et teste les collisions
; ---------------------------------------------------------------------------
update_wand:
        dec item_timer
        bne +
        lda #ITEM_NONE
        sta item_active
        rts
+
        lda item_dir
        cmp #DIR_UP
        beq .w_up
        cmp #DIR_DOWN
        beq .w_dn
        cmp #DIR_LEFT
        beq .w_lf

        ; Droite
        clc
        lda item_x
        adc #4
        sta item_x
        lda item_x+1
        adc #0
        sta item_x+1
        jmp .w_chk
.w_lf:
        sec
        lda item_x
        sbc #4
        sta item_x
        lda item_x+1
        sbc #0
        sta item_x+1
        jmp .w_chk
.w_up:
        sec
        lda item_y
        sbc #4
        sta item_y
        jmp .w_chk
.w_dn:
        clc
        lda item_y
        adc #4
        sta item_y

.w_chk:
        lda item_y
        cmp #PLAYER_Y_MIN
        bcc .w_despawn
        cmp #PLAYER_Y_MAX
        bcs .w_despawn
        rts
.w_despawn:
        lda #ITEM_NONE
        sta item_active
        rts

; ---------------------------------------------------------------------------
; items_draw : configure et affiche les sprites pour l'arme active
; ---------------------------------------------------------------------------
items_draw:
        ; Célébration de la Triforce : affiche le fragment doré brandi par Link sur Sprite 2
        lda triforce_fanfare_timer
        beq .not_triforce_hold
        lda player_x
        sta VIC_SPRITE_X2
        lda player_y
        sec
        sbc #16
        sta VIC_SPRITE_Y2
        lda VIC_SPRITE_MSB
        and #%11111011
        ldx player_x+1
        beq +
        ora #%00000100
+       sta VIC_SPRITE_MSB
        lda #< (sprite_link_item_triforce / 64)
        sta SPRITE_PTR2
        lda triforce_fanfare_timer
        and #4
        bne +
        lda #COL_YELLOW
        jmp ++
+       lda #COL_ORANGE
++      sta VIC_SPRITE_COL2
        jmp .enable_spr2

.not_triforce_hold:
        lda item_active
        beq +
        jmp .draw_item
+
        ; Vérifie si un drop de donjon doit être affiché sur Sprite 2
        lda current_world_type
        cmp #WORLD_DUNGEON
        beq +
        jmp .no_drop_to_draw
+       lda dungeon_drop_active
        bne +
        jmp .no_drop_to_draw
+

        lda dungeon_drop_x
        sta VIC_SPRITE_X2
        lda dungeon_drop_y
        sta VIC_SPRITE_Y2
        lda VIC_SPRITE_MSB
        and #%11111011
        sta VIC_SPRITE_MSB

        lda dungeon_drop_type
        cmp #DROP_KEY
        bne +
        lda #< (sprite_link_item_key / 64)
        sta SPRITE_PTR2
        lda #COL_YELLOW
        sta VIC_SPRITE_COL2
        jmp .enable_spr2
+       cmp #DROP_HEART_CONTAINER
        bne +
        lda #< (sprite_link_item_heart / 64)
        sta SPRITE_PTR2
        lda #COL_RED
        sta VIC_SPRITE_COL2
        jmp .enable_spr2
+       cmp #DROP_TRIFORCE
        bne +
        lda #< (sprite_link_item_triforce / 64)
        sta SPRITE_PTR2
        inc dungeon_torch_tick
        lda dungeon_torch_tick
        and #8
        bne .tri_orange
        lda #COL_YELLOW
        jmp .tri_col_set
.tri_orange:
        lda #COL_ORANGE
.tri_col_set:
        sta VIC_SPRITE_COL2
        jmp .enable_spr2
+       cmp #DROP_COMPASS
        bne +
        lda #< (sprite_link_item_ring / 64)
        sta SPRITE_PTR2
        lda #COL_ORANGE
        sta VIC_SPRITE_COL2
        jmp .enable_spr2
+       cmp #DROP_MAP
        bne +
        lda #< (sprite_link_item_food / 64)
        sta SPRITE_PTR2
        lda #COL_LIGHT_BLUE
        sta VIC_SPRITE_COL2
        jmp .enable_spr2
+       cmp #DROP_BOOMERANG
        bne +
        lda #< (sprite_link_item_boomerang / 64)
        sta SPRITE_PTR2
        lda current_dungeon_level
        cmp #2
        beq .boom_blue
        lda #COL_YELLOW
        jmp .boom_col_set
.boom_blue:
        lda #COL_LIGHT_BLUE
.boom_col_set:
        sta VIC_SPRITE_COL2
        jmp .enable_spr2
+       cmp #DROP_RAFT
        bne +
        lda #< (sprite_link_item_raft / 64)
        sta SPRITE_PTR2
        lda #COL_BROWN
        sta VIC_SPRITE_COL2
        jmp .enable_spr2
+       cmp #DROP_LADDER
        bne +
        lda #< (sprite_link_item_stepladder / 64)
        sta SPRITE_PTR2
        lda #COL_BROWN
        sta VIC_SPRITE_COL2
        jmp .enable_spr2
+       cmp #DROP_WHISTLE
        bne +
        lda #< (sprite_link_item_whistle / 64)
        sta SPRITE_PTR2
        lda #COL_YELLOW
        sta VIC_SPRITE_COL2
        jmp .enable_spr2
+       cmp #DROP_BOOK
        bne +
        lda #< (sprite_link_item_wand / 64)
        sta SPRITE_PTR2
        lda #COL_LIGHT_BLUE
        sta VIC_SPRITE_COL2
        jmp .enable_spr2
+
.no_drop_to_draw:
        ; Aucun objet : désactive Sprite 2
        lda VIC_SPRITE_EN
        and #%11111011                  ; désactive Sprite 2 seul (préserve Link, épée, ennemis)
        sta VIC_SPRITE_EN
        rts

.draw_item:
        ; Pour toutes les armes ou la bombe (posée ou explosion) : utilise Sprite 2 seul
        lda item_x
        sta VIC_SPRITE_X2
        lda item_y
        sta VIC_SPRITE_Y2

        ; MSB horizontal (bit 2)
        lda VIC_SPRITE_MSB
        and #%11111011
        sta ZP_TMP
        lda item_x+1
        and #1
        asl
        asl                             ; bit 2
        ora ZP_TMP
        sta VIC_SPRITE_MSB

        ; S'assure que Sprite 2 n'est jamais étiré matériellement
        lda VIC_SPRITE_EXP_X
        and #%11111011
        sta VIC_SPRITE_EXP_X
        lda VIC_SPRITE_EXP_Y
        and #%11111011
        sta VIC_SPRITE_EXP_Y

        lda item_active
        cmp #ITEM_BOOMERANG
        bne .drw_bomb_single

        ; --- BOOMERANG EN ROTATION (4 angles) ---
        lda item_anim
        lsr
        and #3                          ; rotation fluide tous les 2 frames
        tax
        lda boom_ptrs,x
        sta SPRITE_PTR2
        lda player_has_boomerang
        cmp #2
        beq .blue_b
        lda #COL_YELLOW
        bne .set_b_col
.blue_b:
        lda #COL_LIGHT_BLUE
.set_b_col:
        sta VIC_SPRITE_COL2
        jmp .enable_spr2

.drw_bomb_single:
        cmp #ITEM_BOMB
        beq +
        jmp .drw_bow
+

        lda item_state
        bne .drw_bomb_blast

        ; Phase 0 : Bombe posée (mèche)
        lda #< (sprite_link_item_bomb / 64)
        sta SPRITE_PTR2
        lda #COL_BLUE
        sta VIC_SPRITE_COL2
        jmp .enable_spr2

.drw_bomb_blast:
        ; Animation authentique NES en 3 phases selon item_timer (24..1) :
        ; Phase 3 (6..1)   : Anneau de dispersion de fumée (SPR_COMMON_DEATH_1)
        ; Phase 2 (16..7)  : Pleine déflagration turbulente (sprite_link_proj_explosion + jitter)
        ; Phase 1 (24..17) : Déflagration vive au centre (sprite_link_proj_explosion)

        lda item_timer
        cmp #7
        bcs .bmb_stage_blast

        ; --- PHASE 3 : Anneau de dispersion de fumée ---
        lda #SPR_COMMON_DEATH_1
        sta SPRITE_PTR2
        lda #COL_LIGHT_RED
        sta VIC_SPRITE_COL2
        jmp .enable_spr2

.bmb_stage_blast:
        lda #< (sprite_link_proj_explosion / 64)
        sta SPRITE_PTR2

        lda item_timer
        cmp #20
        bcc .bmb_stage_turbulent

        ; --- PHASE 1 : Déflagration vive (Flash Blanc / Jaune) ---
        lda item_timer
        and #1
        beq +
        lda #COL_WHITE
        bne ++
+       lda #COL_YELLOW
++      sta VIC_SPRITE_COL2
        jmp .enable_spr2

.bmb_stage_turbulent:
        ; --- PHASE 2 : Pleine explosion tourbillonnante aux 7 nuages ---
        lda item_anim
        and #3
        tax
        lda exp_colors,x
        sta VIC_SPRITE_COL2

        ; Vibration subtile simulant le tourbillonnement des 6 satellites
        lda item_timer
        and #3
        tax
        clc
        lda item_x
        adc bomb_jitter_x,x
        sta VIC_SPRITE_X2
        clc
        lda item_y
        adc bomb_jitter_y,x
        sta VIC_SPRITE_Y2
        jmp .enable_spr2

.drw_bow:
        cmp #ITEM_BOW
        bne .drw_candle

        ; --- ARC & FLÈCHE DIRECTIONNELLE ---
        lda item_dir
        cmp #DIR_LEFT
        beq .drw_arrow_lf
        cmp #DIR_RIGHT
        beq .drw_arrow_rt
        lda #< (sprite_link_proj_arrow_v / 64)
        jmp +
.drw_arrow_lf:
        lda #< (sprite_link_proj_arrow_left / 64)
        jmp +
.drw_arrow_rt:
        lda #< (sprite_link_proj_arrow_right / 64)
+       sta SPRITE_PTR2
        lda #COL_WHITE
        sta VIC_SPRITE_COL2
        jmp .enable_spr2

.drw_candle:
        cmp #ITEM_CANDLE
        bne .drw_wand
        ; --- BOUGIE / FLAMME VACILLANTE ---
        lda item_anim
        and #4
        beq +
        lda #< (sprite_link_proj_flame_1 / 64)
        jmp ++
+       lda #< (sprite_link_proj_flame_0 / 64)
++      sta SPRITE_PTR2
        lda #COL_LIGHT_RED
        sta VIC_SPRITE_COL2
        jmp .enable_spr2

.drw_wand:
        ; --- BAGUETTE MAGIQUE : ONDE BLEUE ---
        lda #SPR_COMMON_MAGIC
        sta SPRITE_PTR2
        lda #COL_CYAN
        sta VIC_SPRITE_COL2

.enable_spr2:
        lda VIC_SPRITE_EN
        ora #%00000100                  ; active Sprite 2
        sta VIC_SPRITE_EN
        lda VIC_SPRITE_MC
        ora #%00000100                  ; multicolore
        sta VIC_SPRITE_MC
        rts

; ---------------------------------------------------------------------------
; bomb_check_secret_wall : vérifie si le souffle de la bombe touche un mur secret B
; ---------------------------------------------------------------------------
bomb_check_secret_wall:
        lda current_world_type
        beq +
        rts
+       lda #CART_BANK_OVL_ITEMS
        ldx #4
        jsr cart_load_overlay
        jmp $a009                      ; ovl_item_bomb_secret_exec

record_room_secret_opened:
        lda current_world_type
        bne +
        ldx current_room_idx
        txa
        lsr
        lsr
        lsr
        tax
        lda current_room_idx
        and #7
        tay
        lda bit_powers,y
        ora overworld_secrets_opened,x
        sta overworld_secrets_opened,x
+       rts

; ---------------------------------------------------------------------------
; sound_secret : déclenche le carillon triomphal de découverte secrète
; ---------------------------------------------------------------------------
sound_secret_chime:
sound_secret:
        lda #1
        sta secret_chime_active
        lda #0
        sta secret_chime_idx
        lda #1                          ; première note dès la prochaine frame
        sta secret_chime_timer
        rts

update_secret_chime:
        dec secret_chime_timer
        bne .chime_done
        lda #7                          ; 7 frames par note (~0.14s)
        sta secret_chime_timer

        ldx secret_chime_idx
        cpx #8
        bcs .stop_chime

        lda secret_chime_lo,x
        sta SID_V2_FREQ_LO
        lda secret_chime_hi,x
        sta SID_V2_FREQ_HI
        lda #15
        sta SID_VOLUME
        lda #$03
        sta SID_V2_AD
        lda #$a4
        sta SID_V2_SR
        lda #%00010001                  ; Triangle + Gate ON
        sta SID_V2_CTRL
        inc secret_chime_idx
        rts

.stop_chime:
        lda #%00010000                  ; Gate OFF
        sta SID_V2_CTRL
        lda #0
        sta secret_chime_active
        jsr restore_music_voice_2
.chime_done:
        rts

secret_chime_lo:
        !byte $1c, $bd, $d4, $e7, $2f, $91, $5d, $a0
secret_chime_hi:
        !byte $16, $14, $10, $0c, $0c, $11, $17, $1d

secret_chime_active:    !byte 0
secret_chime_timer:     !byte 0
secret_chime_idx:       !byte 0

