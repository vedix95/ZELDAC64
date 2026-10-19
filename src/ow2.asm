; GENERE par tools/tilegen.py - Chunk Overworld 2 (Salles 64..95)
!cpu 6510
!source "src/enemy_types.inc"
* = $c000

map_rooms_w:    !byte 16
map_rooms_h:    !byte 8
map_rooms_cnt:  !byte 128
map_bg_col:     !byte 13
map_mc1_col:    !byte 8
map_mc2_col:    !byte 1

; Table des offsets ry * map_rooms_w (8 octets : $C006..$C00D)
map_row_offset:
        !byte 0, 16, 32, 48, 64, 80, 96, 112
; Pointeur vers le jeu de caracteres de la carte ($C00E..$C00F)
map_charset_ptr:
        !word overworld_charset
; Pointeur vers la table des ennemis ($C010..$C011)
map_enemies_ptr_hdr:
        !word map_enemies
        !fill 4, 0

; Tables des pointeurs (128 octets LO : $C016..$C095 / 128 octets HI : $C096..$C115)
room_tbl_lo:
        !byte <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64
        !byte <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64
        !byte <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64
        !byte <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64
        !byte <room_64, <room_65, <room_66, <room_67, <room_68, <room_69, <room_70, <room_71, <room_72, <room_73, <room_74, <room_75, <room_76, <room_77, <room_78, <room_79
        !byte <room_80, <room_81, <room_82, <room_83, <room_84, <room_85, <room_86, <room_87, <room_88, <room_89, <room_90, <room_91, <room_92, <room_93, <room_94, <room_95
        !byte <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64
        !byte <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64, <room_64
room_tbl_hi:
        !byte >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64
        !byte >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64
        !byte >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64
        !byte >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64
        !byte >room_64, >room_65, >room_66, >room_67, >room_68, >room_69, >room_70, >room_71, >room_72, >room_73, >room_74, >room_75, >room_76, >room_77, >room_78, >room_79
        !byte >room_80, >room_81, >room_82, >room_83, >room_84, >room_85, >room_86, >room_87, >room_88, >room_89, >room_90, >room_91, >room_92, >room_93, >room_94, >room_95
        !byte >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64
        !byte >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64, >room_64

; Table des zones régionales par salle (128 octets : $C116..$C195)
room_zone_palette:
        !byte 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 3, 3, 0, 0, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 0, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3

; Index de formation d'ennemis par salle (128 octets : $C196..$C215)
room_enemy_idx:
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 1, 2, 3, 0, 4, 5, 0, 0, 6, 7, 8, 9, 10, 11, 11, 12
        !byte 13, 14, 15, 16, 17, 18, 19, 17, 17, 20, 21, 22, 23, 24, 25, 26
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

; Salle (0, 4) - RLE compact (53 octets)
room_64:
        !byte 21, 224, 0, 53, 224, 0, 53, 16, 8, 32, 8, 32, 8, 32, 8, 32
        !byte 21, 224, 32, 21, 16, 8, 32, 8, 32, 8, 32, 8, 32, 21, 224, 32
        !byte 21, 16, 8, 32, 8, 32, 8, 32, 8, 32, 53, 224, 0, 229, 37, 3
        !byte 229, 53, 3, 5, 255
; Salle (1, 4) - RLE compact (49 octets)
room_65:
        !byte 21, 224, 0, 53, 224, 0, 21, 48, 8, 32, 8, 32, 8, 32, 8, 0
        !byte 21, 224, 32, 21, 48, 8, 32, 8, 32, 8, 32, 8, 0, 21, 224, 32
        !byte 21, 48, 8, 32, 8, 32, 8, 32, 8, 0, 21, 224, 32, 229, 229, 181
        !byte 255
; Salle (2, 4) - RLE compact (42 octets)
room_66:
        !byte 229, 229, 165, 64, 116, 64, 21, 32, 3, 0, 116, 16, 3, 16, 21, 64
        !byte 116, 64, 21, 32, 3, 0, 116, 16, 3, 16, 21, 224, 32, 21, 3, 224
        !byte 0, 3, 37, 99, 32, 83, 165, 32, 117, 255
; Salle (3, 4) - RLE compact (42 octets)
room_67:
        !byte 229, 229, 165, 64, 117, 64, 21, 32, 3, 0, 115, 16, 3, 16, 21, 64
        !byte 115, 64, 21, 32, 3, 0, 115, 16, 3, 16, 21, 224, 32, 21, 3, 224
        !byte 0, 3, 37, 99, 32, 83, 165, 32, 117, 255
; Salle (4, 4) - RLE compact (49 octets)
room_68:
        !byte 149, 16, 116, 69, 7, 53, 16, 116, 5, 160, 83, 20, 5, 32, 3, 0
        !byte 19, 48, 83, 20, 5, 160, 83, 20, 5, 32, 3, 0, 19, 48, 83, 20
        !byte 5, 160, 83, 20, 5, 3, 144, 83, 20, 21, 99, 32, 116, 133, 32, 116
        !byte 255
; Salle (5, 4) - RLE compact (60 octets)
room_69:
        !byte 4, 229, 37, 20, 229, 37, 20, 5, 32, 35, 0, 51, 0, 35, 0, 5
        !byte 20, 5, 32, 37, 0, 5, 7, 21, 0, 37, 0, 5, 20, 5, 224, 0
        !byte 5, 20, 5, 224, 0, 5, 20, 5, 224, 0, 5, 20, 5, 224, 0, 5
        !byte 20, 5, 115, 16, 83, 5, 20, 133, 19, 101, 4, 255
; Salle (6, 4) - RLE compact (23 octets)
room_70:
        !byte 227, 227, 227, 227, 227, 211, 10, 144, 131, 160, 131, 32, 227, 19, 32, 227
        !byte 19, 32, 227, 19, 32, 115, 255
; Salle (7, 4) - RLE compact (16 octets)
room_71:
        !byte 227, 227, 227, 227, 227, 67, 224, 224, 144, 227, 227, 227, 227, 227, 67, 255
; Salle (8, 4) - RLE compact (27 octets)
room_72:
        !byte 131, 32, 227, 19, 32, 227, 19, 112, 179, 112, 35, 224, 16, 35, 224, 16
        !byte 99, 192, 99, 192, 179, 32, 227, 19, 32, 115, 255
; Salle (9, 4) - RLE compact (35 octets)
room_73:
        !byte 131, 32, 227, 19, 32, 147, 48, 35, 32, 147, 224, 32, 19, 16, 1, 224
        !byte 19, 224, 32, 19, 48, 35, 32, 147, 48, 35, 32, 227, 19, 32, 227, 19
        !byte 32, 115, 255
; Salle (10, 4) - RLE compact (35 octets)
room_74:
        !byte 133, 32, 229, 21, 32, 21, 7, 101, 224, 0, 21, 80, 19, 64, 3, 224
        !byte 224, 16, 19, 64, 3, 80, 19, 224, 0, 19, 21, 19, 192, 3, 85, 195
        !byte 229, 117, 255
; Salle (11, 4) - RLE compact (64 octets)
room_75:
        !byte 227, 3, 16, 227, 35, 16, 35, 96, 3, 48, 35, 16, 19, 144, 19, 0
        !byte 35, 16, 19, 16, 19, 48, 3, 48, 35, 16, 19, 144, 19, 0, 35, 16
        !byte 35, 96, 3, 48, 35, 16, 35, 176, 35, 16, 35, 0, 19, 48, 3, 0
        !byte 19, 0, 35, 16, 35, 0, 19, 48, 3, 0, 19, 0, 35, 16, 19, 255
; Salle (12, 4) - RLE compact (34 octets)
room_76:
        !byte 133, 3, 229, 53, 3, 181, 80, 5, 3, 53, 32, 53, 96, 5, 3, 53
        !byte 32, 53, 224, 48, 5, 224, 0, 35, 5, 3, 224, 69, 224, 69, 227, 229
        !byte 117, 255
; Salle (13, 4) - RLE compact (78 octets)
room_77:
        !byte 3, 0, 19, 0, 3, 16, 3, 32, 3, 0, 19, 0, 3, 0, 19, 0
        !byte 19, 0, 3, 16, 3, 32, 3, 0, 19, 0, 3, 0, 19, 96, 3, 64
        !byte 19, 32, 3, 5, 0, 19, 0, 3, 80, 3, 48, 3, 144, 3, 64, 19
        !byte 48, 3, 0, 19, 0, 3, 80, 3, 48, 3, 16, 3, 96, 3, 64, 19
        !byte 32, 19, 224, 32, 67, 0, 163, 0, 99, 0, 163, 0, 35, 255
; Salle (14, 4) - RLE compact (27 octets)
room_78:
        !byte 227, 227, 163, 224, 32, 3, 80, 19, 64, 3, 64, 3, 224, 48, 3, 224
        !byte 48, 19, 224, 32, 35, 224, 0, 227, 227, 179, 255
; Salle (15, 4) - RLE compact (37 octets)
room_79:
        !byte 85, 80, 116, 85, 80, 116, 69, 96, 116, 69, 96, 116, 53, 112, 4, 9
        !byte 20, 9, 36, 21, 144, 116, 21, 144, 116, 21, 19, 112, 116, 53, 19, 80
        !byte 116, 85, 80, 116, 255
; Salle (0, 5) - RLE compact (32 octets)
room_80:
        !byte 229, 37, 3, 229, 53, 3, 229, 53, 3, 229, 53, 3, 37, 224, 16, 37
        !byte 224, 16, 37, 224, 16, 37, 224, 16, 37, 224, 0, 53, 224, 0, 21, 255
; Salle (1, 5) - RLE compact (39 octets)
room_81:
        !byte 227, 227, 163, 224, 67, 32, 3, 0, 19, 0, 3, 16, 3, 96, 3, 224
        !byte 48, 3, 32, 3, 0, 19, 0, 3, 16, 3, 96, 3, 224, 83, 208, 227
        !byte 19, 32, 227, 19, 32, 51, 255
; Salle (2, 5) - RLE compact (30 octets)
room_82:
        !byte 131, 32, 227, 19, 32, 147, 32, 227, 64, 227, 64, 227, 64, 227, 19, 32
        !byte 227, 19, 224, 32, 83, 32, 35, 80, 115, 32, 35, 80, 19, 255
; Salle (3, 5) - RLE compact (44 octets)
room_83:
        !byte 131, 32, 227, 19, 32, 147, 224, 16, 35, 80, 3, 160, 19, 160, 3, 80
        !byte 19, 80, 3, 160, 19, 224, 16, 3, 224, 32, 99, 32, 3, 48, 3, 16
        !byte 3, 0, 99, 32, 3, 48, 3, 16, 3, 0, 19, 255
; Salle (4, 5) - RLE compact (40 octets)
room_84:
        !byte 131, 32, 227, 19, 32, 147, 48, 19, 48, 115, 176, 115, 80, 19, 224, 224
        !byte 51, 48, 19, 144, 21, 19, 224, 0, 21, 51, 16, 83, 16, 35, 0, 21
        !byte 51, 16, 83, 16, 35, 0, 21, 255
; Salle (5, 5) - RLE compact (43 octets)
room_85:
        !byte 227, 227, 227, 227, 147, 26, 115, 64, 10, 35, 10, 144, 19, 48, 35, 128
        !byte 19, 21, 48, 35, 128, 53, 48, 35, 128, 53, 48, 35, 48, 3, 16, 3
        !byte 0, 53, 48, 35, 48, 5, 16, 5, 0, 21, 255
; Salle (6, 5) - RLE compact (34 octets)
room_86:
        !byte 131, 32, 227, 19, 32, 227, 19, 160, 131, 48, 3, 16, 19, 224, 96, 51
        !byte 128, 3, 16, 19, 16, 53, 224, 0, 53, 224, 0, 53, 227, 3, 53, 227
        !byte 3, 255
; Salle (7, 5) - RLE compact (41 octets)
room_87:
        !byte 227, 227, 147, 128, 3, 16, 3, 48, 3, 0, 3, 224, 128, 3, 0, 19
        !byte 0, 3, 16, 3, 0, 19, 0, 3, 0, 3, 224, 208, 3, 16, 3, 48
        !byte 3, 0, 3, 224, 64, 227, 227, 147, 255
; Salle (8, 5) - RLE compact (72 octets)
room_88:
        !byte 131, 32, 227, 19, 32, 131, 0, 19, 48, 3, 32, 3, 0, 19, 32, 3
        !byte 224, 64, 3, 0, 19, 0, 3, 16, 3, 32, 3, 0, 19, 0, 3, 224
        !byte 96, 3, 0, 19, 48, 3, 32, 3, 0, 19, 32, 3, 224, 48, 67, 0
        !byte 3, 16, 3, 32, 3, 0, 19, 0, 3, 0, 67, 0, 3, 16, 3, 32
        !byte 3, 0, 19, 0, 3, 0, 3, 255
; Salle (9, 5) - RLE compact (27 octets)
room_89:
        !byte 131, 32, 227, 19, 32, 227, 19, 32, 115, 224, 224, 224, 96, 117, 131, 32
        !byte 227, 19, 32, 227, 19, 32, 227, 19, 32, 115, 255
; Salle (10, 5) - RLE compact (27 octets)
room_90:
        !byte 227, 227, 211, 224, 224, 32, 3, 224, 96, 133, 112, 3, 16, 131, 160, 131
        !byte 160, 131, 64, 51, 0, 147, 64, 51, 0, 3, 255
; Salle (11, 5) - RLE compact (73 octets)
room_91:
        !byte 3, 0, 19, 48, 3, 0, 19, 0, 35, 16, 35, 0, 19, 48, 3, 0
        !byte 19, 0, 35, 16, 19, 192, 3, 64, 3, 16, 19, 48, 3, 0, 19, 96
        !byte 3, 192, 3, 64, 3, 16, 19, 48, 3, 0, 19, 96, 3, 192, 3, 64
        !byte 3, 224, 64, 3, 0, 19, 48, 3, 0, 19, 0, 35, 0, 51, 0, 19
        !byte 48, 3, 0, 19, 0, 35, 0, 35, 255
; Salle (12, 5) - RLE compact (31 octets)
room_92:
        !byte 227, 227, 227, 163, 0, 227, 51, 48, 227, 3, 48, 227, 3, 48, 227, 3
        !byte 0, 35, 80, 147, 0, 115, 0, 147, 0, 115, 0, 147, 0, 35, 255
; Salle (13, 5) - RLE compact (35 octets)
room_93:
        !byte 51, 0, 163, 0, 99, 0, 163, 0, 99, 0, 163, 0, 35, 224, 224, 224
        !byte 224, 51, 0, 163, 0, 99, 0, 163, 0, 99, 0, 163, 0, 99, 0, 163
        !byte 0, 35, 255
; Salle (14, 5) - RLE compact (42 octets)
room_94:
        !byte 229, 213, 7, 165, 160, 21, 64, 5, 64, 3, 144, 3, 16, 5, 224, 48
        !byte 5, 64, 3, 144, 3, 16, 5, 3, 160, 19, 64, 21, 3, 112, 19, 21
        !byte 19, 16, 3, 37, 115, 85, 19, 229, 101, 255
; Salle (15, 5) - RLE compact (37 octets)
room_95:
        !byte 85, 80, 116, 85, 80, 116, 69, 96, 116, 69, 96, 116, 53, 112, 4, 9
        !byte 20, 9, 36, 21, 144, 116, 21, 144, 116, 21, 19, 112, 116, 53, 19, 80
        !byte 116, 85, 80, 116, 255

; 512 octets de caracteres Overworld
overworld_charset:
; Chars 0..31 (Tuiles 0..7 : 256 octets)
        !byte 0, 0, 0, 0, 0, 0, 0, 0   ; char 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0   ; char 1
        !byte 0, 0, 0, 0, 0, 0, 0, 0   ; char 2
        !byte 0, 0, 0, 0, 0, 0, 0, 0   ; char 3
        !byte 0, 12, 51, 0, 0, 0, 0, 0   ; char 4
        !byte 0, 0, 0, 0, 0, 12, 51, 0   ; char 5
        !byte 0, 0, 3, 0, 0, 48, 204, 0   ; char 6
        !byte 0, 192, 48, 0, 0, 0, 0, 0   ; char 7
        !byte 0, 12, 59, 12, 0, 0, 0, 0   ; char 8
        !byte 0, 0, 0, 0, 0, 0, 12, 59   ; char 9
        !byte 0, 0, 0, 3, 0, 0, 0, 0   ; char 10
        !byte 12, 0, 192, 176, 192, 0, 0, 0   ; char 11
        !byte 0, 13, 63, 55, 255, 253, 255, 223   ; char 12
        !byte 0, 64, 84, 212, 212, 213, 212, 213   ; char 13
        !byte 255, 247, 255, 223, 253, 53, 5, 21   ; char 14
        !byte 85, 213, 84, 212, 84, 112, 85, 84   ; char 15
        !byte 255, 255, 239, 255, 255, 255, 191, 255   ; char 16
        !byte 255, 255, 239, 255, 255, 255, 191, 255   ; char 17
        !byte 255, 251, 255, 255, 255, 239, 255, 255   ; char 18
        !byte 255, 251, 255, 255, 255, 239, 255, 255   ; char 19
        !byte 217, 246, 246, 182, 183, 247, 247, 247   ; char 20
        !byte 219, 245, 245, 245, 245, 253, 233, 237   ; char 21
        !byte 215, 215, 149, 153, 111, 109, 191, 110   ; char 22
        !byte 237, 237, 109, 109, 109, 109, 85, 153   ; char 23
        !byte 255, 255, 223, 253, 255, 127, 255, 247   ; char 24
        !byte 253, 247, 255, 255, 127, 247, 255, 255   ; char 25
        !byte 255, 253, 223, 255, 255, 125, 255, 223   ; char 26
        !byte 223, 255, 255, 253, 223, 255, 255, 127   ; char 27
        !byte 217, 105, 90, 103, 95, 223, 111, 223   ; char 28
        !byte 103, 105, 165, 217, 245, 247, 249, 247   ; char 29
        !byte 111, 223, 111, 223, 111, 223, 111, 223   ; char 30
        !byte 249, 247, 249, 247, 249, 247, 249, 247   ; char 31
; Chars 168..199 (Tuiles 8..15 : 256 octets)
        !byte 2, 10, 10, 41, 41, 37, 37, 37   ; char 168
        !byte 128, 128, 144, 96, 100, 84, 84, 84   ; char 169
        !byte 105, 105, 106, 106, 85, 170, 170, 85   ; char 170
        !byte 101, 101, 101, 165, 85, 170, 170, 85   ; char 171
        !byte 0, 0, 0, 0, 0, 0, 0, 0   ; char 172
        !byte 0, 0, 0, 0, 0, 0, 0, 0   ; char 173
        !byte 0, 0, 0, 0, 0, 0, 0, 0   ; char 174
        !byte 0, 0, 0, 0, 0, 0, 0, 0   ; char 175
        !byte 0, 0, 0, 0, 0, 0, 0, 0   ; char 176
        !byte 0, 0, 0, 0, 0, 0, 0, 0   ; char 177
        !byte 0, 0, 0, 0, 0, 0, 0, 0   ; char 178
        !byte 0, 0, 0, 0, 0, 0, 0, 0   ; char 179
        !byte 0, 0, 0, 0, 0, 0, 0, 0   ; char 180
        !byte 0, 0, 0, 0, 0, 0, 0, 0   ; char 181
        !byte 0, 0, 0, 0, 0, 0, 0, 0   ; char 182
        !byte 0, 0, 0, 0, 0, 0, 0, 0   ; char 183
        !byte 0, 85, 85, 255, 85, 85, 255, 85   ; char 184
        !byte 0, 85, 85, 255, 85, 85, 255, 85   ; char 185
        !byte 85, 255, 85, 85, 255, 85, 85, 0   ; char 186
        !byte 85, 255, 85, 85, 255, 85, 85, 0   ; char 187
        !byte 23, 23, 23, 23, 23, 23, 23, 23   ; char 188
        !byte 92, 92, 92, 92, 92, 92, 92, 92   ; char 189
        !byte 23, 23, 23, 23, 23, 23, 23, 23   ; char 190
        !byte 92, 92, 92, 92, 92, 92, 92, 92   ; char 191
        !byte 217, 246, 246, 182, 183, 247, 247, 247   ; char 192
        !byte 219, 245, 245, 245, 245, 253, 233, 237   ; char 193
        !byte 215, 215, 149, 153, 111, 109, 191, 110   ; char 194
        !byte 237, 237, 109, 109, 109, 109, 85, 153   ; char 195
        !byte 217, 246, 246, 182, 183, 247, 247, 247   ; char 196
        !byte 219, 245, 245, 245, 245, 253, 169, 173   ; char 197
        !byte 215, 215, 149, 153, 111, 109, 191, 110   ; char 198
        !byte 173, 237, 109, 109, 109, 109, 85, 153   ; char 199

; Formations d'ennemis dédupliquées (27 formations x 24 octets)
map_enemies:
        ; Formation 0
        !byte TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 1
        !byte TYPE_GHINI      ,  10,  4,   TYPE_GHINI      ,   3,  2,   TYPE_GHINI      ,  16,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 2
        !byte TYPE_GHINI      ,  10,  4,   TYPE_GHINI      ,   3,  7,   TYPE_GHINI      ,  16,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 3
        !byte TYPE_MOBLIN_RED ,  10,  6,   TYPE_ZORA       ,  10,  4,   TYPE_ZORA       ,   6,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 4
        !byte TYPE_OCTO_BLUE  ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  7,   TYPE_OCTO_BLUE  ,   4,  2,   TYPE_OCTO_BLUE  ,   7,  7,   TYPE_ZORA       ,  12,  1,   TYPE_ZORA       ,  19,  9,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 5
        !byte TYPE_PEAHAT     ,   9,  4,   TYPE_ZORA       ,  19,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 6
        !byte TYPE_LEEVER_RED ,  10,  4,   TYPE_LEEVER_RED ,   3,  5,   TYPE_LEEVER_RED ,  16,  7,   TYPE_LEEVER_RED ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 7
        !byte TYPE_OCTO_BLUE  ,  10,  4,   TYPE_OCTO_RED   ,   3,  7,   TYPE_OCTO_RED   ,  16,  3,   TYPE_OCTO_RED   ,   5,  2,   TYPE_OCTO_RED   ,   7,  5,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 8
        !byte TYPE_TEKTITE_BLUE,  10,  4,   TYPE_TEKTITE_BLUE,   3,  2,   TYPE_TEKTITE_BLUE,  16,  7,   TYPE_TEKTITE_BLUE,   5,  7,   TYPE_TEKTITE_BLUE,  15,  2,   TYPE_TEKTITE_BLUE,   7,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 9
        !byte TYPE_MOBLIN_RED ,  10,  4,   TYPE_MOBLIN_RED ,   3,  7,   TYPE_MOBLIN_RED ,  16,  7,   TYPE_MOBLIN_RED ,   5,  2,   TYPE_MOBLIN_RED ,  16,  2,   TYPE_MOBLIN_RED ,   7,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 10
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  7,   TYPE_OCTO_RED   ,  16,  7,   TYPE_OCTO_BLUE  ,   5,  2,   TYPE_OCTO_RED   ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 11
        !byte TYPE_MOBLIN_BLUE,  10,  4,   TYPE_MOBLIN_BLUE,   3,  7,   TYPE_MOBLIN_BLUE,  16,  7,   TYPE_MOBLIN_BLUE,   5,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 12
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  6,   TYPE_OCTO_RED   ,   6,  2,   TYPE_OCTO_BLUE  ,   7,  7,   TYPE_OCTO_BLUE  ,  11,  7,   TYPE_ZORA       ,  12,  4,   TYPE_ZORA       ,  17,  7,   TYPE_NONE       ,   0,  0
        ; Formation 13
        !byte TYPE_LYNEL_RED  ,  10,  4,   TYPE_LYNEL_RED  ,   3,  7,   TYPE_LYNEL_RED  ,  16,  7,   TYPE_LYNEL_RED  ,   6,  4,   TYPE_LYNEL_RED  ,   8,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 14
        !byte TYPE_MOBLIN_BLUE,  10,  4,   TYPE_MOBLIN_BLUE,   3,  7,   TYPE_MOBLIN_BLUE,  16,  3,   TYPE_MOBLIN_BLUE,   5,  2,   TYPE_MOBLIN_BLUE,  14,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 15
        !byte TYPE_MOBLIN_BLUE,  10,  7,   TYPE_MOBLIN_RED ,   3,  2,   TYPE_MOBLIN_BLUE,  16,  7,   TYPE_MOBLIN_RED ,   4,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 16
        !byte TYPE_MOBLIN_BLUE,  10,  4,   TYPE_MOBLIN_BLUE,   3,  7,   TYPE_MOBLIN_RED ,  16,  7,   TYPE_MOBLIN_BLUE,   5,  2,   TYPE_MOBLIN_RED ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 17
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  7,   TYPE_OCTO_RED   ,  16,  7,   TYPE_OCTO_BLUE  ,   5,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 18
        !byte TYPE_OCTO_BLUE  ,  10,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 19
        !byte TYPE_OCTO_BLUE  ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  4,   TYPE_OCTO_BLUE  ,  16,  7,   TYPE_OCTO_BLUE  ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 20
        !byte TYPE_PEAHAT     ,  10,  4,   TYPE_PEAHAT     ,   3,  3,   TYPE_PEAHAT     ,  16,  3,   TYPE_PEAHAT     ,   6,  5,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 21
        !byte TYPE_OCTO_BLUE  ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  3,   TYPE_OCTO_BLUE  ,  16,  7,   TYPE_OCTO_BLUE  ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 22
        !byte TYPE_MOBLIN_BLUE,  10,  4,   TYPE_MOBLIN_RED ,   3,  7,   TYPE_MOBLIN_BLUE,  16,  7,   TYPE_MOBLIN_RED ,   5,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 23
        !byte TYPE_MOBLIN_BLUE,   5,  7,   TYPE_MOBLIN_BLUE,  16,  2,   TYPE_MOBLIN_BLUE,  16,  7,   TYPE_MOBLIN_BLUE,  16,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 24
        !byte TYPE_MOBLIN_BLUE,  10,  4,   TYPE_MOBLIN_BLUE,   3,  3,   TYPE_MOBLIN_BLUE,  16,  7,   TYPE_MOBLIN_BLUE,  16,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 25
        !byte TYPE_MOBLIN_BLUE,  10,  4,   TYPE_MOBLIN_BLUE,   3,  7,   TYPE_MOBLIN_BLUE,  16,  7,   TYPE_MOBLIN_BLUE,   5,  2,   TYPE_MOBLIN_BLUE,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 26
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  6,   TYPE_OCTO_RED   ,   6,  2,   TYPE_OCTO_BLUE  ,   7,  7,   TYPE_OCTO_RED   ,  11,  7,   TYPE_ZORA       ,  12,  4,   TYPE_ZORA       ,  17,  7,   TYPE_NONE       ,   0,  0
