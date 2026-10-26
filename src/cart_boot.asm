; ===========================================================================
; cart_boot.asm : Chargeur de démarrage pour Cartouche Magic Desk (Type 19)
; 8 Ko ROM mappés à $8000..$9FFF au reset KERNAL
; ===========================================================================
!cpu 6510
* = $8000

CART_REG          = $de00
CART_DISABLE      = $80
CART_PRESENT_ADDR = $0810
START_ADDR        = $080d

; En-tête standard cartouche Commodore 64
        !word cart_reset                ; $8000 : Vecteur Cold Start
        !word cart_reset                ; $8002 : Vecteur Warm Start
        !byte $c3, $c2, $cd, $38, $30  ; $8004..$8008 : "CBM80"

cart_reset:
        sei
        cld
        ldx #$ff
        txs

        ; Initialisation matérielle standard KERNAL C64
        jsr $fda3       ; Initialise les timers CIA et le bus IEC
        jsr $fd50       ; Initialise les vecteurs mémoire RAM
        jsr $fd15       ; Restaure les vecteurs KERNAL I/O
        jsr $ff5b       ; Initialise l'écran VIC-II

        ; Coupe le volume sonore SID et couleurs de bordure/fond
        lda #0
        sta $d418
        sta $d020
        sta $d021

        ; Copie le déballeur de cartouche en RAM basse ($0340..$03bf, tampon cassette)
        ldx #0
-       lda cart_unpacker,x
        sta $0340,x
        inx
        cpx #(cart_unpacker_end - cart_unpacker)
        bne -

        ; Exécute le déballeur depuis la RAM pour pouvoir commuter librement les banques
        jmp $0340

cart_unpacker:
!pseudopc $0340 {
        ; 1. LORAM=1 ($37) pour que la ROM cartouche soit active et lisible à $8000..$9FFF
        lda #$37
        sta $01

        ; 2. Boucle de déballage des banques 1..3 de intro.prg
        ;    Banque 1 -> RAM $0800..$27FF
        ;    Banque 2 -> RAM $2800..$47FF
        ;    Banque 3 -> RAM $4800..$67FF
        lda #1
        sta $02                         ; Numéro de banque cartouche (1..3)
        lda #$08
        sta $03                         ; Page haute destination en RAM ($08, $28, $48)

.bank_loop:
        lda $02
        sta CART_REG                    ; Mappe la banque à $8000

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
        cmp #4                          ; Banques 1 à 3 traitées ?
        bcc .bank_loop

        ; Désactive la ROM BASIC ($A000..$BFFF) pour libérer la RAM
        lda #$36
        sta $01

        ; 3. Marque la présence de la cartouche pour intro.prg
        lda #1
        sta CART_PRESENT_ADDR           ; $0810

        ; 4. Désactive la ROM de cartouche pour libérer $8000..$9FFF en RAM normale
        lda #CART_DISABLE
        sta CART_REG

        ; 5. Démarre l'intro Zelda à son point d'entrée SYS 2061
        jmp START_ADDR                  ; $080D
}
cart_unpacker_end:
