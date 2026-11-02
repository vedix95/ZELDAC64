; ---------------------------------------------------------------------------
; hud.asm : affichage du HUD Zelda en haut de l'écran (lignes 0..3)
; Comprend :
;   - Minimap 3x3 avec indicateur de salle active
;   - Compteurs d'inventaire : Rubis, Clefs, Bombes
;   - Boîtes d'armes équipées : [B] Objet secondaire, [A] Épée
;   - Barre de vie (-LIFE-) avec cœurs rouges
;   - Ligne de séparation
; ---------------------------------------------------------------------------

HUD_ROW_MAP     = 0
HUD_ROW_B_A     = 0
HUD_ROW_LIFE    = 0

HUD_HEART_FULL  = 96                    ; code caractère coeur plein ♥
HUD_HEART_EMPTY = 97                    ; code caractère coeur vide ♡
HUD_CHAR_RUPEE  = 98                    ; code caractère rubis ◆
HUD_CHAR_KEY    = 99                    ; code caractère clef
HUD_CHAR_BOMB   = 100                   ; code caractère bombe
HUD_MAP_EMPTY   = 104                   ; salle non visitée
HUD_MAP_ACTIVE  = 105                   ; salle active (plein)
HUD_MAP_VISITED = 106                   ; salle visitée (cadre)
HUD_MAP_CHAR_0  = 107                   ; minimap Ligne 1, Col 2 ($2358)
HUD_MAP_CHAR_1  = 108                   ; minimap Ligne 1, Col 3 ($2360)
HUD_MAP_CHAR_2  = 109                   ; minimap Ligne 1, Col 4 ($2368)
HUD_MAP_CHAR_3  = 110                   ; minimap Ligne 1, Col 5 ($2370)
HUD_MAP_CHAR_4  = 111                   ; minimap Ligne 2, Col 2 ($2378)
HUD_MAP_CHAR_5  = 112                   ; minimap Ligne 2, Col 3 ($2380)
HUD_MAP_CHAR_6  = 113                   ; minimap Ligne 2, Col 4 ($2388)
HUD_MAP_CHAR_7  = 114                   ; minimap Ligne 2, Col 5 ($2390)

hud_rupees:       !byte 15              ; rubis initiaux
hud_keys:         !byte 1               ; clefs initiales
hud_bombs:        !byte 4               ; bombes initiales
hud_max_hearts:   !byte 3               ; 3 cœurs max
hud_cur_hearts:   !byte 3               ; 3 cœurs actuels
hud_selected_b:   !byte 0               ; 0: Boomerang, 1: Bombe, 2: Arc, 3: Bougie

; Salles visitées (128 octets pour Overworld et 128 octets pour Donjons)
visited_rooms:
visited_ow_rooms: !fill 128, 0
visited_uw_rooms: !fill 128, 0

hud_blink_tick:   !byte 0
minimap_rx:       !byte 0
minimap_ry:       !byte 0

; Décalages pour centrer chaque Donjon (1..9) dans le canevas 16x8
dung_shift_x:
        !byte 4, $f9, $fc, 5, 2, $fd, $fd, $fa, 3       ; +4, -7, -4, +5, +2, -3, -3, -6, +3
dung_shift_y:
        !byte $ff, 0, $fe, 0, $ff, 0, $ff, $ff, $ff     ; -1, 0, -2, 0, -1, 0, -1, -1, -1

; Coordonnées de la salle Triforce pour chaque Donjon (1..9)
dungeon_tri_px:
        !byte 10, 6, 9, 8, 6, 9, 8, 6, 5
dungeon_tri_py:
        !byte 2, 0, 1, 0, 0, 0, 1, 1, 2

; Masques pour blocs de salle 2x2 pixels
room_mask_2x2:
        !byte %11000000, %00110000, %00001100, %00000011
room_mask_2x2_inv:
        !byte %00111111, %11001111, %11110011, %11111100

; Noms des objets slot B (4 caractères chacun, 8 objets)
b_item_names:
        !text "BOOM"
        !text "BOMB"
        !text "BOW "
        !text "CAND"
        !text "FLUT"
        !text "FOOD"
        !text "POTI"
        !text "WAND"

; ---------------------------------------------------------------------------
; hud_init : initialise le cadre complet du HUD
; ---------------------------------------------------------------------------
hud_init:
        ; Efface les 4 premières lignes en noir/blanc
        ldx #0
.clear_hud:
        lda #32                         ; espace
        sta SCREEN_RAM,x
        lda #COL_WHITE
        sta COLOR_RAM,x
        inx
        cpx #160                        ; 4 lignes x 40 colonnes = 160 octets
        bne .clear_hud

        ; Ligne 0 : Titres dynamiques gérés par hud_render (LEVEL-N / HYRULE)

        ; "RUPEES"
        lda #'R'
        sta SCREEN_RAM+9
        lda #'U'
        sta SCREEN_RAM+10
        lda #'P'
        sta SCREEN_RAM+11
        lda #'E'
        sta SCREEN_RAM+12
        lda #'E'
        sta SCREEN_RAM+13
        lda #'S'
        sta SCREEN_RAM+14

        ; Boîte [A] (Arme secondaire)
        lda #'['
        sta SCREEN_RAM+21
        lda #'A'
        sta SCREEN_RAM+22
        lda #']'
        sta SCREEN_RAM+23

        ; Boîte [X] (Épée)
        lda #'['
        sta SCREEN_RAM+27
        lda #'X'
        sta SCREEN_RAM+28
        lda #']'
        sta SCREEN_RAM+29

        ; "-LIFE-" (Cols 32..37 de la Ligne 0, centré au-dessus des 8 cœurs)
        lda #'-'
        sta SCREEN_RAM+32
        lda #'L'
        sta SCREEN_RAM+33
        lda #'I'
        sta SCREEN_RAM+34
        lda #'F'
        sta SCREEN_RAM+35
        lda #'E'
        sta SCREEN_RAM+36
        lda #'-'
        sta SCREEN_RAM+37
        lda #COL_YELLOW
        sta COLOR_RAM+32
        sta COLOR_RAM+33
        sta COLOR_RAM+34
        sta COLOR_RAM+35
        sta COLOR_RAM+36
        sta COLOR_RAM+37

        ; Ligne 1 : Labels
        lda #'K'
        sta SCREEN_RAM+40+9
        lda #'E'
        sta SCREEN_RAM+40+10
        lda #'Y'
        sta SCREEN_RAM+40+11
        lda #'S'
        sta SCREEN_RAM+40+12

        ; Ligne 2 : Labels
        lda #'B'
        sta SCREEN_RAM+80+9
        lda #'O'
        sta SCREEN_RAM+80+10
        lda #'M'
        sta SCREEN_RAM+80+11
        lda #'B'
        sta SCREEN_RAM+80+12
        lda #'S'
        sta SCREEN_RAM+80+13

        ; Épée dans le slot X : dynamique selon player_has_sword
        jsr hud_update_sword

        ; Minimap sur Ligne 1 et Ligne 2 (colonnes 2..5) : 4x2 caractères = 32x16 pixels
        jsr hud_setup_map_cells

        ; Espaces noirs autour de la minimap
        lda #32
        sta SCREEN_RAM+40+0
        sta SCREEN_RAM+40+1
        sta SCREEN_RAM+40+6
        sta SCREEN_RAM+40+7
        sta SCREEN_RAM+40+8
        sta SCREEN_RAM+80+0
        sta SCREEN_RAM+80+1
        sta SCREEN_RAM+80+6
        sta SCREEN_RAM+80+7
        sta SCREEN_RAM+80+8
        lda #COL_BLACK
        sta COLOR_RAM+40+0
        sta COLOR_RAM+40+1
        sta COLOR_RAM+40+6
        sta COLOR_RAM+40+7
        sta COLOR_RAM+40+8
        sta COLOR_RAM+80+0
        sta COLOR_RAM+80+1
        sta COLOR_RAM+80+6
        sta COLOR_RAM+80+7
        sta COLOR_RAM+80+8

        ; Ligne 3 : Entièrement noire et vide (séparation propre sans aucun trait)
        ldx #0
.clr_row3:
        lda #32
        sta SCREEN_RAM+120,x
        lda #COL_BLACK
        sta COLOR_RAM+120,x
        inx
        cpx #40
        bne .clr_row3

        jsr hud_render
        rts

; ---------------------------------------------------------------------------
; hud_render : met à jour les données dynamiques du HUD
; ---------------------------------------------------------------------------
hud_render:
        lda #32
        sta SCREEN_RAM+0
        lda #COL_BLACK
        sta COLOR_RAM+0

        ; 1. Mise à jour de la position de la carte (16x8)
        ; Marque la salle active comme visitée dans la table appropriée
        ldx current_room_y
        lda world_row_offset,x
        clc
        adc current_room_x
        tax
        lda #1
        ldy current_world_type
        bne +
        sta visited_ow_rooms,x
        jmp ++
+       sta visited_uw_rooms,x
++

        ; --- En-tête Ligne 0 (Cols 1..7) ---
        lda current_world_type
        cmp #WORLD_DUNGEON
        bne .hud_hdr_ow

        ; Donjon : "LEVEL-X" (ex: LEVEL-1)
        lda #'L'
        sta SCREEN_RAM+1
        lda #'E'
        sta SCREEN_RAM+2
        lda #'V'
        sta SCREEN_RAM+3
        lda #'E'
        sta SCREEN_RAM+4
        lda #'L'
        sta SCREEN_RAM+5
        lda #'-'
        sta SCREEN_RAM+6
        lda #'0'
        clc
        adc current_dungeon_level
        sta SCREEN_RAM+7

        lda #COL_WHITE
        sta COLOR_RAM+1
        sta COLOR_RAM+2
        sta COLOR_RAM+3
        sta COLOR_RAM+4
        sta COLOR_RAM+5
        sta COLOR_RAM+6
        sta COLOR_RAM+7
        jmp .render_map_cells

.hud_hdr_ow:
        ; Overworld : "HYRULE "
        lda #'H'
        sta SCREEN_RAM+1
        lda #'Y'
        sta SCREEN_RAM+2
        lda #'R'
        sta SCREEN_RAM+3
        lda #'U'
        sta SCREEN_RAM+4
        lda #'L'
        sta SCREEN_RAM+5
        lda #'E'
        sta SCREEN_RAM+6
        lda #' '
        sta SCREEN_RAM+7

        lda #COL_WHITE
        sta COLOR_RAM+1
        sta COLOR_RAM+2
        sta COLOR_RAM+3
        sta COLOR_RAM+4
        sta COLOR_RAM+5
        sta COLOR_RAM+6
        sta COLOR_RAM+7

.render_map_cells:
        ; Garantit que les 8 caractères minimap sont en place sur Lignes 1 & 2 (cols 2..5)
        jsr hud_setup_map_cells

        ; Efface le tampon minimap_buf (64 octets) en RAM, SANS toucher à $2358..$2397
        ldx #63
        lda #0
-       sta minimap_buf,x
        dex
        bpl -

        lda current_world_type
        cmp #WORLD_DUNGEON
        beq .render_uw_minimap

        ; --- OVERWORLD MINIMAP (16x8 salles = 32x16 pixels, 2x2 par salle) ---
        ldx #0
.ow_room_loop:
        lda visited_ow_rooms,x
        beq .ow_room_next
        stx ZP_SRC
        txa
        and #$0f
        sta minimap_rx
        txa
        lsr
        lsr
        lsr
        lsr
        sta minimap_ry
        jsr minimap_buf_set_room_2x2
        ldx ZP_SRC
.ow_room_next:
        inx
        cpx #128
        bne .ow_room_loop
        jmp .minimap_commit

        ; ===================================================================
        ; MINIMAP SOUS-SOL / DONJONS (2x2 pixels par salle, centré dans 32x16)
        ; ===================================================================
.render_uw_minimap:
        lda current_dungeon_level
        bne +
        lda #1
        sta current_dungeon_level
+
        ; Affiche les salles du donjon dans minimap_buf
        ldx #0
.uw_room_loop:
        lda player_has_dungeon_map
        bne .uw_has_map_check

        ; Pas de carte : vérifie si la salle a été visitée
        lda visited_uw_rooms,x
        beq .uw_room_next
        jmp .uw_draw_one_room

.uw_has_map_check:
        ; Avec carte : affiche toutes les salles réelles du donjon
        ; (room_tbl_lo à $C016 : salle valide si != salle $00)
        lda $c016,x
        cmp $c016                       ; salle $00 = dummy_sealed_room
        beq .uw_room_next

.uw_draw_one_room:
        stx ZP_SRC
        txa
        and #$0f
        sta ZP_TMP                      ; rx = X & 15
        txa
        lsr
        lsr
        lsr
        lsr
        sta ZP_TMP+1                    ; ry = X >> 4

        ldy current_dungeon_level
        dey
        lda ZP_TMP
        clc
        adc dung_shift_x,y
        bmi .uw_room_skip
        cmp #16
        bcs .uw_room_skip
        sta minimap_rx

        lda ZP_TMP+1
        clc
        adc dung_shift_y,y
        bmi .uw_room_skip
        cmp #8
        bcs .uw_room_skip
        sta minimap_ry

        jsr minimap_buf_set_room_2x2

.uw_room_skip:
        ldx ZP_SRC
.uw_room_next:
        inx
        cpx #128
        bne .uw_room_loop

.minimap_commit:
        ; Copie atomique de minimap_buf vers la RAM caractères VIC-II ($2358..$2397)
        ldx #63
-       lda minimap_buf,x
        sta $2358,x
        dex
        bpl -

        ; Applique immédiatement l'état courant du clignotement
        jsr hud_apply_blink
        jmp .counters

; ---------------------------------------------------------------------------
; hud_blink_update : appelé chaque frame dans main_loop (sans reconstruire
; toute la minimap) pour faire clignoter uniquement le carré 2x2 de Link
; et celui de la Triforce sans aucun clignotement/tearing de la carte.
; ---------------------------------------------------------------------------
hud_blink_update:
        inc hud_blink_tick
hud_apply_blink:
        lda current_world_type
        cmp #WORLD_DUNGEON
        beq .blink_uw

        ; Overworld : position de Link
        lda current_room_x
        sta minimap_rx
        lda current_room_y
        sta minimap_ry
        lda hud_blink_tick
        and #%00010000
        bne .blink_ow_on
        jmp minimap_clear_room_2x2
.blink_ow_on:
        jmp minimap_set_room_2x2

.blink_uw:
        lda current_dungeon_level
        bne +
        lda #1
        sta current_dungeon_level
+       ldy current_dungeon_level
        dey
        lda current_room_x
        clc
        adc dung_shift_x,y
        sta minimap_rx
        lda current_room_y
        clc
        adc dung_shift_y,y
        sta minimap_ry

        lda hud_blink_tick
        and #%00010000
        bne +
        jsr minimap_clear_room_2x2
        jmp ++
+       jsr minimap_set_room_2x2
++
        lda player_has_compass
        beq .blink_done
        ldy current_dungeon_level
        dey
        lda dungeon_tri_px,y
        sta minimap_rx
        lda dungeon_tri_py,y
        sta minimap_ry
        lda hud_blink_tick
        and #%00010000
        bne +
        jmp minimap_set_room_2x2
+       jmp minimap_clear_room_2x2
.blink_done:
        rts

; ---------------------------------------------------------------------------
; hud_setup_map_cells : Place les 8 caractères et couleurs du canvas minimap
; ---------------------------------------------------------------------------
hud_setup_map_cells:
        ldx #3
-       txa
        clc
        adc #HUD_MAP_CHAR_0
        sta SCREEN_RAM+40+2,x
        adc #4
        sta SCREEN_RAM+80+2,x
        lda #COL_CYAN
        sta COLOR_RAM+40+2,x
        sta COLOR_RAM+80+2,x
        dex
        bpl -
        rts

; ---------------------------------------------------------------------------
; minimap_calc_offset : calcule l'offset X dans $2358 (0..62) et Y = index masque
; Entrées : minimap_rx (0..15), minimap_ry (0..7)
; ---------------------------------------------------------------------------
minimap_calc_offset:
        lda minimap_ry
        and #%00000100
        lsr                             ; bit 2 -> bit 1
        asl
        asl
        asl
        asl                             ; char_row * 32 (0 ou 32)
        sta ZP_TMP

        lda minimap_rx
        lsr
        lsr                             ; char_col (0..3)
        asl
        asl
        asl                             ; * 8 (0, 8, 16, 24)
        clc
        adc ZP_TMP
        sta ZP_TMP

        lda minimap_ry
        and #%00000011                  ; ry & 3 (0..3)
        asl                             ; * 2 (0, 2, 4, 6)
        clc
        adc ZP_TMP
        tax                             ; X = offset dans $2358

        lda minimap_rx
        and #%00000011
        tay                             ; Y = index masque (0..3)
        rts

minimap_buf_set_room_2x2:
        lda minimap_rx
        cmp #16
        bcs .bset_ret
        lda minimap_ry
        cmp #8
        bcs .bset_ret
        jsr minimap_calc_offset
        lda room_mask_2x2,y
        ora minimap_buf,x
        sta minimap_buf,x
        lda room_mask_2x2,y
        ora minimap_buf+1,x
        sta minimap_buf+1,x
.bset_ret:
        rts

minimap_set_room_2x2:
        lda minimap_rx
        cmp #16
        bcs .set_ret
        lda minimap_ry
        cmp #8
        bcs .set_ret
        jsr minimap_calc_offset
        lda room_mask_2x2,y
        ora $2358,x
        sta $2358,x
        lda room_mask_2x2,y
        ora $2359,x
        sta $2359,x
.set_ret:
        rts

minimap_clear_room_2x2:
        lda minimap_rx
        cmp #16
        bcs .clr_ret
        lda minimap_ry
        cmp #8
        bcs .clr_ret
        jsr minimap_calc_offset
        lda room_mask_2x2_inv,y
        and $2358,x
        sta $2358,x
        lda room_mask_2x2_inv,y
        and $2359,x
        sta $2359,x
.clr_ret:
        rts

minimap_buf:
        !fill 64, 0

.counters:

        ; 2. Compteurs avec icônes Zelda en colonne 16
        ; Rubis : icône losange ◆ + compteur 2 chiffres
        lda #HUD_CHAR_RUPEE
        sta SCREEN_RAM+16
        lda hud_rupees
        jsr print_2digits
        sta SCREEN_RAM+17
        stx SCREEN_RAM+18
        lda #COL_YELLOW
        sta COLOR_RAM+16
        sta COLOR_RAM+17
        sta COLOR_RAM+18

        ; Clefs : icône clef + compteur
        lda #HUD_CHAR_KEY
        sta SCREEN_RAM+40+16
        lda hud_keys
        jsr print_2digits
        sta SCREEN_RAM+40+17
        stx SCREEN_RAM+40+18
        lda #COL_WHITE
        sta COLOR_RAM+40+16
        sta COLOR_RAM+40+17
        sta COLOR_RAM+40+18

        ; Bombes : icône bombe + compteur
        lda #HUD_CHAR_BOMB
        sta SCREEN_RAM+80+16
        lda hud_bombs
        jsr print_2digits
        sta SCREEN_RAM+80+17
        stx SCREEN_RAM+80+18
        lda #COL_CYAN
        sta COLOR_RAM+80+16
        lda #COL_WHITE
        sta COLOR_RAM+80+17
        sta COLOR_RAM+80+18

        ; 3. Slot B (Objet secondaire équipé) : ligne 1, colonne 21..24
        lda hud_selected_b
        asl
        asl                             ; index * 4
        tax
        ldy #0
.put_b_name:
        lda b_item_names,x
        sta SCREEN_RAM+40+21,y
        lda #COL_YELLOW
        sta COLOR_RAM+40+21,y
        inx
        iny
        cpy #4
        bne .put_b_name

        ; 4. Barre de vie (Cœurs) : 2 rangées de 8 (cols 31..38 sur Ligne 1 et Ligne 2)
        ldx #0
-       lda #32
        sta SCREEN_RAM+40+31,x
        sta SCREEN_RAM+80+31,x
        lda #COL_BLACK
        sta COLOR_RAM+40+31,x
        sta COLOR_RAM+80+31,x
        inx
        cpx #8
        bne -

        ldx #0
.heart_loop:
        cpx hud_cur_hearts
        bcs .empty_heart
        lda #HUD_HEART_FULL
        jmp .draw_heart
.empty_heart:
        lda #HUD_HEART_EMPTY
.draw_heart:
        cpx #8
        bcs .heart_row2
        ; Rangée 1 : cœurs 0..7
        sta SCREEN_RAM+40+31,x
        lda #COL_RED
        sta COLOR_RAM+40+31,x
        jmp .heart_next
.heart_row2:
        ; Rangée 2 : cœurs 8..15
        pha
        txa
        sec
        sbc #8
        tay
        pla
        sta SCREEN_RAM+80+31,y
        lda #COL_RED
        sta COLOR_RAM+80+31,y
.heart_next:
        inx
        cpx hud_max_hearts
        bne .heart_loop
        jsr hud_update_sword
        rts

; Convertit A (0..99) en 2 caractères ASCII (dizaines dans A, unités dans X)
; Préserve le registre Y intact.
print_2digits:
        cmp #100
        bcc +
        lda #99
+       ldx #0
.div10:
        cmp #10
        bcc .done10
        sec
        sbc #10
        inx
        jmp .div10
.done10:
        ora #'0'
        sta .units_tmp
        txa
        ora #'0'
        ldx .units_tmp
        rts
.units_tmp: !byte 0

; ---------------------------------------------------------------------------
; hud_update_sword : affiche "SWOR" si Link a l'épée, ou blanc sinon
; ---------------------------------------------------------------------------
hud_update_sword:
        lda player_has_sword
        bne .show_sword
        lda #32                         ; espace
        sta SCREEN_RAM+40+27
        sta SCREEN_RAM+40+28
        sta SCREEN_RAM+40+29
        sta SCREEN_RAM+40+30
        rts
.show_sword:
        lda #'S'
        sta SCREEN_RAM+40+27
        lda #'W'
        sta SCREEN_RAM+40+28
        lda #'O'
        sta SCREEN_RAM+40+29
        lda #'R'
        sta SCREEN_RAM+40+30
        lda #COL_CYAN
        sta COLOR_RAM+40+27
        sta COLOR_RAM+40+28
        sta COLOR_RAM+40+29
        sta COLOR_RAM+40+30
        rts

