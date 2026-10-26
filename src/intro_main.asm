; ============================================================================
; intro_main.asm : Programme autonome d'introduction pour Commodore 64
; Création d'un passionné à l'aide de son IA préférée issue de chez Google
; Génère build/intro.prg (écrit sur disquette build/zelda.d64 en tant que "INTRO")
; ============================================================================
!cpu 6510
!source "src/c64.inc"

; --- Stub BASIC : 10 SYS 2061 -------------------------------------------
* = $0801
        !word basic_end
        !word 10
        !byte $9e
        !text "2061"
        !byte 0
basic_end:
        !word 0

!ifndef SKIP_INTRO {
        SKIP_INTRO = 0
}

start:
!if start != 2061 {
        !error "L'adresse de start doit etre 2061 (SYS 2061)"
}
!if SKIP_INTRO == 1 {
        jmp launch_zelda_game
} else {
        jmp intro_standalone_init
}

cart_present:
        !byte 0                         ; 0 = Disquette, 1 = Cartouche Magic Desk (Type 19)

; Lecture joystick et manette
!source "src/input.asm"

; Jeu de caractères dédié à l'intro à $2000 (avec blason officiel NES et glyphes)
* = CHARSET_ADDR
!source "src/intro_charset.asm"

; Code et données de l'introduction à $2800
* = $2800
!source "src/intro.asm"

MAP_BG_COLOR    = 13
MAP_MC1_COLOR   = 8
MAP_MC2_COLOR   = 1

wait_frame:
-       lda VIC_RASTER
        cmp #250
        bne -
-       lda VIC_RASTER
        cmp #250
        beq -
        rts

intro_standalone_init:
        ; Désactive la ROM BASIC pour accéder à toute la RAM si nécessaire
        lda #$36
        sta CPU_PORT

        ; Initialise la vidéo
        lda #1
        sta CURSOR_FLAG                 ; pas de curseur clignotant
        lda #MAP_BG_COLOR
        sta VIC_BACKGROUND
        lda #MAP_MC1_COLOR
        sta VIC_BG_MC1
        lda #MAP_MC2_COLOR
        sta VIC_BG_MC2
        lda #COL_BLACK
        sta VIC_BORDER
        lda #MEMSETUP_VALUE             ; écran $0400, caractères $2000
        sta VIC_MEMSETUP
        lda VIC_CTRL2
        and #%11101111                  ; bit 4 = 0 : texte haute résolution (pixels nets 8x8)
        sta VIC_CTRL2

        ; Efface l'écran
        ldx #0
-       lda #0
        sta SCREEN_RAM,x
        sta SCREEN_RAM+$100,x
        sta SCREEN_RAM+$200,x
        sta SCREEN_RAM+$2e8,x
        lda #COL_BLACK
        sta COLOR_RAM,x
        sta COLOR_RAM+$100,x
        sta COLOR_RAM+$200,x
        sta COLOR_RAM+$2e8,x
        inx
        bne -

        ; Initialise l'introduction et la musique SID
        jsr intro_init

intro_main_loop:
        jsr wait_frame
        jsr read_input
        jsr intro_update
        jmp intro_main_loop

; ---------------------------------------------------------------------------
; launch_zelda_game : Déballe instantanément le moteur résident zelda.prg
; depuis les banques cartouche 4..9 vers la RAM ($0800..$C7FF) et lance le jeu.
; ---------------------------------------------------------------------------
launch_zelda_game:
        ; Arrête la musique d'intro
        jsr intro_music_stop
        lda #0
        sta SID_VOLUME
        sta VIC_SPRITE_EN
        sta VIC_SPRITE_EXP_X
        sta VIC_SPRITE_EXP_Y

        ; Copie le déballeur de cartouche dans le buffer cassette $0340
        ldx #0
-       lda .cart_unpacker_code,x
        sta $0340,x
        inx
        cpx #(.cart_unpacker_end - .cart_unpacker_code)
        bne -

        jmp $0340

.cart_unpacker_code:
!pseudopc $0340 {
        sei
        lda #0
        sta VIC_IRQ_ENABLE
        asl VIC_IRQ_FLAG

        ; 1. Active LORAM=1 ($37) pour lire la ROM cartouche à $8000..$9FFF
        lda #$37
        sta CPU_PORT

        ; 2. Boucle de déballage des banques 4..9 de zelda.prg en RAM ($0800..$C7FF)
        lda #4                          ; Banque cartouche de départ (4..9)
        sta $02
        lda #$08                        ; Page haute destination en RAM
        sta $03

.cart_bank_loop:
        lda $02
        sta $de00                       ; Commute la banque à $8000

        lda #0
        sta $fb
        lda #$80
        sta $fc                         ; Source $8000
        lda #0
        sta $fd
        lda $03
        sta $fe                         ; Destination ($03):$00

        ldx #32                         ; 32 pages = 8192 octets par banque
        ldy #0
-       lda ($fb),y
        sta ($fd),y
        iny
        bne -
        inc $fc
        inc $fe
        dex
        bne -

        lda $03
        clc
        adc #$20                        ; Avance de 32 pages ($2000 octets)
        sta $03

        inc $02
        lda $02
        cmp #10                         ; Banques 4 à 9 traitées ?
        bcc .cart_bank_loop

        ; 3. Désactive la ROM BASIC ($A000..$BFFF)
        lda #$36
        sta CPU_PORT

        ; 4. Active le flag cart_present dans zelda.prg ($0810)
        lda #1
        sta $0810

        ; 5. Désactive la ROM cartouche ($80 = bit 7 actif désactive /ROML)
        lda #$80
        sta $de00

        ; 6. Saute au point d'entrée de zelda.prg (SYS 2061 = $080D)
        jmp $080d
}
.cart_unpacker_end:

