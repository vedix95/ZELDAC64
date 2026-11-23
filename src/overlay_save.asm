; ===========================================================================
; overlay_save.asm : Overlay Cartouche EasyFlash — Sauvegarde & File Select
; Banque 32 (CART_BANK_OVL_SAVE), chargée à $A000 (RAM sous BASIC)
;   - Pilote Flash Am29F040 (Secteur 7 : Banques 56..63 LoROM, journal 256 B)
;   - Menu original Zelda NES : - SELECT -, REGISTER YOUR NAME, ELIMINATION MODE
;   - Musique File Select (Fairy Fountain) en SID / Dual SID
;   - Sérialisation / Désérialisation des 3 slots via EasyFlash RAM ($DF00..$DF5F)
; ===========================================================================
!cpu 6510
!source "src/c64.inc"
!source "src/cart_defs.inc"
!source "build/resident_symbols.inc"

; EasyFlash RAM ($DF00..$DFFF) : zone d'échange persistante entre intro.prg et zelda.prg
EF_RAM_SLOT_IDX   = $df00       ; 0..2 = slot actif
EF_RAM_LOADED     = $df01       ; 1 = slot chargé à appliquer au boot de zelda.prg
EF_RAM_DUAL_SID   = $df02       ; 1 = Dual SID activé depuis l'intro
EF_RAM_SLOT_DATA  = $df10       ; 80 octets du slot actif ($df10..$df5f)

SAVE_SLOT_SIZE    = 80
SAVE_MAX_SLOTS    = 3
SAVE_MAGIC_0      = $5a         ; 'Z'
SAVE_MAGIC_1      = $4c         ; 'L'
SAVE_VERSION      = 1

; Offsets dans un slot de 80 octets
SL_ACTIVE         = 0
SL_NAME           = 1           ; 8 octets (1..8)
SL_DEATHS_LO      = 9
SL_DEATHS_HI      = 10
SL_MAX_HEARTS     = 11
SL_RUPEES         = 12
SL_BOMBS          = 13
SL_KEYS           = 14
SL_SWORD          = 15
SL_RING           = 16
SL_BRACELET       = 17
SL_MAGIC_KEY      = 18
SL_BOOK           = 19
SL_BOOMERANG      = 20
SL_BOW            = 21
SL_RAFT           = 22
SL_LADDER         = 23
SL_WHISTLE        = 24
SL_WAND           = 25
SL_CANDLE         = 26
SL_POTION         = 27
SL_LETTER         = 28
SL_TRIFORCE       = 29
SL_SEL_B          = 30
SL_OW_SECRETS     = 31          ; 7 octets (31..37)

* = OVERLAY_RAM_ADDR ; $A000

; Table de vecteurs ($A000..$A00B)
        jmp ovl_file_select_run         ; $A000 : Menu File Select (depuis intro)
        jmp ovl_save_apply_slot         ; $A003 : Restaure le slot actif dans zelda.prg
        jmp ovl_save_current_slot       ; $A006 : Sauvegarde le slot actif en Flash
        jmp ovl_save_inc_death          ; $A009 : Incrémente le compteur de morts + sauve

; ===========================================================================
; 1. PILOTE FLASH AM29F040 (Secteur 7 : Banques 56..63 LoROM = 64 Ko)
; ===========================================================================

; Variables internes de scan/écriture
save_next_idx:    !word 0       ; Prochain index libre (0..256)
save_best_idx:    !word 0       ; Meilleur index valide trouvé
save_best_seq:    !word 0
save_tmp_bank:    !byte 0
save_tmp_page:    !byte 0
save_crc_lo:      !byte 0
save_crc_hi:      !byte 0

; Calcule Fletcher-16 sur save_buf+7..save_buf+255 -> save_crc_lo/hi
calc_save_crc:
        lda #0
        sta save_crc_lo
        sta save_crc_hi
        ldx #7
.crc_loop:
        lda save_buf,x
        clc
        adc save_crc_lo
        sta save_crc_lo
        clc
        adc save_crc_hi
        sta save_crc_hi
        inx
        bne .crc_loop
        rts

; Copie le stub Flash en RAM ($0340) pour exécution hors ROM cartouche
install_flash_stubs:
        ldx #0
-       lda flash_ram_code,x
        sta $0340,x
        inx
        cpx #(flash_ram_code_end - flash_ram_code)
        bne -
        rts

; Stub exécuté en RAM ($0340) : lit 256 octets depuis banque A, page Y ($80..$9F) -> save_buf
; Entrée : A = bank (56..63), Y = page_hi ($80..$9F), ZP_DST = destination
; Note : $0340.. est en RAM basse, jamais écrasée par les banques cartouche.
flash_ram_code:
!pseudopc $0340 {
ram_read_page:
        sei
        sta CART_REG
        lda #CART_MODE_8K
        sta CART_CTRL
        lda #$37
        sta CPU_PORT
        sty ZP_SRC+1
        lda #0
        sta ZP_SRC
        ldy #0
-       lda (ZP_SRC),y
        sta (ZP_DST),y
        iny
        bne -
        lda #$36
        sta CPU_PORT
        lda #CART_MODE_OFF
        sta CART_CTRL
        cli
        rts

; Efface le Secteur 7 (banques 56..63) de la Flash Am29F040
; Note : EasyFlash exige le mode Ultimax ($85) pour router les écritures CPU $8000..$9FFF vers la Flash !
ram_erase_sec7:
        sei
        lda #$85
        sta CART_CTRL
        lda #$37
        sta CPU_PORT

        lda #0
        sta CART_REG
        lda #$aa
        sta $8555
        lda #$55
        sta $82aa
        lda #$80
        sta $8555
        lda #$aa
        sta $8555
        lda #$55
        sta $82aa

        lda #CART_BANK_SAVE_START
        sta CART_REG
        lda #$30
        sta $8000

        ; Attente fin d'effacement (DQ7 = 1, $8000 == $FF) avec timeout sécurité
        ldx #0
        ldy #0
.er_wait:
        lda $8000
        cmp #$ff
        beq .er_done
        dex
        bne .er_wait
        dey
        bne .er_wait
.er_done:
        lda #$36
        sta CPU_PORT
        lda #CART_MODE_OFF
        sta CART_CTRL
        cli
        rts

; Programme 256 octets de save_buf vers banque A (56..63), page Y ($80..$9F)
ram_prog_page:
        sta .prog_bank
        sty ZP_DST+1
        lda #0
        sta ZP_DST

        sei
        ldy #0
.pr_loop:
        ; Lire save_buf,y ($Bxxx) avec $01=$36 (RAM $A000..$BFFF visible) et EasyFlash OFF
        lda #$36
        sta CPU_PORT
        lda #CART_MODE_OFF
        sta CART_CTRL
        lda save_buf,y
        cmp #$ff
        beq .pr_skip            ; Octet $FF déjà vierge en Flash

        sta .prog_val
        lda #$37
        sta CPU_PORT
        lda #$85                ; Mode Ultimax ($85) requis pour écriture Flash sur EasyFlash
        sta CART_CTRL

        lda #0
        sta CART_REG
        lda #$aa
        sta $8555
        lda #$55
        sta $82aa
        lda #$a0
        sta $8555

        lda #0
.prog_bank = * - 1
        sta CART_REG
        lda #0
.prog_val = * - 1
        sta (ZP_DST),y

        ; Attente programmation (polling égalité avec timeout court)
        ldx #64
.pr_poll:
        lda (ZP_DST),y
        cmp .prog_val
        beq .pr_skip
        dex
        bne .pr_poll
.pr_skip:
        iny
        bne .pr_loop

        lda #$36
        sta CPU_PORT
        lda #CART_MODE_OFF
        sta CART_CTRL
        cli
        rts
}
flash_ram_code_end:

; Pointeurs des routines en $0340
RAM_READ_PAGE   = $0340 + (ram_read_page - ram_read_page)
RAM_ERASE_SEC7  = $0340 + (ram_erase_sec7 - ram_read_page)
RAM_PROG_PAGE   = $0340 + (ram_prog_page - ram_read_page)

; save_flash_scan : recherche la sauvegarde la plus récente dans le secteur 7 (0..255)
save_flash_scan:
        jsr install_flash_stubs
        lda #0
        sta save_next_idx
        sta save_next_idx+1
        sta save_best_seq
        sta save_best_seq+1
        lda #$ff
        sta save_best_idx
        sta save_best_idx+1

        ldx #0                          ; idx = 0..255
.scan_loop:
        txa
        pha
        ; bank = 56 + (idx >> 5)
        lsr
        lsr
        lsr
        lsr
        lsr
        clc
        adc #CART_BANK_SAVE_START
        sta save_tmp_bank
        ; page = $80 + (idx & 31)
        pla
        pha
        and #$1f
        clc
        adc #$80
        tay
        lda #<save_buf
        sta ZP_DST
        lda #>save_buf
        sta ZP_DST+1
        lda save_tmp_bank
        jsr RAM_READ_PAGE

        ; Page vierge ($FF) ? Alors fin du journal !
        lda save_buf
        cmp #$ff
        bne .chk_hdr
        pla
        sta save_next_idx
        lda #0
        sta save_next_idx+1
        jmp .scan_finish

.chk_hdr:
        cmp #SAVE_MAGIC_0
        bne .scan_next
        lda save_buf+1
        cmp #SAVE_MAGIC_1
        bne .scan_next
        lda save_buf+2
        cmp #SAVE_VERSION
        bne .scan_next

        jsr calc_save_crc
        lda save_crc_lo
        cmp save_buf+5
        bne .scan_next
        lda save_crc_hi
        cmp save_buf+6
        bne .scan_next

        ; Valide : compare seq > save_best_seq
        lda save_buf+4
        cmp save_best_seq+1
        bcc .scan_next
        bne .is_newer
        lda save_buf+3
        cmp save_best_seq
        bcc .scan_next
        beq .scan_next
.is_newer:
        lda save_buf+3
        sta save_best_seq
        lda save_buf+4
        sta save_best_seq+1
        pla
        pha
        sta save_best_idx
        lda #0
        sta save_best_idx+1

.scan_next:
        pla
        tax
        inx
        beq +
        jmp .scan_loop
+
        ; Secteur plein (256 blocs écrits)
        lda #0
        sta save_next_idx
        lda #1
        sta save_next_idx+1

.scan_finish:
        lda save_best_idx+1
        bmi .init_empty_buf
        ; Recharge le meilleur bloc dans save_buf
        lda save_best_idx
        lsr
        lsr
        lsr
        lsr
        lsr
        clc
        adc #CART_BANK_SAVE_START
        pha
        lda save_best_idx
        and #$1f
        clc
        adc #$80
        tay
        lda #<save_buf
        sta ZP_DST
        lda #>save_buf
        sta ZP_DST+1
        pla
        jsr RAM_READ_PAGE
        rts

.init_empty_buf:
        ldx #0
        lda #0
-       sta save_buf,x
        inx
        bne -
        lda #SAVE_MAGIC_0
        sta save_buf
        lda #SAVE_MAGIC_1
        sta save_buf+1
        lda #SAVE_VERSION
        sta save_buf+2
        rts

; save_flash_commit : écrit save_buf dans le prochain emplacement Flash libre
save_flash_commit:
        jsr install_flash_stubs
        lda #SAVE_MAGIC_0
        sta save_buf
        lda #SAVE_MAGIC_1
        sta save_buf+1
        lda #SAVE_VERSION
        sta save_buf+2

        inc save_buf+3
        bne +
        inc save_buf+4
+       jsr calc_save_crc
        lda save_crc_lo
        sta save_buf+5
        lda save_crc_hi
        sta save_buf+6

        lda save_next_idx+1
        beq .do_prog
        ; Secteur plein : efface Secteur 7 puis repart à 0
        jsr RAM_ERASE_SEC7
        lda #0
        sta save_next_idx
        sta save_next_idx+1

.do_prog:
        lda save_next_idx
        lsr
        lsr
        lsr
        lsr
        lsr
        clc
        adc #CART_BANK_SAVE_START
        pha
        lda save_next_idx
        and #$1f
        clc
        adc #$80
        tay
        pla
        jsr RAM_PROG_PAGE

        inc save_next_idx
        bne +
        inc save_next_idx+1
+       rts

; ===========================================================================
; 2. SÉRIALISATION / DÉSÉRIALISATION DES SLOTS (via EasyFlash RAM $DF10)
; ===========================================================================

; Calcule l'offset dans save_buf pour le slot A (0..2) -> X
get_slot_offset:
        cmp #0
        bne +
        ldx #8
        rts
+       cmp #1
        bne +
        ldx #88
        rts
+       ldx #168
        rts

; Copie le slot A (0..2) de save_buf vers EF_RAM_SLOT_DATA ($DF10..$DF5F)
copy_slot_to_efram:
        sta EF_RAM_SLOT_IDX
        jsr get_slot_offset
        ldy #0
-       lda save_buf,x
        sta EF_RAM_SLOT_DATA,y
        inx
        iny
        cpy #SAVE_SLOT_SIZE
        bne -
        lda #1
        sta EF_RAM_LOADED
        rts

; $A003 : Restaure les variables de zelda.prg depuis EF_RAM_SLOT_DATA ($DF10)
ovl_save_apply_slot:
        lda EF_RAM_LOADED
        bne +
        rts
+       lda #0
        sta EF_RAM_LOADED

        lda EF_RAM_SLOT_DATA + SL_MAX_HEARTS
        cmp #3
        bcs +
        lda #3
+       sta hud_max_hearts
        sta hud_cur_hearts
        lda EF_RAM_SLOT_DATA + SL_RUPEES
        sta hud_rupees
        lda EF_RAM_SLOT_DATA + SL_BOMBS
        sta hud_bombs
        lda EF_RAM_SLOT_DATA + SL_KEYS
        sta hud_keys
        lda EF_RAM_SLOT_DATA + SL_SWORD
        sta player_has_sword
        lda EF_RAM_SLOT_DATA + SL_RING
        sta player_has_blue_ring
        lda EF_RAM_SLOT_DATA + SL_BRACELET
        sta player_has_bracelet
        lda EF_RAM_SLOT_DATA + SL_MAGIC_KEY
        sta player_has_magic_key
        lda EF_RAM_SLOT_DATA + SL_BOOK
        sta player_has_book
        lda EF_RAM_SLOT_DATA + SL_BOOMERANG
        sta player_has_boomerang
        lda EF_RAM_SLOT_DATA + SL_BOW
        sta player_has_bow
        lda EF_RAM_SLOT_DATA + SL_RAFT
        sta player_has_raft
        lda EF_RAM_SLOT_DATA + SL_LADDER
        sta player_has_stepladder
        lda EF_RAM_SLOT_DATA + SL_WHISTLE
        sta player_has_whistle
        lda EF_RAM_SLOT_DATA + SL_WAND
        sta player_has_wand
        lda EF_RAM_SLOT_DATA + SL_CANDLE
        sta player_has_candle
        lda EF_RAM_SLOT_DATA + SL_POTION
        sta player_has_potion
        lda EF_RAM_SLOT_DATA + SL_TRIFORCE
        sta player_triforce_pieces
        lda EF_RAM_SLOT_DATA + SL_SEL_B
        sta hud_selected_b

        ldx #6
-       lda EF_RAM_SLOT_DATA + SL_OW_SECRETS,x
        sta overworld_secrets_opened,x
        dex
        bpl -
        jmp hud_render

; $A006 : Sauvegarde la partie courante de zelda.prg dans le slot actif en Flash
ovl_save_current_slot:
        jsr save_flash_scan
        lda EF_RAM_SLOT_IDX
        cmp #SAVE_MAX_SLOTS
        bcc +
        lda #0
        sta EF_RAM_SLOT_IDX
+       jsr get_slot_offset

        lda save_buf + SL_ACTIVE,x
        bne .slot_already_named
        ; Initialiser nom par défaut "LINK    " si slot neuf
        txa
        pha
        ldy #0
-       lda txt_default_name,y
        sta save_buf + SL_NAME,x
        inx
        iny
        cpy #8
        bne -
        pla
        tax
.slot_already_named:
        lda #1
        sta save_buf + SL_ACTIVE,x
        lda hud_max_hearts
        sta save_buf + SL_MAX_HEARTS,x
        lda hud_rupees
        sta save_buf + SL_RUPEES,x
        lda hud_bombs
        sta save_buf + SL_BOMBS,x
        lda hud_keys
        sta save_buf + SL_KEYS,x
        lda player_has_sword
        sta save_buf + SL_SWORD,x
        lda player_has_blue_ring
        sta save_buf + SL_RING,x
        lda player_has_bracelet
        sta save_buf + SL_BRACELET,x
        lda player_has_magic_key
        sta save_buf + SL_MAGIC_KEY,x
        lda player_has_book
        sta save_buf + SL_BOOK,x
        lda player_has_boomerang
        sta save_buf + SL_BOOMERANG,x
        lda player_has_bow
        sta save_buf + SL_BOW,x
        lda player_has_raft
        sta save_buf + SL_RAFT,x
        lda player_has_stepladder
        sta save_buf + SL_LADDER,x
        lda player_has_whistle
        sta save_buf + SL_WHISTLE,x
        lda player_has_wand
        sta save_buf + SL_WAND,x
        lda player_has_candle
        sta save_buf + SL_CANDLE,x
        lda player_has_potion
        sta save_buf + SL_POTION,x
        lda player_triforce_pieces
        sta save_buf + SL_TRIFORCE,x
        lda hud_selected_b
        sta save_buf + SL_SEL_B,x

        ; Copier overworld_secrets_opened (7 octets)
        txa
        clc
        adc #SL_OW_SECRETS
        tay
        ldx #0
-       lda overworld_secrets_opened,x
        sta save_buf,y
        iny
        inx
        cpx #7
        bne -

        jsr save_flash_commit
        lda EF_RAM_SLOT_IDX
        jsr copy_slot_to_efram
        lda #0
        sta EF_RAM_LOADED
        rts

; $A009 : Incrémente le compteur de morts du slot actif et sauvegarde en Flash
ovl_save_inc_death:
        jsr save_flash_scan
        lda EF_RAM_SLOT_IDX
        cmp #SAVE_MAX_SLOTS
        bcc +
        rts
+       jsr get_slot_offset
        lda save_buf + SL_ACTIVE,x
        bne +
        rts
+       inc save_buf + SL_DEATHS_LO,x
        bne +
        inc save_buf + SL_DEATHS_HI,x
+       jmp save_flash_commit

; ===========================================================================
; 3. RELAIS MUSIQUE FILE SELECT (vraie partition Zelda de intro.prg via $02F0)
; ===========================================================================
fs_music_init:
        rts

fs_music_update:
        lda $02f0
        cmp #$4c
        bne +
        jmp $02f0                       ; jmp intro_music_update (50 Hz)
+       rts

; ===========================================================================
; 4. MENU ORIGINAL ZELDA NES (FILE SELECT / REGISTER / ELIMINATION)
; ===========================================================================
FS_MODE_SELECT    = 0
FS_MODE_REGISTER  = 1
FS_MODE_ELIMINATE = 2

fs_mode:          !byte 0
fs_cursor:        !byte 0       ; 0..2 = slots, 3 = REGISTER, 4 = ELIMINATE
fs_reg_slot:      !byte 0
fs_reg_pos:       !byte 0       ; 0..7 curseur nom
fs_grid_idx:      !byte 0       ; 0..43 curseur grille alphabet
fs_joy_prev:      !byte $ff
fs_key_prev:      !byte $ff
fs_done_flag:     !byte 0
fs_tmp:           !byte 0
fs_cnt:           !byte 0
fs_color:         !byte 0

; Clavier matriciel simplifié (via $DC00/$DC01) & Joystick Port 2 ($DC00)
fs_read_nav:
        ; Retourne A = masque bits pressés (0=Up, 1=Down, 2=Left, 3=Right, 4=Fire/Enter)
        lda #$ff
        sta $dc02                       ; Port A sortie
        lda #$00
        sta $dc03                       ; Port B entrée
        lda $dc00                       ; Joystick Port 2 (bits actifs à 0)
        eor #$ff
        and #$1f
        sta ZP_TMP
        ; Debounce : front montant uniquement
        lda ZP_TMP
        eor fs_joy_prev
        and ZP_TMP
        pha
        lda ZP_TMP
        sta fs_joy_prev
        pla
        rts

; Efface l'écran texte ($0400) et Color RAM ($D800) en noir
fs_clear_screen:
        ldx #0
-       lda #32
        sta SCREEN_RAM,x
        sta SCREEN_RAM+$100,x
        sta SCREEN_RAM+$200,x
        sta SCREEN_RAM+$2e8,x
        lda #COL_WHITE
        sta COLOR_RAM,x
        sta COLOR_RAM+$100,x
        sta COLOR_RAM+$200,x
        sta COLOR_RAM+$2e8,x
        inx
        bne -
        rts

; Affiche chaîne terminée par 0 depuis (ZP_SRC) vers (ZP_DST)/(ZP_COL) avec couleur A
fs_print_at:
        sta fs_color
        ldy #0
-       lda (ZP_SRC),y
        beq +
        sta (ZP_DST),y
        lda fs_color
        sta (ZP_COL),y
        iny
        bne -
+       rts

; Helper : met ZP_DST = SCREEN_RAM + row*40 + col, ZP_COL = COLOR_RAM + row*40 + col
; Entrée : X = row (0..24), Y = col (0..39)
fs_set_pos:
        lda row_scr_lo,x
        sta ZP_DST
        sta ZP_COL
        lda row_scr_hi,x
        sta ZP_DST+1
        clc
        adc #>(COLOR_RAM - SCREEN_RAM)
        sta ZP_COL+1
        tya
        clc
        adc ZP_DST
        sta ZP_DST
        sta ZP_COL
        bcc +
        inc ZP_DST+1
        inc ZP_COL+1
+       rts

; Dessine l'écran File Select / Elimination
fs_draw_select_screen:
        jsr fs_clear_screen
        lda #COL_BLACK
        sta VIC_BACKGROUND
        sta VIC_BORDER
        lda #0
        sta VIC_SPRITE_EN

        ; Titre : "- SELECT -" ou "- ELIMINATE -"
        ldx #2
        ldy #14
        jsr fs_set_pos
        lda fs_mode
        cmp #FS_MODE_ELIMINATE
        beq .title_elim
        lda #<txt_title_select
        sta ZP_SRC
        lda #>txt_title_select
        sta ZP_SRC+1
        lda #COL_WHITE
        jmp +
.title_elim:
        lda #<txt_title_elim
        sta ZP_SRC
        lda #>txt_title_elim
        sta ZP_SRC+1
        lda #COL_RED
+       jsr fs_print_at

        ; Dessine les 3 slots (rows 6, 10, 14)
        lda #0
        sta fs_tmp
.slot_draw_loop:
        lda fs_tmp
        jsr get_slot_offset
        stx ZP_TMP                      ; ZP_TMP = offset dans save_buf

        ; Row = 6 + slot*4
        lda fs_tmp
        asl
        asl
        clc
        adc #6
        tax
        ldy #6
        jsr fs_set_pos

        ; Curseur coeur si fs_cursor == slot
        ldy #0
        lda fs_cursor
        cmp fs_tmp
        bne +
        lda #'*'
        sta (ZP_DST),y
        lda #COL_RED
        sta (ZP_COL),y
        jmp ++
+       lda #' '
        sta (ZP_DST),y
++
        ; Numéro "1." / "2." / "3."
        ldy #2
        lda fs_tmp
        clc
        adc #'1'
        sta (ZP_DST),y
        iny
        lda #'.'
        sta (ZP_DST),y

        ; Nom ou "- EMPTY -"
        ldx ZP_TMP
        lda save_buf + SL_ACTIVE,x
        beq .slot_empty

        ldy #5
        lda #0
        sta fs_cnt
-       ldx ZP_TMP
        clc
        txa
        adc fs_cnt
        tax
        lda save_buf + SL_NAME,x
        sta (ZP_DST),y
        lda #COL_WHITE
        sta (ZP_COL),y
        iny
        inc fs_cnt
        lda fs_cnt
        cmp #8
        bne -

        ; Cœurs max (petits cœurs '+' en rouge)
        ldx ZP_TMP
        lda save_buf + SL_MAX_HEARTS,x
        cmp #17
        bcc +
        lda #16
+       sta fs_cnt
        ldy #15
-       lda fs_cnt
        beq +
        lda #'#'
        sta (ZP_DST),y
        lda #COL_RED
        sta (ZP_COL),y
        iny
        dec fs_cnt
        jmp -
+       jmp .next_slot_draw

.slot_empty:
        ldy #5
        ldx #0
-       lda txt_empty,x
        beq .next_slot_draw
        sta (ZP_DST),y
        lda #COL_DGREY
        sta (ZP_COL),y
        iny
        inx
        bne -

.next_slot_draw:
        inc fs_tmp
        lda fs_tmp
        cmp #SAVE_MAX_SLOTS
        beq +
        jmp .slot_draw_loop
+

        ; Options du bas : REGISTER YOUR NAME (row 19), ELIMINATION MODE (row 21)
        ldx #19
        ldy #8
        jsr fs_set_pos
        lda #<txt_opt_register
        sta ZP_SRC
        lda #>txt_opt_register
        sta ZP_SRC+1
        lda #COL_YELLOW
        jsr fs_print_at
        lda fs_cursor
        cmp #3
        bne +
        ldx #19
        ldy #6
        jsr fs_set_pos
        ldy #0
        lda #'*'
        sta (ZP_DST),y
        lda #COL_RED
        sta (ZP_COL),y
+
        ldx #21
        ldy #8
        jsr fs_set_pos
        lda #<txt_opt_eliminate
        sta ZP_SRC
        lda #>txt_opt_eliminate
        sta ZP_SRC+1
        lda #COL_LIGHT_RED
        jsr fs_print_at
        lda fs_cursor
        cmp #4
        bne +
        ldx #21
        ldy #6
        jsr fs_set_pos
        ldy #0
        lda #'*'
        sta (ZP_DST),y
        lda #COL_RED
        sta (ZP_COL),y
+       rts

; Dessine l'écran REGISTER YOUR NAME
fs_draw_register_screen:
        jsr fs_clear_screen
        ldx #2
        ldy #10
        jsr fs_set_pos
        lda #<txt_title_register
        sta ZP_SRC
        lda #>txt_title_register
        sta ZP_SRC+1
        lda #COL_YELLOW
        jsr fs_print_at

        ; Affiche le nom en cours (8 chars) à row 6, col 15
        ldx #6
        ldy #15
        jsr fs_set_pos
        lda fs_reg_slot
        jsr get_slot_offset
        stx ZP_TMP
        ldy #0
.reg_nm:
        ldx ZP_TMP
        lda save_buf + SL_NAME,x
        sta (ZP_DST),y
        lda #COL_WHITE
        cpy fs_reg_pos
        bne +
        lda #COL_CYAN
+       sta (ZP_COL),y
        inc ZP_TMP
        iny
        cpy #8
        bne .reg_nm

        ; Grille 11 colonnes x 4 rangées (44 symboles : A-Z, 0-9, ponctuation, END)
        lda #0
        sta fs_tmp                       ; index 0..43
.grid_loop:
        ; row = 10 + (idx / 11) * 2
        lda fs_tmp
        ldx #0
-       cmp #11
        bcc +
        sec
        sbc #11
        inx
        jmp -
+       ; A = col_idx (0..10), X = row_idx (0..3)
        asl                             ; *2 pour espacement
        clc
        adc #9
        tay
        txa
        asl
        clc
        adc #10
        tax
        jsr fs_set_pos

        ldx fs_tmp
        lda fs_alphabet,x
        ldy #0
        sta (ZP_DST),y
        lda #COL_WHITE
        cpx fs_grid_idx
        bne +
        lda #COL_YELLOW
+       sta (ZP_COL),y

        inc fs_tmp
        lda fs_tmp
        cmp #44
        bne .grid_loop

        ldx #21
        ldy #7
        jsr fs_set_pos
        lda #<txt_reg_hint
        sta ZP_SRC
        lda #>txt_reg_hint
        sta ZP_SRC+1
        lda #COL_LIGHT_BLUE
        jmp fs_print_at

; $A000 : Boucle principale du Menu File Select (appelée depuis intro_main.asm)
ovl_file_select_run:
        jsr save_flash_scan
        jsr fs_music_init
        lda #FS_MODE_SELECT
        sta fs_mode
        lda #0
        sta fs_cursor
        sta fs_done_flag
        lda #$ff
        sta fs_joy_prev
        jsr fs_draw_select_screen

.fs_loop:
        ; Synchro 1 frame PAL
-       lda VIC_CTRL1
        bmi -
-       lda VIC_RASTER
        cmp #248
        bcc -

        jsr fs_music_update
        jsr fs_read_nav
        beq .fs_loop

        ldx fs_mode
        cpx #FS_MODE_REGISTER
        bne +
        jmp .handle_reg
+

        ; --- Navigation SELECT / ELIMINATE ---
        pha
        and #$01                        ; UP
        beq +
        lda fs_cursor
        beq +
        dec fs_cursor
        jsr fs_draw_select_screen
+       pla
        pha
        and #$02                        ; DOWN
        beq +
        lda fs_cursor
        cmp #4
        bcs +
        inc fs_cursor
        jsr fs_draw_select_screen
+       pla
        and #$10                        ; FIRE / ENTER
        beq .fs_loop

        lda fs_cursor
        cmp #3
        beq .enter_reg_mode
        cmp #4
        beq .toggle_elim_mode

        ; Action sur un slot 0..2
        ldx fs_mode
        cpx #FS_MODE_ELIMINATE
        beq .do_eliminate_slot

        ; Mode SELECT : vérifier si occupé
        jsr get_slot_offset
        lda save_buf + SL_ACTIVE,x
        bne .launch_slot
        ; Slot vide : ouvrir Register sur ce slot !
        lda fs_cursor
        jmp .start_reg_on_slot

.launch_slot:
        lda fs_cursor
        jsr copy_slot_to_efram
        ; Coupe SID proprement et retourne à intro_main pour lancer zelda.prg
        lda #0
        sta SID_VOLUME
        sta SID2_VOLUME
        rts

.do_eliminate_slot:
        lda fs_cursor
        jsr get_slot_offset
        ldy #0
        lda #0
-       sta save_buf,x
        inx
        iny
        cpy #SAVE_SLOT_SIZE
        bne -
        jsr save_flash_commit
        lda #FS_MODE_SELECT
        sta fs_mode
        jsr fs_draw_select_screen
        jmp .fs_loop

.toggle_elim_mode:
        lda fs_mode
        eor #FS_MODE_ELIMINATE
        sta fs_mode
        jsr fs_draw_select_screen
        jmp .fs_loop

.enter_reg_mode:
        ; Trouve le premier slot libre (ou slot 0)
        lda #0
        sta ZP_TMP
-       lda ZP_TMP
        jsr get_slot_offset
        lda save_buf + SL_ACTIVE,x
        beq .found_free_reg
        inc ZP_TMP
        lda ZP_TMP
        cmp #SAVE_MAX_SLOTS
        bne -
        lda #0
        sta ZP_TMP
.found_free_reg:
        lda ZP_TMP
.start_reg_on_slot:
        sta fs_reg_slot
        jsr get_slot_offset
        ; Initialise le slot vierge avec nom "LINK    "
        ldy #0
        lda #0
-       sta save_buf,x
        inx
        iny
        cpy #SAVE_SLOT_SIZE
        bne -
        lda fs_reg_slot
        jsr get_slot_offset
        lda #1
        sta save_buf + SL_ACTIVE,x
        lda #3
        sta save_buf + SL_MAX_HEARTS,x
        ldy #0
-       lda txt_default_name,y
        sta save_buf + SL_NAME,x
        inx
        iny
        cpy #8
        bne -
        lda #FS_MODE_REGISTER
        sta fs_mode
        lda #0
        sta fs_reg_pos
        sta fs_grid_idx
        jsr fs_draw_register_screen
        jmp .fs_loop

.handle_reg:
        pha
        and #$04                        ; LEFT
        beq +
        lda fs_grid_idx
        beq +
        dec fs_grid_idx
        jsr fs_draw_register_screen
+       pla
        pha
        and #$08                        ; RIGHT
        beq +
        lda fs_grid_idx
        cmp #43
        bcs +
        inc fs_grid_idx
        jsr fs_draw_register_screen
+       pla
        pha
        and #$01                        ; UP
        beq +
        lda fs_grid_idx
        cmp #11
        bcc +
        sec
        sbc #11
        sta fs_grid_idx
        jsr fs_draw_register_screen
+       pla
        pha
        and #$02                        ; DOWN
        beq +
        lda fs_grid_idx
        cmp #33
        bcs +
        clc
        adc #11
        sta fs_grid_idx
        jsr fs_draw_register_screen
+       pla
        and #$10                        ; FIRE -> choisit lettre ou '*' (END)
        bne +
        jmp .fs_loop
+       ldx fs_grid_idx
        lda fs_alphabet,x
        cmp #'*'                        ; '*' = END / Valider
        beq .finish_register

        pha
        lda fs_reg_slot
        jsr get_slot_offset
        txa
        clc
        adc fs_reg_pos
        tax
        pla
        sta save_buf + SL_NAME,x
        inc fs_reg_pos
        lda fs_reg_pos
        cmp #8
        bcc +
        lda #0
        sta fs_reg_pos
+       jsr fs_draw_register_screen
        jmp .fs_loop

.finish_register:
        jsr save_flash_commit
        lda #FS_MODE_SELECT
        sta fs_mode
        lda fs_reg_slot
        sta fs_cursor
        jsr fs_draw_select_screen
        jmp .fs_loop

; Tables et chaînes (en ACME, !scr convertit a..z -> 1..26 = lettres A..Z à l'écran C64)
txt_title_select:   !scr "- select -" : !byte 0
txt_title_elim:     !scr "- eliminate -" : !byte 0
txt_title_register: !scr "register your name" : !byte 0
txt_empty:          !scr "- empty -" : !byte 0
txt_default_name:   !scr "link    "
txt_opt_register:   !scr "register your name" : !byte 0
txt_opt_eliminate:  !scr "elimination mode" : !byte 0
txt_reg_hint:       !scr "fire: letter   *: save & exit" : !byte 0

fs_alphabet:
        !scr "abcdefghijklmnopqrstuvwxyz0123456789-.,!'& *"

row_scr_lo:
        !for r, 0, 24 {
            !byte <(SCREEN_RAM + r * 40)
        }
row_scr_hi:
        !for r, 0, 24 {
            !byte >(SCREEN_RAM + r * 40)
        }

; Tampon 256 octets pour lecture/écriture Flash
        !align 255, 0
save_buf:
        !fill 256, 0
