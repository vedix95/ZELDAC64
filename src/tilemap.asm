; ---------------------------------------------------------------------------
; tilemap.asm : affichage de la carte en tuiles 16x16 (2x2 caractères)
; Mode texte multicolore + jeu de caractères perso (src/charset.asm).
; Tuile N = caractères 4N (HG), 4N+1 (HD), 4N+2 (BG), 4N+3 (BD).
; La carte (20x12 tuiles) couvre les 24 premières lignes de texte ; la 25e
; reste vide (caractère 0 = fond uni).
; ---------------------------------------------------------------------------

START_ROOM_X    = 1
START_ROOM_Y    = 1

current_room_x:   !byte START_ROOM_X
current_room_y:   !byte START_ROOM_Y
current_room_idx: !byte 0

init_video:
        lda #1
        sta CURSOR_FLAG                 ; pas de curseur clignotant
        lda #MAP_BG_COLOR
        sta VIC_BACKGROUND
        lda #MAP_MC1_COLOR
        sta VIC_BG_MC1
        lda #MAP_MC2_COLOR
        sta VIC_BG_MC2
        lda #COL_BLACK
        sta VIC_BORDER
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
        sta ZP_MAP
        lda room_tbl_hi,x
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
        lda tile_color,x
        sta ZP_TMP                      ; couleur (bit 3 = multicolore)
        txa
        asl
        asl
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
