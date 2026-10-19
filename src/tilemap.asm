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

current_world_type:     !byte WORLD_OVERWORLD
saved_ow_room_x:        !byte START_ROOM_X
saved_ow_room_y:        !byte START_ROOM_Y
saved_ow_player_x:      !word 0
saved_ow_player_y:      !byte 0
current_dungeon_level:   !byte 1
dungeon_entrance_room_x: !byte 3
dungeon_entrance_room_y: !byte 7
active_bg_color:        !byte COL_BLACK

apply_map_colors:
        lda map_bg_col
        sta active_bg_color
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
        lda current_world_type
        bne +
        jsr disk_ensure_ow_chunk
+       ldx current_room_y
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
        jsr dungeon_apply_room_state_active

        ; Restauration des grottes secrètes déjà ouvertes à la bombe
        lda current_world_type
        bne +
        ldx current_room_idx
        txa
        lsr
        lsr
        lsr
        tax
        lda current_room_idx
        and #7
        tay
        lda bit_powers,y
        and overworld_secrets_opened,x
        beq +

        ldy #199
-       lda room_buf,y
        cmp #TILE_WALL_BOMB
        bne .sk_bomb_conv
        lda #TILE_CAVE
        sta room_buf,y
.sk_bomb_conv:
        dey
        bpl -
+
        ; Application des couleurs de la zone active
        lda current_world_type
        bne .lr_dungeon

        ; Overworld : lecture de la zone (0..3) pour la salle
        ldx current_room_idx
        lda room_zone_palette,x
        sta current_zone
        tax
        lda zone_bg_color,x
        sta active_bg_color
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
        jsr apply_dungeon_colors
        jmp .lr_draw

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


; --- Palettes et Couleurs des 9 Donjons de Zelda 1 ---
dungeon_mc1_table:
        !byte 3, 6, 5, 15, 2, 8, 5, 14, 2       ; Cyan, Bleu, Vert, Gris, Rouge, Orange, Vert, Bleu clair, Rouge sombre
dungeon_wall_color:
        !byte 11, 14, 13, 23, 10, 16, 13, 22, 10
base_dungeon_tile_color:
        !byte 8, 19, 10, 11, 14, 11, 20, 8, 8, 8, 8, 11, 11, 0, 0, 0

apply_dungeon_colors:
        lda #COL_BLACK
        sta active_bg_color
        sta VIC_BACKGROUND
        ldx current_dungeon_level
        dex
        cpx #9
        bcc +
        ldx #0
+       lda dungeon_mc1_table,x
        sta VIC_BG_MC1
        lda #14                         ; Light Blue pour MC2 (reflets, murs et portes)
        sta VIC_BG_MC2

        ; Couleur individuelle des tuiles en mode multicolore : Bleu (6) + 8 = 14
        lda #14
        ldy #15
-       sta active_tile_color,y
        dey
        bpl -
        rts

; ===========================================================================
; TABLE DES 128 SALLES DE L'OVERWORLD VERS LES 9 DONJONS (Niveau 1..9)
; 0 = pas de donjon
; ===========================================================================
dungeon_room_levels:
        ; Rangée 0 (0..15 : A-1 .. P-1) - Salle 4: N9, Salle 10: N5
        !byte 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0
        ; Rangée 1 (16..31 : A-2 .. P-2) - Salle 20: N6
        !byte 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        ; Rangée 2 (32..47 : A-3 .. P-3) - Salle 34: N4
        !byte 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        ; Rangée 3 (48..63 : A-4 .. P-4) - Salle 51: N7, Salle 55: N1, Salle 60: N2, Salle 62: N8
        !byte 0, 0, 0, 7, 0, 0, 0, 1, 0, 0, 0, 0, 2, 0, 8, 0
        ; Rangée 4 (64..79 : A-5 .. P-5) - Salle 68: N3
        !byte 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        ; Rangée 5 (80..95 : A-6 .. P-6)
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        ; Rangée 6 (96..111 : A-7 .. P-7)
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        ; Rangée 7 (112..127 : A-8 .. P-8)
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

dungeon_start_rx:
        !byte 3, 13, 12, 1, 6, 9, 9, 14, 6
dungeon_start_ry:
        !byte 7,  7,  7, 7, 7, 7, 7,  7, 7

; ---------------------------------------------------------------------------
; enter_dungeon : Bascule vers le monde souterrain / Donjon (Niveaux 1 à 9)
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

        ; 3. Détermine le Niveau de Donjon (1..9)
        lda current_dungeon_level
        bne +
        lda #1
        sta current_dungeon_level
+
        ; 4. Vider l'écran et charger le Donjon depuis la disquette
        jsr clear_screen
        jsr disk_load_dungeon
        lda current_dungeon_level
        cmp dungeon_active_level
        beq +
        jsr dungeon_init
+

        ; 5. Positionne Link dans la salle d'entrée du Donjon
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

        ; Lance la musique authentique du Donjon (Underworld)
        lda #MUSIC_DUNGEON
        jsr music_play

        ; 5. Afficher la salle et les ennemis
        jsr load_room
        jsr hud_init
        jsr enemies_room_init
        jsr dungeon_on_enter_room
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

        ; 2. Restaurer la salle et la position Overworld de Link avant chargement du chunk
        lda saved_ow_room_x
        sta current_room_x
        lda saved_ow_room_y
        sta current_room_y

        ; 3. Vider l'écran et recharger le chunk Overworld actif
        jsr clear_screen
        jsr disk_load_map_overworld

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

        ; Relance la musique héroïque de l'Overworld
        lda #MUSIC_OVERWORLD
        jsr music_play

        ; 4. Afficher la salle et les ennemis
        jsr load_room
        jsr hud_init
        jsr enemies_room_init
        lda #STATE_PLAYING
        sta game_state
        rts

; ---------------------------------------------------------------------------
; redraw_single_tile : redessine immédiatement la tuile Y (2x2 caractères) à l'écran
; Entrée : Y = index de la tuile dans room_buf (0..199)
; ---------------------------------------------------------------------------
redraw_single_tile:
        sty ZP_TMP
        ; Calcul tile_y = ZP_TMP / 20 et tile_x = ZP_TMP % 20
        ldx #0
        lda ZP_TMP
.div20_loop:
        cmp #20
        bcc .div20_done
        sec
        sbc #20
        inx
        jmp .div20_loop
.div20_done:
        ; X = tile_y (0..9), A = tile_x (0..19)
        asl                             ; A = tile_x * 2 (colonne texte 0..38)
        sta ZP_TCOL

        ; Pointeur écran ligne haute
        lda tile_y_scr_lo,x
        clc
        adc ZP_TCOL
        sta ZP_SCR
        sta ZP_COL
        lda tile_y_scr_hi,x
        adc #0
        sta ZP_SCR+1
        clc
        adc #>(COLOR_RAM - SCREEN_RAM)  ; + $D4 ($04 -> $D8)
        sta ZP_COL+1

        ; Données de la tuile
        ldy ZP_TMP
        lda room_buf,y
        tax
        lda active_tile_color,x
        sta ZP_TMP                      ; couleur
        lda tile_char_base,x
        sta ZP_BASE                     ; caractère base

        ; Caractères haut-gauche et haut-droite
        ldy #0
        lda ZP_BASE
        sta (ZP_SCR),y
        lda ZP_TMP
        sta (ZP_COL),y
        iny
        lda ZP_BASE
        ora #1
        sta (ZP_SCR),y
        lda ZP_TMP
        sta (ZP_COL),y

        ; Pointeur ligne basse (+40 colonnes)
        lda ZP_SCR
        clc
        adc #40
        sta ZP_SCR
        sta ZP_COL
        bcc +
        inc ZP_SCR+1
        inc ZP_COL+1
+
        ldy #0
        lda ZP_BASE
        ora #2
        sta (ZP_SCR),y
        lda ZP_TMP
        sta (ZP_COL),y
        iny
        lda ZP_BASE
        ora #3
        sta (ZP_SCR),y
        lda ZP_TMP
        sta (ZP_COL),y
        rts

tile_y_scr_lo:
        !byte <(SCREEN_RAM + 160 + 0*80)
        !byte <(SCREEN_RAM + 160 + 1*80)
        !byte <(SCREEN_RAM + 160 + 2*80)
        !byte <(SCREEN_RAM + 160 + 3*80)
        !byte <(SCREEN_RAM + 160 + 4*80)
        !byte <(SCREEN_RAM + 160 + 5*80)
        !byte <(SCREEN_RAM + 160 + 6*80)
        !byte <(SCREEN_RAM + 160 + 7*80)
        !byte <(SCREEN_RAM + 160 + 8*80)
        !byte <(SCREEN_RAM + 160 + 9*80)

tile_y_scr_hi:
        !byte >(SCREEN_RAM + 160 + 0*80)
        !byte >(SCREEN_RAM + 160 + 1*80)
        !byte >(SCREEN_RAM + 160 + 2*80)
        !byte >(SCREEN_RAM + 160 + 3*80)
        !byte >(SCREEN_RAM + 160 + 4*80)
        !byte >(SCREEN_RAM + 160 + 5*80)
        !byte >(SCREEN_RAM + 160 + 6*80)
        !byte >(SCREEN_RAM + 160 + 7*80)
        !byte >(SCREEN_RAM + 160 + 8*80)
        !byte >(SCREEN_RAM + 160 + 9*80)

overworld_secrets_opened:
        !fill 16, 0

bit_powers:
        !byte 1, 2, 4, 8, 16, 32, 64, 128

