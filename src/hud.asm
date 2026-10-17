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

hud_cur_line:     !byte 0
hud_cur_col:      !byte 0
hud_base_off:     !byte 0
hud_calc_ry:      !byte 0
hud_calc_rx:      !byte 0

; Noms des objets slot B (4 caractères chacun, 8 objets)
b_item_names:
        !text "BOOM"
        !text "BOMB"
        !text "BOW "
        !text "CAND"
        !text "FOOD"
        !text "POTI"
        !text "FLUT"
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

        ; "-LIFE-"
        lda #'-'
        sta SCREEN_RAM+34
        lda #'L'
        sta SCREEN_RAM+35
        lda #'I'
        sta SCREEN_RAM+36
        lda #'F'
        sta SCREEN_RAM+37
        lda #'E'
        sta SCREEN_RAM+38
        lda #'-'
        sta SCREEN_RAM+39
        lda #COL_YELLOW
        sta COLOR_RAM+34
        sta COLOR_RAM+35
        sta COLOR_RAM+36
        sta COLOR_RAM+37
        sta COLOR_RAM+38
        sta COLOR_RAM+39

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

        ; Ligne 3 : Ligne de séparation (colonnes 8 à 39)
        ldx #8
.sep_line:
        lda #'-'
        sta SCREEN_RAM+120,x
        lda #COL_BLACK
        sta COLOR_RAM+120,x
        inx
        cpx #40
        bne .sep_line

        jsr hud_render
        rts

; ---------------------------------------------------------------------------
; hud_render : met à jour les données dynamiques du HUD
; ---------------------------------------------------------------------------
hud_render:
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

        lda #COL_LIGHT_GREEN
        sta COLOR_RAM+1
        sta COLOR_RAM+2
        sta COLOR_RAM+3
        sta COLOR_RAM+4
        sta COLOR_RAM+5
        sta COLOR_RAM+6
        sta COLOR_RAM+7

.render_map_cells:
        lda current_world_type
        cmp #WORLD_DUNGEON
        bne +
        jmp .render_dungeon_minimap
+

        ; --- Overworld : Radar Hyrule GPS (Lignes 1..3, Cols 1..5) ---
        ; Ligne 1 : "+---+"
        lda #'+'
        sta SCREEN_RAM+41
        sta SCREEN_RAM+45
        lda #'-'
        sta SCREEN_RAM+42
        sta SCREEN_RAM+43
        sta SCREEN_RAM+44
        lda #COL_GREY
        sta COLOR_RAM+41
        sta COLOR_RAM+42
        sta COLOR_RAM+43
        sta COLOR_RAM+44
        sta COLOR_RAM+45

        ; Ligne 2 : "| . |" avec position proportionnelle de Link
        lda #'|'
        sta SCREEN_RAM+81
        sta SCREEN_RAM+85
        lda #' '
        sta SCREEN_RAM+82
        sta SCREEN_RAM+83
        sta SCREEN_RAM+84
        lda #COL_GREY
        sta COLOR_RAM+81
        sta COLOR_RAM+82
        sta COLOR_RAM+83
        sta COLOR_RAM+84
        sta COLOR_RAM+85

        ; Colonne du point vert : 82 + (current_room_x * 3) / 16 (82, 83 ou 84)
        lda current_room_x
        cmp #6
        bcc .ow_dot_c0
        cmp #11
        bcc .ow_dot_c1
        ldx #84
        bne .ow_dot_draw
.ow_dot_c0:
        ldx #82
        bne .ow_dot_draw
.ow_dot_c1:
        ldx #83
.ow_dot_draw:
        lda #HUD_MAP_ACTIVE
        sta SCREEN_RAM,x
        lda #COL_LIGHT_GREEN
        sta COLOR_RAM,x

        ; Ligne 3 : "+---+" et coordonnées de secteur en colonnes 6 et 7
        lda #'+'
        sta SCREEN_RAM+121
        sta SCREEN_RAM+125
        lda #'-'
        sta SCREEN_RAM+122
        sta SCREEN_RAM+123
        sta SCREEN_RAM+124
        lda #COL_GREY
        sta COLOR_RAM+121
        sta COLOR_RAM+122
        sta COLOR_RAM+123
        sta COLOR_RAM+124
        sta COLOR_RAM+125

        ; Secteur en cols 6-7 : Lettre X (A..P) sur Ligne 2, Chiffre Y (1..8) sur Ligne 3
        lda #'A'
        clc
        adc current_room_x
        sta SCREEN_RAM+87
        lda #COL_WHITE
        sta COLOR_RAM+87
        lda #'1'
        clc
        adc current_room_y
        sta SCREEN_RAM+127
        lda #COL_WHITE
        sta COLOR_RAM+127
        jmp .counters

.render_dungeon_minimap:
        ; --- Donjon : Minimap matricielle 5 colonnes x 3 lignes ---
        ; Fenêtre centrée sur Link :
        ;   Ligne 1 : ry = current_room_y - 1 (offset 40)
        ;   Ligne 2 : ry = current_room_y     (offset 80)
        ;   Ligne 3 : ry = current_room_y + 1 (offset 120)
        ;   Cols 1..5 : rx = current_room_x - 2 .. current_room_x + 2
        ; Link est toujours au centre (Col 3, Ligne 2) en jaune brillant !

        ldy #0
        sty hud_cur_line
.map_row_loop:
        ; Calcule ry = current_room_y - 1 + hud_cur_line
        lda current_room_y
        sec
        sbc #1
        clc
        adc hud_cur_line
        sta hud_calc_ry

        ; Calcule offset écran de base pour la ligne (40, 80 ou 120)
        lda hud_cur_line
        beq .row_off_0
        cmp #1
        beq .row_off_1
        lda #120
        bne .row_off_set
.row_off_0:
        lda #40
        bne .row_off_set
.row_off_1:
        lda #80
.row_off_set:
        sta hud_base_off

        ; Boucle sur les 5 colonnes (cols 1..5)
        ldx #0
        stx hud_cur_col
.map_col_loop:
        ; Calcule rx = current_room_x - 2 + hud_cur_col
        lda current_room_x
        sec
        sbc #2
        clc
        adc hud_cur_col
        sta hud_calc_rx

        ; Calcul adresse écran de la cellule : hud_base_off + 1 + hud_cur_col
        lda hud_base_off
        clc
        adc #1
        adc hud_cur_col
        tay                             ; Y = offset écran dans SCREEN_RAM

        ; Vérifie les limites du monde (0 <= rx < 16 et 0 <= ry < 8)
        lda hud_calc_ry
        bmi .cell_blank_jmp
        cmp #8
        bcs .cell_blank_jmp
        lda hud_calc_rx
        bmi .cell_blank_jmp
        cmp #16
        bcc .cell_in_bounds
.cell_blank_jmp:
        jmp .cell_blank
.cell_in_bounds:

        ; Index de la salle = ry * 16 + rx
        tax
        lda world_row_offset,x
        clc
        adc hud_calc_rx
        tax                             ; X = index salle (0..127)

        ; Si c'est la salle actuelle de Link -> HUD_MAP_ACTIVE en Jaune
        lda hud_calc_rx
        cmp current_room_x
        bne .chk_cell_triforce
        lda hud_calc_ry
        cmp current_room_y
        bne .chk_cell_triforce
        lda #HUD_MAP_ACTIVE
        sta SCREEN_RAM,y
        lda #COL_YELLOW
        sta COLOR_RAM,y
        jmp .next_col

.chk_cell_triforce:
        ; Si joueur a la boussole et c'est la salle de la Triforce -> Rouge
        lda player_has_compass
        beq .chk_cell_visited
        lda current_dungeon_level
        beq .chk_cell_visited
        sec
        sbc #1
        cmp #9
        bcs .chk_cell_visited
        pha
        txa
        pha
        lda current_dungeon_level
        sec
        sbc #1
        tax
        lda dungeon_triforce_rooms,x
        sta ZP_TMP
        pla
        tax
        pla
        cpx ZP_TMP
        bne .chk_cell_visited
        lda #HUD_MAP_ACTIVE
        sta SCREEN_RAM,y
        lda #COL_LIGHT_RED
        sta COLOR_RAM,y
        jmp .next_col

.chk_cell_visited:
        ; Si la salle a été visitée -> HUD_MAP_VISITED en Cyan
        lda visited_uw_rooms,x
        beq .chk_cell_mapped
        lda #HUD_MAP_VISITED
        sta SCREEN_RAM,y
        lda #COL_CYAN
        sta COLOR_RAM,y
        jmp .next_col

.chk_cell_mapped:
        ; Si joueur a la carte du donjon -> HUD_MAP_EMPTY en Gris foncé
        lda player_has_dungeon_map
        beq .cell_blank
        lda #HUD_MAP_EMPTY
        sta SCREEN_RAM,y
        lda #COL_DARK_GREY
        sta COLOR_RAM,y
        jmp .next_col

.cell_blank:
        lda #' '
        sta SCREEN_RAM,y
        lda #COL_BLACK
        sta COLOR_RAM,y

.next_col:
        inc hud_cur_col
        lda hud_cur_col
        cmp #5
        bcs +
        jmp .map_col_loop
+

        ; Nettoie cols 6 et 7 de cette ligne
        lda hud_base_off
        clc
        adc #6
        tay
        lda #' '
        sta SCREEN_RAM,y
        sta SCREEN_RAM+1,y
        lda #COL_BLACK
        sta COLOR_RAM,y
        sta COLOR_RAM+1,y

        inc hud_cur_line
        lda hud_cur_line
        cmp #3
        bcs +
        jmp .map_row_loop
+

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

        ; 4. Barre de vie (Cœurs) : ligne 1, colonne 34..38
        ldx #0
.heart_loop:
        cpx hud_cur_hearts
        bcs .empty_heart
        lda #HUD_HEART_FULL
        jmp .draw_heart
.empty_heart:
        lda #HUD_HEART_EMPTY
.draw_heart:
        sta SCREEN_RAM+40+35,x
        lda #COL_RED                    ; cœurs rouge vif
        sta COLOR_RAM+40+35,x
        inx
        cpx hud_max_hearts
        bne .heart_loop
        rts

; Convertit A (0..99) en 2 caractères ASCII (dizaines dans A, unités dans X)
print_2digits:
        ldx #0
.div10:
        cmp #10
        bcc .done10
        sec
        sbc #10
        inx
        jmp .div10
.done10:
        tay                             ; Y = unités (0..9)
        txa
        clc
        adc #'0'                        ; A = dizaines ASCII
        pha
        tya
        clc
        adc #'0'
        tax                             ; X = unités ASCII
        pla
        rts

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

