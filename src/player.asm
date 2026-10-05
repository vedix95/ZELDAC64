; ---------------------------------------------------------------------------
; player.asm : position et affichage de Link (sprite 0, multicolore)
; Coordonnées en pixels sprite. X sur 16 bits car l'écran fait plus de 255.
; Zone visible (cadre 320x200) : X 24..343, Y 50..249.
; Le dessin de Link (16x16) est décalé de (4,2) dans le sprite 24x21 :
;   X min = 24-4 = 20,  X max = 343-19 = 324
;   Y min = 50-2 = 48,  Y max = 249-17 = 232
; ---------------------------------------------------------------------------
PLAYER_SPEED    = 2
PLAYER_X_MIN    = 20
PLAYER_X_MAX    = 324
PLAYER_Y_MIN    = 48
PLAYER_Y_MAX    = 224                   ; la carte fait 192 px : 50+192-1-17

; Directions : l'ordre doit suivre celui des images dans assets/link.txt
DIR_DOWN        = 0
DIR_UP          = 1
DIR_LEFT        = 2
DIR_RIGHT       = 3

PLAYER_COLOR    = COL_GREEN             ; couleur propre : tunique
PLAYER_SKIN     = COL_LRED              ; multicolore 1  : peau
PLAYER_BROWN    = COL_BROWN             ; multicolore 2  : cheveux, ceinture...

player_x:       !word 180               ; carrefour au centre : tuile 10 (24 + 10*16 - 4)
player_y:       !byte 128               ; tuile 5 (50 + 5*16 - 2)
player_dir:     !byte DIR_DOWN

player_init:
        lda #PLAYER_COLOR
        sta VIC_SPRITE_COL0
        lda #PLAYER_SKIN
        sta VIC_SPRITE_MC1
        lda #PLAYER_BROWN
        sta VIC_SPRITE_MC2
        lda #%00000001
        sta VIC_SPRITE_MC               ; sprite 0 en multicolore
        sta VIC_SPRITE_EN               ; et visible
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
        lda #DIR_LEFT
        sta player_dir
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
        lda #DIR_RIGHT
        sta player_dir
.no_right:
        lda joy
        and #JOY_UP
        beq .no_up
        sec
        lda player_y
        sbc #PLAYER_SPEED
        sta player_y
        lda #DIR_UP
        sta player_dir
.no_up:
        lda joy
        and #JOY_DOWN
        beq .no_down
        clc
        lda player_y
        adc #PLAYER_SPEED
        sta player_y
        lda #DIR_DOWN
        sta player_dir
.no_down:

        ; --- Bornes en X (16 bits) et transition d'écran ---
        lda player_x+1
        bne .x_high
        lda player_x                    ; X < 256 : vérification bord gauche
        cmp #PLAYER_X_MIN
        bcs .x_done                     ; player_x >= PLAYER_X_MIN -> dans l'écran
        lda current_room_x
        beq .clamp_x_min                ; bord du monde gauche atteint
        dec current_room_x
        lda #<PLAYER_X_MAX
        sec
        sbc #4
        sta player_x
        lda #>PLAYER_X_MAX
        sbc #0
        sta player_x+1
        jsr load_room
        jmp .x_done
.clamp_x_min:
        lda #PLAYER_X_MIN
        sta player_x
        jmp .x_done

.x_high:                                ; X >= 256 : vérification bord droit
        lda player_x
        cmp #<(PLAYER_X_MAX + 1)
        bcc .x_done                     ; player_x <= PLAYER_X_MAX -> dans l'écran
        lda current_room_x
        cmp #(WORLD_ROOMS_X - 1)
        bcs .clamp_x_max                ; bord du monde droit atteint
        inc current_room_x
        lda #(PLAYER_X_MIN + 4)
        sta player_x
        lda #0
        sta player_x+1
        jsr load_room
        jmp .x_done
.clamp_x_max:
        lda #<PLAYER_X_MAX
        sta player_x
        lda #>PLAYER_X_MAX
        sta player_x+1
.x_done:

        ; --- Bornes en Y et transition d'écran ---
        lda player_y
        cmp #PLAYER_Y_MIN
        bcs .check_y_max
        lda current_room_y
        beq .clamp_y_min                ; bord du monde haut atteint
        dec current_room_y
        lda #(PLAYER_Y_MAX - 4)
        sta player_y
        jsr load_room
        jmp .y_done
.clamp_y_min:
        lda #PLAYER_Y_MIN
        sta player_y
        jmp .y_done

.check_y_max:
        cmp #(PLAYER_Y_MAX + 1)
        bcc .y_done
        lda current_room_y
        cmp #(WORLD_ROOMS_Y - 1)
        bcs .clamp_y_max                ; bord du monde bas atteint
        inc current_room_y
        lda #(PLAYER_Y_MIN + 4)
        sta player_y
        jsr load_room
        jmp .y_done
.clamp_y_max:
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

        clc                             ; images consécutives : base + direction
        lda #(sprite_link_down >> 6)
        adc player_dir
        sta SPRITE_PTR0

        lda joy                         ; feu = tunique blanche (test d'entrée)
        and #JOY_FIRE
        beq .normal
        lda #COL_WHITE
        sta VIC_SPRITE_COL0
        rts
.normal:
        lda #PLAYER_COLOR
        sta VIC_SPRITE_COL0
        rts
