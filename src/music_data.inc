; ===========================================================================
; music_data.inc - Partitions BGM Overworld, Underworld et Donjon 9
; GENERE AUTOMATIQUEMENT par tools/generate_game_audio.py - NE PAS MODIFIER
; ===========================================================================

MUSIC_OW_P1_LEN     = 111
MUSIC_OW_P2_LEN     = 112
MUSIC_UW_LEN        = 116
MUSIC_D9_LEN        = 124

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
        !byte $2a, $00, $23, $fe, $fe, $fe, $00, $2a, $2a, $2c, $2e, $2f, $31, $fe, $fe, $fe
        !byte $fe, $fe, $fe, $fe, $fe, $00, $31, $31, $32, $34, $36, $fe, $fe, $fe, $fe, $fe
        !byte $fe, $fe, $fe, $00, $36, $36, $36, $34, $32, $34, $00, $32, $31, $fe, $fe, $fe
        !byte $fe, $fe, $31, $fe, $fe, $2f, $2f, $31, $32, $fe, $fe, $fe, $fe, $fe, $31, $fe
        !byte $2f, $fe, $2d, $2d, $2f, $31, $fe, $fe, $fe, $fe, $fe, $2f, $fe, $2d, $fe, $2c
        !byte $2c, $2e, $30, $fe, $fe, $fe, $fe, $fe, $fe, $fe, $33, $fe, $fe, $fe, $31, $00
        !byte $23, $23, $23, $00, $23, $23, $23, $00, $23, $23, $23, $23, $2a, $00, $23
music_ow_p1_v2:
        !byte $1f, $00, $1f, $1f, $1c, $1f, $00, $1f, $1f, $20, $23, $26, $27, $00, $2a, $2a
        !byte $2c, $fe, $2e, $fe, $2f, $31, $fe, $27, $2a, $2c, $2d, $00, $25, $25, $27, $fe
        !byte $2a, $fe, $2c, $2d, $00, $2d, $2d, $2c, $2a, $2d, $00, $27, $27, $27, $25, $27
        !byte $00, $27, $27, $25, $27, $25, $25, $23, $25, $fe, $25, $fe, $27, $2a, $27, $fe
        !byte $25, $fe, $23, $23, $20, $23, $fe, $23, $fe, $25, $27, $25, $fe, $23, $fe, $21
        !byte $fe, $fe, $21, $fe, $21, $fe, $23, $26, $26, $28, $2a, $fe, $2c, $fe, $28, $fe
        !byte $19, $19, $19, $fe, $19, $19, $19, $fe, $19, $19, $19, $19, $1f, $00, $1f
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
        !byte $fe, $fe, $fe, $00, $2a, $2a, $2c, $2e, $2f, $31, $fe, $fe, $fe, $fe, $fe, $fe
        !byte $fe, $fe, $00, $31, $31, $32, $34, $36, $fe, $fe, $fe, $fe, $39, $38, $00, $35
        !byte $fe, $fe, $fe, $31, $32, $fe, $fe, $fe, $fe, $fe, $fe, $36, $35, $00, $31, $fe
        !byte $fe, $fe, $31, $32, $fe, $fe, $fe, $fe, $fe, $fe, $36, $35, $00, $31, $fe, $fe
        !byte $fe, $2e, $2f, $fe, $fe, $fe, $fe, $32, $fe, $fe, $31, $00, $2d, $fe, $fe, $fe
        !byte $2a, $fe, $fe, $2c, $2c, $2e, $30, $fe, $fe, $fe, $fe, $fe, $fe, $fe, $33, $fe
        !byte $fe, $fe, $31, $00, $23, $23, $23, $00, $23, $23, $23, $00, $23, $23, $23, $23
music_ow_p2_v2:
        !byte $1f, $1c, $1f, $00, $1f, $1f, $20, $23, $26, $27, $00, $2a, $2a, $2c, $fe, $2e
        !byte $fe, $2f, $31, $fe, $27, $2a, $2c, $2d, $fe, $fe, $fe, $fe, $30, $2f, $00, $2c
        !byte $fe, $fe, $fe, $28, $2b, $fe, $fe, $fe, $fe, $fe, $fe, $2d, $2c, $00, $28, $fe
        !byte $fe, $fe, $28, $2b, $fe, $fe, $fe, $fe, $fe, $fe, $2d, $2c, $00, $28, $fe, $fe
        !byte $fe, $28, $25, $fe, $fe, $fe, $fe, $2b, $fe, $fe, $2a, $00, $23, $fe, $fe, $fe
        !byte $1d, $fe, $fe, $21, $fe, $fe, $21, $fe, $21, $fe, $23, $26, $26, $28, $2a, $fe
        !byte $2c, $fe, $28, $fe, $19, $19, $19, $fe, $19, $19, $19, $fe, $19, $19, $19, $19
music_ow_p2_v3:
        !byte $08, $06, $08, $fe, $fe, $08, $fe, $fe, $fe, $06, $fe, $fe, $06, $fe, $06, $fe
        !byte $04, $fe, $06, $fe, $06, $fe, $fe, $04, $04, $04, $02, $04, $04, $03, $fe, $03
        !byte $03, $01, $03, $03, $02, $08, $0b, $0e, $1a, $1d, $21, $fe, $22, $fe, $03, $03
        !byte $03, $03, $fe, $02, $08, $0b, $0e, $1a, $1d, $21, $fe, $22, $fe, $03, $03, $03
        !byte $03, $fe, $09, $09, $09, $08, $09, $09, $09, $09, $08, $fe, $08, $08, $06, $08
        !byte $08, $08, $08, $0a, $fe, $fe, $0a, $0a, $fe, $09, $fe, $0a, $fe, $fe, $0a, $0a
        !byte $fe, $0a, $03, $fe, $fe, $fe, $03, $fe, $fe, $fe, $03, $fe, $fe, $fe, $05, $07

; --- music_uw (116 pas) ---
music_uw_v1:
        !byte $26, $fe, $2e, $fe, $26, $fe, $2e, $fe, $26, $fe, $2e, $fe, $26, $fe, $2e, $fe
        !byte $25, $fe, $2e, $fe, $25, $fe, $2e, $fe, $25, $fe, $2e, $fe, $25, $fe, $2e, $fe
        !byte $23, $fe, $2e, $fe, $23, $fe, $2e, $fe, $23, $fe, $2e, $fe, $23, $fe, $2e, $fe
        !byte $21, $fe, $2e, $fe, $21, $fe, $2e, $fe, $21, $fe, $2e, $fe, $21, $fe, $2e, $fe
        !byte $20, $fe, $2c, $fe, $20, $fe, $2c, $fe, $20, $fe, $2c, $fe, $20, $fe, $2c, $fe
        !byte $1f, $fe, $2c, $fe, $1f, $fe, $2c, $fe, $1f, $fe, $2c, $fe, $1f, $fe, $2c, $fe
        !byte $1c, $fe, $28, $fe, $25, $fe, $2c, $fe, $28, $fe, $2f, $fe, $2f, $fe, $2f, $fe
        !byte $35, $fe, $35, $fe
music_uw_v2:
        !byte $00, $2a, $fe, $2f, $fe, $2a, $fe, $2f, $fe, $2a, $fe, $2f, $fe, $2a, $fe, $2f
        !byte $fe, $28, $fe, $2f, $fe, $28, $fe, $2f, $fe, $28, $fe, $2f, $fe, $28, $fe, $2f
        !byte $fe, $27, $fe, $2f, $fe, $27, $fe, $2f, $fe, $27, $fe, $2f, $fe, $27, $fe, $2f
        !byte $fe, $26, $fe, $2f, $fe, $26, $fe, $2f, $fe, $26, $fe, $2f, $fe, $26, $fe, $2f
        !byte $00, $26, $fe, $2e, $fe, $26, $fe, $2e, $fe, $26, $fe, $2e, $fe, $26, $fe, $2e
        !byte $fe, $26, $fe, $2e, $fe, $26, $fe, $2e, $fe, $26, $fe, $2e, $fe, $26, $fe, $2e
        !byte $fe, $25, $fe, $2c, $fe, $28, $fe, $2f, $fe, $2c, $fe, $2c, $fe, $32, $fe, $32
        !byte $fe, $32, $fe, $38
music_uw_v3:
        !byte $14, $fe, $fe, $fe, $00, $00, $00, $00, $1a, $fe, $fe, $fe, $1e, $fe, $fe, $fe
        !byte $1d, $fe, $fe, $fe, $12, $fe, $fe, $fe, $00, $00, $00, $00, $00, $00, $00, $00
        !byte $10, $fe, $fe, $fe, $00, $00, $00, $00, $10, $fe, $00, $16, $00, $00, $1d, $fe
        !byte $1c, $fe, $fe, $fe, $0e, $fe, $fe, $fe, $00, $00, $00, $00, $00, $00, $00, $00
        !byte $0d, $0c, $0d, $fe, $fe, $fe, $00, $00, $14, $fe, $00, $20, $00, $00, $1e, $fe
        !byte $0c, $0b, $0c, $fe, $fe, $fe, $00, $00, $14, $fe, $00, $1e, $00, $00, $1d, $fe
        !byte $0c, $12, $18, $12, $18, $1c, $18, $1c, $20, $1c, $20, $24, $29, $24, $20, $1c
        !byte $20, $1c, $18, $12

bgm_track_buffer_end:

; Equates pour le Donjon 9 (recoit les 2 pages streamees depuis Banque 31)
music_d9_dur        = bgm_track_buffer
music_d9_v1         = music_d9_dur + MUSIC_D9_LEN
music_d9_v2         = music_d9_v1 + MUSIC_D9_LEN
music_d9_v3         = music_d9_v2 + MUSIC_D9_LEN

