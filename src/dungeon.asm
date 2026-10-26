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
; dungeon_room_state est alloué proprement en mémoire résidente BSS dans main.asm

DROP_NONE               = 0
DROP_KEY                = 1
DROP_HEART_CONTAINER    = 2
DROP_COMPASS            = 3
DROP_MAP                = 4
DROP_TRIFORCE           = 5
DROP_BOOMERANG          = 6
DROP_BOW                = 7
DROP_RAFT               = 8
DROP_LADDER             = 9
DROP_WHISTLE            = 10
DROP_WAND               = 11
DROP_CANDLE             = 12
DROP_MAGIC_KEY          = 13
DROP_BOOK               = 14
DROP_RED_RING           = 15
DROP_SILVER_ARROW       = 16

DUNG_DOOR_N_OPEN        = %00000001     ; Porte Nord déverrouillée / ouverte
DUNG_DOOR_S_OPEN        = %00000010     ; Porte Sud déverrouillée / ouverte
DUNG_DOOR_W_OPEN        = %00000100     ; Porte Ouest déverrouillée / ouverte
DUNG_DOOR_E_OPEN        = %00001000     ; Porte Est déverrouillée / ouverte
DUNG_ROOM_CLEARED       = %00010000     ; Monstres éliminés (volets ouverts)
DUNG_ITEM_COLLECTED     = %00100000     ; Objet de salle ramassé
DUNG_SECRET_REVEALED    = %01000000     ; Escalier de l'arc révélé (bloc poussé)
DUNG_BLOCK_DOWN         = %10000000     ; Salle 0x22 : le bloc a été poussé vers le BAS (sinon vers le haut)

; Tables des salles officielles de boss et triforce (Niveaux 1 à 9)
dungeon_boss_rooms:
        !byte $35, $0e, $4d, $13, $24, $1c, $2a, $3c, $42
dungeon_triforce_rooms:
        !byte $36, $0d, $3d, $03, $14, $0c, $2b, $2c, $32

; ---------------------------------------------------------------------------
; VALIDATION DES POINTS D'APPARITION (ennemis et objets au sol)
;
; Un point d'apparition donné par une table (tuile tx,ty) peut tomber dans un bloc,
; une statue, un mur ou l'eau : l'ennemi y reste coincé et l'objet est inaccessible.
; spawn_validate_tile remplace alors la case par la case libre la plus proche
; (24 décalages triés par distance, Manhattan <= 3). Une case déjà valide n'est
; jamais modifiée. Les bornes et la règle de case dépendent du monde et du type.
; ---------------------------------------------------------------------------
SPAWN_FLOOR             = 0             ; donjon : dalle de sol pure (tuile 0)
SPAWN_WALK              = 1             ; overworld : tuile non solide, hors entrée de grotte
SPAWN_WATER             = 2             ; overworld : eau (Zora)
SPAWN_OFFS_COUNT        = 24

spawn_tx:               !byte 0         ; entrée / sortie : tuile X
spawn_ty:               !byte 0         ; entrée / sortie : tuile Y
spawn_min_tx:           !byte 2
spawn_max_tx:           !byte 17
spawn_min_ty:           !byte 1
spawn_max_ty:           !byte 8
spawn_kind:             !byte SPAWN_FLOOR
spawn_try_x:            !byte 0
spawn_try_y:            !byte 0
spawn_ofs_idx:          !byte 0

; 24 décalages (dx, dy) triés par (distance Manhattan, Chebyshev, dy, dx).
; Cette table est relue par tools/validate_spawns.py : ne pas la réordonner sans le relancer.
spawn_offs_dx:  !byte 0, $ff, 1, 0, $ff, 1, $ff, 1, 0, $fe, 2, 0, $ff, 1, $fe, 2, $fe, 2, $ff, 1, 0, $fd, 3, 0
spawn_offs_dy:  !byte $ff, 0, 0, 1, $ff, $ff, 1, 1, $fe, 0, 0, 2, $fe, $fe, $ff, $ff, 1, 1, 2, 2, $fd, 0, 0, 3

; ---------------------------------------------------------------------------
; spawn_check_try : la case (spawn_try_x, spawn_try_y) est-elle acceptable ?
; Sortie : Carry = 1 si oui. Un décalage négatif devient un grand nombre non signé
;          et est donc rejeté par le test de borne supérieure.
; ---------------------------------------------------------------------------
spawn_check_try:
        lda spawn_try_x
        cmp spawn_min_tx
        bcc .sct_no
        cmp spawn_max_tx
        beq +
        bcs .sct_no
+       lda spawn_try_y
        cmp spawn_min_ty
        bcc .sct_no
        cmp spawn_max_ty
        beq +
        bcs .sct_no
+       ldy spawn_try_y
        lda tile_row_offset,y
        clc
        adc spawn_try_x
        tay                             ; Y = ty * 20 + tx
        lda room_buf,y
        cmp #TILE_DUNG_BLOCK            ; Reject dungeon blocks (pushable blocks)
        beq .sct_no
        cmp #TILE_DUNG_STAIRS           ; Reject stairs 
        beq .sct_no
        
        ldx spawn_kind
        beq .sct_floor
        cpx #SPAWN_WATER
        beq .sct_water
        cmp #TILE_CAVE                  ; SPAWN_WALK
        beq .sct_no
        tax
        lda tile_flags,x
        and #TILE_SOLID
        bne .sct_no
        
        sec
        rts
.sct_floor:
        cmp #TILE_DUNG_FLOOR
        bne .sct_no
        sec
        rts
.sct_water:
        cmp #TILE_WATER
        bne .sct_no
        sec
        rts
.sct_no:
        clc
        rts

; ---------------------------------------------------------------------------
; spawn_validate_tile : corrige (spawn_tx, spawn_ty) si la case ne convient pas
; Sortie : Carry = 1 si la case finale est valide, Carry = 0 si aucune case libre
;          n'a été trouvée (la position d'origine est alors conservée).
; ---------------------------------------------------------------------------
spawn_validate_tile:
        lda spawn_tx
        sta spawn_try_x
        lda spawn_ty
        sta spawn_try_y
        jsr spawn_check_try
        bcs .sv_done
        ldx #0
.sv_loop:
        stx spawn_ofs_idx
        lda spawn_tx
        clc
        adc spawn_offs_dx,x
        sta spawn_try_x
        lda spawn_ty
        clc
        adc spawn_offs_dy,x
        sta spawn_try_y
        jsr spawn_check_try
        bcs .sv_found
        ldx spawn_ofs_idx
        inx
        cpx #SPAWN_OFFS_COUNT
        bcc .sv_loop
        clc                             ; aucune case : position d'origine conservée
        rts
.sv_found:
        lda spawn_try_x
        sta spawn_tx
        lda spawn_try_y
        sta spawn_ty
        sec
.sv_done:
        rts

; ---------------------------------------------------------------------------
; spawn_set_bounds_enemy : bornes et règle de case pour l'ennemi en_idx
; Sortie : Carry = 1 si l'ennemi doit être validé, Carry = 0 s'il en est dispensé
;          (pièges dans les murs, statues Armos)
; ---------------------------------------------------------------------------
spawn_set_bounds_enemy:
        ldx en_idx
        lda en_type,x
        cmp #TYPE_TRAP
        beq .ssb_skip
        cmp #TYPE_ARMOS
        beq .ssb_skip
        lda current_world_type
        bne .ssb_dungeon
        ; Overworld : toute la zone de jeu (20 x 10 tuiles)
        lda #0
        sta spawn_min_tx
        sta spawn_min_ty
        lda #19
        sta spawn_max_tx
        lda #9
        sta spawn_max_ty
        lda #SPAWN_WALK
        sta spawn_kind
        lda en_type,x
        cmp #TYPE_ZORA
        bne .ssb_ok
        lda #SPAWN_WATER                ; le Zora doit rester dans l'eau
        sta spawn_kind
        jmp .ssb_ok
.ssb_dungeon:
        ; Donjon : intérieur de la salle (hors murs et portes)
        lda #2
        sta spawn_min_tx
        lda #17
        sta spawn_max_tx
        lda #1
        sta spawn_min_ty
        lda #8
        sta spawn_max_ty
        lda #SPAWN_FLOOR
        sta spawn_kind
.ssb_ok:
        sec
        rts
.ssb_skip:
        clc
        rts

; ---------------------------------------------------------------------------
; dungeon_place_drop : place l'objet au sol sur la tuile (A = tile_x, X = tile_y)
; après validation. Remplit dungeon_drop_x / dungeon_drop_y (pixels sprite).
;   x = 20 + 16 * tx   (tx <= 14 : le sprite 2 n'a pas de bit MSB X)
;   y = 84 + 16 * ty   ((10,4) -> (180,148) comme avant)
; ---------------------------------------------------------------------------
dungeon_place_drop:
        sta spawn_tx
        stx spawn_ty
        lda #2
        sta spawn_min_tx
        lda #14
        sta spawn_max_tx
        lda #1
        sta spawn_min_ty
        lda #8
        sta spawn_max_ty
        lda #SPAWN_FLOOR
        sta spawn_kind
        jsr spawn_validate_tile
        lda spawn_tx
        asl
        asl
        asl
        asl
        clc
        adc #20
        sta dungeon_drop_x
        lda #0
        sta dungeon_drop_x+1
        lda spawn_ty
        asl
        asl
        asl
        asl
        clc
        adc #84
        sta dungeon_drop_y
        rts

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
        sta visited_uw_rooms,x
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
        ; 1. Salle Triforce (officielle pour chaque niveau 1..9)
        ldx current_dungeon_level
        dex
        cpx #9
        bcs .check_floor_key
        lda dungeon_triforce_rooms,x
        cmp current_room_idx
        bne .check_floor_key
        ldx current_room_idx
        lda dungeon_room_state,x
        and #DUNG_ITEM_COLLECTED
        beq +
        rts
+       lda #DROP_TRIFORCE
        sta dungeon_drop_type
        lda #1
        sta dungeon_drop_active
        lda #10                         ; tuile (10,4) : centre de la salle
        ldx #4
        jsr dungeon_place_drop
        rts

.check_floor_key:
        ; 2. Salles avec clés au sol au premier passage
        lda current_dungeon_level
        cmp #1
        bne .chk_floor_d2
        ldx current_room_idx
        cpx #$72
        bne .check_cleared_drop
        lda #13                         ; tuile (13,6) : clé Donjon 1
        ldx #6
        jmp .spawn_floor_key

.chk_floor_d2:
        cmp #2
        bne .chk_floor_d3
        ldx current_room_idx
        cpx #$6E
        bne .check_cleared_drop
        lda #10                         ; tuile (10,4) : clé Donjon 2
        ldx #4
        jmp .spawn_floor_key

.chk_floor_d3:
        cmp #3
        bne .check_cleared_drop
        ldx current_room_idx
        cpx #$6C
        beq +
        cpx #$7B
        bne .check_cleared_drop
+       lda #10                         ; tuile (10,4) : clé Donjon 3
        ldx #4

.spawn_floor_key:
        sta spawn_try_x
        stx spawn_try_y
        ldx current_room_idx
        lda dungeon_room_state,x
        and #DUNG_ITEM_COLLECTED
        bne .check_shutters_enter
        lda #DROP_KEY
        sta dungeon_drop_type
        lda #1
        sta dungeon_drop_active
        lda spawn_try_x
        ldx spawn_try_y
        jsr dungeon_place_drop
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
        bne +
        jmp .lvl1_shutters
+       cmp #2
        bne +
        jmp .lvl2_shutters
+       cmp #3
        bne +
        jmp .lvl3_shutters
+       cmp #4
        bne +
        jmp .lvl4_shutters
+       cmp #5
        bne +
        jmp .lvl5_shutters
+       cmp #6
        bne +
        jmp .lvl6_shutters
+       cmp #7
        bne +
        jmp .lvl7_shutters
+       cmp #8
        bne +
        jmp .lvl8_shutters
+       cmp #9
        bne +
        jmp .lvl9_shutters
+       jmp .chk_generic_boss

.has_shutt_69:
        sec
        rts

.lvl6_shutters:
        lda current_room_idx
        cmp #$1C                        ; Boss Gohma Red
        beq .has_shutt_69
        cmp #$49                        ; Wizzrobes
        beq .has_shutt_69
        cmp #$5A                        ; Wizzrobes
        beq .has_shutt_69
        cmp #$38
        beq .has_shutt_69
        clc
        rts

.lvl7_shutters:
        lda current_room_idx
        cmp #$2A                        ; Boss Aquamentus
        beq .has_shutt_69
        cmp #$59
        beq .has_shutt_69
        cmp #$6B
        beq .has_shutt_69
        cmp #$18
        beq .has_shutt_69
        clc
        rts

.lvl8_shutters:
        lda current_room_idx
        cmp #$3C                        ; Boss Dodongo
        beq .has_shutt_69
        cmp #$4D
        beq .has_shutt_69
        cmp #$5E
        beq .has_shutt_69
        cmp #$7F
        beq .has_shutt_69
        clc
        rts

.lvl9_shutters:
        lda current_room_idx
        cmp #$42                        ; Boss Ganon
        beq .has_shutt_69
        cmp #$66
        beq .has_shutt_69
        cmp #$45
        beq .has_shutt_69
        clc
        rts

.lvl1_shutters:
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

.lvl2_shutters:
        lda current_room_idx
        cmp #$0E                        ; Salle 0x0E : Boss Dodongo (Volet Ouest)
        beq .has_shutt
        cmp #$1E                        ; Salle 0x1E : Volets Nord & Sud
        beq .has_shutt
        cmp #$4E                        ; Salle 0x4E : Volet Sud
        beq .has_shutt
        cmp #$6D                        ; Salle 0x6D : Volet Ouest
        beq .has_shutt
        clc
        rts

.lvl3_shutters:
        lda current_room_idx
        cmp #$4D                        ; Salle 0x4D : Boss Manhandla (Volet Nord)
        beq .has_shutt
        cmp #$3B                        ; Salle 0x3B : Volet Nord
        beq .has_shutt
        cmp #$3C                        ; Salle 0x3C : Volet Nord
        beq .has_shutt
        cmp #$5C                        ; Salle 0x5C : Volet Est
        beq .has_shutt
        cmp #$5D                        ; Salle 0x5D : Volet Nord
        beq .has_shutt
        clc
        rts

.lvl4_shutters:
        lda current_room_idx
        cmp #$13                        ; Salle 0x13 : Boss Gleeok (Volet Nord)
        beq .has_shutt
        cmp #$40                        ; Salle 0x40 : Volet Est
        beq .has_shutt
        cmp #$31                        ; Salle 0x31 : Volet Nord
        beq .has_shutt
        clc
        rts

.lvl5_shutters:
        lda current_room_idx
        cmp #$24                        ; Salle 0x24 : Boss Digdogger (Volet Ouest)
        beq .has_shutt
        cmp #$56                        ; Salle 0x56 : Volet Nord
        beq .has_shutt
        cmp #$66                        ; Salle 0x66 : Volet Est
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
        bne +
        jmp .lvl1_drops
+       cmp #2
        bne +
        jmp .lvl2_drops
+       cmp #3
        bne +
        jmp .lvl3_drops
+       cmp #4
        bne +
        jmp .lvl4_drops
+       cmp #5
        bne +
        jmp .lvl5_drops
+       cmp #6
        bne +
        jmp .lvl6_drops
+       cmp #7
        bne +
        jmp .lvl7_drops
+       cmp #8
        bne +
        jmp .lvl8_drops
+       cmp #9
        bne +
        jmp .lvl9_drops
+       jmp .check_boss_drop_generic

.ret_heart_69:
        lda #DROP_HEART_CONTAINER
        rts
.ret_compass_69:
        lda #DROP_COMPASS
        rts
.ret_map_69:
        lda #DROP_MAP
        rts
.ret_key_69:
        lda #DROP_KEY
        rts
.ret_book_69:
        lda #DROP_BOOK
        rts

.lvl6_drops:
        lda current_room_idx
        cmp #$1C
        beq .ret_heart_69               ; Boss Gohma Red
        cmp #$28
        beq .ret_compass_69             ; Boussole
        cmp #$7A
        beq .ret_map_69                 ; Carte
        cmp #$19
        beq .ret_key_69
        cmp #$2A
        beq .ret_key_69
        cmp #$49
        beq .ret_key_69
        cmp #$58
        beq .ret_key_69
        cmp #$5A
        beq .ret_key_69
        cmp #$68
        beq .ret_key_69
        lda #DROP_NONE
        rts

.lvl7_drops:
        lda current_room_idx
        cmp #$2A
        beq .ret_heart_69               ; Boss Aquamentus
        cmp #$38
        beq .ret_compass_69             ; Boussole
        cmp #$3A
        beq .ret_map_69                 ; Carte
        cmp #$5C
        beq .ret_key_69
        cmp #$6D
        beq .ret_key_69
        cmp #$78
        beq .ret_key_69
        lda #DROP_NONE
        rts

.lvl8_drops:
        lda current_room_idx
        cmp #$3C
        beq .ret_heart_89               ; Boss Dodongo
        cmp #$4E
        beq .ret_compass_89             ; Boussole
        cmp #$4C
        beq .ret_map_89                 ; Carte
        cmp #$3B
        beq .ret_book_69                ; Livre Magique
        cmp #$5C
        beq .ret_key_89
        cmp #$5E
        beq .ret_key_89
        cmp #$6D
        beq .ret_key_89
        lda #DROP_NONE
        rts

.lvl9_drops:
        lda current_room_idx
        cmp #$42
        beq .ret_heart_89               ; Boss Ganon
        cmp #$34
        beq .ret_compass_89             ; Boussole
        cmp #$65
        beq .ret_map_89                 ; Carte
        cmp #$35
        beq .ret_key_89
        cmp #$56
        beq .ret_key_89
        lda #DROP_NONE
        rts

.ret_heart_89:
        lda #DROP_HEART_CONTAINER
        rts
.ret_compass_89:
        lda #DROP_COMPASS
        rts
.ret_map_89:
        lda #DROP_MAP
        rts
.ret_key_89:
        lda #DROP_KEY
        rts

.lvl1_drops:
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
.ret_raft:
        lda #DROP_RAFT
        rts
.ret_none:
        lda #DROP_NONE
        rts

.lvl2_drops:
        lda current_room_idx
        cmp #$0E
        beq .ret_heart                  ; Boss Dodongo
        cmp #$4F
        beq .ret_boomerang              ; 3x Goriyas Bleus -> Boomerang Magique
        cmp #$5F
        beq .ret_compass                ; Boussole
        cmp #$6F
        beq .ret_map                    ; Carte
        cmp #$3E
        beq .ret_key
        cmp #$4E
        beq .ret_key
        cmp #$2E
        beq .ret_key
        cmp #$5E
        beq .ret_key
        cmp #$6D
        beq .ret_key
        cmp #$1F
        beq .ret_key
        cmp #$6E
        beq .ret_key
        lda #DROP_NONE
        rts

.lvl3_drops:
        lda current_room_idx
        cmp #$4D
        beq .ret_heart                  ; Boss Manhandla
        cmp #$5A
        beq .ret_map                    ; Carte
        cmp #$4C
        beq .ret_compass                ; Boussole
        cmp #$4B
        beq .ret_key
        cmp #$6B
        beq .ret_key
        cmp #$6C
        beq .ret_key
        cmp #$7B
        beq .ret_key
        cmp #$3A
        beq .ret_key
        cmp #$3C
        beq .ret_key
        cmp #$4A
        beq .ret_key
        cmp #$5B
        beq .ret_key
        cmp #$5D
        beq .ret_raft                   ; Radeau (si obtenu en salle)
        lda #DROP_NONE
        rts

.lvl4_drops:
        lda current_room_idx
        cmp #$13
        beq .ret_heart_45               ; Boss Gleeok
        cmp #$10
        beq .ret_compass_45             ; Boussole
        cmp #$32
        beq .ret_map_45                 ; Carte
        cmp #$70
        beq .ret_key_45
        cmp #$41
        beq .ret_key_45
        cmp #$30
        beq .ret_key_45
        cmp #$21
        beq .ret_key_45
        lda #DROP_NONE
        rts

.ret_key_45:
        lda #DROP_KEY
        rts
.ret_compass_45:
        lda #DROP_COMPASS
        rts
.ret_map_45:
        lda #DROP_MAP
        rts
.ret_heart_45:
        lda #DROP_HEART_CONTAINER
        rts

.lvl5_drops:
        lda current_room_idx
        cmp #$24
        beq .ret_heart_45               ; Boss Digdogger
        cmp #$77
        beq .ret_compass_45             ; Boussole
        cmp #$15
        beq .ret_map_45                 ; Carte
        cmp #$67
        beq .ret_key_45
        cmp #$55
        beq .ret_key_45
        cmp #$47
        beq .ret_key_45
        cmp #$37
        beq .ret_key_45
        cmp #$16
        beq .ret_key_45
        lda #DROP_NONE
        rts

.check_boss_drop_generic:
        ldx current_dungeon_level
        dex
        cpx #9
        bcs +
        lda dungeon_boss_rooms,x
        cmp current_room_idx
        bne +
        lda #DROP_HEART_CONTAINER
        rts
+       lda #DROP_NONE
        rts

; ---------------------------------------------------------------------------
; dungeon_on_room_cleared_doors : ouvre les portes connexes des volets spéciaux
; ---------------------------------------------------------------------------
dungeon_on_room_cleared_doors:
        lda current_dungeon_level
        cmp #1
        bne +
        jmp .lvl1_cleared_doors
+       cmp #2
        bne +
        jmp .lvl2_cleared_doors
+       cmp #3
        bne +
        jmp .lvl3_cleared_doors
+       cmp #4
        bne +
        jmp .lvl4_cleared_doors
+       cmp #5
        bne +
        jmp .lvl5_cleared_doors
+       cmp #6
        bne +
        jmp .lvl6_cleared_doors
+       cmp #7
        bne +
        jmp .lvl7_cleared_doors
+       cmp #8
        bne +
        jmp .lvl8_cleared_doors
+       cmp #9
        bne +
        jmp .lvl9_cleared_doors
+       rts

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

.lvl2_cleared_doors:
        lda current_room_idx
        cmp #$0E                        ; Boss Dodongo
        bne +
        ldx #$0E
        lda dungeon_room_state,x
        ora #DUNG_DOOR_W_OPEN
        sta dungeon_room_state,x
        ldx #$0D                        ; Salle Triforce N2
        lda dungeon_room_state,x
        ora #DUNG_DOOR_E_OPEN
        sta dungeon_room_state,x
        rts

+       cmp #$1E
        bne +
        ldx #$1E
        lda dungeon_room_state,x
        ora #(DUNG_DOOR_N_OPEN | DUNG_DOOR_S_OPEN)
        sta dungeon_room_state,x
        ldx #$0E
        lda dungeon_room_state,x
        ora #DUNG_DOOR_S_OPEN
        sta dungeon_room_state,x
        ldx #$2E
        lda dungeon_room_state,x
        ora #DUNG_DOOR_N_OPEN
        sta dungeon_room_state,x
        rts

+       cmp #$4E
        bne +
        ldx #$4E
        lda dungeon_room_state,x
        ora #DUNG_DOOR_S_OPEN
        sta dungeon_room_state,x
        ldx #$5E
        lda dungeon_room_state,x
        ora #DUNG_DOOR_N_OPEN
        sta dungeon_room_state,x
        rts

+       cmp #$6D
        bne .done_d2_doors
        ldx #$6D
        lda dungeon_room_state,x
        ora #DUNG_DOOR_W_OPEN
        sta dungeon_room_state,x
.done_d2_doors:
        rts

.lvl3_cleared_doors:
        lda current_room_idx
        cmp #$4D                        ; Boss Manhandla
        bne +
        ldx #$4D
        lda dungeon_room_state,x
        ora #DUNG_DOOR_N_OPEN
        sta dungeon_room_state,x
        ldx #$3D                        ; Salle Triforce N3
        lda dungeon_room_state,x
        ora #DUNG_DOOR_S_OPEN
        sta dungeon_room_state,x
        rts

+       cmp #$3B
        bne +
        ldx #$3B
        lda dungeon_room_state,x
        ora #DUNG_DOOR_N_OPEN
        sta dungeon_room_state,x
        rts

+       cmp #$3C
        bne +
        ldx #$3C
        lda dungeon_room_state,x
        ora #DUNG_DOOR_N_OPEN
        sta dungeon_room_state,x
        rts

+       cmp #$5C
        bne +
        ldx #$5C
        lda dungeon_room_state,x
        ora #DUNG_DOOR_E_OPEN
        sta dungeon_room_state,x
        ldx #$5D
        lda dungeon_room_state,x
        ora #DUNG_DOOR_W_OPEN
        sta dungeon_room_state,x
        rts

+       cmp #$5D
        bne .done_d3_doors
        ldx #$5D
        lda dungeon_room_state,x
        ora #DUNG_DOOR_N_OPEN
        sta dungeon_room_state,x
        ldx #$4D
        lda dungeon_room_state,x
        ora #DUNG_DOOR_S_OPEN
        sta dungeon_room_state,x
.done_d3_doors:
        rts

.lvl4_cleared_doors:
        lda current_room_idx
        cmp #$13                        ; Boss Gleeok
        bne +
        ldx #$13
        lda dungeon_room_state,x
        ora #DUNG_DOOR_N_OPEN
        sta dungeon_room_state,x
        ldx #$03                        ; Salle Triforce N4
        lda dungeon_room_state,x
        ora #DUNG_DOOR_S_OPEN
        sta dungeon_room_state,x
        rts
+       cmp #$40
        bne +
        ldx #$40
        lda dungeon_room_state,x
        ora #DUNG_DOOR_E_OPEN
        sta dungeon_room_state,x
        ldx #$41
        lda dungeon_room_state,x
        ora #DUNG_DOOR_W_OPEN
        sta dungeon_room_state,x
        rts
+       cmp #$31
        bne .done_d4_doors
        ldx #$31
        lda dungeon_room_state,x
        ora #DUNG_DOOR_N_OPEN
        sta dungeon_room_state,x
        ldx #$21
        lda dungeon_room_state,x
        ora #DUNG_DOOR_S_OPEN
        sta dungeon_room_state,x
.done_d4_doors:
        rts

.lvl5_cleared_doors:
        lda current_room_idx
        cmp #$24                        ; Boss Digdogger
        bne +
        ldx #$24
        lda dungeon_room_state,x
        ora #DUNG_DOOR_W_OPEN
        sta dungeon_room_state,x
        ldx #$23                        ; Salle Triforce N5
        lda dungeon_room_state,x
        ora #DUNG_DOOR_E_OPEN
        sta dungeon_room_state,x
        rts
+       cmp #$56
        bne +
        ldx #$56
        lda dungeon_room_state,x
        ora #DUNG_DOOR_N_OPEN
        sta dungeon_room_state,x
        ldx #$46
        lda dungeon_room_state,x
        ora #DUNG_DOOR_S_OPEN
        sta dungeon_room_state,x
        rts
+       cmp #$66
        bne .done_d5_doors
        ldx #$66
        lda dungeon_room_state,x
        ora #DUNG_DOOR_E_OPEN
        sta dungeon_room_state,x
        ldx #$67
        lda dungeon_room_state,x
        ora #DUNG_DOOR_W_OPEN
        sta dungeon_room_state,x
.done_d5_doors:
        rts

.lvl6_cleared_doors:
        lda current_room_idx
        cmp #$1C                        ; Boss Gohma Red
        bne .done_d6_doors
        ldx #$1C
        lda dungeon_room_state,x
        ora #DUNG_DOOR_N_OPEN
        sta dungeon_room_state,x
        ldx #$0C                        ; Salle Triforce N6
        lda dungeon_room_state,x
        ora #DUNG_DOOR_S_OPEN
        sta dungeon_room_state,x
.done_d6_doors:
        rts

.lvl7_cleared_doors:
        lda current_room_idx
        cmp #$2A                        ; Boss Aquamentus
        bne .done_d7_doors
        ldx #$2A
        lda dungeon_room_state,x
        ora #DUNG_DOOR_E_OPEN
        sta dungeon_room_state,x
        ldx #$2B                        ; Salle Triforce N7
        lda dungeon_room_state,x
        ora #DUNG_DOOR_W_OPEN
        sta dungeon_room_state,x
.done_d7_doors:
        rts

.lvl8_cleared_doors:
        lda current_room_idx
        cmp #$3C                        ; Boss Dodongo
        bne .done_d8_doors
        ldx #$3C
        lda dungeon_room_state,x
        ora #DUNG_DOOR_N_OPEN
        sta dungeon_room_state,x
        ldx #$2C                        ; Salle Triforce N8
        lda dungeon_room_state,x
        ora #DUNG_DOOR_S_OPEN
        sta dungeon_room_state,x
.done_d8_doors:
        rts

.lvl9_cleared_doors:
        lda current_room_idx
        cmp #$42                        ; Boss Ganon
        bne .done_d9_doors
        ldx #$42
        lda dungeon_room_state,x
        ora #DUNG_DOOR_N_OPEN
        sta dungeon_room_state,x
        ldx #$32                        ; Salle Princesse Zelda N9
        lda dungeon_room_state,x
        ora #DUNG_DOOR_S_OPEN
        sta dungeon_room_state,x
.done_d9_doors:
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
        lda #SPR_COMMON_ITEM_GET
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
        ; 3. Bloc poussable : Link doit TOUCHER un bloc et le pousser sans interruption
        ;    pendant PUSH_FRAMES images (résistance). Le bloc tremble pendant l'effort.
        lda dungeon_block_pushed
        bne .check_drop_pickup

        lda joy
        and #%00001111
        beq .reset_push_timer

        ; Vérifie si Link est en contact avec un bloc poussable dans le sens où il pousse
        jsr check_link_pushing_block
        bcc .reset_push_timer
        inc dungeon_push_timer
        lda dungeon_push_timer
        cmp #PUSH_FRAMES
        bcc .push_in_progress

        ; Le bloc cède !
        lda #1
        sta dungeon_block_pushed
        lda #0
        sta dungeon_push_timer
        jsr dungeon_do_push_block
        jsr sound_secret_chime
        jmp .check_drop_pickup

.push_in_progress:
        jsr push_shiver
        jmp .check_drop_pickup

.reset_push_timer:
        lda dungeon_push_timer
        beq .push_timer_zero
        ldy push_block_idx              ; effort interrompu : le bloc retrouve sa couleur
        jsr redraw_single_tile
.push_timer_zero:
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

; ===========================================================================
; BLOCS POUSSABLES (toutes les salles de donjon)
;
; Un bloc ne bouge que si Link le TOUCHE et le pousse sans interruption pendant
; PUSH_FRAMES images, dans un sens autorisé et vers une case libre. Le bloc
; tremble pendant l'effort. Aucune poussée ne peut donc sceller un passage.
; ===========================================================================
PUSH_FRAMES             = 60            ; ~1,2 s de poussée continue (50 Hz)
PUSH_FX_STAIRS          = 0             ; salle 0x22 : révèle l'escalier du Bow
PUSH_FX_HERMIT          = 1             ; salle 0x42 : ouvre le passage vers l'ermite
PUSH_ENTRY_GENERIC      = $ff           ; bloc d'une salle à volets fermés : ouvre les volets

dungeon_push_entry:     !byte 0
push_block_idx:         !byte 0         ; index (ty*20+tx) du bloc touché
push_dest_idx:          !byte 0
push_pdx:               !byte 0
push_pdy:               !byte 0

; Table : salle, index du bloc, sens autorisés (bit = 1<<DIR : bas, haut, gauche, droite), effet
push_tbl:
        !byte $22, 88, %0011, PUSH_FX_STAIRS    ; bloc gauche du losange : vers le haut ou le bas
        !byte $42, 89, %0100, PUSH_FX_HERMIT    ; bloc du passage de l'ermite : vers la gauche
        !byte $ff

; Déplacement de l'index de tuile selon le sens (bas +20, haut -20, gauche -1, droite +1)
push_delta:             !byte 20, $ec, $ff, 1
push_dirbit:            !byte %0001, %0010, %0100, %1000

; Points testés juste devant Link : ce sont ceux de la prochaine étape de déplacement
; de player.asm (bas, haut, gauche, droite)
push_p1x:               !byte  6,  6,  4, 19
push_p1y:               !byte 18,  3, 10, 10
push_p2x:               !byte 17, 17,  4, 19
push_p2y:               !byte 18,  3, 15, 15

; ---------------------------------------------------------------------------
; push_probe_pt : la tuile au point (player + push_pdx, player + push_pdy) est-elle un bloc ?
; Sortie : Carry = 1 si bloc, Y = index de la tuile
; ---------------------------------------------------------------------------
push_probe_pt:
        clc
        lda player_x
        adc push_pdx
        sta col_x
        lda player_x+1
        adc #0
        sta col_x+1
        clc
        lda player_y
        adc push_pdy
        sta col_y
        jsr get_tile_at_point
        cmp #TILE_DUNG_BLOCK
        beq .ppp_yes
        clc
        rts
.ppp_yes:
        sec
        rts

; ---------------------------------------------------------------------------
; push_find_block : Link touche-t-il un bloc dans son sens de marche ?
; Sortie : Carry = 1 si bloc, Y = index de la tuile du bloc
; ---------------------------------------------------------------------------
push_find_block:
        ldx player_dir
        lda push_p1x,x
        sta push_pdx
        lda push_p1y,x
        sta push_pdy
        jsr push_probe_pt
        bcs .pfb_done
        ldx player_dir
        lda push_p2x,x
        sta push_pdx
        lda push_p2y,x
        sta push_pdy
        jsr push_probe_pt
.pfb_done:
        rts

; ---------------------------------------------------------------------------
; check_link_pushing_block : Link pousse-t-il un bloc qu'il a le droit de déplacer ?
; Sortie : Carry = 1 si oui (dungeon_push_entry et push_block_idx renseignés)
; ---------------------------------------------------------------------------
check_link_pushing_block:
        jsr push_find_block
        bcc .clp_no
        sty push_block_idx

        ; Cherche (salle, bloc) dans la table des blocs poussables
        ldx #0
.clp_scan:
        lda push_tbl,x
        cmp #$ff
        beq .clp_generic
        cmp current_room_idx
        bne .clp_next
        lda push_tbl+1,x
        cmp push_block_idx
        beq .clp_found
.clp_next:
        inx
        inx
        inx
        inx
        jmp .clp_scan

.clp_found:
        ; Sens de poussée autorisé ?
        ldy player_dir
        lda push_dirbit,y
        and push_tbl+2,x
        beq .clp_no
        ; Passage de l'ermite : n'est poussable qu'une fois la salle nettoyée
        lda push_tbl+3,x
        cmp #PUSH_FX_HERMIT
        bne .clp_dest
        ldy current_room_idx
        lda dungeon_room_state,y
        and #DUNG_ROOM_CLEARED
        beq .clp_no
.clp_dest:
        ; La case d'arrivée doit être une dalle libre (jamais de blocage définitif)
        ldy player_dir
        lda push_block_idx
        clc
        adc push_delta,y
        tay
        lda room_buf,y
        cmp #TILE_DUNG_FLOOR
        bne .clp_no
        stx dungeon_push_entry
        sec
        rts

.clp_generic:
        ; Salle ordinaire à volets fermés : Link pousse un bloc vers le haut (ouvre les volets)
        lda dungeon_shutter_closed
        beq .clp_no
        lda player_dir
        cmp #DIR_UP
        bne .clp_no
        lda #PUSH_ENTRY_GENERIC
        sta dungeon_push_entry
        sec
        rts

.clp_no:
        clc
        rts

; ---------------------------------------------------------------------------
; dungeon_do_push_block : déplace le bloc d'une case et applique l'effet
; ---------------------------------------------------------------------------
dungeon_do_push_block:
        lda dungeon_push_entry
        cmp #PUSH_ENTRY_GENERIC
        beq .dpb_generic

        ; L'ancienne case redevient du sol
        ldy push_block_idx
        lda #TILE_DUNG_FLOOR
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile

        ; Le bloc arrive une case plus loin, dans le sens de la poussée
        ldx player_dir
        lda push_block_idx
        clc
        adc push_delta,x
        sta push_dest_idx
        tay
        lda #TILE_DUNG_BLOCK
        sta (ZP_MAP),y
        sta room_buf,y
        jsr redraw_single_tile

        ldx dungeon_push_entry
        lda push_tbl+3,x
        cmp #PUSH_FX_HERMIT
        beq .dpb_hermit

        ; --- Salle 0x22 : l'escalier central apparaît ---
        ldx current_room_idx
        lda dungeon_room_state,x
        ora #DUNG_SECRET_REVEALED
        ldy player_dir
        cpy #DIR_DOWN
        bne +
        ora #DUNG_BLOCK_DOWN
+       sta dungeon_room_state,x
        
        ; --- Salle 0x22 : ne pas afficher les escaliers immédiatement ---
        ; Le bloc doit être poussé correctement avant que l'escalier apparaisse
        ; On ne redessine pas ici l'escalier pour attendre la poussée correcte
        
        ldx dungeon_push_entry
        lda push_tbl+3,x
        cmp #PUSH_FX_HERMIT
        beq .dpb_hermit

        rts

.dpb_hermit:
        ; --- Salle 0x42 : le volet Ouest s'ouvre vers l'ermite (0x41) ---
        ldx #$42
        lda dungeon_room_state,x
        ora #(DUNG_SECRET_REVEALED | DUNG_DOOR_W_OPEN)
        sta dungeon_room_state,x
        ldx #$41
        lda dungeon_room_state,x
        ora #DUNG_DOOR_E_OPEN
        sta dungeon_room_state,x
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
        rts

.dpb_generic:
        lda dungeon_shutter_closed
        beq +
        lda #0
        sta dungeon_shutter_closed
        jsr dungeon_open_shutters
+       ldy push_block_idx              ; le bloc retrouve sa couleur normale
        jsr redraw_single_tile
        rts

; ---------------------------------------------------------------------------
; push_shiver : le bloc poussé tremble (couleur blanche / normale toutes les 4 images)
; ---------------------------------------------------------------------------
push_shiver:
        lda dungeon_push_timer
        and #3
        bne .psh_done
        lda dungeon_push_timer
        and #4
        beq .psh_normal
        lda #(COL_WHITE | 8)
        ldy push_block_idx
        jmp tile_set_color
.psh_normal:
        ldy push_block_idx
        jmp redraw_single_tile
.psh_done:
        rts

; ---------------------------------------------------------------------------
; tile_set_color : écrit la couleur A dans la Color RAM des 4 caractères de la tuile Y
; (même calcul d'adresse que redraw_single_tile, sans toucher aux caractères)
; ---------------------------------------------------------------------------
tile_set_color:
        sta ZP_BASE
        sty ZP_TMP
        ldx #0
        lda ZP_TMP
.tsc_div:
        cmp #20
        bcc .tsc_done
        sec
        sbc #20
        inx
        jmp .tsc_div
.tsc_done:
        asl                             ; colonne texte = tile_x * 2
        sta ZP_TCOL
        lda tile_y_scr_lo,x
        clc
        adc ZP_TCOL
        sta ZP_COL
        lda tile_y_scr_hi,x
        adc #0
        clc
        adc #>(COLOR_RAM - SCREEN_RAM)
        sta ZP_COL+1
        lda ZP_BASE
        ldy #0
        sta (ZP_COL),y
        iny
        sta (ZP_COL),y
        ldy #40
        sta (ZP_COL),y
        iny
        sta (ZP_COL),y
        rts

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
        ; Conteneur de Cœur du Boss : devant la porte Est, tuile (14,4)
        lda #14
        ldx #4
        jmp dungeon_place_drop

.default_drop_pos:
        lda #10                         ; butin standard : tuile (10,4), validée (jamais dans un bloc)
        ldx #4
        jmp dungeon_place_drop
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
        lda current_dungeon_level
        cmp #2
        bne .set_wood_boom
        lda #2                          ; Boomerang Magique (bleu)
        bne .store_boom
.set_wood_boom:
        lda #1                          ; Boomerang de Bois (jaune)
.store_boom:
        sta player_has_boomerang
        jsr hud_render
        jsr sound_item_fanfare
        lda #0
        sta dungeon_drop_active
        rts

+       cmp #DROP_RAFT
        bne +
        lda #1
        sta player_has_raft
        jsr hud_render
        jsr sound_item_fanfare
        lda #0
        sta dungeon_drop_active
        rts

+       cmp #DROP_LADDER
        bne +
        lda #1
        sta player_has_stepladder
        jsr hud_render
        jsr sound_item_fanfare
        lda #0
        sta dungeon_drop_active
        rts

+       cmp #DROP_WHISTLE
        bne +
        lda #1
        sta player_has_whistle
        jsr hud_render
        jsr sound_item_fanfare
        lda #0
        sta dungeon_drop_active
        rts

+       cmp #DROP_BOOK
        bne +
        lda #1
        sta player_has_book
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
        lda current_dungeon_level
        cmp #1
        bne +
        jmp .chk_bow_inner
+       cmp #3
        bne +
        jmp .chk_raft_pickup
+       cmp #4
        bne +
        jmp .chk_ladder_pickup
+       cmp #5
        bne +
        jmp .chk_whistle_pickup
+       cmp #6
        beq .chk_wand_pickup
        cmp #7
        beq .chk_candle_pickup
        cmp #8
        beq .chk_magic_key_pickup
        cmp #9
        bne +
        jmp .chk_l9_cellar_pickup
+       rts

.chk_wand_pickup:
        ; --- Donjon 6 : Baguette Magique (salle 0x08) ---
        ldx #$08
        lda dungeon_room_state,x
        and #DUNG_ITEM_COLLECTED
        bne +
        lda player_x
        cmp #172
        bcc +
        cmp #208
        bcs +
        lda #1
        sta player_has_wand
        ldx #$08
        lda dungeon_room_state,x
        ora #DUNG_ITEM_COLLECTED
        sta dungeon_room_state,x
        lda #80
        sta cellar_pickup_timer
        jsr sound_item_fanfare
        jsr hud_render
+       rts

.chk_candle_pickup:
        ; --- Donjon 7 : Bougie Rouge (salle 0x4A) ---
        ldx #$4A
        lda dungeon_room_state,x
        and #DUNG_ITEM_COLLECTED
        bne +
        lda player_x
        cmp #172
        bcc +
        cmp #208
        bcs +
        lda #2                          ; Bougie Rouge (utilisations illimitées)
        sta player_has_candle
        ldx #$4A
        lda dungeon_room_state,x
        ora #DUNG_ITEM_COLLECTED
        sta dungeon_room_state,x
        lda #80
        sta cellar_pickup_timer
        jsr sound_item_fanfare
        jsr hud_render
+       rts

.chk_magic_key_pickup:
        ; --- Donjon 8 : Clé Magique (salle 0x6F) ---
        ldx #$6F
        lda dungeon_room_state,x
        and #DUNG_ITEM_COLLECTED
        bne +
        lda player_x
        cmp #172
        bcc +
        cmp #208
        bcs +
        lda #1
        sta player_has_magic_key
        ldx #$6F
        lda dungeon_room_state,x
        ora #DUNG_ITEM_COLLECTED
        sta dungeon_room_state,x
        lda #80
        sta cellar_pickup_timer
        jsr sound_item_fanfare
        jsr hud_render
+       rts

.chk_l9_cellar_pickup:
        ; --- Donjon 9 : Anneau Rouge (0x23) ou Flèches d'Argent (0x45) ---
        lda current_room_idx
        cmp #$23
        bne .chk_l9_silver
        ldx #$23
        lda dungeon_room_state,x
        and #DUNG_ITEM_COLLECTED
        bne +
        lda player_x
        cmp #172
        bcc +
        cmp #208
        bcs +
        lda #2                          ; Anneau Rouge (dégâts divisés par 4)
        sta player_has_blue_ring
        ldx #$23
        lda dungeon_room_state,x
        ora #DUNG_ITEM_COLLECTED
        sta dungeon_room_state,x
        lda #80
        sta cellar_pickup_timer
        jsr sound_item_fanfare
        jsr hud_render
+       rts

.chk_l9_silver:
        ldx #$45
        lda dungeon_room_state,x
        and #DUNG_ITEM_COLLECTED
        bne +
        lda player_x
        cmp #172
        bcc +
        cmp #208
        bcs +
        lda #2                          ; Flèches d'Argent (Silver Arrows)
        sta player_has_arrows
        ldx #$45
        lda dungeon_room_state,x
        ora #DUNG_ITEM_COLLECTED
        sta dungeon_room_state,x
        lda #80
        sta cellar_pickup_timer
        jsr sound_item_fanfare
        jsr hud_render
+       rts

.chk_bow_inner:
        ; --- Donjon 1 : Arc (salle 0x22) ---
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

.chk_raft_pickup:
        ; --- Donjon 3 : Radeau (salle 0x6A) ---
        ldx #$6A
        lda dungeon_room_state,x
        and #DUNG_ITEM_COLLECTED
        bne +
        lda player_x
        cmp #172
        bcc +
        cmp #208
        bcs +
        lda #1
        sta player_has_raft
        ldx #$6A
        lda dungeon_room_state,x
        ora #DUNG_ITEM_COLLECTED
        sta dungeon_room_state,x
        lda #80
        sta cellar_pickup_timer
        jsr sound_item_fanfare
        jsr hud_render
+       rts

.chk_ladder_pickup:
        ; --- Donjon 4 : Échelle (salle 0x04) ---
        ldx #$04
        lda dungeon_room_state,x
        and #DUNG_ITEM_COLLECTED
        bne +
        lda player_x
        cmp #172
        bcc +
        cmp #208
        bcs +
        lda #1
        sta player_has_stepladder
        ldx #$04
        lda dungeon_room_state,x
        ora #DUNG_ITEM_COLLECTED
        sta dungeon_room_state,x
        lda #80
        sta cellar_pickup_timer
        jsr sound_item_fanfare
        jsr hud_render
+       rts

.chk_whistle_pickup:
        ; --- Donjon 5 : Flûte (salle 0x36) ---
        ldx #$36
        lda dungeon_room_state,x
        and #DUNG_ITEM_COLLECTED
        bne +
        lda player_x
        cmp #172
        bcc +
        cmp #208
        bcs +
        lda #1
        sta player_has_whistle
        ldx #$36
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
        bne +
        jmp .cellar_normal_spr
+       lda #SPR_COMMON_ITEM_GET
        sta SPRITE_PTR0

        ; Sprite 1 : Objet brandi au-dessus de la tête
        lda current_dungeon_level
        cmp #3
        bne +
        jmp .brandish_raft
+       cmp #4
        bne +
        jmp .brandish_ladder
+       cmp #5
        bne +
        jmp .brandish_whistle
+       cmp #6
        beq .brandish_wand
        cmp #7
        beq .brandish_candle
        cmp #8
        beq .brandish_magic_key
        cmp #9
        beq .brandish_l9
        lda #(sprite_link_item_bow / 64)
        sta SPRITE_PTR1
        lda #COL_GREEN
        sta VIC_SPRITE_COL1
        jmp .brandish_pos

.brandish_wand:
        lda #(sprite_link_item_wand / 64)
        sta SPRITE_PTR1
        lda #COL_CYAN
        sta VIC_SPRITE_COL1
        jmp .brandish_pos

.brandish_candle:
        lda #(sprite_link_item_potion / 64)
        sta SPRITE_PTR1
        lda #COL_RED
        sta VIC_SPRITE_COL1
        jmp .brandish_pos

.brandish_magic_key:
        lda #(sprite_link_item_key / 64)
        sta SPRITE_PTR1
        lda #COL_YELLOW
        sta VIC_SPRITE_COL1
        jmp .brandish_pos

.brandish_l9:
        lda current_room_idx
        cmp #$23
        bne .brandish_l9_silver
        lda #(sprite_link_item_ring / 64)
        sta SPRITE_PTR1
        lda #COL_RED
        sta VIC_SPRITE_COL1
        jmp .brandish_pos
.brandish_l9_silver:
        lda #(sprite_link_item_bow / 64)
        sta SPRITE_PTR1
        lda #COL_WHITE
        sta VIC_SPRITE_COL1
        jmp .brandish_pos

.brandish_ladder:
        lda #(sprite_link_item_shield / 64)
        sta SPRITE_PTR1
        lda #COL_CYAN
        sta VIC_SPRITE_COL1
        jmp .brandish_pos

.brandish_whistle:
        lda #(sprite_link_item_whistle / 64)
        sta SPRITE_PTR1
        lda #COL_YELLOW
        sta VIC_SPRITE_COL1
        jmp .brandish_pos

.brandish_raft:
        lda #(sprite_link_item_food / 64)
        sta SPRITE_PTR1
        lda #COL_BROWN
        sta VIC_SPRITE_COL1

.brandish_pos:
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

.no_bow_pedestal_top:
        lda #%00000001
        sta VIC_SPRITE_EN
        rts

.draw_bow_pedestal:
        lda current_dungeon_level
        cmp #3
        bne +
        jmp .draw_raft_pedestal
+       cmp #4
        bne +
        jmp .draw_ladder_pedestal
+       cmp #5
        bne +
        jmp .draw_whistle_pedestal
+       cmp #6
        beq .draw_wand_pedestal
        cmp #7
        beq .draw_candle_pedestal
        cmp #8
        beq .draw_magic_key_pedestal
        cmp #9
        beq .draw_l9_pedestal

        ldx #$22
        lda dungeon_room_state,x
        and #DUNG_ITEM_COLLECTED
        bne .no_bow_pedestal_top
        lda #(sprite_link_item_bow / 64)
        sta SPRITE_PTR1
        lda #COL_GREEN
        sta VIC_SPRITE_COL1
        jmp .place_pedestal_spr

.draw_wand_pedestal:
        ldx #$08
        lda dungeon_room_state,x
        and #DUNG_ITEM_COLLECTED
        bne .no_bow_pedestal_top
        lda #(sprite_link_item_wand / 64)
        sta SPRITE_PTR1
        lda #COL_CYAN
        sta VIC_SPRITE_COL1
        jmp .place_pedestal_spr

.draw_candle_pedestal:
        ldx #$4A
        lda dungeon_room_state,x
        and #DUNG_ITEM_COLLECTED
        bne .no_bow_pedestal_top
        lda #(sprite_link_item_potion / 64)
        sta SPRITE_PTR1
        lda #COL_RED
        sta VIC_SPRITE_COL1
        jmp .place_pedestal_spr

.draw_magic_key_pedestal:
        ldx #$6F
        lda dungeon_room_state,x
        and #DUNG_ITEM_COLLECTED
        bne .no_bow_pedestal_top
        lda #(sprite_link_item_key / 64)
        sta SPRITE_PTR1
        lda #COL_YELLOW
        sta VIC_SPRITE_COL1
        jmp .place_pedestal_spr

.draw_l9_pedestal:
        lda current_room_idx
        cmp #$23
        bne .draw_l9_silver_pedestal
        ldx #$23
        lda dungeon_room_state,x
        and #DUNG_ITEM_COLLECTED
        bne .no_bow_pedestal
        lda #(sprite_link_item_ring / 64)
        sta SPRITE_PTR1
        lda #COL_RED
        sta VIC_SPRITE_COL1
        jmp .place_pedestal_spr

.draw_l9_silver_pedestal:
        ldx #$45
        lda dungeon_room_state,x
        and #DUNG_ITEM_COLLECTED
        bne .no_bow_pedestal
        lda #(sprite_link_item_bow / 64)
        sta SPRITE_PTR1
        lda #COL_WHITE
        sta VIC_SPRITE_COL1
        jmp .place_pedestal_spr

.draw_ladder_pedestal:
        ldx #$04
        lda dungeon_room_state,x
        and #DUNG_ITEM_COLLECTED
        bne .no_bow_pedestal
        lda #(sprite_link_item_shield / 64)
        sta SPRITE_PTR1
        lda #COL_CYAN
        sta VIC_SPRITE_COL1
        jmp .place_pedestal_spr

.draw_whistle_pedestal:
        ldx #$36
        lda dungeon_room_state,x
        and #DUNG_ITEM_COLLECTED
        bne .no_bow_pedestal
        lda #(sprite_link_item_whistle / 64)
        sta SPRITE_PTR1
        lda #COL_YELLOW
        sta VIC_SPRITE_COL1
        jmp .place_pedestal_spr

.draw_raft_pedestal:
        ldx #$6A
        lda dungeon_room_state,x
        and #DUNG_ITEM_COLLECTED
        bne .no_bow_pedestal
        lda #(sprite_link_item_food / 64)
        sta SPRITE_PTR1
        lda #COL_BROWN
        sta VIC_SPRITE_COL1

.place_pedestal_spr:
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
        lda current_dungeon_level
        cmp #1
        beq .exit_d1
        lda #216
        sta player_x
        lda #0
        sta player_x+1
        lda #134
        sta player_y
        lda #DIR_LEFT
        sta player_dir
        jmp .finish_exit

.exit_d1:
        lda #152
        sta player_x
        lda #0
        sta player_x+1
        lda #143
        sta player_y
        lda #DIR_LEFT
        sta player_dir

.finish_exit:
        jsr copy_map_charset
        jsr load_room
        jsr dungeon_apply_room_state_active
        jsr enemies_room_init
        jmp hud_render


