; ---------------------------------------------------------------------------
; player.asm : position et affichage de Link (sprite 0)
; Coordonnées en pixels sprite. X sur 16 bits car l'écran fait plus de 255.
; Zone visible (cadre 320x200) : X 24..343, Y 50..249.
; Le sprite fait 24x21, donc X max = 343-23 = 320 et Y max = 249-20 = 229.
; ---------------------------------------------------------------------------
PLAYER_SPEED    = 2
PLAYER_X_MIN    = 24
PLAYER_X_MAX    = 320
PLAYER_Y_MIN    = 50
PLAYER_Y_MAX    = 229

player_x:       !word 172
player_y:       !byte 140

player_init:
        lda #(sprite_link >> 6)         ; pointeur = adresse / 64
        sta SPRITE_PTR0
        lda #COL_LGREEN
        sta VIC_SPRITE_COL0
        lda #%00000001                  ; active le sprite 0
        sta VIC_SPRITE_EN
        rts

player_update:
        lda joy
        and #JOY_LEFT
        beq .no_left
        sec
        lda player_x
        sbc #PLAYER_SPEED
        sta player_x
        lda player_x+1
        sbc #0
        sta player_x+1
.no_left:
        lda joy
        and #JOY_RIGHT
        beq .no_right
        clc
        lda player_x
        adc #PLAYER_SPEED
        sta player_x
        lda player_x+1
        adc #0
        sta player_x+1
.no_right:
        lda joy
        and #JOY_UP
        beq .no_up
        sec
        lda player_y
        sbc #PLAYER_SPEED
        sta player_y
.no_up:
        lda joy
        and #JOY_DOWN
        beq .no_down
        clc
        lda player_y
        adc #PLAYER_SPEED
        sta player_y
.no_down:

        ; --- bornes en X (16 bits) ---
        lda player_x+1
        bne .x_high
        lda player_x                    ; X < 256 : seulement la borne basse
        cmp #PLAYER_X_MIN
        bcs .x_done
        lda #PLAYER_X_MIN
        sta player_x
        jmp .x_done
.x_high:                                ; X >= 256 : seulement la borne haute
        lda player_x
        cmp #<(PLAYER_X_MAX + 1)
        bcc .x_done
        lda #<PLAYER_X_MAX
        sta player_x
        lda #>PLAYER_X_MAX
        sta player_x+1
.x_done:

        ; --- bornes en Y ---
        lda player_y
        cmp #PLAYER_Y_MIN
        bcs .y_not_low
        lda #PLAYER_Y_MIN
        sta player_y
.y_not_low:
        cmp #(PLAYER_Y_MAX + 1)
        bcc .y_done
        lda #PLAYER_Y_MAX
        sta player_y
.y_done:
        rts

; Recopie la position dans les registres VIC-II.
player_draw:
        lda player_x
        sta VIC_SPRITE_X0
        lda VIC_SPRITE_MSB
        and #%11111110
        ora player_x+1                  ; bit 8 de X (0 ou 1)
        sta VIC_SPRITE_MSB
        lda player_y
        sta VIC_SPRITE_Y0

        lda joy                         ; feu = sprite blanc (test d'entrée)
        and #JOY_FIRE
        beq .normal
        lda #COL_WHITE
        sta VIC_SPRITE_COL0
        rts
.normal:
        lda #COL_LGREEN
        sta VIC_SPRITE_COL0
        rts
