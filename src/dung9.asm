; ===========================================================================
; dung9.asm - Donjon Niveau 9 : Death Mountain (Montagne de la Mort) pour Zelda C64
; GENERE AUTOMATIQUEMENT par tools/build_dungeons.py - NE PAS MODIFIER
; Salles étanches : 22 salles
; ===========================================================================
!cpu 6510
!source "src/enemy_types.inc"
* = $c000

; En-tête Donjon (6 octets : $C000..$C005)
map_rooms_w:        !byte 16
map_rooms_h:        !byte 8
map_rooms_cnt:      !byte 22
map_bg_col:         !byte 0   ; noir
map_mc1_col:        !byte 2
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
        !byte <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <u_room_23, <u_room_24, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room
        !byte <dummy_sealed_room, <dummy_sealed_room, <u_room_32, <u_room_33, <u_room_34, <u_room_35, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room
        !byte <dummy_sealed_room, <dummy_sealed_room, <u_room_42, <u_room_43, <u_room_44, <u_room_45, <u_room_46, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room
        !byte <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <u_room_53, <u_room_54, <u_room_55, <u_room_56, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room
        !byte <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <u_room_63, <u_room_64, <u_room_65, <u_room_66, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room
        !byte <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <u_room_75, <u_room_76, <u_room_77, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room
room_tbl_hi:
        !byte >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room
        !byte >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room
        !byte >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >u_room_23, >u_room_24, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room
        !byte >dummy_sealed_room, >dummy_sealed_room, >u_room_32, >u_room_33, >u_room_34, >u_room_35, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room
        !byte >dummy_sealed_room, >dummy_sealed_room, >u_room_42, >u_room_43, >u_room_44, >u_room_45, >u_room_46, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room
        !byte >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >u_room_53, >u_room_54, >u_room_55, >u_room_56, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room
        !byte >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >u_room_63, >u_room_64, >u_room_65, >u_room_66, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room
        !byte >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >u_room_75, >u_room_76, >u_room_77, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room

; Métadonnées Donjon & Palette (128 octets : $C116..$C195)
room_zone_palette:
dungeon_enemies_ptr:    !word map_enemies   ; $C116 ($C116..$C117)
dungeon_boss_room:      !byte $42    ; $C118
dungeon_tri_room:       !byte $32     ; $C119
dungeon_boss_type:      !byte TYPE_GANON ; $C11A
dungeon_boss_hp:        !byte 16   ; $C11B
dungeon_level:          !byte 9         ; $C11C
dungeon_wall_col:       !byte 10 ; $C11D
dungeon_start_rx:       !byte 6    ; $C11E
dungeon_start_ry:       !byte 7    ; $C11F
        !fill 128 - 10, 0                   ; Reste des 128 octets ($C120..$C195)

; Index de formation d'ennemis par salle (128 octets : $C196..$C215)
room_enemy_idx:
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 1, 3, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 5, 6, 7, 8, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 8, 4, 10, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 12, 8, 7, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 14, 0, 14, 0, 0, 0, 0, 0, 0, 0, 0

; Salle ($23 : rx=3, ry=2) - RLE compact (57 octets)
u_room_23:
        !byte 8, 225, 33, 9, 19, 224, 0, 20, 19, 32, 149, 32, 20, 19, 32, 149
        !byte 32, 20, 19, 32, 21, 80, 5, 7, 48, 15, 19, 32, 21, 80, 21, 48
        !byte 15, 19, 32, 53, 16, 53, 32, 20, 19, 32, 53, 16, 53, 32, 20, 19
        !byte 224, 0, 20, 10, 114, 29, 114, 11, 255
; Salle ($24 : rx=4, ry=2) - RLE compact (91 octets)
u_room_24:
        !byte 8, 225, 33, 9, 19, 16, 69, 16, 69, 16, 20, 19, 16, 5, 32, 5
        !byte 48, 5, 0, 5, 16, 20, 19, 16, 5, 0, 5, 0, 5, 0, 21, 0
        !byte 5, 0, 5, 16, 20, 15, 64, 5, 0, 5, 16, 5, 0, 5, 48, 20
        !byte 15, 32, 5, 0, 5, 0, 21, 0, 5, 0, 5, 0, 5, 16, 20, 19
        !byte 16, 5, 0, 5, 48, 5, 32, 5, 16, 20, 19, 16, 69, 16, 69, 16
        !byte 20, 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($32 : rx=2, ry=3) - RLE compact (81 octets)
u_room_32:
        !byte 8, 225, 33, 9, 19, 16, 181, 16, 20, 19, 16, 5, 32, 5, 16, 5
        !byte 32, 5, 16, 20, 19, 16, 5, 0, 21, 48, 21, 0, 5, 16, 20, 19
        !byte 16, 5, 0, 21, 48, 21, 0, 5, 16, 20, 19, 16, 5, 32, 6, 16
        !byte 6, 32, 5, 16, 20, 19, 16, 5, 144, 5, 16, 20, 19, 16, 5, 0
        !byte 6, 80, 6, 0, 5, 16, 20, 19, 224, 0, 20, 10, 114, 28, 114, 11
        !byte 255
; Salle ($33 : rx=3, ry=3) - RLE compact (45 octets)
u_room_33:
        !byte 8, 113, 29, 113, 9, 19, 224, 0, 20, 19, 16, 181, 16, 20, 19, 224
        !byte 0, 20, 19, 224, 16, 15, 19, 224, 16, 15, 19, 16, 181, 16, 20, 19
        !byte 224, 0, 20, 19, 224, 0, 20, 10, 114, 17, 114, 11, 255
; Salle ($34 : rx=4, ry=3) - RLE compact (54 octets)
u_room_34:
        !byte 8, 113, 28, 113, 9, 19, 224, 0, 20, 19, 32, 149, 32, 20, 19, 32
        !byte 5, 112, 5, 32, 20, 15, 48, 5, 112, 5, 32, 20, 15, 48, 5, 112
        !byte 5, 32, 20, 19, 32, 149, 32, 20, 19, 224, 0, 20, 19, 224, 0, 20
        !byte 10, 114, 17, 114, 11, 255
; Salle ($35 : rx=5, ry=3) - RLE compact (42 octets)
u_room_35:
        !byte 8, 225, 33, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20
        !byte 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20
        !byte 19, 224, 0, 20, 10, 114, 17, 114, 11, 255
; Salle ($42 : rx=2, ry=4) - RLE compact (49 octets)
u_room_42:
        !byte 8, 113, 30, 113, 9, 19, 16, 6, 144, 6, 16, 20, 19, 224, 0, 20
        !byte 19, 224, 0, 20, 19, 224, 16, 15, 19, 224, 16, 15, 19, 224, 0, 20
        !byte 19, 16, 6, 144, 6, 16, 20, 19, 224, 0, 20, 10, 114, 17, 114, 11
        !byte 255
; Salle ($43 : rx=3, ry=4) - RLE compact (42 octets)
u_room_43:
        !byte 8, 225, 33, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20
        !byte 15, 224, 16, 20, 15, 224, 16, 20, 19, 224, 0, 20, 19, 224, 0, 20
        !byte 19, 224, 0, 20, 10, 114, 31, 114, 11, 255
; Salle ($44 : rx=4, ry=4) - RLE compact (42 octets)
u_room_44:
        !byte 8, 225, 33, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20
        !byte 19, 224, 16, 12, 19, 224, 16, 12, 19, 224, 0, 20, 19, 224, 0, 20
        !byte 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($45 : rx=5, ry=4) - RLE compact (42 octets)
u_room_45:
        !byte 8, 225, 33, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20
        !byte 12, 192, 7, 48, 28, 224, 32, 12, 19, 224, 0, 20, 19, 224, 0, 20
        !byte 19, 224, 0, 20, 10, 114, 31, 114, 11, 255
; Salle ($46 : rx=6, ry=4) - RLE compact (42 octets)
u_room_46:
        !byte 8, 225, 33, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20
        !byte 12, 224, 16, 20, 12, 224, 16, 20, 19, 224, 0, 20, 19, 224, 0, 20
        !byte 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($53 : rx=3, ry=5) - RLE compact (46 octets)
u_room_53:
        !byte 8, 113, 31, 113, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 80, 6, 16, 6, 80, 20, 19, 224, 0, 20, 19, 224, 0, 20
        !byte 19, 224, 0, 20, 19, 224, 0, 20, 10, 114, 31, 114, 11, 255
; Salle ($54 : rx=4, ry=5) - RLE compact (80 octets)
u_room_54:
        !byte 8, 113, 28, 113, 9, 19, 32, 5, 0, 5, 144, 20, 19, 32, 5, 0
        !byte 37, 0, 37, 48, 20, 19, 32, 5, 32, 5, 32, 37, 16, 20, 19, 32
        !byte 5, 0, 5, 0, 5, 32, 5, 64, 15, 19, 32, 37, 0, 5, 32, 5
        !byte 64, 15, 19, 96, 5, 0, 5, 0, 5, 0, 5, 16, 20, 19, 48, 5
        !byte 48, 5, 32, 5, 16, 20, 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($55 : rx=5, ry=5) - RLE compact (55 octets)
u_room_55:
        !byte 8, 113, 31, 113, 9, 19, 224, 0, 20, 19, 112, 5, 96, 20, 19, 96
        !byte 5, 0, 5, 80, 20, 15, 96, 5, 0, 7, 0, 5, 80, 31, 112, 5
        !byte 0, 5, 96, 15, 19, 112, 5, 96, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 10, 114, 31, 114, 11, 255
; Salle ($56 : rx=6, ry=5) - RLE compact (45 octets)
u_room_56:
        !byte 8, 113, 28, 113, 9, 19, 224, 0, 20, 19, 16, 181, 16, 20, 19, 224
        !byte 0, 20, 15, 224, 16, 20, 15, 224, 16, 20, 19, 16, 181, 16, 20, 19
        !byte 224, 0, 20, 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($63 : rx=3, ry=6) - RLE compact (50 octets)
u_room_63:
        !byte 8, 113, 31, 113, 9, 19, 144, 53, 16, 20, 19, 144, 53, 16, 20, 19
        !byte 160, 37, 16, 20, 19, 192, 7, 16, 20, 19, 160, 37, 16, 20, 19, 144
        !byte 53, 16, 20, 19, 144, 53, 16, 20, 19, 224, 0, 20, 10, 114, 17, 114
        !byte 11, 255
; Salle ($64 : rx=4, ry=6) - RLE compact (50 octets)
u_room_64:
        !byte 8, 113, 28, 113, 9, 19, 224, 0, 20, 19, 32, 21, 80, 21, 32, 20
        !byte 19, 224, 0, 20, 19, 96, 21, 112, 12, 19, 224, 16, 12, 19, 32, 21
        !byte 80, 21, 32, 20, 19, 224, 0, 20, 19, 224, 0, 20, 10, 114, 17, 114
        !byte 11, 255
; Salle ($65 : rx=5, ry=6) - RLE compact (43 octets)
u_room_65:
        !byte 8, 113, 31, 113, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 16, 181
        !byte 16, 20, 12, 224, 32, 28, 224, 32, 12, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 10, 114, 17, 114, 11, 255
; Salle ($66 : rx=6, ry=6) - RLE compact (43 octets)
u_room_66:
        !byte 8, 113, 30, 113, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 14, 224, 16, 20, 14, 224, 16, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($75 : rx=5, ry=7) - RLE compact (65 octets)
u_room_75:
        !byte 8, 225, 33, 9, 19, 32, 5, 32, 53, 0, 21, 16, 20, 19, 96, 53
        !byte 0, 21, 16, 20, 19, 96, 53, 0, 21, 16, 20, 19, 96, 55, 0, 23
        !byte 32, 12, 19, 96, 53, 0, 21, 32, 12, 19, 96, 101, 16, 20, 19, 32
        !byte 5, 32, 53, 0, 21, 16, 20, 19, 224, 0, 20, 10, 114, 17, 114, 11
        !byte 255
; Salle ($76 : rx=6, ry=7) - RLE compact (64 octets)
u_room_76:
        !byte 8, 113, 28, 113, 9, 19, 224, 0, 20, 19, 32, 6, 16, 6, 16, 6
        !byte 16, 6, 32, 20, 19, 224, 0, 20, 19, 32, 6, 16, 6, 16, 6, 16
        !byte 6, 32, 20, 19, 224, 0, 20, 19, 32, 6, 16, 6, 16, 6, 16, 6
        !byte 32, 20, 19, 224, 0, 20, 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($77 : rx=7, ry=7) - RLE compact (65 octets)
u_room_77:
        !byte 8, 225, 33, 9, 19, 32, 5, 32, 53, 0, 21, 16, 20, 19, 96, 53
        !byte 0, 21, 16, 20, 19, 96, 53, 0, 21, 16, 20, 12, 112, 55, 0, 23
        !byte 16, 20, 12, 112, 53, 0, 21, 16, 20, 19, 96, 101, 16, 20, 19, 32
        !byte 5, 32, 53, 0, 21, 16, 20, 19, 224, 0, 20, 10, 114, 17, 114, 11
        !byte 255

; Salle scellée étanche pour toutes les coordonnées hors-donjon
dummy_sealed_room:
        !byte 225, 225, 225, 225, 225, 225, 225, 225, 225, 225, 225, 225, 225, 65, 255

; Table d'apparition des monstres dédupliquée (15 formations x 24 octets)
map_enemies:
        ; Formation 0
        !byte TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 1
        !byte TYPE_GEL          ,  6,  3,   TYPE_GEL          , 14,  3,   TYPE_GEL          ,  8,  6,   TYPE_GEL          , 12,  6,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 2
        !byte TYPE_LIKE_LIKE    ,  6,  3,   TYPE_LIKE_LIKE    , 14,  3,   TYPE_LIKE_LIKE    , 10,  5,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 3
        !byte TYPE_STALFOS      ,  6,  3,   TYPE_STALFOS      , 14,  3,   TYPE_STALFOS      ,  8,  6,   TYPE_STALFOS      , 12,  6,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 4
        !byte TYPE_DARKNUT_RED  ,  8,  3,   TYPE_DARKNUT_RED  , 12,  3,   TYPE_DARKNUT_RED  , 10,  5,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 5
        !byte TYPE_GANON        , 10,  4,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 6
        !byte TYPE_STALFOS      , 10,  4,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 7
        !byte TYPE_WALLMASTER   ,  6,  3,   TYPE_WALLMASTER   , 14,  3,   TYPE_WALLMASTER   ,  6,  6,   TYPE_WALLMASTER   , 14,  6,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 8
        !byte TYPE_DARKNUT_BLUE ,  6,  3,   TYPE_DARKNUT_BLUE , 14,  3,   TYPE_DARKNUT_BLUE ,  8,  6,   TYPE_DARKNUT_BLUE , 12,  6,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 9
        !byte TYPE_WIZZROBE_BLUE,  8,  3,   TYPE_WIZZROBE_BLUE, 12,  3,   TYPE_WIZZROBE_BLUE, 10,  5,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 10
        !byte TYPE_DARKNUT_BLUE , 10,  4,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 11
        !byte TYPE_GORIYA_RED   ,  6,  3,   TYPE_GORIYA_RED   , 14,  3,   TYPE_GORIYA_RED   ,  8,  6,   TYPE_GORIYA_RED   , 12,  6,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 12
        !byte TYPE_GORIYA_RED   ,  8,  3,   TYPE_GORIYA_RED   , 12,  3,   TYPE_GORIYA_RED   , 10,  5,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 13
        !byte TYPE_DARKNUT_RED  , 10,  4,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 14
        !byte TYPE_GIBDO        ,  6,  3,   TYPE_GIBDO        , 14,  3,   TYPE_GIBDO        , 10,  5,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0

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
