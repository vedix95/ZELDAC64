; ===========================================================================
; cave.asm : Grotte de l'Épée - "C'est dangereux d'y aller tout seul !"
; Inspiré fidèlement de la première grotte de The Legend of Zelda (NES 1986).
;
; Comprend :
;   - Décor de chambre souterraine (murs rocheux, sol sombre, seuil d'entrée)
;   - Texte officiel en français :
;       "C'EST DANGEREUX D'Y ALLER"
;       "TOUT SEUL ! PRENDS CECI."
;   - Le Vieil Homme (Old Man) en robe rouge avec barbe blanche
;   - Deux braseros / torches aux flammes vacillantes
;   - L'Épée de bois posée au sol
;   - Récupération de l'épée avec jingle triomphal SID et pose "Item Get"
;   - Transition de retour vers l'overworld par le seuil du bas
; ===========================================================================

!zone cave_module

; ---------------------------------------------------------------------------
; Variables de la grotte
; ---------------------------------------------------------------------------
saved_overworld_x:  !word 0
saved_overworld_y:  !byte 0
cave_torch_tick:    !byte 0
cave_pickup_timer:  !byte 0
cave_jingle_tick:   !byte 0
cave_jingle_idx:    !byte 0

; Lignes de texte en français (caractères ASCII majuscules 8x8)
txt_cave_line1:
        !text "C'EST DANGEREUX D'Y ALLER"       ; 25 caractères
txt_cave_line2:
        !text "TOUT SEUL ! PRENDS CECI."        ; 24 caractères

; Fanfare triomphale SID pour l'obtention de l'Épée (8 notes arpégées)
cave_fanfare_lo:
        !byte $26, $9E, $B8, $4C, $3C, $70, $98, $78
cave_fanfare_hi:
        !byte $11, $15, $19, $22, $2B, $33, $44, $56

; ---------------------------------------------------------------------------
; cave_enter : appelé lorsque Link marche sur l'entrée de grotte dans l'overworld
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

        ; 4. Positionne Link au seuil du bas de la grotte, tourné vers le haut
        lda #180
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

        ; 5. Dessine l'écran complet de la grotte
        jsr cave_draw_screen
        rts

; ---------------------------------------------------------------------------
; cave_draw_screen : dessine le décor, les murs rocheux et le texte de la grotte
; ---------------------------------------------------------------------------
cave_draw_screen:
        ; Couleurs VIC-II intérieures : fond noir, murs marron
        lda #COL_BLACK
        sta VIC_BACKGROUND
        sta VIC_BORDER
        lda #COL_BROWN
        sta VIC_BG_MC1
        lda #COL_GREY
        sta VIC_BG_MC2

        ; 1. Efface les lignes 4 à 23 (zone de jeu sous le HUD) en noir
        ldx #0
.cls_cave:
        lda #0                          ; caractère 0 (fond noir uni)
        sta SCREEN_RAM+160,x
        sta SCREEN_RAM+416,x
        sta SCREEN_RAM+672,x
        lda #COL_BLACK
        sta COLOR_RAM+160,x
        sta COLOR_RAM+416,x
        sta COLOR_RAM+672,x
        inx
        bne .cls_cave

        ; 2. Dessine le mur rocheux supérieur (ligne 4) : 20 tuiles TILE_WALL
        ; Tuile TILE_WALL = 5 : chars HG=20, HD=21, BG=22, BD=23
        ldx #0
.draw_top_wall:
        lda #20                         ; HG
        sta SCREEN_RAM+160,x
        lda #21                         ; HD
        sta SCREEN_RAM+161,x
        lda #8                          ; couleur tuile mur (multicolore)
        sta COLOR_RAM+160,x
        sta COLOR_RAM+161,x
        inx
        inx
        cpx #40
        bne .draw_top_wall

        ; 3. Dessine les murs rocheux latéraux (lignes 5 à 22)
        ldx #5
.draw_side_walls:
        lda scr_row_lo,x
        sta ZP_SCR
        sta ZP_COL
        lda scr_row_hi,x
        sta ZP_SCR+1
        lda col_row_hi,x
        sta ZP_COL+1

        ; Colonnes de gauche 0..1
        ldy #0
        lda #22
        sta (ZP_SCR),y
        lda #8
        sta (ZP_COL),y
        iny
        lda #23
        sta (ZP_SCR),y
        lda #8
        sta (ZP_COL),y

        ; Colonnes de droite 38..39
        ldy #38
        lda #22
        sta (ZP_SCR),y
        lda #8
        sta (ZP_COL),y
        iny
        lda #23
        sta (ZP_SCR),y
        lda #8
        sta (ZP_COL),y

        inx
        cpx #23
        bne .draw_side_walls

        ; 4. Dessine le mur rocheux inférieur (ligne 23) avec l'ouverture centrale
        ldx #0
.draw_bottom_wall:
        cpx #18
        bcc .bw_wall
        cpx #22
        bcc .bw_door                    ; cols 18..21 = passage de sortie noir
.bw_wall:
        lda #22
        sta SCREEN_RAM+23*40,x
        lda #8
        sta COLOR_RAM+23*40,x
        jmp .bw_next
.bw_door:
        lda #0                          ; ouverture noire
        sta SCREEN_RAM+23*40,x
        lda #COL_BLACK
        sta COLOR_RAM+23*40,x
.bw_next:
        inx
        cpx #40
        bne .draw_bottom_wall

        ; 5. Affiche le texte officiel sur les lignes 6 et 8
        ; Ligne 6 : "C'EST DANGEREUX D'Y ALLER" (cols 7..31)
        ldx #0
.put_line1:
        lda txt_cave_line1,x
        sta SCREEN_RAM+6*40+7,x
        lda #COL_WHITE
        sta COLOR_RAM+6*40+7,x
        inx
        cpx #25
        bne .put_line1

        ; Ligne 8 : "TOUT SEUL ! PRENDS CECI." (cols 8..31)
        ldx #0
.put_line2:
        lda txt_cave_line2,x
        sta SCREEN_RAM+8*40+8,x
        lda #COL_WHITE
        sta COLOR_RAM+8*40+8,x
        inx
        cpx #24
        bne .put_line2

        rts

; ---------------------------------------------------------------------------
; cave_update : mise à jour de la logique de la grotte
; ---------------------------------------------------------------------------
cave_update:
        inc cave_torch_tick

        ; Si Link est en train de brandir l'épée obtenue
        lda cave_pickup_timer
        beq .normal_cave_controls
        dec cave_pickup_timer
        jsr cave_play_jingle
        rts                             ; Link reste immobile pendant la célébration

.normal_cave_controls:
        ; -------------------------------------------------------------------
        ; Déplacement de Link dans la grotte
        ; -------------------------------------------------------------------
        ldx #0                          ; X = indicateur de marche (0 = immobile)

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
        cmp #60                         ; limite mur gauche
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
        cmp #44                         ; 256 + 44 = 300 (limite mur droit)
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
        cmp #162                        ; limite supérieure (près de l'épée/vieux)
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

        ; Vérifie si Link est dans le seuil de sortie (X ~ 168..192)
        lda player_x+1
        bne .bottom_wall_check
        lda player_x
        cmp #166
        bcc .bottom_wall_check
        cmp #196
        bcs .bottom_wall_check

        ; Dans le seuil : Link peut descendre pour sortir
        lda player_y
        cmp #214
        bcc ++
        ; SORTIE DE LA GROTTE !
        jsr cave_exit
        rts

.bottom_wall_check:
        lda player_y
        cmp #204                        ; bloqué par le mur du bas hors du seuil
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
        ; Test de ramassage de l'épée (si pas encore obtenue)
        ; -------------------------------------------------------------------
        lda player_has_sword
        bne .cave_done                  ; épée déjà prise

        ; Link doit s'approcher de l'épée (X=180, Y=158)
        lda player_x+1
        bne .cave_done
        lda player_x
        cmp #172
        bcc .cave_done
        cmp #188
        bcs .cave_done
        lda player_y
        cmp #166
        bcs .cave_done

        ; OBTENTION DE L'ÉPÉE !
        lda #1
        sta player_has_sword
        lda #100                        ; ~1.6 seconde de célébration
        sta cave_pickup_timer
        lda #0
        sta cave_jingle_tick
        sta cave_jingle_idx

        ; Met à jour l'icône de l'épée dans le HUD
        jsr hud_update_sword

        ; Démarre la première note de la fanfare
        jsr cave_play_note

.cave_done:
        rts

; ---------------------------------------------------------------------------
; cave_play_jingle : joue l'arpège triomphal note par note sur la voix 1
; ---------------------------------------------------------------------------
cave_play_jingle:
        inc cave_jingle_tick
        lda cave_jingle_tick
        cmp #8                          ; changement de note toutes les 8 frames
        bcc .jingle_hold
        lda #0
        sta cave_jingle_tick
        lda cave_jingle_idx
        cmp #7
        bcs .jingle_hold                ; reste sur la note la plus haute
        inc cave_jingle_idx
        jsr cave_play_note
.jingle_hold:
        lda cave_pickup_timer
        cmp #1
        bne +
        ; Coupe la note à la fin
        lda #%00010000                  ; Gate OFF
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
        lda #$13                        ; Attack rapide, Decay court
        sta SID_V1_AD
        lda #$c4                        ; Sustain fort
        sta SID_V1_SR
        lda #%00010001                  ; Onde triangle + Gate ON
        sta SID_V1_CTRL
        rts

; ---------------------------------------------------------------------------
; cave_draw : configure et positionne tous les sprites de la grotte
; ---------------------------------------------------------------------------
cave_draw:
        ; Multicolore commun
        lda #PLAYER_SKIN
        sta VIC_SPRITE_MC1
        lda #PLAYER_BROWN
        sta VIC_SPRITE_MC2
        lda #%00111111                  ; Sprites 0..5 en multicolore
        sta VIC_SPRITE_MC
        lda #0
        sta VIC_SPRITE_EXP_X
        sta VIC_SPRITE_EXP_Y

        ; Bit 8 (MSB) de X pour Link
        lda player_x+1
        and #1
        sta VIC_SPRITE_MSB

        ; 1. Sprite 0 : Link
        lda player_x
        sta VIC_SPRITE_X0
        lda player_y
        sta VIC_SPRITE_Y0
        lda #COL_GREEN
        sta VIC_SPRITE_COL0

        lda cave_pickup_timer
        beq .normal_link_spr

        ; Pose "Item Get" : Link brandit l'épée au-dessus de sa tête
        lda #(sprite_link_item_get >> 6)
        sta SPRITE_PTR0

        ; Sprite 1 : Épée tenue au-dessus de la tête
        lda #(sprite_link_sword_up >> 6)
        sta SPRITE_PTR1
        lda player_x
        sta VIC_SPRITE_X1
        lda player_y
        sec
        sbc #14
        sta VIC_SPRITE_Y1
        lda #COL_WHITE
        sta VIC_SPRITE_COL1
        jmp .setup_actors

.normal_link_spr:
        ; Sprite Link normal selon direction et pas
        lda player_dir
        asl
        ora player_walk_anim
        clc
        adc #(sprite_link_down_0 >> 6)
        sta SPRITE_PTR0

.setup_actors:
        ; 2. Sprite 2 : L'Épée au sol (si pas encore prise)
        lda #(sprite_link_sword_up >> 6)
        sta SPRITE_PTR2
        lda #180
        sta VIC_SPRITE_X2
        lda #158
        sta VIC_SPRITE_Y2
        lda #COL_WHITE
        sta VIC_SPRITE_COL2

        ; 3. Sprite 3 : Le Vieil Homme (Old Man)
        lda #(sprite_link_old_man >> 6)
        sta SPRITE_PTR3
        lda #180
        sta VIC_SPRITE_X3
        lda #130
        sta VIC_SPRITE_Y3
        lda #COL_RED
        sta VIC_SPRITE_COL3

        ; 4. Sprite 4 : Torche gauche
        lda #132
        sta VIC_SPRITE_X4
        lda #130
        sta VIC_SPRITE_Y4
        lda #COL_LIGHT_RED
        sta VIC_SPRITE_COL4

        ; 5. Sprite 5 : Torche droite
        lda #228
        sta VIC_SPRITE_X5
        lda #130
        sta VIC_SPRITE_Y5
        lda #COL_LIGHT_RED
        sta VIC_SPRITE_COL5

        ; Animation des deux flammes alternées
        lda cave_torch_tick
        and #8
        beq +
        lda #(sprite_link_proj_flame_0 >> 6)
        sta SPRITE_PTR4
        lda #(sprite_link_proj_flame_1 >> 6)
        sta SPRITE_PTR5
        jmp ++
+       lda #(sprite_link_proj_flame_1 >> 6)
        sta SPRITE_PTR4
        lda #(sprite_link_proj_flame_0 >> 6)
        sta SPRITE_PTR5
++

        ; 6. Activation des sprites (VIC_SPRITE_EN)
        lda cave_pickup_timer
        beq +
        ; Célébration : Link (0), Épée levée (1), Vieux (3), Torches (4, 5)
        lda #%00111011
        sta VIC_SPRITE_EN
        rts
+
        lda player_has_sword
        bne +
        ; Épée encore au sol : Link (0), Épée sol (2), Vieux (3), Torches (4, 5)
        lda #%00111101
        sta VIC_SPRITE_EN
        rts
+
        ; Épée déjà prise : Link (0), Vieux (3), Torches (4, 5)
        lda #%00111001
        sta VIC_SPRITE_EN
        rts

; ---------------------------------------------------------------------------
; cave_exit : replace Link à l'extérieur devant la grotte et restaure l'overworld
; ---------------------------------------------------------------------------
cave_exit:
        ; 1. Restaure l'état de jeu normal
        lda #STATE_PLAYING
        sta game_state

        ; 2. Replace Link juste devant l'entrée de la grotte (vers le bas)
        lda saved_overworld_x
        sta player_x
        lda saved_overworld_x+1
        sta player_x+1
        lda saved_overworld_y
        clc
        adc #16                         ; 16 px plus bas pour ne pas ré-entrer aussitôt
        sta player_y
        lda #DIR_DOWN
        sta player_dir
        lda #0
        sta player_walk_anim
        sta player_walk_tick

        ; 3. Restaure les couleurs de l'overworld
        lda #MAP_BG_COLOR
        sta VIC_BACKGROUND
        lda #COL_BLACK
        sta VIC_BORDER
        lda #MAP_MC1_COLOR
        sta VIC_BG_MC1
        lda #MAP_MC2_COLOR
        sta VIC_BG_MC2

        ; 4. Recharge la carte de la salle extérieure
        jsr load_room

        ; 5. Rafraîchit le HUD (notamment l'épée)
        jsr hud_init

        ; 6. Réactive les ennemis extérieurs
        jsr enemies_room_init

        rts
