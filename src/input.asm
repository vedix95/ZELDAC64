; ---------------------------------------------------------------------------
; input.asm : lecture du joystick (port 2)
; Le matériel renvoie 0 quand une direction est pressée ; on inverse pour
; obtenir 1 = pressé, plus naturel à tester.
; ---------------------------------------------------------------------------
joy:            !byte 0                 ; état courant (masques JOY_*)
joy_prev:       !byte 0                 ; état à l'image précédente
joy_pressed:    !byte 0                 ; front montant (1 = vient d'être pressé)

read_input:
        lda joy
        sta joy_prev
        lda CIA1_PORT_A
        eor #$ff
        and #%00011111
        sta joy
        lda joy_prev
        eor #$ff
        and joy
        sta joy_pressed
        rts
