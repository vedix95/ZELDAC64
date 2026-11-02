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
        !byte 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 3, 3, 0, 0, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3

; Index de formation d'ennemis par salle (128 octets : $C196..$C215)
room_enemy_idx:
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 1, 2, 3, 4, 5, 6, 7, 8, 9, 8, 10, 11, 12, 13, 14, 15
        !byte 16, 17, 18, 19, 20, 21, 22, 0, 23, 24, 25, 26, 27, 28, 29, 30

; Salle (0, 6) - RLE compact (24 octets)
room_96:
        !byte 51, 176, 115, 176, 115, 176, 115, 192, 99, 224, 0, 51, 224, 0, 51, 224
        !byte 0, 51, 192, 99, 176, 227, 131, 255
; Salle (1, 6) - RLE compact (26 octets)
room_97:
        !byte 179, 16, 227, 35, 16, 227, 35, 16, 227, 35, 16, 83, 224, 224, 224, 224
        !byte 179, 16, 227, 35, 16, 227, 35, 16, 83, 255
; Salle (2, 6) - RLE compact (36 octets)
room_98:
        !byte 99, 16, 19, 64, 163, 16, 19, 64, 163, 32, 3, 64, 163, 32, 3, 224
        !byte 48, 3, 224, 48, 3, 224, 48, 3, 128, 115, 16, 83, 48, 115, 16, 227
        !byte 35, 16, 147, 255
; Salle (3, 6) - RLE compact (52 octets)
room_99:
        !byte 83, 16, 3, 32, 3, 0, 3, 0, 147, 16, 3, 32, 3, 0, 3, 0
        !byte 115, 176, 51, 64, 3, 80, 3, 48, 35, 112, 3, 224, 0, 3, 80, 3
        !byte 0, 3, 192, 3, 224, 0, 3, 80, 3, 48, 99, 176, 195, 32, 3, 0
        !byte 3, 0, 51, 255
; Salle (4, 6) - RLE compact (33 octets)
room_100:
        !byte 69, 16, 53, 16, 21, 0, 133, 16, 21, 7, 5, 16, 21, 0, 133, 224
        !byte 53, 224, 128, 3, 224, 224, 128, 3, 160, 53, 224, 0, 69, 224, 229, 69
        !byte 255
; Salle (5, 6) - RLE compact (48 octets)
room_101:
        !byte 53, 32, 20, 32, 5, 0, 5, 0, 117, 32, 20, 32, 5, 0, 5, 0
        !byte 53, 96, 20, 224, 32, 20, 32, 13, 208, 20, 64, 13, 176, 25, 32, 13
        !byte 208, 20, 64, 13, 176, 20, 32, 13, 208, 20, 160, 85, 0, 20, 165, 255
; Salle (6, 6) - RLE compact (29 octets)
room_102:
        !byte 229, 213, 7, 149, 224, 0, 53, 64, 61, 112, 37, 144, 45, 176, 61, 224
        !byte 80, 45, 176, 61, 112, 37, 224, 0, 229, 37, 16, 53, 255
; Salle (7, 6) - RLE compact (40 octets)
room_103:
        !byte 229, 229, 213, 96, 21, 32, 101, 16, 13, 0, 13, 80, 13, 16, 37, 224
        !byte 144, 13, 0, 13, 80, 13, 224, 144, 37, 16, 13, 0, 13, 80, 13, 16
        !byte 101, 96, 21, 32, 197, 16, 133, 255
; Salle (8, 6) - RLE compact (83 octets)
room_104:
        !byte 53, 3, 0, 3, 0, 3, 16, 3, 0, 3, 0, 3, 0, 35, 53, 3
        !byte 0, 3, 0, 3, 16, 3, 0, 3, 0, 3, 0, 35, 53, 192, 35, 37
        !byte 32, 3, 48, 3, 32, 3, 0, 35, 48, 3, 224, 80, 3, 0, 3, 16
        !byte 3, 0, 3, 0, 3, 112, 3, 224, 37, 32, 3, 48, 3, 32, 3, 0
        !byte 35, 53, 192, 35, 53, 3, 0, 3, 0, 3, 16, 3, 0, 3, 0, 3
        !byte 0, 35, 255
; Salle (9, 6) - RLE compact (34 octets)
room_105:
        !byte 131, 16, 132, 131, 16, 132, 51, 96, 132, 35, 48, 3, 32, 132, 48, 3
        !byte 80, 132, 96, 3, 224, 0, 3, 224, 35, 48, 3, 176, 51, 224, 0, 227
        !byte 67, 255
; Salle (10, 6) - RLE compact (27 octets)
room_106:
        !byte 132, 48, 35, 0, 35, 132, 48, 35, 0, 35, 132, 160, 132, 160, 132, 64
        !byte 3, 224, 224, 128, 3, 224, 224, 224, 227, 67, 255
; Salle (11, 6) - RLE compact (55 octets)
room_107:
        !byte 35, 0, 3, 32, 3, 0, 3, 0, 19, 0, 115, 0, 3, 32, 3, 0
        !byte 3, 0, 19, 0, 67, 224, 0, 51, 176, 3, 48, 35, 48, 3, 32, 3
        !byte 0, 3, 224, 80, 3, 160, 3, 32, 3, 0, 3, 224, 80, 3, 48, 35
        !byte 224, 0, 227, 19, 32, 51, 255
; Salle (12, 6) - RLE compact (35 octets)
room_108:
        !byte 83, 0, 99, 0, 163, 0, 99, 0, 163, 0, 19, 160, 83, 0, 3, 96
        !byte 67, 96, 3, 96, 67, 96, 3, 96, 67, 96, 3, 96, 195, 96, 211, 160
        !byte 227, 67, 255
; Salle (13, 6) - RLE compact (36 octets)
room_109:
        !byte 67, 0, 115, 0, 147, 0, 115, 0, 67, 176, 3, 16, 131, 16, 115, 0
        !byte 131, 16, 115, 80, 51, 16, 115, 80, 51, 16, 115, 80, 51, 16, 211, 80
        !byte 227, 227, 51, 255
; Salle (14, 6) - RLE compact (29 octets)
room_110:
        !byte 227, 227, 211, 224, 0, 35, 16, 35, 224, 128, 51, 128, 35, 0, 19, 224
        !byte 80, 51, 48, 35, 16, 35, 176, 51, 224, 0, 227, 67, 255
; Salle (15, 6) - RLE compact (26 octets)
room_111:
        !byte 101, 48, 132, 69, 7, 5, 48, 132, 160, 132, 160, 132, 160, 132, 160, 132
        !byte 160, 132, 160, 132, 160, 132, 101, 48, 132, 255
; Salle (0, 7) - RLE compact (38 octets)
room_112:
        !byte 229, 229, 37, 7, 181, 208, 69, 16, 18, 0, 18, 112, 53, 32, 18, 0
        !byte 18, 112, 37, 224, 16, 53, 48, 18, 0, 18, 96, 69, 32, 18, 0, 18
        !byte 96, 85, 208, 229, 69, 255
; Salle (1, 7) - RLE compact (22 octets)
room_113:
        !byte 181, 16, 229, 37, 16, 85, 224, 69, 224, 0, 53, 224, 224, 224, 224, 224
        !byte 0, 53, 224, 229, 149, 255
; Salle (2, 7) - RLE compact (26 octets)
room_114:
        !byte 115, 16, 227, 35, 16, 227, 35, 176, 227, 67, 48, 227, 3, 112, 179, 112
        !byte 227, 3, 48, 227, 3, 224, 0, 227, 67, 255
; Salle (3, 7) - RLE compact (33 octets)
room_115:
        !byte 131, 32, 3, 0, 3, 0, 195, 32, 3, 0, 3, 0, 51, 224, 0, 195
        !byte 112, 179, 160, 131, 32, 3, 96, 131, 160, 131, 112, 35, 224, 0, 227, 131
        !byte 255
; Salle (4, 7) - RLE compact (40 octets)
room_116:
        !byte 229, 229, 213, 176, 101, 80, 47, 64, 37, 80, 14, 0, 14, 15, 7, 15
        !byte 14, 0, 14, 16, 37, 224, 16, 37, 80, 14, 0, 14, 32, 14, 0, 14
        !byte 16, 85, 208, 101, 176, 229, 133, 255
; Salle (5, 7) - RLE compact (58 octets)
room_117:
        !byte 85, 0, 20, 229, 7, 5, 0, 20, 229, 32, 20, 160, 37, 48, 20, 0
        !byte 13, 32, 13, 64, 37, 48, 20, 32, 13, 96, 37, 16, 13, 0, 20, 0
        !byte 13, 32, 13, 64, 37, 48, 20, 32, 13, 96, 37, 48, 20, 0, 13, 32
        !byte 13, 64, 53, 32, 20, 160, 101, 20, 165, 255
; Salle (6, 7) - RLE compact (37 octets)
room_118:
        !byte 213, 16, 229, 37, 16, 53, 224, 0, 53, 144, 13, 64, 53, 176, 13, 48
        !byte 37, 48, 13, 16, 13, 16, 13, 224, 80, 13, 48, 37, 144, 13, 64, 53
        !byte 224, 0, 229, 133, 255
; Salle (7, 7) - RLE compact (24 octets)
room_119:
        !byte 133, 16, 229, 7, 21, 16, 229, 64, 213, 80, 197, 96, 133, 224, 64, 53
        !byte 176, 117, 176, 117, 176, 229, 133, 255
; Salle (8, 7) - RLE compact (79 octets)
room_120:
        !byte 53, 3, 0, 3, 0, 3, 16, 3, 0, 3, 0, 3, 0, 35, 53, 3
        !byte 0, 3, 0, 3, 16, 3, 0, 3, 0, 3, 0, 35, 53, 224, 0, 53
        !byte 48, 3, 16, 3, 0, 3, 0, 3, 48, 37, 0, 3, 0, 3, 224, 80
        !byte 3, 16, 3, 0, 3, 0, 3, 48, 37, 0, 3, 0, 3, 192, 53, 48
        !byte 3, 16, 3, 0, 3, 0, 3, 48, 53, 224, 0, 53, 227, 3, 255
; Salle (9, 7) - RLE compact (36 octets)
room_121:
        !byte 229, 229, 149, 32, 69, 80, 85, 48, 53, 96, 69, 64, 37, 32, 13, 32
        !byte 69, 80, 21, 16, 13, 0, 13, 224, 32, 13, 32, 69, 224, 69, 80, 21
        !byte 80, 229, 165, 255
; Salle (10, 7) - RLE compact (22 octets)
room_122:
        !byte 229, 229, 229, 53, 16, 229, 80, 197, 96, 117, 224, 64, 69, 96, 213, 80
        !byte 229, 21, 16, 229, 213, 255
; Salle (11, 7) - RLE compact (24 octets)
room_123:
        !byte 197, 32, 229, 21, 32, 197, 160, 117, 176, 101, 224, 224, 32, 101, 16, 164
        !byte 117, 0, 164, 133, 164, 133, 164, 255
; Salle (12, 7) - RLE compact (16 octets)
room_124:
        !byte 229, 229, 149, 224, 224, 224, 224, 224, 64, 228, 228, 228, 228, 228, 68, 255
; Salle (13, 7) - RLE compact (16 octets)
room_125:
        !byte 229, 229, 149, 224, 224, 224, 224, 224, 64, 228, 228, 228, 228, 228, 68, 255
; Salle (14, 7) - RLE compact (19 octets)
room_126:
        !byte 229, 229, 149, 48, 229, 5, 48, 229, 5, 224, 224, 144, 228, 228, 228, 228
        !byte 228, 68, 255
; Salle (15, 7) - RLE compact (22 octets)
room_127:
        !byte 101, 48, 132, 101, 48, 132, 101, 48, 132, 101, 48, 132, 160, 132, 144, 228
        !byte 228, 228, 228, 228, 228, 255

; 512 octets de caracteres Overworld
overworld_charset:
; Chars 0..31 (Tuiles 0..7 : 256 octets)
        !byte 0, 0, 0, 0, 0, 0, 0, 0   ; char 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0   ; char 1
        !byte 0, 0, 0, 0, 0, 0, 0, 0   ; char 2
        !byte 0, 0, 0, 0, 0, 0, 0, 0   ; char 3
        !byte 167, 167, 167, 87, 171, 191, 191, 87   ; char 4
        !byte 167, 167, 167, 87, 171, 191, 191, 87   ; char 5
        !byte 167, 167, 167, 87, 171, 191, 191, 87   ; char 6
        !byte 167, 167, 167, 87, 171, 191, 191, 87   ; char 7
        !byte 0, 2, 75, 111, 110, 249, 253, 255   ; char 8
        !byte 0, 130, 210, 246, 182, 95, 127, 255   ; char 9
        !byte 254, 245, 249, 192, 247, 55, 21, 85   ; char 10
        !byte 191, 95, 111, 3, 223, 220, 84, 85   ; char 11
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
; Chars 168..199 (Tuiles 8..12 : 256 octets)
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
; Chars 200..211 (Tuiles 13..15 : 96 octets dont rocher, statue, monument)
        !byte 5, 26, 110, 109, 121, 122, 94, 87   ; char 200
        !byte 80, 92, 151, 231, 119, 119, 87, 87   ; char 201
        !byte 85, 94, 94, 85, 85, 21, 53, 15   ; char 202
        !byte 87, 151, 87, 87, 87, 92, 92, 252   ; char 203
        !byte 51, 29, 13, 14, 253, 245, 253, 253   ; char 204
        !byte 240, 208, 176, 176, 240, 84, 253, 253   ; char 205
        !byte 253, 253, 253, 253, 245, 253, 21, 85   ; char 206
        !byte 253, 189, 165, 181, 213, 60, 125, 85   ; char 207
        !byte 20, 84, 93, 221, 253, 255, 247, 247   ; char 208
        !byte 21, 85, 85, 85, 87, 95, 127, 255   ; char 209
        !byte 247, 251, 251, 247, 255, 245, 213, 213   ; char 210
        !byte 215, 215, 215, 255, 255, 127, 95, 87   ; char 211

; Formations d'ennemis dédupliquées (31 formations x 24 octets)
map_enemies:
        ; Formation 0
        !byte TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 1
        !byte TYPE_PEAHAT     ,  10,  4,   TYPE_PEAHAT     ,   4,  6,   TYPE_LYNEL_RED  ,  16,  7,   TYPE_LYNEL_BLUE ,   5,  2,   TYPE_LYNEL_RED  ,  15,  2,   TYPE_LYNEL_BLUE ,   7,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 2
        !byte TYPE_MOBLIN_BLUE,  10,  4,   TYPE_MOBLIN_BLUE,   2,  4,   TYPE_MOBLIN_BLUE,  15,  4,   TYPE_MOBLIN_BLUE,  13,  6,   TYPE_MOBLIN_BLUE,   6,  5,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 3
        !byte TYPE_MOBLIN_BLUE,   9,  4,   TYPE_MOBLIN_BLUE,  15,  1,   TYPE_MOBLIN_BLUE,   2,  4,   TYPE_MOBLIN_BLUE,  13,  5,   TYPE_MOBLIN_BLUE,  12,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 4
        !byte TYPE_MOBLIN_BLUE,  10,  4,   TYPE_OCTO_RED   ,   3,  7,   TYPE_MOBLIN_RED ,  16,  7,   TYPE_OCTO_RED   ,   5,  2,   TYPE_MOBLIN_RED ,  15,  2,   TYPE_MOBLIN_RED ,   7,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 5
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_OCTO_BLUE  ,   4,  3,   TYPE_OCTO_RED   ,  16,  7,   TYPE_OCTO_BLUE  ,   5,  7,   TYPE_OCTO_RED   ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 6
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  7,   TYPE_OCTO_RED   ,  16,  7,   TYPE_OCTO_BLUE  ,   5,  2,   TYPE_ZORA       ,   8,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 7
        !byte TYPE_OCTO_RED   ,   9,  3,   TYPE_OCTO_BLUE  ,   3,  7,   TYPE_OCTO_RED   ,  16,  7,   TYPE_OCTO_BLUE  ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 8
        !byte TYPE_OCTO_BLUE  ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  7,   TYPE_OCTO_BLUE  ,  16,  7,   TYPE_OCTO_BLUE  ,   5,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 9
        !byte TYPE_OCTO_BLUE  ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  7,   TYPE_OCTO_BLUE  ,  16,  7,   TYPE_OCTO_BLUE  ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 10
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  7,   TYPE_OCTO_RED   ,  16,  7,   TYPE_OCTO_BLUE  ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 11
        !byte TYPE_MOBLIN_BLUE,   9,  3,   TYPE_OCTO_RED   ,   3,  7,   TYPE_MOBLIN_RED ,  16,  7,   TYPE_OCTO_RED   ,   5,  2,   TYPE_MOBLIN_RED ,  15,  2,   TYPE_MOBLIN_RED ,   7,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 12
        !byte TYPE_MOBLIN_RED ,  10,  4,   TYPE_MOBLIN_RED ,   2,  4,   TYPE_MOBLIN_RED ,  15,  8,   TYPE_MOBLIN_RED ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 13
        !byte TYPE_MOBLIN_RED ,   4,  4,   TYPE_MOBLIN_RED ,  14,  1,   TYPE_MOBLIN_RED ,   4,  6,   TYPE_MOBLIN_RED ,  16,  5,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 14
        !byte TYPE_MOBLIN_BLUE,  10,  3,   TYPE_OCTO_RED   ,   3,  7,   TYPE_MOBLIN_RED ,  16,  7,   TYPE_OCTO_RED   ,  15,  2,   TYPE_MOBLIN_RED ,   4,  2,   TYPE_MOBLIN_RED ,   8,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 15
        !byte TYPE_OCTO_BLUE  ,  10,  4,   TYPE_OCTO_RED   ,   3,  7,   TYPE_OCTO_RED   ,   5,  2,   TYPE_OCTO_RED   ,   7,  7,   TYPE_OCTO_RED   ,  10,  6,   TYPE_ZORA       ,  12,  4,   TYPE_ZORA       ,  17,  7,   TYPE_NONE       ,   0,  0
        ; Formation 16
        !byte TYPE_PEAHAT     ,   9,  3,   TYPE_PEAHAT     ,   4,  4,   TYPE_PEAHAT     ,  16,  7,   TYPE_PEAHAT     ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 17
        !byte TYPE_MOBLIN_BLUE,  10,  4,   TYPE_MOBLIN_BLUE,   3,  7,   TYPE_MOBLIN_BLUE,  15,  6,   TYPE_MOBLIN_BLUE,   5,  2,   TYPE_MOBLIN_BLUE,  14,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 18
        !byte TYPE_MOBLIN_BLUE,   6,  5,   TYPE_MOBLIN_BLUE,  15,  8,   TYPE_MOBLIN_RED ,  10,  8,   TYPE_MOBLIN_BLUE,   2,  6,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 19
        !byte TYPE_MOBLIN_BLUE,  10,  4,   TYPE_MOBLIN_BLUE,   2,  8,   TYPE_MOBLIN_BLUE,  16,  7,   TYPE_MOBLIN_BLUE,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 20
        !byte TYPE_TEKTITE_RED,   8,  3,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 21
        !byte TYPE_LEEVER_BLUE,  10,  4,   TYPE_PEAHAT     ,   3,  7,   TYPE_LEEVER_RED ,  16,  7,   TYPE_PEAHAT     ,   5,  2,   TYPE_LEEVER_BLUE,  15,  2,   TYPE_PEAHAT     ,  12,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 22
        !byte TYPE_TEKTITE_RED,  10,  4,   TYPE_TEKTITE_RED,   3,  7,   TYPE_TEKTITE_RED,  15,  6,   TYPE_TEKTITE_RED,   5,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 23
        !byte TYPE_OCTO_BLUE  ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  6,   TYPE_OCTO_BLUE  ,  16,  7,   TYPE_OCTO_BLUE  ,   5,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 24
        !byte TYPE_TEKTITE_BLUE,  10,  3,   TYPE_TEKTITE_BLUE,   3,  7,   TYPE_TEKTITE_BLUE,  15,  5,   TYPE_TEKTITE_BLUE,   8,  7,   TYPE_TEKTITE_BLUE,  13,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 25
        !byte TYPE_TEKTITE_BLUE,  10,  4,   TYPE_TEKTITE_BLUE,   2,  5,   TYPE_TEKTITE_BLUE,  15,  5,   TYPE_TEKTITE_BLUE,   6,  3,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 26
        !byte TYPE_LEEVER_RED ,  10,  4,   TYPE_LEEVER_RED ,   2,  5,   TYPE_LEEVER_RED ,  16,  2,   TYPE_LEEVER_RED ,   8,  3,   TYPE_LEEVER_RED ,  13,  3,   TYPE_LEEVER_RED ,   8,  6,   TYPE_ZORA       ,   9,  6,   TYPE_ZORA       ,  17,  7
        ; Formation 27
        !byte TYPE_LEEVER_RED ,  10,  4,   TYPE_LEEVER_RED ,   3,  2,   TYPE_LEEVER_RED ,  16,  2,   TYPE_LEEVER_RED ,   7,  2,   TYPE_LEEVER_RED ,  13,  3,   TYPE_LEEVER_RED ,   5,  4,   TYPE_ZORA       ,   9,  6,   TYPE_ZORA       ,   2,  7
        ; Formation 28
        !byte TYPE_OCTO_BLUE  ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  2,   TYPE_OCTO_BLUE  ,  16,  2,   TYPE_OCTO_BLUE  ,   7,  2,   TYPE_ZORA       ,   9,  6,   TYPE_ZORA       ,   2,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 29
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_OCTO_RED   ,   3,  3,   TYPE_OCTO_RED   ,  15,  4,   TYPE_OCTO_RED   ,   6,  4,   TYPE_ZORA       ,   9,  6,   TYPE_ZORA       ,   2,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 30
        !byte TYPE_OCTO_BLUE  ,  10,  3,   TYPE_ZORA       ,  11,  3,   TYPE_ZORA       ,   2,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
