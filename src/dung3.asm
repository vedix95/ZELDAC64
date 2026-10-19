; ===========================================================================
; dung3.asm - Donjon Niveau 3 : Manji pour Zelda C64
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
        !byte <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room
        !byte <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room
        !byte <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <u_room_3a, <u_room_3b, <u_room_3c, <u_room_3d, <dummy_sealed_room, <dummy_sealed_room
        !byte <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <u_room_4a, <u_room_4b, <u_room_4c, <u_room_4d, <dummy_sealed_room, <dummy_sealed_room
        !byte <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <u_room_5a, <u_room_5b, <u_room_5c, <u_room_5d, <dummy_sealed_room, <dummy_sealed_room
        !byte <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <u_room_6a, <u_room_6b, <u_room_6c, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room
        !byte <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room, <u_room_7b, <u_room_7c, <dummy_sealed_room, <dummy_sealed_room, <dummy_sealed_room
room_tbl_hi:
        !byte >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room
        !byte >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room
        !byte >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room
        !byte >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >u_room_3a, >u_room_3b, >u_room_3c, >u_room_3d, >dummy_sealed_room, >dummy_sealed_room
        !byte >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >u_room_4a, >u_room_4b, >u_room_4c, >u_room_4d, >dummy_sealed_room, >dummy_sealed_room
        !byte >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >u_room_5a, >u_room_5b, >u_room_5c, >u_room_5d, >dummy_sealed_room, >dummy_sealed_room
        !byte >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >u_room_6a, >u_room_6b, >u_room_6c, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room
        !byte >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room, >u_room_7b, >u_room_7c, >dummy_sealed_room, >dummy_sealed_room, >dummy_sealed_room

; Métadonnées Donjon & Palette (128 octets : $C116..$C195)
room_zone_palette:
dungeon_enemies_ptr:    !word map_enemies   ; $C116 ($C116..$C117)
dungeon_boss_room:      !byte $4d    ; $C118
dungeon_tri_room:       !byte $3d     ; $C119
dungeon_boss_type:      !byte TYPE_MANHANDLA ; $C11A
dungeon_boss_hp:        !byte 8   ; $C11B
dungeon_level:          !byte 3         ; $C11C
dungeon_wall_col:       !byte 13 ; $C11D
dungeon_start_rx:       !byte 12    ; $C11E
dungeon_start_ry:       !byte 7    ; $C11F
        !fill 128 - 10, 0                   ; Reste des 128 octets ($C120..$C195)

; Index de formation d'ennemis par salle (128 octets : $C196..$C215)
room_enemy_idx:
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 2, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0

; Salle ($3a : rx=10, ry=3) - RLE compact (43 octets)
u_room_3a:
        !byte 8, 113, 28, 113, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($3b : rx=11, ry=3) - RLE compact (43 octets)
u_room_3b:
        !byte 8, 113, 28, 113, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($3c : rx=12, ry=3) - RLE compact (43 octets)
u_room_3c:
        !byte 8, 113, 28, 113, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($3d : rx=13, ry=3) - RLE compact (43 octets)
u_room_3d:
        !byte 8, 113, 28, 113, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($4a : rx=10, ry=4) - RLE compact (43 octets)
u_room_4a:
        !byte 8, 113, 28, 113, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($4b : rx=11, ry=4) - RLE compact (43 octets)
u_room_4b:
        !byte 8, 113, 28, 113, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($4c : rx=12, ry=4) - RLE compact (43 octets)
u_room_4c:
        !byte 8, 113, 28, 113, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($4d : rx=13, ry=4) - RLE compact (43 octets)
u_room_4d:
        !byte 8, 113, 28, 113, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($5a : rx=10, ry=5) - RLE compact (43 octets)
u_room_5a:
        !byte 8, 113, 28, 113, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($5b : rx=11, ry=5) - RLE compact (43 octets)
u_room_5b:
        !byte 8, 113, 28, 113, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($5c : rx=12, ry=5) - RLE compact (43 octets)
u_room_5c:
        !byte 8, 113, 28, 113, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($5d : rx=13, ry=5) - RLE compact (43 octets)
u_room_5d:
        !byte 8, 113, 28, 113, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($6a : rx=10, ry=6) - RLE compact (43 octets)
u_room_6a:
        !byte 8, 113, 28, 113, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($6b : rx=11, ry=6) - RLE compact (43 octets)
u_room_6b:
        !byte 8, 113, 28, 113, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($6c : rx=12, ry=6) - RLE compact (43 octets)
u_room_6c:
        !byte 8, 113, 28, 113, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($7b : rx=11, ry=7) - RLE compact (43 octets)
u_room_7b:
        !byte 8, 113, 28, 113, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 10, 114, 28, 114, 11, 255
; Salle ($7c : rx=12, ry=7) - RLE compact (43 octets)
u_room_7c:
        !byte 8, 113, 28, 113, 9, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0, 20, 19, 224, 0
        !byte 20, 19, 224, 0, 20, 10, 114, 28, 114, 11, 255

; Salle scellée étanche pour toutes les coordonnées hors-donjon
dummy_sealed_room:
        !byte 225, 225, 225, 225, 225, 225, 225, 225, 225, 225, 225, 225, 225, 65, 255

; Table d'apparition des monstres dédupliquée (3 formations x 24 octets)
map_enemies:
        ; Formation 0
        !byte TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 1
        !byte TYPE_STALFOS      ,  8,  4,   TYPE_KEESE_RED    , 12,  3,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0
        ; Formation 2
        !byte TYPE_MANHANDLA    , 10,  4,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0,   TYPE_NONE         ,  0,  0

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
