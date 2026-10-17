; ---------------------------------------------------------------------------
; main.asm : point d'entrée
; Création d'un passionné à l'aide de son IA préférée issue de chez Google
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
!if * > $1000 {
        !error "Les sprites Link debordent sur la zone ROM chargen ($1000)"
}

game_init:
        ; Désactive la ROM BASIC ($A000-$BFFF) pour libérer les 64 Ko de RAM
        ; $36 (%00110110) : RAM à $A000-$BFFF, I/O à $D000-$DFFF, KERNAL ACTIF à $E000-$FFFF
        lda #$36
        sta CPU_PORT

        jsr disk_init
        jsr disk_load_map_overworld
        jsr init_video
        jsr clear_screen
        jsr load_room
        jsr hud_init
        jsr player_init
        jsr items_init
        jsr enemies_init
        jsr player_draw
        jsr enemies_prep_multiplexer
        jsr init_raster_irq
        jsr sound_init
        jsr sound_detect_dual_sid
        lda #MUSIC_OVERWORLD
        jsr music_play

        lda #STATE_PLAYING
        sta game_state

main_loop:
        jsr wait_frame
        jsr music_update
        jsr read_input

        ; Si déjà en mode debug
        lda game_state
        cmp #STATE_DEBUG
        bne +
        jmp .in_debug
+

        ; Touche D : ouvre l'écran de debug depuis n'importe où
        lda key_d_pressed
        beq +
        jsr open_debug
        jmp main_loop
+
        ; Touche 2 : Bascule vers le Donjon (recharge map_uw)
        lda key_2_pressed
        beq +
        lda current_world_type
        cmp #WORLD_DUNGEON
        beq +
        jsr enter_dungeon
        jmp main_loop
+
        ; Touche 1 : Bascule vers l'Overworld (recharge map_ow)
        lda key_1_pressed
        beq +
        lda current_world_type
        cmp #WORLD_OVERWORLD
        beq +
        jsr exit_dungeon
        jmp main_loop
+
        ; Touche 3 : Bascule Dual SID (Mono 1 SID / Stéréo 2 SIDs $D420)
        lda key_3_pressed
        beq +
        lda dual_sid_enabled
        eor #1
        sta dual_sid_enabled
        beq .disable_sid2
        lda #15
        sta SID2_VOLUME
        jmp +
.disable_sid2:
        lda #0
        sta SID2_VOLUME
+
        ; Dispatch selon l'état de jeu
        lda game_state
        cmp #STATE_INVENTORY
        beq .in_inventory
        cmp #STATE_CAVE
        beq .in_cave

        ; --- ÉTAT DE JEU NORMAL ---
        ; Bouton B (Manette Xbox Bouton B / Touche 'B') : ouvre l'inventaire
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
        jsr enemies_prep_multiplexer
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

; Synchronisation sur l'interruption raster VBlank (50 Hz).
wait_frame:
        lda #0
        sta frame_ready
.wait:
        lda frame_ready
        beq .wait
        rts

!source "src/input.asm"
!source "src/hud.asm"
!source "src/player.asm"
!source "src/tilemap.asm"
!source "src/gameplay.asm"

; Le jeu de caractères est à une adresse fixe : le code et les données
; ci-dessus doivent tenir avant ($1000-$1FFF).
!if * > CHARSET_ADDR {
        !error "Le code deborde sur le jeu de caracteres ($2000)"
}
* = CHARSET_ADDR
!source "src/charset.asm"

; Sprites des ennemis, PNJs et boss alignés à 64 octets dans Bank 0 (RAM $2800..$3FFF)
* = $2800
!source "src/sprites_enemies.asm"
!source "src/sprites_extra.asm"

!if * > $4000 {
        !error "Les sprites debordent de la banque VIC 0 ($3FFF)"
}

; Code CPU au-delà de la banque VIC 0 ($4000..$CFFF)
* = $4000
!source "src/tiles_data.asm"
!source "src/transition.asm"
!source "src/items.asm"
!source "src/enemies.asm"
!source "src/inventory.asm"
!source "src/inventory_draw.asm"

; Module de communication disquette 1541 / D64
!source "src/disk.asm"

; Écran de diagnostic matériel et cartographie mémoire (Touche 'D')
!source "src/debug.asm"

; Grotte secrète de l'Épée ("C'est dangereux d'y aller tout seul")
!source "src/cave.asm"

; Moteur Audio et partitions (Single SID + Dual SID)
!source "src/sound.asm"

!if * > MAP_DATA_ADDR {
        !error "Le programme resident deborde sur la zone des cartes ($A000)"
}


