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
        lda #COL_BLACK
        sta VIC_BORDER
        sta VIC_BACKGROUND

        lda #PET_CLEAR
        jsr CHROUT
        ldx #0
.print:
        lda message,x
        beq .print_done
        jsr CHROUT
        inx
        bne .print
.print_done:

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

message:
        !text "JOYSTICK PORT 2 : DEPLACE LINK", PET_RETURN, 0

!source "src/input.asm"
!source "src/player.asm"

!align 63, 0                    ; les sprites doivent commencer sur 64 octets
!source "src/sprites.asm"
