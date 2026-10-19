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
HUD_MAP_CHAR_L  = 107                   ; minimap gauche (8x8 pixels)
HUD_MAP_CHAR_R  = 108                   ; minimap droite (8x8 pixels)

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
minimap_px:       !byte 0
minimap_py:       !byte 0

; Décalages pour centrer chaque Donjon (1..9) dans le canevas 16x8 pixels
dung_shift_x:
        !byte 4, $f9, $fc, 5, 2, $fd, $fd, $fa, 3       ; +4, -7, -4, +5, +2, -3, -3, -6, +3
dung_shift_y:
        !byte $ff, 0, $fe, 0, $ff, 0, $ff, $ff, $ff     ; -1, 0, -2, 0, -1, 0, -1, -1, -1

; Coordonnées pixel de la salle Triforce pour chaque Donjon (1..9)
dungeon_tri_px:
        !byte 10, 6, 9, 8, 6, 9, 8, 6, 5
dungeon_tri_py:
        !byte 2, 0, 1, 0, 0, 0, 1, 1, 2

bitmask:
        !byte $80, $40, $20, $10, $08, $04, $02, $01
bitmask_inv:
        !byte $7f, $bf, $df, $ef, $f7, $fb, $fd, $fe

; Silhouettes complètes des 9 Donjons officiels Zelda 1 (16 octets par niveau = 16x8 pixels)
dungeon_shapes:
        ; Lvl 1 (Eagle / Aigle)
        !byte $00, $03, $07, $03, $03, $03, $03, $00, $00, $00, $60, $c0, $80, $c0, $80, $00
        ; Lvl 2 (Moon / Lune)
        !byte $03, $01, $01, $01, $01, $01, $03, $02, $80, $80, $80, $80, $80, $80, $80, $00
        ; Lvl 3 (Manji)
        !byte $00, $03, $03, $03, $03, $01, $00, $00, $00, $c0, $c0, $c0, $80, $80, $00, $00
        ; Lvl 4 (Steer / Gnou)
        !byte $07, $07, $06, $07, $06, $06, $07, $06, $c0, $80, $00, $00, $00, $00, $00, $00
        ; Lvl 5 (Lizard / Lézard)
        !byte $03, $03, $01, $01, $01, $01, $00, $00, $80, $80, $c0, $c0, $c0, $c0, $c0, $00
        ; Lvl 6 (Dragon)
        !byte $07, $07, $07, $07, $07, $07, $07, $07, $c0, $c0, $00, $00, $00, $00, $00, $00
        ; Lvl 7 (Demon / Démon)
        !byte $07, $07, $07, $07, $07, $07, $07, $00, $00, $80, $00, $00, $e0, $e0, $00, $00
        ; Lvl 8 (Lion)
        !byte $00, $03, $07, $03, $03, $01, $03, $00, $00, $00, $c0, $80, $c0, $c0, $c0, $00
        ; Lvl 9 (Death Mountain / Montagne de la Mort)
        !byte $00, $03, $07, $07, $03, $03, $00, $00, $00, $00, $80, $c0, $c0, $c0, $e0, $00

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

        ; Minimap sur Ligne 1 (colonnes 2 et 3) : 2 caractères 8x8 = 16x8 pixels (1 pixel par salle)
        lda #HUD_MAP_CHAR_L
        sta SCREEN_RAM+40+2
        lda #HUD_MAP_CHAR_R
        sta SCREEN_RAM+40+3
        lda #COL_CYAN
        sta COLOR_RAM+40+2
        sta COLOR_RAM+40+3

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
        ; Garantit que les 2 caractères minimap sont en place sur Ligne 1 (cols 2 et 3)
        lda #HUD_MAP_CHAR_L
        sta SCREEN_RAM+40+2
        lda #HUD_MAP_CHAR_R
        sta SCREEN_RAM+40+3
        lda #COL_CYAN
        sta COLOR_RAM+40+2
        sta COLOR_RAM+40+3

        inc hud_blink_tick

        lda current_world_type
        cmp #WORLD_DUNGEON
        beq .render_uw_minimap

        ; --- OVERWORLD MINIMAP (16x8 salles = 16x8 pixels) ---
        ldx #15
        lda #$ff
-       sta $2358,x
        dex
        bpl -

        ; Clignotement de Link (éteint quand bit 3 == 0)
        lda hud_blink_tick
        and #%00001000
        bne +
        lda current_room_x
        sta minimap_px
        lda current_room_y
        sta minimap_py
        jsr minimap_clear_pixel
+       jmp .minimap_done

        ; ===================================================================
        ; MINIMAP SOUS-SOL / DONJONS (1 pixel par salle, centré dans 16x8)
        ; ===================================================================
.render_uw_minimap:
        lda current_dungeon_level
        bne +
        lda #1
        sta current_dungeon_level
+
        ; Efface les 16 octets de la bitmap ($2358..$2367)
        ldx #15
        lda #0
-       sta $2358,x
        dex
        bpl -

        ; Le joueur a-t-il la carte du donjon ?
        lda player_has_dungeon_map
        beq .uw_only_visited

        ; Joueur a la carte : copie la silhouette officielle complète du donjon (16 octets)
        lda current_dungeon_level
        sec
        sbc #1
        cmp #9
        bcc +
        lda #0
+       asl
        asl
        asl
        asl                             ; index * 16 octets
        tax
        ldy #0
-       lda dungeon_shapes,x
        sta $2358,y
        inx
        iny
        cpy #16
        bne -
        jmp .uw_draw_link_and_tri

.uw_only_visited:
        ; Joueur n'a pas la carte : affiche uniquement les salles visitées
        ldx #0
.uw_vis_loop:
        lda visited_uw_rooms,x
        beq .uw_vis_next

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
        bmi .uw_vis_skip
        cmp #16
        bcs .uw_vis_skip
        sta minimap_px

        lda ZP_TMP+1
        clc
        adc dung_shift_y,y
        bmi .uw_vis_skip
        cmp #8
        bcs .uw_vis_skip
        sta minimap_py

        jsr minimap_set_pixel

.uw_vis_skip:
        ldx ZP_SRC
.uw_vis_next:
        inx
        cpx #128
        bne .uw_vis_loop

.uw_draw_link_and_tri:
        ; 1. Position actuelle de Link dans le donjon
        ldy current_dungeon_level
        dey
        lda current_room_x
        clc
        adc dung_shift_x,y
        sta minimap_px
        lda current_room_y
        clc
        adc dung_shift_y,y
        sta minimap_py

        ; Clignotement de Link (bit 3 == 0 -> pixel éteint)
        lda hud_blink_tick
        and #%00001000
        bne +
        jsr minimap_clear_pixel
+
        ; 2. Salle de la Triforce (si le joueur a trouvé la Boussole)
        lda player_has_compass
        beq .minimap_done

        ldy current_dungeon_level
        dey
        lda dungeon_tri_px,y
        sta minimap_px
        lda dungeon_tri_py,y
        sta minimap_py

        ; La Triforce clignote en opposition avec Link (éteint quand bit 3 != 0, allumé quand bit 3 == 0)
        lda hud_blink_tick
        and #%00001000
        bne +
        jsr minimap_set_pixel
        jmp .minimap_done
+       jsr minimap_clear_pixel

.minimap_done:
        ; Nettoie colonnes 0..7 sur Ligne 2 (espace noir propre sous la minimap)
        ldx #0
-       lda #32
        sta SCREEN_RAM+80,x
        lda #COL_BLACK
        sta COLOR_RAM+80,x
        inx
        cpx #8
        bne -

        jmp .counters

; ---------------------------------------------------------------------------
; minimap_set_pixel : allume le pixel (minimap_px, minimap_py) dans $2358..$2367
; ---------------------------------------------------------------------------
minimap_set_pixel:
        lda minimap_py
        cmp #8
        bcs .set_pix_ret
        tay                             ; Y = py (0..7)
        lda minimap_px
        cmp #16
        bcs .set_pix_ret
        cmp #8
        bcs .set_pix_r
        tax                             ; X = px (0..7)
        lda bitmask,x
        ora $2358,y
        sta $2358,y
.set_pix_ret:
        rts
.set_pix_r:
        sec
        sbc #8
        tax                             ; X = px - 8 (0..7)
        lda bitmask,x
        ora $2360,y
        sta $2360,y
        rts

; ---------------------------------------------------------------------------
; minimap_clear_pixel : éteint le pixel (minimap_px, minimap_py) dans $2358..$2367
; ---------------------------------------------------------------------------
minimap_clear_pixel:
        lda minimap_py
        cmp #8
        bcs .clr_pix_ret
        tay
        lda minimap_px
        cmp #16
        bcs .clr_pix_ret
        cmp #8
        bcs .clr_pix_r
        tax
        lda bitmask_inv,x
        and $2358,y
        sta $2358,y
.clr_pix_ret:
        rts
.clr_pix_r:
        sec
        sbc #8
        tax
        lda bitmask_inv,x
        and $2360,y
        sta $2360,y
        rts

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

