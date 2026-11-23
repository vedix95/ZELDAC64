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

; Table de vecteurs d'entrée de l'overlay ($A000..$A02C)
        jmp ovl_item_whistle_exec       ; $A000
        jmp ovl_item_candle_exec        ; $A003
        jmp ovl_item_bracelet_exec      ; $A006
        jmp ovl_item_bomb_secret_exec   ; $A009
        jmp ovl_item_raft_launch        ; $A00C
        jmp ovl_enter_cellar            ; $A00F
        jmp ovl_exit_cellar             ; $A012
        jmp ovl_d1_hermit_41            ; $A015
        jmp ovl_gameover_open           ; $A018
        jmp ovl_gameover_update         ; $A01B
        jmp ovl_ending_open             ; $A01E
        jmp ovl_ending_update           ; $A021
        jmp ovl_d9_gate_blocked         ; $A024
        jmp ovl_use_food_exec           ; $A027
        jmp ovl_d7_hungry_goriya_setup  ; $A02A
        jmp ovl_exit_dungeon            ; $A02D
        jmp ovl_spawn_loot              ; $A030
        jmp ovl_curtain_close           ; $A033
        jmp ovl_enter_dungeon           ; $A036
        jmp ovl_gameover_continue       ; $A039
        jmp ovl_update_loot             ; $A03C
        jmp ovl_dungeon_collect_drop    ; $A03F
        jmp ovl_dungeon_bomb_explode    ; $A042
        jmp ovl_open_north_door         ; $A045
        jmp ovl_open_south_door         ; $A048
        jmp ovl_open_west_door          ; $A04B
        jmp ovl_open_east_door          ; $A04E

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
        bne .chk_pols
        lda #TYPE_GEL
        sta en_type,x
        lda #2
        sta en_hp,x
        lda #0
        sta en_anim,x
        jmp +
.chk_pols:
        cmp #TYPE_POLS_VOICE
        bne +
        lda en_state,x
        cmp #EN_STATE_DYING
        beq +
        lda #0
        sta en_hp,x
        lda #EN_STATE_DYING
        sta en_state,x
        lda #16
        sta en_timer,x
        jsr sound_enemy_die
+       inx
        cpx #MAX_ENEMIES
        bcc .chk_dig

        lda current_world_type
        cmp #WORLD_OVERWORLD
        beq +
        rts
+

        ; --- Sur l'Overworld ---
        lda current_room_idx
        cmp #66                         ; Salle 66 (C-5) : Assèche l'étang du Donjon 7 !
        bne .whistle_warp

.whistle_open_d7:
        ; Remplacement des tuiles d'eau par de l'herbe et apparition de la grotte du Donjon 7
        ldy #0
-       lda room_buf,y
        cmp #TILE_WATER
        bne +
        lda #TILE_GRASS
        sta room_buf,y
+       iny
        cpy #200
        bcc -

        ; Place l'entrée au centre de l'étang asséché (ligne 4, col 10 -> index 90)
        lda #TILE_CAVE
        ldy #90
        sta room_buf,y

        lda #<room_buf
        sta ZP_MAP
        lda #>room_buf
        sta ZP_MAP+1
        jsr draw_map
        jsr sound_secret_chime
        jsr record_room_secret_opened
        rts

.whistle_warp:
        ; Téléportation cyclique par la tornade vers les entrées des Donjons 1..8
        ; déjà complétés (ou Donjon 1 par défaut si aucune Triforce obtenue)
        ldx #0                          ; index de départ par défaut (D1)
        ldy #7
.ww_find_cur:
        lda current_room_idx
        cmp .whistle_rooms,y
        beq .ww_start_next
        dey
        bpl .ww_find_cur
        jmp .ww_scan
.ww_start_next:
        tya
        tax
        inx
        cpx #8
        bcc .ww_scan
        ldx #0
.ww_scan:
        lda player_triforce_pieces
        beq .ww_default                 ; Aucun fragment -> Donjon 1 (H-4)
        ldy #8                          ; Max 8 essais cycliques
.ww_loop:
        lda bit_powers,x
        and player_triforce_pieces
        bne .ww_found
        inx
        cpx #8
        bcc +
        ldx #0
+       dey
        bne .ww_loop
.ww_default:
        ldx #0
.ww_found:
        lda .whistle_rooms,x
        sta current_room_idx
        lda .whistle_rx,x
        sta current_room_x
        lda .whistle_ry,x
        sta current_room_y
        lda .whistle_px,x
        sta player_x
        lda #0
        sta player_x+1
        lda .whistle_py,x
        sta player_y
        jsr load_room
        jsr hud_init
        jsr player_draw
        jsr enemies_init
        jsr enemies_prep_multiplexer
        jsr sound_secret_chime
.whistle_end:
        rts

.whistle_rooms: !byte  55,  60, 116,  69,  11,  34,  66, 109
.whistle_rx:    !byte   7,  12,   4,   5,  11,   2,   2,  13
.whistle_ry:    !byte   3,   3,   7,   4,   0,   2,   4,   6
.whistle_px:    !byte 164, 164, 180, 180, 164, 164, 180, 180
.whistle_py:    !byte 158, 158, 158, 158, 158, 158, 190, 110

; ===========================================================================
; 2. BOUGIE BLEUE / ROUGE (Candle)
; ===========================================================================
ovl_item_candle_exec:
        lda current_world_type
        bne .candle_done

        ; Tester si la flamme touche un arbre secret (centre du sprite +8,+8)
        clc
        lda item_x
        adc #8
        sta col_x
        lda item_x+1
        adc #0
        sta col_x+1
        clc
        lda item_y
        adc #8
        sta col_y
        jsr get_tile_at_point           ; A = tile_id, Y = offset dans room_buf
        cmp #TILE_TREE
        bne .candle_done

        lda current_room_idx
        ldx #11
.chk_burn_tbl:
        cmp .burnable_rooms,x
        beq .burn_tree_secret
        dex
        bpl .chk_burn_tbl
.candle_done:
        clc
        rts

.burnable_rooms:
        ; 12 salles Overworld authentiques avec arbres brûlables (incluant D8 en N-7 #109)
        !byte 40, 70, 81, 82, 83, 88, 91, 98, 99, 106, 107, 109

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
; 3. POUSSÉE OVERWORLD UNIFIÉE : ROCHERS (BRACELET) & TOMBES (IDENTIQUE DONJONS)
;    Entrée : Y = index de la tuile (0..199) touchée devant Link
;    - Table stricte ow_push_tbl : seul le rocher/tombe authentique NES bouge
;    - 1 seule poussée par salle (vérification overworld_secrets_opened)
;    - Poussée continue OW_PUSH_FRAMES (60 images = ~1,2 s) avec push_shiver
;    - Glissement réel d'une case (push_delta) + révélation TILE_CAVE dessous
; ===========================================================================
OW_PUSH_FRAMES          = 60
ow_push_cand_idx:       !byte 0
ow_push_tile_type:      !byte 0
ow_push_reveal_off:     !byte 0   ; décalage de l'escalier par rapport au rocher (0 = sous le rocher, 1 = au centre à droite)

; Table : salle, index_tuile, type_tuile, sens_autorisés (%RLUD = bits 3..0), besoin_bracelet, décalage_escalier
; D-3 et J-8 (4 rochers en losange) : poussée Haut/Bas/Gauche (%0111), l'escalier apparaît AU CENTRE du losange (+1 à droite)
; Autres rochers : 4 directions (%1111) ; Tombes : vers le Haut (%0010)
ow_push_tbl:
        !byte   9, 106, TILE_ROCK , %1111, 1, 0   ; J-1 ($09) (6,5)  -> Hint 1
        !byte  17, 110, TILE_ROCK , %1111, 1, 0   ; B-2 ($11) (10,5) -> Hint 1
        !byte  29, 105, TILE_ROCK , %1111, 1, 0   ; N-2 ($1D) (5,5)  -> Warp
        !byte  32, 108, TILE_GRAVE, %0010, 0, 0   ; A-3 ($20) (8,5)  -> Warp (Tombe, Haut)
        !byte  33, 111, TILE_GRAVE, %0010, 0, 0   ; B-3 ($21) (11,5) -> Épée Magique (Tombe, Haut)
        !byte  35, 105, TILE_ROCK , %0111, 1, 1   ; D-3 ($23) (5,5)  -> Warp (escalier au centre 6,5)
        !byte  51,  89, TILE_ROCK , %1111, 1, 0   ; D-4 ($33) (9,4)  -> Potion Shop
        !byte  73, 105, TILE_ROCK , %1111, 1, 0   ; J-5 ($49) (5,5)  -> Warp
        !byte 121, 110, TILE_ROCK , %0111, 1, 1   ; J-8 ($79) (10,5) -> Warp (escalier au centre 11,5)
        !byte $ff

ovl_item_bracelet_exec:
        sty ow_push_cand_idx
        lda current_world_type
        bne .ow_abort_tramp

        ; 1. Bloque si le secret de la salle est déjà ouvert (1 seule poussée)
        lda current_room_idx
        lsr
        lsr
        lsr
        tax
        lda current_room_idx
        and #7
        tay
        lda bit_powers,y
        and overworld_secrets_opened,x
        bne .ow_abort_tramp

        ; 2. Recherche stricte (salle, index_tuile) dans ow_push_tbl
        ldx #0
.ow_pt_scan:
        lda ow_push_tbl,x
        cmp #$ff
        beq .ow_abort_tramp
        cmp current_room_idx
        bne .ow_pt_next
        lda ow_push_tbl+1,x
        cmp ow_push_cand_idx
        beq .ow_pt_found
.ow_pt_next:
        txa
        clc
        adc #6
        tax
        bne .ow_pt_scan
.ow_abort_tramp:
        jmp .ow_push_abort

.ow_pt_found:
        ; 3. Vérifie le type de tuile actuel dans room_buf
        ldy ow_push_cand_idx
        lda ow_push_tbl+2,x
        sta ow_push_tile_type
        lda ow_push_tbl+5,x
        sta ow_push_reveal_off
        lda ow_push_tile_type
        cmp room_buf,y
        bne .ow_abort_tramp

        ; 4. Vérifie le Bracelet de Force si requis
        lda ow_push_tbl+4,x
        beq .ow_pt_dir_chk
        lda player_has_bracelet
        beq .ow_abort_tramp

.ow_pt_dir_chk:
        ; 5. Direction de poussée autorisée ?
        ldy player_dir
        lda push_dirbit,y
        and ow_push_tbl+3,x
        beq .ow_abort_tramp

        ; 6. Case d'arrivée libre (TILE_GRASS) ?
        lda ow_push_cand_idx
        clc
        adc push_delta,y
        sta push_dest_idx
        tay
        lda room_buf,y
        cmp #TILE_GRASS
        bne .ow_abort_tramp

        ; 7. Si changement de tuile poussée en cours de route, restaure l'ancienne
        lda dungeon_push_timer
        beq .ow_pt_set_idx
        lda ow_push_cand_idx
        cmp push_block_idx
        beq .ow_pt_inc
        ldy push_block_idx
        jsr redraw_single_tile
        lda #0
        sta dungeon_push_timer
.ow_pt_set_idx:
        lda ow_push_cand_idx
        sta push_block_idx

.ow_pt_inc:
        inc dungeon_push_timer
        lda dungeon_push_timer
        cmp #OW_PUSH_FRAMES
        bcc .ow_pt_shiver

        ; 8. Le rocher / la tombe cède et glisse d'une case !
        lda #0
        sta dungeon_push_timer

        ; Ancienne case -> Escalier secret (sous le rocher) ou herbe + escalier au centre
        ldy push_block_idx
        lda ow_push_reveal_off
        beq .ow_rv_under
        lda #TILE_GRASS
        sta room_buf,y
        jsr redraw_single_tile
        lda push_block_idx
        clc
        adc ow_push_reveal_off
        tay
.ow_rv_under:
        lda #TILE_CAVE
        sta room_buf,y
        jsr redraw_single_tile

        ; Nouvelle case (+push_delta) -> Rocher ou Tombe déplacé
        ldy push_dest_idx
        lda ow_push_tile_type
        sta room_buf,y
        jsr redraw_single_tile

        jsr sound_secret
        jsr record_room_secret_opened
        rts

.ow_pt_shiver:
        jmp push_shiver

.ow_push_abort:
        lda dungeon_push_timer
        beq .ow_special_done
        ldy push_block_idx
        jsr redraw_single_tile
        lda #0
        sta dungeon_push_timer
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
        ; Les 23 parois secrètes bombables authentiques sont marquées 'B' (TILE_WALL_SECRET_B)
        ; dans assets/world.txt : ouverture exacte et persistance 100% garantie.
        jsr get_tile_at_point
        cmp #TILE_WALL_SECRET_B
        bne .not_b_sec
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

; ===========================================================================
; 6. CELLIERS SOUTERRAINS (ovl_enter_cellar / ovl_exit_cellar — Fix C1 D9 $23)
; ===========================================================================
cellar_ladder_char_l:
        !byte %00100100, %00101010, %00100101, %00100100
        !byte %00100100, %00101010, %00100101, %00100100
cellar_ladder_char_r:
        !byte %00100100, %10101000, %01010100, %00100100
        !byte %00100100, %10101000, %01010100, %00100100

build_cellar_room:
        ldx #0
        lda #TILE_DUNG_WALL_TOP
-       sta room_buf,x
        inx
        cpx #200
        bcc -

        ldy #40
.cellar_row_loop:
        tya
        clc
        adc #3
        tax
        lda #14
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
        cpy #160
        bcc .cellar_row_loop

        lda #TILE_DUNG_WALL_TOP
        sta room_buf+46
        sta room_buf+47
        sta room_buf+48
        sta room_buf+51
        sta room_buf+52
        sta room_buf+53
        sta room_buf+149
        sta room_buf+150
        sta room_buf+151

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

ovl_enter_cellar:
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

        ldx #7
        lda #0
-       sta en_state,x
        dex
        bpl -

        ldx #7
-       lda cellar_ladder_char_l,x
        sta $20e0,x
        sta $20f0,x
        lda cellar_ladder_char_r,x
        sta $20e8,x
        sta $20f8,x
        dex
        bpl -

        lda #COL_BLACK
        sta active_bg_color
        sta VIC_BACKGROUND
        lda #COL_GREY
        sta VIC_BG_MC1
        lda #COL_WHITE
        sta VIC_BG_MC2
        lda #9
        ldy #15
-       sta active_tile_color,y
        dey
        bpl -

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

ovl_exit_cellar:
        lda #STATE_PLAYING
        sta game_state
        lda #0
        sta cellar_pickup_timer
        sta player_x+1
        lda #DIR_LEFT
        sta player_dir

        ; Recharge d'abord la salle du donjon pour valider les tuiles praticables
        jsr copy_map_charset
        jsr load_room
        jsr dungeon_apply_room_state_active

        lda current_dungeon_level
        cmp #1
        beq .exit_d1
        cmp #5
        beq .exit_d5
        cmp #9
        bne .exit_default
        lda current_room_idx
        cmp #$23
        bne .exit_default
        ; Fix C1 : En D9 $23 (Cellier Anneau Rouge), (12,3) est une statue solide !
        ; Les escaliers sont en (14,4) -> placer Link en (15,4) libre (X=264=$0108, Y=146)
        lda #<264
        sta player_x
        lda #>264
        sta player_x+1
        lda #146
        sta player_y
        lda #DIR_RIGHT
        sta player_dir
        jmp .finish_exit

.exit_d5:
        lda #228
        sta player_x
        lda #142
        sta player_y
        jmp .finish_exit

.exit_d1:
        lda #152
        sta player_x
        lda #143
        sta player_y
        jmp .finish_exit

.exit_default:
        lda #216
        sta player_x
        lda #134
        sta player_y

.finish_exit:
        jsr enemies_room_init
        jmp hud_render

; ===========================================================================
; 7. ERMITE DONJON 1 ($41) & GORIYA AFFAMÉ DONJON 7 ($4B) (V1 / M6)
; ===========================================================================
ovl_d1_hermit_41:
        ldx #0
        lda #0
-       sta en_state,x
        inx
        cpx #MAX_ENEMIES
        bcc -

        ldx #0
-       lda txt_hint_d1_1,x
        sta SCREEN_RAM+240+7,x
        lda #COL_WHITE
        sta COLOR_RAM+240+7,x
        inx
        cpx #25
        bne -

        ldx #0
-       lda txt_hint_d1_2,x
        sta SCREEN_RAM+320+13,x
        lda #COL_WHITE
        sta COLOR_RAM+320+13,x
        inx
        cpx #14
        bne -

        lda #(sprite_link_old_man / 64)
        sta SPRITE_PTR3
        lda #COL_RED
        sta VIC_SPRITE_COL3
        lda #160
        sta VIC_SPRITE_X3
        lda #130
        sta VIC_SPRITE_Y3
        jmp .setup_npc_torches

ovl_d7_hungry_goriya_setup:
        ldx #0
        lda #0
-       sta en_state,x
        inx
        cpx #MAX_ENEMIES
        bcc -

        ; Affiche "GRUMBLE, GRUMBLE..." centré ligne 6
        ldx #0
-       lda txt_grumble,x
        sta SCREEN_RAM+240+10,x
        lda #COL_WHITE
        sta COLOR_RAM+240+10,x
        inx
        cpx #19
        bne -

        ; Goriya affamé au centre (Sprite 3)
        lda #SPR_DUNG_GORIYA_DOWN_0
        sta SPRITE_PTR3
        lda #COL_RED
        sta VIC_SPRITE_COL3
        lda #172
        sta VIC_SPRITE_X3
        lda #136
        sta VIC_SPRITE_Y3

.setup_npc_torches:
        lda #(sprite_link_proj_flame_0 / 64)
        sta SPRITE_PTR4
        lda #(sprite_link_proj_flame_1 / 64)
        sta SPRITE_PTR5
        lda #COL_CYAN
        sta VIC_SPRITE_COL4
        sta VIC_SPRITE_COL5
        lda #120
        sta VIC_SPRITE_X4
        lda #224
        sta VIC_SPRITE_X5
        lda #136
        sta VIC_SPRITE_Y4
        sta VIC_SPRITE_Y5
        lda #0
        sta VIC_SPRITE_MSB
        lda #%00111001
        sta VIC_SPRITE_EN
        sta VIC_SPRITE_MC
        rts

txt_hint_d1_1:  !text "EASTMOST PENINSULA IS THE"
txt_hint_d1_2:  !text "   SECRET.    "
txt_grumble:    !text "GRUMBLE, GRUMBLE..."

; ===========================================================================
; 8. UTILISATION DE LA NOURRITURE / APPÂT (ovl_use_food_exec — Fix M6)
; ===========================================================================
ovl_use_food_exec:
        ; En Donjon 7 salle $49 : nourrit le Goriya affamé et ouvre les volets !
        lda current_world_type
        cmp #WORLD_DUNGEON
        bne .food_bait
        lda current_dungeon_level
        cmp #7
        bne .food_bait
        lda current_room_idx
        cmp #$49
        bne .food_bait
        ldx #$49
        lda dungeon_room_state,x
        and #DUNG_SECRET_REVEALED
        bne .food_bait

        ; Consomme la nourriture et libère la salle $4B
        lda #0
        sta player_has_food
        lda dungeon_room_state,x
        ora #(DUNG_SECRET_REVEALED | DUNG_ROOM_CLEARED)
        sta dungeon_room_state,x
        ; Efface les sprites Goriya/torches et redessine la salle proprement
        lda #%00000001
        sta VIC_SPRITE_EN
        jsr load_room
        jsr dungeon_open_shutters
        jsr hud_render
        jsr sound_secret_chime
        rts

.food_bait:
        ; Hors Goriya affamé : joue le son d'appât et étourdit/attire les ennemis actifs
        lda #0
        sta ZP_TMP
        ldx #0
.bait_loop:
        lda en_state,x
        cmp #EN_STATE_WALK
        bne .bait_next
        ldy en_type,x
        lda en_ai_type,y
        cmp #AI_BOSS
        beq .bait_next
        cpy #TYPE_BUBBLE
        beq .bait_next
        cpy #TYPE_TRAP
        beq .bait_next
        lda #EN_STATE_HURT
        sta en_state,x
        lda #120
        sta en_hurt_timer,x
        inc ZP_TMP
.bait_next:
        inx
        cpx #MAX_ENEMIES
        bcc .bait_loop
        ; Ne consomme la viande que si au moins un monstre a été attiré !
        lda ZP_TMP
        beq +
        lda #0
        sta player_has_food
+       jsr sound_food
        rts

; ===========================================================================
; 9. PORTAIL DONJON 9 : REQUIERT LES 8 FRAGMENTS DE TRIFORCE (Fix M3)
; ===========================================================================
ovl_d9_gate_blocked:
        ; Repousse Link sous l'entrée de Spectacle Rock
        lda player_y
        clc
        adc #20
        sta player_y
        lda #DIR_DOWN
        sta player_dir
        jsr sound_shield_block

        ; Affiche la bannière d'avertissement sur la ligne 5 (centrée)
        ldx #0
-       lda txt_d9_gate,x
        sta SCREEN_RAM+200+6,x
        lda #COL_YELLOW
        sta COLOR_RAM+200+6,x
        inx
        cpx #28
        bne -

        ; Maintient le message ~1,4s (70 frames) puis redessine la salle
        lda #70
        sta ZP_TMP
.d9g_wait:
        jsr wait_frame
        dec ZP_TMP
        bne .d9g_wait

        jsr load_room
        jsr hud_render
        rts

txt_d9_gate:    !text "NEED ALL 8 TRIFORCE PIECES! "

; ===========================================================================
; 10. ÉCRAN GAME OVER & CONTINUE (Fix C2 — STATE_GAMEOVER = 8)
; ===========================================================================
ovl_modal_timer: !byte 0

ovl_clear_screen_black:
        lda #0
        sta VIC_SPRITE_EN
        sta VIC_SPRITE_MSB
        sta VIC_SPRITE_EXP_X
        sta VIC_SPRITE_EXP_Y
        sta active_bg_color
        sta VIC_BACKGROUND
        sta VIC_BORDER
        ldx #0
.oc_lp:
        lda #32
        sta SCREEN_RAM,x
        sta SCREEN_RAM+250,x
        sta SCREEN_RAM+500,x
        sta SCREEN_RAM+750,x
        lda #COL_WHITE
        sta COLOR_RAM,x
        sta COLOR_RAM+250,x
        sta COLOR_RAM+500,x
        sta COLOR_RAM+750,x
        inx
        cpx #250
        bne .oc_lp
        rts

ovl_print_line:
        ; ZP_SRC = texte nul-terminé, ZP_DST = SCREEN_RAM+ofs, ZP_TMP = couleur
        ldy #0
-       lda (ZP_SRC),y
        beq +
        sta (ZP_DST),y
        iny
        bne -
+       ; Applique la couleur sur Y caractères
        lda ZP_DST
        sta ZP_MAP
        lda ZP_DST+1
        clc
        adc #($d8 - $04)                ; $0400 -> $D800
        sta ZP_MAP+1
        lda ZP_TMP
        dey
        bmi ++
-       sta (ZP_MAP),y
        dey
        bpl -
++      rts

ovl_gameover_open:
        lda #STATE_GAMEOVER
        sta game_state
        jsr music_stop
        lda hud_cur_hearts
        bne +
        jsr go_play_death_anim
+       jsr ovl_clear_screen_black
        lda #35
        sta ovl_modal_timer

        ; Titre "GAME OVER" en rouge (ligne 8, col 15)
        lda #<txt_go_title
        sta ZP_SRC
        lda #>txt_go_title
        sta ZP_SRC+1
        lda #<(SCREEN_RAM + 40 * 8 + 15)
        sta ZP_DST
        lda #>(SCREEN_RAM + 40 * 8 + 15)
        sta ZP_DST+1
        lda #COL_RED
        sta ZP_TMP
        jsr ovl_print_line

        ; Sous-titre (ligne 11, col 7)
        lda #<txt_go_sub
        sta ZP_SRC
        lda #>txt_go_sub
        sta ZP_SRC+1
        lda #<(SCREEN_RAM + 40 * 11 + 7)
        sta ZP_DST
        lda #>(SCREEN_RAM + 40 * 11 + 7)
        sta ZP_DST+1
        lda #COL_WHITE
        sta ZP_TMP
        jsr ovl_print_line

        lda #0
        sta go_cursor
        jsr go_draw_menu
        jsr go_music_init
        jmp save_inc_death

go_cursor:      !byte 0

go_draw_menu:
        ; Option 0 : SAVE + CONTINUE (ligne 15, col 11)
        lda #<txt_go_opt0
        sta ZP_SRC
        lda #>txt_go_opt0
        sta ZP_SRC+1
        lda #<(SCREEN_RAM + 40 * 15 + 11)
        sta ZP_DST
        lda #>(SCREEN_RAM + 40 * 15 + 11)
        sta ZP_DST+1
        lda #COL_YELLOW
        sta ZP_TMP
        jsr ovl_print_line

        ; Option 1 : SAVE + QUIT (ligne 17, col 11)
        lda #<txt_go_opt1
        sta ZP_SRC
        lda #>txt_go_opt1
        sta ZP_SRC+1
        lda #<(SCREEN_RAM + 40 * 17 + 11)
        sta ZP_DST
        lda #>(SCREEN_RAM + 40 * 17 + 11)
        sta ZP_DST+1
        lda #COL_WHITE
        sta ZP_TMP
        jsr ovl_print_line

        ; Option 2 : RETOUR (ligne 19, col 11)
        lda #<txt_go_opt2
        sta ZP_SRC
        lda #>txt_go_opt2
        sta ZP_SRC+1
        lda #<(SCREEN_RAM + 40 * 19 + 11)
        sta ZP_DST
        lda #>(SCREEN_RAM + 40 * 19 + 11)
        sta ZP_DST+1
        lda #COL_CYAN
        sta ZP_TMP
        jsr ovl_print_line

        ; Curseur '*' à col 9 sur la ligne sélectionnée
        lda #' '
        sta SCREEN_RAM + 40 * 15 + 9
        sta SCREEN_RAM + 40 * 17 + 9
        sta SCREEN_RAM + 40 * 19 + 9
        lda #'*'
        ldx go_cursor
        beq .cur0
        cpx #1
        beq .cur1
        sta SCREEN_RAM + 40 * 19 + 9
        lda #COL_RED
        sta COLOR_RAM + 40 * 19 + 9
        rts
.cur0:  sta SCREEN_RAM + 40 * 15 + 9
        lda #COL_RED
        sta COLOR_RAM + 40 * 15 + 9
        rts
.cur1:  sta SCREEN_RAM + 40 * 17 + 9
        lda #COL_RED
        sta COLOR_RAM + 40 * 17 + 9
        rts

ovl_gameover_update:
        lda #0
        sta VIC_SPRITE_EN
        jsr go_music_update
        lda ovl_modal_timer
        beq .go_wait_btn
        dec ovl_modal_timer
        rts

.go_wait_btn:
        lda joy_pressed
        and #JOY_UP
        beq +
        lda go_cursor
        beq +
        dec go_cursor
        jsr sound_inv_flip
        jsr go_draw_menu
+       lda joy_pressed
        and #JOY_DOWN
        beq +
        lda go_cursor
        cmp #2
        bcs +
        inc go_cursor
        jsr sound_inv_flip
        jsr go_draw_menu
+
        lda btn_a_pressed
        ora btn_x_pressed
        ora btn_b_pressed
        bne .go_exec_choice
        rts

.go_exec_choice:
        jsr sound_inv_select
        ; Coupe V1/V2 avant de quitter le menu Game Over
        lda #%01000000
        sta SID1_V1_CTRL
        lda #%00010000
        sta SID1_V2_CTRL
        ldy dual_sid_enabled
        beq +
        lda #%01000000
        sta SID2_V1_CTRL
        lda #%00010000
        sta SID2_V2_CTRL
+       lda go_cursor
        bne +
        jmp gameover_save_and_continue
+       cmp #1
        bne +
        jmp gameover_save_and_quit
+
        ; RETOUR : si vivant (hud_cur_hearts > 0), reprend sur place ; sinon respawn
        lda hud_cur_hearts
        beq ovl_gameover_continue
        lda current_world_type
        cmp #WORLD_DUNGEON
        bne .ret_ow
        lda VIC_CTRL2
        ora #%00010000
        sta VIC_CTRL2
        jsr clear_screen
        jsr load_room
        jsr hud_init
        jsr sound_play_dungeon_music
        lda #STATE_PLAYING
        sta game_state
        rts
.ret_ow:
        lda VIC_CTRL2
        ora #%00010000
        sta VIC_CTRL2
        jsr clear_screen
        jsr load_room
        jsr hud_init
        lda #MUSIC_OVERWORLD
        jsr music_play
        lda #STATE_PLAYING
        sta game_state
        rts

ovl_gameover_continue:
.go_continue:
        ; Restaure 3 cœurs (12 quarts) ou hud_max_hearts*4 si inférieur
        lda hud_max_hearts
        asl
        asl
        cmp #12
        bcc +
        lda #12
+       sta hud_cur_hearts
        lda #0
        sta player_hurt_timer
        sta sword_cursed_timer
        sta item_active
        sta en_proj_active
        sta player_attacking

        lda current_world_type
        cmp #WORLD_DUNGEON
        beq .go_respawn_dung

        ; Respawn Overworld au départ H-8 (7, 7)
        lda #7
        sta current_room_x
        sta current_room_y
        jsr clear_screen
        jsr cart_load_map_overworld
        jsr cart_load_sprites_ow
        lda #180
        sta player_x
        lda #0
        sta player_x+1
        lda #150
        sta player_y
        lda #DIR_DOWN
        sta player_dir
        lda #MUSIC_OVERWORLD
        jsr music_play
        jsr load_room
        jsr hud_init
        jsr enemies_room_init
        lda #STATE_PLAYING
        sta game_state
        rts

.go_respawn_dung:
        ; Respawn à l'entrée du donjon actif
        lda dungeon_entrance_room_x
        sta current_room_x
        lda dungeon_entrance_room_y
        sta current_room_y
        jsr clear_screen
        lda #176
        sta player_x
        lda #0
        sta player_x+1
        lda #180
        sta player_y
        lda #DIR_UP
        sta player_dir
        jsr sound_play_dungeon_music
        jsr load_room
        jsr hud_init
        jsr enemies_room_init
        jsr dungeon_on_enter_room
        lda #STATE_PLAYING
        sta game_state
        rts

txt_go_title:   !text "GAME OVER", 0
txt_go_sub:     !text "LINK HAS FALLEN IN BATTLE.", 0
txt_go_opt0:    !text "SAVE + CONTINUE", 0
txt_go_opt1:    !text "SAVE + QUIT", 0
txt_go_opt2:    !text "RETOUR", 0

; ---------------------------------------------------------------------------
; Animation et jingle de mort de Link + musique du menu Game Over (Banque 29)
; ---------------------------------------------------------------------------
go_play_death_anim:
        lda #%00000001
        sta VIC_SPRITE_EN
        sta VIC_SPRITE_MC
        lda #15
        sta SID1_VOLUME
        ldy dual_sid_enabled
        beq +
        sta SID2_VOLUME
+       lda #$08
        sta SID1_V1_PW_HI
        lda #$05
        sta SID1_V1_AD
        lda #$40
        sta SID1_V1_SR
        ldy dual_sid_enabled
        beq +
        lda #$08
        sta SID2_V1_PW_HI
        lda #$05
        sta SID2_V1_AD
        lda #$40
        sta SID2_V1_SR
+       lda #0
        sta go_anim_step
.death_spin_loop:
        ldx go_anim_step
        cpx #12
        bcs .death_puff
        ; Note descendante de mort sur V1
        lda go_death_freq_lo,x
        sta SID1_V1_FREQ_LO
        lda go_death_freq_hi,x
        sta SID1_V1_FREQ_HI
        lda #%01000000
        sta SID1_V1_CTRL
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        lda #%01000001
        sta SID1_V1_CTRL
        ldy dual_sid_enabled
        beq +
        lda go_death_freq_lo,x
        sta SID2_V1_FREQ_LO
        lda go_death_freq_hi,x
        sta SID2_V1_FREQ_HI
        lda #%01000000
        sta SID2_V1_CTRL
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        lda #%01000001
        sta SID2_V1_CTRL
+
        ; Rotation Link (Bas -> Gauche -> Haut -> Droite) + flash couleur
        txa
        and #3
        tay
        lda go_spin_ptrs,y
        sta SPRITE_PTR0
        lda go_spin_cols,y
        sta VIC_SPRITE_COL0
        ldx #4
-       jsr wait_frame
        dex
        bne -
        inc go_anim_step
        bne .death_spin_loop

.death_puff:
        lda #%01000000
        sta SID1_V1_CTRL
        ldy dual_sid_enabled
        beq +
        sta SID2_V1_CTRL
+       lda #<(sprite_link_proj_explosion / 64)
        sta SPRITE_PTR0
        ldx #16
.puff_loop:
        txa
        and #2
        beq +
        lda #COL_WHITE
        bne ++
+       lda #COL_ORANGE
++      sta VIC_SPRITE_COL0
        jsr wait_frame
        dex
        bne .puff_loop
        lda #0
        sta VIC_SPRITE_EN
        ldx #10
-       jsr wait_frame
        dex
        bne -
        rts

go_music_init:
        lda #0
        sta go_mus_idx
        lda #1
        sta go_mus_tmr
        lda #15
        sta SID1_VOLUME
        lda #$06
        sta SID1_V1_PW_HI
        lda #$18
        sta SID1_V1_AD
        lda #$40
        sta SID1_V1_SR
        lda #$08
        sta SID1_V2_AD
        lda #$60
        sta SID1_V2_SR
        ldy dual_sid_enabled
        beq +
        sta SID2_V2_SR
        lda #$08
        sta SID2_V2_AD
        lda #$40
        sta SID2_V1_SR
        lda #$18
        sta SID2_V1_AD
        lda #$06
        sta SID2_V1_PW_HI
        lda #15
        sta SID2_VOLUME
+       rts

go_music_update:
        dec go_mus_tmr
        beq +
        rts
+       lda #12
        sta go_mus_tmr
        ldx go_mus_idx
        cpx #32
        bcc +
        ldx #0
        stx go_mus_idx
+       lda go_bgm_v1_lo,x
        sta SID1_V1_FREQ_LO
        lda go_bgm_v1_hi,x
        sta SID1_V1_FREQ_HI
        lda go_bgm_v2_lo,x
        sta SID1_V2_FREQ_LO
        lda go_bgm_v2_hi,x
        sta SID1_V2_FREQ_HI
        lda #%01000000
        sta SID1_V1_CTRL
        lda #%00010000
        sta SID1_V2_CTRL
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        lda #%01000001
        sta SID1_V1_CTRL
        lda #%00010001
        sta SID1_V2_CTRL

        ldy dual_sid_enabled
        beq +
        lda go_bgm_v1_lo,x
        sta SID2_V1_FREQ_LO
        lda go_bgm_v1_hi,x
        sta SID2_V1_FREQ_HI
        lda go_bgm_v2_lo,x
        sta SID2_V2_FREQ_LO
        lda go_bgm_v2_hi,x
        sta SID2_V2_FREQ_HI
        lda #%01000000
        sta SID2_V1_CTRL
        lda #%00010000
        sta SID2_V2_CTRL
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        lda #%01000001
        sta SID2_V1_CTRL
        lda #%00010001
        sta SID2_V2_CTRL
+       inc go_mus_idx
        rts

go_anim_step:   !byte 0
go_mus_idx:     !byte 0
go_mus_tmr:     !byte 1
go_spin_ptrs:
        !byte <(sprite_link_down_0 / 64), <(sprite_link_left_0 / 64)
        !byte <(sprite_link_up_0 / 64), <(sprite_link_right_0 / 64)
go_spin_cols:
        !byte COL_RED, COL_WHITE, COL_GREEN, COL_YELLOW
go_death_freq_lo:
        !byte $c5, $c5, $4b, $f1, $c5, $c5, $4b, $f1, $c5, $c5, $4b, $f1
go_death_freq_hi:
        !byte $2b, $22, $1d, $18, $2b, $22, $1d, $18, $2b, $22, $1d, $18
go_bgm_v1_lo:
        !byte $ac, $04, $c5, $c5, $56, $04, $45, $a2
        !byte $21, $c5, $c5, $21, $ac, $c5, $c1, $c5
        !byte $21, $c5, $ee, $21, $b6, $c5, $c1, $ee
        !byte $c5, $04, $c5, $c5, $c1, $4b, $a2, $c1
go_bgm_v1_hi:
        !byte $33, $1a, $22, $2b, $29, $1a, $41, $20
        !byte $3a, $22, $2b, $3a, $33, $22, $26, $2b
        !byte $3a, $22, $2d, $3a, $36, $22, $26, $2d
        !byte $2b, $1a, $22, $2b, $26, $1d, $20, $26
go_bgm_v2_lo:
        !byte $84, $4f, $36, $b1, $02, $84, $02, $36
        !byte $02, $84, $02, $b1, $02, $84, $02, $b1
        !byte $b1, $c4, $f1, $97, $62, $b1, $62, $97
        !byte $62, $b1, $62, $f1, $62, $84, $02, $36
go_bgm_v2_hi:
        !byte $06, $07, $08, $08, $0d, $06, $0d, $08
        !byte $0d, $06, $0d, $08, $0d, $06, $0d, $08
        !byte $08, $09, $0a, $0b, $11, $08, $11, $0b
        !byte $11, $08, $11, $0a, $11, $06, $0d, $08

; ===========================================================================
; 11. SAUVETAGE PRINCESSE ZELDA & ÉCRAN DE FIN (Fix M2 — STATE_ENDING = 9)
; ===========================================================================
ovl_ending_open:
        lda #STATE_ENDING
        sta game_state
        jsr ovl_clear_screen_black
        jsr sound_triforce_fanfare
        lda #60
        sta ovl_modal_timer

        ; Texte de victoire authentique NES
        lda #<txt_end_1
        sta ZP_SRC
        lda #>txt_end_1
        sta ZP_SRC+1
        lda #<(SCREEN_RAM + 40 * 5 + 13)
        sta ZP_DST
        lda #>(SCREEN_RAM + 40 * 5 + 13)
        sta ZP_DST+1
        lda #COL_YELLOW
        sta ZP_TMP
        jsr ovl_print_line

        lda #<txt_end_2
        sta ZP_SRC
        lda #>txt_end_2
        sta ZP_SRC+1
        lda #<(SCREEN_RAM + 40 * 7 + 6)
        sta ZP_DST
        lda #>(SCREEN_RAM + 40 * 7 + 6)
        sta ZP_DST+1
        lda #COL_WHITE
        sta ZP_TMP
        jsr ovl_print_line

        lda #<txt_end_3
        sta ZP_SRC
        lda #>txt_end_3
        sta ZP_SRC+1
        lda #<(SCREEN_RAM + 40 * 16 + 7)
        sta ZP_DST
        lda #>(SCREEN_RAM + 40 * 16 + 7)
        sta ZP_DST+1
        lda #COL_CYAN
        sta ZP_TMP
        jsr ovl_print_line

        lda #<txt_end_4
        sta ZP_SRC
        lda #>txt_end_4
        sta ZP_SRC+1
        lda #<(SCREEN_RAM + 40 * 20 + 6)
        sta ZP_DST
        lda #>(SCREEN_RAM + 40 * 20 + 6)
        sta ZP_DST+1
        lda #COL_YELLOW
        sta ZP_TMP
        jsr ovl_print_line

        ; Sprites de fin : Link (0) brandissant la Triforce (2) à côté de Zelda (1)
        lda #SPR_COMMON_ITEM_GET
        sta SPRITE_PTR0
        lda #COL_GREEN
        sta VIC_SPRITE_COL0
        lda #148
        sta VIC_SPRITE_X0
        lda #148
        sta VIC_SPRITE_Y0

        lda #(sprite_link_old_woman / 64)
        sta SPRITE_PTR1
        lda #COL_LIGHT_RED
        sta VIC_SPRITE_COL1
        lda #196
        sta VIC_SPRITE_X1
        lda #148
        sta VIC_SPRITE_Y1

        lda #SPR_COMMON_TRIFORCE
        sta SPRITE_PTR2
        lda #COL_YELLOW
        sta VIC_SPRITE_COL2
        lda #172
        sta VIC_SPRITE_X2
        lda #128
        sta VIC_SPRITE_Y2

        lda #%00000111
        sta VIC_SPRITE_EN
        sta VIC_SPRITE_MC
        rts

ovl_ending_update:
        ; Fait scintiller la Triforce
        inc ZP_TMP
        lda ZP_TMP
        and #8
        beq +
        lda #COL_WHITE
        bne ++
+       lda #COL_YELLOW
++      sta VIC_SPRITE_COL2

        lda ovl_modal_timer
        beq .end_wait_btn
        dec ovl_modal_timer
        rts

.end_wait_btn:
        lda btn_a_pressed
        ora btn_x_pressed
        ora btn_b_pressed
        bne .end_finish
        lda joy
        and #JOY_FIRE
        bne .end_finish
        rts

.end_finish:
        ; Soin complet et retour triomphal en Hyrule
        lda hud_max_hearts
        sta hud_cur_hearts
        lda #$ff
        sta player_triforce_pieces
        jmp ovl_exit_dungeon

txt_end_1:      !text "THANKS LINK!", 0
txt_end_2:      !text "YOU ARE THE HERO OF HYRULE!", 0
txt_end_3:      !text "PEACE RETURNS TO HYRULE.", 0
txt_end_4:      !text "PRESS [A] TO RETURN TO HYRULE", 0

; ===========================================================================
; 12. SORTIE DE DONJON (ovl_exit_dungeon — déporté de tilemap.asm vers Banque 29)
; ===========================================================================
ovl_exit_dungeon:
        jsr ovl_curtain_close
        lda #0
        sta en_type
        sta en_type+1
        sta en_proj_active
        sta item_active
        sta player_attacking

        lda saved_ow_room_x
        sta current_room_x
        lda saved_ow_room_y
        sta current_room_y

        jsr clear_screen
        lda #WORLD_OVERWORLD
        sta current_world_type
        jsr cart_load_map_overworld
        jsr cart_load_sprites_ow

        lda saved_ow_player_x
        sta player_x
        lda saved_ow_player_x+1
        sta player_x+1
        lda saved_ow_player_y
        clc
        adc #16
        sta player_y
        lda #DIR_DOWN
        sta player_dir
        lda #0
        sta player_walk_anim
        sta player_walk_tick

        lda current_dungeon_level
        cmp #9
        bne +
        jsr sound_restore_standard_bgm
+       lda #MUSIC_OVERWORLD
        jsr music_play

        jsr load_room
        lda current_dungeon_level
        cmp #8
        bne +
        lda #244
        sta player_x
        lda #0
        sta player_x+1
        lda #162
        sta player_y
+       jsr hud_init
        jsr enemies_room_init
        lda #STATE_PLAYING
        sta game_state
        rts

; ===========================================================================
; 13. BUTIN ENNEMI (ovl_spawn_loot & ovl_collect_loot — Banque 29)
; ===========================================================================
ovl_spawn_loot:
        jsr get_rand
        and #$3f
        beq .drop_fairy                 ; 1/64 (~1.6%)  : Fée (soin complet)
        cmp #1
        beq .drop_clock                 ; 1/64 (~1.6%)  : Horloge (gèle ennemis)
        cmp #5
        bcc .drop_rupee5                ; 3/64 (~4.7%)  : Rubis bleu (+5)
        cmp #8
        bcc .drop_bomb                  ; 3/64 (~4.7%)  : Bombes (+4)
        cmp #19
        bcc .drop_heart                 ; 11/64 (~17.2%): Cœur (+1 cœur)
        cmp #32
        bcc .drop_rupee1                ; 13/64 (~20.3%): Rubis jaune (+1)
        rts                             ; 32/64 (50%)   : rien

.drop_fairy:
        lda #LOOT_FAIRY
        !byte $2c
.drop_clock:
        lda #LOOT_CLOCK
        !byte $2c
.drop_rupee5:
        lda #LOOT_RUPEE_5
        !byte $2c
.drop_bomb:
        lda #LOOT_BOMB
        !byte $2c
.drop_heart:
        lda #LOOT_HEART
        !byte $2c
.drop_rupee1:
        lda #LOOT_RUPEE_1
        sta loot_drop_type
        ldx en_idx
        lda en_y,x
        sta loot_drop_y
        txa
        asl
        tax
        lda en_x,x
        sta loot_drop_x
        lda en_x+1,x
        sta loot_drop_x+1
        lda #<400
        sta loot_drop_timer
        lda #>400
        sta loot_drop_timer+1
        lda #1
        sta loot_drop_active
        rts

ovl_update_loot:
        lda loot_drop_timer
        bne +
        lda loot_drop_timer+1
        beq .loot_expire
        dec loot_drop_timer+1
+       dec loot_drop_timer
        lda loot_drop_type
        cmp #LOOT_FAIRY
        bne .chk_loot_pickup
        jsr .ovl_update_fairy

.chk_loot_pickup:
        lda player_x
        sec
        sbc loot_drop_x
        tay
        lda player_x+1
        sbc loot_drop_x+1
        beq .chk_lx_pos
        cmp #$ff
        bne .loot_ret
        tya
        eor #$ff
        clc
        adc #1
        jmp .chk_lx_dist
.chk_lx_pos:
        tya
.chk_lx_dist:
        cmp #12
        bcs .loot_ret
        lda player_y
        sec
        sbc loot_drop_y
        bcs +
        eor #$ff
        adc #1
+       cmp #12
        bcs .loot_ret

ovl_collect_loot:
        lda #0
        sta loot_drop_active
        lda loot_drop_type
        cmp #LOOT_FAIRY
        beq ovl_loot_fairy
        cmp #LOOT_CLOCK
        beq ovl_loot_clock
        cmp #LOOT_RUPEE_5
        beq .loot_rupee5
        cmp #LOOT_BOMB
        beq .loot_bomb
        cmp #LOOT_HEART
        beq .loot_heart
        cmp #LOOT_RUPEE_1
        beq .loot_rupee1
        rts
.loot_expire:
        lda #0
        sta loot_drop_active
.loot_ret:
        rts

ovl_loot_fairy:
        jsr hud_heal_full
        jmp sound_item_fanfare

ovl_loot_clock:
        lda #1
        sta clock_freeze_active
        jmp sound_secret_chime

.loot_rupee5:
        lda #5
        !byte $2c
.loot_rupee1:
        lda #1
        clc
        adc hud_rupees
        bcc +
        lda #255
+       sta hud_rupees
        jsr hud_render
        jmp sound_rupee

.loot_bomb:
        lda hud_bombs
        clc
        adc #4
        cmp #17
        bcc +
        lda #16
+       sta hud_bombs
        jsr hud_render
        jmp sound_rupee

.loot_heart:
        jsr hud_heal_one_heart
        jmp sound_rupee

.ovl_update_fairy:
        lda loot_drop_timer
        and #$0f
        bne .move_fairy
        jsr get_rand
        and #3
        tax
        lda .fairy_vel_tbl,x
        sta loot_fairy_dx
        jsr get_rand
        and #3
        tax
        lda .fairy_vel_tbl,x
        sta loot_fairy_dy
.move_fairy:
        lda loot_fairy_dx
        beq .fairy_move_y
        bmi .fairy_left
        clc
        lda loot_drop_x
        adc #1
        sta loot_drop_x
        bcc +
        inc loot_drop_x+1
+       lda loot_drop_x+1
        beq .fairy_move_y
        lda loot_drop_x
        cmp #<312
        bcc .fairy_move_y
        lda #255
        sta loot_fairy_dx
        bne .fairy_move_y
.fairy_left:
        lda loot_drop_x
        bne +
        dec loot_drop_x+1
+       dec loot_drop_x
        lda loot_drop_x+1
        bne .fairy_move_y
        lda loot_drop_x
        cmp #32
        bcs .fairy_move_y
        lda #1
        sta loot_fairy_dx
.fairy_move_y:
        lda loot_fairy_dy
        beq .fairy_done
        bmi .fairy_up
        inc loot_drop_y
        lda loot_drop_y
        cmp #214
        bcc .fairy_done
        lda #255
        sta loot_fairy_dy
        rts
.fairy_up:
        dec loot_drop_y
        lda loot_drop_y
        cmp #92
        bcs .fairy_done
        lda #1
        sta loot_fairy_dy
.fairy_done:
        rts

loot_fairy_dx:  !byte 1
loot_fairy_dy:  !byte 255
.fairy_vel_tbl: !byte 1, 255, 1, 0

; ===========================================================================
; 13b. RAMASSAGE D'OBJET DE DONJON (ovl_dungeon_collect_drop — Banque 29)
; ===========================================================================
ovl_dungeon_collect_drop:
        ldx current_room_idx
        lda dungeon_room_state,x
        ora #DUNG_ITEM_COLLECTED
        sta dungeon_room_state,x

        lda dungeon_drop_type
        cmp #DROP_KEY
        bne +
        inc hud_keys
.done_minor_drop:
        jsr hud_render
        jsr sound_rupee
        lda #0
        sta dungeon_drop_active
        rts

+       cmp #DROP_HEART_CONTAINER
        bne +
        ldx current_dungeon_level
        beq .hc_skip_mask
        cpx #9
        bcs .hc_skip_mask
        lda bit_powers-1,x
        ora heart_dung_mask
        sta heart_dung_mask
.hc_skip_mask:
        jsr hud_add_max_heart
        jmp .start_dungeon_pickup

+       cmp #DROP_COMPASS
        bne +
        lda #1
        sta player_has_compass
        jmp .done_minor_drop

+       cmp #DROP_MAP
        bne +
        lda #1
        sta player_has_dungeon_map
        jmp .done_minor_drop

+       cmp #DROP_BOOMERANG
        bne +
        lda current_dungeon_level
        cmp #2
        bne .set_wood_boom
        lda #2
        bne .store_boom
.set_wood_boom:
        lda #1
.store_boom:
        sta player_has_boomerang
        jmp .start_dungeon_pickup_hud

+       cmp #DROP_RAFT
        bne +
        lda #1
        sta player_has_raft
        jmp .start_dungeon_pickup_hud

+       cmp #DROP_LADDER
        bne +
        lda #1
        sta player_has_stepladder
        jmp .start_dungeon_pickup_hud

+       cmp #DROP_WHISTLE
        bne +
        lda #1
        sta player_has_whistle
        jmp .start_dungeon_pickup_hud

+       cmp #DROP_BOOK
        bne +
        lda #1
        sta player_has_book
.start_dungeon_pickup_hud:
        jsr hud_render
.start_dungeon_pickup:
        jsr sound_item_fanfare
        lda player_x
        sta dungeon_drop_x
        lda player_y
        sec
        sbc #16
        sta dungeon_drop_y
        lda #60
        sta dungeon_pickup_timer
        rts

+       cmp #DROP_TRIFORCE
        bne +
        lda current_dungeon_level
        cmp #9
        bne .tf_normal
        lda #0
        sta dungeon_drop_active
        jmp ovl_ending_open
.tf_normal:
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

        jsr hud_heal_full

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

; ===========================================================================
; 13c. EXPLOSION BOMBE EN DONJON (ovl_dungeon_bomb_explode — Banque 29)
; ===========================================================================
ovl_dungeon_bomb_explode:
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
        jmp ovl_open_north_door

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
        jmp ovl_open_south_door

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
        jmp ovl_open_west_door

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
        jmp ovl_open_east_door

.done_bomb:
        rts

; ===========================================================================
; 13d. PORTES VERROUILLÉES & OUVERTURES BIDIRECTIONNELLES (Banque 29)
; ===========================================================================
ovl_open_north_door:
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

ovl_open_south_door:
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

ovl_open_west_door:
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

ovl_open_east_door:
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

ovl_dungeon_check_key_door:
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
        jmp ovl_open_north_door

.chk_south:
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
        jmp ovl_open_south_door

.chk_west:
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
        jmp ovl_open_west_door

.chk_east:
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
        jmp ovl_open_east_door

.done_doors:
        rts

.consume_key:
        lda player_has_magic_key
        bne +
        dec hud_keys
        jsr hud_render
+       jmp sound_door_unlock

; ===========================================================================
; 14. RIDEAU D'ENTRÉE / SORTIE DE DONJON (ovl_curtain_close)
; ===========================================================================
ovl_curtain_close:
        lda #0
        sta VIC_SPRITE_EN
        sta curt_left                   ; colonne gauche (0 -> 19)
        lda #39
        sta curt_right                  ; colonne droite (39 -> 20)
.curt_step:
        jsr wait_frame
        sei
        ldx #17
.curt_row:
        lda curtain_row_lo,x
        sta ZP_SCR
        lda curtain_row_hi,x
        sta ZP_SCR+1
        lda #$20                        ; espace noir (fond VIC_BG_COL0)
        ldy curt_left
        sta (ZP_SCR),y
        ldy curt_right
        sta (ZP_SCR),y
        dex
        bpl .curt_row
        cli

        inc curt_left
        dec curt_right
        lda curt_left
        cmp #20
        bcc .curt_step
        rts

curt_left:      !byte 0
curt_right:     !byte 0

; Adresses Screen RAM des lignes 7..24 ($0400 + row * 40)
curtain_row_lo:
        !for r, 7, 24 {
            !byte <(SCREEN_RAM + r * 40)
        }
curtain_row_hi:
        !for r, 7, 24 {
            !byte >(SCREEN_RAM + r * 40)
        }

; ===========================================================================
; 15. ENTRÉE EN DONJON (ovl_enter_dungeon — déporté de tilemap.asm vers Banque 29)
; ===========================================================================
ovl_enter_dungeon:
        lda current_room_x
        sta saved_ow_room_x
        lda current_room_y
        sta saved_ow_room_y
        lda player_x
        sta saved_ow_player_x
        lda player_x+1
        sta saved_ow_player_x+1
        lda player_y
        sta saved_ow_player_y

        lda #0
        sta en_type
        sta en_type+1
        sta en_proj_active
        sta item_active
        sta player_attacking

        lda current_dungeon_level
        bne +
        lda #1
        sta current_dungeon_level
+       lda #WORLD_DUNGEON
        sta current_world_type

        jsr ovl_curtain_close
        jsr clear_screen
        jsr cart_load_dungeon
        jsr cart_load_sprites_dung
        lda current_dungeon_level
        cmp dungeon_active_level
        beq +
        jsr dungeon_init
+
        lda current_dungeon_level
        sec
        sbc #1
        cmp #9
        bcc +
        lda #0
+       tax

        lda dungeon_start_rx,x
        sta current_room_x
        sta dungeon_entrance_room_x
        lda dungeon_start_ry,x
        sta current_room_y
        sta dungeon_entrance_room_y

        lda #176
        sta player_x
        lda #0
        sta player_x+1
        lda #180
        sta player_y
        lda #DIR_UP
        sta player_dir
        lda #0
        sta player_walk_anim
        sta player_walk_tick

        jsr sound_play_dungeon_music
        jsr load_room
        jsr hud_init
        jsr enemies_room_init
        jsr dungeon_on_enter_room
        lda #STATE_PLAYING
        sta game_state
        rts
