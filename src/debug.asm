; ---------------------------------------------------------------------------
; debug.asm : Menu de débogage multifonctions, téléportation et télémétrie
;             Organisé en 3 pages claires :
;               Page 0 : Téléportation (Donjons 1..9 & Overworld)
;               Page 1 : Arsenal & Triche (Objets, Cœurs, Ressources)
;               Page 2 : Système & Télémétrie matérielle temps réel
;             (Touche [ESPACE] pour changer de page, [D] ou [B] pour quitter)
; ---------------------------------------------------------------------------

!zone debug

prev_game_state:    !byte 0
dbg_page:           !byte 0         ; 0 = Warp, 1 = Cheats, 2 = Diagnostic
dbg_cursor:         !byte 0         ; 0..10 (sélection sur page 0)
dbg_warp_ow_room:   !byte 119       ; 0..127 (défaut départ H-8 = 119)
dbg_joy_cooldown:   !byte 0

dbg_col0:           !byte 0
dbg_col1:           !byte 0
dbg_col2:           !byte 0
dbg_col3:           !byte 0
dbg_col4:           !byte 0
dbg_col7:           !byte 0

; Entrées Overworld authentiques pour les 9 Donjons
debug_dungeon_ow_rx:
        !byte 7, 12, 4, 5, 11, 2, 2, 13, 5
debug_dungeon_ow_ry:
        !byte 3,  3, 7, 4,  0, 2, 4,  6, 0
debug_dungeon_ow_px:
        !byte 184, 184, 184, 184, 184, 184, 184, 184, 120
debug_dungeon_ow_py:
        !byte 146, 146, 146, 146, 146, 146, 146, 146, 146

ovl_debug_open:
        lda game_state
        sta prev_game_state
        lda #STATE_DEBUG
        sta game_state

        lda #0
        sta key_d_pressed
        sta btn_b_pressed
        sta VIC_SPRITE_EN
        sta active_bg_color
        sta VIC_BACKGROUND
        sta VIC_BORDER
        sta dbg_page
        sta dbg_cursor
        lda #15
        sta dbg_joy_cooldown

        jsr sound_inv_flip
        jsr debug_render_screen
        rts

ovl_debug_update:
        lda key_d_pressed
        bne .do_close
        lda btn_b_pressed
        bne .do_close

        lda dbg_joy_cooldown
        beq +
        dec dbg_joy_cooldown
+       jmp .scan_matrix

.do_close:
        jsr close_debug
        rts

.scan_matrix:
        ; Ligne 7 ($7F) : Col 0='1', Col 3='2', Col 4=Espace, Col 6='M'
        lda #%01111111
        sta CIA1_PORT_A
        lda CIA1_PORT_B
        sta dbg_col7

        ; Ligne 1 ($FD) : Col 0='3', Col 1='W', Col 3='4', Col 6='E'
        lda #%11111101
        sta CIA1_PORT_A
        lda CIA1_PORT_B
        sta dbg_col1

        ; Ligne 2 ($FB) : Col 0='5', Col 1='R', Col 3='6', Col 5='F'
        lda #%11111011
        sta CIA1_PORT_A
        lda CIA1_PORT_B
        sta dbg_col2

        ; Ligne 3 ($F7) : Col 0='7', Col 3='8', Col 4='B', Col 5='H', Col 6='U'
        lda #%11110111
        sta CIA1_PORT_A
        lda CIA1_PORT_B
        sta dbg_col3

        ; Ligne 4 ($EF) : Col 0='9', Col 5='K', Col 6='O'
        lda #%11101111
        sta CIA1_PORT_A
        lda CIA1_PORT_B
        sta dbg_col4

        ; Ligne 0 ($FE) : Col 1=Return
        lda #%11111110
        sta CIA1_PORT_A
        lda CIA1_PORT_B
        sta dbg_col0

        lda #$ff
        sta CIA1_PORT_A

        ; Touche ESPACE : cycle de page
        lda dbg_col7
        and #%00010000
        bne .chk_actions
        lda dbg_joy_cooldown
        bne .chk_actions
        lda #15
        sta dbg_joy_cooldown
        inc dbg_page
        lda dbg_page
        cmp #3
        bcc +
        lda #0
        sta dbg_page
+       jsr sound_inv_flip
        jsr debug_render_screen
        rts

.chk_actions:
        lda dbg_page
        bne +
        jmp .update_p0
+       cmp #1
        bne +
        jmp .update_p1
+       jmp .update_p2

; ---------------------------------------------------------------------------
; PAGE 0 ACTIONS : TELEPORTATION
; ---------------------------------------------------------------------------
.update_p0:
        lda dbg_col7
        and #%00000001
        bne +
        lda #1
        jmp .direct_d
+       lda dbg_col7
        and #%00001000
        bne +
        lda #2
        jmp .direct_d
+       lda dbg_col1
        and #%00000001
        bne +
        lda #3
        jmp .direct_d
+       lda dbg_col1
        and #%00001000
        bne +
        lda #4
        jmp .direct_d
+       lda dbg_col2
        and #%00000001
        bne +
        lda #5
        jmp .direct_d
+       lda dbg_col2
        and #%00001000
        bne +
        lda #6
        jmp .direct_d
+       lda dbg_col3
        and #%00000001
        bne +
        lda #7
        jmp .direct_d
+       lda dbg_col3
        and #%00001000
        bne +
        lda #8
        jmp .direct_d
+       lda dbg_col4
        and #%00000001
        bne +
        lda #9
.direct_d:
        sta current_dungeon_level
        jmp debug_do_warp_dungeon
+
        lda dbg_col4
        and #%01000000
        bne +
        jmp debug_do_warp_overworld
+
        lda dbg_joy_cooldown
        bne .p0_chk_fire

        lda joy
        and #JOY_UP
        beq +
        lda #10
        sta dbg_joy_cooldown
        lda dbg_cursor
        beq ++
        dec dbg_cursor
        jmp .p0_moved
++      lda #10
        sta dbg_cursor
        jmp .p0_moved
+
        lda joy
        and #JOY_DOWN
        beq +
        lda #10
        sta dbg_joy_cooldown
        lda dbg_cursor
        cmp #10
        bcs ++
        inc dbg_cursor
        jmp .p0_moved
++      lda #0
        sta dbg_cursor
        jmp .p0_moved
+
        lda joy
        and #JOY_LEFT
        beq +
        lda #8
        sta dbg_joy_cooldown
        lda dbg_warp_ow_room
        beq .p0_moved
        dec dbg_warp_ow_room
        jmp .p0_moved
+
        lda joy
        and #JOY_RIGHT
        beq .p0_chk_fire
        lda #8
        sta dbg_joy_cooldown
        lda dbg_warp_ow_room
        cmp #127
        bcs .p0_moved
        inc dbg_warp_ow_room

.p0_moved:
        jsr sound_inv_select
        jsr debug_render_screen
        rts

.p0_chk_fire:
        lda btn_a_pressed
        bne .p0_exec
        lda dbg_col0
        and #%00000010
        beq .p0_exec
        rts

.p0_exec:
        lda dbg_cursor
        cmp #9
        bcc +
        beq .p0_start_ow
        jmp debug_do_warp_overworld
.p0_start_ow:
        lda #119
        sta dbg_warp_ow_room
        jmp debug_do_warp_overworld
+       clc
        adc #1
        sta current_dungeon_level
        jmp debug_do_warp_dungeon

; ---------------------------------------------------------------------------
; PAGE 1 ACTIONS : CHEATS
; ---------------------------------------------------------------------------
.update_p1:
        lda dbg_joy_cooldown
        bne .p1_keys

        lda joy
        and #JOY_LEFT
        beq +
        lda #12
        sta dbg_joy_cooldown
        lda hud_max_hearts
        cmp #4
        bcc .p1_ref
        dec hud_max_hearts
        lda hud_cur_hearts
        cmp hud_max_hearts
        bcc .p1_ref
        lda hud_max_hearts
        sta hud_cur_hearts
        jmp .p1_ref
+
        lda joy
        and #JOY_RIGHT
        beq .p1_keys
        lda #12
        sta dbg_joy_cooldown
        lda hud_max_hearts
        cmp #16
        bcs .p1_ref
        inc hud_max_hearts
        inc hud_cur_hearts
        jmp .p1_ref

.p1_ref:
        jmp .p1_do_ref

.p1_keys:
        lda dbg_col2
        and #%00100000
        bne +
        jsr debug_cheat_full_gear
        jmp .p1_ref
+
        lda dbg_col3
        and #%00100000
        bne +
        jsr debug_cheat_heal
        jmp .p1_ref
+
        lda dbg_col1
        and #%01000000
        bne +
        lda dbg_joy_cooldown
        bne +
        lda #12
        sta dbg_joy_cooldown
        inc player_has_sword
        lda player_has_sword
        cmp #4
        bcc .p1_ref
        lda #0
        sta player_has_sword
        jmp .p1_ref
+
        lda dbg_col3
        and #%00010000
        bne +
        lda dbg_joy_cooldown
        bne +
        lda #12
        sta dbg_joy_cooldown
        lda player_has_shield
        eor #3
        sta player_has_shield
        jmp .p1_ref
+
        lda dbg_col2
        and #%00000010
        bne +
        lda dbg_joy_cooldown
        bne +
        lda #12
        sta dbg_joy_cooldown
        inc player_has_blue_ring
        lda player_has_blue_ring
        cmp #3
        bcc .p1_ref
        lda #0
        sta player_has_blue_ring
        jmp .p1_ref
+
        lda dbg_col4
        and #%00100000
        bne +
        lda dbg_joy_cooldown
        bne +
        lda #12
        sta dbg_joy_cooldown
        lda hud_keys
        clc
        adc #5
        cmp #99
        bcc ++
        lda #99
++      sta hud_keys
        jmp .p1_ref
+
        lda dbg_col7
        and #%01000000
        bne +
        lda dbg_joy_cooldown
        bne +
        lda #12
        sta dbg_joy_cooldown
        lda hud_bombs
        clc
        adc #4
        cmp #16
        bcc ++
        lda #16
++      sta hud_bombs
        jmp .p1_ref
+
        lda dbg_col3
        and #%01000000
        bne +
        lda dbg_joy_cooldown
        bne +
        lda #12
        sta dbg_joy_cooldown
        lda hud_rupees
        clc
        adc #50
        bcc ++
        lda #255
++      sta hud_rupees
        jmp .p1_ref
+
        lda dbg_col2
        and #%01000000
        bne .p1_idle
        lda dbg_joy_cooldown
        bne .p1_idle
        lda #15
        sta dbg_joy_cooldown
        sec
        rol player_triforce_pieces
        lda player_triforce_pieces
        bne .p1_do_ref
        lda #1
        sta player_triforce_pieces

.p1_do_ref:
        jsr sound_secret
        jsr hud_render
        jsr debug_render_screen
.p1_idle:
        rts

; ---------------------------------------------------------------------------
; PAGE 2 ACTIONS : SYSTEME
; ---------------------------------------------------------------------------
.update_p2:
        lda dbg_col1
        and #%00100000
        bne +
        lda dbg_joy_cooldown
        bne +
        lda #15
        sta dbg_joy_cooldown
        lda dual_sid_enabled
        eor #1
        sta dual_sid_enabled
        jsr sound_secret
        jsr debug_render_screen
+       rts

close_debug:
        lda prev_game_state
        cmp #STATE_INVENTORY
        bne +
        jsr open_inventory
        rts
+       cmp #STATE_CAVE
        bne .restore_p
        lda #STATE_CAVE
        sta game_state
        jsr cave_draw_screen
        rts

.restore_p:
        lda #STATE_PLAYING
        sta game_state
        lda #COL_BLACK
        sta active_bg_color
        sta VIC_BACKGROUND
        sta VIC_BORDER
        jsr clear_screen
        jsr load_room
        jsr hud_init
        jsr player_draw
        jsr items_draw
        jsr enemies_prep_multiplexer
        rts

debug_clear_screen:
        ldx #0
.clr:
        lda #32
        sta SCREEN_RAM,x
        sta SCREEN_RAM + 250,x
        sta SCREEN_RAM + 500,x
        sta SCREEN_RAM + 750,x
        lda #COL_WHITE
        sta COLOR_RAM,x
        sta COLOR_RAM + 250,x
        sta COLOR_RAM + 500,x
        sta COLOR_RAM + 750,x
        inx
        cpx #250
        bne .clr
        rts

ovl_debug_render_screen:
        jsr debug_clear_screen

        lda #< (SCREEN_RAM + 6)
        sta ZP_DST
        lda #> (SCREEN_RAM + 6)
        sta ZP_DST+1
        lda #< dbg_title_str
        sta ZP_SRC
        lda #> dbg_title_str
        sta ZP_SRC+1
        jsr debug_print_str

        lda #< (SCREEN_RAM + 40 * 1 + 2)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 1 + 2)
        sta ZP_DST+1
        lda #< dbg_tabs_base
        sta ZP_SRC
        lda #> dbg_tabs_base
        sta ZP_SRC+1
        jsr debug_print_str

        ldx dbg_page
        lda dbg_tab_b1,x
        tay
        lda #'['
        sta SCREEN_RAM + 40 * 1 + 2,y
        lda dbg_tab_b2,x
        tay
        lda #']'
        sta SCREEN_RAM + 40 * 1 + 2,y

        ldx #0
-       lda #'-'
        sta SCREEN_RAM + 40 * 2,x
        lda #COL_BLUE
        sta COLOR_RAM + 40 * 2,x
        inx
        cpx #40
        bne -

        lda #< (SCREEN_RAM + 40 * 23 + 2)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 23 + 2)
        sta ZP_DST+1
        lda #< dbg_foot1_str
        sta ZP_SRC
        lda #> dbg_foot1_str
        sta ZP_SRC+1
        jsr debug_print_str

        lda #< (SCREEN_RAM + 40 * 24 + 2)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 24 + 2)
        sta ZP_DST+1
        lda #< dbg_foot2_str
        sta ZP_SRC
        lda #> dbg_foot2_str
        sta ZP_SRC+1
        jsr debug_print_str

        lda dbg_page
        bne +
        jmp debug_draw_p0
+       cmp #1
        bne +
        jmp debug_draw_p1
+       jmp debug_draw_p2

; ---------------------------------------------------------------------------
; PAGE 0 AFFICHAGE
; ---------------------------------------------------------------------------
debug_draw_p0:
        lda #< (SCREEN_RAM + 40 * 4 + 2)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 4 + 2)
        sta ZP_DST+1

        lda #< dbg_p0_strings
        sta ZP_SRC
        lda #> dbg_p0_strings
        sta ZP_SRC+1

        ldx #0
.p0_str_loop:
        txa
        pha
        jsr debug_print_str

        tya
        sec
        adc ZP_SRC
        sta ZP_SRC
        lda ZP_SRC+1
        adc #0
        sta ZP_SRC+1

        pla
        tax
        cpx dbg_cursor
        bne +
        lda #'>'
        ldy #0
        sta (ZP_DST),y
+
        ; Ligne suivante : ZP_DST += 40
        lda ZP_DST
        clc
        adc #40
        sta ZP_DST
        lda ZP_DST+1
        adc #0
        sta ZP_DST+1

        cpx #8
        bne ++
        ; Saut de ligne après le Donjon 9
        lda ZP_DST
        clc
        adc #40
        sta ZP_DST
        lda ZP_DST+1
        adc #0
        sta ZP_DST+1
++
        inx
        cpx #11
        bne .p0_str_loop

        ; Affiche l'ID hex et les coordonnées de la salle OW choisie
        lda #< (SCREEN_RAM + 40 * 15 + 19)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 15 + 19)
        sta ZP_DST+1
        lda dbg_warp_ow_room
        jsr debug_put_hex

        clc
        lda dbg_warp_ow_room
        and #$0f
        adc #'A'
        sta SCREEN_RAM + 40 * 15 + 23
        lda #'-'
        sta SCREEN_RAM + 40 * 15 + 24
        lda dbg_warp_ow_room
        lsr
        lsr
        lsr
        lsr
        and #$07
        clc
        adc #'1'
        sta SCREEN_RAM + 40 * 15 + 25
        rts

; ---------------------------------------------------------------------------
; PAGE 1 AFFICHAGE
; ---------------------------------------------------------------------------
debug_draw_p1:
        lda #< (SCREEN_RAM + 40 * 4 + 2)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 4 + 2)
        sta ZP_DST+1

        lda #< dbg_p1_strings
        sta ZP_SRC
        lda #> dbg_p1_strings
        sta ZP_SRC+1

        ldx #0
.p1_str_loop:
        txa
        pha
        jsr debug_print_str

        tya
        sec
        adc ZP_SRC
        sta ZP_SRC
        lda ZP_SRC+1
        adc #0
        sta ZP_SRC+1

        lda ZP_DST
        clc
        adc #80                         ; saut de 2 lignes
        sta ZP_DST
        lda ZP_DST+1
        adc #0
        sta ZP_DST+1

        pla
        tax
        inx
        cpx #6
        bne .p1_str_loop

        ; Valeurs dynamiques
        lda #< (SCREEN_RAM + 40 * 14 + 11)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 14 + 11)
        sta ZP_DST+1
        lda hud_cur_hearts
        jsr debug_put_dec2
        lda #'/'
        ldy #2
        sta (ZP_DST),y
        iny
        lda hud_max_hearts
        jsr debug_put_dec2_offset

        lda #< (SCREEN_RAM + 40 * 14 + 22)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 14 + 22)
        sta ZP_DST+1
        lda hud_rupees
        jsr debug_put_hex

        lda #< (SCREEN_RAM + 40 * 14 + 29)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 14 + 29)
        sta ZP_DST+1
        lda hud_keys
        jsr debug_put_dec2

        ; Ligne 16 : Épée et Bouclier
        lda #< (SCREEN_RAM + 40 * 16 + 2)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 16 + 2)
        sta ZP_DST+1
        lda #< dbg_p1_eq_str
        sta ZP_SRC
        lda #> dbg_p1_eq_str
        sta ZP_SRC+1
        jsr debug_print_str

        lda #< (SCREEN_RAM + 40 * 16 + 7)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 16 + 7)
        sta ZP_DST+1
        ldx player_has_sword
        cpx #4
        bcc +
        ldx #3
+       lda dbg_sw_names_lo,x
        sta ZP_SRC
        lda dbg_sw_names_hi,x
        sta ZP_SRC+1
        jsr debug_print_str

        lda #< (SCREEN_RAM + 40 * 16 + 22)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 16 + 22)
        sta ZP_DST+1
        ldx #0
        lda player_has_shield
        cmp #2
        bcc +
        inx
+       lda dbg_sh_names_lo,x
        sta ZP_SRC
        lda dbg_sh_names_hi,x
        sta ZP_SRC+1
        jsr debug_print_str
        rts

; ---------------------------------------------------------------------------
; PAGE 2 AFFICHAGE
; ---------------------------------------------------------------------------
debug_draw_p2:
        ; Diagnostic Link & Salle
        lda #< (SCREEN_RAM + 40 * 6 + 6)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 6 + 6)
        sta ZP_DST+1
        lda #< dbg_p2_str1
        sta ZP_SRC
        lda #> dbg_p2_str1
        sta ZP_SRC+1
        jsr debug_print_str

        lda #< (SCREEN_RAM + 40 * 6 + 20)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 6 + 20)
        sta ZP_DST+1
        lda player_x
        jsr debug_put_hex

        lda #< (SCREEN_RAM + 40 * 6 + 27)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 6 + 27)
        sta ZP_DST+1
        lda player_y
        jsr debug_put_hex

        lda #< (SCREEN_RAM + 40 * 9 + 6)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 9 + 6)
        sta ZP_DST+1
        lda #< dbg_p2_str2
        sta ZP_SRC
        lda #> dbg_p2_str2
        sta ZP_SRC+1
        jsr debug_print_str

        lda #< (SCREEN_RAM + 40 * 9 + 25)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 9 + 25)
        sta ZP_DST+1
        lda current_room_idx
        jsr debug_put_hex

        lda #< (SCREEN_RAM + 40 * 12 + 6)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 12 + 6)
        sta ZP_DST+1
        lda #< dbg_p2_str3
        sta ZP_SRC
        lda #> dbg_p2_str3
        sta ZP_SRC+1
        jsr debug_print_str
        rts

dbg_p2_str1: !text "LINK: X=$__ Y=$__", 0
dbg_p2_str2: !text "ROOM  OW/DUNG $__", 0
dbg_p2_str3: !text "RAM: ZONE <$C000 OK", 0

debug_cheat_heal:
        lda hud_max_hearts
        sta hud_cur_hearts
        jsr hud_render
        jsr sound_item_fanfare
        rts

debug_cheat_full_gear:
        lda #3
        sta player_has_sword
        lda #2
        sta player_has_shield
        sta player_has_boomerang
        lda #1
        sta player_has_blue_ring
        sta player_has_raft
        sta player_has_stepladder
        sta player_has_bracelet
        sta player_has_magic_key
        sta player_has_bow
        sta player_has_arrows
        sta player_has_candle
        sta player_has_whistle
        sta player_has_wand
        sta player_has_book
        sta player_has_compass
        sta player_has_dungeon_map
        lda #16
        sta hud_max_hearts
        sta hud_cur_hearts
        lda #8
        sta hud_keys
        sta hud_bombs
        lda #99
        sta hud_rupees
        lda #$ff
        sta player_triforce_pieces
        jsr hud_render
        jsr sound_secret
        rts

debug_do_warp_dungeon:
        lda #STATE_PLAYING
        sta game_state
        lda #0
        sta en_type
        sta en_type+1
        sta en_proj_active
        sta item_active
        sta player_attacking

        ; Sauvegarde l'entrée Overworld exacte du donjon pour la sortie
        ldx current_dungeon_level
        dex
        cpx #9
        bcc +
        ldx #0
+       lda debug_dungeon_ow_rx,x
        sta saved_ow_room_x
        lda debug_dungeon_ow_ry,x
        sta saved_ow_room_y
        lda debug_dungeon_ow_px,x
        sta saved_ow_player_x
        lda #0
        sta saved_ow_player_x+1
        lda debug_dungeon_ow_py,x
        sta saved_ow_player_y

        jsr clear_screen
        jsr disk_load_dungeon
        jsr cart_load_sprites_dung
        jsr dungeon_init

        ldx current_dungeon_level
        dex
        cpx #9
        bcc +
        ldx #0
+       lda dungeon_start_rx,x
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
        rts

debug_do_warp_overworld:
        lda #STATE_PLAYING
        sta game_state
        lda #0
        sta en_type
        sta en_type+1
        sta en_proj_active
        sta item_active
        sta player_attacking

        lda dbg_warp_ow_room
        and #$0f
        sta current_room_x
        lda dbg_warp_ow_room
        lsr
        lsr
        lsr
        lsr
        and #$07
        sta current_room_y

        jsr clear_screen
        jsr disk_load_map_overworld
        jsr cart_load_sprites_ow

        lda #184
        sta player_x
        lda #0
        sta player_x+1
        lda #150
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
        jsr hud_init
        jsr enemies_room_init
        rts

debug_print_str:
        ldy #0
-       lda (ZP_SRC),y
        beq +
        sta (ZP_DST),y
        iny
        bne -
+       rts

debug_put_hex:
        pha
        lsr
        lsr
        lsr
        lsr
        jsr .hex_digit
        ldy #0
        sta (ZP_DST),y
        pla
        and #$0f
        jsr .hex_digit
        ldy #1
        sta (ZP_DST),y
        rts

.hex_digit:
        cmp #10
        bcc +
        adc #6
+       adc #'0'
        rts

debug_put_dec2:
        ldy #0
debug_put_dec2_offset:
        jsr print_2digits
        sta (ZP_DST),y
        txa
        iny
        sta (ZP_DST),y
        rts

dbg_title_str:
        !text "=== DEBUG ZELDA ===", 0

dbg_tabs_base:
        !text " 1:WARP    2:CHEATS    3:INFO  ", 0
dbg_tab_b1:
        !byte 1, 14, 29
dbg_tab_b2:
        !byte 8, 23, 37

dbg_foot1_str:
        !text "[SPACE]  PAGE [FIRE] OK", 0
dbg_foot2_str:
        !text "[D]/[B] : RESUME GAME", 0

dbg_p0_strings:
        !text " 1. L1:EAGLE  H-4", 0
        !text " 2. L2:MOON   M-4", 0
        !text " 3. L3:MANJI  E-8", 0
        !text " 4. L4:SNAKE  F-5", 0
        !text " 5. L5:LIZARD L-1", 0
        !text " 6. L6:DRAGON C-3", 0
        !text " 7. L7:DEMON  C-5", 0
        !text " 8. L8:LION   N-7", 0
        !text " 9. L9:DEATH  F-1", 0
        !text "10. OW START  H-8", 0
        !text "11. OW ROOM : $__ (___)", 0

dbg_p1_strings:
        !text "[F] GEAR  [H] FULL HEAL", 0
        !text "[JOY L/R] +/- MAX HEARTS", 0
        !text "[E] SWORD [B] SHIELD    [R] RING", 0
        !text "[K] +5 KEYS  [M] +4 BOMBS", 0
        !text "[U] +50 RUPEES [T] +1 TRIFORCE", 0
        !text "STAT: HP __/__ RUP:$__ KEY:__", 0

dbg_p1_eq_str:
        !text "SWRD:___ SHLD :___", 0

dbg_sw_names_lo:
        !byte <dbg_sw0, <dbg_sw1, <dbg_sw2, <dbg_sw3
dbg_sw_names_hi:
        !byte >dbg_sw0, >dbg_sw1, >dbg_sw2, >dbg_sw3
dbg_sw0: !text "NONE   ", 0
dbg_sw1: !text "WOOD   ", 0
dbg_sw2: !text "WHITE  ", 0
dbg_sw3: !text "MAGIC  ", 0

dbg_sh_names_lo:
        !byte <dbg_sh1, <dbg_sw3
dbg_sh_names_hi:
        !byte >dbg_sh1, >dbg_sw3
dbg_sh1: !text "SMALL  ", 0

; ---------------------------------------------------------------------------
; Auto-warp debug hook (activable par mémoire ou moniteur)
; ---------------------------------------------------------------------------
ovl_debug_exec_hook_cmd:
        lda debug_hook_cmd
        cmp #1
        bne +
        jmp .hook_warp_ow
+       cmp #2
        bne +
        jmp .hook_warp_dung
+       cmp #3
        bne +
        jmp .hook_open_inv
+       cmp #4
        bne +
        jmp .hook_open_debug
+       cmp #5
        bne +
        jmp .hook_use_item
+       cmp #6
        bne +
        jmp .hook_force_joy
+       cmp #7
        bne +
        jmp .hook_full_gear
+       cmp #8
        bne +
        jmp .hook_test_sound
+       jmp .hook_done

.hook_test_sound:
        lda debug_hook_arg
        cmp #1
        bne +
        jsr sound_rupee
        jmp .hook_done
+       cmp #2
        bne +
        jsr sound_secret_chime
        jmp .hook_done
+       cmp #3
        bne +
        jsr sound_rupee
        jsr sound_secret_chime
        jmp .hook_done
+       cmp #4
        bne +
        jsr sound_sword
        jmp .hook_done
+       jmp .hook_done

.hook_full_gear:
        jsr debug_cheat_full_gear
        jmp .hook_done

.hook_warp_ow:
        lda debug_hook_arg
        sta dbg_warp_ow_room
        jsr debug_do_warp_overworld
        jmp .hook_done

.hook_warp_dung:
        lda debug_hook_arg
        sta current_dungeon_level
        jsr debug_do_warp_dungeon
        lda debug_hook_arg2
        beq +
        and #$0f
        sta current_room_x
        lda debug_hook_arg2
        lsr
        lsr
        lsr
        lsr
        and #$07
        sta current_room_y
        jsr load_room
        jsr enemies_room_init
        jsr dungeon_on_enter_room
+       jmp .hook_done

.hook_open_inv:
        jsr open_inventory
        lda debug_hook_arg
        sta inv_page
        jsr inv_display_current_page
        jmp .hook_done

.hook_open_debug:
        jsr ovl_debug_open
        lda debug_hook_arg
        sta dbg_page
        jsr debug_render_screen
        jmp .hook_done

.hook_use_item:
        lda game_state
        cmp #STATE_DEBUG
        bne +
        jsr close_debug
+       lda debug_hook_arg
        sta hud_selected_b
        jsr player_use_item_b
        jmp .hook_done

.hook_force_joy:
        lda debug_hook_arg
        sta joy
        dec debug_hook_arg2
        bne +
        lda #0
        sta debug_hook_cmd
+       rts

.hook_done:
        lda #0
        sta debug_hook_cmd
        rts
