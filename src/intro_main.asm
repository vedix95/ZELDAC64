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

start:
!if start != 2061 {
        !error "L'adresse de start doit etre 2061 (SYS 2061)"
}
        jmp intro_standalone_init

; Lecture joystick et manette
!source "src/input.asm"

; Jeu de caractères à $2000
* = CHARSET_ADDR
!source "src/charset.asm"

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

        ; Détecte l'unité de disquette courante
        lda DEVICE_NUM
        cmp #8
        bcc +
        cmp #12
        bcs +
        sta zelda_boot_dev
        jmp ++
+       lda #8
        sta zelda_boot_dev
++
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
; launch_zelda_game : Copie un petit chargeur KERNAL dans le buffer cassette
; ($033C..$03FB), zone protégée non écrasée par le chargement de ZELDA ($0801+)
; ---------------------------------------------------------------------------
launch_zelda_game:
        ; Arrête la musique d'intro
        jsr intro_music_stop
        lda #0
        sta SID_VOLUME
        sta VIC_SPRITE_EN
        sta VIC_SPRITE_EXP_X
        sta VIC_SPRITE_EXP_Y

        ; Copie le chargeur KERNAL dans le buffer cassette $033C
        ldx #0
-       lda .loader_code,x
        sta $033c,x
        inx
        cpx #(.loader_end - .loader_code)
        bne -

        ; Transmet le device de boot actif dans le chargeur à $033C
        lda zelda_boot_dev
        sta .loader_dev

        ; Saute dans le chargeur en zone protégée
        jmp $033c

.loader_code:
!pseudopc $033c {
        sei
        lda #0
        sta VIC_IRQ_ENABLE
        asl VIC_IRQ_FLAG
        lda #$36                        ; Active KERNAL et I/O, RAM sous BASIC ($A000-$BFFF)
        sta CPU_PORT

        jsr $fda3                      ; IOINIT (initialise CIA1 et CIA2)
        jsr $fd15                      ; RESTOR (restaure vecteurs KERNAL)

        ; SETLFS : LFN=1, Dev=device, SA=1 (adresse d'origine du fichier)
        lda #1
.loader_dev = * + 1
        ldx #8
        ldy #1
        jsr SETLFS

        ; SETNAM : nom "ZELDA" (5 caractères)
        lda #5
        ldx #< .loader_name
        ldy #> .loader_name
        jsr SETNAM

        ; LOAD en RAM (A=0 pour LOAD)
        lda #0
        jsr LOAD
        bcs .loader_error

        ; Démarrage direct du jeu ZELDA à SYS 2061 ($080D)
        jmp $080d

.loader_error:
        lda #COL_RED
        sta VIC_BORDER
-       jmp -

.loader_name:
        !text "ZELDA"
}
.loader_end:

zelda_boot_dev: !byte 8
