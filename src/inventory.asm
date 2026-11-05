; ---------------------------------------------------------------------------
; inventory.asm : Logique et navigation du menu d'inventaire en 4 pages
;   Page 0 : [1:OBJETS]     - Sélection et équipement du Slot B
;   Page 1 : [2:TRIFORCE]   - Triangle de la Triforce de la Sagesse (8 fragments)
;   Page 2 : [3:EQUIPEMENT] - Arsenal permanent de Link & Reliques
;   Page 3 : [4:CARTE]      - Carte du Monde 16x8 avec Link clignotant
; ---------------------------------------------------------------------------

!zone inventory

inv_frame_timer:    !byte 0
map_rx:             !byte 0
map_ry:             !byte 0
map_link_color:     !byte COL_YELLOW
visited_count:      !byte 0

; ---------------------------------------------------------------------------
; open_inventory : ouvre le menu d'inventaire
; ---------------------------------------------------------------------------
ovl_inventory_open:
        lda #STATE_INVENTORY
        sta game_state

        lda #0
        sta btn_b_pressed
        sta btn_x_pressed
        sta VIC_SPRITE_EXP_X
        sta VIC_SPRITE_EXP_Y

        jsr items_init

        ; Marque la salle active comme visitée selon le monde
        ldx current_room_y
        lda world_row_offset,x
        clc
        adc current_room_x
        tax
        lda #1
        ldy current_world_type
        bne +
        sta visited_ow_rooms,x
        sta visited_rooms,x
        jmp ++
+       sta visited_uw_rooms,x
++

        ; Bip sonore d'ouverture
        jsr sound_inv_flip

        lda #COL_BLACK
        sta active_bg_color
        sta VIC_BACKGROUND
        sta VIC_BORDER

        ; Désactive le texte multicolore pour un texte haute résolution net
        lda VIC_CTRL2
        and #%11101111
        sta VIC_CTRL2

        lda #0
        ldy current_world_type
        cpy #WORLD_DUNGEON
        bne +
        lda #3                          ; En donjon : atterrissage direct sur la Carte du Donjon !
+       sta inv_page
        jsr inv_display_current_page
        rts

; ---------------------------------------------------------------------------
; close_inventory : referme le menu et reprend le jeu
; ---------------------------------------------------------------------------
ovl_inventory_close:
        lda #STATE_PLAYING
        sta game_state

        lda #0
        sta btn_b_pressed
        sta btn_x_pressed

        ; Réactive le texte multicolore pour l'overworld
        lda VIC_CTRL2
        ora #%00010000
        sta VIC_CTRL2

        lda #0
        sta VIC_SPRITE_EN
        sta VIC_SPRITE_MSB
        sta VIC_SPRITE_EXP_X
        sta VIC_SPRITE_EXP_Y

        ; Restaure la couleur de Link selon l'Anneau Bleu
        lda player_has_blue_ring
        beq +
        lda #COL_WHITE
        sta VIC_SPRITE_COL0
        jmp ++
+       lda #COL_GREEN
        sta VIC_SPRITE_COL0
++
        lda #COL_WHITE
        sta VIC_SPRITE_COL1
        lda #%00000011
        sta VIC_SPRITE_MC

        lda #MAP_BG_COLOR
        sta active_bg_color
        sta VIC_BACKGROUND
        lda #COL_BLACK
        sta VIC_BORDER

        jsr load_room
        jsr hud_init
        jsr items_init
        jsr player_draw
        rts

; ---------------------------------------------------------------------------
; inventory_update : navigation, sélection et changement de page
; ---------------------------------------------------------------------------
ovl_inventory_update:
        ; 1. Fermeture par Bouton B, X ou Espace
        lda btn_b_pressed
        bne .do_close
        lda btn_x_pressed
        bne .do_close
        jmp .check_direct_keys

.do_close:
        jsr close_inventory
        rts

.check_direct_keys:
        ; 2. Accès direct par les touches 1, 2, 3, 4
        lda key_1_pressed
        beq +
        lda #0
        sta key_1_pressed
        lda #INV_PAGE_ITEMS
        jmp .set_page
+       lda key_2_pressed
        beq +
        lda #0
        sta key_2_pressed
        lda #INV_PAGE_TRIFORCE
        jmp .set_page
+       lda key_3_pressed
        beq +
        lda #0
        sta key_3_pressed
        lda #INV_PAGE_EQUIPMENT
        jmp .set_page
+       lda key_4_pressed
        beq +
        lda #0
        sta key_4_pressed
        lda #INV_PAGE_MAP
        jmp .set_page
+       jmp .check_joy_page

.set_page:
        cmp inv_page
        beq .no_page_change             ; déjà sur cette page
        sta inv_page
        jsr inv_sound_flip
        jsr inv_display_current_page
        rts
.no_page_change:
        rts

.check_joy_page:
        ; 3. Défilement par Joystick HAUT / BAS
        lda joy_pressed
        and #JOY_UP
        beq +
        lda inv_page
        beq .wrap_page_up
        dec inv_page
        jmp .page_flipped
.wrap_page_up:
        lda #INV_PAGE_MAX
        sta inv_page
        jmp .page_flipped
+
        lda joy_pressed
        and #JOY_DOWN
        beq .no_joy_flip
        lda inv_page
        cmp #INV_PAGE_MAX
        beq .wrap_page_down
        inc inv_page
        jmp .page_flipped
.wrap_page_down:
        lda #0
        sta inv_page
.page_flipped:
        jsr inv_sound_flip
        jsr inv_display_current_page
        rts

.no_joy_flip:
        ; 4. Mise à jour de la logique propre à chaque page
        lda inv_page
        cmp #INV_PAGE_ITEMS
        bne +
        jmp update_items_page
+       cmp #INV_PAGE_TRIFORCE
        bne +
        jmp update_triforce_page
+       cmp #INV_PAGE_EQUIPMENT
        bne +
        jmp update_equipment_page
+       jmp update_map_page

; ---------------------------------------------------------------------------
; update_items_page : sélection d'arme Slot B (Page 0)
; ---------------------------------------------------------------------------
update_items_page:
        inc inv_frame_timer
        lda inv_frame_timer
        and #%00001100
        lsr
        lsr
        tax
        lda flash_colors,x
        sta VIC_SPRITE_COL7             ; Cadre clignotant

        ; Bouton A : Cycle l'objet
        lda btn_a_pressed
        beq .check_joy_vert
        lda hud_selected_b
        cmp #7
        beq .wrap_a_min
        inc hud_selected_b
        jmp .a_changed
.wrap_a_min:
        lda #0
        sta hud_selected_b
.a_changed:
        jsr sound_select_item
        jsr inv_update_cursor
        rts

.check_joy_vert:
        ; Joystick HAUT (navigation grille 4x2)
        lda joy_pressed
        and #JOY_UP
        beq .check_down
        lda hud_selected_b
        cmp #4
        bcc .check_down
        sec
        sbc #4
        sta hud_selected_b
        jmp .sel_changed

.check_down:
        ; Joystick BAS (navigation grille 4x2)
        lda joy_pressed
        and #JOY_DOWN
        beq .check_joy_horiz
        lda hud_selected_b
        cmp #4
        bcs .check_joy_horiz
        clc
        adc #4
        sta hud_selected_b
        jmp .sel_changed

.check_joy_horiz:
        ; Joystick GAUCHE
        lda joy_pressed
        and #JOY_LEFT
        beq .check_right
        lda hud_selected_b
        and #3
        beq .wrap_left
        dec hud_selected_b
        jmp .sel_changed
.wrap_left:
        lda hud_selected_b
        clc
        adc #3
        sta hud_selected_b
        jmp .sel_changed

.check_right:
        ; Joystick DROITE
        lda joy_pressed
        and #JOY_RIGHT
        beq .items_idle
        lda hud_selected_b
        and #3
        cmp #3
        beq .wrap_right
        inc hud_selected_b
        jmp .sel_changed
.wrap_right:
        lda hud_selected_b
        sec
        sbc #3
        sta hud_selected_b

.sel_changed:
        jsr sound_select_item
        jsr inv_update_cursor
.items_idle:
        rts


; ---------------------------------------------------------------------------
; update_triforce_page : Page 1
; ---------------------------------------------------------------------------
update_triforce_page:
        inc inv_frame_timer
        lda inv_frame_timer
        and #%00001000
        beq .tri_gold
        lda #COL_WHITE
        bne .tri_apply
.tri_gold:
        lda #COL_YELLOW
.tri_apply:
        ldx #7
-       sta VIC_SPRITE_COL0,x
        dex
        bpl -

        lda btn_a_pressed
        beq +
        lda #INV_PAGE_EQUIPMENT
        sta inv_page
        jsr inv_sound_flip
        jsr inv_display_current_page
+       rts

; ---------------------------------------------------------------------------
; update_equipment_page : Page 2
; ---------------------------------------------------------------------------
update_equipment_page:
        lda btn_a_pressed
        beq +
        lda #INV_PAGE_MAP
        sta inv_page
        jsr inv_sound_flip
        jsr inv_display_current_page
+       rts

; ---------------------------------------------------------------------------
; update_map_page : Page 3
; ---------------------------------------------------------------------------
update_map_page:
        lda btn_a_pressed
        beq .map_blink
        lda #INV_PAGE_ITEMS
        sta inv_page
        jsr inv_sound_flip
        jsr inv_display_current_page
        rts

.map_blink:
        inc inv_frame_timer
        lda inv_frame_timer
        and #%00010000
        beq .blink_yellow
        lda #COL_LIGHT_RED
        bne .apply_blink
.blink_yellow:
        lda #COL_YELLOW
.apply_blink:
        sta map_link_color
        jsr map_update_link_color
        rts

; ---------------------------------------------------------------------------
; inv_sound_flip : bip sonore de changement d'onglet
; ---------------------------------------------------------------------------
inv_sound_flip:
        jmp sound_inv_flip

; ---------------------------------------------------------------------------
; sound_select_item : son de sélection d'arme
; ---------------------------------------------------------------------------
sound_select_item:
        jsr sound_inv_select
        jsr inv_update_cursor
        jsr hud_render
        rts

; ---------------------------------------------------------------------------
; map_update_link_color : clignotement Link sur la carte
; ---------------------------------------------------------------------------
map_update_link_color:
        ldx current_room_y
        lda map_row_scr_lo,x
        sta ZP_COL
        lda map_row_col_hi,x
        sta ZP_COL+1

        lda current_room_x
        asl
        clc
        adc #4
        tay
        lda map_link_color
        sta (ZP_COL),y
        rts
