; ---------------------------------------------------------------------------
; player.asm : position, déplacements, attaque à l'épée et affichage de Link
; Link est en sprite 0 (multicolore).
; L'épée est en sprite 1 (multicolore, lame blanche, garde or/marron).
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

ATTACK_FRAMES   = 10                    ; durée du coup d'épée en images (0.2s)

; Directions : l'ordre suit celui des images dans assets/link.txt
DIR_DOWN        = 0
DIR_UP          = 1
DIR_LEFT        = 2
DIR_RIGHT       = 3

PLAYER_COLOR    = COL_GREEN             ; tunique de Link
PLAYER_SKIN     = COL_LRED              ; multicolore 1  : peau / garde or
PLAYER_BROWN    = COL_BROWN             ; multicolore 2  : cheveux, ceinture, manche
SWORD_COLOR     = COL_WHITE             ; couleur propre sprite 1 : lame brillante

player_x:         !word 180             ; départ au centre
player_y:         !byte 128
player_dir:       !byte DIR_DOWN
player_attacking: !byte 0               ; compteur d'images d'attaque (>0 = attaque en cours)

sword_x:          !word 0
sword_y:          !byte 0

; Décalages de l'épée selon la direction (bas, haut, gauche, droite)
sword_off_x_lo:   !byte 0, 0, <(-12), 12
sword_off_x_hi:   !byte 0, 0, >(-12), 0
sword_off_y:      !byte 12, <(-12), 0, 0

player_init:
        lda #PLAYER_COLOR
        sta VIC_SPRITE_COL0
        lda #SWORD_COLOR
        sta VIC_SPRITE_COL1
        lda #PLAYER_SKIN
        sta VIC_SPRITE_MC1
        lda #PLAYER_BROWN
        sta VIC_SPRITE_MC2
        lda #%00000011                  ; sprites 0 et 1 en multicolore
        sta VIC_SPRITE_MC
        lda #%00000001                  ; seul le sprite 0 est actif au départ
        sta VIC_SPRITE_EN
        lda #0
        sta player_attacking
        rts

player_update:
        ; --- Gestion de l'attaque en cours ---
        lda player_attacking
        beq .check_attack_start
        dec player_attacking
        bne .attacking_active
        ; Fin de l'attaque : couper la porte sonore SID
        lda #%10000000
        sta SID_V1_CTRL
.attacking_active:
        rts                             ; Link reste immobile pendant le coup d'épée

.check_attack_start:
        ; Déclenchement de l'attaque sur appui bouton Feu (front montant)
        lda joy_pressed
        and #JOY_FIRE
        beq .handle_movement
        lda #ATTACK_FRAMES
        sta player_attacking
        jsr sound_sword
        rts                             ; pas de déplacement sur l'image d'impact

.handle_movement:
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
        jsr transition_left
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
        jsr transition_right
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
        jsr transition_up
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
        jsr transition_down
        jmp .y_done
.clamp_y_max:
        lda #PLAYER_Y_MAX
        sta player_y
.y_done:
        rts

; Bruitage d'attaque à l'épée via le synthétiseur SID (bruit blanc + déclin rapide)
sound_sword:
        lda #15
        sta SID_VOLUME                  ; volume maximum
        lda #$00
        sta SID_V1_FREQ_LO
        lda #$40
        sta SID_V1_FREQ_HI              ; fréquence de souffle
        lda #$09                        ; Attaque 2 ms, Déclin ~168 ms
        sta SID_V1_AD
        lda #$00                        ; Soutien 0, Relâchement 6 ms
        sta SID_V1_SR
        lda #%10000001                  ; Forme d'onde : Bruit (Noise) + Gate ON
        sta SID_V1_CTRL
        rts

; Recopie la position et les pointeurs dans les registres VIC-II.
player_draw:
        ; Position de base de Link (Sprite 0)
        lda player_x
        sta VIC_SPRITE_X0
        lda player_y
        sta VIC_SPRITE_Y0

        ; Si Link n'attaque pas : affichage normal
        lda player_attacking
        beq .draw_normal

        ; --- Affichage en cours d'attaque ---
        ; Pointeur Sprite 0 : base + 4 + player_dir (postures de fente)
        clc
        lda #(sprite_link_down >> 6)
        adc #4
        adc player_dir
        sta SPRITE_PTR0

        ; Pointeur Sprite 1 : base + 8 + player_dir (lames de l'épée)
        clc
        lda #(sprite_link_down >> 6)
        adc #8
        adc player_dir
        sta SPRITE_PTR1

        ; Calcul de la position de l'épée (Sprite 1)
        ldx player_dir
        clc
        lda player_x
        adc sword_off_x_lo,x
        sta sword_x
        lda player_x+1
        adc sword_off_x_hi,x
        sta sword_x+1

        clc
        lda player_y
        adc sword_off_y,x
        sta sword_y

        lda sword_x
        sta VIC_SPRITE_X1
        lda sword_y
        sta VIC_SPRITE_Y1

        ; MSB pour Sprites 0 et 1
        lda VIC_SPRITE_MSB
        and #%11111100                  ; efface bits 0 et 1
        ora player_x+1                  ; bit 0 = sprite 0
        ldy sword_x+1
        tya
        and #1
        beq +
        ora #%00000010                  ; bit 1 = sprite 1
+       sta VIC_SPRITE_MSB

        ; Active les deux sprites (Link + Epée)
        lda #%00000011
        sta VIC_SPRITE_EN
        rts

.draw_normal:
        ; Seul le sprite 0 est actif (épée masquée)
        lda #%00000001
        sta VIC_SPRITE_EN

        ; MSB pour Sprite 0
        lda VIC_SPRITE_MSB
        and #%11111100
        ora player_x+1
        sta VIC_SPRITE_MSB

        ; Pointeur Sprite 0 : base + player_dir (images consécutives 0..3)
        clc
        lda #(sprite_link_down >> 6)
        adc player_dir
        sta SPRITE_PTR0
        rts
