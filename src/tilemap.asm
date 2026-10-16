; ---------------------------------------------------------------------------
; tilemap.asm : affichage de la carte en tuiles 16x16 (2x2 caractères)
; Mode texte multicolore + jeu de caractères perso (src/charset.asm).
; Tuile N = caractères 4N (HG), 4N+1 (HD), 4N+2 (BG), 4N+3 (BD).
; La carte (20x12 tuiles) couvre les 24 premières lignes de texte ; la 25e
; reste vide (caractère 0 = fond uni).
; ---------------------------------------------------------------------------

START_ROOM_X    = 7
START_ROOM_Y    = 7

current_room_x:     !byte START_ROOM_X
current_room_y:     !byte START_ROOM_Y
current_room_idx:   !byte 0
current_zone:       !byte 0

current_world_type: !byte WORLD_OVERWORLD
saved_ow_room_x:    !byte START_ROOM_X
saved_ow_room_y:    !byte START_ROOM_Y
saved_ow_player_x:  !word 0
saved_ow_player_y:  !byte 0

apply_map_colors:
        lda map_bg_col
        sta VIC_BACKGROUND
        lda map_mc1_col
        sta VIC_BG_MC1
        lda map_mc2_col
        sta VIC_BG_MC2
        rts

init_video:
        lda #1
        sta CURSOR_FLAG                 ; pas de curseur clignotant
        jsr apply_map_colors
        lda #COL_BLACK
        sta VIC_BORDER
        lda #0
        sta VIC_SPRITE_EXP_X
        sta VIC_SPRITE_EXP_Y
        lda #MEMSETUP_VALUE             ; écran $0400, caractères $2000
        sta VIC_MEMSETUP
        lda VIC_CTRL2
        ora #%00010000                  ; bit 4 : texte multicolore
        sta VIC_CTRL2
        rts

; Remplit l'écran de caractères 0 (fond uni, tuile 0).
; 1000 octets en 4 passes (le dernier bloc recouvre $2e8-$3e7 : surtout pas
; $3f8-$3ff, ce sont les pointeurs de sprites).
clear_screen:
        ldx #0
.loop:
        lda #0
        sta SCREEN_RAM,x
        sta SCREEN_RAM+$100,x
        sta SCREEN_RAM+$200,x
        sta SCREEN_RAM+$2e8,x
        lda #COL_BLACK
        sta COLOR_RAM,x
        sta COLOR_RAM+$100,x
        sta COLOR_RAM+$200,x
        sta COLOR_RAM+$2e8,x
        inx
        bne .loop
        rts

; Charge et dessine la salle désignée par current_room_x / current_room_y
load_room:
        ldx current_room_y
        lda world_row_offset,x
        clc
        adc current_room_x
        sta current_room_idx
        tax
        lda room_tbl_lo,x
        sta ZP_SRC
        lda room_tbl_hi,x
        sta ZP_SRC+1
        jsr decompress_room_main

        ; Application des couleurs de la zone active
        lda current_world_type
        bne .lr_dungeon

        ; Overworld : lecture de la zone (0..3) pour la salle
        ldx current_room_idx
        lda room_zone_palette,x
        sta current_zone
        tax
        lda zone_bg_color,x
        sta VIC_BACKGROUND
        lda zone_mc1_color,x
        sta VIC_BG_MC1
        lda zone_mc2_color,x
        sta VIC_BG_MC2

        ; Copie des 16 couleurs de tuiles actives
        lda zone_color_lo,x
        sta ZP_SRC
        lda zone_color_hi,x
        sta ZP_SRC+1
        ldy #15
.cpy_ow_col:
        lda (ZP_SRC),y
        sta active_tile_color,y
        dey
        bpl .cpy_ow_col
        jmp .lr_draw

.lr_dungeon:
        jsr apply_map_colors
        ldy #15
.cpy_uw_col:
        lda zone_dungeon_tile_color,y
        sta active_tile_color,y
        dey
        bpl .cpy_uw_col

.lr_draw:
        lda #<room_buf
        sta ZP_MAP
        lda #>room_buf
        sta ZP_MAP+1
        jsr draw_map
        rts

; Dessine la salle pointée par ZP_MAP (200 tuiles = 20x10).
; ZP_SCR / ZP_COL pointent sur la ligne 4 de texte (écran / couleur) :
; SCREEN_RAM + 160 ($04A0) et COLOR_RAM + 160 ($D8A0).
; Les lignes 0..3 restent réservées au HUD Zelda.
draw_map:
        lda #<(SCREEN_RAM + 160)
        sta ZP_SCR
        lda #>(SCREEN_RAM + 160)
        sta ZP_SCR+1
        lda #<(COLOR_RAM + 160)
        sta ZP_COL
        lda #>(COLOR_RAM + 160)
        sta ZP_COL+1
        lda #0
        sta ZP_IDX
        lda #MAP_H
        sta ZP_ROW
.row:
        lda #0
        sta ZP_TCOL
.col:
        ldy ZP_IDX
        lda (ZP_MAP),y                  ; numéro de tuile dans la salle courante
        tax
        lda active_tile_color,x
        sta ZP_TMP                      ; couleur (bit 3 = multicolore)
        lda tile_char_base,x
        sta ZP_BASE                     ; premier caractère de la tuile
        lda ZP_TCOL
        asl
        tay                             ; Y = colonne de texte (2 par tuile)

        lda ZP_BASE                     ; haut gauche
        sta (ZP_SCR),y
        lda ZP_TMP
        sta (ZP_COL),y
        iny
        lda ZP_BASE                     ; haut droite
        ora #1
        sta (ZP_SCR),y
        lda ZP_TMP
        sta (ZP_COL),y

        tya                             ; ligne du dessous : +40 colonnes
        clc
        adc #39                         ; (Y est déjà à colonne+1)
        tay
        lda ZP_BASE                     ; bas gauche
        ora #2
        sta (ZP_SCR),y
        lda ZP_TMP
        sta (ZP_COL),y
        iny
        lda ZP_BASE                     ; bas droite
        ora #3
        sta (ZP_SCR),y
        lda ZP_TMP
        sta (ZP_COL),y

        inc ZP_IDX
        inc ZP_TCOL
        lda ZP_TCOL
        cmp #MAP_W
        bne .col

        clc                             ; ligne de tuiles suivante = +80 octets
        lda ZP_SCR
        adc #80
        sta ZP_SCR
        bcc .no_carry_scr
        inc ZP_SCR+1
.no_carry_scr:
        clc
        lda ZP_COL
        adc #80
        sta ZP_COL
        bcc .no_carry_col
        inc ZP_COL+1
.no_carry_col:
        dec ZP_ROW
        bne .row
        rts

; ---------------------------------------------------------------------------
; enter_dungeon : Bascule vers le monde souterrain / Donjon
; ---------------------------------------------------------------------------
enter_dungeon:
        ; 1. Sauvegarde la position Overworld
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

        ; 2. Désactive ennemis, projectiles et objets
        lda #0
        sta en_type
        sta en_type+1
        sta en_proj_active
        sta item_active
        sta player_attacking

        ; 3. Vider l'écran et recharger la carte Donjon
        jsr clear_screen
        jsr disk_load_map_underworld

        ; 4. Placer Link dans la salle d'entrée du Donjon (1, 0)
        lda #1
        sta current_room_x
        lda #0
        sta current_room_y

        lda #160
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

        ; 5. Afficher la salle et les ennemis
        jsr load_room
        jsr enemies_room_init
        lda #STATE_PLAYING
        sta game_state
        rts

; ---------------------------------------------------------------------------
; exit_dungeon : Quitte le donjon et restaure la carte Overworld
; ---------------------------------------------------------------------------
exit_dungeon:
        ; 1. Désactive ennemis et objets
        lda #0
        sta en_type
        sta en_type+1
        sta en_proj_active
        sta item_active
        sta player_attacking

        ; 2. Vider l'écran et recharger la carte Overworld
        jsr clear_screen
        jsr disk_load_map_overworld

        ; 3. Restaurer la salle et la position Overworld de Link
        lda saved_ow_room_x
        sta current_room_x
        lda saved_ow_room_y
        sta current_room_y

        lda saved_ow_player_x
        sta player_x
        lda saved_ow_player_x+1
        sta player_x+1
        lda saved_ow_player_y
        clc
        adc #16                         ; Juste sous l'entrée
        sta player_y
        lda #DIR_DOWN
        sta player_dir
        lda #0
        sta player_walk_anim
        sta player_walk_tick

        ; 4. Afficher la salle et les ennemis
        jsr load_room
        jsr hud_init
        jsr enemies_room_init
        lda #STATE_PLAYING
        sta game_state
        rts

