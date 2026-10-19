; ---------------------------------------------------------------------------
; debug.asm : Moniteur de diagnostic matériel et télémétrie temps réel
;             (Touche 'D' ou Bouton B pour quitter)
; ---------------------------------------------------------------------------

!zone debug

prev_game_state:    !byte 0
dbg_tmp:            !byte 0

; ---------------------------------------------------------------------------
; open_debug : active l'écran de debug
; ---------------------------------------------------------------------------
open_debug:
        lda game_state
        sta prev_game_state
        lda #STATE_DEBUG
        sta game_state

        ; Masque tous les sprites du jeu
        lda #0
        sta VIC_SPRITE_EN

        ; Fond et bordure noirs
        lda #COL_BLACK
        sta active_bg_color
        sta VIC_BACKGROUND
        sta VIC_BORDER

        ; Bip sonore SID
        jsr sound_inv_flip

        jsr debug_render_screen
        rts

; ---------------------------------------------------------------------------
; debug_update : boucle d'exécution de l'écran de debug
; ---------------------------------------------------------------------------
debug_update:
        lda key_d_pressed
        bne +
        lda btn_b_pressed
        bne +
        lda btn_x_pressed
        beq .refresh
+       jsr close_debug
        rts

.refresh:
        jsr debug_render_dynamic
        rts

; ---------------------------------------------------------------------------
; close_debug : ferme le debug et restaure l'affichage du jeu
; ---------------------------------------------------------------------------
close_debug:
        lda prev_game_state
        cmp #STATE_INVENTORY
        bne +
        jsr open_inventory
        rts
+       cmp #STATE_CAVE
        bne .restore_play
        lda #STATE_CAVE
        sta game_state
        jsr cave_draw_screen
        rts

.restore_play:
        lda #STATE_PLAYING
        sta game_state

        lda #COL_BLACK
        sta active_bg_color
        sta VIC_BACKGROUND
        sta VIC_BORDER

        jsr load_room
        jsr hud_init
        jsr player_draw
        jsr items_draw
        jsr enemies_prep_multiplexer
        rts

; ---------------------------------------------------------------------------
; debug_clear_screen : efface l'écran avec des espaces
; ---------------------------------------------------------------------------
debug_clear_screen:
        ldx #0
.clr:
        lda #32                         ; espace
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

; ---------------------------------------------------------------------------
; debug_print_str : affiche une chaîne terminée par 0 à (ZP_DST)
; ---------------------------------------------------------------------------
debug_print_str:
        ldy #0
-       lda (ZP_SRC),y
        beq +
        sta (ZP_DST),y
        iny
        bne -
+       rts

; ---------------------------------------------------------------------------
; debug_put_hex : écrit la valeur de A en hexadécimal à (ZP_DST)
; ---------------------------------------------------------------------------
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
        adc #6                          ; 'A' - '9' - 1
+       adc #48                         ; '0'
        rts

; ---------------------------------------------------------------------------
; debug_render_screen : trace la structure générale
; ---------------------------------------------------------------------------
debug_render_screen:
        jsr debug_clear_screen

        ; Titre Ligne 1
        lda #< (SCREEN_RAM + 40 * 1 + 2)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 1 + 2)
        sta ZP_DST+1
        lda #< dbg_title_str
        sta ZP_SRC
        lda #> dbg_title_str
        sta ZP_SRC+1
        jsr debug_print_str

        ; Lignes 3..21 de description
        ldx #0
.draw_labels:
        lda dbg_row_tbl_lo,x
        sta ZP_DST
        lda dbg_row_tbl_hi,x
        sta ZP_DST+1
        lda dbg_txt_tbl_lo,x
        sta ZP_SRC
        lda dbg_txt_tbl_hi,x
        sta ZP_SRC+1
        txa
        pha
        jsr debug_print_str
        pla
        tax
        inx
        cpx #8
        bne .draw_labels

        ; Pied de page Ligne 23
        lda #< (SCREEN_RAM + 40 * 23 + 2)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 23 + 2)
        sta ZP_DST+1
        lda #< dbg_foot_str
        sta ZP_SRC
        lda #> dbg_foot_str
        sta ZP_SRC+1
        jsr debug_print_str
        rts

; ---------------------------------------------------------------------------
; debug_render_dynamic : met à jour les données dynamiques
; ---------------------------------------------------------------------------
debug_render_dynamic:
        ; 1. Link X (16-bit)
        lda #< (SCREEN_RAM + 40 * 5 + 12)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 5 + 12)
        sta ZP_DST+1
        lda player_x+1
        jsr debug_put_hex
        lda ZP_DST
        clc
        adc #2
        sta ZP_DST
        lda player_x
        jsr debug_put_hex

        ; 2. Link Y (8-bit)
        lda #< (SCREEN_RAM + 40 * 5 + 23)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 5 + 23)
        sta ZP_DST+1
        lda player_y
        jsr debug_put_hex

        ; 3. Link Dir
        lda #< (SCREEN_RAM + 40 * 5 + 34)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 5 + 34)
        sta ZP_DST+1
        lda player_dir
        jsr debug_put_hex

        ; 4. HP
        lda #< (SCREEN_RAM + 40 * 7 + 12)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 7 + 12)
        sta ZP_DST+1
        lda hud_cur_hearts
        jsr debug_put_hex

        ; 5. Max HP
        lda #< (SCREEN_RAM + 40 * 7 + 23)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 7 + 23)
        sta ZP_DST+1
        lda hud_max_hearts
        jsr debug_put_hex

        ; 6. Rupees
        lda #< (SCREEN_RAM + 40 * 7 + 34)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 7 + 34)
        sta ZP_DST+1
        lda hud_rupees
        jsr debug_put_hex

        ; 7. Keys & Bombs
        lda #< (SCREEN_RAM + 40 * 9 + 12)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 9 + 12)
        sta ZP_DST+1
        lda hud_keys
        jsr debug_put_hex
        lda #< (SCREEN_RAM + 40 * 9 + 25)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 9 + 25)
        sta ZP_DST+1
        lda hud_bombs
        jsr debug_put_hex

        ; 8. World & Room
        lda #< (SCREEN_RAM + 40 * 11 + 12)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 11 + 12)
        sta ZP_DST+1
        lda current_world_type
        jsr debug_put_hex
        lda #< (SCREEN_RAM + 40 * 11 + 25)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 11 + 25)
        sta ZP_DST+1
        lda current_room_idx
        jsr debug_put_hex

        ; 9. Level
        lda #< (SCREEN_RAM + 40 * 11 + 36)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 11 + 36)
        sta ZP_DST+1
        lda current_dungeon_level
        jsr debug_put_hex

        ; 10. Dual SID status
        lda #< (SCREEN_RAM + 40 * 13 + 12)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 13 + 12)
        sta ZP_DST+1
        lda dual_sid_enabled
        jsr debug_put_hex

        ; 11. Ennemis actifs (types slots 0 et 1)
        lda #< (SCREEN_RAM + 40 * 15 + 12)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 15 + 12)
        sta ZP_DST+1
        lda en_type
        jsr debug_put_hex
        lda #< (SCREEN_RAM + 40 * 15 + 25)
        sta ZP_DST
        lda #> (SCREEN_RAM + 40 * 15 + 25)
        sta ZP_DST+1
        lda en_type+1
        jsr debug_put_hex

        rts

; ---------------------------------------------------------------------------
; Textes et tables
; ---------------------------------------------------------------------------
dbg_title_str:
        !text "=== ZELDA C64 TELEMETRY & HARDWARE ===", 0
dbg_foot_str:
        !text "APPUYEZ SUR [D] OU [B] POUR QUITTER", 0

dbg_t0: !text "HARDWARE  : VIC $D000  SID $D400 (D420)", 0
dbg_t1: !text "LINK POS  : X=$____   Y=$__    DIR=$__", 0
dbg_t2: !text "STATUS    : HP=$__    MAX=$__  RUP=$__", 0
dbg_t3: !text "ITEMS     : KEYS=$__  BOMBS=$__", 0
dbg_t4: !text "WORLD MAP : TYPE=$__  ROOM=$__ LEVEL=$__", 0
dbg_t5: !text "AUDIO     : DUAL_SID=$__ (TOUCHE 3)", 0
dbg_t6: !text "ENEMIES   : EN0=$__   EN1=$__", 0
dbg_t7: !text "MEMORY    : PRG<$C000 OVERLAY=$C000..$CFFF", 0

dbg_row_tbl_lo:
        !byte <(SCREEN_RAM + 40 * 3 + 2)
        !byte <(SCREEN_RAM + 40 * 5 + 2)
        !byte <(SCREEN_RAM + 40 * 7 + 2)
        !byte <(SCREEN_RAM + 40 * 9 + 2)
        !byte <(SCREEN_RAM + 40 * 11 + 2)
        !byte <(SCREEN_RAM + 40 * 13 + 2)
        !byte <(SCREEN_RAM + 40 * 15 + 2)
        !byte <(SCREEN_RAM + 40 * 17 + 2)

dbg_row_tbl_hi:
        !byte >(SCREEN_RAM + 40 * 3 + 2)
        !byte >(SCREEN_RAM + 40 * 5 + 2)
        !byte >(SCREEN_RAM + 40 * 7 + 2)
        !byte >(SCREEN_RAM + 40 * 9 + 2)
        !byte >(SCREEN_RAM + 40 * 11 + 2)
        !byte >(SCREEN_RAM + 40 * 13 + 2)
        !byte >(SCREEN_RAM + 40 * 15 + 2)
        !byte >(SCREEN_RAM + 40 * 17 + 2)

dbg_txt_tbl_lo:
        !byte <dbg_t0, <dbg_t1, <dbg_t2, <dbg_t3, <dbg_t4, <dbg_t5, <dbg_t6, <dbg_t7
dbg_txt_tbl_hi:
        !byte >dbg_t0, >dbg_t1, >dbg_t2, >dbg_t3, >dbg_t4, >dbg_t5, >dbg_t6, >dbg_t7
