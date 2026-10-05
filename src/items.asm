; ---------------------------------------------------------------------------
; items.asm : Gestion complète des armes secondaires en cours de jeu (Bouton B)
;   - Boomerang   : Projectile rotatif qui part droit puis revient vers Link
;   - Bombe       : Posée au sol, mèche qui brûle puis explosion puissante
;   - Arc         : Flèche rapide orientée selon la direction de tir
;   - Bougie      : Flamme vacillante projetée devant Link qui brûle au sol
; ---------------------------------------------------------------------------

ITEM_NONE       = 0
ITEM_BOOMERANG  = 1
ITEM_BOMB       = 2
ITEM_BOW        = 3
ITEM_CANDLE     = 4

item_active:    !byte ITEM_NONE         ; type d'arme active (0 = aucune)
item_x:         !word 0                 ; position X en pixels sprite (16 bits)
item_y:         !byte 0                 ; position Y en pixels sprite (8 bits)
item_dir:       !byte 0                 ; direction de propagation (DIR_*)
item_state:     !byte 0                 ; phase (0 = aller/pose, 1 = retour/explosion)
item_timer:     !byte 0                 ; compte à rebours de vie/phase
item_anim:      !byte 0                 ; compteur de pas d'animation

; Couleurs d'explosion scintillante
exp_colors:     !byte COL_WHITE, COL_YELLOW, COL_LIGHT_RED, COL_ORANGE

; ---------------------------------------------------------------------------
; items_init : réinitialise l'état des projectiles
; ---------------------------------------------------------------------------
items_init:
        lda #ITEM_NONE
        sta item_active
        sta item_state
        sta item_timer
        lda VIC_SPRITE_EN
        and #%11111011                  ; désactive Sprite 2
        sta VIC_SPRITE_EN
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
+       jmp spawn_candle

; ---------------------------------------------------------------------------
; 1. BOOMERANG : part devant Link et revient vers lui
; ---------------------------------------------------------------------------
spawn_boomerang:
        lda #ITEM_BOOMERANG
        sta item_active
        lda player_dir
        sta item_dir
        lda #0
        sta item_state                  ; phase 0 = aller
        lda #26                         ; ~78 pixels de portée aller
        sta item_timer

        jsr set_spawn_coords

        ; Bruitage de lancement
        lda #15
        sta SID_VOLUME
        lda #$00
        sta SID_V1_FREQ_LO
        lda #$28
        sta SID_V1_FREQ_HI
        lda #$24
        sta SID_V1_AD
        lda #$20
        sta SID_V1_SR
        lda #%00010001                  ; Triangle + Gate ON
        sta SID_V1_CTRL
        rts

; ---------------------------------------------------------------------------
; 2. BOMBE : posée devant Link, mèche puis explosion
; ---------------------------------------------------------------------------
spawn_bomb:
        ; Vérifie les munitions
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
        ; Vérifie les rubis (chaque flèche coûte 1 rubis comme sur NES)
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
        lda #15
        sta SID_VOLUME
        lda #$80
        sta SID_V1_FREQ_LO
        lda #$48
        sta SID_V1_FREQ_HI
        lda #$02
        sta SID_V1_AD
        lda #$00
        sta SID_V1_SR
        lda #%10000001                  ; Bruit blanc
        sta SID_V1_CTRL
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
        sta item_state                  ; phase 0 = avance
        lda #14                         ; avance de 14 pixels
        sta item_timer

        jsr set_spawn_coords

        ; Crépitement de la flamme
        lda #15
        sta SID_VOLUME
        lda #$40
        sta SID_V1_FREQ_LO
        lda #$1c
        sta SID_V1_FREQ_HI
        lda #$28
        sta SID_V1_AD
        lda #$00
        sta SID_V1_SR
        lda #%10000001
        sta SID_V1_CTRL
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
+       jmp update_candle

; ---------------------------------------------------------------------------
; Mise à jour Boomerang
; ---------------------------------------------------------------------------
update_boomerang:
        lda item_state
        bne .boom_return

        ; --- PHASE 0 : ALLER (3 pixels / frame) ---
        lda item_dir
        cmp #DIR_UP
        beq .bm_up
        cmp #DIR_DOWN
        beq .bm_dn
        cmp #DIR_LEFT
        beq .bm_lf

        ; Droite
        clc
        lda item_x
        adc #3
        sta item_x
        lda item_x+1
        adc #0
        sta item_x+1
        jmp .bm_check
.bm_lf:
        sec
        lda item_x
        sbc #3
        sta item_x
        lda item_x+1
        sbc #0
        sta item_x+1
        jmp .bm_check
.bm_up:
        sec
        lda item_y
        sbc #3
        sta item_y
        jmp .bm_check
.bm_dn:
        clc
        lda item_y
        adc #3
        sta item_y

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

.boom_return:
        ; --- PHASE 1 : RETOUR VERS LINK (Homing 3 px / frame) ---
        ; Rapprochement horizontal
        sec
        lda item_x
        sbc player_x
        sta ZP_TMP
        lda item_x+1
        sbc player_x+1
        bne .bm_ret_x_far
        ; Si à moins de 4 pixels, ne bouge plus sur X
        lda ZP_TMP
        cmp #4
        bcc .bm_ret_y
        cmp #252
        bcs .bm_ret_y

.bm_ret_x_far:
        lda item_x+1
        cmp player_x+1
        bcc .bm_ret_right
        bne .bm_ret_left
        lda item_x
        cmp player_x
        bcc .bm_ret_right
.bm_ret_left:
        sec
        lda item_x
        sbc #3
        sta item_x
        lda item_x+1
        sbc #0
        sta item_x+1
        jmp .bm_ret_y
.bm_ret_right:
        clc
        lda item_x
        adc #3
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
        sbc #3
        sta item_y
        jmp .bm_check_caught
.bm_ret_down:
        clc
        adc #3
        sta item_y

.bm_check_caught:
        ; Link attrape le boomerang s'il est proche (< 10 px)
        sec
        lda item_x
        sbc player_x
        bpl +
        eor #$ff
        clc
        adc #1
+       cmp #10
        bcs .bm_ret_done

        sec
        lda item_y
        sbc player_y
        bpl +
        eor #$ff
        clc
        adc #1
+       cmp #10
        bcs .bm_ret_done

        ; Attrapé !
        lda #ITEM_NONE
        sta item_active
        ; Éteint le son
        lda #%00010000
        sta SID_V1_CTRL
.bm_ret_done:
        rts

; ---------------------------------------------------------------------------
; Mise à jour Bombe
; ---------------------------------------------------------------------------
update_bomb:
        lda item_state
        bne .bomb_explode

        ; --- PHASE 0 : MÈCHE QUI BRÛLE ---
        dec item_timer
        bne .bmb_done

        ; Détonation !
        lda #1
        sta item_state
        lda #20                         ; durée de l'explosion
        sta item_timer

        ; Déclenche le son d'explosion
        lda #15
        sta SID_VOLUME
        lda #$00
        sta SID_V1_FREQ_LO
        lda #$0e
        sta SID_V1_FREQ_HI
        lda #$00
        sta SID_V1_AD
        lda #$09
        sta SID_V1_SR
        lda #%10000001                  ; Bruit blanc puissant
        sta SID_V1_CTRL
.bmb_done:
        rts

.bomb_explode:
        ; --- PHASE 1 : SOUFFLE D'EXPLOSION ---
        dec item_timer
        bne .exp_done
        lda #ITEM_NONE
        sta item_active
.exp_done:
        rts

; ---------------------------------------------------------------------------
; Mise à jour Arc & Flèche
; ---------------------------------------------------------------------------
update_bow:
        ; Avance rapide : 4 pixels / frame
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
        dec item_timer
        bne .burn_done
        lda #ITEM_NONE
        sta item_active
.burn_done:
        rts

; ---------------------------------------------------------------------------
; items_draw : configure et affiche le Sprite 2 pour l'arme active
; ---------------------------------------------------------------------------
items_draw:
        lda item_active
        bne .draw_item

        ; Aucun objet : désactive Sprite 2
        lda VIC_SPRITE_EN
        and #%11111011                  ; efface bit 2
        sta VIC_SPRITE_EN
        rts

.draw_item:
        ; 1. Coordonnées Sprite 2
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

        ; 2. Choix du sprite et de la couleur selon le type d'objet
        lda item_active
        cmp #ITEM_BOOMERANG
        bne .drw_bomb

        ; --- BOOMERANG ---
        lda item_anim
        and #4
        beq +
        lda #< (sprite_link_proj_boom_1 / 64)
        jmp ++
+       lda #< (sprite_link_proj_boom_0 / 64)
++      sta SPRITE_PTR2
        lda #COL_LIGHT_BLUE
        sta VIC_SPRITE_COL2
        jmp .enable_spr

.drw_bomb:
        cmp #ITEM_BOMB
        bne .drw_bow

        ; --- BOMBE ---
        lda item_state
        bne .drw_explosion
        ; Bombe posée
        lda #< (sprite_link_item_bomb / 64)
        sta SPRITE_PTR2
        lda #COL_BLUE
        sta VIC_SPRITE_COL2
        jmp .enable_spr
.drw_explosion:
        ; Explosion clignotante
        lda #< (sprite_link_proj_explosion / 64)
        sta SPRITE_PTR2
        lda item_anim
        and #%00000011
        tax
        lda exp_colors,x
        sta VIC_SPRITE_COL2
        jmp .enable_spr

.drw_bow:
        cmp #ITEM_BOW
        bne .drw_candle

        ; --- ARC & FLÈCHE ---
        lda item_dir
        cmp #DIR_LEFT
        beq .drw_arrow_lf
        cmp #DIR_RIGHT
        beq .drw_arrow_rt
        ; Flèche verticale Haut / Bas
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
        jmp .enable_spr

.drw_candle:
        ; --- BOUGIE / FLAMME ---
        lda item_anim
        and #4
        beq +
        lda #< (sprite_link_proj_flame_1 / 64)
        jmp ++
+       lda #< (sprite_link_proj_flame_0 / 64)
++      sta SPRITE_PTR2
        lda #COL_LIGHT_RED
        sta VIC_SPRITE_COL2

.enable_spr:
        ; Active Sprite 2 en multicolore
        lda VIC_SPRITE_EN
        ora #%00000100
        sta VIC_SPRITE_EN
        lda VIC_SPRITE_MC
        ora #%00000100
        sta VIC_SPRITE_MC
        rts
