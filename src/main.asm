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
        jsr init_video
        jsr clear_screen
        jsr load_room
        jsr player_init

main_loop:
        jsr wait_frame
        jsr read_input
        jsr player_update
        jsr player_draw
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
!source "src/player.asm"
!source "src/tilemap.asm"
!source "src/transition.asm"

; Les sprites doivent impérativement être en-dessous de $1000 (ou au-delà de $2000)
; car pour le VIC-II (banque 0), la zone $1000-$1FFF voit la ROM des caractères (chargen).
!align 63, 0
!source "src/sprites.asm"

; Les cartes sont lues par le CPU, qui voit la RAM en $1000-$1FFF sans problème.
!source "src/map_data.asm"

; Le jeu de caractères est à une adresse fixe : le code et les données
; ci-dessus doivent tenir avant (la zone entre les deux est remplie de 0).
!if * > CHARSET_ADDR {
        !error "Le code deborde sur le jeu de caracteres ($2000)"
}
* = CHARSET_ADDR
!source "src/charset.asm"
