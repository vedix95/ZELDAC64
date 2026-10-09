; ---------------------------------------------------------------------------
; player.asm : position, déplacements, collisions de tuiles, marche animée
;              et attaque à l'épée
; Link est en sprite 0 (multicolore, 8x16 centré).
; L'épée est en sprite 1 (multicolore, 12x21 pleine taille, lame blanche).
; Coordonnées en pixels sprite. X sur 16 bits car l'écran fait plus de 255.
; Zone visible (cadre 320x200) : X 24..343, Y 50..249.
; Le dessin de Link (16x16) est décalé de (4,2) dans le sprite 24x21 :
;   X min = 24-4 = 20,  X max = 343-19 = 324
;   Y min = 50-2 = 48,  Y max = 249-17 = 232
;
; Boîte de collision des pieds de Link (au sol) :
;   X : player_x + 6 .. player_x + 17 (12 px de large)
;   Y : player_y + 11 .. player_y + 16 (6 px de haut)
; ---------------------------------------------------------------------------
PLAYER_SPEED    = 2
PLAYER_X_MIN    = 20
PLAYER_X_MAX    = 324
PLAYER_Y_MIN    = 80                    ; au-dessous du bandeau HUD (lignes 0..3 = 32 px)
PLAYER_Y_MAX    = 224                   ; 82 + 160 - 18 = 224

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
player_y:         !byte 150             ; centré dans la clairière (Zelda 1 NES)
player_dir:       !byte DIR_UP          ; Link regarde vers le haut (grotte)
player_has_sword: !byte 0               ; 0 = sans épée, 1 = épée obtenue dans la grotte

; Animation de marche
player_walk_anim: !byte 0               ; image courante (0 ou 1)
player_walk_tick: !byte 0               ; compteur de temporisation des pas

; Attaque à l'épée
player_attacking: !byte 0               ; décompte d'attaque (>0 = en cours)

; Variables de collision et déplacement temporaire
target_x:         !word 0
target_y:         !byte 0
col_x:            !word 0
col_y:            !byte 0
col_x1:           !word 0
col_x2:           !word 0
col_y1:           !byte 0
col_y2:           !byte 0
col_row_offset:   !byte 0

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
        ; Déclenchement sur appui Bouton X (Épée)
        lda btn_x_pressed
        beq .check_item_a
        ; Link ne peut attaquer que s'il a récupéré l'épée dans la grotte !
        lda player_has_sword
        beq .check_item_a
        lda #ATTACK_FRAMES
        sta player_attacking
        jsr sound_sword
        rts

.check_item_a:
        ; Déclenchement sur appui Bouton A (Arme secondaire équipée)
        lda btn_a_pressed
        beq .handle_movement
        jsr player_use_item_b
        rts

.handle_movement:
        ldx #0                          ; X = indicateur de mouvement (1 = marche)

        ; ===================================================================
        ; 1. DÉPLACEMENT VERS LA GAUCHE
        ; ===================================================================
        lda joy
        and #JOY_LEFT
        beq .no_left
        lda #DIR_LEFT
        sta player_dir

        sec
        lda player_x
        sbc #PLAYER_SPEED
        sta target_x
        lda player_x+1
        sbc #0
        sta target_x+1

        ; Vérifie si le bord gauche de l'écran est atteint
        lda target_x+1
        bne .left_not_border
        lda target_x
        cmp #PLAYER_X_MIN
        bcs .left_not_border
        lda current_room_x
        beq .clamp_left
        jsr transition_left
        jmp .no_left
.clamp_left:
        lda #PLAYER_X_MIN
        sta player_x
        jmp .no_left

.left_not_border:
        ; Collision tuiles sur le bord gauche des pieds : target_x + 6
        clc
        lda target_x
        adc #6
        sta col_x
        lda target_x+1
        adc #0
        sta col_x+1

        lda player_y
        clc
        adc #11
        sta col_y1
        lda player_y
        clc
        adc #16
        sta col_y2

        jsr check_v_edge
        bcs .no_left                    ; Bloqué par un obstacle !

        lda target_x
        sta player_x
        lda target_x+1
        sta player_x+1
        ldx #1
.no_left:

        ; ===================================================================
        ; 2. DÉPLACEMENT VERS LA DROITE
        ; ===================================================================
        lda joy
        and #JOY_RIGHT
        beq .no_right
        lda #DIR_RIGHT
        sta player_dir

        clc
        lda player_x
        adc #PLAYER_SPEED
        sta target_x
        lda player_x+1
        adc #0
        sta target_x+1

        ; Vérifie si le bord droit de l'écran est atteint
        lda target_x+1
        beq .right_not_border
        lda target_x
        cmp #<(PLAYER_X_MAX + 1)
        bcc .right_not_border
        lda current_room_x
        cmp #(WORLD_ROOMS_X - 1)
        bcs .clamp_right
        jsr transition_right
        jmp .no_right
.clamp_right:
        lda #<PLAYER_X_MAX
        sta player_x
        lda #>PLAYER_X_MAX
        sta player_x+1
        jmp .no_right

.right_not_border:
        ; Collision tuiles sur le bord droit des pieds : target_x + 17
        clc
        lda target_x
        adc #17
        sta col_x
        lda target_x+1
        adc #0
        sta col_x+1

        lda player_y
        clc
        adc #11
        sta col_y1
        lda player_y
        clc
        adc #16
        sta col_y2

        jsr check_v_edge
        bcs .no_right                   ; Bloqué par un obstacle !

        lda target_x
        sta player_x
        lda target_x+1
        sta player_x+1
        ldx #1
.no_right:

        ; ===================================================================
        ; 3. DÉPLACEMENT VERS LE HAUT
        ; ===================================================================
        lda joy
        and #JOY_UP
        beq .no_up
        lda #DIR_UP
        sta player_dir

        sec
        lda player_y
        sbc #PLAYER_SPEED
        sta target_y

        ; Vérifie si le bord haut de l'écran est atteint
        cmp #PLAYER_Y_MIN
        bcs .up_not_border
        lda current_room_y
        beq .clamp_up
        jsr transition_up
        jmp .no_up
.clamp_up:
        lda #PLAYER_Y_MIN
        sta player_y
        jmp .no_up

.up_not_border:
        ; Collision tuiles sur le bord haut des pieds : target_y + 11
        clc
        lda target_y
        adc #11
        sta col_y

        clc
        lda player_x
        adc #6
        sta col_x1
        lda player_x+1
        adc #0
        sta col_x1+1

        clc
        lda player_x
        adc #17
        sta col_x2
        lda player_x+1
        adc #0
        sta col_x2+1

        jsr check_h_edge
        bcs .no_up                      ; Bloqué par un obstacle !

        lda target_y
        sta player_y
        ldx #1
.no_up:

        ; ===================================================================
        ; 4. DÉPLACEMENT VERS LE BAS
        ; ===================================================================
        lda joy
        and #JOY_DOWN
        beq .no_down
        lda #DIR_DOWN
        sta player_dir

        clc
        lda player_y
        adc #PLAYER_SPEED
        sta target_y

        ; Vérifie si le bord bas de l'écran est atteint
        cmp #(PLAYER_Y_MAX + 1)
        bcc .down_not_border
        lda current_room_y
        cmp #(WORLD_ROOMS_Y - 1)
        bcs .clamp_down
        jsr transition_down
        jmp .no_down
.clamp_down:
        lda #PLAYER_Y_MAX
        sta player_y
        jmp .no_down

.down_not_border:
        ; Collision tuiles sur le bord bas des pieds : target_y + 16
        clc
        lda target_y
        adc #16
        sta col_y

        clc
        lda player_x
        adc #6
        sta col_x1
        lda player_x+1
        adc #0
        sta col_x1+1

        clc
        lda player_x
        adc #17
        sta col_x2
        lda player_x+1
        adc #0
        sta col_x2+1

        jsr check_h_edge
        bcs .no_down                    ; Bloqué par un obstacle !

        lda target_y
        sta player_y
        ldx #1
.no_down:

        ; ===================================================================
        ; ANIMATION DES PAS
        ; ===================================================================
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
        ; Test si Link marche sur une entrée de grotte (TILE_CAVE)
        lda player_y
        clc
        adc #12                         ; niveau des pieds de Link
        sta col_y
        lda player_x
        clc
        adc #12                         ; centre horizontal de Link
        sta col_x
        lda player_x+1
        adc #0
        sta col_x+1
        jsr get_tile_at_point
        cmp #TILE_CAVE
        bne +
        jsr cave_enter
+       rts

; ---------------------------------------------------------------------------
; check_v_edge : teste 2 points sur une colonne verticale (col_x, col_y1) et (col_x, col_y2)
; Sortie : Carry = 1 si bloqué, Carry = 0 si libre
; ---------------------------------------------------------------------------
check_v_edge:
        lda col_y1
        sta col_y
        jsr check_point_solid
        bcs .v_blocked
        lda col_y2
        sta col_y
        jsr check_point_solid
        bcs .v_blocked
        clc
        rts
.v_blocked:
        sec
        rts

; ---------------------------------------------------------------------------
; check_h_edge : teste 2 points sur une ligne horizontale (col_x1, col_y) et (col_x2, col_y)
; Sortie : Carry = 1 si bloqué, Carry = 0 si libre
; ---------------------------------------------------------------------------
check_h_edge:
        lda col_x1
        sta col_x
        lda col_x1+1
        sta col_x+1
        jsr check_point_solid
        bcs .h_blocked
        lda col_x2
        sta col_x
        lda col_x2+1
        sta col_x+1
        jsr check_point_solid
        bcs .h_blocked
        clc
        rts
.h_blocked:
        sec
        rts

; ---------------------------------------------------------------------------
; ---------------------------------------------------------------------------
; get_tile_at_point : renvoie l'ID de la tuile au point (col_x:col_x+1, col_y)
; Sortie : A = ID de tuile ($ff si hors écran)
; ---------------------------------------------------------------------------
get_tile_at_point:
        ; 1. Coordonnée Y : map_y = col_y - 82 (début ligne 4 de texte = 50 + 32)
        lda col_y
        cmp #82
        bcc .tile_off_screen
        sec
        sbc #82
        cmp #160                        ; hauteur de jeu = 160 px (10 tuiles)
        bcs .tile_off_screen
        lsr
        lsr
        lsr
        lsr                             ; tile_y = 0..9
        tax
        lda tile_row_offset,x           ; tile_y * 20
        sta col_row_offset

        ; 2. Coordonnée X : map_x = col_x - 24
        sec
        lda col_x
        sbc #24
        sta ZP_TMP
        lda col_x+1
        sbc #0
        bne .tile_x_high

        ; X < 256 : tile_x = ZP_TMP >> 4 (0..15)
        lda ZP_TMP
        lsr
        lsr
        lsr
        lsr
        jmp .tile_fetch

.tile_x_high:
        ; X >= 256 : tile_x = 16 + (ZP_TMP >> 4)
        lda ZP_TMP
        cmp #64                         ; 256 + 64 = 320 max
        bcs .tile_off_screen
        lsr
        lsr
        lsr
        lsr
        ora #16

.tile_fetch:
        clc
        adc col_row_offset
        tay
        lda (ZP_MAP),y                  ; ID de tuile dans la salle active
        rts

.tile_off_screen:
        lda #$ff
        rts

; ---------------------------------------------------------------------------
; check_point_solid : teste si le point (col_x:col_x+1, col_y) touche une tuile solide
; Entrée : col_x (16 bits), col_y (8 bits)
; Sortie : Carry = 1 si solide, Carry = 0 si libre
; ---------------------------------------------------------------------------
check_point_solid:
        jsr get_tile_at_point
        cmp #$ff
        beq .free
        tax
        lda tile_flags,x
        and #TILE_SOLID
        beq .free
        sec                             ; Solide !
        rts

.free:
        clc                             ; Libre !
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

; ---------------------------------------------------------------------------
; player_use_item_b : déclenché par le Bouton B (arme secondaire équipée)
; ---------------------------------------------------------------------------
player_use_item_b:
        jsr items_use_b
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

        ; Active les deux sprites (préserve armes et ennemis sur bits 2..7)
        lda VIC_SPRITE_EN
        and #%11111100
        ora #%00000011
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

        ; Masque le sprite 1 (épée rangée) et gère le clignotement d'invincibilité
        lda VIC_SPRITE_EN
        and #%11111100                  ; efface sprites 0 et 1
        sta ZP_TMP
        lda player_hurt_timer
        beq .link_visible
        and #2                          ; clignote toutes les 2 frames
        bne .link_hidden
.link_visible:
        lda ZP_TMP
        ora #%00000001                  ; active sprite 0
        sta ZP_TMP
.link_hidden:
        lda ZP_TMP
        sta VIC_SPRITE_EN

        ; Pointeur Sprite 0 : base + (player_dir << 1) + player_walk_anim
        lda player_dir
        asl
        ora player_walk_anim
        clc
        adc #(sprite_link_down_0 >> 6)
        sta SPRITE_PTR0
        rts
