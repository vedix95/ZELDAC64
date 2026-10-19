; ===========================================================================
; music_data.inc - Partition authentique Overworld & Underworld pour Zelda C64
; GENERE AUTOMATIQUEMENT par tools/generate_game_audio.py - NE PAS MODIFIER
; ===========================================================================

MUSIC_NOTE_COUNT    = 55
MUSIC_OW_P1_LEN     = 111
MUSIC_OW_P2_LEN     = 112
MUSIC_UW_LEN        = 116
MUSIC_ITEM_LEN      = 4
MUSIC_TRIFORCE_LEN  = 41

; Table des frequences SID (Index 0 = Silence)
music_note_freq_lo:
        !byte $00, $2b, $7b, $ce, $26, $84, $e7, $4f, $c0, $36, $b1, $35, $c4, $56, $f1, $97
        !byte $47, $4c, $02, $08, $c7, $97, $9e, $80, $6d, $62, $6b, $7a, $88, $ab, $e2, $1c
        !byte $2e, $7a, $8f, $04, $8f, $2e, $4b, $01, $c7, $c5, $d6, $f5, $56, $c5, $37, $f4
        !byte $08, $1e, $97, $01, $45, $8a, $ac, $82
music_note_freq_hi:
        !byte $00, $05, $05, $05, $06, $06, $06, $07, $07, $08, $08, $09, $09, $0a, $0a, $0b
        !byte $0c, $0c, $0d, $0d, $0d, $0e, $0e, $0f, $10, $11, $12, $13, $13, $14, $15, $17
        !byte $17, $18, $18, $1a, $1b, $1d, $1d, $1f, $20, $22, $24, $26, $29, $2b, $2e, $30
        !byte $34, $37, $3a, $3e, $41, $45, $49, $4d

; --- music_ow_p1 (111 pas) ---
music_ow_p1_dur:
        !byte  10,  10,   7,   7,   7,  10,   5,   5,   5,   5,   5,   5,  10,   5,   5,   5
        !byte   2,   3,   3,   2,   5,  10,  10,   7,   7,   7,  10,   5,   5,   5,   2,   3
        !byte   3,   2,   5,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7,   7
        !byte   7,   7,   7,   7,   7,  10,   5,   5,   7,   3,   3,   2,   5,  20,   7,   3
        !byte   3,   7,  10,   5,   5,   7,   3,   3,   2,   5,  20,   7,   3,   3,   7,  10
        !byte   5,   5,   7,   3,   3,   2,   5,  10,   5,   5,   7,   3,   3,   7,   5,   5
        !byte   5,   5,   5,   5,   5,   5,   5,   5,   5,   5,  10,  10,  10,  10,   7
music_ow_p1_v1:
        !byte $27, $00, $20, $fe, $fe, $fe, $00, $27, $27, $29, $2b, $2c, $2e, $fe, $fe, $fe
        !byte $fe, $fe, $fe, $fe, $fe, $00, $2e, $2e, $2f, $31, $33, $fe, $fe, $fe, $fe, $fe
        !byte $fe, $fe, $fe, $00, $33, $33, $33, $31, $2f, $31, $00, $2f, $2e, $fe, $fe, $fe
        !byte $fe, $fe, $2e, $fe, $fe, $2c, $2c, $2e, $2f, $fe, $fe, $fe, $fe, $fe, $2e, $fe
        !byte $2c, $fe, $2a, $2a, $2c, $2e, $fe, $fe, $fe, $fe, $fe, $2c, $fe, $2a, $fe, $29
        !byte $29, $2b, $2d, $fe, $fe, $fe, $fe, $fe, $fe, $fe, $30, $fe, $fe, $fe, $2e, $00
        !byte $20, $20, $20, $00, $20, $20, $20, $00, $20, $20, $20, $20, $27, $00, $20
music_ow_p1_v2:
        !byte $1c, $00, $1c, $1c, $19, $1c, $00, $1c, $1c, $1d, $20, $23, $24, $00, $27, $27
        !byte $29, $fe, $2b, $fe, $2c, $2e, $fe, $24, $27, $29, $2a, $00, $22, $22, $24, $fe
        !byte $27, $fe, $29, $2a, $00, $2a, $2a, $29, $27, $2a, $00, $24, $24, $24, $22, $24
        !byte $00, $24, $24, $22, $24, $22, $22, $20, $22, $fe, $22, $fe, $24, $27, $24, $fe
        !byte $22, $fe, $20, $20, $1d, $20, $fe, $20, $fe, $22, $24, $22, $fe, $20, $fe, $1e
        !byte $fe, $fe, $1e, $fe, $1e, $fe, $20, $23, $23, $25, $27, $fe, $29, $fe, $25, $fe
        !byte $16, $16, $16, $fe, $16, $16, $16, $fe, $16, $16, $16, $16, $1c, $00, $1c
music_ow_p1_v3:
        !byte $08, $fe, $08, $08, $06, $08, $fe, $fe, $08, $fe, $fe, $fe, $06, $fe, $fe, $06
        !byte $fe, $06, $fe, $04, $fe, $06, $fe, $06, $fe, $fe, $04, $fe, $fe, $04, $fe, $04
        !byte $fe, $02, $fe, $04, $fe, $fe, $04, $fe, $fe, $0b, $fe, $fe, $0b, $0b, $0a, $0b
        !byte $fe, $fe, $0b, $fe, $fe, $09, $fe, $fe, $09, $09, $fe, $08, $fe, $09, $09, $09
        !byte $fe, $09, $08, $fe, $fe, $08, $08, $fe, $06, $fe, $08, $08, $08, $fe, $08, $0a
        !byte $fe, $fe, $0a, $0a, $fe, $09, $fe, $0a, $fe, $fe, $0a, $0a, $fe, $0a, $03, $fe
        !byte $fe, $fe, $03, $fe, $fe, $fe, $03, $fe, $fe, $fe, $05, $07, $08, $fe, $08

; --- music_ow_p2 (112 pas) ---
music_ow_p2_dur:
        !byte   7,   7,  10,   5,   5,   5,   5,   5,   5,  10,   5,   5,   5,   2,   3,   3
        !byte   2,   5,  10,  10,   7,   7,   7,  20,   7,   7,   7,  20,  20,  10,  10,   7
        !byte   7,   7,  20,  20,   7,   7,   7,   7,   7,   7,  20,  20,  10,  10,   7,   7
        !byte   7,  20,  20,   7,   7,   7,   7,   7,   7,  20,  20,  10,  10,   7,   7,   7
        !byte  20,  20,  20,   7,   7,   7,  20,   7,   7,   7,  10,  10,   7,   7,   7,  20
        !byte   7,   7,   7,  10,   5,   5,   7,   3,   3,   2,   5,  10,   5,   5,   7,   3
        !byte   3,   7,   5,   5,   5,   5,   5,   5,   5,   5,   5,   5,   5,   5,  10,  10
music_ow_p2_v1:
        !byte $fe, $fe, $fe, $00, $27, $27, $29, $2b, $2c, $2e, $fe, $fe, $fe, $fe, $fe, $fe
        !byte $fe, $fe, $00, $2e, $2e, $2f, $31, $33, $fe, $fe, $fe, $fe, $36, $35, $00, $32
        !byte $fe, $fe, $fe, $2e, $2f, $fe, $fe, $fe, $fe, $fe, $fe, $33, $32, $00, $2e, $fe
        !byte $fe, $fe, $2e, $2f, $fe, $fe, $fe, $fe, $fe, $fe, $33, $32, $00, $2e, $fe, $fe
        !byte $fe, $2b, $2c, $fe, $fe, $fe, $fe, $2f, $fe, $fe, $2e, $00, $2a, $fe, $fe, $fe
        !byte $27, $fe, $fe, $29, $29, $2b, $2d, $fe, $fe, $fe, $fe, $fe, $fe, $fe, $30, $fe
        !byte $fe, $fe, $2e, $00, $20, $20, $20, $00, $20, $20, $20, $00, $20, $20, $20, $20
music_ow_p2_v2:
        !byte $1c, $19, $1c, $00, $1c, $1c, $1d, $20, $23, $24, $00, $27, $27, $29, $fe, $2b
        !byte $fe, $2c, $2e, $fe, $24, $27, $29, $2a, $fe, $fe, $fe, $fe, $2d, $2c, $00, $29
        !byte $fe, $fe, $fe, $25, $28, $fe, $fe, $fe, $fe, $fe, $fe, $2a, $29, $00, $25, $fe
        !byte $fe, $fe, $25, $28, $fe, $fe, $fe, $fe, $fe, $fe, $2a, $29, $00, $25, $fe, $fe
        !byte $fe, $25, $22, $fe, $fe, $fe, $fe, $28, $fe, $fe, $27, $00, $20, $fe, $fe, $fe
        !byte $1a, $fe, $fe, $1e, $fe, $fe, $1e, $fe, $1e, $fe, $20, $23, $23, $25, $27, $fe
        !byte $29, $fe, $25, $fe, $16, $16, $16, $fe, $16, $16, $16, $fe, $16, $16, $16, $16
music_ow_p2_v3:
        !byte $08, $06, $08, $fe, $fe, $08, $fe, $fe, $fe, $06, $fe, $fe, $06, $fe, $06, $fe
        !byte $04, $fe, $06, $fe, $06, $fe, $fe, $04, $04, $04, $02, $04, $04, $03, $fe, $03
        !byte $03, $01, $03, $03, $02, $08, $0b, $0e, $17, $1a, $1e, $fe, $1f, $fe, $03, $03
        !byte $03, $03, $fe, $02, $08, $0b, $0e, $17, $1a, $1e, $fe, $1f, $fe, $03, $03, $03
        !byte $03, $fe, $09, $09, $09, $08, $09, $09, $09, $09, $08, $fe, $08, $08, $06, $08
        !byte $08, $08, $08, $0a, $fe, $fe, $0a, $0a, $fe, $09, $fe, $0a, $fe, $fe, $0a, $0a
        !byte $fe, $0a, $03, $fe, $fe, $fe, $03, $fe, $fe, $fe, $03, $fe, $fe, $fe, $05, $07

; --- music_uw (116 pas) ---
music_uw_dur:
        !byte   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8
        !byte   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8
        !byte   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8
        !byte   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8
        !byte   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8
        !byte   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8
        !byte   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8,   8
        !byte   8,   8,   8,   8
music_uw_v1:
        !byte $23, $fe, $2b, $fe, $23, $fe, $2b, $fe, $23, $fe, $2b, $fe, $23, $fe, $2b, $fe
        !byte $22, $fe, $2b, $fe, $22, $fe, $2b, $fe, $22, $fe, $2b, $fe, $22, $fe, $2b, $fe
        !byte $20, $fe, $2b, $fe, $20, $fe, $2b, $fe, $20, $fe, $2b, $fe, $20, $fe, $2b, $fe
        !byte $1e, $fe, $2b, $fe, $1e, $fe, $2b, $fe, $1e, $fe, $2b, $fe, $1e, $fe, $2b, $fe
        !byte $1d, $fe, $29, $fe, $1d, $fe, $29, $fe, $1d, $fe, $29, $fe, $1d, $fe, $29, $fe
        !byte $1c, $fe, $29, $fe, $1c, $fe, $29, $fe, $1c, $fe, $29, $fe, $1c, $fe, $29, $fe
        !byte $19, $fe, $25, $fe, $22, $fe, $29, $fe, $25, $fe, $2c, $fe, $2c, $fe, $2c, $fe
        !byte $32, $fe, $32, $fe
music_uw_v2:
        !byte $00, $27, $fe, $2c, $fe, $27, $fe, $2c, $fe, $27, $fe, $2c, $fe, $27, $fe, $2c
        !byte $fe, $25, $fe, $2c, $fe, $25, $fe, $2c, $fe, $25, $fe, $2c, $fe, $25, $fe, $2c
        !byte $fe, $24, $fe, $2c, $fe, $24, $fe, $2c, $fe, $24, $fe, $2c, $fe, $24, $fe, $2c
        !byte $fe, $23, $fe, $2c, $fe, $23, $fe, $2c, $fe, $23, $fe, $2c, $fe, $23, $fe, $2c
        !byte $00, $23, $fe, $2b, $fe, $23, $fe, $2b, $fe, $23, $fe, $2b, $fe, $23, $fe, $2b
        !byte $fe, $23, $fe, $2b, $fe, $23, $fe, $2b, $fe, $23, $fe, $2b, $fe, $23, $fe, $2b
        !byte $fe, $22, $fe, $29, $fe, $25, $fe, $2c, $fe, $29, $fe, $29, $fe, $2f, $fe, $2f
        !byte $fe, $2f, $fe, $35
music_uw_v3:
        !byte $12, $fe, $fe, $fe, $00, $00, $00, $00, $17, $fe, $fe, $fe, $1b, $fe, $fe, $fe
        !byte $1a, $fe, $fe, $fe, $10, $fe, $fe, $fe, $00, $00, $00, $00, $00, $00, $00, $00
        !byte $0f, $fe, $fe, $fe, $00, $00, $00, $00, $0f, $fe, $00, $14, $00, $00, $1a, $fe
        !byte $19, $fe, $fe, $fe, $0e, $fe, $fe, $fe, $00, $00, $00, $00, $00, $00, $00, $00
        !byte $0d, $0c, $0d, $fe, $fe, $fe, $00, $00, $12, $fe, $00, $1d, $00, $00, $1b, $fe
        !byte $0c, $0b, $0c, $fe, $fe, $fe, $00, $00, $12, $fe, $00, $1b, $00, $00, $1a, $fe
        !byte $0c, $10, $15, $10, $15, $19, $15, $19, $1d, $19, $1d, $21, $26, $21, $1d, $19
        !byte $1d, $19, $15, $10

; --- music_item_fanfare (4 pas) ---
music_item_fanfare_dur:
        !byte  10,  10,  10,  40
music_item_fanfare_v1:
        !byte $19, $1a, $1c, $1d
music_item_fanfare_v2:
        !byte $25, $27, $28, $29
music_item_fanfare_v3:
        !byte $0f, $10, $12, $14

; --- music_triforce (41 pas) ---
music_triforce_dur:
        !byte   7,   7,   7,  20,   7,   7,   7,  20,   5,   5,   5,   5,  20,   5,   5,   5
        !byte   5,  20,   7,   7,   7,  20,   7,   7,   7,  20,   5,   5,   5,   5,  20,   5
        !byte   5,   5,   5,  20,   5,   5,   5,   5,  30
music_triforce_v1:
        !byte $1c, $1c, $1c, $23, $fe, $fe, $fe, $fe, $23, $25, $28, $29, $2b, $fe, $fe, $fe
        !byte $fe, $fe, $2b, $2b, $2b, $30, $fe, $fe, $fe, $fe, $30, $32, $34, $35, $37, $fe
        !byte $fe, $fe, $fe, $fe, $1c, $1c, $00, $1c, $23
music_triforce_v2:
        !byte $00, $00, $00, $00, $0c, $0c, $0c, $13, $fe, $fe, $fe, $fe, $fe, $13, $16, $18
        !byte $19, $1c, $fe, $fe, $fe, $fe, $1c, $1c, $1c, $23, $fe, $fe, $fe, $fe, $fe, $23
        !byte $25, $28, $29, $2b, $11, $11, $fe, $11, $18
music_triforce_v3:
        !byte $00, $00, $00, $12, $fe, $fe, $fe, $12, $fe, $fe, $fe, $fe, $0f, $fe, $fe, $fe
        !byte $fe, $0f, $fe, $fe, $fe, $0d, $fe, $fe, $fe, $0d, $fe, $fe, $fe, $fe, $0c, $fe
        !byte $fe, $fe, $fe, $0c, $0a, $0a, $00, $0a, $0c

