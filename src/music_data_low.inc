; ===========================================================================
; music_data_low.inc - Tables de frequences SID et fanfares sous $2000
; GENERE AUTOMATIQUEMENT par tools/generate_game_audio.py - NE PAS MODIFIER
; ===========================================================================

MUSIC_NOTE_COUNT    = 58
MUSIC_ITEM_LEN      = 4
MUSIC_TRIFORCE_LEN  = 41

; Table des frequences SID (Index 0 = Silence)
music_note_freq_lo:
        !byte $00, $2b, $7b, $ce, $26, $84, $e7, $4f, $c0, $36, $b1, $35, $c4, $56, $f1, $f5
        !byte $97, $9c, $47, $4c, $02, $08, $c7, $ce, $97, $9e, $80, $6d, $62, $6b, $7a, $88
        !byte $ab, $e2, $1c, $2e, $7a, $8f, $04, $8f, $2e, $4b, $01, $c7, $c5, $d6, $f5, $56
        !byte $c5, $37, $f4, $08, $1e, $97, $01, $45, $8a, $ac, $82
music_note_freq_hi:
        !byte $00, $05, $05, $05, $06, $06, $06, $07, $07, $08, $08, $09, $09, $0a, $0a, $0a
        !byte $0b, $0b, $0c, $0c, $0d, $0d, $0d, $0d, $0e, $0e, $0f, $10, $11, $12, $13, $13
        !byte $14, $15, $17, $17, $18, $18, $1a, $1b, $1d, $1d, $1f, $20, $22, $24, $26, $29
        !byte $2b, $2e, $30, $34, $37, $3a, $3e, $41, $45, $49, $4d

; --- music_item_fanfare (4 pas) ---
music_item_fanfare_dur:
        !byte  10,  10,  10,  40
music_item_fanfare_v1:
        !byte $1c, $1d, $1f, $20
music_item_fanfare_v2:
        !byte $28, $2a, $2b, $2c
music_item_fanfare_v3:
        !byte $10, $12, $14, $16

; --- music_triforce (41 pas) ---
music_triforce_dur:
        !byte   7,   7,   7,  20,   7,   7,   7,  20,   5,   5,   5,   5,  20,   5,   5,   5
        !byte   5,  20,   7,   7,   7,  20,   7,   7,   7,  20,   5,   5,   5,   5,  20,   5
        !byte   5,   5,   5,  20,   5,   5,   5,   5,  30
music_triforce_v1:
        !byte $1f, $1f, $1f, $26, $fe, $fe, $fe, $fe, $26, $28, $2b, $2c, $2e, $fe, $fe, $fe
        !byte $fe, $fe, $2e, $2e, $2e, $33, $fe, $fe, $fe, $fe, $33, $35, $37, $38, $3a, $fe
        !byte $fe, $fe, $fe, $fe, $1f, $1f, $00, $1f, $26
music_triforce_v2:
        !byte $00, $00, $00, $00, $0c, $0c, $0c, $15, $fe, $fe, $fe, $fe, $fe, $15, $19, $1b
        !byte $1c, $1f, $fe, $fe, $fe, $fe, $1f, $1f, $1f, $26, $fe, $fe, $fe, $fe, $fe, $26
        !byte $28, $2b, $2c, $2e, $13, $13, $fe, $13, $1b
music_triforce_v3:
        !byte $00, $00, $00, $14, $fe, $fe, $fe, $14, $fe, $fe, $fe, $fe, $10, $fe, $fe, $fe
        !byte $fe, $10, $fe, $fe, $fe, $0d, $fe, $fe, $fe, $0d, $fe, $fe, $fe, $fe, $0c, $fe
        !byte $fe, $fe, $fe, $0c, $0a, $0a, $00, $0a, $0c

