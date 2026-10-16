!cpu 6510
* = $0801
!word .basic_end
!word 10
!byte $9e
!text "2061"
!byte 0
.basic_end:
!word 0

start:
        sei
        lda #$36
        sta $01                         ; RAM $A000, I/O $D000, KERNAL $E000
        cli

        ; Teste le chargement de MAP_OW avec OPEN/CHKIN/CHRIN
        lda #6
        ldx #< name_ow
        ldy #> name_ow
        jsr test_stream_load
        sta result_code

        ; Sauvegarde les 32 premiers octets de $A000
        ldx #0
-       lda $a000,x
        sta dump_buf,x
        inx
        cpx #32
        bne -

        ; Arrêt
        rts

name_ow: !text "MAP_OW"
result_code: !byte 0
dump_buf: !fill 32, 0

SETLFS = $ffba
SETNAM = $ffbd
OPEN   = $ffc0
CLOSE  = $ffc3
CHKIN  = $ffc6
CLRCHN = $ffcc
CHRIN  = $ffcf
READST = $ffb7

ZP_PTR = $02

test_stream_load:
        sta .namelen
        stx .nameptr
        sty .nameptr+1

        ; SETNAM
        lda .namelen
        ldx .nameptr
        ldy .nameptr+1
        jsr SETNAM

        ; SETLFS : LFN=1, Dev=8, SA=0
        lda #1
        ldx #8
        ldy #0
        jsr SETLFS

        jsr OPEN
        bcc +
        lda #1                          ; Erreur OPEN
        rts
+
        ldx #1
        jsr CHKIN
        bcc +
        lda #2                          ; Erreur CHKIN
        rts
+
        ; Lit l'adresse de chargement (2 octets)
        jsr CHRIN
        sta ZP_PTR
        jsr CHRIN
        sta ZP_PTR+1

        ; Boucle de lecture
        ldy #0
.read_loop:
        jsr READST
        bne .check_st

        jsr CHRIN
        sta (ZP_PTR),y
        inc ZP_PTR
        bne +
        inc ZP_PTR+1
+
        jmp .read_loop

.check_st:
        ; Si EOF (bit 6), lit le dernier octet éventuel
        and #$40
        beq .io_error

        ; Fin normale
        jsr CLRCHN
        lda #1
        jsr CLOSE
        lda #0                          ; Succès
        rts

.io_error:
        jsr CLRCHN
        lda #1
        jsr CLOSE
        lda #3                          ; Erreur I/O
        rts

.namelen: !byte 0
.nameptr: !word 0
