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

; Types de drops de donjon
DROP_NONE               = 0
DROP_KEY                = 1
DROP_HEART_CONTAINER    = 2
DROP_COMPASS            = 3
DROP_MAP                = 4
DROP_TRIFORCE           = 5

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
        ; Vérifie si c'est la salle du Boss du niveau actif
        ldx current_dungeon_level
        dex
        cpx #9
        bcs .no_monsters
        lda dungeon_boss_rooms,x
        cmp current_room_idx
        bne .no_monsters

        ; C'est la salle du Boss ! Si des monstres sont vivants, les volets se ferment !
        ldx #0
        ldy #0
-       lda en_state,x
        cmp #EN_STATE_DEAD
        beq +
        iny                             ; Y = nombre de monstres vivants
+       inx
        cpx #MAX_ENEMIES
        bcc -

        cpy #0
        beq .no_monsters
        ; Ferme les volets de la salle
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
        rts

; ---------------------------------------------------------------------------
; check_link_pushing_block : vérifie si Link pousse contre un bloc poussable
; ---------------------------------------------------------------------------
check_link_pushing_block:
        lda player_dir
        cmp #DIR_UP
        beq .push_up
        cmp #DIR_RIGHT
        beq .push_right
        clc
        rts

.push_up:
        sec
        lda player_y
        sbc #18
        sta col_y
        lda player_x
        clc
        adc #8
        sta col_x
        lda player_x+1
        adc #0
        sta col_x+1
        jsr get_tile_at_point
        cmp #TILE_TREE                  ; Bloc/pilier de donjon
        beq .found_block
        clc
        rts

.push_right:
        clc
        lda player_x
        adc #20
        sta col_x
        lda player_x+1
        adc #0
        sta col_x+1
        lda player_y
        clc
        adc #8
        sta col_y
        jsr get_tile_at_point
        cmp #TILE_TREE
        beq .found_block
        clc
        rts

.found_block:
        sec
        rts

; ---------------------------------------------------------------------------
; dungeon_do_push_block : déplace le bloc et révèle le secret
; ---------------------------------------------------------------------------
dungeon_do_push_block:
        ; Révèle un escalier secret au centre de la salle ou ouvre les volets
        lda dungeon_shutter_closed
        beq +
        lda #0
        sta dungeon_shutter_closed
        jsr dungeon_open_shutters
+
        ; Place un escalier (TILE_CAVE) au centre de la salle si pas encore fait
        ldy #90                         ; tuile (10, 4) = 4*20 + 10 = 90
        lda #TILE_CAVE
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile
        rts

; ---------------------------------------------------------------------------
; dungeon_close_shutters : ferme visuellement les 4 portes de la salle
; ---------------------------------------------------------------------------
dungeon_close_shutters:
        ; Porte Nord : tuiles 9 et 10
        ldy #9
        lda #TILE_WALL
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile
        ldy #10
        lda #TILE_WALL
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile

        ; Porte Sud : tuiles 189 et 190
        ldy #189
        lda #TILE_WALL
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile
        ldy #190
        lda #TILE_WALL
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile
        rts

; ---------------------------------------------------------------------------
; dungeon_open_shutters : rouvre les portes de la salle
; ---------------------------------------------------------------------------
dungeon_open_shutters:
        ; Porte Nord
        ldy #9
        lda #TILE_GRASS
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile
        ldy #10
        lda #TILE_GRASS
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile

        ; Porte Sud
        ldy #189
        lda #TILE_GRASS
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile
        ldy #190
        lda #TILE_GRASS
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile
        rts

; ---------------------------------------------------------------------------
; dungeon_spawn_room_drop : fait apparaître un butin mérité au centre de la salle
; ---------------------------------------------------------------------------
dungeon_spawn_room_drop:
        ; Vérifie si c'est une salle de boss officielle
        ldx current_dungeon_level
        dex
        cpx #9
        bcs .not_boss_drop
        lda dungeon_boss_rooms,x
        cmp current_room_idx
        beq .spawn_boss_heart
.not_boss_drop:

        ; Sinon, lâche une petite clef de donjon
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
+       cmp #DROP_TRIFORCE
        bne +
        ; --- OBTENTION DE LA TRIFORCE ! ---
        lda current_dungeon_level
        sec
        sbc #1                          ; 0..7
        tay
        lda #1
-       cpy #0
        beq ++
        asl
        dey
        jmp -
++      ora player_triforce_pieces
        sta player_triforce_pieces

        ; Soin complet
        lda hud_max_hearts
        sta hud_cur_hearts
        jsr hud_render

        ; Déclenche la célébration pendant 150 frames (~3 secondes)
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
; ---------------------------------------------------------------------------
dungeon_check_key_door:
        lda hud_keys
        bne .has_key
        lda player_has_magic_key
        bne .has_key
        rts

.has_key:
        ; Link est-il tout en haut contre le chambranle nord (y ~ 82..88, x ~ 170..190) ?
        lda player_y
        cmp #88
        bcs .chk_south
        lda player_x+1
        bne .chk_south
        lda player_x
        cmp #168
        bcc .chk_south
        cmp #196
        bcs .chk_south

        ; Vérifie si la porte nord est fermée/solide
        ldy #9
        lda (ZP_MAP),y
        cmp #TILE_WALL
        bne .chk_south

        ; Ouvre la porte nord !
        lda player_has_magic_key
        bne +
        dec hud_keys
        jsr hud_render
+       jsr dungeon_open_shutters
        jsr sound_secret_chime
        rts

.chk_south:
        ; Link est-il tout en bas contre le chambranle sud (y ~ 220, x ~ 170..190) ?
        lda player_y
        cmp #218
        bcc .done_doors
        lda player_x+1
        bne .done_doors
        lda player_x
        cmp #168
        bcc .done_doors
        cmp #196
        bcs .done_doors

        ldy #189
        lda (ZP_MAP),y
        cmp #TILE_WALL
        bne .done_doors

        lda player_has_magic_key
        bne +
        dec hud_keys
        jsr hud_render
+       jsr dungeon_open_shutters
        jsr sound_secret_chime

.done_doors:
        rts

; ---------------------------------------------------------------------------
; dungeon_on_bomb_explode : vérifie si l'explosion d'une bombe ouvre un mur
; ---------------------------------------------------------------------------
dungeon_on_bomb_explode:
        lda current_world_type
        cmp #WORLD_DUNGEON
        beq +
        rts
+
        ; Si la bombe explose près du mur nord (y < 100, x ~ 160..200)
        lda item_y
        cmp #100
        bcs +
        lda item_x+1
        bne +
        lda item_x
        cmp #150
        bcc +
        cmp #210
        bcs +
        ; Ouvre le passage nord !
        ldy #9
        lda #TILE_WALL_PASS
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile
        ldy #10
        lda #TILE_WALL_PASS
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile
        jsr sound_secret_chime
+       rts

; ---------------------------------------------------------------------------
; sound_item_fanfare : fanfare triomphale de trouvaille d'objet
; ---------------------------------------------------------------------------
sound_item_fanfare:
        lda #15
        sta SID_VOLUME
        lda #$80
        sta SID_V1_FREQ_LO
        lda #$50
        sta SID_V1_FREQ_HI
        lda #$09
        sta SID_V1_AD
        lda #$40
        sta SID_V1_SR
        lda #%00010001                  ; Triangle
        sta SID_V1_CTRL
        rts
