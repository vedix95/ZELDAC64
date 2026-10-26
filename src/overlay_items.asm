; ===========================================================================
; overlay_items.asm : Overlay Cartouche pour les logiques d'objets complexes
; Banque 29 (CART_BANK_OVL_ITEMS), chargée à la demande à $A000 (RAM sous BASIC)
; Gère :
;   - Flûte (Whistle) : rétrécissement de Digdogger, assèchement de lac & tornade
;   - Bougie (Candle) : détection du brûlage des arbres secrets Overworld
;   - Bracelet de Force (Bracelet) : déplacement du rocher escargot en D-4
;   - Bombes secrètes : détection des parois fissurables Overworld
;   - Radeau (Raft) : vérification des pontons marins officiels
; ===========================================================================
!cpu 6510
!source "src/c64.inc"
!source "src/cart_defs.inc"
!source "build/resident_symbols.inc"
!source "build/sprite_ptrs.inc"

* = OVERLAY_RAM_ADDR ; $A000

; Table de vecteurs d'entrée de l'overlay ($A000..$A00F)
        jmp ovl_item_whistle_exec       ; $A000
        jmp ovl_item_candle_exec        ; $A003
        jmp ovl_item_bracelet_exec      ; $A006
        jmp ovl_item_bomb_secret_exec   ; $A009
        jmp ovl_item_raft_launch        ; $A00C

; ===========================================================================
; 1. FLÛTE MAGIQUE (Whistle)
; ===========================================================================
ovl_item_whistle_exec:
        ; Joue la mélodie de la flûte (synthèse SID)
        jsr sound_flute

        ; Si Digdogger est dans la salle (Niveau 5) : il rétrécit !
        ldx #0
.chk_dig:
        lda en_state,x
        cmp #EN_STATE_DEAD
        beq +
        lda en_type,x
        cmp #TYPE_DIGDOGGER
        bne +
        lda #TYPE_GEL
        sta en_type,x
        lda #2
        sta en_hp,x
        lda #AI_ROAM
        sta en_ai_type,x
        lda #0
        sta en_anim,x
+       inx
        cpx #MAX_ENEMIES
        bcc .chk_dig

        lda current_world_type
        cmp #WORLD_OVERWORLD
        bne .whistle_end

        ; --- Sur l'Overworld ---
        lda current_room_idx
        cmp #66                         ; Salle 66 (C-5) : Assèche l'étang du Donjon 7 !
        bne .whistle_warp

        ; Remplacement des tuiles d'eau par de l'herbe et apparition de la grotte du Donjon 7
        ldy #199
-       lda room_buf,y
        cmp #TILE_WATER
        bne +
        lda #TILE_GRASS
        sta room_buf,y
+       dey
        bpl -

        ; Place l'entrée du Donjon 7 au centre de l'ancien étang (ligne 4, col 10 -> index 90)
        lda #TILE_CAVE
        sta room_buf+90

        lda #<room_buf
        sta ZP_MAP
        lda #>room_buf
        sta ZP_MAP+1
        jsr draw_map
        jsr sound_secret_chime
        jsr record_room_secret_opened
        rts

.whistle_warp:
        ; Téléportation magique par la tornade vers l'entrée d'un donjon !
        lda #55                         ; Entrée Niveau 1 (H-4)
        sta current_room_idx
        lda #7
        sta current_room_x
        lda #3
        sta current_room_y
        lda #180
        sta player_x
        lda #0
        sta player_x+1
        lda #150
        sta player_y
        jsr load_room
        jsr hud_init
        jsr player_draw
        jsr enemies_init
        jsr enemies_prep_multiplexer
        jsr sound_secret_chime
.whistle_end:
        rts

; ===========================================================================
; 2. BOUGIE BLEUE / ROUGE (Candle)
; ===========================================================================
ovl_item_candle_exec:
        lda current_world_type
        bne .candle_done

        ; Tester si la flamme touche un arbre secret
        lda item_x
        sta col_x
        lda item_x+1
        sta col_x+1
        lda item_y
        sta col_y
        jsr get_tile_at_point           ; A = tile_id, Y = offset dans room_buf
        cmp #TILE_TREE
        bne .candle_done

        lda current_room_idx
        cmp #107                        ; Salle 107 (L-7) : Cœur dans l'arbre !
        beq .burn_tree_secret
        cmp #15                         ; Salle 15 (P-1) : Grotte indice
        beq .burn_tree_secret
        cmp #108                        ; Salle 108 (M-7) : Arbre Donjon 8
        beq .burn_tree_secret
        cmp #109                        ; Salle 109 (N-7) : Arbre Donjon 8
        beq .burn_tree_secret
        cmp #82                         ; Salle 82 (C-6) : Moblin secret
        beq .burn_tree_secret
        cmp #111                        ; Salle 111 (P-7) : Boutique
        beq .burn_tree_secret
.candle_done:
        clc
        rts

.burn_tree_secret:
        lda #TILE_CAVE
        sta room_buf,y
        jsr redraw_single_tile
        jsr sound_secret
        jsr record_room_secret_opened
        lda #ITEM_NONE
        sta item_active
        sec
        rts

; ===========================================================================
; 3. BRACELET DE FORCE (Power Bracelet)
; ===========================================================================
ovl_item_bracelet_exec:
        lda current_world_type
        bne .ow_special_done
        lda player_has_bracelet
        beq .ow_special_done
        lda player_dir
        cmp #DIR_UP
        bne .ow_special_done

        ; Teste si Link pousse vers le haut contre un rocher (TILE_ROCK)
        lda player_x
        clc
        adc #12                         ; Centre horizontal de Link
        sta col_x
        lda player_x+1
        adc #0
        sta col_x+1
        lda player_y
        sec
        sbc #4                          ; Point de contact juste au-dessus de Link
        sta col_y
        jsr get_tile_at_point           ; Y = index dans room_buf (0..199), A = tile_id
        cmp #TILE_ROCK
        bne .ow_special_done

        ; Salles overworld avec secret de rocher poussable :
        ; 51 (D-4), 35 (D-3), 73 (J-5), 121 (J-8), 29 (N-2)
        lda current_room_idx
        cmp #51
        beq .push_rock_found
        cmp #35
        beq .push_rock_found
        cmp #73
        beq .push_rock_found
        cmp #121
        beq .push_rock_found
        cmp #29
        beq .push_rock_found
        rts

.push_rock_found:
        lda room_buf,y
        cmp #TILE_CAVE
        beq .ow_special_done
        lda #TILE_CAVE
        sta room_buf,y
        jsr redraw_single_tile
        jsr sound_secret
        jsr record_room_secret_opened
.ow_special_done:
        rts

; ===========================================================================
; 4. BOMBES SECRÈTES OVERWORLD
; ===========================================================================
ovl_item_bomb_secret_exec:
        lda current_world_type
        beq +
        rts
+
        ; Tester 5 points autour du centre de la bombe
        ; 1. Centre
        lda item_x
        sta col_x
        lda item_x+1
        sta col_x+1
        lda item_y
        sta col_y
        jsr .test_bomb_point
        bcs .found_secret

        ; 2. Nord (item_y - 14)
        lda item_x
        sta col_x
        lda item_x+1
        sta col_x+1
        sec
        lda item_y
        sbc #14
        sta col_y
        jsr .test_bomb_point
        bcs .found_secret

        ; 3. Sud (item_y + 14)
        lda item_x
        sta col_x
        lda item_x+1
        sta col_x+1
        clc
        lda item_y
        adc #14
        sta col_y
        jsr .test_bomb_point
        bcs .found_secret

        ; 4. Ouest (item_x - 14)
        sec
        lda item_x
        sbc #14
        sta col_x
        lda item_x+1
        sbc #0
        sta col_x+1
        lda item_y
        sta col_y
        jsr .test_bomb_point
        bcs .found_secret

        ; 5. Est (item_x + 14)
        clc
        lda item_x
        adc #14
        sta col_x
        lda item_x+1
        adc #0
        sta col_x+1
        lda item_y
        sta col_y
        jsr .test_bomb_point
        bcc .bc_done

.found_secret:
        ; Y contient l'offset de la tuile dans room_buf (0..199)
        lda #TILE_CAVE
        sta room_buf,y
        jsr redraw_single_tile
        jsr sound_secret
        jsr record_room_secret_opened
.bc_done:
        rts

.test_bomb_point:
        jsr get_tile_at_point
        cmp #TILE_WALL_SECRET_B
        bne .check_b_room
        sec
        rts

.check_b_room:
        cmp #TILE_WALL
        bne .not_b_sec
        lda current_room_idx
        cmp #14                         ; Salle 14 (O-1, Grotte de jeu)
        beq .is_b_room
        cmp #33                         ; Salle 33 (B-3, Grotte potion)
        beq .is_b_room
        cmp #37                         ; Salle 37 (F-3, Grotte marchande)
        beq .is_b_room
        cmp #50                         ; Salle 50 (C-4, Grotte arme)
        beq .is_b_room
        cmp #67                         ; Salle 67 (D-5, Moblin +30)
        beq .is_b_room
        cmp #73                         ; Salle 73 (J-5, Moblin +100)
        beq .is_b_room
        cmp #86                         ; Salle 86 (G-6, Moblin +30)
        beq .is_b_room
        cmp #98                         ; Salle 98 (C-7, Moblin +30)
        beq .is_b_room
        cmp #100                        ; Salle 100 (E-7, Anneau Bleu secret)
        beq .is_b_room
        cmp #114                        ; Salle 114 (C-8, Moblin +30)
        beq .is_b_room
        cmp #2                          ; Salle 2 (C-1, Door repair)
        beq .is_b_room
        cmp #61                         ; Salle 61 (N-4, Porte Niveau 4)
        beq .is_b_room
        bne .not_b_sec
.is_b_room:
        cpy #6
        beq .found_b_sec
        cpy #7
        beq .found_b_sec
        cpy #8
        beq .found_b_sec
        cpy #9
        beq .found_b_sec
        cpy #10
        beq .found_b_sec
        cpy #11
        beq .found_b_sec
        cpy #12
        beq .found_b_sec
        cpy #13
        beq .found_b_sec
        bne .not_b_sec
.found_b_sec:
        sec
        rts
.not_b_sec:
        clc
        rts

; ===========================================================================
; 5. RADEAU DE TRANSPORT (Raft launch check)
; ===========================================================================
ovl_item_raft_launch:
        lda player_has_raft
        beq .raft_no
        lda current_world_type
        bne .raft_no

        ldx #3
.chk_dock:
        lda .raft_rooms,x
        cmp current_room_idx
        bne .next_dock
        lda player_dir
        cmp .raft_dirs,x
        beq .launch
.next_dock:
        dex
        bpl .chk_dock
.raft_no:
        clc
        rts

.raft_rooms: !byte 85, 69, 63, 47
.raft_dirs:  !byte DIR_UP, DIR_DOWN, DIR_UP, DIR_DOWN

.launch:
        stx raft_journey_id
        lda #0
        sta raft_state
        lda #STATE_RAFT
        sta game_state
        jsr sound_secret
        sec
        rts
