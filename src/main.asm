; ---------------------------------------------------------------------------
; main.asm : point d'entrée
; Assembleur : ACME   -   Cible : C64 (6510)
; ---------------------------------------------------------------------------
!cpu 6510
!source "src/c64.inc"

; --- Stub BASIC : 10 SYS 2061 -------------------------------------------
* = $0801
        !word basic_end         ; pointeur vers la ligne suivante
        !word 10                ; numéro de ligne
        !byte $9e               ; token SYS
        !text "2061"
        !byte 0                 ; fin de ligne
basic_end:
        !word 0                 ; fin du programme BASIC

; --- Programme ----------------------------------------------------------
start:
!if start != 2061 {
        !error "L'adresse de start doit etre 2061 (SYS 2061)"
}
        jmp game_init

; Les sprites doivent impérativement être en-dessous de $1000 (ou au-delà de $2000)
; car pour le VIC-II (banque 0), la zone $1000-$1FFF voit la ROM des caractères (chargen).
!align 63, 0
!source "src/sprites.asm"

game_init:
        jsr init_video
        jsr clear_screen
        jsr load_room
        jsr hud_init
        jsr player_init
        jsr items_init
        jsr enemies_init

main_loop:
        jsr wait_frame
        jsr read_input

        ; Si déjà en mode debug
        lda game_state
        cmp #STATE_DEBUG
        beq .in_debug

        ; Touche D : ouvre l'écran de debug depuis n'importe où
        lda key_d_pressed
        beq +
        jsr open_debug
        jmp main_loop
+
        ; Dispatch selon l'état de jeu
        lda game_state
        cmp #STATE_INVENTORY
        beq .in_inventory
        cmp #STATE_CAVE
        beq .in_cave

        ; --- ÉTAT DE JEU NORMAL ---
        ; Bouton B : ouvre l'inventaire
        lda btn_b_pressed
        beq .play_frame
        jsr open_inventory
        jmp main_loop

.play_frame:
        jsr player_update
        jsr items_update
        jsr enemies_update
        jsr player_draw
        jsr items_draw
        jsr enemies_draw
        jmp main_loop

.in_inventory:
        jsr inventory_update
        jmp main_loop

.in_cave:
        jsr cave_update
        jsr cave_draw
        jmp main_loop

.in_debug:
        jsr debug_update
        jmp main_loop

; Synchronisation sur la ligne raster 255 (1 passage par image, 50/60 Hz).
wait_frame:
.wait_line:
        lda VIC_RASTER
        cmp #$ff
        bne .wait_line
.leave_line:                    ; sortir de la ligne pour ne pas compter 2 fois
        lda VIC_RASTER
        cmp #$ff
        beq .leave_line
        rts

!source "src/input.asm"
!source "src/hud.asm"
!source "src/player.asm"
!source "src/tilemap.asm"
!source "src/transition.asm"

; Le jeu de caractères est à une adresse fixe : le code et les données
; ci-dessus doivent tenir avant ($1000-$1FFF).
!if * > CHARSET_ADDR {
        !error "Le code deborde sur le jeu de caracteres ($2000)"
}
* = CHARSET_ADDR
!source "src/charset.asm"

; Données de carte, sous-menus et logique des objets dans la RAM libre au-delà du jeu de caractères
* = $2800
!source "src/items.asm"
!source "src/inventory.asm"
!source "src/map_data.asm"

; Sprites des ennemis alignés à 64 octets dans Bank 0 (RAM $3000..$3FFF)
!align 63, 0
!source "src/sprites_enemies.asm"

!if * > $4000 {
        !error "Les sprites ennemis debordent de la banque VIC 0 ($3FFF)"
}

; Logique et IA des ennemis (code CPU en RAM libre)
!source "src/enemies.asm"

; Écran de diagnostic matériel et cartographie mémoire (Touche 'D')
!source "src/debug.asm"

; Grotte secrète de l'Épée ("C'est dangereux d'y aller tout seul")
!source "src/cave.asm"

