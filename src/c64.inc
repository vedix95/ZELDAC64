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
VIC_SPRITE_MC1  = $d025         ; multicolore 1 (commun aux sprites)
VIC_SPRITE_MC2  = $d026         ; multicolore 2 (commun aux sprites)
VIC_SPRITE_COL0 = $d027         ; couleur propre du sprite 0

; --- Pointeurs de sprites (bloc de 64 octets = adresse >> 6) ---
SPRITE_PTR0     = $07f8

; --- SID ---
SID_BASE        = $d400
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

; --- Mémoire ---
SCREEN_RAM      = $0400
COLOR_RAM       = $d800
CPU_PORT        = $01

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

; --- Codes PETSCII ---
PET_CLEAR       = 147
PET_RETURN      = 13
