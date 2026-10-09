; ---------------------------------------------------------------------------
; input.asm : lecture du joystick (port 2), des 3 boutons de la manette
;             et du clavier (touche Espace / touche 'X' / touche 'D')
;
; Configuration :
;   - Bouton X (Manette X ou Y / Touche ESPACE / touche 'X') : Épée
;   - Bouton A (Manette A / Feu joystick CIA1 Port A bit 4) : Arme secondaire
;   - Bouton B (Manette B / Touche 'B' -> Ligne 3, Col 4)  : Menu / Inventaire
;   - Clavier 'D'                                          : Écran de debug
; ---------------------------------------------------------------------------
joy:                !byte 0                 ; état courant (masques JOY_*)
joy_prev:           !byte 0                 ; état à l'image précédente
joy_pressed:        !byte 0                 ; front montant

btn_a:              !byte 0                 ; 1 si Bouton A (Arme secondaire) enfoncé
btn_a_prev:         !byte 0
btn_a_pressed:      !byte 0                 ; 1 au front montant

btn_b:              !byte 0                 ; 1 si Bouton B (Inventaire / Menu) enfoncé
btn_b_prev:         !byte 0
btn_b_pressed:      !byte 0                 ; 1 au front montant

btn_x:              !byte 0                 ; 1 si Bouton X (Épée) enfoncé
btn_x_prev:         !byte 0
btn_x_pressed:      !byte 0                 ; 1 au front montant

key_d:              !byte 0                 ; 1 si touche 'D' (Debug) enfoncée
key_d_prev:         !byte 0
key_d_pressed:      !byte 0                 ; 1 au front montant

; Variables de lecture matricielle anti-ghosting
col_idle:           !byte 0                 ; état des colonnes au repos (Port A = $FF)
col_row3:           !byte 0                 ; état des colonnes avec Ligne 3 active ('B')
col_row7:           !byte 0                 ; état des colonnes avec Ligne 7 active (Espace)
col_row2:           !byte 0                 ; état des colonnes avec Ligne 2 active ('D' et 'X')

; Alias de compatibilité
btn_c               = btn_x
btn_c_prev          = btn_x_prev
btn_c_pressed       = btn_x_pressed
key_space_pressed   = btn_x_pressed

read_input:
        ; Sauvegarde les états précédents pour calculer les fronts montants
        lda joy
        sta joy_prev
        lda btn_a
        sta btn_a_prev
        lda btn_b
        sta btn_b_prev
        lda btn_x
        sta btn_x_prev
        lda key_d
        sta key_d_prev

        ; -------------------------------------------------------------------
        ; 1. LECTURE DU JOYSTICK PORT 2 & BOUTON A (FIRE 1 = ARME SECONDAIRE)
        ; -------------------------------------------------------------------
        ; Port A ($DC00) : toutes les lignes de sortie à 1 ($FF).
        ; Les directions et Fire tirent les broches à 0 (GND).
        lda #$ff
        sta CIA1_PORT_A

        ; Lecture de l'état du Joystick 2 (0 = contact fermé)
        lda CIA1_PORT_A
        eor #$ff
        and #%00001111                  ; Bits 0..3 : Directions Up, Down, Left, Right
        sta joy
        lda joy_prev
        and #%00001111
        eor #$ff
        and joy
        sta joy_pressed                 ; front montant directions

        ; Bouton A (Fire 1 / Arme secondaire) : Bit 4 de CIA1 Port A ($DC00)
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
        ; 2. SCAN MATRICIEL SÉCURISÉ & ANTI-GHOSTING
        ; -------------------------------------------------------------------
        ; Référence au repos : Port A = $FF (aucune ligne activée par le CPU).
        ; Si Joystick 2 Droite est pressé (PA3 = 0) ET que la touche 'B' est
        ; enfoncée (relie PA3 et Colonne 4), la Colonne 4 est court-circuitée
        ; à la masse en permanence (bit 4 de Port B = 0).
        lda CIA1_PORT_B
        sta col_idle

        sei
        ; Test Ligne 3 ($F7) : Touche 'B' (Inventaire / Menu)
        lda #%11110111
        sta CIA1_PORT_A
        lda CIA1_PORT_B
        sta col_row3

        ; Test Ligne 7 ($7F) : Touche ESPACE (Manette X / Touche Espace)
        lda #%01111111
        sta CIA1_PORT_A
        lda CIA1_PORT_B
        sta col_row7

        ; Test Ligne 2 ($FB) : Touche 'D' (Debug, Col 2) et Touche 'X' (Épée, Col 7)
        lda #%11111011
        sta CIA1_PORT_A
        lda CIA1_PORT_B
        sta col_row2

        ; Restaure immédiatement Port A à $FF (prêt pour le prochain tour)
        lda #$ff
        sta CIA1_PORT_A
        cli

        ; -------------------------------------------------------------------
        ; 3. TRAITEMENT BOUTON B (INVENTAIRE / MENU / TOUCHE 'B')
        ; -------------------------------------------------------------------
        lda #0
        sta btn_b

        lda col_row3
        and #%00010000                  ; Bit 4 = 0 si 'B' enfoncé
        bne .done_btn_b
        lda #1
        sta btn_b

.done_btn_b:
        lda btn_b_prev
        eor #$ff
        and btn_b
        sta btn_b_pressed

        ; -------------------------------------------------------------------
        ; 4. TRAITEMENT BOUTON X (ÉPÉE / MANETTE X / ESPACE / TOUCHE 'X')
        ; -------------------------------------------------------------------
        lda #0
        sta btn_x

        ; Test a : Touche 'X' du clavier (Ligne 2, Colonne 7 -> bit 7 de col_row2)
        lda col_row2
        bpl .got_btn_x                  ; Bit 7 = 0 si 'X' enfoncé (bpl car bit 7 = signe)

        ; Test b : Manette X (Bouton 3) / Touche ESPACE (Ligne 7, Colonne 4)
        ; Anti-ghosting différentiel :
        ; Si la Colonne 4 était DÉJÀ à 0 au repos (col_idle bit 4 = 0), c'est un
        ; retour de masse causé par Droite + Touche 'B' -> on rejette !
        lda col_idle
        and #%00010000                  ; Bit 4 doit être 1 au repos
        beq .done_btn_x                 ; Si 0 -> ghosting, rejet immédiat !

        ; Vérifie si la Colonne 4 passe à 0 quand la Ligne 7 est activée
        lda col_row7
        and #%00010000                  ; Bit 4 = 0 si Espace enfoncé
        bne .done_btn_x

.got_btn_x:
        lda #1
        sta btn_x

.done_btn_x:
        lda btn_x_prev
        eor #$ff
        and btn_x
        sta btn_x_pressed

        ; -------------------------------------------------------------------
        ; 5. TRAITEMENT TOUCHE 'D' (DEBUG MATÉRIEL & MÉMOIRE)
        ; -------------------------------------------------------------------
        lda #0
        sta key_d

        lda col_row2
        and #%00000100                  ; Bit 2 = 0 si 'D' enfoncé
        bne .done_key_d
        lda #1
        sta key_d

.done_key_d:
        lda key_d_prev
        eor #$ff
        and key_d
        sta key_d_pressed

        ; -------------------------------------------------------------------
        ; Vider le tampon clavier KERNAL ($C6 = 0) pour empêcher l'accumulation
        ; de frappes fantômes générées par SCNKEY lors des mouvements de joystick.
        ; -------------------------------------------------------------------
        lda #0
        sta $c6

        ; Restaure Port A à $FF
        lda #$ff
        sta CIA1_PORT_A
        rts
