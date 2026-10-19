; ===========================================================================
; dungeon.asm : Mécanismes complets des Donjons de Zelda 1
;
; Gère :
;   - Portes verrouillées (consommation de clef ou clef magique)
;   - Portes à volet (shutter doors) : fermeture à l'entrée et ouverture auto
;     lorsque tous les monstres de la salle sont éliminés
;   - Blocs poussables (pushable blocks) : pousser un bloc vers le haut/droite
;     ouvre les volets ou révèle l'escalier secret
;   - Murs fissurables à la bombe dans les donjons (détection d'explosion)
;   - Butin de salle (apparition au centre : Clef, Boussole, Carte, Cœur, etc.)
;   - Salle du boss & Conteneur de Cœur lâché à la mort du boss
;   - Salle de la Triforce & Célébration (Link brandit le fragment doré,
;     fanfare victorieuse, soin complet et retour à l'extérieur)
;   - Franchissement d'eau automatique grâce à l'Échelle (Stepladder)
; ===========================================================================

!zone dungeon_module

dungeon_shutter_closed: !byte 0
dungeon_block_pushed:   !byte 0
dungeon_push_timer:     !byte 0
dungeon_drop_active:    !byte 0
dungeon_drop_type:      !byte 0         ; 1=Key, 2=Heart Container, 3=Compass, 4=Map, 5=Triforce
dungeon_drop_x:         !word 180
dungeon_drop_y:         !byte 148
dungeon_drop_cooldown:  !byte 0
triforce_fanfare_timer: !byte 0
cellar_pickup_timer:    !byte 0
dungeon_torch_tick:     !byte 0
target_room_idx:        !byte 0
dungeon_active_level:   !byte $ff
dungeon_room_state      = $033c

DROP_NONE               = 0
DROP_KEY                = 1
DROP_HEART_CONTAINER    = 2
DROP_COMPASS            = 3
DROP_MAP                = 4
DROP_TRIFORCE           = 5
DROP_BOOMERANG          = 6
DROP_BOW                = 7

DUNG_DOOR_N_OPEN        = %00000001     ; Porte Nord déverrouillée / ouverte
DUNG_DOOR_S_OPEN        = %00000010     ; Porte Sud déverrouillée / ouverte
DUNG_DOOR_W_OPEN        = %00000100     ; Porte Ouest déverrouillée / ouverte
DUNG_DOOR_E_OPEN        = %00001000     ; Porte Est déverrouillée / ouverte
DUNG_ROOM_CLEARED       = %00010000     ; Monstres éliminés (volets ouverts)
DUNG_ITEM_COLLECTED     = %00100000     ; Objet de salle ramassé
DUNG_SECRET_REVEALED    = %01000000     ; Escalier de l'arc révélé (bloc poussé)

; Tables des salles officielles de boss et triforce (Niveaux 1 à 9)
dungeon_boss_rooms:
        !byte $35, $0e, $4d, $13, $24, $1c, $2a, $3c, $42
dungeon_triforce_rooms:
        !byte $36, $0d, $3d, $03, $14, $0c, $2b, $2c, $32

; ---------------------------------------------------------------------------
; dungeon_init : réinitialisation globale
; ---------------------------------------------------------------------------
dungeon_init:
        lda #0
        sta dungeon_shutter_closed
        sta dungeon_block_pushed
        sta dungeon_push_timer
        sta dungeon_drop_active
        sta dungeon_drop_type
        sta dungeon_drop_cooldown
        sta triforce_fanfare_timer
        lda current_dungeon_level
        sta dungeon_active_level
        lda #0
        ldx #127
-       sta dungeon_room_state,x
        dex
        bpl -
        rts

; ---------------------------------------------------------------------------
; dungeon_on_enter_room : appelé à chaque entrée dans une salle de donjon
; ---------------------------------------------------------------------------
dungeon_on_enter_room:
        lda current_world_type
        cmp #WORLD_DUNGEON
        beq +
        rts
+
        lda #0
        sta dungeon_block_pushed
        sta dungeon_push_timer
        sta dungeon_drop_active
        sta dungeon_drop_type
        sta dungeon_drop_cooldown

        ldx current_room_idx

        ; 0. Salle Ermite Donjon 1 (0x41)
        cpx #$41
        bne +
        jsr dungeon_setup_room_41
        rts
+
        ; 1. Salle Triforce (0x36)
        cpx #$36
        bne .check_floor_key
        lda dungeon_room_state,x
        and #DUNG_ITEM_COLLECTED
        bne .done_enter
        lda #DROP_TRIFORCE
        sta dungeon_drop_type
        lda #1
        sta dungeon_drop_active
        lda #180
        sta dungeon_drop_x
        lda #0
        sta dungeon_drop_x+1
        lda #148
        sta dungeon_drop_y
        rts

.check_floor_key:
        ; 2. Salle 0x72 (Clé au sol à gauche de l'entrée)
        cpx #$72
        bne .check_cleared_drop
        lda dungeon_room_state,x
        and #DUNG_ITEM_COLLECTED
        bne .check_shutters_enter
        lda #DROP_KEY
        sta dungeon_drop_type
        lda #1
        sta dungeon_drop_active
        lda #230
        sta dungeon_drop_x
        lda #0
        sta dungeon_drop_x+1
        lda #180
        sta dungeon_drop_y
        jmp .check_shutters_enter

.check_cleared_drop:
        ; Si la salle a déjà été nettoyée de ses monstres mais que l'objet n'a pas encore été ramassé :
        lda dungeon_room_state,x
        and #DUNG_ROOM_CLEARED
        beq .check_shutters_enter
        lda dungeon_room_state,x
        and #DUNG_ITEM_COLLECTED
        bne .check_shutters_enter
        jsr dungeon_spawn_room_drop

.check_shutters_enter:
        ; 3. Vérification des volets pour la salle active
        jsr dungeon_room_has_shutters
        bcc .no_shutters_here

        ; La salle a des volets : est-elle déjà cleared ?
        ldx current_room_idx
        lda dungeon_room_state,x
        and #DUNG_ROOM_CLEARED
        bne .no_shutters_here

        ; Pas encore cleared : si des monstres vivants, les volets sont fermés !
        jsr dungeon_count_alive_enemies
        cpy #0
        beq .no_shutters_here
        lda #1
        sta dungeon_shutter_closed
        rts

.no_shutters_here:
        lda #0
        sta dungeon_shutter_closed
.done_enter:
        rts

; ---------------------------------------------------------------------------
; dungeon_count_alive_enemies : compte les ennemis vivants (hors traps et bubbles)
; Sortie : Y = nombre d'ennemis vivants
; ---------------------------------------------------------------------------
dungeon_count_alive_enemies:
        ldx #0
        ldy #0
-       lda en_state,x
        cmp #EN_STATE_DEAD
        beq +
        lda en_type,x
        cmp #TYPE_TRAP
        beq +
        cmp #TYPE_BUBBLE
        beq +
        iny
+       inx
        cpx #MAX_ENEMIES
        bcc -
        rts

; ---------------------------------------------------------------------------
; dungeon_room_has_shutters : indique si la salle possède des volets
; Sortie : Carry = 1 si volets, Carry = 0 sinon
; ---------------------------------------------------------------------------
dungeon_room_has_shutters:
        lda current_dungeon_level
        cmp #1
        bne .chk_generic_boss
        lda current_room_idx
        cmp #$53                        ; Salle 0x53 : Volet Nord
        beq .has_shutt
        cmp #$52                        ; Salle 0x52 : Volet Est
        beq .has_shutt
        cmp #$42                        ; Salle 0x42 : Volet Ouest
        beq .has_shutt
        cmp #$44                        ; Salle 0x44 : Goriyas (Boomerang)
        beq .has_shutt
        cmp #$23                        ; Salle 0x23 : Goriyas
        beq .has_shutt
        cmp #$35                        ; Salle 0x35 : Boss Aquamentus
        beq .has_shutt
        clc
        rts
.chk_generic_boss:
        ldx current_dungeon_level
        dex
        cpx #9
        bcs .no_shutt
        lda dungeon_boss_rooms,x
        cmp current_room_idx
        beq .has_shutt
.no_shutt:
        clc
        rts
.has_shutt:
        sec
        rts

; ---------------------------------------------------------------------------
; dungeon_get_room_drop_type : renvoie le type d'objet attribué à la salle
; Sortie : A = DROP_*
; ---------------------------------------------------------------------------
dungeon_get_room_drop_type:
        lda current_dungeon_level
        cmp #1
        bne .check_boss_drop_generic
        lda current_room_idx
        cmp #$74
        beq .ret_key
        cmp #$63
        beq .ret_key
        cmp #$53
        beq .ret_key
        cmp #$33
        beq .ret_key
        cmp #$23
        beq .ret_key
        cmp #$54
        beq .ret_compass
        cmp #$45
        beq .ret_map
        cmp #$44
        beq .ret_boomerang
        cmp #$35
        beq .ret_heart
        lda #DROP_NONE
        rts

.check_boss_drop_generic:
        ldx current_dungeon_level
        dex
        cpx #9
        bcs .ret_none
        lda dungeon_boss_rooms,x
        cmp current_room_idx
        beq .ret_heart
.ret_none:
        lda #DROP_NONE
        rts
.ret_key:
        lda #DROP_KEY
        rts
.ret_compass:
        lda #DROP_COMPASS
        rts
.ret_map:
        lda #DROP_MAP
        rts
.ret_boomerang:
        lda #DROP_BOOMERANG
        rts
.ret_heart:
        lda #DROP_HEART_CONTAINER
        rts

; ---------------------------------------------------------------------------
; dungeon_on_room_cleared_doors : ouvre les portes connexes des volets spéciaux
; ---------------------------------------------------------------------------
dungeon_on_room_cleared_doors:
        lda current_dungeon_level
        cmp #1
        beq .lvl1_cleared_doors
        rts

.lvl1_cleared_doors:
        lda current_room_idx
        cmp #$53
        bne +
        ldx #$53
        lda dungeon_room_state,x
        ora #DUNG_DOOR_N_OPEN
        sta dungeon_room_state,x
        ldx #$43
        lda dungeon_room_state,x
        ora #DUNG_DOOR_S_OPEN
        sta dungeon_room_state,x
        rts

+       cmp #$35
        bne +
        ldx #$35
        lda dungeon_room_state,x
        ora #DUNG_DOOR_E_OPEN
        sta dungeon_room_state,x
        ldx #$36
        lda dungeon_room_state,x
        ora #DUNG_DOOR_W_OPEN
        sta dungeon_room_state,x
        rts

+       cmp #$52
        bne +
        ldx #$52
        lda dungeon_room_state,x
        ora #DUNG_DOOR_E_OPEN
        sta dungeon_room_state,x
        ldx #$53
        lda dungeon_room_state,x
        ora #DUNG_DOOR_W_OPEN
        sta dungeon_room_state,x
        rts

+       cmp #$42
        bne +
        ldx #$42
        lda dungeon_room_state,x
        ora #DUNG_DOOR_W_OPEN
        sta dungeon_room_state,x
        ldx #$41
        lda dungeon_room_state,x
        ora #DUNG_DOOR_E_OPEN
        sta dungeon_room_state,x
        rts

+       cmp #$44
        bne +
        ldx #$44
        lda dungeon_room_state,x
        ora #DUNG_DOOR_W_OPEN
        sta dungeon_room_state,x
        ldx #$43
        lda dungeon_room_state,x
        ora #DUNG_DOOR_E_OPEN
        sta dungeon_room_state,x
        rts

+       cmp #$23
        bne .done_doors_cleared
        ldx #$23
        lda dungeon_room_state,x
        ora #DUNG_DOOR_W_OPEN
        sta dungeon_room_state,x
        ldx #$22
        lda dungeon_room_state,x
        ora #DUNG_DOOR_E_OPEN
        sta dungeon_room_state,x
.done_doors_cleared:
        rts

; ---------------------------------------------------------------------------
; dungeon_update : exécuté à chaque frame
; ---------------------------------------------------------------------------
dungeon_update:
        lda current_world_type
        cmp #WORLD_DUNGEON
        beq +
        rts
+
        ; Animation torches salle Ermite (0x41)
        ldx current_room_idx
        cpx #$41
        bne +
        inc dungeon_torch_tick
        lda dungeon_torch_tick
        and #8
        beq .flame_a
        lda #(sprite_link_proj_flame_0 / 64)
        sta SPRITE_PTR4
        lda #(sprite_link_proj_flame_1 / 64)
        sta SPRITE_PTR5
        jmp .check_locked_door
.flame_a:
        lda #(sprite_link_proj_flame_1 / 64)
        sta SPRITE_PTR4
        lda #(sprite_link_proj_flame_0 / 64)
        sta SPRITE_PTR5
        jmp .check_locked_door
+
        ; 1. Gestion de la fanfare de la Triforce en cours
        lda triforce_fanfare_timer
        beq .check_room_objectives
        inc triforce_fanfare_timer
        bne +
        inc triforce_fanfare_timer
+       lda current_music
        cmp #MUSIC_TRIFORCE
        beq .hold_triforce
        ; Fin de la célébration : retour à l'extérieur dans l'overworld !
        lda #0
        sta triforce_fanfare_timer
        jsr exit_dungeon
        rts

.hold_triforce:
        ; Link brandit l'objet vers le haut
        lda #< (sprite_link_item_get / 64)
        sta SPRITE_PTR0
        rts

.check_room_objectives:
        ; 2. Vérification des objectifs de salle et volets fermés
        ldx current_room_idx
        lda dungeon_room_state,x
        and #DUNG_ROOM_CLEARED
        bne .check_push_block           ; Déjà cleared !

        jsr dungeon_count_alive_enemies
        cpy #0
        bne .check_push_block           ; Monstres vivants !

        ; Tous les monstres de la pièce sont vaincus !
        ldx current_room_idx
        lda dungeon_room_state,x
        ora #DUNG_ROOM_CLEARED
        sta dungeon_room_state,x

        lda dungeon_shutter_closed
        beq +
        lda #0
        sta dungeon_shutter_closed
        jsr dungeon_open_shutters
        jsr sound_secret_chime
+
        jsr dungeon_on_room_cleared_doors
        jsr dungeon_spawn_room_drop

.check_push_block:
        ; 3. Bloc poussable : Link pousse contre un bloc (colonne/rangée centrale)
        lda dungeon_block_pushed
        bne .check_drop_pickup

        lda joy
        and #%00001111
        beq .reset_push_timer

        ; Vérifie si Link est devant un bloc solide
        jsr check_link_pushing_block
        bcc .reset_push_timer
        inc dungeon_push_timer
        lda dungeon_push_timer
        cmp #18                         ; ~0.35s de poussée continue
        bcc .check_drop_pickup

        ; Bloc poussé !
        lda #1
        sta dungeon_block_pushed
        jsr dungeon_do_push_block
        jsr sound_secret_chime
        jmp .check_drop_pickup

.reset_push_timer:
        lda #0
        sta dungeon_push_timer

.check_drop_pickup:
        ; 4. Collision de Link avec l'objet au sol (Clef, Cœur, Triforce)
        lda dungeon_drop_active
        beq .check_locked_door
        lda dungeon_drop_cooldown
        beq +
        dec dungeon_drop_cooldown
        jmp .check_locked_door
+
        ; Distance X
        sec
        lda player_x
        sbc dungeon_drop_x
        bcs +
        eor #$ff
        adc #1
+       cmp #14
        bcs .check_locked_door

        ; Distance Y
        sec
        lda player_y
        sbc dungeon_drop_y
        bcs +
        eor #$ff
        adc #1
+       cmp #14
        bcs .check_locked_door

        ; --- OBJET RAMASSÉ ! ---
        jsr dungeon_collect_drop

.check_locked_door:
        ; 5. Porte verrouillée : ouverture automatique si Link touche une porte avec une clé
        jsr dungeon_check_key_door

        ; 6. Escalier secret vers le passage sous-terrain (Salle 0x22)
        lda current_room_idx
        cmp #$22
        bne +
        lda player_x
        clc
        adc #8
        sta col_x
        lda player_x+1
        adc #0
        sta col_x+1
        lda player_y
        clc
        adc #12
        sta col_y
        jsr get_tile_at_point
        cmp #TILE_DUNG_STAIRS
        bne +
        jsr enter_cellar
+       rts

; ---------------------------------------------------------------------------
; check_link_pushing_block : vérifie si Link pousse contre un bloc poussable
; ---------------------------------------------------------------------------
check_link_pushing_block:
        lda current_room_idx
        cmp #$42                        ; Salle 0x42 (passage vers ermite 0x41)
        bne .chk_push_22
        ldx #$42
        lda dungeon_room_state,x
        and #DUNG_ROOM_CLEARED
        beq .no_block_42
        lda player_dir
        cmp #DIR_UP
        beq .chk_42_up
        cmp #DIR_LEFT
        beq .chk_42_left
.no_block_42:
        clc
        rts
.chk_42_up:
        lda player_y
        cmp #155
        bcc .no_block_42
        cmp #174
        bcs .no_block_42
        lda player_x
        cmp #158
        bcc .no_block_42
        cmp #190
        bcs .no_block_42
        sec
        rts
.chk_42_left:
        lda player_x
        cmp #178
        bcc .no_block_42
        cmp #196
        bcs .no_block_42
        lda player_y
        cmp #140
        bcc .no_block_42
        cmp #164
        bcs .no_block_42
        sec
        rts

.chk_push_22:
        cmp #$22                        ; Salle 0x22 (Bow room : bloc gauche 88 du losange)
        bne .check_generic_block
        lda player_x+1
        bne .no_block
        lda player_x
        cmp #126
        bcc .no_block
        cmp #184
        bcs .no_block
        lda player_y
        cmp #124
        bcc .no_block
        cmp #178
        bcs .no_block
        sec
        rts

.check_generic_block:
        lda dungeon_shutter_closed
        beq .no_block
        lda player_dir
        cmp #DIR_UP
        bne .no_block
        sec
        lda player_y
        sbc #16
        sta col_y
        lda player_x
        clc
        adc #8
        sta col_x
        lda player_x+1
        adc #0
        sta col_x+1
        jsr get_tile_at_point
        cmp #TILE_DUNG_BLOCK
        beq .found_block

.no_block:
        clc
        rts

.found_block:
        sec
        rts

; ---------------------------------------------------------------------------
; dungeon_do_push_block : déplace le bloc et révèle le secret
; ---------------------------------------------------------------------------
dungeon_do_push_block:
        lda current_room_idx
        cmp #$42
        bne .chk_do_22

        ldx #$42
        lda dungeon_room_state,x
        ora #(DUNG_SECRET_REVEALED | DUNG_DOOR_W_OPEN)
        sta dungeon_room_state,x
        ldx #$41
        lda dungeon_room_state,x
        ora #DUNG_DOOR_E_OPEN
        sta dungeon_room_state,x

        ; Déplace le bloc (89 -> 88)
        ldy #89
        lda #TILE_DUNG_FLOOR
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile

        ldy #88
        lda #TILE_DUNG_BLOCK
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile

        ; Ouvre le volet Ouest (80 et 100)
        ldy #80
        lda #TILE_DUNG_DOOR_OPEN
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile
        ldy #100
        lda #TILE_DUNG_DOOR_OPEN
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile
        jsr sound_secret_chime
        rts

.chk_do_22:
        cmp #$22
        bne .do_generic_push

        ldx #$22
        lda dungeon_room_state,x
        ora #DUNG_SECRET_REVEALED
        sta dungeon_room_state,x

        ; Salle 0x22 : Déplace le bloc (88 -> 68) et libère l'entrée (88) vers l'escalier central (90)
        ldy #68
        lda #TILE_DUNG_BLOCK
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile

        ldy #88
        lda #TILE_DUNG_FLOOR
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile

        ldy #90
        lda #TILE_DUNG_STAIRS
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile
        jsr sound_secret_chime
        rts

.do_generic_push:
        lda dungeon_shutter_closed
        beq +
        lda #0
        sta dungeon_shutter_closed
        jsr dungeon_open_shutters
        jsr sound_secret_chime
+       rts

; ---------------------------------------------------------------------------
; Tables des indices de tuiles pour les portes (N, S, W, E)
; ---------------------------------------------------------------------------
dung_door_tiles_1: !byte 9, 189, 80, 99
dung_door_tiles_2: !byte 10, 190, 100, 119

; ---------------------------------------------------------------------------
; dungeon_close_shutters : les volets débutent déjà fermés dans le fichier de donjon
; ---------------------------------------------------------------------------
dungeon_close_shutters:
        rts

; ---------------------------------------------------------------------------
; dungeon_open_shutters : rouvre les volets de la salle (4 directions)
; ---------------------------------------------------------------------------
dungeon_open_shutters:
        ldx #3
-       ldy dung_door_tiles_1,x
        lda room_buf,y
        cmp #TILE_DUNG_DOOR_SHUTTER
        bne +
        lda #TILE_DUNG_DOOR_OPEN
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile
        ldy dung_door_tiles_2,x
        lda #TILE_DUNG_DOOR_OPEN
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile
+       dex
        bpl -
        rts

; ---------------------------------------------------------------------------
; dungeon_spawn_room_drop : fait apparaître un butin mérité dans la salle
; ---------------------------------------------------------------------------
dungeon_spawn_boss_heart = dungeon_spawn_room_drop

dungeon_spawn_room_drop:
        lda dungeon_drop_active
        bne .no_drop
        ldx current_room_idx
        lda dungeon_room_state,x
        and #DUNG_ITEM_COLLECTED
        bne .no_drop

        jsr dungeon_get_room_drop_type
        cmp #DROP_NONE
        beq .no_drop

        sta dungeon_drop_type
        lda #1
        sta dungeon_drop_active
        lda #25
        sta dungeon_drop_cooldown

        lda dungeon_drop_type
        cmp #DROP_HEART_CONTAINER
        bne .default_drop_pos
        ; Conteneur de Cœur du Boss : devant la porte Est (X=240, Y=148)
        lda #240
        sta dungeon_drop_x
        lda #0
        sta dungeon_drop_x+1
        lda #148
        sta dungeon_drop_y
        rts

.default_drop_pos:
        lda #180
        sta dungeon_drop_x
        lda #0
        sta dungeon_drop_x+1
        lda #148
        sta dungeon_drop_y
.no_drop:
        rts

; ---------------------------------------------------------------------------
; dungeon_collect_drop : ramasse l'objet au sol
; ---------------------------------------------------------------------------
dungeon_collect_drop:
        ldx current_room_idx
        lda dungeon_room_state,x
        ora #DUNG_ITEM_COLLECTED
        sta dungeon_room_state,x

        lda dungeon_drop_type
        cmp #DROP_KEY
        bne +
        inc hud_keys
        jsr hud_render
        jsr sound_item_fanfare
        lda #0
        sta dungeon_drop_active
        rts

+       cmp #DROP_HEART_CONTAINER
        bne +
        inc hud_max_hearts
        lda hud_max_hearts
        sta hud_cur_hearts
        jsr hud_render
        jsr sound_item_fanfare
        lda #0
        sta dungeon_drop_active
        rts

+       cmp #DROP_COMPASS
        bne +
        lda #1
        sta player_has_compass
        jsr hud_render
        jsr sound_item_fanfare
        lda #0
        sta dungeon_drop_active
        rts

+       cmp #DROP_MAP
        bne +
        lda #1
        sta player_has_dungeon_map
        jsr hud_render
        jsr sound_item_fanfare
        lda #0
        sta dungeon_drop_active
        rts

+       cmp #DROP_BOOMERANG
        bne +
        lda #1
        sta player_has_boomerang
        jsr hud_render
        jsr sound_item_fanfare
        lda #0
        sta dungeon_drop_active
        rts

+       cmp #DROP_TRIFORCE
        bne +
        ; --- OBTENTION DE LA TRIFORCE ! ---
        lda current_dungeon_level
        sec
        sbc #1
        tay
        lda #1
-       cpy #0
        beq ++
        asl
        dey
        jmp -
++      ora player_triforce_pieces
        sta player_triforce_pieces

        lda hud_max_hearts
        sta hud_cur_hearts
        jsr hud_render

        lda #1
        sta triforce_fanfare_timer
        jsr sound_triforce_fanfare
        lda #0
        sta dungeon_drop_active
        rts
+
        lda #0
        sta dungeon_drop_active
        rts

; ---------------------------------------------------------------------------
; dungeon_apply_room_state_active : applique l'état sauvegardé à room_buf
; ---------------------------------------------------------------------------
dungeon_apply_room_state_active:
        lda current_world_type
        cmp #WORLD_DUNGEON
        beq +
        rts
+       lda #<room_buf
        sta ZP_DST
        lda #>room_buf
        sta ZP_DST+1
        ldx current_room_idx
        jmp dungeon_apply_room_state_internal

; ---------------------------------------------------------------------------
; dungeon_apply_room_state_target : applique l'état sauvegardé à target_room_buf
; ---------------------------------------------------------------------------
dungeon_apply_room_state_target:
        lda current_world_type
        cmp #WORLD_DUNGEON
        beq +
        rts
+       lda #<target_room_buf
        sta ZP_DST
        lda #>target_room_buf
        sta ZP_DST+1
        ldx target_room_idx
        jmp dungeon_apply_room_state_internal

; ---------------------------------------------------------------------------
; dungeon_apply_room_state_internal : applique l'état de la salle index X au tampon ZP_DST
; ---------------------------------------------------------------------------
dung_door_masks: !byte DUNG_DOOR_N_OPEN, DUNG_DOOR_S_OPEN, DUNG_DOOR_W_OPEN, DUNG_DOOR_E_OPEN

dungeon_apply_room_state_internal:
        cpx #128
        bcc +
        rts
+       stx ZP_IDX
        lda dungeon_room_state,x
        sta ZP_TMP

        ldx #3
.apply_door_loop:
        lda ZP_TMP
        and dung_door_masks,x
        beq .check_cleared_door
        ldy dung_door_tiles_1,x
        lda #TILE_DUNG_DOOR_OPEN
        sta (ZP_DST),y
        ldy dung_door_tiles_2,x
        sta (ZP_DST),y
        jmp .next_door_apply

.check_cleared_door:
        lda ZP_TMP
        and #DUNG_ROOM_CLEARED
        beq .next_door_apply
        ldy dung_door_tiles_1,x
        lda (ZP_DST),y
        cmp #TILE_DUNG_DOOR_SHUTTER
        bne .next_door_apply
        lda #TILE_DUNG_DOOR_OPEN
        sta (ZP_DST),y
        ldy dung_door_tiles_2,x
        sta (ZP_DST),y

.next_door_apply:
        dex
        bpl .apply_door_loop

        ; Persistance salle 0x42 si secret révélé
        lda ZP_IDX
        cmp #$42
        bne +
        lda ZP_TMP
        and #DUNG_SECRET_REVEALED
        beq +
        ldy #89
        lda #TILE_DUNG_FLOOR
        sta (ZP_DST),y
        ldy #88
        lda #TILE_DUNG_BLOCK
        sta (ZP_DST),y
        ldy #80
        lda #TILE_DUNG_DOOR_OPEN
        sta (ZP_DST),y
        ldy #100
        sta (ZP_DST),y

+       ; Escalier secret salle 0x22 si déjà révélé
        lda ZP_IDX
        cmp #$22
        bne .done_apply
        lda ZP_TMP
        and #DUNG_SECRET_REVEALED
        beq .done_apply

        ldy #68
        lda #TILE_DUNG_BLOCK
        sta (ZP_DST),y
        ldy #88
        lda #TILE_DUNG_FLOOR
        sta (ZP_DST),y
        ldy #90
        lda #TILE_DUNG_STAIRS
        sta (ZP_DST),y

.done_apply:
        rts

; ---------------------------------------------------------------------------
; Routines d'ouverture de portes bidirectionnelles (Nord, Sud, Ouest, Est)
; ---------------------------------------------------------------------------
dungeon_open_north_door:
        ldy #9
        lda #TILE_DUNG_DOOR_OPEN
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile
        ldy #10
        lda #TILE_DUNG_DOOR_OPEN
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile
        jsr sound_secret_chime
        ldx current_room_idx
        lda dungeon_room_state,x
        ora #DUNG_DOOR_N_OPEN
        sta dungeon_room_state,x
        txa
        sec
        sbc #16
        tax
        lda dungeon_room_state,x
        ora #DUNG_DOOR_S_OPEN
        sta dungeon_room_state,x
        rts

dungeon_open_south_door:
        ldy #189
        lda #TILE_DUNG_DOOR_OPEN
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile
        ldy #190
        lda #TILE_DUNG_DOOR_OPEN
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile
        jsr sound_secret_chime
        ldx current_room_idx
        lda dungeon_room_state,x
        ora #DUNG_DOOR_S_OPEN
        sta dungeon_room_state,x
        txa
        clc
        adc #16
        tax
        lda dungeon_room_state,x
        ora #DUNG_DOOR_N_OPEN
        sta dungeon_room_state,x
        rts

dungeon_open_west_door:
        ldy #80
        lda #TILE_DUNG_DOOR_OPEN
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile
        ldy #100
        lda #TILE_DUNG_DOOR_OPEN
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile
        jsr sound_secret_chime
        ldx current_room_idx
        lda dungeon_room_state,x
        ora #DUNG_DOOR_W_OPEN
        sta dungeon_room_state,x
        dex
        lda dungeon_room_state,x
        ora #DUNG_DOOR_E_OPEN
        sta dungeon_room_state,x
        rts

dungeon_open_east_door:
        ldy #99
        lda #TILE_DUNG_DOOR_OPEN
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile
        ldy #119
        lda #TILE_DUNG_DOOR_OPEN
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile
        jsr sound_secret_chime
        ldx current_room_idx
        lda dungeon_room_state,x
        ora #DUNG_DOOR_E_OPEN
        sta dungeon_room_state,x
        inx
        lda dungeon_room_state,x
        ora #DUNG_DOOR_W_OPEN
        sta dungeon_room_state,x
        rts

; ---------------------------------------------------------------------------
; dungeon_check_key_door : ouvre les portes verrouillées si Link a une clé
; ---------------------------------------------------------------------------
dungeon_check_key_door:
        lda hud_keys
        bne .has_key
        lda player_has_magic_key
        bne .has_key
        rts

.has_key:
        ; 1. Porte Nord (y <= 98, x ~ 145..215)
        lda player_y
        cmp #98
        bcs .chk_south
        lda player_x+1
        bne .chk_south
        lda player_x
        cmp #145
        bcc .chk_south
        cmp #215
        bcs .chk_south
        ldy #9
        lda room_buf,y
        cmp #TILE_DUNG_DOOR_LOCKED
        bne .chk_south
        jsr .consume_key
        jmp dungeon_open_north_door

.chk_south:
        ; 2. Porte Sud (y >= 195, x ~ 145..215)
        lda player_y
        cmp #195
        bcc .chk_west
        lda player_x+1
        bne .chk_west
        lda player_x
        cmp #145
        bcc .chk_west
        cmp #215
        bcs .chk_west
        ldy #189
        lda room_buf,y
        cmp #TILE_DUNG_DOOR_LOCKED
        bne .chk_west
        jsr .consume_key
        jmp dungeon_open_south_door

.chk_west:
        ; 3. Porte Ouest (x <= 48, y ~ 125..180)
        lda player_x+1
        bne .chk_east
        lda player_x
        cmp #48
        bcs .chk_east
        lda player_y
        cmp #125
        bcc .chk_east
        cmp #180
        bcs .chk_east
        ldy #80
        lda room_buf,y
        cmp #TILE_DUNG_DOOR_LOCKED
        bne .chk_east
        jsr .consume_key
        jmp dungeon_open_west_door

.chk_east:
        ; 4. Porte Est (x >= 280, y ~ 125..180)
        lda player_x+1
        beq .done_doors
        lda player_x
        cmp #<280
        bcc .done_doors
        lda player_y
        cmp #125
        bcc .done_doors
        cmp #180
        bcs .done_doors
        ldy #99
        lda room_buf,y
        cmp #TILE_DUNG_DOOR_LOCKED
        bne .done_doors
        jsr .consume_key
        jmp dungeon_open_east_door

.done_doors:
        rts

.consume_key:
        lda player_has_magic_key
        bne +
        dec hud_keys
        jsr hud_render
+       rts

; ---------------------------------------------------------------------------
; dungeon_on_bomb_explode : vérifie si l'explosion d'une bombe ouvre un mur
; ---------------------------------------------------------------------------
dungeon_on_bomb_explode:
        lda current_world_type
        cmp #WORLD_DUNGEON
        beq +
        rts
+
        ; 1. Mur Nord : y < 100, x ~ 150..210
        lda item_y
        cmp #100
        bcs .chk_bomb_south
        lda item_x+1
        bne .chk_bomb_south
        lda item_x
        cmp #150
        bcc .chk_bomb_south
        cmp #210
        bcs .chk_bomb_south
        ldy #9
        lda room_buf,y
        cmp #TILE_DUNG_DOOR_BOMB
        bne .chk_bomb_south
        jmp dungeon_open_north_door

.chk_bomb_south:
        ; 2. Mur Sud : y > 200, x ~ 150..210
        lda item_y
        cmp #200
        bcc .chk_bomb_west
        lda item_x+1
        bne .chk_bomb_west
        lda item_x
        cmp #150
        bcc .chk_bomb_west
        cmp #210
        bcs .chk_bomb_west
        ldy #189
        lda room_buf,y
        cmp #TILE_DUNG_DOOR_BOMB
        bne .chk_bomb_west
        jmp dungeon_open_south_door

.chk_bomb_west:
        ; 3. Mur Ouest : x < 50, y ~ 120..180
        lda item_x+1
        bne .chk_bomb_east
        lda item_x
        cmp #50
        bcs .chk_bomb_east
        lda item_y
        cmp #120
        bcc .chk_bomb_east
        cmp #180
        bcs .chk_bomb_east
        ldy #80
        lda room_buf,y
        cmp #TILE_DUNG_DOOR_BOMB
        bne .chk_bomb_east
        jmp dungeon_open_west_door

.chk_bomb_east:
        ; 4. Mur Est : x > 270, y ~ 120..180
        lda item_x+1
        beq .done_bomb
        lda item_x
        cmp #<270
        bcc .done_bomb
        lda item_y
        cmp #120
        bcc .done_bomb
        cmp #180
        bcs .done_bomb
        ldy #99
        lda room_buf,y
        cmp #TILE_DUNG_DOOR_BOMB
        bne .done_bomb
        jmp dungeon_open_east_door

.done_bomb:
        rts

; ===========================================================================
; SALLE ERMITE DONJON 1 (Salle 0x41 : "LA PENINSULE TOUT A L'EST EST LE SECRET.")
; ===========================================================================
dungeon_setup_room_41:
        ldx #0
        lda #0
-       sta en_state,x
        inx
        cpx #MAX_ENEMIES
        bcc -

        ; Ligne 6 : "LA PENINSULE TOUT A L'EST" (25 car)
        ldx #0
-       lda txt_hint_d1_1,x
        sta SCREEN_RAM+240+7,x
        lda #COL_WHITE
        sta COLOR_RAM+240+7,x
        inx
        cpx #25
        bne -

        ; Ligne 8 : "EST LE SECRET." (14 car)
        ldx #0
-       lda txt_hint_d1_2,x
        sta SCREEN_RAM+320+13,x
        lda #COL_WHITE
        sta COLOR_RAM+320+13,x
        inx
        cpx #14
        bne -

        ; Ermite au centre (Sprite 3 : X=160, Y=130)
        lda #(sprite_link_old_man / 64)
        sta SPRITE_PTR3
        lda #COL_RED
        sta VIC_SPRITE_COL3
        lda #160
        sta VIC_SPRITE_X3
        lda #130
        sta VIC_SPRITE_Y3

        ; Torches gauche (Sprite 4 : X=120) et droite (Sprite 5 : X=200)
        lda #(sprite_link_proj_flame_0 / 64)
        sta SPRITE_PTR4
        lda #(sprite_link_proj_flame_1 / 64)
        sta SPRITE_PTR5
        lda #COL_CYAN
        sta VIC_SPRITE_COL4
        sta VIC_SPRITE_COL5
        lda #120
        sta VIC_SPRITE_X4
        lda #200
        sta VIC_SPRITE_X5
        lda #130
        sta VIC_SPRITE_Y4
        sta VIC_SPRITE_Y5

        lda #%00111001
        sta VIC_SPRITE_EN
        sta VIC_SPRITE_MC
        rts

txt_hint_d1_1:  !text "LA PENINSULE TOUT A L'EST"
txt_hint_d1_2:  !text "EST LE SECRET."

; ===========================================================================
; PASSAGE SOUS-TERRAIN VU DE CÔTÉ (STATE_CELLAR - Trésor de l'Arc du Donjon 1)
; Fidèle à la salle souterraine de briques NES (Cellar1 : fond noir, murs de
; briques grises/blanches, échelle à gauche et piédestal central de l'Arc).
; ===========================================================================
; Caractères 2D de l'échelle souterraine (tuile 7 : $20E0..$20FF en mode STATE_CELLAR)
cellar_ladder_char_l:
        !byte %00100100, %00101010, %00100101, %00100100
        !byte %00100100, %00101010, %00100101, %00100100
cellar_ladder_char_r:
        !byte %00100100, %10101000, %01010100, %00100100
        !byte %00100100, %10101000, %01010100, %00100100

build_cellar_room:
        ; 1. Remplit tout le tampon de 200 tuiles de briques (tuile 1 = TILE_DUNG_WALL_TOP)
        ldx #0
        lda #TILE_DUNG_WALL_TOP
-       sta room_buf,x
        inx
        cpx #200
        bcc -

        ; 2. Évide la chambre souterraine centrale (rangées 2..7, colonnes 3..16)
        ;    en fond noir uni (tuile 12 = TILE_DUNG_DOOR_OPEN)
        ldy #40                         ; début rangée 2 (2 * 20)
.cellar_row_loop:
        tya
        clc
        adc #3
        tax                             ; X = offset col 3
        lda #14                         ; 14 colonnes (cols 3..16)
        sta ZP_TMP
        lda #TILE_DUNG_DOOR_OPEN
.cellar_col_loop:
        sta room_buf,x
        inx
        dec ZP_TMP
        bne .cellar_col_loop

        tya
        clc
        adc #20
        tay
        cpy #160                        ; jusqu'à la fin de la rangée 7 (8 * 20)
        bcc .cellar_row_loop

        ; 3. Piliers de briques supérieurs (rangée 2, cols 6..8 et 11..13)
        lda #TILE_DUNG_WALL_TOP
        sta room_buf+46
        sta room_buf+47
        sta room_buf+48
        sta room_buf+51
        sta room_buf+52
        sta room_buf+53

        ; 4. Piédestal central en briques de l'Arc (rangée 7, cols 9..11 = offsets 149..151)
        lda #TILE_DUNG_WALL_TOP
        sta room_buf+149
        sta room_buf+150
        sta room_buf+151

        ; 5. Échelle de descente en colonne 4 (rangées 0..7)
        ldy #4
        ldx #8
-       lda #TILE_DUNG_STAIRS
        sta room_buf,y
        tya
        clc
        adc #20
        tay
        dex
        bne -
        rts

enter_cellar:
        lda #STATE_CELLAR
        sta game_state
        lda #0
        sta cellar_pickup_timer
        sta player_attacking
        sta item_active
        sta en_proj_active
        sta VIC_SPRITE_EXP_X
        sta VIC_SPRITE_EXP_Y
        sta VIC_SPRITE_MSB

        ; Désactive les ennemis de la salle supérieure
        ldx #7
        lda #0
-       sta en_state,x
        dex
        bpl -

        ; Charge le motif d'échelle 2D dans la tuile 7 ($20E0..$20FF)
        ldx #7
-       lda cellar_ladder_char_l,x
        sta $20e0,x
        sta $20f0,x
        lda cellar_ladder_char_r,x
        sta $20e8,x
        sta $20f8,x
        dex
        bpl -

        ; Palette de briques souterraines NES (Noir / Gris / Blanc)
        lda #COL_BLACK
        sta active_bg_color
        sta VIC_BACKGROUND
        lda #COL_GREY
        sta VIC_BG_MC1
        lda #COL_WHITE
        sta VIC_BG_MC2
        lda #9                          ; Multicolore (8) + Blanc (1)
        ldy #15
-       sta active_tile_color,y
        dey
        bpl -

        ; Link apparaît en haut de l'échelle (col 4 : X=88, Y=84)
        lda #88
        sta player_x
        lda #0
        sta player_x+1
        lda #84
        sta player_y
        lda #DIR_DOWN
        sta player_dir

        jsr build_cellar_room
        lda #<room_buf
        sta ZP_MAP
        lda #>room_buf
        sta ZP_MAP+1
        jsr draw_map
        jsr hud_render
        jmp cellar_draw

cellar_update:
        lda cellar_pickup_timer
        beq .cellar_controls
        dec cellar_pickup_timer
        rts

.cellar_controls:
        lda player_x
        cmp #93
        bcs .on_cellar_floor

        ; --- SUR L'ÉCHELLE (X = 88) ---
        lda joy
        and #JOY_UP
        beq +
        lda #DIR_UP
        sta player_dir
        dec player_y
        dec player_y
        lda player_y
        cmp #74
        bcc .do_exit_cellar
        jmp .cellar_anim
.do_exit_cellar:
        jmp exit_cellar

+       lda joy
        and #JOY_DOWN
        beq +
        lda #DIR_DOWN
        sta player_dir
        inc player_y
        inc player_y
        lda player_y
        cmp #188
        bcc .jmp_cellar_anim
        lda #188
        sta player_y
.jmp_cellar_anim:
        jmp .cellar_anim

+       lda joy
        and #JOY_RIGHT
        beq .jmp_cellar_anim
        lda player_y
        cmp #180
        bcc .jmp_cellar_anim
        lda #188
        sta player_y
        inc player_x
        inc player_x
        lda #DIR_RIGHT
        sta player_dir
        jmp .cellar_anim

.on_cellar_floor:
        ; --- SUR LE SOL DE BRIQUES (Y = 188) ---
        lda #188
        sta player_y

        lda joy
        and #JOY_LEFT
        beq +
        lda #DIR_LEFT
        sta player_dir
        dec player_x
        dec player_x
        lda player_x
        cmp #88
        bcs .cellar_walk_l
        lda #88
        sta player_x
.cellar_walk_l:
        jmp .cellar_anim

+       lda joy
        and #JOY_RIGHT
        beq .chk_bow_pickup
        lda #DIR_RIGHT
        sta player_dir
        lda player_x
        cmp #248
        bcs .chk_bow_pickup
        inc player_x
        inc player_x
        jsr .cellar_anim

.chk_bow_pickup:
        ldx #$22
        lda dungeon_room_state,x
        and #DUNG_ITEM_COLLECTED
        bne +
        lda player_x
        cmp #172
        bcc +
        cmp #208
        bcs +
        lda #1
        sta player_has_bow
        sta player_has_arrows
        ldx #$22
        lda dungeon_room_state,x
        ora #DUNG_ITEM_COLLECTED
        sta dungeon_room_state,x
        lda #80
        sta cellar_pickup_timer
        jsr sound_item_fanfare
        jsr hud_render
+       rts

.cellar_anim:
        inc player_walk_tick
        lda player_walk_tick
        cmp #6
        bcc +
        lda #0
        sta player_walk_tick
        lda player_walk_anim
        eor #1
        sta player_walk_anim
+       rts

cellar_draw:
        lda #PLAYER_SKIN
        sta VIC_SPRITE_MC1
        lda #PLAYER_BROWN
        sta VIC_SPRITE_MC2
        lda #%00000011
        sta VIC_SPRITE_MC
        lda #0
        sta VIC_SPRITE_EXP_X
        sta VIC_SPRITE_EXP_Y
        sta VIC_SPRITE_MSB

        ; Sprite 0 : Link
        lda player_x
        sta VIC_SPRITE_X0
        lda player_y
        sta VIC_SPRITE_Y0
        lda player_has_blue_ring
        beq +
        lda #COL_WHITE
        bne ++
+       lda #COL_GREEN
++      sta VIC_SPRITE_COL0

        lda cellar_pickup_timer
        beq .cellar_normal_spr
        lda #(sprite_link_item_get / 64)
        sta SPRITE_PTR0

        ; Sprite 1 : Arc brandi au-dessus de la tête
        lda #(sprite_link_item_bow / 64)
        sta SPRITE_PTR1
        lda #COL_GREEN
        sta VIC_SPRITE_COL1
        lda player_x
        sta VIC_SPRITE_X1
        lda player_y
        sec
        sbc #16
        sta VIC_SPRITE_Y1
        lda #%00000011
        sta VIC_SPRITE_EN
        rts

.cellar_normal_spr:
        lda player_x
        cmp #93
        bcs .cellar_floor_spr
        lda #(sprite_link_up_0 / 64)
        clc
        adc player_walk_anim
        sta SPRITE_PTR0
        jmp .draw_bow_pedestal

.cellar_floor_spr:
        lda player_dir
        asl
        ora player_walk_anim
        clc
        adc #(sprite_link_down_0 / 64)
        sta SPRITE_PTR0

.draw_bow_pedestal:
        ldx #$22
        lda dungeon_room_state,x
        and #DUNG_ITEM_COLLECTED
        bne .no_bow_pedestal
        lda #(sprite_link_item_bow / 64)
        sta SPRITE_PTR1
        lda #COL_GREEN
        sta VIC_SPRITE_COL1
        lda #188
        sta VIC_SPRITE_X1
        lda #174
        sta VIC_SPRITE_Y1
        lda #%00000011
        sta VIC_SPRITE_EN
        rts

.no_bow_pedestal:
        lda #%00000001
        sta VIC_SPRITE_EN
        rts

exit_cellar:
        lda #STATE_PLAYING
        sta game_state
        lda #0
        sta cellar_pickup_timer
        lda #152
        sta player_x
        lda #0
        sta player_x+1
        lda #143
        sta player_y
        lda #DIR_LEFT
        sta player_dir
        jsr copy_map_charset
        jsr load_room
        jsr dungeon_apply_room_state_active
        jsr enemies_room_init
        jmp hud_render


