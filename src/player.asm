; ---------------------------------------------------------------------------
; player.asm : position, déplacements, marche animée et attaque à l'épée
; Link est en sprite 0 (multicolore, 8x16 centré).
; L'épée est en sprite 1 (multicolore, 12x21 pleine taille, lame blanche).
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

WALK_TICK_MAX   = 6                     ; cadence d'alternance des pas (~8 Hz)
ATTACK_FRAMES   = 12                    ; durée totale du coup d'épée (0.24s)

; Directions : l'ordre suit celui des images dans assets/link.txt
DIR_DOWN        = 0
DIR_UP          = 1
DIR_LEFT        = 2
DIR_RIGHT       = 3

PLAYER_COLOR    = COL_GREEN             ; tunique de Link
PLAYER_SKIN     = COL_LRED              ; multicolore 1  : peau / garde dorée
PLAYER_BROWN    = COL_BROWN             ; multicolore 2  : cheveux, ceinture, poignée
SWORD_COLOR     = COL_WHITE             ; couleur propre sprite 1 : lame blanche brillante

player_x:         !word 180             ; position courante de Link
player_y:         !byte 128
player_dir:       !byte DIR_DOWN

; Animation de marche
player_walk_anim: !byte 0               ; image courante (0 ou 1)
player_walk_tick: !byte 0               ; compteur de temporisation des pas

; Attaque à l'épée
player_attacking: !byte 0               ; décompte d'attaque (>0 = en cours)

; Coordonnées temporaires de dessin
link_draw_x:      !word 0
link_draw_y:      !byte 0
sword_x:          !word 0
sword_y:          !byte 0

; Décalages de l'épée : phase courte (extension / retrait, frames 12..10 et 3..1)
sword_short_off_x_lo: !byte 0, 0, <(-10), 10
sword_short_off_x_hi: !byte 0, 0, >(-10), 0
sword_short_off_y:    !byte 8, <(-10), 0, 0

; Décalages de l'épée : pleine fente (frappe maximale, frames 9..4)
sword_full_off_x_lo:  !byte 0, 0, <(-16), 16
sword_full_off_x_hi:  !byte 0, 0, >(-16), 0
sword_full_off_y:     !byte 14, <(-16), 0, 0

; Avancée du corps de Link pendant la pleine fente (2 pixels de lunge)
link_lunge_x_lo:      !byte 0, 0, <(-2), 2
link_lunge_x_hi:      !byte 0, 0, >(-2), 0
link_lunge_y:         !byte 2, <(-2), 0, 0

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
        sta player_walk_anim
        sta player_walk_tick
        rts

player_update:
        ; --- Gestion du coup d'épée ---
        lda player_attacking
        beq .check_attack_start
        dec player_attacking
        bne .attacking_active
        ; Fin de l'attaque : couper la porte sonore SID
        lda #%10000000
        sta SID_V1_CTRL
.attacking_active:
        rts                             ; Link reste immobile pendant le coup

.check_attack_start:
        ; Déclenchement sur appui bouton Feu (front montant)
        lda joy_pressed
        and #JOY_FIRE
        beq .handle_movement
        lda #ATTACK_FRAMES
        sta player_attacking
        jsr sound_sword
        rts

.handle_movement:
        ldx #0                          ; X = indicateur de mouvement (1 = marche)

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
        ldx #1
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
        ldx #1
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
        ldx #1
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
        ldx #1
.no_down:

        ; --- Animation des pas ---
        cpx #1
        bne .idle
        inc player_walk_tick
        lda player_walk_tick
        cmp #WALK_TICK_MAX
        bcc .anim_done
        lda #0
        sta player_walk_tick
        lda player_walk_anim
        eor #1                          ; alterne entre 0 et 1
        sta player_walk_anim
        jmp .anim_done
.idle:
        lda #0
        sta player_walk_tick
        sta player_walk_anim            ; retour posture neutre à l'arrêt
.anim_done:

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

; Bruitage d'attaque à l'épée via le synthétiseur SID (bruit blanc + déclin percussif)
sound_sword:
        lda #15
        sta SID_VOLUME                  ; volume maximum
        lda #$00
        sta SID_V1_FREQ_LO
        lda #$48
        sta SID_V1_FREQ_HI              ; souffle d'acier tranchant
        lda #$09                        ; Attaque 2 ms, Déclin ~168 ms
        sta SID_V1_AD
        lda #$00                        ; Soutien 0, Relâchement 6 ms
        sta SID_V1_SR
        lda #%10000001                  ; Forme d'onde : Bruit (Noise) + Gate ON
        sta SID_V1_CTRL
        rts

; Recopie la position et les pointeurs dans les registres VIC-II.
player_draw:
        lda player_attacking
        bne +
        jmp .draw_normal
+

        ; ===================================================================
        ; LINK EN ATTAQUE (Fente dynamique + Grande Épée)
        ; ===================================================================
        ; Pointeur Sprite 0 : base + 8 + player_dir (postures attack_*)
        clc
        lda #(sprite_link_down_0 >> 6)
        adc #8
        adc player_dir
        sta SPRITE_PTR0

        ; Pointeur Sprite 1 : base + 12 + player_dir (lames sword_*)
        clc
        lda #(sprite_link_down_0 >> 6)
        adc #12
        adc player_dir
        sta SPRITE_PTR1

        ; Phase d'animation selon le compte d'images (12..10 = fente courte,
        ; 9..4 = pleine extension + avancée du corps, 3..1 = retrait)
        lda player_attacking
        cmp #10
        bcs .use_short                  ; frames 12, 11, 10
        cmp #4
        bcc .use_short                  ; frames 3, 2, 1

        ; --- Pleine extension (frames 9..4) ---
        ldx player_dir
        ; Avancée de Link de 2 pixels
        clc
        lda player_x
        adc link_lunge_x_lo,x
        sta link_draw_x
        lda player_x+1
        adc link_lunge_x_hi,x
        sta link_draw_x+1
        clc
        lda player_y
        adc link_lunge_y,x
        sta link_draw_y

        ; Position de l'épée à pleine allonge
        clc
        lda player_x
        adc sword_full_off_x_lo,x
        sta sword_x
        lda player_x+1
        adc sword_full_off_x_hi,x
        sta sword_x+1
        clc
        lda player_y
        adc sword_full_off_y,x
        sta sword_y
        jmp .apply_positions

.use_short:
        ; --- Extension courte / retrait ---
        lda player_x
        sta link_draw_x
        lda player_x+1
        sta link_draw_x+1
        lda player_y
        sta link_draw_y

        ldx player_dir
        clc
        lda player_x
        adc sword_short_off_x_lo,x
        sta sword_x
        lda player_x+1
        adc sword_short_off_x_hi,x
        sta sword_x+1
        clc
        lda player_y
        adc sword_short_off_y,x
        sta sword_y

.apply_positions:
        ; Écrit les positions VIC-II
        lda link_draw_x
        sta VIC_SPRITE_X0
        lda link_draw_y
        sta VIC_SPRITE_Y0

        lda sword_x
        sta VIC_SPRITE_X1
        lda sword_y
        sta VIC_SPRITE_Y1

        ; MSB pour Sprites 0 et 1
        lda VIC_SPRITE_MSB
        and #%11111100                  ; efface bits 0 et 1
        sta ZP_TMP

        lda link_draw_x+1
        and #1
        ora ZP_TMP
        sta ZP_TMP

        lda sword_x+1
        and #1
        asl                             ; bit 1 = sprite 1
        ora ZP_TMP
        sta VIC_SPRITE_MSB

        ; Active les deux sprites
        lda #%00000011
        sta VIC_SPRITE_EN
        rts

        ; ===================================================================
        ; LINK EN MARCHE NORMALE (Pas alternés 0 / 1)
        ; ===================================================================
.draw_normal:
        ; Position de base de Link
        lda player_x
        sta VIC_SPRITE_X0
        lda player_y
        sta VIC_SPRITE_Y0

        ; MSB pour Sprite 0
        lda VIC_SPRITE_MSB
        and #%11111100
        sta ZP_TMP
        lda player_x+1
        and #1
        ora ZP_TMP
        sta VIC_SPRITE_MSB

        ; Masque le sprite 1 (épée rangée)
        lda #%00000001
        sta VIC_SPRITE_EN

        ; Pointeur Sprite 0 : base + (player_dir << 1) + player_walk_anim
        lda player_dir
        asl
        ora player_walk_anim
        clc
        adc #(sprite_link_down_0 >> 6)
        sta SPRITE_PTR0
        rts
