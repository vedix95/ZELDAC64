; ===========================================================================
; music_data.inc - Partitions BGM Overworld, Underworld et Donjon 9
; GENERE AUTOMATIQUEMENT par tools/generate_game_audio.py - NE PAS MODIFIER
; ===========================================================================

MUSIC_OW_P1_LEN     = 111
MUSIC_OW_P2_LEN     = 112
MUSIC_UW_LEN        = 116
MUSIC_D9_LEN        = 124
MUSIC_GANON_LEN     = 21

; bgm_track_buffer : Tampon dynamique partage sous $A000
bgm_track_buffer:
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
        !byte $2b, $00, $24, $fe, $fe, $fe, $00, $2b, $2b, $2d, $2f, $30, $32, $fe, $fe, $fe
        !byte $fe, $fe, $fe, $fe, $fe, $00, $32, $32, $33, $35, $37, $fe, $fe, $fe, $fe, $fe
        !byte $fe, $fe, $fe, $00, $37, $37, $37, $35, $33, $35, $00, $33, $32, $fe, $fe, $fe
        !byte $fe, $fe, $32, $fe, $fe, $30, $30, $32, $33, $fe, $fe, $fe, $fe, $fe, $32, $fe
        !byte $30, $fe, $2e, $2e, $30, $32, $fe, $fe, $fe, $fe, $fe, $30, $fe, $2e, $fe, $2d
        !byte $2d, $2f, $31, $fe, $fe, $fe, $fe, $fe, $fe, $fe, $34, $fe, $fe, $fe, $32, $00
        !byte $24, $24, $24, $00, $24, $24, $24, $00, $24, $24, $24, $24, $2b, $00, $24
music_ow_p1_v2:
        !byte $20, $00, $20, $20, $1d, $20, $00, $20, $20, $21, $24, $27, $28, $00, $2b, $2b
        !byte $2d, $fe, $2f, $fe, $30, $32, $fe, $28, $2b, $2d, $2e, $00, $26, $26, $28, $fe
        !byte $2b, $fe, $2d, $2e, $00, $2e, $2e, $2d, $2b, $2e, $00, $28, $28, $28, $26, $28
        !byte $00, $28, $28, $26, $28, $26, $26, $24, $26, $fe, $26, $fe, $28, $2b, $28, $fe
        !byte $26, $fe, $24, $24, $21, $24, $fe, $24, $fe, $26, $28, $26, $fe, $24, $fe, $22
        !byte $fe, $fe, $22, $fe, $22, $fe, $24, $27, $27, $29, $2b, $fe, $2d, $fe, $29, $fe
        !byte $19, $19, $19, $fe, $19, $19, $19, $fe, $19, $19, $19, $19, $20, $00, $20
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
        !byte $fe, $fe, $fe, $00, $2b, $2b, $2d, $2f, $30, $32, $fe, $fe, $fe, $fe, $fe, $fe
        !byte $fe, $fe, $00, $32, $32, $33, $35, $37, $fe, $fe, $fe, $fe, $3a, $39, $00, $36
        !byte $fe, $fe, $fe, $32, $33, $fe, $fe, $fe, $fe, $fe, $fe, $37, $36, $00, $32, $fe
        !byte $fe, $fe, $32, $33, $fe, $fe, $fe, $fe, $fe, $fe, $37, $36, $00, $32, $fe, $fe
        !byte $fe, $2f, $30, $fe, $fe, $fe, $fe, $33, $fe, $fe, $32, $00, $2e, $fe, $fe, $fe
        !byte $2b, $fe, $fe, $2d, $2d, $2f, $31, $fe, $fe, $fe, $fe, $fe, $fe, $fe, $34, $fe
        !byte $fe, $fe, $32, $00, $24, $24, $24, $00, $24, $24, $24, $00, $24, $24, $24, $24
music_ow_p2_v2:
        !byte $20, $1d, $20, $00, $20, $20, $21, $24, $27, $28, $00, $2b, $2b, $2d, $fe, $2f
        !byte $fe, $30, $32, $fe, $28, $2b, $2d, $2e, $fe, $fe, $fe, $fe, $31, $30, $00, $2d
        !byte $fe, $fe, $fe, $29, $2c, $fe, $fe, $fe, $fe, $fe, $fe, $2e, $2d, $00, $29, $fe
        !byte $fe, $fe, $29, $2c, $fe, $fe, $fe, $fe, $fe, $fe, $2e, $2d, $00, $29, $fe, $fe
        !byte $fe, $29, $26, $fe, $fe, $fe, $fe, $2c, $fe, $fe, $2b, $00, $24, $fe, $fe, $fe
        !byte $1e, $fe, $fe, $22, $fe, $fe, $22, $fe, $22, $fe, $24, $27, $27, $29, $2b, $fe
        !byte $2d, $fe, $29, $fe, $19, $19, $19, $fe, $19, $19, $19, $fe, $19, $19, $19, $19
music_ow_p2_v3:
        !byte $08, $06, $08, $fe, $fe, $08, $fe, $fe, $fe, $06, $fe, $fe, $06, $fe, $06, $fe
        !byte $04, $fe, $06, $fe, $06, $fe, $fe, $04, $04, $04, $02, $04, $04, $03, $fe, $03
        !byte $03, $01, $03, $03, $02, $08, $0b, $0e, $1a, $1e, $22, $fe, $23, $fe, $03, $03
        !byte $03, $03, $fe, $02, $08, $0b, $0e, $1a, $1e, $22, $fe, $23, $fe, $03, $03, $03
        !byte $03, $fe, $09, $09, $09, $08, $09, $09, $09, $09, $08, $fe, $08, $08, $06, $08
        !byte $08, $08, $08, $0a, $fe, $fe, $0a, $0a, $fe, $09, $fe, $0a, $fe, $fe, $0a, $0a
        !byte $fe, $0a, $03, $fe, $fe, $fe, $03, $fe, $fe, $fe, $03, $fe, $fe, $fe, $05, $07

; --- music_uw (116 pas) ---
music_uw_v1:
        !byte $27, $fe, $2f, $fe, $27, $fe, $2f, $fe, $27, $fe, $2f, $fe, $27, $fe, $2f, $fe
        !byte $26, $fe, $2f, $fe, $26, $fe, $2f, $fe, $26, $fe, $2f, $fe, $26, $fe, $2f, $fe
        !byte $24, $fe, $2f, $fe, $24, $fe, $2f, $fe, $24, $fe, $2f, $fe, $24, $fe, $2f, $fe
        !byte $22, $fe, $2f, $fe, $22, $fe, $2f, $fe, $22, $fe, $2f, $fe, $22, $fe, $2f, $fe
        !byte $21, $fe, $2d, $fe, $21, $fe, $2d, $fe, $21, $fe, $2d, $fe, $21, $fe, $2d, $fe
        !byte $20, $fe, $2d, $fe, $20, $fe, $2d, $fe, $20, $fe, $2d, $fe, $20, $fe, $2d, $fe
        !byte $1d, $fe, $29, $fe, $26, $fe, $2d, $fe, $29, $fe, $30, $fe, $30, $fe, $30, $fe
        !byte $36, $fe, $36, $fe
music_uw_v2:
        !byte $00, $2b, $fe, $30, $fe, $2b, $fe, $30, $fe, $2b, $fe, $30, $fe, $2b, $fe, $30
        !byte $fe, $29, $fe, $30, $fe, $29, $fe, $30, $fe, $29, $fe, $30, $fe, $29, $fe, $30
        !byte $fe, $28, $fe, $30, $fe, $28, $fe, $30, $fe, $28, $fe, $30, $fe, $28, $fe, $30
        !byte $fe, $27, $fe, $30, $fe, $27, $fe, $30, $fe, $27, $fe, $30, $fe, $27, $fe, $30
        !byte $00, $27, $fe, $2f, $fe, $27, $fe, $2f, $fe, $27, $fe, $2f, $fe, $27, $fe, $2f
        !byte $fe, $27, $fe, $2f, $fe, $27, $fe, $2f, $fe, $27, $fe, $2f, $fe, $27, $fe, $2f
        !byte $fe, $26, $fe, $2d, $fe, $29, $fe, $30, $fe, $2d, $fe, $2d, $fe, $33, $fe, $33
        !byte $fe, $33, $fe, $39
music_uw_v3:
        !byte $14, $fe, $fe, $fe, $00, $00, $00, $00, $1a, $fe, $fe, $fe, $1f, $fe, $fe, $fe
        !byte $1e, $fe, $fe, $fe, $12, $fe, $fe, $fe, $00, $00, $00, $00, $00, $00, $00, $00
        !byte $10, $fe, $fe, $fe, $00, $00, $00, $00, $10, $fe, $00, $16, $00, $00, $1e, $fe
        !byte $1d, $fe, $fe, $fe, $0e, $fe, $fe, $fe, $00, $00, $00, $00, $00, $00, $00, $00
        !byte $0d, $0c, $0d, $fe, $fe, $fe, $00, $00, $14, $fe, $00, $21, $00, $00, $1f, $fe
        !byte $0c, $0b, $0c, $fe, $fe, $fe, $00, $00, $14, $fe, $00, $1f, $00, $00, $1e, $fe
        !byte $0c, $12, $18, $12, $18, $1d, $18, $1d, $21, $1d, $21, $25, $2a, $25, $21, $1d
        !byte $21, $1d, $18, $12

bgm_track_buffer_end:

; Equates pour le Donjon 9 et Fanfare Ganon (3 pages streamees depuis Banque 31 $8800)
music_d9_dur        = bgm_track_buffer
music_d9_v1         = music_d9_dur + MUSIC_D9_LEN
music_d9_v2         = music_d9_v1 + MUSIC_D9_LEN
music_d9_v3         = music_d9_v2 + MUSIC_D9_LEN
music_ganon_dur     = bgm_track_buffer + 512
music_ganon_v1      = music_ganon_dur + MUSIC_GANON_LEN
music_ganon_v2      = music_ganon_v1 + MUSIC_GANON_LEN
music_ganon_v3      = music_ganon_v2 + MUSIC_GANON_LEN

