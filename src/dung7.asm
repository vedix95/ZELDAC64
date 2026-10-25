; ===========================================================================
; dung7.asm - Donjon Niveau 7 : Demon (Démon) pour Zelda C64
; GENERE AUTOMATIQUEMENT par tools/build_dungeons.py - NE PAS MODIFIER
; Salles étanches : 28 salles
; ===========================================================================
!cpu 6510
!source "src/enemy_types.inc"
* = $c000

; En-tête Donjon (6 octets : $C000..$C005)
map_rooms_w:        !byte 16
map_rooms_h:        !byte 8
map_rooms_cnt:      !byte 28
map_bg_col:         !byte 0   ; noir
map_mc1_col:        !byte 5
map_mc2_col:        !byte 14  ; bleu clair

; Table des offsets ry * map_rooms_w (8 octets : $C006..$C00D)
map_row_offset:
        !byte 0, 16, 32, 48, 64, 80, 96, 112
; Pointeur vers le jeu de caracteres du donjon ($C00E..$C00F)
map_charset_ptr:
        !word dungeon_charset
; Pointeur vers la table des ennemis ($C010..$C011)
map_enemies_ptr_hdr:
        !word map_enemies
        !fill 4, 0                          ; Alignement à $C015

; Tables des pointeurs (128 octets LO : $C016..$C095 / 128 octets HI : $C096..$C115)
room_tbl_lo:
        !byte <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room
        !byte <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <u_room_18, <u_room_19, <u_room_1a, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room
        !byte <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <u_room_28, <u_room_29, <u_room_2a, <u_room_2b, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room
        !byte <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <u_room_38, <u_room_39, <u_room_3a, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room
        !byte <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <u_room_48, <u_room_49, <u_room_4a, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room
        !byte <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <u_room_58, <u_room_59, <u_room_5a, <u_room_5b, <u_room_5c, <u_room_5d, <dummy_sealed_room, <dummy_sealed_room
        !byte <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <u_room_68, <u_room_69, <u_room_6a, <u_room_6b, <u_room_6c, <u_room_6d, <dummy_sealed_room, <dummy_sealed_room
        !byte <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <u_room_78, <u_room_79, <u_room_7a, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room
room_tbl_hi:
        !byte >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room
        !byte >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >u_room_18, >u_room_19, >u_room_1a, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room
        !byte >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >u_room_28, >u_room_29, >u_room_2a, >u_room_2b, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room
        !byte >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >u_room_38, >u_room_39, >u_room_3a, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room
        !byte >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >u_room_48, >u_room_49, >u_room_4a, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room
        !byte >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >u_room_58, >u_room_59, >u_room_5a, >u_room_5b, >u_room_5c, >u_room_5d, >dummy_sealed_room, >dummy_sealed_room
        !byte >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >u_room_68, >u_room_69, >u_room_6a, >u_room_6b, >u_room_6c, >u_room_6d, >dummy_sealed_room, >dummy_sealed_room
        !byte >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >u_room_78, >u_room_79, >u_room_7a, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room

; Métadonnées Donjon & Palette (128 octets : $C116..$C195)
room_zone_palette:
dungeon_enemies_ptr:    !word map_enemies   ; $C116 ($C116..$C117)
dungeon_boss_room:      !byte $2a    ; $C118
dungeon_tri_room:       !byte $2b     ; $C119
dungeon_boss_type:      !byte TYPE_AQUAMENTUS ; $C11A
dungeon_boss_hp:        !byte 8   ; $C11B
dungeon_level:          !byte 7         ; $C11C
dungeon_wall_col:       !byte 13 ; $C11D
dungeon_start_rx:       !byte 9    ; $C11E
dungeon_start_ry:       !byte 7    ; $C11F
        !fill 128 - 10, 0                   ; Reste des 128 octets ($C120..$C195)

; Index de formation d'ennemis par salle (128 octets : $C196..$C215)
room_enemy_idx:
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 4, 3, 5, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 3, 4, 6, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 7, 1, 8, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 9, 3, 10, 11, 12, 13, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 14, 15, 16, 2, 4, 10, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 8, 0, 6, 0, 0, 0, 0, 0

; Salle ($18 : rx=8, ry=1) - RLE compact (75 octets)
u_room_18:
        !byte 8, 225, 33, 9, 19, 16, 69, 16, 69, 16, 20, 19, 16, 5, 32, 53
        !byte 32, 5, 16, 20, 19, 16, 5, 0, 37, 16, 37, 0, 5, 16, 20, 19
        !byte 48, 5, 80, 5, 64, 13, 19, 16, 5, 0, 37, 16, 37, 0, 5, 32
        !byte 13, 19, 16, 5, 32, 53, 32, 5, 16, 20, 19, 16, 69, 16, 69, 16
        !byte 20, 19, 224, 0, 20, 10, 114, 30, 114, 11, 255
; Salle ($19 : rx=9, ry=1) - RLE compact (49 octets)
u_room_19:
        !byte 8, 225, 33, 9, 19, 224, 0, 20, 19, 32, 21, 80, 21, 32, 20, 19
        !byte 224, 0, 20, 13, 112, 21, 112, 15, 13, 224, 32, 15, 19, 32, 21, 80
        !byte 21, 32, 20, 19, 224, 0, 20, 19, 224, 0, 20, 10, 114, 17, 114, 11
        !byte 255
; Salle ($1a : rx=10, ry=1) - RLE compact (55 octets)
u_room_1a:
        !byte 8, 225, 33, 9, 19, 224, 0, 20, 19, 112, 5, 96, 20, 19, 96, 5
        !byte 0, 5, 80, 20, 15, 96, 5, 0, 7, 0, 5, 64, 20, 15, 112, 5
        !byte 0, 5, 80, 20, 19, 112, 5, 96, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 10, 114, 17, 114, 11, 255
; Salle ($28 : rx=8, ry=2) - RLE compact (43 octets)
u_room_28:
        !byte 8, 113, 28, 113, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 10, 114, 29, 114, 11, 255
; Salle ($29 : rx=9, ry=2) - RLE compact (55 octets)
u_room_29:
        !byte 8, 225, 33, 9, 19, 224, 0, 20, 19, 112, 5, 96, 20, 19, 96, 5
        !byte 0, 5, 80, 20, 19, 80, 5, 0, 7, 0, 5, 80, 15, 19, 96, 5
        !byte 0, 5, 96, 15, 19, 112, 5, 96, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 10, 114, 17, 114, 11, 255
; Salle ($2a : rx=10, ry=2) - RLE compact (48 octets)
u_room_2a:
        !byte 8, 225, 33, 9, 19, 128, 69, 16, 20, 19, 160, 37, 16, 20, 19, 176
        !byte 21, 16, 20, 15, 224, 32, 14, 15, 192, 21, 32, 14, 19, 160, 37, 16
        !byte 20, 19, 128, 69, 16, 20, 19, 224, 0, 20, 10, 114, 17, 114, 11, 255
; Salle ($2b : rx=11, ry=2) - RLE compact (63 octets)
u_room_2b:
        !byte 8, 225, 33, 9, 19, 224, 0, 20, 19, 32, 149, 32, 20, 19, 32, 5
        !byte 16, 6, 16, 6, 16, 5, 32, 20, 12, 48, 5, 0, 6, 48, 6, 0
        !byte 5, 32, 20, 12, 48, 5, 112, 5, 32, 20, 19, 32, 53, 16, 53, 32
        !byte 20, 19, 224, 0, 20, 19, 224, 0, 20, 10, 114, 17, 114, 11, 255
; Salle ($38 : rx=8, ry=3) - RLE compact (70 octets)
u_room_38:
        !byte 8, 113, 29, 113, 9, 19, 224, 0, 20, 19, 32, 5, 0, 5, 0, 21
        !byte 0, 5, 0, 5, 32, 20, 19, 224, 0, 20, 19, 32, 5, 0, 5, 0
        !byte 21, 0, 5, 0, 5, 48, 14, 19, 224, 16, 14, 19, 32, 5, 0, 5
        !byte 0, 21, 0, 5, 0, 5, 32, 20, 19, 224, 0, 20, 19, 224, 0, 20
        !byte 10, 114, 17, 114, 11, 255
; Salle ($39 : rx=9, ry=3) - RLE compact (48 octets)
u_room_39:
        !byte 8, 225, 33, 9, 19, 16, 6, 144, 6, 16, 20, 19, 224, 0, 20, 19
        !byte 224, 0, 20, 12, 224, 32, 15, 12, 224, 32, 15, 19, 224, 0, 20, 19
        !byte 16, 6, 144, 6, 16, 20, 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($3a : rx=10, ry=3) - RLE compact (42 octets)
u_room_3a:
        !byte 8, 225, 33, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20
        !byte 15, 224, 16, 20, 15, 224, 16, 20, 19, 224, 0, 20, 19, 224, 0, 20
        !byte 19, 224, 0, 20, 10, 114, 17, 114, 11, 255
; Salle ($48 : rx=8, ry=4) - RLE compact (42 octets)
u_room_48:
        !byte 8, 225, 33, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20
        !byte 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20
        !byte 19, 224, 0, 20, 10, 114, 29, 114, 11, 255
; Salle ($49 : rx=9, ry=4) - RLE compact (44 octets)
u_room_49:
        !byte 8, 113, 30, 113, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 16, 181
        !byte 16, 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224
        !byte 0, 20, 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($4a : rx=10, ry=4) - RLE compact (68 octets)
u_room_4a:
        !byte 8, 113, 28, 113, 9, 19, 16, 21, 176, 20, 19, 16, 21, 64, 5, 0
        !byte 37, 16, 20, 19, 16, 21, 0, 37, 0, 69, 16, 20, 12, 64, 5, 48
        !byte 5, 16, 7, 32, 20, 12, 32, 21, 96, 5, 48, 20, 19, 16, 21, 48
        !byte 21, 0, 5, 48, 20, 19, 16, 21, 176, 20, 19, 224, 0, 20, 10, 114
        !byte 17, 114, 11, 255
; Salle ($58 : rx=8, ry=5) - RLE compact (43 octets)
u_room_58:
        !byte 8, 113, 29, 113, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 16, 12, 19, 224, 16, 12, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($59 : rx=9, ry=5) - RLE compact (49 octets)
u_room_59:
        !byte 8, 113, 28, 113, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 48, 5
        !byte 80, 5, 48, 20, 12, 224, 32, 14, 12, 64, 5, 80, 5, 64, 14, 19
        !byte 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20, 10, 114, 31, 114, 11
        !byte 255
; Salle ($5a : rx=10, ry=5) - RLE compact (44 octets)
u_room_5a:
        !byte 8, 225, 33, 9, 19, 224, 0, 20, 19, 16, 181, 16, 20, 19, 224, 0
        !byte 20, 12, 224, 16, 20, 12, 224, 16, 20, 19, 16, 181, 16, 20, 19, 224
        !byte 0, 20, 19, 224, 0, 20, 10, 114, 30, 114, 11, 255
; Salle ($5b : rx=11, ry=5) - RLE compact (42 octets)
u_room_5b:
        !byte 8, 225, 33, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20
        !byte 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20
        !byte 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($5c : rx=12, ry=5) - RLE compact (48 octets)
u_room_5c:
        !byte 8, 225, 33, 9, 19, 16, 6, 144, 6, 16, 20, 19, 224, 0, 20, 19
        !byte 224, 0, 20, 19, 224, 16, 12, 19, 224, 16, 12, 19, 224, 0, 20, 19
        !byte 16, 6, 144, 6, 16, 20, 19, 224, 0, 20, 10, 114, 17, 114, 11, 255
; Salle ($5d : rx=13, ry=5) - RLE compact (67 octets)
u_room_5d:
        !byte 8, 225, 33, 9, 19, 48, 5, 112, 5, 16, 20, 19, 32, 5, 32, 5
        !byte 48, 5, 32, 20, 19, 80, 5, 48, 5, 48, 20, 12, 80, 5, 48, 5
        !byte 64, 20, 12, 64, 5, 48, 5, 80, 20, 19, 32, 5, 48, 5, 32, 5
        !byte 32, 20, 19, 16, 5, 112, 5, 48, 20, 19, 224, 0, 20, 10, 114, 17
        !byte 114, 11, 255
; Salle ($68 : rx=8, ry=6) - RLE compact (43 octets)
u_room_68:
        !byte 8, 113, 28, 113, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 16, 15, 19, 224, 16, 15, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($69 : rx=9, ry=6) - RLE compact (46 octets)
u_room_69:
        !byte 8, 113, 31, 113, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 15, 96, 6, 16, 6, 96, 12, 15, 224, 32, 12, 19, 224, 0, 20
        !byte 19, 224, 0, 20, 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($6a : rx=10, ry=6) - RLE compact (53 octets)
u_room_6a:
        !byte 8, 113, 30, 113, 9, 19, 224, 0, 20, 19, 48, 117, 48, 20, 19, 48
        !byte 5, 80, 5, 48, 20, 12, 64, 5, 80, 5, 64, 28, 64, 5, 80, 5
        !byte 64, 12, 19, 48, 117, 48, 20, 19, 224, 0, 20, 19, 224, 0, 20, 10
        !byte 114, 28, 114, 11, 255
; Salle ($6b : rx=11, ry=6) - RLE compact (45 octets)
u_room_6b:
        !byte 8, 113, 30, 113, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 96, 21
        !byte 96, 20, 12, 112, 21, 112, 28, 112, 21, 112, 12, 19, 224, 0, 20, 19
        !byte 224, 0, 20, 19, 224, 0, 20, 10, 114, 17, 114, 11, 255
; Salle ($6c : rx=12, ry=6) - RLE compact (47 octets)
u_room_6c:
        !byte 8, 225, 33, 9, 19, 16, 6, 144, 6, 16, 20, 19, 224, 0, 20, 19
        !byte 224, 0, 20, 12, 224, 32, 28, 224, 32, 12, 19, 224, 0, 20, 19, 16
        !byte 6, 144, 6, 16, 20, 19, 224, 0, 20, 10, 114, 17, 114, 11, 255
; Salle ($6d : rx=13, ry=6) - RLE compact (49 octets)
u_room_6d:
        !byte 8, 225, 33, 9, 19, 144, 5, 64, 20, 19, 144, 5, 64, 20, 19, 144
        !byte 5, 64, 20, 12, 160, 5, 64, 20, 12, 160, 5, 64, 20, 19, 144, 5
        !byte 64, 20, 19, 144, 5, 64, 20, 19, 224, 0, 20, 10, 114, 17, 114, 11
        !byte 255
; Salle ($78 : rx=8, ry=7) - RLE compact (46 octets)
u_room_78:
        !byte 8, 113, 28, 113, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 80, 6, 16, 6, 80, 20, 19, 224, 0, 20, 19, 224, 0, 20
        !byte 19, 224, 0, 20, 19, 224, 0, 20, 10, 114, 17, 114, 11, 255
; Salle ($79 : rx=9, ry=7) - RLE compact (64 octets)
u_room_79:
        !byte 8, 113, 28, 113, 9, 19, 224, 0, 20, 19, 32, 6, 16, 6, 16, 6
        !byte 16, 6, 32, 20, 19, 224, 0, 20, 19, 32, 6, 16, 6, 16, 6, 16
        !byte 6, 48, 12, 19, 224, 16, 12, 19, 32, 6, 16, 6, 16, 6, 16, 6
        !byte 32, 20, 19, 224, 0, 20, 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($7a : rx=10, ry=7) - RLE compact (52 octets)
u_room_7a:
        !byte 8, 113, 28, 113, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 48, 21
        !byte 48, 21, 48, 20, 12, 64, 21, 48, 21, 48, 20, 12, 64, 21, 48, 21
        !byte 48, 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20, 10, 114
        !byte 17, 114, 11, 255

; Salle scellée étanche pour toutes les coordonnées hors-donjon
dummy_sealed_room:
        !byte 225, 225, 225, 225, 225, 225, 225, 225, 225, 225, 225, 225, 225, 65, 255

; Table d'apparition des monstres dédupliquée (17 formations x 24 octets)
map_enemies:
        ; Formation 0
        !byte TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 1
        !byte TYPE_BUBBLE       ,  6,  3,   TYPE_BUBBLE       , 14,  3,   TYPE_BUBBLE       , 10,  5,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 2
        !byte TYPE_GORIYA_BLUE  ,  6,  3,   TYPE_GORIYA_BLUE  , 14,  3,   TYPE_GORIYA_BLUE  ,  8,  6,   TYPE_GORIYA_BLUE  , 12,  6,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 3
        !byte TYPE_DARKNUT_RED  ,  6,  3,   TYPE_DARKNUT_RED  , 14,  3,   TYPE_DARKNUT_RED  ,  8,  6,   TYPE_DARKNUT_RED  , 12,  6,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 4
        !byte TYPE_DODONGO      , 10,  4,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 5
        !byte TYPE_AQUAMENTUS   , 14,  4,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 6
        !byte TYPE_GORIYA_RED   , 10,  4,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 7
        !byte TYPE_DARKNUT_BLUE , 10,  4,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 8
        !byte TYPE_GIBDO        ,  6,  3,   TYPE_GIBDO        , 14,  3,   TYPE_GIBDO        , 10,  5,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 9
        !byte TYPE_WALLMASTER   , 10,  4,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 10
        !byte TYPE_KEESE_RED    ,  6,  2,   TYPE_KEESE_RED    , 14,  2,   TYPE_KEESE_RED    , 10,  4,   TYPE_KEESE_RED    ,  6,  6,   TYPE_KEESE_RED    , 14,  6,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 11
        !byte TYPE_STALFOS      , 10,  4,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 12
        !byte TYPE_DARKNUT_RED  , 10,  4,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 13
        !byte TYPE_KEESE_BLUE   ,  6,  2,   TYPE_KEESE_BLUE   , 14,  2,   TYPE_KEESE_BLUE   ,  6,  6,   TYPE_KEESE_BLUE   , 14,  6,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 14
        !byte TYPE_WIZZROBE_BLUE,  8,  3,   TYPE_WIZZROBE_BLUE, 12,  3,   TYPE_WIZZROBE_BLUE, 10,  5,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 15
        !byte TYPE_GORIYA_BLUE  ,  8,  3,   TYPE_GORIYA_BLUE  , 12,  3,   TYPE_GORIYA_BLUE  , 10,  5,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 16
        !byte TYPE_STALFOS      ,  6,  3,   TYPE_STALFOS      , 14,  3,   TYPE_STALFOS      , 10,  4,   TYPE_STALFOS      ,  6,  6,   TYPE_STALFOS      , 14,  6,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0

; ===========================================================================
; Jeu de caracteres authentique du donjon (512 octets)
; Copié dynamiquement par disk.asm a $2000 (0..31) et $2540 (168..199)
; ===========================================================================
dungeon_charset:
; Chars 0..31 (Tuiles 0..7 : 256 octets)
        !byte 0, 21, 21, 21, 21, 21, 21, 21
        !byte 0, 85, 85, 85, 85, 85, 85, 85
        !byte 0, 21, 21, 21, 21, 21, 21, 21
        !byte 0, 85, 85, 85, 85, 85, 85, 85
        !byte 170, 149, 149, 170, 101, 101, 170, 149
        !byte 170, 149, 149, 170, 101, 101, 170, 149
        !byte 149, 170, 101, 101, 170, 149, 149, 0
        !byte 149, 170, 101, 101, 170, 149, 149, 0
        !byte 0, 170, 149, 149, 170, 101, 101, 170
        !byte 0, 170, 149, 149, 170, 101, 101, 170
        !byte 149, 149, 170, 101, 101, 170, 149, 170
        !byte 149, 149, 170, 101, 101, 170, 149, 170
        !byte 150, 150, 150, 170, 150, 150, 150, 170
        !byte 148, 148, 148, 168, 148, 148, 148, 168
        !byte 150, 150, 150, 170, 150, 150, 150, 170
        !byte 148, 148, 148, 168, 148, 148, 148, 168
        !byte 22, 22, 22, 42, 22, 22, 22, 42
        !byte 150, 150, 150, 170, 150, 150, 150, 170
        !byte 22, 22, 22, 42, 22, 22, 22, 42
        !byte 150, 150, 150, 170, 150, 150, 150, 170
        !byte 0, 10, 42, 41, 37, 37, 37, 45
        !byte 0, 160, 172, 124, 92, 92, 92, 124
        !byte 47, 47, 15, 0, 0, 0, 0, 0
        !byte 124, 252, 240, 0, 0, 0, 0, 0
        !byte 9, 37, 157, 157, 149, 37, 38, 37
        !byte 96, 88, 118, 118, 86, 88, 152, 88
        !byte 157, 150, 149, 37, 9, 9, 9, 0
        !byte 118, 150, 86, 88, 96, 96, 96, 0
        !byte 170, 191, 190, 189, 191, 191, 191, 191
        !byte 170, 253, 169, 85, 253, 169, 85, 253
        !byte 191, 191, 191, 191, 191, 191, 149, 0
        !byte 233, 213, 253, 249, 245, 253, 85, 0
; Chars 168..199 (Tuiles 8..15 : 256 octets)
        !byte 170, 170, 170, 170, 170, 169, 165, 148
        !byte 170, 169, 165, 148, 80, 64, 0, 0
        !byte 144, 80, 64, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0
        !byte 170, 106, 90, 22, 5, 1, 0, 0
        !byte 170, 170, 170, 170, 170, 106, 90, 22
        !byte 0, 0, 0, 0, 0, 0, 0, 0
        !byte 6, 5, 1, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 64, 80
        !byte 0, 0, 0, 0, 0, 0, 0, 0
        !byte 144, 148, 165, 169, 170, 170, 170, 170
        !byte 0, 0, 0, 64, 80, 148, 165, 170
        !byte 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 1, 5
        !byte 0, 0, 0, 1, 5, 22, 90, 170
        !byte 6, 22, 90, 106, 170, 170, 170, 170
        !byte 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0
        !byte 170, 149, 149, 149, 150, 152, 152, 150
        !byte 170, 86, 86, 86, 150, 38, 38, 150
        !byte 148, 148, 148, 149, 149, 149, 149, 170
        !byte 22, 22, 22, 86, 86, 86, 86, 170
        !byte 170, 136, 136, 170, 136, 136, 170, 136
        !byte 170, 136, 136, 170, 136, 136, 170, 136
        !byte 136, 170, 136, 136, 170, 136, 136, 170
        !byte 136, 170, 136, 136, 170, 136, 136, 170
        !byte 170, 145, 145, 160, 100, 100, 168, 0
        !byte 170, 149, 149, 170, 37, 101, 42, 64
        !byte 168, 145, 145, 160, 100, 101, 170, 0
        !byte 106, 149, 149, 170, 37, 37, 42, 0
