; ---------------------------------------------------------------------------
; input.asm : lecture du joystick (port 2), des 3 boutons de la manette
;             et du clavier (touche Espace / touches de secours)
;
; Manette 3 boutons (standard C64GS / Amiga / Megadrive / VICE) :
;   - Bouton A (1) : Épée (CIA1 Port A bit 4 = 0)
;   - Bouton B (2) : Arme secondaire (SID POTX < $80, Port 1 Fire, ou touche 'B')
;   - Bouton C (3) : Menu / Inventaire (SID POTY < $80, barre ESPACE, ou 'M'/'I')
; ---------------------------------------------------------------------------
joy:                !byte 0                 ; état courant (masques JOY_*)
joy_prev:           !byte 0                 ; état à l'image précédente
joy_pressed:        !byte 0                 ; front montant

btn_a:              !byte 0                 ; 1 si Bouton A (Épée) enfoncé
btn_a_prev:         !byte 0
btn_a_pressed:      !byte 0                 ; 1 au front montant

btn_b:              !byte 0                 ; 1 si Bouton B (Objet secondaire) enfoncé
btn_b_prev:         !byte 0
btn_b_pressed:      !byte 0                 ; 1 au front montant

btn_c:              !byte 0                 ; 1 si Bouton C (Inventaire / Menu) enfoncé
btn_c_prev:         !byte 0
btn_c_pressed:      !byte 0                 ; 1 au front montant

key_d:              !byte 0                 ; 1 si touche 'D' (Debug) enfoncée
key_d_prev:         !byte 0
key_d_pressed:      !byte 0                 ; 1 au front montant

; Alias pour rétro-compatibilité
key_space_pressed   = btn_c_pressed

read_input:
        ; Sauvegarde les états précédents pour calculer les fronts montants
        lda joy
        sta joy_prev
        lda btn_a
        sta btn_a_prev
        lda btn_b
        sta btn_b_prev
        lda btn_c
        sta btn_c_prev
        lda key_d
        sta key_d_prev

        ; -------------------------------------------------------------------
        ; 1. LECTURE DU JOYSTICK PORT 2 & BOUTON A (FIRE 1)
        ; -------------------------------------------------------------------
        ; Sélectionne le Port 2 pour les potentiomètres SID (Bit 7 = 1, Bit 6 = 0)
        ; et prépare les bits 0..4 en entrée pull-up
        lda #%10011111                  ; $9F
        sta CIA1_PORT_A

        lda CIA1_PORT_A
        eor #$ff
        and #%00001111                  ; Bits 0..3 : Directions Up, Down, Left, Right
        sta joy
        lda joy_prev
        and #%00001111
        eor #$ff
        and joy
        sta joy_pressed                 ; front montant directions

        ; Bouton A (Fire 1) : Bit 4 de CIA1 Port A ($DC00)
        lda CIA1_PORT_A
        eor #$ff
        and #%00010000
        beq .no_btn_a
        lda #1
        bne .store_btn_a
.no_btn_a:
        lda #0
.store_btn_a:
        sta btn_a
        lda btn_a_prev
        eor #$ff
        and btn_a
        sta btn_a_pressed

        ; Maintient la compatibilité avec le masque JOY_FIRE dans joy_pressed
        lda btn_a_pressed
        beq +
        lda #JOY_FIRE
        ora joy_pressed
        sta joy_pressed
+

        ; -------------------------------------------------------------------
        ; 2. LECTURE DU BOUTON B (OBJET SECONDAIRE)
        ; Sources combinées :
        ;   a) SID POT X ($D419) < $80 (standard 2e bouton C64GS / Megadrive)
        ;   b) CIA1 Port B ($DC01) bit 4 = 0 (si l'émulateur assigne Bouton 2 à Port 1)
        ;   c) Touche clavier 'B' ou 'X'
        ; -------------------------------------------------------------------
        lda #0
        sta btn_b

        ; Test a : SID POT X (Pin 9 du Port 2)
        lda SID_POTX
        bmi .check_b_port1              ; si >= $80, bouton relâché
        lda #1
        sta btn_b
        jmp .done_btn_b

.check_b_port1:
        ; Test b : Port 1 Fire ($DC01 bit 4)
        lda CIA1_PORT_B
        and #%00010000                  ; bit 4 = 0 si feu port 1 pressé
        bne .check_b_key
        lda #1
        sta btn_b
        jmp .done_btn_b

.check_b_key:
        ; Test c : Touche 'B' (Ligne 3, Colonne 4)
        sei
        lda #%11110111                  ; Ligne 3 ($F7)
        sta CIA1_PORT_A
        lda CIA1_PORT_B
        sta ZP_TMP
        lda #%10011111                  ; Restaure Port A
        sta CIA1_PORT_A
        cli

        lda ZP_TMP
        and #%00010000                  ; bit 4 = 0 si 'B' enfoncé
        bne .done_btn_b
        lda #1
        sta btn_b

.done_btn_b:
        lda btn_b_prev
        eor #$ff
        and btn_b
        sta btn_b_pressed

        ; -------------------------------------------------------------------
        ; 3. LECTURE DU BOUTON C (INVENTAIRE / MENU)
        ; Sources combinées :
        ;   a) SID POT Y ($D41A) < $80 (standard 3e bouton C64GS / Amiga)
        ;   b) Touche ESPACE (Ligne 7, Colonne 4)
        ;   c) Buffer KERNAL (touches Space, 'M', 'I', Entrée)
        ; -------------------------------------------------------------------
        lda #0
        sta btn_c

        ; Test a : SID POT Y (Pin 5 du Port 2)
        lda SID_POTY
        bmi .check_c_space              ; si >= $80, bouton relâché
        lda #1
        sta btn_c
        jmp .done_btn_c

.check_c_space:
        ; Test b : Touche ESPACE (Ligne 7, Colonne 4)
        sei
        lda #$7f                        ; Ligne 7 ($7F)
        sta CIA1_PORT_A
        lda CIA1_PORT_B
        sta ZP_TMP
        lda #%10011111                  ; Restaure Port A
        sta CIA1_PORT_A
        cli

        lda ZP_TMP
        and #%00010000                  ; bit 4 = 0 si Espace enfoncé
        bne .check_c_getin
        lda #1
        sta btn_c
        jmp .done_btn_c

.check_c_getin:
        ; Test c : Buffer KERNAL (Espace = 32, 'M' = 77, 'I' = 73, Return = 13)
        jsr GETIN
        beq .done_btn_c
        cmp #32
        beq .got_c_key
        cmp #77
        beq .got_c_key
        cmp #73
        beq .got_c_key
        cmp #13
        bne .done_btn_c
.got_c_key:
        lda #1
        sta btn_c

.done_btn_c:
        lda btn_c_prev
        eor #$ff
        and btn_c
        sta btn_c_pressed

        ; -------------------------------------------------------------------
        ; 4. LECTURE DE LA TOUCHE 'D' (DEBUG HARDWARE & MEMOIRE)
        ; -------------------------------------------------------------------
        lda #0
        sta key_d

        ; Matrice clavier : Ligne 2 ($FB), Colonne 2 (bit 2 de Port B = 0 si 'D')
        sei
        lda #$fb                        ; Ligne 2 ($FB)
        sta CIA1_PORT_A
        lda CIA1_PORT_B
        sta ZP_TMP
        lda #$ff                        ; Restaure Port A
        sta CIA1_PORT_A
        cli

        lda ZP_TMP
        and #%00000100                  ; bit 2 = 0 si 'D' enfoncé
        bne .check_d_done
        lda #1
        sta key_d

.check_d_done:
        lda key_d_prev
        eor #$ff
        and key_d
        sta key_d_pressed

        ; Restaure Port A à $FF
        lda #$ff
        sta CIA1_PORT_A
        rts

