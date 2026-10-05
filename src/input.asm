; ---------------------------------------------------------------------------
; input.asm : lecture du joystick (port 2)
; Le matériel renvoie 0 quand une direction est pressée ; on inverse pour
; obtenir 1 = pressé, plus naturel à tester.
; ---------------------------------------------------------------------------
joy:    !byte 0                 ; état courant (masques JOY_*)

read_input:
        lda CIA1_PORT_A
        eor #$ff
        and #%00011111
        sta joy
        rts
