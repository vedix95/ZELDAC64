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
PLAYER_SKIN     = COL_LIGHT_RED         ; multicolore 1  : peau / chair authentique (rose/flesh C64)
PLAYER_BROWN    = COL_BROWN             ; multicolore 2  : cheveux, ceinture, poignée
SWORD_COLOR     = COL_WHITE             ; couleur propre sprite 1 : lame blanche brillante

player_x:         !word 180             ; position courante de Link
player_y:         !byte 150             ; centré dans la clairière (Zelda 1)
player_dir:       !byte DIR_UP          ; Link regarde vers le haut (grotte)
player_has_sword:      !byte 0          ; 0 = sans épée, 1 = bois, 2 = blanche, 3 = magique
player_has_shield:     !byte 1          ; 1 = petit bouclier, 2 = grand bouclier magique
player_has_blue_ring:  !byte 0          ; 0 = tunique verte, 1 = anneau bleu (dégâts divisés par 2)
player_has_bracelet:   !byte 0          ; 1 = bracelet de force
player_has_raft:       !byte 0          ; 1 = radeau
player_has_stepladder: !byte 0          ; 1 = échelle
ladder_tile_idx:       !byte $ff        ; $ff = inactive, 0..199 = tuile d'eau où l'échelle est posée
player_has_magic_key:  !byte 0          ; 1 = clef magique

; Objets d'inventaire Slot B
player_has_boomerang:  !byte 1          ; 1 = boomerang
player_has_bow:        !byte 1          ; 1 = arc
player_has_arrows:     !byte 1          ; 1 = flèches
player_has_candle:     !byte 1          ; 1 = bougie bleue
player_has_food:       !byte 0          ; 1 = viande / appât
player_has_potion:     !byte 0          ; 0 = aucune, 1 = bleue, 2 = rouge
player_has_whistle:    !byte 1          ; 1 = flûte magique
player_has_wand:       !byte 1          ; 1 = baguette magique


player_has_compass:     !byte 0          ; 1 = boussole du donjon actif
player_has_dungeon_map:  !byte 0          ; 1 = plan du donjon actif
player_has_book:         !byte 0          ; 1 = livre magique (flammes de la baguette)

; Triforce de la Sagesse (8 fragments numérotés 1 à 8)
player_triforce_pieces: !byte %00000000 ; masque 8 bits
player_blue_ring_hits:  !byte 0          ; compteur alternance dégâts Anneau Bleu

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
        sta VIC_SPRITE_EXP_X            ; réinitialise l'agrandissement X
        sta VIC_SPRITE_EXP_Y            ; réinitialise l'agrandissement Y
        sta player_attacking
        sta player_walk_anim
        sta player_walk_tick
        lda #$ff
        sta ladder_tile_idx
        rts

player_update:
        lda triforce_fanfare_timer
        beq +
        rts
+
        ; --- Gestion du coup d'épée ---
        lda player_attacking
        beq .check_attack_start
        dec player_attacking
        bne .attacking_active
        ; Fin de l'attaque (la voix sonore est gérée par le timer SFX de sound.asm)
.attacking_active:
        rts                             ; Link reste immobile pendant le coup

.check_attack_start:
        ; Déclenchement sur appui Bouton X (Manette Xbox Bouton X / Touche 'X' / Espace : Épée)
        lda btn_x_pressed
        beq .check_item_a
        ; Link ne peut attaquer que s'il a récupéré l'épée dans la grotte !
        lda player_has_sword
        beq .check_item_a
        ; Si l'épée est maudite par un Bubble : impossible d'attaquer
        lda sword_cursed_timer
        bne .check_item_a
        lda #ATTACK_FRAMES
        sta player_attacking
        jsr sound_sword
        rts

.check_item_a:
        ; Déclenchement sur appui Bouton A (Manette Xbox Bouton A / Feu joystick : Arme secondaire)
        lda btn_a_pressed
        beq .handle_movement
        jsr player_use_item_b
        rts

.handle_movement:
        ; Détection de sortie de l'eau pour ranger l'échelle
        lda ladder_tile_idx
        cmp #$ff
        beq .ladder_check_done
        lda player_y
        clc
        adc #12
        sta col_y
        lda player_x
        clc
        adc #12
        sta col_x
        lda player_x+1
        adc #0
        sta col_x+1
        jsr get_tile_at_point
        cmp #TILE_BRIDGE_H
        beq .ladder_check_done
        cmp #TILE_BRIDGE_V
        beq .ladder_check_done
        cmp #TILE_WATER
        beq .ladder_check_done
        ; Link est sur la terre ferme : on retire l'échelle et rétablit l'eau
        ldy ladder_tile_idx
        lda #TILE_WATER
        sta room_buf,y
        jsr redraw_single_tile
        lda #$ff
        sta ladder_tile_idx
.ladder_check_done:

        ldx #0                          ; X = indicateur de mouvement (1 = marche)

        ; ===================================================================
        ; 1. DÉPLACEMENT VERS LA GAUCHE
        ; ===================================================================
        lda joy
        and #JOY_LEFT
        bne +
        jmp .no_left
+       lda #DIR_LEFT
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
        lda current_world_type
        cmp #WORLD_DUNGEON
        bne +
        lda player_y
        cmp #125
        bcc .clamp_left
        cmp #180
        bcs .clamp_left
        ldy #80
        lda room_buf,y
        cmp #TILE_DUNG_DOOR_OPEN
        bne .clamp_left
+       jsr transition_left
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
        adc #10
        sta col_y1
        lda player_y
        clc
        adc #15
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
        bne +
        jmp .no_right
+       lda #DIR_RIGHT
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
        lda map_rooms_w
        sec
        sbc #1
        cmp current_room_x
        beq .clamp_right
        bcc .clamp_right
        lda current_world_type
        cmp #WORLD_DUNGEON
        bne +
        lda player_y
        cmp #125
        bcc .clamp_right
        cmp #180
        bcs .clamp_right
        ldy #99
        lda room_buf,y
        cmp #TILE_DUNG_DOOR_OPEN
        bne .clamp_right
+       jsr transition_right
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
        adc #10
        sta col_y1
        lda player_y
        clc
        adc #15
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
        bne +
        jmp .no_up
+       lda #DIR_UP
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
        lda current_world_type
        cmp #WORLD_DUNGEON
        bne +
        lda player_x+1
        bne .clamp_up
        lda player_x
        cmp #145
        bcc .clamp_up
        cmp #215
        bcs .clamp_up
        ldy #9
        lda room_buf,y
        cmp #TILE_DUNG_DOOR_OPEN
        bne .clamp_up
+       jsr transition_up
        jmp .no_up
.clamp_up:
        lda #PLAYER_Y_MIN
        sta player_y
        jmp .no_up

.up_not_border:
        ; Collision tuiles sur le haut du corps : target_y + 5 (évite l'immersion dans les murs et l'eau)
        clc
        lda target_y
        adc #5
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
        bne +
        jmp .no_down
+       lda #DIR_DOWN
        sta player_dir

        clc
        lda player_y
        adc #PLAYER_SPEED
        sta target_y

        ; Si on est dans le donjon dans la salle d'entrée du donjon actif, franchir le seuil sud = sortir
        lda current_world_type
        cmp #WORLD_DUNGEON
        bne .chk_border_down
        lda current_room_x
        cmp dungeon_entrance_room_x
        bne .chk_border_down
        lda current_room_y
        cmp dungeon_entrance_room_y
        bne .chk_border_down
        lda player_x+1
        bne .chk_border_down
        lda player_x
        cmp #145
        bcc .chk_border_down
        cmp #215
        bcs .chk_border_down
        lda target_y
        cmp #214
        bcc .chk_border_down
        jsr exit_dungeon
        jmp .no_down

.chk_border_down:
        ; Vérifie si le bord bas de l'écran est atteint
        lda target_y
        cmp #(PLAYER_Y_MAX + 1)
        bcc .down_not_border

        ; Déplacement vers le bas : changement de salle
        lda map_rooms_h
        sec
        sbc #1
        cmp current_room_y
        beq .clamp_down
        bcc .clamp_down
        lda current_world_type
        cmp #WORLD_DUNGEON
        bne +
        lda player_x+1
        bne .clamp_down
        lda player_x
        cmp #145
        bcc .clamp_down
        cmp #215
        bcs .clamp_down
        ldy #189
        lda room_buf,y
        cmp #TILE_DUNG_DOOR_OPEN
        bne .clamp_down
+       jsr transition_down
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
        ; 1. Test si Link marche sur une entrée de grotte (TILE_CAVE)
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
        jsr check_room_entrance
        rts
+
        ; 2. Mécaniques spéciales Overworld (Fontaine de Fée, Cœur du ponton, etc.)
        lda current_world_type
        beq .chk_ow_special
        rts

.chk_ow_special:
        jsr check_ow_specials_ext
        ; --- Fontaine des Fées (Bassin) en salle 57 (J-4) et salle 67 (D-5) ---
        lda current_room_idx
        cmp #57
        beq .in_fairy_pond
        cmp #67
        bne .chk_dock_heart

.in_fairy_pond:
        lda player_y
        cmp #100
        bcc .chk_dock_heart
        cmp #160
        bcs .chk_dock_heart
        lda player_x
        cmp #120
        bcc .chk_dock_heart
        cmp #184
        bcs .chk_dock_heart
        ; Link est dans le bassin de la Fée : soin complet de sa vie !
        lda hud_cur_hearts
        cmp hud_max_hearts
        bcs .chk_dock_heart
        lda hud_max_hearts
        sta hud_cur_hearts
        jsr hud_render
        jsr sound_item_fanfare
        jsr sound_secret
        rts

.chk_dock_heart:
        ; --- Conteneur de Cœur sur le ponton marin en salle 95 (P-6) ---
        lda current_room_idx
        cmp #95
        bne .chk_grave_push
        lda player_has_stepladder
        beq .chk_grave_push
        lda player_x+1
        bne .dock_heart_x_ok
        lda player_x
        cmp #200
        bcc .chk_grave_push
.dock_heart_x_ok:
        lda player_y
        cmp #120
        bcc .chk_grave_push
        cmp #180
        bcs .chk_grave_push
        ; Vérifie si le cœur de la salle 95 a déjà été pris
        ldx #95
        lda cave_room_cleared,x
        and #1
        bne .chk_grave_push
        lda #1
        ora cave_room_cleared,x
        sta cave_room_cleared,x
        inc hud_max_hearts
        lda hud_max_hearts
        sta hud_cur_hearts
        jsr hud_render
        jsr sound_item_fanfare
        rts

.chk_grave_push:
        ; --- Pousser la tombe en salle 33 (B-3) vers l'Épée Magique ---
        lda current_room_idx
        cmp #33
        bne .chk_rock_push
        lda player_dir
        cmp #DIR_UP
        bne .chk_rock_push
        lda player_x
        cmp #200
        bcc .chk_rock_push
        cmp #232
        bcs .chk_rock_push
        lda player_y
        cmp #148
        bcc .chk_rock_push
        cmp #172
        bcs .chk_rock_push
        ; Si la tombe n'a pas encore été révélée
        lda room_buf+92
        cmp #TILE_CAVE
        beq .chk_rock_push
        lda #TILE_CAVE
        sta room_buf+92
        ldy #92
        jsr redraw_single_tile
        jsr sound_secret
        jsr record_room_secret_opened
        rts

.chk_rock_push:
        ; --- Pousser le rocher escargot en salle 51 (D-4) avec le Bracelet de Force ---
        lda current_room_idx
        cmp #51
        bne .ow_special_done
        lda player_has_bracelet
        beq .ow_special_done
        lda player_dir
        cmp #DIR_UP
        bne .ow_special_done
        lda player_x+1
        bne .ow_special_done
        lda player_x
        cmp #120
        bcc .ow_special_done
        cmp #144
        bcs .ow_special_done
        lda player_y
        cmp #148
        bcc .ow_special_done
        cmp #168
        bcs .ow_special_done
        lda room_buf+88
        cmp #TILE_CAVE
        beq .ow_special_done
        lda #TILE_CAVE
        sta room_buf+88
        ldy #88
        jsr redraw_single_tile
        jsr sound_secret
        jsr record_room_secret_opened
.ow_special_done:
        rts

; ---------------------------------------------------------------------------
; check_room_entrance : Gère l'entrée dans les donjons ou les grottes
; Découplage strict entre donjons (1..9) et grottes overworld (boutiques, etc.)
; ---------------------------------------------------------------------------
check_room_entrance:
        ; Uniquement actif en mode Overworld et en état de jeu normal
        lda current_world_type
        cmp #WORLD_OVERWORLD
        bne .chk_ent_done
        lda game_state
        cmp #STATE_PLAYING
        bne .chk_ent_done

        ; 1. Priorité absolue : entrée d'un des 9 Donjons (Niveaux 1 à 9)
        ldx current_room_idx
        lda dungeon_room_levels,x
        beq .chk_cave
        sta current_dungeon_level
        jsr enter_dungeon
        rts

.chk_cave:
        ; 2. Entrée dans une des grottes authentiques (boutiques, sage, etc.)
        ldx current_room_idx
        lda room_cave_types,x
        beq .chk_ent_done
        sta current_cave_type
        jsr cave_enter
.chk_ent_done:
        rts

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
        ; Mur traversable Overworld : P-2 (Salle 31) en haut, P-1 (Salle 15) en bas
        ldx current_world_type
        bne +
        lda col_x+1
        bne +
        lda col_x
        cmp #170
        bcc +
        cmp #211
        bcs +
        lda current_room_idx
        cmp #31                         ; P-2
        bne .chk_pt_r15
        lda col_y
        cmp #114                        ; Traversée du mur nord
        bcc .free_pt
        bcs +
.chk_pt_r15:
        cmp #15                         ; P-1
        bne +
        lda col_y
        cmp #210                        ; Traversée du mur sud
        bcs .free_pt
+
        jsr get_tile_at_point
        cmp #$ff
        bne +
        sec                             ; Toujours SOLIDE si hors écran !
        rts
+       ldx current_world_type
        bne .dung_collision
        cmp #TILE_WATER
        bne .not_water
        lda player_has_stepladder
        beq .water_solid
        ; Link possède l'échelle : Y contient l'offset de la tuile d'eau
        lda ladder_tile_idx
        cmp #$ff
        beq .deploy_ladder
        cpy ladder_tile_idx
        beq .ladder_free
        bne .water_solid
.deploy_ladder:
        sty ladder_tile_idx
        lda player_dir
        cmp #DIR_LEFT
        beq .hl
        cmp #DIR_RIGHT
        beq .hl
        lda #TILE_BRIDGE_V
        bne +
.hl:    lda #TILE_BRIDGE_H
+       sta room_buf,y
        tya
        pha
        jsr redraw_single_tile
        pla
        tay
.ladder_free:
        clc
        rts
.water_solid:
        sec
        rts

.dung_collision:
        cmp #TILE_WATER
        bne .not_water
        lda player_has_stepladder
        bne .free
        sec
        rts

.not_water:
        tax
        lda tile_flags,x
        and #TILE_SOLID
        beq .free
        sec                             ; Solide !
        rts

.free_pt:
.free:
        clc                             ; Libre !
        rts

; Bruitage d'attaque à l'épée via le synthétiseur SID (bruit blanc + déclin percussif)
; sound_sword delegue a src/sound.asm

; ---------------------------------------------------------------------------
; player_use_item_b : déclenché par le Bouton B (arme secondaire équipée)
; ---------------------------------------------------------------------------
player_use_item_b:
        jsr items_use_b
        rts

; Recopie la position et les pointeurs dans les registres VIC-II.
player_draw:
        ; Couleur de Link (Verte ou Blanche si Anneau Bleu)
        lda #COL_GREEN
        ldx player_has_blue_ring
        beq +
        lda #COL_WHITE
+       sta VIC_SPRITE_COL0
        lda #PLAYER_SKIN
        sta VIC_SPRITE_MC1
        lda #PLAYER_BROWN
        sta VIC_SPRITE_MC2
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

        ; Pointeur Sprite 0 : pose celebration Triforce ou marche normale
        lda triforce_fanfare_timer
        beq +
        lda #(sprite_link_item_get >> 6)
        sta SPRITE_PTR0
        rts
+       lda player_dir
        asl
        ora player_walk_anim
        clc
        adc #(sprite_link_down_0 >> 6)
        sta SPRITE_PTR0
        rts
