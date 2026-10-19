; ===========================================================================
; dung1.asm - Donjon Niveau 1 : Eagle (Aigle) pour Zelda C64
; GENERE AUTOMATIQUEMENT par tools/build_dungeons.py - NE PAS MODIFIER
; Salles étanches : 17 salles
; ===========================================================================
!cpu 6510
!source "src/enemy_types.inc"
* = $c000

; En-tête Donjon (6 octets : $C000..$C005)
map_rooms_w:        !byte 16
map_rooms_h:        !byte 8
map_rooms_cnt:      !byte 17
map_bg_col:         !byte 0   ; noir
map_mc1_col:        !byte 3
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
        !byte <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room
        !byte <dummy_sealed_room, <dummy_sealed_room, <u_room_22, <u_room_23, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room
        !byte <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <u_room_33, <dummy_sealed_room, <u_room_35, <u_room_36, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room
        !byte <dummy_sealed_room, <u_room_41, <u_room_42, <u_room_43, <u_room_44, <u_room_45, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room
        !byte <dummy_sealed_room, <dummy_sealed_room, <u_room_52, <u_room_53, <u_room_54, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room
        !byte <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <u_room_63, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room
        !byte <dummy_sealed_room, <dummy_sealed_room, <u_room_72, <u_room_73, <u_room_74, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room
room_tbl_hi:
        !byte >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room
        !byte >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room
        !byte >dummy_sealed_room, >dummy_sealed_room, >u_room_22, >u_room_23, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room
        !byte >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >u_room_33, >dummy_sealed_room, >u_room_35, >u_room_36, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room
        !byte >dummy_sealed_room, >u_room_41, >u_room_42, >u_room_43, >u_room_44, >u_room_45, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room
        !byte >dummy_sealed_room, >dummy_sealed_room, >u_room_52, >u_room_53, >u_room_54, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room
        !byte >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >u_room_63, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room
        !byte >dummy_sealed_room, >dummy_sealed_room, >u_room_72, >u_room_73, >u_room_74, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room

; Métadonnées Donjon & Palette (128 octets : $C116..$C195)
room_zone_palette:
dungeon_enemies_ptr:    !word map_enemies   ; $C116 ($C116..$C117)
dungeon_boss_room:      !byte $35    ; $C118
dungeon_tri_room:       !byte $36     ; $C119
dungeon_boss_type:      !byte TYPE_AQUAMENTUS ; $C11A
dungeon_boss_hp:        !byte 6   ; $C11B
dungeon_level:          !byte 1         ; $C11C
dungeon_wall_col:       !byte 11 ; $C11D
dungeon_start_rx:       !byte 3    ; $C11E
dungeon_start_ry:       !byte 7    ; $C11F
        !fill 128 - 10, 0                   ; Reste des 128 octets ($C120..$C195)

; Index de formation d'ennemis par salle (128 octets : $C196..$C215)
room_enemy_idx:
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 3, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 5, 5, 2, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 7, 3, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 7, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

; Salle ($22 : rx=2, ry=2) - RLE compact (55 octets)
u_room_22:
        !byte 8, 225, 33, 9, 19, 224, 0, 20, 19, 112, 5, 96, 20, 19, 96, 5
        !byte 0, 5, 80, 20, 19, 80, 5, 0, 5, 0, 5, 80, 13, 19, 96, 5
        !byte 0, 5, 96, 13, 19, 112, 5, 96, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 10, 114, 17, 114, 11, 255
; Salle ($23 : rx=3, ry=2) - RLE compact (59 octets)
u_room_23:
        !byte 8, 225, 33, 9, 19, 224, 0, 20, 19, 32, 37, 48, 37, 32, 20, 19
        !byte 32, 5, 112, 5, 32, 20, 13, 48, 5, 0, 85, 0, 5, 32, 20, 13
        !byte 48, 5, 112, 5, 32, 20, 19, 32, 37, 48, 37, 32, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 10, 114, 29, 114, 11, 255
; Salle ($33 : rx=3, ry=3) - RLE compact (92 octets)
u_room_33:
        !byte 8, 113, 29, 113, 9, 19, 16, 69, 16, 69, 16, 20, 19, 16, 5, 32
        !byte 5, 48, 5, 0, 5, 16, 20, 19, 16, 5, 0, 5, 0, 5, 0, 21
        !byte 0, 5, 0, 5, 16, 20, 19, 48, 5, 0, 5, 16, 5, 0, 5, 48
        !byte 20, 19, 16, 5, 0, 5, 0, 21, 0, 5, 0, 5, 0, 5, 16, 20
        !byte 19, 16, 5, 0, 5, 48, 5, 32, 5, 16, 20, 19, 16, 69, 16, 69
        !byte 16, 20, 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($35 : rx=5, ry=3) - RLE compact (48 octets)
u_room_35:
        !byte 8, 225, 33, 9, 19, 128, 69, 16, 20, 19, 160, 37, 16, 20, 19, 176
        !byte 21, 16, 20, 19, 224, 16, 14, 19, 176, 21, 32, 14, 19, 160, 37, 16
        !byte 20, 19, 128, 69, 16, 20, 19, 224, 0, 20, 10, 114, 29, 114, 11, 255
; Salle ($36 : rx=6, ry=3) - RLE compact (63 octets)
u_room_36:
        !byte 8, 225, 33, 9, 19, 224, 0, 20, 19, 32, 149, 32, 20, 19, 32, 5
        !byte 16, 6, 16, 6, 16, 5, 32, 20, 12, 48, 5, 0, 6, 48, 6, 0
        !byte 5, 32, 20, 12, 48, 5, 112, 5, 32, 20, 19, 32, 53, 16, 53, 32
        !byte 20, 19, 224, 0, 20, 19, 224, 0, 20, 10, 114, 17, 114, 11, 255
; Salle ($41 : rx=1, ry=4) - RLE compact (42 octets)
u_room_41:
        !byte 8, 225, 33, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20
        !byte 19, 224, 16, 12, 19, 224, 16, 12, 19, 224, 0, 20, 19, 224, 0, 20
        !byte 19, 224, 0, 20, 10, 114, 17, 114, 11, 255
; Salle ($42 : rx=2, ry=4) - RLE compact (43 octets)
u_room_42:
        !byte 8, 225, 33, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20
        !byte 14, 112, 5, 128, 12, 14, 224, 32, 12, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 10, 114, 29, 114, 11, 255
; Salle ($43 : rx=3, ry=4) - RLE compact (50 octets)
u_room_43:
        !byte 8, 113, 28, 113, 9, 19, 224, 0, 20, 19, 32, 21, 80, 21, 32, 20
        !byte 19, 224, 0, 20, 12, 112, 21, 112, 13, 12, 224, 32, 13, 19, 32, 21
        !byte 80, 21, 32, 20, 19, 224, 0, 20, 19, 224, 0, 20, 10, 114, 30, 114
        !byte 11, 255
; Salle ($44 : rx=4, ry=4) - RLE compact (48 octets)
u_room_44:
        !byte 8, 225, 33, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 48, 5, 80
        !byte 5, 48, 20, 13, 224, 32, 12, 13, 64, 5, 80, 5, 64, 12, 19, 224
        !byte 0, 20, 19, 224, 0, 20, 19, 224, 0, 20, 10, 114, 31, 114, 11, 255
; Salle ($45 : rx=5, ry=4) - RLE compact (70 octets)
u_room_45:
        !byte 8, 113, 29, 113, 9, 19, 224, 0, 20, 19, 32, 5, 0, 5, 0, 21
        !byte 0, 5, 0, 5, 32, 20, 19, 224, 0, 20, 12, 48, 5, 0, 5, 0
        !byte 21, 0, 5, 0, 5, 32, 20, 12, 224, 16, 20, 19, 32, 5, 0, 5
        !byte 0, 21, 0, 5, 0, 5, 32, 20, 19, 224, 0, 20, 19, 224, 0, 20
        !byte 10, 114, 17, 114, 11, 255
; Salle ($52 : rx=2, ry=5) - RLE compact (46 octets)
u_room_52:
        !byte 8, 113, 29, 113, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 96, 21
        !byte 96, 20, 19, 96, 21, 112, 14, 19, 96, 21, 112, 14, 19, 224, 0, 20
        !byte 19, 224, 0, 20, 19, 224, 0, 20, 10, 114, 17, 114, 11, 255
; Salle ($53 : rx=3, ry=5) - RLE compact (48 octets)
u_room_53:
        !byte 8, 113, 30, 113, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 48, 5
        !byte 80, 5, 48, 20, 12, 224, 32, 28, 64, 5, 80, 5, 64, 12, 19, 224
        !byte 0, 20, 19, 224, 0, 20, 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($54 : rx=4, ry=5) - RLE compact (49 octets)
u_room_54:
        !byte 8, 113, 31, 113, 9, 19, 224, 0, 20, 19, 48, 5, 80, 5, 48, 20
        !byte 19, 224, 0, 20, 12, 224, 16, 20, 12, 224, 16, 20, 19, 48, 5, 80
        !byte 5, 48, 20, 19, 224, 0, 20, 19, 224, 0, 20, 10, 114, 17, 114, 11
        !byte 255
; Salle ($63 : rx=3, ry=6) - RLE compact (46 octets)
u_room_63:
        !byte 8, 113, 28, 113, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 96, 21
        !byte 96, 20, 19, 96, 21, 96, 20, 19, 96, 21, 96, 20, 19, 224, 0, 20
        !byte 19, 224, 0, 20, 19, 224, 0, 20, 10, 114, 29, 114, 11, 255
; Salle ($72 : rx=2, ry=7) - RLE compact (42 octets)
u_room_72:
        !byte 8, 225, 33, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20
        !byte 19, 224, 16, 12, 19, 224, 16, 12, 19, 224, 0, 20, 19, 224, 0, 20
        !byte 19, 224, 0, 20, 10, 114, 17, 114, 11, 255
; Salle ($73 : rx=3, ry=7) - RLE compact (63 octets)
u_room_73:
        !byte 8, 113, 29, 113, 9, 19, 224, 0, 20, 19, 32, 6, 16, 6, 16, 6
        !byte 16, 6, 32, 20, 19, 224, 0, 20, 12, 48, 6, 16, 6, 16, 6, 16
        !byte 6, 48, 28, 224, 32, 12, 19, 32, 6, 16, 6, 16, 6, 16, 6, 32
        !byte 20, 19, 224, 0, 20, 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($74 : rx=4, ry=7) - RLE compact (51 octets)
u_room_74:
        !byte 8, 225, 33, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 48, 21, 48
        !byte 21, 48, 20, 12, 64, 21, 48, 21, 48, 20, 12, 64, 21, 48, 21, 48
        !byte 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20, 10, 114, 17
        !byte 114, 11, 255

; Salle scellée étanche pour toutes les coordonnées hors-donjon
dummy_sealed_room:
        !byte 225, 225, 225, 225, 225, 225, 225, 225, 225, 225, 225, 225, 225, 65, 255

; Table d'apparition des monstres dédupliquée (9 formations x 24 octets)
map_enemies:
        ; Formation 0
        !byte TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 1
        !byte TYPE_KEESE_RED    ,  6,  2,   TYPE_KEESE_RED    , 14,  2,   TYPE_KEESE_RED    ,  6,  6,   TYPE_KEESE_RED    , 14,  6,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 2
        !byte TYPE_GORIYA_RED   ,  8,  3,   TYPE_GORIYA_RED   , 12,  3,   TYPE_GORIYA_RED   , 10,  5,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 3
        !byte TYPE_STALFOS      ,  6,  3,   TYPE_STALFOS      , 14,  3,   TYPE_STALFOS      , 10,  4,   TYPE_STALFOS      ,  6,  6,   TYPE_STALFOS      , 14,  6,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 4
        !byte TYPE_AQUAMENTUS   , 14,  4,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 5
        !byte TYPE_GEL          ,  8,  3,   TYPE_GEL          , 12,  3,   TYPE_GEL          , 10,  5,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 6
        !byte TYPE_KEESE_RED    ,  7,  2,   TYPE_KEESE_RED    , 13,  2,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 7
        !byte TYPE_KEESE_RED    ,  6,  2,   TYPE_KEESE_RED    , 14,  2,   TYPE_KEESE_RED    , 10,  4,   TYPE_KEESE_RED    ,  6,  6,   TYPE_KEESE_RED    , 14,  6,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 8
        !byte TYPE_STALFOS      ,  7,  3,   TYPE_STALFOS      , 13,  3,   TYPE_STALFOS      , 10,  6,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0

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
        !byte 170, 128, 138, 136, 136, 136, 136, 136
        !byte 170, 2, 162, 34, 226, 226, 226, 226
        !byte 136, 136, 136, 136, 138, 128, 170, 0
        !byte 226, 226, 226, 34, 162, 2, 170, 0
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
