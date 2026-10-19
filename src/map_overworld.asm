; GENERE par tools/tilegen.py - Chunk Overworld 3 (Salles 96..127)
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
        !byte <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96
        !byte <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96
        !byte <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96
        !byte <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96
        !byte <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96
        !byte <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96, <room_96
        !byte <room_96, <room_97, <room_98, <room_99, <room_100, <room_101, <room_102, <room_103, <room_104, <room_105, <room_106, <room_107, <room_108, <room_109, <room_110, <room_111
        !byte <room_112, <room_113, <room_114, <room_115, <room_116, <room_117, <room_118, <room_119, <room_120, <room_121, <room_122, <room_123, <room_124, <room_125, <room_126, <room_127
room_tbl_hi:
        !byte >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96
        !byte >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96
        !byte >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96
        !byte >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96
        !byte >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96
        !byte >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96, >room_96
        !byte >room_96, >room_97, >room_98, >room_99, >room_100, >room_101, >room_102, >room_103, >room_104, >room_105, >room_106, >room_107, >room_108, >room_109, >room_110, >room_111
        !byte >room_112, >room_113, >room_114, >room_115, >room_116, >room_117, >room_118, >room_119, >room_120, >room_121, >room_122, >room_123, >room_124, >room_125, >room_126, >room_127

; Table des zones régionales par salle (128 octets : $C116..$C195)
room_zone_palette:
        !byte 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 3, 3, 0, 0, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 0, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3

; Index de formation d'ennemis par salle (128 octets : $C196..$C215)
room_enemy_idx:
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 1, 2, 3, 4, 5, 6, 7, 8, 9, 8, 7, 4, 10, 11, 12, 13
        !byte 14, 15, 16, 17, 18, 19, 20, 0, 8, 21, 22, 23, 24, 25, 26, 27

; Salle (0, 6) - RLE compact (28 octets)
room_96:
        !byte 19, 224, 0, 51, 224, 0, 51, 224, 16, 35, 224, 32, 19, 224, 32, 19
        !byte 224, 32, 19, 224, 16, 35, 224, 0, 227, 227, 179, 255
; Salle (1, 6) - RLE compact (26 octets)
room_97:
        !byte 195, 32, 227, 19, 32, 227, 19, 32, 51, 224, 224, 224, 224, 195, 32, 227
        !byte 19, 32, 227, 19, 32, 227, 19, 32, 51, 255
; Salle (2, 6) - RLE compact (35 octets)
room_98:
        !byte 83, 32, 35, 80, 115, 32, 35, 80, 115, 48, 19, 224, 32, 19, 224, 32
        !byte 19, 224, 32, 19, 112, 115, 16, 115, 16, 115, 16, 227, 35, 16, 227, 35
        !byte 16, 147, 255
; Salle (3, 6) - RLE compact (55 octets)
room_99:
        !byte 67, 32, 3, 48, 3, 16, 3, 0, 99, 32, 3, 48, 3, 16, 3, 0
        !byte 19, 48, 3, 112, 3, 64, 3, 112, 3, 224, 3, 112, 3, 16, 3, 160
        !byte 3, 224, 3, 112, 3, 64, 35, 224, 0, 163, 48, 3, 16, 3, 0, 163
        !byte 48, 3, 16, 3, 0, 19, 255
; Salle (4, 6) - RLE compact (36 octets)
room_100:
        !byte 53, 16, 85, 16, 37, 0, 85, 16, 37, 7, 21, 16, 37, 0, 53, 224
        !byte 160, 3, 224, 224, 128, 3, 160, 19, 224, 32, 21, 19, 224, 0, 53, 227
        !byte 3, 229, 69, 255
; Salle (5, 6) - RLE compact (48 octets)
room_101:
        !byte 21, 48, 35, 48, 5, 16, 5, 0, 53, 48, 35, 48, 5, 16, 5, 0
        !byte 21, 80, 36, 48, 5, 176, 36, 96, 5, 128, 41, 48, 5, 176, 36, 96
        !byte 5, 128, 36, 48, 5, 176, 36, 160, 67, 0, 211, 69, 0, 35, 165, 255
; Salle (6, 6) - RLE compact (31 octets)
room_102:
        !byte 229, 213, 7, 149, 48, 69, 144, 5, 144, 53, 144, 69, 224, 80, 53, 144
        !byte 69, 144, 3, 224, 32, 3, 5, 227, 3, 16, 229, 37, 16, 21, 255
; Salle (7, 6) - RLE compact (44 octets)
room_103:
        !byte 229, 229, 165, 32, 1, 0, 17, 112, 1, 16, 5, 224, 128, 1, 0, 17
        !byte 112, 1, 224, 112, 3, 32, 1, 0, 17, 112, 1, 16, 3, 5, 3, 144
        !byte 19, 48, 3, 37, 99, 32, 21, 51, 165, 32, 117, 255
; Salle (8, 6) - RLE compact (97 octets)
room_104:
        !byte 21, 19, 0, 3, 16, 3, 32, 3, 0, 19, 0, 3, 0, 3, 21, 19
        !byte 0, 3, 16, 3, 32, 3, 0, 19, 0, 3, 0, 3, 5, 48, 3, 80
        !byte 3, 48, 3, 0, 3, 16, 19, 224, 80, 3, 16, 3, 32, 3, 0, 19
        !byte 0, 3, 48, 19, 224, 0, 3, 48, 3, 80, 3, 48, 3, 0, 3, 5
        !byte 3, 224, 16, 3, 21, 19, 0, 3, 16, 3, 32, 3, 0, 19, 0, 3
        !byte 0, 3, 21, 19, 0, 3, 16, 3, 32, 3, 0, 19, 0, 3, 0, 3
        !byte 255
; Salle (9, 6) - RLE compact (31 octets)
room_105:
        !byte 131, 32, 227, 19, 32, 131, 64, 19, 48, 115, 16, 19, 112, 115, 80, 19
        !byte 208, 19, 224, 0, 3, 64, 19, 176, 19, 224, 32, 227, 227, 147, 255
; Salle (10, 6) - RLE compact (24 octets)
room_106:
        !byte 131, 64, 51, 0, 147, 64, 51, 0, 147, 160, 131, 96, 3, 224, 224, 128
        !byte 3, 224, 224, 192, 227, 227, 147, 255
; Salle (11, 6) - RLE compact (55 octets)
room_107:
        !byte 3, 0, 19, 48, 3, 0, 19, 0, 35, 0, 51, 0, 19, 48, 3, 0
        !byte 19, 0, 35, 0, 35, 192, 3, 64, 3, 16, 19, 48, 3, 0, 19, 224
        !byte 80, 3, 112, 19, 48, 3, 0, 19, 224, 80, 3, 64, 3, 224, 32, 227
        !byte 3, 48, 227, 3, 48, 19, 255
; Salle (12, 6) - RLE compact (32 octets)
room_108:
        !byte 67, 0, 147, 0, 115, 0, 147, 0, 115, 0, 19, 128, 35, 80, 19, 128
        !byte 35, 80, 19, 128, 35, 80, 19, 128, 163, 128, 179, 160, 227, 227, 147, 255
; Salle (13, 6) - RLE compact (33 octets)
room_109:
        !byte 51, 0, 163, 0, 99, 0, 163, 0, 67, 32, 163, 0, 67, 32, 163, 48
        !byte 19, 32, 163, 48, 19, 32, 163, 48, 19, 32, 227, 64, 227, 227, 227, 147
        !byte 255
; Salle (14, 6) - RLE compact (27 octets)
room_110:
        !byte 227, 227, 163, 32, 51, 224, 144, 67, 80, 51, 0, 35, 224, 80, 67, 16
        !byte 3, 32, 51, 176, 19, 224, 32, 227, 227, 147, 255
; Salle (15, 6) - RLE compact (27 octets)
room_111:
        !byte 85, 80, 116, 53, 7, 5, 80, 116, 176, 116, 176, 116, 176, 116, 176, 116
        !byte 176, 116, 176, 116, 83, 80, 116, 85, 80, 116, 255
; Salle (0, 7) - RLE compact (41 octets)
room_112:
        !byte 229, 229, 53, 7, 133, 16, 33, 0, 33, 96, 21, 48, 35, 0, 35, 96
        !byte 5, 224, 48, 5, 3, 80, 17, 16, 17, 80, 21, 19, 48, 19, 16, 19
        !byte 80, 53, 3, 224, 69, 227, 229, 69, 255
; Salle (1, 7) - RLE compact (25 octets)
room_113:
        !byte 197, 32, 229, 21, 32, 53, 224, 32, 21, 224, 224, 224, 224, 224, 32, 19
        !byte 224, 16, 3, 21, 227, 19, 229, 117, 255
; Salle (2, 7) - RLE compact (22 octets)
room_114:
        !byte 115, 16, 227, 35, 16, 227, 227, 16, 227, 35, 112, 179, 112, 211, 80, 211
        !byte 224, 32, 227, 227, 147, 255
; Salle (3, 7) - RLE compact (31 octets)
room_115:
        !byte 131, 48, 3, 16, 3, 0, 163, 48, 3, 16, 3, 0, 163, 144, 147, 160
        !byte 131, 48, 3, 80, 131, 160, 131, 144, 3, 224, 32, 227, 227, 179, 255
; Salle (4, 7) - RLE compact (46 octets)
room_116:
        !byte 229, 229, 165, 112, 3, 21, 3, 80, 5, 64, 5, 16, 21, 7, 37, 16
        !byte 5, 16, 5, 224, 48, 5, 64, 5, 16, 5, 48, 5, 16, 5, 16, 5
        !byte 3, 224, 32, 21, 3, 224, 0, 3, 37, 227, 3, 229, 101, 255
; Salle (5, 7) - RLE compact (58 octets)
room_117:
        !byte 69, 0, 35, 197, 12, 21, 0, 35, 181, 64, 35, 0, 17, 48, 1, 32
        !byte 5, 64, 35, 48, 1, 80, 5, 32, 1, 0, 35, 0, 17, 48, 1, 32
        !byte 5, 64, 35, 48, 1, 80, 5, 64, 35, 0, 17, 48, 1, 32, 5, 3
        !byte 48, 35, 160, 21, 227, 35, 85, 35, 165, 255
; Salle (6, 7) - RLE compact (39 octets)
room_118:
        !byte 229, 5, 16, 229, 37, 16, 21, 144, 17, 80, 21, 192, 1, 64, 5, 16
        !byte 17, 16, 17, 16, 17, 224, 80, 1, 64, 3, 144, 17, 80, 3, 5, 224
        !byte 32, 21, 227, 35, 229, 101, 255
; Salle (7, 7) - RLE compact (29 octets)
room_119:
        !byte 133, 32, 197, 7, 37, 32, 181, 112, 149, 144, 117, 224, 64, 19, 224, 0
        !byte 19, 21, 224, 0, 53, 224, 0, 53, 227, 3, 229, 101, 255
; Salle (8, 7) - RLE compact (80 octets)
room_120:
        !byte 21, 19, 0, 3, 16, 3, 32, 3, 0, 19, 0, 3, 0, 3, 21, 19
        !byte 0, 3, 16, 3, 32, 3, 0, 19, 0, 3, 0, 3, 21, 80, 3, 32
        !byte 3, 0, 19, 0, 3, 16, 5, 0, 19, 0, 3, 224, 96, 3, 32, 3
        !byte 0, 19, 0, 3, 16, 3, 0, 19, 0, 3, 208, 5, 3, 80, 3, 32
        !byte 3, 0, 19, 0, 3, 16, 21, 224, 32, 21, 227, 35, 21, 227, 35, 255
; Salle (9, 7) - RLE compact (38 octets)
room_121:
        !byte 229, 229, 149, 16, 85, 128, 37, 48, 53, 48, 5, 48, 37, 64, 37, 16
        !byte 21, 0, 5, 224, 32, 5, 48, 35, 224, 16, 37, 64, 35, 112, 3, 37
        !byte 67, 37, 115, 229, 133, 255
; Salle (10, 7) - RLE compact (25 octets)
room_122:
        !byte 229, 229, 229, 112, 165, 128, 101, 224, 64, 51, 128, 99, 53, 3, 112, 181
        !byte 51, 32, 3, 229, 5, 35, 229, 197, 255
; Salle (11, 7) - RLE compact (26 octets)
room_123:
        !byte 213, 48, 229, 5, 48, 149, 176, 85, 224, 224, 48, 83, 32, 164, 85, 19
        !byte 0, 164, 117, 3, 164, 133, 164, 133, 164, 255
; Salle (12, 7) - RLE compact (15 octets)
room_124:
        !byte 229, 229, 149, 224, 224, 224, 224, 228, 228, 228, 228, 228, 228, 148, 255
; Salle (13, 7) - RLE compact (15 octets)
room_125:
        !byte 229, 229, 149, 224, 224, 224, 224, 228, 228, 228, 228, 228, 228, 148, 255
; Salle (14, 7) - RLE compact (17 octets)
room_126:
        !byte 229, 229, 149, 16, 229, 37, 224, 224, 144, 228, 228, 228, 228, 228, 228, 148
        !byte 255
; Salle (15, 7) - RLE compact (22 octets)
room_127:
        !byte 85, 80, 116, 85, 80, 116, 85, 80, 116, 176, 116, 144, 25, 228, 228, 228
        !byte 228, 228, 228, 228, 36, 255

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

; Formations d'ennemis dédupliquées (28 formations x 24 octets)
map_enemies:
        ; Formation 0
        !byte TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 1
        !byte TYPE_PEAHAT     ,  10,  4,   TYPE_PEAHAT     ,   3,  7,   TYPE_LYNEL_RED  ,  16,  7,   TYPE_LYNEL_BLUE ,   5,  2,   TYPE_LYNEL_RED  ,  15,  2,   TYPE_LYNEL_BLUE ,   7,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 2
        !byte TYPE_MOBLIN_BLUE,  10,  4,   TYPE_MOBLIN_BLUE,   3,  3,   TYPE_MOBLIN_BLUE,  16,  3,   TYPE_MOBLIN_BLUE,  14,  7,   TYPE_MOBLIN_BLUE,   6,  5,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 3
        !byte TYPE_MOBLIN_BLUE,   9,  4,   TYPE_MOBLIN_BLUE,  16,  2,   TYPE_MOBLIN_BLUE,   3,  3,   TYPE_MOBLIN_BLUE,  13,  5,   TYPE_MOBLIN_BLUE,  12,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 4
        !byte TYPE_MOBLIN_BLUE,  10,  4,   TYPE_OCTO_RED   ,   3,  7,   TYPE_MOBLIN_RED ,  16,  7,   TYPE_OCTO_RED   ,   5,  2,   TYPE_MOBLIN_RED ,  15,  2,   TYPE_MOBLIN_RED ,   7,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 5
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  2,   TYPE_OCTO_RED   ,  16,  7,   TYPE_OCTO_BLUE  ,   5,  7,   TYPE_OCTO_RED   ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 6
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  7,   TYPE_OCTO_RED   ,  16,  7,   TYPE_OCTO_BLUE  ,   5,  2,   TYPE_ZORA       ,   8,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 7
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  7,   TYPE_OCTO_RED   ,  16,  7,   TYPE_OCTO_BLUE  ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 8
        !byte TYPE_OCTO_BLUE  ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  7,   TYPE_OCTO_BLUE  ,  16,  7,   TYPE_OCTO_BLUE  ,   5,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 9
        !byte TYPE_OCTO_BLUE  ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  7,   TYPE_OCTO_BLUE  ,  16,  7,   TYPE_OCTO_BLUE  ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 10
        !byte TYPE_MOBLIN_RED ,  10,  4,   TYPE_MOBLIN_RED ,   3,  3,   TYPE_MOBLIN_RED ,  16,  7,   TYPE_MOBLIN_RED ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 11
        !byte TYPE_MOBLIN_RED ,   4,  4,   TYPE_MOBLIN_RED ,  16,  2,   TYPE_MOBLIN_RED ,   3,  7,   TYPE_MOBLIN_RED ,  16,  5,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 12
        !byte TYPE_MOBLIN_BLUE,  10,  3,   TYPE_OCTO_RED   ,   3,  7,   TYPE_MOBLIN_RED ,  16,  7,   TYPE_OCTO_RED   ,  15,  2,   TYPE_MOBLIN_RED ,   3,  2,   TYPE_MOBLIN_RED ,   8,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 13
        !byte TYPE_OCTO_BLUE  ,  10,  4,   TYPE_OCTO_RED   ,   3,  7,   TYPE_OCTO_RED   ,   5,  2,   TYPE_OCTO_RED   ,   7,  7,   TYPE_OCTO_RED   ,  11,  7,   TYPE_ZORA       ,  12,  4,   TYPE_ZORA       ,  17,  7,   TYPE_NONE       ,   0,  0
        ; Formation 14
        !byte TYPE_PEAHAT     ,  10,  4,   TYPE_PEAHAT     ,   3,  3,   TYPE_PEAHAT     ,  16,  7,   TYPE_PEAHAT     ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 15
        !byte TYPE_MOBLIN_BLUE,  10,  4,   TYPE_MOBLIN_BLUE,   3,  7,   TYPE_MOBLIN_BLUE,  16,  7,   TYPE_MOBLIN_BLUE,   5,  2,   TYPE_MOBLIN_BLUE,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 16
        !byte TYPE_MOBLIN_BLUE,   7,  4,   TYPE_MOBLIN_BLUE,  16,  7,   TYPE_MOBLIN_RED ,  11,  7,   TYPE_MOBLIN_BLUE,   3,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 17
        !byte TYPE_MOBLIN_BLUE,  10,  4,   TYPE_MOBLIN_BLUE,   3,  7,   TYPE_MOBLIN_BLUE,  16,  7,   TYPE_MOBLIN_BLUE,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 18
        !byte TYPE_TEKTITE_RED,   9,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 19
        !byte TYPE_LEEVER_BLUE,  10,  4,   TYPE_PEAHAT     ,   3,  7,   TYPE_LEEVER_RED ,  16,  7,   TYPE_PEAHAT     ,   5,  2,   TYPE_LEEVER_BLUE,  15,  2,   TYPE_PEAHAT     ,  12,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 20
        !byte TYPE_TEKTITE_RED,  10,  4,   TYPE_TEKTITE_RED,   3,  7,   TYPE_TEKTITE_RED,  16,  7,   TYPE_TEKTITE_RED,   5,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 21
        !byte TYPE_TEKTITE_BLUE,  10,  3,   TYPE_TEKTITE_BLUE,   3,  7,   TYPE_TEKTITE_BLUE,  16,  6,   TYPE_TEKTITE_BLUE,   8,  7,   TYPE_TEKTITE_BLUE,  14,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 22
        !byte TYPE_TEKTITE_BLUE,  10,  4,   TYPE_TEKTITE_BLUE,   3,  4,   TYPE_TEKTITE_BLUE,  16,  4,   TYPE_TEKTITE_BLUE,   7,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 23
        !byte TYPE_LEEVER_RED ,  10,  4,   TYPE_LEEVER_RED ,   3,  4,   TYPE_LEEVER_RED ,  16,  2,   TYPE_LEEVER_RED ,   7,  3,   TYPE_LEEVER_RED ,  13,  3,   TYPE_LEEVER_RED ,   8,  6,   TYPE_ZORA       ,  10,  5,   TYPE_ZORA       ,  17,  7
        ; Formation 24
        !byte TYPE_LEEVER_RED ,  10,  4,   TYPE_LEEVER_RED ,   3,  2,   TYPE_LEEVER_RED ,  16,  2,   TYPE_LEEVER_RED ,   7,  2,   TYPE_LEEVER_RED ,  13,  3,   TYPE_LEEVER_RED ,   5,  4,   TYPE_ZORA       ,  10,  5,   TYPE_ZORA       ,   2,  7
        ; Formation 25
        !byte TYPE_OCTO_BLUE  ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  2,   TYPE_OCTO_BLUE  ,  16,  2,   TYPE_OCTO_BLUE  ,   7,  2,   TYPE_ZORA       ,  10,  5,   TYPE_ZORA       ,   2,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 26
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_OCTO_RED   ,   3,  3,   TYPE_OCTO_RED   ,  16,  3,   TYPE_OCTO_RED   ,   7,  3,   TYPE_ZORA       ,  10,  5,   TYPE_ZORA       ,   2,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 27
        !byte TYPE_OCTO_BLUE  ,  10,  3,   TYPE_ZORA       ,  10,  4,   TYPE_ZORA       ,   2,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
