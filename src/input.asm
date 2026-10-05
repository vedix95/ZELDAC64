; ---------------------------------------------------------------------------
; input.asm : lecture du joystick (port 2) et du clavier (touche Espace)
; ---------------------------------------------------------------------------
joy:                !byte 0                 ; état courant (masques JOY_*)
joy_prev:           !byte 0                 ; état à l'image précédente
joy_pressed:        !byte 0                 ; front montant (1 = vient d'être pressé)

key_space:          !byte 0                 ; 1 si Espace enfoncé
key_space_prev:     !byte 0
key_space_pressed:  !byte 0                 ; 1 au front montant d'Espace

read_input:
        ; 1. Lecture du Joystick Port 2 sur CIA1 Port A ($DC00)
        lda joy
        sta joy_prev
        lda #$ff
        sta CIA1_PORT_A
        lda CIA1_PORT_A
        eor #$ff
        and #%00011111
        sta joy
        lda joy_prev
        eor #$ff
        and joy
        sta joy_pressed

        ; 2. Lecture de la touche Espace (Matrice clavier Ligne 7 Col 4 + Buffer KERNAL)
        lda key_space
        sta key_space_prev
        lda #0
        sta key_space

        ; Méthode 1 : Lecture matérielle directe de la matrice CIA1
        sei                             ; protège la sélection de ligne
        lda #$7f                        ; ligne 7 (bit 7 = 0)
        sta CIA1_PORT_A
        lda CIA1_PORT_B
        sta ZP_TMP
        lda #$ff                        ; restaure Port A pour le joystick
        sta CIA1_PORT_A
        cli

        lda ZP_TMP
        and #%00010000                  ; bit 4 = 0 si Espace est enfoncé
        bne .check_getin
        lda #1
        sta key_space
        jmp .calc_space

.check_getin:
        ; Méthode 2 : Buffer clavier KERNAL (code PETSCII 32 = Espace)
        jsr GETIN
        cmp #32
        bne .calc_space
        lda #1
        sta key_space

.calc_space:
        lda key_space_prev
        eor #$ff
        and key_space
        sta key_space_pressed
        rts

