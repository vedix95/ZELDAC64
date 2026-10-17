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

; Salles visitées (128 octets pour la grille 16x8, 1 = visitée)
visited_rooms:    !fill 128, 0

; Coordonnées écran pour chaque cellule de la minimap 3x3
hud_map_offsets:
        !byte 41, 43, 45                ; ry = 0 (ligne 1, cols 1, 3, 5)
        !byte 81, 83, 85                ; ry = 1 (ligne 2, cols 1, 3, 5)
        !byte 121, 123, 125             ; ry = 2 (ligne 3, cols 1, 3, 5)

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

        ; Ligne 0 : Titres
        ; "[MAP]"
        lda #'['
        sta SCREEN_RAM+1
        lda #'M'
        sta SCREEN_RAM+2
        lda #'A'
        sta SCREEN_RAM+3
        lda #'P'
        sta SCREEN_RAM+4
        lda #']'
        sta SCREEN_RAM+5

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

        ; Ligne 3 : Ligne de séparation (colonnes 6 à 39)
        ldx #6
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
        ; Marque la salle active comme visitée
        ldx current_room_y
        lda world_row_offset,x
        clc
        adc current_room_x
        tax
        lda #1
        sta visited_rooms,x

        ; Ligne 1 : "LV:" + Niveau (1..9) si Donjon, ou "R:" + Colonne-Rangée si Overworld
        lda current_world_type
        cmp #WORLD_DUNGEON
        bne .hud_ow_coord

        lda #'L'
        sta SCREEN_RAM+41
        lda #'V'
        sta SCREEN_RAM+42
        lda #':'
        sta SCREEN_RAM+43
        lda #'0'
        clc
        adc current_dungeon_level
        sta SCREEN_RAM+44
        lda #' '
        sta SCREEN_RAM+45
        sta SCREEN_RAM+46
        jmp .hud_coord_col

.hud_ow_coord:
        lda #'R'
        sta SCREEN_RAM+41
        lda #':'
        sta SCREEN_RAM+42
        lda #'A'
        clc
        adc current_room_x
        sta SCREEN_RAM+43
        lda #'-'
        sta SCREEN_RAM+44
        lda #'1'
        clc
        adc current_room_y
        sta SCREEN_RAM+45
        lda #' '
        sta SCREEN_RAM+46

.hud_coord_col:
        lda #COL_YELLOW
        sta COLOR_RAM+41
        sta COLOR_RAM+42
        lda #COL_WHITE
        sta COLOR_RAM+43
        sta COLOR_RAM+44
        sta COLOR_RAM+45

        ; Ligne 2 : Coordonnées matricielles [XX,Y]
        lda #'['
        sta SCREEN_RAM+81
        lda current_room_x
        jsr print_2digits
        sta SCREEN_RAM+82
        stx SCREEN_RAM+83
        lda #','
        sta SCREEN_RAM+84
        lda #'0'
        clc
        adc current_room_y
        sta SCREEN_RAM+85
        lda #']'
        sta SCREEN_RAM+86

        lda #COL_CYAN
        sta COLOR_RAM+81
        lda #COL_WHITE
        sta COLOR_RAM+82
        sta COLOR_RAM+83
        sta COLOR_RAM+84
        sta COLOR_RAM+85
        lda #COL_CYAN
        sta COLOR_RAM+86

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

