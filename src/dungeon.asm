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
triforce_fanfare_timer: !byte 0

DROP_NONE               = 0
DROP_KEY                = 1
DROP_HEART_CONTAINER    = 2
DROP_COMPASS            = 3
DROP_MAP                = 4
DROP_TRIFORCE           = 5
DROP_BOOMERANG          = 6
DROP_BOW                = 7

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
        sta triforce_fanfare_timer
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

        ; Vérifie si c'est la salle de la Triforce du niveau actif
        ldx current_dungeon_level
        dex
        cpx #9
        bcs .check_boss_room
        lda dungeon_triforce_rooms,x
        cmp current_room_idx
        bne .check_boss_room

        ; C'est la salle de la Triforce du donjon actif !
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

.check_boss_room:
        ldx current_dungeon_level
        dex
        cpx #9
        bcs .check_special_rooms
        lda dungeon_boss_rooms,x
        cmp current_room_idx
        bne .check_special_rooms

        ; Salle du Boss : volets fermés si boss vivant !
        ldx #0
        ldy #0
-       lda en_state,x
        cmp #EN_STATE_DEAD
        beq +
        iny
+       inx
        cpx #MAX_ENEMIES
        bcc -
        cpy #0
        bne +
        jmp .no_monsters
+       lda #1
        sta dungeon_shutter_closed
        jsr dungeon_close_shutters
        rts

.check_special_rooms:
        lda current_dungeon_level
        cmp #1
        beq +
        jmp .no_monsters
+

        ; Niveau 1 : salles avec drops ou volets
        lda current_room_idx
        cmp #$72                        ; Salle Ouest Entrée : Clé au sol
        bne +
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
        rts

+       cmp #$54                        ; Salle Boussole
        bne +
        lda player_has_compass
        bne .no_monsters
        lda #DROP_COMPASS
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

+       cmp #$45                        ; Salle Carte
        bne +
        lda player_has_dungeon_map
        bne .no_monsters
        lda #DROP_MAP
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

+       cmp #$44                        ; Salle Boomerang (Goriyas)
        beq .shutters_on_enemies
        cmp #$23                        ; Salle U-Wall (Goriyas)
        beq .shutters_on_enemies
        jmp .no_monsters

.shutters_on_enemies:
        ldx #0
        ldy #0
-       lda en_state,x
        cmp #EN_STATE_DEAD
        beq +
        iny
+       inx
        cpx #MAX_ENEMIES
        bcc -
        cpy #0
        beq .no_monsters
        lda #1
        sta dungeon_shutter_closed
        jsr dungeon_close_shutters
        rts

.no_monsters:
        lda #0
        sta dungeon_shutter_closed
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
        ; 1. Gestion de la fanfare de la Triforce en cours
        lda triforce_fanfare_timer
        beq .check_shutters
        dec triforce_fanfare_timer
        bne .hold_triforce
        ; Fin de la célébration : retour à l'extérieur dans l'overworld !
        jsr exit_dungeon
        rts

.hold_triforce:
        ; Link brandit l'objet vers le haut
        lda #< (sprite_link_item_get / 64)
        sta SPRITE_PTR0
        rts

.check_shutters:
        ; 2. Vérification des volets fermés : si tous les monstres sont morts, ouverture !
        lda dungeon_shutter_closed
        beq .check_push_block

        ldx #0
        ldy #0
-       lda en_state,x
        cmp #EN_STATE_DEAD
        beq +
        iny
+       inx
        cpx #MAX_ENEMIES
        bcc -

        cpy #0
        bne .check_push_block
        ; Tous les monstres sont vaincus !
        lda #0
        sta dungeon_shutter_closed
        jsr dungeon_open_shutters
        jsr sound_secret_chime

        ; Apparition du butin de salle
        jsr dungeon_spawn_room_drop

.check_push_block:
        ; 3. Bloc poussable : Link pousse contre un bloc (colonne/rangée centrale)
        lda dungeon_block_pushed
        bne .check_drop_pickup

        lda joy
        and #(JOY_UP | JOY_RIGHT)
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

        ; 6. Escalier secret vers l'Arc (Salle 0x22)
        lda current_room_idx
        cmp #$22
        bne +
        lda player_has_bow
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
        lda #1
        sta player_has_bow
        jsr sound_item_fanfare
        jsr hud_render
+       rts

; ---------------------------------------------------------------------------
; check_link_pushing_block : vérifie si Link pousse contre un bloc poussable
; ---------------------------------------------------------------------------
check_link_pushing_block:
        lda current_room_idx
        cmp #$22                        ; Salle 0x22 (Bow room)
        bne .check_generic_block

        ; Salle 0x22 : Link pousse vers le haut contre le bloc gauche (offset 86)
        lda player_dir
        cmp #DIR_UP
        bne .no_block
        lda player_y
        cmp #140
        bcc .no_block
        cmp #170
        bcs .no_block
        lda player_x
        cmp #100
        bcc .no_block
        cmp #135
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
        cmp #$22
        bne .do_generic_push

        ; Salle 0x22 : Déplace le bloc (86 -> 66) et révèle l'escalier (88)
        ldy #86
        lda #TILE_DUNG_FLOOR
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile

        ldy #66
        lda #TILE_DUNG_BLOCK
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile

        ldy #88
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
; dungeon_close_shutters : ferme visuellement les portes ouvertes de la salle
; ---------------------------------------------------------------------------
dungeon_close_shutters:
        ; Porte Nord : tuiles 9 et 10
        ldy #9
        lda room_buf,y
        cmp #TILE_DUNG_DOOR_OPEN
        bne +
        lda #TILE_DUNG_DOOR_SHUTTER
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile
        ldy #10
        lda #TILE_DUNG_DOOR_SHUTTER
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile

+       ; Porte Sud : tuiles 189 et 190
        ldy #189
        lda room_buf,y
        cmp #TILE_DUNG_DOOR_OPEN
        bne +
        lda #TILE_DUNG_DOOR_SHUTTER
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile
        ldy #190
        lda #TILE_DUNG_DOOR_SHUTTER
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile

+       ; Porte Ouest : tuiles 80 et 100
        ldy #80
        lda room_buf,y
        cmp #TILE_DUNG_DOOR_OPEN
        bne +
        lda #TILE_DUNG_DOOR_SHUTTER
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile
        ldy #100
        lda #TILE_DUNG_DOOR_SHUTTER
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile

+       ; Porte Est : tuiles 99 et 119
        ldy #99
        lda room_buf,y
        cmp #TILE_DUNG_DOOR_OPEN
        bne +
        lda #TILE_DUNG_DOOR_SHUTTER
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile
        ldy #119
        lda #TILE_DUNG_DOOR_SHUTTER
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile
+       rts

; ---------------------------------------------------------------------------
; dungeon_open_shutters : rouvre les volets de la salle (4 directions)
; ---------------------------------------------------------------------------
dungeon_open_shutters:
        ; Porte Nord
        ldy #9
        lda room_buf,y
        cmp #TILE_DUNG_DOOR_SHUTTER
        bne +
        lda #TILE_DUNG_DOOR_OPEN
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile
        ldy #10
        lda #TILE_DUNG_DOOR_OPEN
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile

+       ; Porte Sud
        ldy #189
        lda room_buf,y
        cmp #TILE_DUNG_DOOR_SHUTTER
        bne +
        lda #TILE_DUNG_DOOR_OPEN
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile
        ldy #190
        lda #TILE_DUNG_DOOR_OPEN
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile

+       ; Porte Ouest
        ldy #80
        lda room_buf,y
        cmp #TILE_DUNG_DOOR_SHUTTER
        bne +
        lda #TILE_DUNG_DOOR_OPEN
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile
        ldy #100
        lda #TILE_DUNG_DOOR_OPEN
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile

+       ; Porte Est
        ldy #99
        lda room_buf,y
        cmp #TILE_DUNG_DOOR_SHUTTER
        bne +
        lda #TILE_DUNG_DOOR_OPEN
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile
        ldy #119
        lda #TILE_DUNG_DOOR_OPEN
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile
+       rts

; ---------------------------------------------------------------------------
; dungeon_spawn_room_drop : fait apparaître un butin mérité au centre de la salle
; ---------------------------------------------------------------------------
dungeon_spawn_room_drop:
        ldx current_dungeon_level
        dex
        cpx #9
        bcs .not_boss_drop
        lda dungeon_boss_rooms,x
        cmp current_room_idx
        beq .spawn_boss_heart
.not_boss_drop:
        lda current_dungeon_level
        cmp #1
        bne .default_key_drop

        ; Si salle 0x44 (Boomerang) : drop Boomerang !
        lda current_room_idx
        cmp #$44
        bne .default_key_drop
        lda player_has_boomerang
        bne .default_key_drop
        lda #DROP_BOOMERANG
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

.default_key_drop:
        lda #DROP_KEY
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

dungeon_spawn_boss_heart:
.spawn_boss_heart:
        lda #DROP_HEART_CONTAINER
        sta dungeon_drop_type
        lda #1
        sta dungeon_drop_active
        lda #180
        sta dungeon_drop_x
        lda #0
        sta dungeon_drop_x+1
        lda #148
        sta dungeon_drop_y
        ; Ouvre les volets et joue le carillon secret
        lda #0
        sta dungeon_shutter_closed
        jsr dungeon_open_shutters
        jsr sound_secret_chime
        rts

; ---------------------------------------------------------------------------
; dungeon_collect_drop : ramasse l'objet au sol
; ---------------------------------------------------------------------------
dungeon_collect_drop:
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

        lda #150
        sta triforce_fanfare_timer
        jsr sound_item_fanfare
        lda #0
        sta dungeon_drop_active
        rts
+
        lda #0
        sta dungeon_drop_active
        rts

; ---------------------------------------------------------------------------
; dungeon_check_key_door : ouvre les portes verrouillées si Link a une clé
;   Gère les 4 directions : Nord (9), Sud (189), Ouest (80), Est (99)
; ---------------------------------------------------------------------------
dungeon_check_key_door:
        lda hud_keys
        bne .has_key
        lda player_has_magic_key
        bne .has_key
        rts

.has_key:
        ; 1. Porte Nord (y <= 88, x ~ 160..200)
        lda player_y
        cmp #88
        bcs .chk_south
        lda player_x+1
        bne .chk_south
        lda player_x
        cmp #160
        bcc .chk_south
        cmp #200
        bcs .chk_south

        ldy #9
        lda room_buf,y
        cmp #TILE_DUNG_DOOR_LOCKED
        bne .chk_south

        ; Ouvre la porte nord !
        jsr .consume_key
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
        rts

.chk_south:
        ; 2. Porte Sud (y >= 218, x ~ 160..200)
        lda player_y
        cmp #218
        bcc .chk_west
        lda player_x+1
        bne .chk_west
        lda player_x
        cmp #160
        bcc .chk_west
        cmp #200
        bcs .chk_west

        ldy #189
        lda room_buf,y
        cmp #TILE_DUNG_DOOR_LOCKED
        bne .chk_west

        ; Ouvre la porte sud !
        jsr .consume_key
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
        rts

.chk_west:
        ; 3. Porte Ouest (x <= 36, y ~ 130..170)
        lda player_x+1
        bne .chk_east
        lda player_x
        cmp #36
        bcs .chk_east
        lda player_y
        cmp #130
        bcc .chk_east
        cmp #170
        bcs .chk_east

        ldy #80
        lda room_buf,y
        cmp #TILE_DUNG_DOOR_LOCKED
        bne .chk_east

        ; Ouvre la porte ouest !
        jsr .consume_key
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

.chk_east:
        ; 4. Porte Est (x >= 284, y ~ 130..170)
        lda player_x+1
        beq .done_doors
        lda player_x
        cmp #<284
        bcc .done_doors
        lda player_y
        cmp #130
        bcc .done_doors
        cmp #170
        bcs .done_doors

        ldy #99
        lda room_buf,y
        cmp #TILE_DUNG_DOOR_LOCKED
        bne .done_doors

        ; Ouvre la porte est !
        jsr .consume_key
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
;   Gère les 4 directions : Nord (9), Sud (189), Ouest (80), Est (99)
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
        rts

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
        rts

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

.done_bomb:
        rts
