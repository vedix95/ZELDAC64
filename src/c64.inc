; ---------------------------------------------------------------------------
; c64.inc : constantes matérielles et KERNAL du Commodore 64
; ---------------------------------------------------------------------------

; --- VIC-II ---
VIC_SPRITE_X0   = $d000
VIC_SPRITE_Y0   = $d001
VIC_SPRITE_MSB  = $d010
VIC_CTRL1       = $d011         ; bit 7 = bit 8 du raster, bit 4 = écran ON
VIC_RASTER      = $d012
VIC_SPRITE_EN   = $d015
VIC_CTRL2       = $d016
VIC_MEMSETUP    = $d018
VIC_IRQ_FLAG    = $d019
VIC_IRQ_ENABLE  = $d01a
VIC_SPRITE_MC   = $d01c         ; 1 bit par sprite : mode multicolore
VIC_BORDER      = $d020
VIC_BACKGROUND  = $d021
VIC_BG_MC1      = $d022         ; texte multicolore : couleur 1 (paire 01)
VIC_BG_MC2      = $d023         ; texte multicolore : couleur 2 (paire 10)
VIC_SPRITE_MC1  = $d025         ; multicolore 1 (commun aux sprites)
VIC_SPRITE_MC2  = $d026         ; multicolore 2 (commun aux sprites)
VIC_SPRITE_X1   = $d002
VIC_SPRITE_Y1   = $d003
VIC_SPRITE_X2   = $d004
VIC_SPRITE_Y2   = $d005
VIC_SPRITE_X3   = $d006
VIC_SPRITE_Y3   = $d007
VIC_SPRITE_X4   = $d008
VIC_SPRITE_Y4   = $d009
VIC_SPRITE_X5   = $d00a
VIC_SPRITE_Y5   = $d00b
VIC_SPRITE_X6   = $d00c
VIC_SPRITE_Y6   = $d00d
VIC_SPRITE_X7   = $d00e
VIC_SPRITE_Y7   = $d00f
VIC_SPRITE_COL0 = $d027         ; couleur propre du sprite 0
VIC_SPRITE_COL1 = $d028         ; couleur propre du sprite 1
VIC_SPRITE_COL2 = $d029
VIC_SPRITE_COL3 = $d02a
VIC_SPRITE_COL4 = $d02b
VIC_SPRITE_COL5 = $d02c
VIC_SPRITE_COL6 = $d02d
VIC_SPRITE_COL7 = $d02e

; --- Pointeurs de sprites (bloc de 64 octets = adresse >> 6) ---
SPRITE_PTR0     = $07f8
SPRITE_PTR1     = $07f9
SPRITE_PTR2     = $07fa
SPRITE_PTR3     = $07fb
SPRITE_PTR4     = $07fc
SPRITE_PTR5     = $07fd
SPRITE_PTR6     = $07fe
SPRITE_PTR7     = $07ff

; --- SID ---
SID_BASE        = $d400
SID_V1_FREQ_LO  = $d400
SID_V1_FREQ_HI  = $d401
SID_V1_PW_LO    = $d402
SID_V1_PW_HI    = $d403
SID_V1_CTRL     = $d404
SID_V1_AD       = $d405
SID_V1_SR       = $d406
SID_POTX        = $d419         ; Potentiomètre X (Bouton 2 de la manette)
SID_POTY        = $d41a         ; Potentiomètre Y (Bouton 3 de la manette)
SID_VOLUME      = $d418

; --- CIA ---
CIA1_PORT_A     = $dc00         ; joystick 2
CIA1_PORT_B     = $dc01         ; joystick 1
CIA1_ICR        = $dc0d
CIA2_ICR        = $dd0d

; --- Joystick (masques, une fois la lecture inversée : 1 = actif) ---
JOY_UP          = %00000001
JOY_DOWN        = %00000010
JOY_LEFT        = %00000100
JOY_RIGHT       = %00001000
JOY_FIRE        = %00010000

; --- Boutons de la manette à 3 boutons ---
BTN_A           = %00000001     ; Bouton 1 : Épée (Slot A)
BTN_B           = %00000010     ; Bouton 2 : Objet secondaire (Slot B)
BTN_C           = %00000100     ; Bouton 3 : Menu / Inventaire

; --- Mémoire ---
SCREEN_RAM      = $0400
COLOR_RAM       = $d800
CPU_PORT        = $01

; Jeu de caractères perso : $2000-$27FF. Dans la banque VIC 0, $1000-$1FFF
; est vu comme la ROM de caractères, donc on prend le bloc suivant.
CHARSET_ADDR    = $2000
; Registre $d018 : bits 4-7 = écran/$0400, bits 1-3 = charset/$0800
MEMSETUP_VALUE  = ((SCREEN_RAM >> 6) & $f0) | ((CHARSET_ADDR >> 10) & $0e)

CURSOR_FLAG     = $cc           ; non nul = curseur KERNAL désactivé

; --- Zéro page (cases libres, non utilisées par le KERNAL en dehors de BASIC) ---
ZP_IDX          = $02
ZP_ROW          = $03
ZP_TCOL         = $04
ZP_TMP          = $05
ZP_BASE         = $06
ZP_MAP          = $07           ; pointeur 16 bits vers la salle active ($07-$08)
ZP_TGT          = $09           ; pointeur 16 bits vers la salle cible ($09-$0a)
ZP_STEP         = $0b           ; compteur d'étapes de transition
ZP_SRC          = $0c           ; pointeur source 16 bits ($0c-$0d)
ZP_DST          = $0e           ; pointeur destination 16 bits ($0e-$0f)
ZP_SCR          = $fb           ; pointeur 16 bits écran ($fb-$fc)
ZP_COL          = $fd           ; pointeur 16 bits couleur ($fd-$fe)

; --- KERNAL ---
CHROUT          = $ffd2
GETIN           = $ffe4

; --- Couleurs ---
COL_BLACK       = 0
COL_WHITE       = 1
COL_RED         = 2
COL_CYAN        = 3
COL_PURPLE      = 4
COL_GREEN       = 5
COL_BLUE        = 6
COL_YELLOW      = 7
COL_ORANGE      = 8
COL_BROWN       = 9
COL_LRED        = 10
COL_DGREY       = 11
COL_GREY        = 12
COL_LGREEN      = 13
COL_LBLUE       = 14
COL_LGREY       = 15

; Alias plus explicites
COL_LIGHT_RED   = COL_LRED
COL_LIGHT_GREEN = COL_LGREEN
COL_LIGHT_BLUE  = COL_LBLUE
COL_LIGHT_GREY  = COL_LGREY
COL_DARK_GREY   = COL_DGREY

; --- Codes PETSCII ---
PET_CLEAR       = 147
PET_RETURN      = 13
