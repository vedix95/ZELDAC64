; ---------------------------------------------------------------------------
; transition.asm : défilement d'écran par poussée (push-scroll classique Zelda)
; Lors du passage d'une salle à l'autre :
;   - Le jeu effectue une transition fluide tuile par tuile (16 pixels par étape)
;   - La salle courante est poussée hors de l'écran pendant que la nouvelle salle entre
;   - Link avance simultanément vers l'intérieur du nouvel écran
; ---------------------------------------------------------------------------

!zone transition_tables

; Table des adresses des 24 lignes de texte (960 caractères = 20x12 tuiles)
scr_row_lo:
        !byte $00, $28, $50, $78, $a0, $c8, $f0, $18, $40, $68, $90, $b8
        !byte $e0, $08, $30, $58, $80, $a8, $d0, $f8, $20, $48, $70, $98
scr_row_hi:
        !byte $04, $04, $04, $04, $04, $04, $04, $05, $05, $05, $05, $05
        !byte $05, $06, $06, $06, $06, $06, $06, $06, $07, $07, $07, $07
col_row_hi:
        !byte $d8, $d8, $d8, $d8, $d8, $d8, $d8, $d9, $d9, $d9, $d9, $d9
        !byte $d9, $da, $da, $da, $da, $da, $da, $da, $db, $db, $db, $db



; ---------------------------------------------------------------------------
; Transition vers la DROITE (Est) : l'écran défile vers la gauche
; ---------------------------------------------------------------------------
!zone transition_right

trans_setup_target:
        stx target_room_idx
        lda current_world_type
        bne .tst_chunk_ok
        lda target_room_idx
        lsr
        lsr
        lsr
        lsr
        lsr
        jsr disk_ensure_ow_chunk_a
        ldx target_room_idx
.tst_chunk_ok:
        lda room_tbl_lo,x
        sta ZP_SRC
        lda room_tbl_hi,x
        sta ZP_SRC+1
        jsr decompress_room_target
        jsr dungeon_apply_room_state_target
        lda #<target_room_buf
        sta ZP_TGT
        lda #>target_room_buf
        sta ZP_TGT+1
        lda #0
        sta ZP_STEP
        rts

trans_finish:
        jsr load_room
        jsr hud_render
        jsr player_draw
        jsr enemies_room_init
        jsr dungeon_on_enter_room
        lda #STATE_PLAYING
        sta game_state
        rts

transition_right:
        lda #STATE_TRANSITION
        sta game_state
        jsr enemies_clear
        ; Pointeur ZP_TGT vers la salle cible (current_room_x + 1)
        ldx current_room_y
        lda world_row_offset,x
        clc
        adc current_room_x
        clc
        adc #1
        tax
        jsr trans_setup_target
.tr_step:
        jsr wait_frame
        jsr wait_frame

        ; Décalage horizontal de chaque ligne de texte : 2 colonnes vers la gauche
        ; Concerne uniquement les lignes de jeu 4..23 (le HUD en 0..3 reste fixe)
        ldx #4
.tr_row:
        stx ZP_ROW                      ; sauvegarde numéro de ligne de texte

        lda scr_row_lo,x
        sta ZP_SCR
        lda scr_row_hi,x
        sta ZP_SCR+1
        lda col_row_hi,x
        sta ZP_COL+1
        lda ZP_SCR
        sta ZP_COL                      ; col_row_lo = scr_row_lo

        ; Pointeur source = ZP_SCR + 2
        clc
        lda ZP_SCR
        adc #2
        sta ZP_SRC
        lda ZP_SCR+1
        adc #0
        sta ZP_SRC+1

        ; Décale 38 caractères écran (colonnes 2..39 -> colonnes 0..37)
        ldy #0
.tr_shift_scr:
        lda (ZP_SRC),y
        sta (ZP_SCR),y
        iny
        cpy #38
        bne .tr_shift_scr

        ; Pointeur source couleur = ZP_COL + 2
        clc
        lda ZP_COL
        adc #2
        sta ZP_SRC
        lda ZP_COL+1
        adc #0
        sta ZP_SRC+1

        ; Décale 38 caractères couleur
        ldy #0
.tr_shift_col:
        lda (ZP_SRC),y
        sta (ZP_COL),y
        iny
        cpy #38
        bne .tr_shift_col

        ; Insère la nouvelle tuile en colonnes 38 et 39
        ; tr = (row - 4) / 2, sub_y = row & 1
        lda ZP_ROW
        sec
        sbc #4
        lsr
        tax                             ; X = tr (0..9)
        lda tile_row_offset,x
        clc
        adc ZP_STEP                     ; + colonne entrante (0..19)
        tay
        lda (ZP_TGT),y                  ; Tuile ID
        tax
        lda active_tile_color,x
        sta ZP_TMP                      ; couleur
        lda tile_char_base,x
        sta ZP_BASE
        lda ZP_ROW
        and #1
        beq .tr_no_suby
        lda ZP_BASE
        ora #2
        sta ZP_BASE
.tr_no_suby:
        ldy #38
        lda ZP_BASE
        sta (ZP_SCR),y
        lda ZP_TMP
        sta (ZP_COL),y
        iny
        lda ZP_BASE
        ora #1
        sta (ZP_SCR),y
        lda ZP_TMP
        sta (ZP_COL),y

        ldx ZP_ROW
        inx
        cpx #24
        beq .tr_row_done
        jmp .tr_row
.tr_row_done:

        ; Déplacement de Link vers la gauche pendant le défilement
        sec
        lda player_x
        sbc #15
        sta player_x
        lda player_x+1
        sbc #0
        sta player_x+1
        jsr player_draw

        inc ZP_STEP
        lda ZP_STEP
        cmp #20
        beq .tr_step_done
        jmp .tr_step
.tr_step_done:

        ; Fin de transition
        inc current_room_x
        lda #<(PLAYER_X_MIN + 4)
        ldx current_world_type
        cpx #WORLD_DUNGEON
        bne +
        lda #68
+       sta player_x
        lda #0
        sta player_x+1
        jmp trans_finish

; ---------------------------------------------------------------------------
; Transition vers la GAUCHE (Ouest) : l'écran défile vers la droite
; ---------------------------------------------------------------------------
!zone transition_left

transition_left:
        lda #STATE_TRANSITION
        sta game_state
        jsr enemies_clear
        ; Pointeur ZP_TGT vers la salle cible (current_room_x - 1)
        ldx current_room_y
        lda world_row_offset,x
        clc
        adc current_room_x
        sec
        sbc #1
        tax
        jsr trans_setup_target
.tl_step:
        jsr wait_frame
        jsr wait_frame

        ; Décalage horizontal : 2 colonnes vers la droite
        ; Concerne uniquement les lignes de jeu 4..23 (le HUD en 0..3 reste fixe)
        ldx #4
.tl_row:
        stx ZP_ROW

        lda scr_row_lo,x
        sta ZP_SCR
        lda scr_row_hi,x
        sta ZP_SCR+1
        lda col_row_hi,x
        sta ZP_COL+1
        lda ZP_SCR
        sta ZP_COL

        ; Destination = ZP_SCR + 2
        clc
        lda ZP_SCR
        adc #2
        sta ZP_DST
        lda ZP_SCR+1
        adc #0
        sta ZP_DST+1

        ; Décale 38 caractères écran de droite à gauche (colonnes 37..0 -> 39..2)
        ldy #37
.tl_shift_scr:
        lda (ZP_SCR),y
        sta (ZP_DST),y
        dey
        bpl .tl_shift_scr

        ; Destination couleur = ZP_COL + 2
        clc
        lda ZP_COL
        adc #2
        sta ZP_DST
        lda ZP_COL+1
        adc #0
        sta ZP_DST+1

        ldy #37
.tl_shift_col:
        lda (ZP_COL),y
        sta (ZP_DST),y
        dey
        bpl .tl_shift_col

        ; Insère la nouvelle tuile en colonnes 0 et 1 (colonne entrante = 19 - ZP_STEP)
        lda #19
        sec
        sbc ZP_STEP
        sta ZP_TCOL                     ; colonne de tuile entrante

        ; tr = (row - 4) / 2, sub_y = row & 1
        lda ZP_ROW
        sec
        sbc #4
        lsr
        tax
        lda tile_row_offset,x
        clc
        adc ZP_TCOL
        tay
        lda (ZP_TGT),y                  ; Tuile ID
        tax
        lda active_tile_color,x
        sta ZP_TMP
        lda tile_char_base,x
        sta ZP_BASE
        lda ZP_ROW
        and #1
        beq .tl_no_suby
        lda ZP_BASE
        ora #2
        sta ZP_BASE
.tl_no_suby:
        ldy #0
        lda ZP_BASE
        sta (ZP_SCR),y
        lda ZP_TMP
        sta (ZP_COL),y
        iny
        lda ZP_BASE
        ora #1
        sta (ZP_SCR),y
        lda ZP_TMP
        sta (ZP_COL),y

        ldx ZP_ROW
        inx
        cpx #24
        beq .tl_row_done
        jmp .tl_row
.tl_row_done:

        ; Déplacement de Link vers la droite pendant le défilement
        clc
        lda player_x
        adc #15
        sta player_x
        lda player_x+1
        adc #0
        sta player_x+1
        jsr player_draw

        inc ZP_STEP
        lda ZP_STEP
        cmp #20
        beq .tl_step_done
        jmp .tl_step
.tl_step_done:

        ; Fin de transition
        dec current_room_x
        lda #<(PLAYER_X_MAX - 4)
        ldy #>(PLAYER_X_MAX - 4)
        ldx current_world_type
        cpx #WORLD_DUNGEON
        bne +
        lda #<276
        ldy #>276
+       sta player_x
        sty player_x+1
        jmp trans_finish

; ---------------------------------------------------------------------------
; Transition vers le BAS (Sud) : l'écran défile vers le haut (2 rangées par étape)
; ---------------------------------------------------------------------------
!zone transition_down

transition_down:
        lda #STATE_TRANSITION
        sta game_state
        jsr enemies_clear
        ; Pointeur ZP_TGT vers la salle cible (current_room_y + 1)
        ldx current_room_y
        inx
        lda world_row_offset,x
        clc
        adc current_room_x
        tax
        jsr trans_setup_target
.td_step:
        jsr wait_frame
        jsr wait_frame

        ; Décale 18 rangées de jeu vers le haut (720 octets décalés de 80)
        ; Les lignes 0..3 (HUD) restent totalement intactes.
        ldx #0
.td_shift_0:
        lda SCREEN_RAM+240,x
        sta SCREEN_RAM+160,x
        lda COLOR_RAM+240,x
        sta COLOR_RAM+160,x
        inx
        bne .td_shift_0

        ldx #0
.td_shift_1:
        lda SCREEN_RAM+240+$100,x
        sta SCREEN_RAM+160+$100,x
        lda COLOR_RAM+240+$100,x
        sta COLOR_RAM+160+$100,x
        inx
        bne .td_shift_1

        ldx #0
.td_shift_2:
        lda SCREEN_RAM+240+$200,x
        sta SCREEN_RAM+160+$200,x
        lda COLOR_RAM+240+$200,x
        sta COLOR_RAM+160+$200,x
        inx
        cpx #208
        bne .td_shift_2

        ; Insère la nouvelle rangée de tuiles (tr = ZP_STEP) sur les lignes 22 et 23
        ldx ZP_STEP
        lda tile_row_offset,x
        sta ZP_TMP                      ; décalage dans la salle cible

        ldx #0                          ; colonne de tuile (0..19)
.td_put_row:
        stx ZP_TCOL
        txa
        clc
        adc ZP_TMP
        tay
        lda (ZP_TGT),y                  ; Tuile ID
        tax
        lda active_tile_color,x
        sta ZP_ROW                      ; couleur temporaire
        lda tile_char_base,x
        sta ZP_BASE                     ; caractère de base

        lda ZP_TCOL
        asl
        tay                             ; colonne écran (0, 2, 4...)

        ; Ligne 22 ($0770 / $db70 = 880)
        lda ZP_BASE
        sta SCREEN_RAM+880,y
        lda ZP_ROW
        sta COLOR_RAM+880,y
        iny
        lda ZP_BASE
        ora #1
        sta SCREEN_RAM+880,y
        lda ZP_ROW
        sta COLOR_RAM+880,y

        dey                             ; revient à colonne gauche
        ; Ligne 23 ($0798 / $db98 = 920)
        lda ZP_BASE
        ora #2
        sta SCREEN_RAM+920,y
        lda ZP_ROW
        sta COLOR_RAM+920,y
        iny
        lda ZP_BASE
        ora #3
        sta SCREEN_RAM+920,y
        lda ZP_ROW
        sta COLOR_RAM+920,y

        ldx ZP_TCOL
        inx
        cpx #20
        bne .td_put_row

        ; Déplacement de Link vers le haut pendant le défilement
        sec
        lda player_y
        sbc #14
        sta player_y
        jsr player_draw

        inc ZP_STEP
        lda ZP_STEP
        cmp #10
        beq .td_step_done
        jmp .td_step
.td_step_done:

        ; Fin de transition
        inc current_room_y
        lda #(PLAYER_Y_MIN + 4)
        ldx current_world_type
        cpx #WORLD_DUNGEON
        bne +
        lda #102
+       sta player_y
        jmp trans_finish

; ---------------------------------------------------------------------------
; Transition vers le HAUT (Nord) : l'écran défile vers le bas (2 rangées par étape)
; ---------------------------------------------------------------------------
!zone transition_up

transition_up:
        lda #STATE_TRANSITION
        sta game_state
        jsr enemies_clear
        ; Pointeur ZP_TGT vers la salle cible (current_room_y - 1)
        ldx current_room_y
        dex
        lda world_row_offset,x
        clc
        adc current_room_x
        tax
        jsr trans_setup_target
.tu_step:
        jsr wait_frame
        jsr wait_frame

        ; Décale 18 rangées de jeu vers le bas (720 octets, copie du bas vers le haut)
        ldx #208
.tu_shift_2:
        dex
        lda SCREEN_RAM+160+$200,x
        sta SCREEN_RAM+240+$200,x
        lda COLOR_RAM+160+$200,x
        sta COLOR_RAM+240+$200,x
        cpx #0
        bne .tu_shift_2

        ldx #0
.tu_shift_1:
        dex
        lda SCREEN_RAM+160+$100,x
        sta SCREEN_RAM+240+$100,x
        lda COLOR_RAM+160+$100,x
        sta COLOR_RAM+240+$100,x
        cpx #0
        bne .tu_shift_1

        ldx #0
.tu_shift_0:
        dex
        lda SCREEN_RAM+160,x
        sta SCREEN_RAM+240,x
        lda COLOR_RAM+160,x
        sta COLOR_RAM+240,x
        cpx #0
        bne .tu_shift_0

        ; Insère la nouvelle rangée de tuiles (tr = 9 - ZP_STEP) sur les lignes 4 et 5
        lda #9
        sec
        sbc ZP_STEP
        tax
        lda tile_row_offset,x
        sta ZP_TMP

        ldx #0
.tu_put_row:
        stx ZP_TCOL
        txa
        clc
        adc ZP_TMP
        tay
        lda (ZP_TGT),y                  ; Tuile ID
        tax
        lda active_tile_color,x
        sta ZP_ROW
        lda tile_char_base,x
        sta ZP_BASE

        lda ZP_TCOL
        asl
        tay

        ; Ligne 4 ($04a0 / $d8a0 = 160)
        lda ZP_BASE
        sta SCREEN_RAM+160,y
        lda ZP_ROW
        sta COLOR_RAM+160,y
        iny
        lda ZP_BASE
        ora #1
        sta SCREEN_RAM+160,y
        lda ZP_ROW
        sta COLOR_RAM+160,y

        dey
        ; Ligne 5 ($04c8 / $d8c8 = 200)
        lda ZP_BASE
        ora #2
        sta SCREEN_RAM+200,y
        lda ZP_ROW
        sta COLOR_RAM+200,y
        iny
        lda ZP_BASE
        ora #3
        sta SCREEN_RAM+200,y
        lda ZP_ROW
        sta COLOR_RAM+200,y

        ldx ZP_TCOL
        inx
        cpx #20
        bne .tu_put_row

        ; Déplacement de Link vers le bas pendant le défilement
        clc
        lda player_y
        adc #14
        sta player_y
        jsr player_draw

        inc ZP_STEP
        lda ZP_STEP
        cmp #10
        beq .tu_step_done
        jmp .tu_step
.tu_step_done:

        ; Fin de transition
        dec current_room_y
        lda #(PLAYER_Y_MAX - 4)
        ldx current_world_type
        cpx #WORLD_DUNGEON
        bne +
        lda #204
+       sta player_y
        jmp trans_finish
