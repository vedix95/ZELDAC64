!cpu 6510
* = $0801
    !word basic_end
    !word 10
    !byte $9e
    !text "2061"
    !byte 0
basic_end:
    !word 0

start:
    sei
    lda #0
    sta $d020
    sta $d021
    lda #147
    jsr $ffd2

loop:
    ; Read Port A ($dc00), Port B ($dc01), POTX ($d419), POTY ($d41a), Control port registers
    ; Display them on screen line 0..5
    ldx #0
-   lda $dc00
    sta $0400,x
    lda $dc01
    sta $0428,x
    lda $d419
    sta $0450,x
    lda $d41a
    sta $0478,x
    jmp loop
