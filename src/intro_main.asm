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
        jmp sid_setup_menu_init
}

cart_present:
        !byte 0                         ; 0 = Disquette, 1 = Cartouche Magic Desk (Type 19)

; Lecture joystick et manette ($0811..$0836, btn_a_pressed = $0816)
!source "src/input.asm"

selected_dual_sid:
        !byte 0                         ; 0 = Single SID (Mono), 1 = Dual SID (Stereo)
selected_sid2_addr_idx:
        !byte 0                         ; 0 = $D420, 1 = $D500, 2 = $DF00
menu_cursor_idx:
        !byte 0                         ; 0..3 (Défaut: 0 = Mono)
menu_timeout_frames:
        !word 0                         ; Compteur pour auto-sélection ~10s
menu_opt_loop_idx:
        !byte 0

; Motif du triangle plein pour la Triforce (24x21, 64 octets alignes)
!align 63, 0
spr_triforce_triangle:
        !byte $00, $18, $00             ; line 0: ...........##...........
        !byte $00, $18, $00             ; line 1: ...........##...........
        !byte $00, $3C, $00             ; line 2: ..........####..........
        !byte $00, $3C, $00             ; line 3: ..........####..........
        !byte $00, $7E, $00             ; line 4: .........######.........
        !byte $00, $7E, $00             ; line 5: .........######.........
        !byte $00, $FF, $00             ; line 6: ........########........
        !byte $00, $FF, $00             ; line 7: ........########........
        !byte $01, $FF, $80             ; line 8: .......##########.......
        !byte $01, $FF, $80             ; line 9: .......##########.......
        !byte $03, $FF, $C0             ; line 10: ......############......
        !byte $03, $FF, $C0             ; line 11: ......############......
        !byte $07, $FF, $E0             ; line 12: .....##############.....
        !byte $07, $FF, $E0             ; line 13: .....##############.....
        !byte $0F, $FF, $F0             ; line 14: ....################....
        !byte $0F, $FF, $F0             ; line 15: ....################....
        !byte $1F, $FF, $F8             ; line 16: ...##################...
        !byte $1F, $FF, $F8             ; line 17: ...##################...
        !byte $3F, $FF, $FC             ; line 18: ..####################..
        !byte $3F, $FF, $FC             ; line 19: ..####################..
        !byte $7F, $FF, $FE             ; line 20: .######################.
        !byte $00                       ; line 21 / padding (64 octets au total)

!if spr_triforce_triangle >= $1000 {
        !error "spr_triforce_triangle deborde sur la zone ROM chargen ($1000)"
}

!align 63, 0
intro_mon_spr_buffers:
        !fill 64 * 6, 0                 ; 6 blocs sprites de 64 octets = 384 octets ($0A40..$0BBF)
SPR_BLOCK_MON0 = (intro_mon_spr_buffers / 64)

!if intro_mon_spr_buffers + (64 * 6) > $0C00 {
        !error "intro_mon_spr_buffers deborde sur Screen RAM 1 ($0C00)"
}

; Jeu de caractères dédié à l'intro à $2000 (avec blason officiel NES et glyphes)
* = CHARSET_ADDR
!source "src/intro_charset.asm"

; Sprites des 27 objets authentiques pour le defile des tresors ($2800..$2EBF)
!source "src/intro_items_sprites.asm"

; Code et données de l'introduction à la suite
!source "src/intro.asm"

MAP_BG_COLOR    = 13
MAP_MC1_COLOR   = 8
MAP_MC2_COLOR   = 1

wait_frame:
        lda #0
        sta intro_frame_ready
-       lda intro_frame_ready
        beq -
        rts

; ============================================================================
; MENU DE CONFIGURATION AUDIO SID AU DEMARRAGE (BOOT CARTOUCHE)
; ============================================================================
sid_setup_menu_init:
        ; Desactive la ROM BASIC pour acceder a toute la RAM
        lda #$36
        sta CPU_PORT

        ; Initialise la video
        lda #1
        sta CURSOR_FLAG                 ; Pas de curseur
        lda #COL_BLACK
        sta VIC_BACKGROUND
        sta VIC_BORDER
        lda #MEMSETUP_VALUE             ; Ecran $0400, caracteres $2000
        sta VIC_MEMSETUP
        lda VIC_CTRL2
        and #%11101111                  ; Texte haute resolution
        sta VIC_CTRL2
        jsr intro_init_raster_irq       ; Installe l'interruption raster synchronisee

        ; Efface l'ecran et les couleurs
        ldx #0
-       lda #32
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

        ; Configuration des 3 sprites Triforce geants (96x84 pixels)
        lda #< (spr_triforce_triangle / 64)
        sta SPRITE_PTR0
        sta SPRITE_PTR1
        sta SPRITE_PTR2

        ; Coordonnees VIC-II
        lda #160                        ; Sprite 0 (Triangle Haut) : centre X = 184 (184-24 = 160)
        sta VIC_SPRITE_X0
        lda #54                         ; Y = 54
        sta VIC_SPRITE_Y0

        lda #136                        ; Sprite 1 (Triangle Bas Gauche) : X = 136
        sta VIC_SPRITE_X1
        lda #96                         ; Y = 96 (54 + 42)
        sta VIC_SPRITE_Y1

        lda #184                        ; Sprite 2 (Triangle Bas Droit) : X = 184
        sta VIC_SPRITE_X2
        lda #96                         ; Y = 96
        sta VIC_SPRITE_Y2

        lda #0
        sta VIC_SPRITE_MSB              ; Aucun X >= 256
        sta VIC_SPRITE_MC               ; Monochrome haute resolution

        lda #%00000111
        sta VIC_SPRITE_EXP_X            ; Double largeur Sprites 0, 1, 2 (48 px chacun)
        sta VIC_SPRITE_EXP_Y            ; Double hauteur Sprites 0, 1, 2 (42 px chacun)

        lda #COL_YELLOW
        sta VIC_SPRITE_COL0
        sta VIC_SPRITE_COL1
        sta VIC_SPRITE_COL2

        lda #%00000111                  ; Active Sprites 0, 1, 2
        sta VIC_SPRITE_EN

        ; Affiche le titre a la ligne 13 (offset 520)
        ldx #0
-       lda .txt_menu_title,x
        beq +
        sta SCREEN_RAM+520+6,x
        lda #COL_WHITE
        sta COLOR_RAM+520+6,x
        inx
        bne -
+
        ; Affiche l'aide de controle a la ligne 21 (offset 840)
        ldx #0
-       lda .txt_menu_hint,x
        beq +
        sta SCREEN_RAM+840+5,x
        lda #COL_LGREY
        sta COLOR_RAM+840+5,x
        inx
        bne -
+
        ; Reinitialise variables de menu
        lda #0
        sta menu_cursor_idx
        sta menu_timeout_frames
        sta menu_timeout_frames+1

        jsr menu_redraw_options

sid_setup_menu_loop:
        jsr wait_frame
        jsr read_input
sid_setup_menu_check_input:

        ; Timeout automatique (~10s = 500 frames)
        inc menu_timeout_frames
        bne +
        inc menu_timeout_frames+1
+       lda menu_timeout_frames+1
        cmp #2                          ; 512 frames
        bcs .menu_confirm

        ; Touches directes '1'..'4'
        lda key_1_pressed
        beq +
        lda #0
        sta menu_cursor_idx
        jmp .menu_confirm
+       lda key_2_pressed
        beq +
        lda #1
        sta menu_cursor_idx
        jmp .menu_confirm
+       lda key_3_pressed
        beq +
        lda #2
        sta menu_cursor_idx
        jmp .menu_confirm
+       lda key_4_pressed
        beq +
        lda #3
        sta menu_cursor_idx
        jmp .menu_confirm
+

        ; Joystick Haut
        lda joy_pressed
        and #JOY_UP
        beq +
        lda menu_cursor_idx
        beq +
        dec menu_cursor_idx
        jsr menu_redraw_options
+

        ; Joystick Bas
        lda joy_pressed
        and #JOY_DOWN
        beq +
        lda menu_cursor_idx
        cmp #3
        bcs +
        inc menu_cursor_idx
        jsr menu_redraw_options
+

        ; Validation par Bouton A (Feu), Espace (Bouton X), ou Touche Return
        lda btn_a_pressed
        bne .menu_confirm
        lda btn_x_pressed
        bne .menu_confirm

        ; Teste la touche Return (Ligne 0, Colonne 1 du clavier C64)
        lda #$fe
        sta CIA1_PORT_A
        lda CIA1_PORT_B
        and #%00000010
        php
        lda #$ff
        sta CIA1_PORT_A
        plp
        beq .menu_confirm

        jmp sid_setup_menu_loop

.menu_confirm:
        ; Convertit menu_cursor_idx en selected_dual_sid et selected_sid2_addr_idx
        lda menu_cursor_idx
        bne .sel_stereo

        ; Option 0 : 1 SID Mono
        lda #0
        sta selected_dual_sid
        sta selected_sid2_addr_idx
        jmp .play_confirm_sound

.sel_stereo:
        lda #1
        sta selected_dual_sid
        lda menu_cursor_idx
        sec
        sbc #1                          ; Index 0->$D420, 1->$D500, 2->$DF00
        sta selected_sid2_addr_idx

.play_confirm_sound:
        ; Petit son de confirmation sur SID 1 (Voix 1)
        lda #15
        sta SID_VOLUME
        lda #0
        sta SID_V1_AD                   ; Attack/Decay
        lda #$a0
        sta SID_V1_SR                   ; Sustain/Release
        lda #$00
        sta SID_V1_PW_LO                ; Pulse width low
        lda #$08
        sta SID_V1_PW_HI                ; Pulse width high
        lda #<$1500
        sta SID_V1_FREQ_LO              ; Freq LO
        lda #>$1500
        sta SID_V1_FREQ_HI              ; Freq HI
        lda #$21                        ; Sawtooth + Gate ON
        sta SID_V1_CTRL
        ldx #5
-       jsr wait_frame
        dex
        bne -

        ; Palier bas Gate=0 (au moins 16 cycles selon Règle 6)
        lda #$20                        ; Gate OFF
        sta SID_V1_CTRL
        ldx #8
-       dex
        bne -

        ; Seconde note plus haute
        lda #<$2800
        sta SID_V1_FREQ_LO
        lda #>$2800
        sta SID_V1_FREQ_HI
        lda #$21                        ; Sawtooth + Gate ON
        sta SID_V1_CTRL
        ldx #8
-       jsr wait_frame
        dex
        bne -

        lda #$20                        ; Gate OFF
        sta SID_V1_CTRL
        ldx #4
-       jsr wait_frame
        dex
        bne -

        ; Eteint les sprites et restaure l'affichage
        lda #0
        sta VIC_SPRITE_EN
        sta VIC_SPRITE_EXP_X
        sta VIC_SPRITE_EXP_Y

        ; Enchaine avec l'intro normale
        jmp intro_standalone_init

menu_redraw_options:
        lda #0
        sta menu_opt_loop_idx

.opt_loop:
        ldx menu_opt_loop_idx

        ; Adresses ecran et couleur pour l'option X
        lda .opt_scr_lo,x
        sta ZP_SRC
        lda .opt_scr_hi,x
        sta ZP_SRC+1

        lda ZP_SRC
        sta ZP_DST
        lda .opt_col_hi,x
        sta ZP_DST+1

        ; Pointeur de texte pour l'option X dans ZP_SCR ($fb-$fc)
        lda .opt_txt_lo,x
        sta ZP_SCR
        lda .opt_txt_hi,x
        sta ZP_SCR+1

        ; Curseur '>' ou ' '
        cpx menu_cursor_idx
        bne .opt_unselected

        ; Option active : curseur '>' jaune, texte jaune
        lda #'>'
        ldy #2
        sta (ZP_SRC),y
        lda #COL_YELLOW
        sta (ZP_DST),y
        sta .cur_opt_col
        jmp .draw_chars

.opt_unselected:
        ; Option inactive : curseur ' ', texte gris
        lda #32
        ldy #2
        sta (ZP_SRC),y
        lda #COL_BLACK
        sta (ZP_DST),y
        lda #COL_GREY
        sta .cur_opt_col

.draw_chars:
        ldy #0
.char_loop:
        lda (ZP_SCR),y
        beq .opt_line_done
        pha
        tya
        clc
        adc #4                          ; Place le texte a partir de la colonne 4
        tay
        pla
        sta (ZP_SRC),y
.cur_opt_col = * + 1
        lda #COL_WHITE
        sta (ZP_DST),y
        tya
        sec
        sbc #4
        tay
        iny
        bne .char_loop

.opt_line_done:
        inc menu_opt_loop_idx
        lda menu_opt_loop_idx
        cmp #4
        bne .opt_loop
        rts

.txt_menu_title:
        !text "--- AUDIO HARDWARE SETUP ---", 0

.txt_menu_hint:
        !text "JOYSTICK OR KEYS 1-4 TO SELECT", 0

.txt_opt0:
        !text "[1] 1 SID - MONO (STANDARD C64)", 0
.txt_opt1:
        !text "[2] 2 SID - STEREO ($D420 - VICE)", 0
.txt_opt2:
        !text "[3] 2 SID - STEREO ($D500 - MIXSID)", 0
.txt_opt3:
        !text "[4] 2 SID - STEREO ($DF00 - I/O 2)", 0

.opt_scr_lo:
        !byte <(SCREEN_RAM + 600)       ; Ligne 15
        !byte <(SCREEN_RAM + 640)       ; Ligne 16
        !byte <(SCREEN_RAM + 680)       ; Ligne 17
        !byte <(SCREEN_RAM + 720)       ; Ligne 18

.opt_scr_hi:
        !byte >(SCREEN_RAM + 600)
        !byte >(SCREEN_RAM + 640)
        !byte >(SCREEN_RAM + 680)
        !byte >(SCREEN_RAM + 720)

.opt_col_hi:
        !byte >(COLOR_RAM + 600)
        !byte >(COLOR_RAM + 640)
        !byte >(COLOR_RAM + 680)
        !byte >(COLOR_RAM + 720)

.opt_txt_lo:
        !byte <.txt_opt0, <.txt_opt1, <.txt_opt2, <.txt_opt3
.opt_txt_hi:
        !byte >.txt_opt0, >.txt_opt1, >.txt_opt2, >.txt_opt3

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

        ; Transmet la configuration audio au déballeur en $0340
        lda selected_dual_sid
        sta .unp_cfg_dual_sid
        lda selected_sid2_addr_idx
        sta .unp_cfg_sid2_idx

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

        ; 4b. Transmet la configuration audio dans zelda.prg ($0811-$0812)
        lda #0
.unp_cfg_dual_sid = * - 1
        sta $0811

        lda #0
.unp_cfg_sid2_idx = * - 1
        sta $0812

        ; 5. Désactive la ROM cartouche ($80 = bit 7 actif désactive /ROML)
        lda #$80
        sta $de00

        ; 6. Saute au point d'entrée de zelda.prg (SYS 2061 = $080D)
        jmp $080d
}
.cart_unpacker_end:

