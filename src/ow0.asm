; GENERE par tools/tilegen.py - Chunk Overworld 0 (Salles 0..31)
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
        !byte <room_00, <room_01, <room_02, <room_03, <room_04, <room_05, <room_06, <room_07, <room_08, <room_09, <room_10, <room_11, <room_12, <room_13, <room_14, <room_15
        !byte <room_16, <room_17, <room_18, <room_19, <room_20, <room_21, <room_22, <room_23, <room_24, <room_25, <room_26, <room_27, <room_28, <room_29, <room_30, <room_31
        !byte <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00
        !byte <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00
        !byte <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00
        !byte <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00
        !byte <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00
        !byte <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00, <room_00
room_tbl_hi:
        !byte >room_00, >room_01, >room_02, >room_03, >room_04, >room_05, >room_06, >room_07, >room_08, >room_09, >room_10, >room_11, >room_12, >room_13, >room_14, >room_15
        !byte >room_16, >room_17, >room_18, >room_19, >room_20, >room_21, >room_22, >room_23, >room_24, >room_25, >room_26, >room_27, >room_28, >room_29, >room_30, >room_31
        !byte >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00
        !byte >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00
        !byte >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00
        !byte >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00
        !byte >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00
        !byte >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00, >room_00

; Table des zones régionales par salle (128 octets : $C116..$C195)
room_zone_palette:
        !byte 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 3, 3, 0, 0, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 0, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3

; Index de formation d'ennemis par salle (128 octets : $C196..$C215)
room_enemy_idx:
        !byte 0, 1, 2, 3, 4, 5, 6, 7, 8, 0, 9, 10, 11, 12, 13, 14
        !byte 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 0, 26, 27, 28, 29
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

; Salle (0, 0) - RLE compact (22 octets)
room_00:
        !byte 229, 229, 229, 229, 229, 229, 229, 53, 160, 133, 0, 147, 133, 0, 229, 53
        !byte 0, 229, 53, 0, 149, 255
; Salle (1, 0) - RLE compact (29 octets)
room_01:
        !byte 229, 229, 229, 85, 64, 117, 0, 85, 64, 101, 16, 85, 80, 37, 224, 64
        !byte 35, 208, 35, 37, 3, 176, 3, 101, 176, 197, 0, 149, 255
; Salle (2, 0) - RLE compact (29 octets)
room_02:
        !byte 229, 229, 229, 229, 181, 16, 229, 37, 32, 69, 224, 64, 67, 0, 83, 112
        !byte 69, 0, 85, 112, 69, 0, 85, 3, 96, 69, 0, 213, 255
; Salle (3, 0) - RLE compact (33 octets)
room_03:
        !byte 229, 229, 197, 16, 229, 37, 32, 229, 21, 48, 21, 12, 149, 192, 101, 96
        !byte 67, 0, 101, 80, 3, 69, 0, 101, 64, 3, 85, 0, 229, 53, 0, 101
        !byte 255
; Salle (4, 0) - RLE compact (30 octets)
room_04:
        !byte 229, 229, 53, 7, 229, 37, 48, 229, 112, 165, 128, 53, 48, 21, 144, 37
        !byte 224, 16, 37, 224, 16, 37, 3, 48, 19, 96, 35, 229, 69, 255
; Salle (5, 0) - RLE compact (41 octets)
room_05:
        !byte 229, 229, 229, 160, 53, 80, 19, 48, 19, 32, 37, 64, 3, 12, 5, 3
        !byte 16, 3, 21, 3, 16, 37, 64, 53, 16, 53, 144, 53, 16, 53, 16, 35
        !byte 224, 16, 37, 67, 160, 3, 229, 117, 255
; Salle (6, 0) - RLE compact (25 octets)
room_06:
        !byte 229, 229, 229, 53, 16, 229, 80, 197, 96, 117, 224, 64, 67, 96, 115, 69
        !byte 3, 80, 213, 35, 16, 3, 229, 197, 255
; Salle (7, 0) - RLE compact (26 octets)
room_07:
        !byte 229, 229, 229, 229, 229, 213, 16, 133, 224, 64, 83, 0, 19, 16, 131, 85
        !byte 0, 21, 19, 229, 0, 229, 53, 0, 197, 255
; Salle (8, 0) - RLE compact (25 octets)
room_08:
        !byte 229, 229, 229, 53, 16, 229, 80, 197, 96, 117, 224, 64, 67, 96, 115, 69
        !byte 3, 80, 213, 35, 16, 3, 229, 197, 255
; Salle (9, 0) - RLE compact (42 octets)
room_09:
        !byte 229, 229, 229, 5, 128, 117, 64, 13, 96, 101, 48, 13, 128, 37, 80, 13
        !byte 0, 13, 0, 13, 0, 13, 0, 13, 16, 37, 35, 48, 13, 128, 85, 64
        !byte 13, 96, 3, 85, 35, 128, 3, 229, 133, 255
; Salle (10, 0) - RLE compact (40 octets)
room_10:
        !byte 229, 133, 7, 229, 53, 176, 101, 16, 132, 32, 85, 16, 132, 32, 85, 16
        !byte 132, 32, 85, 16, 132, 32, 85, 48, 9, 4, 9, 96, 85, 3, 48, 4
        !byte 96, 3, 165, 4, 85, 0, 53, 255
; Salle (11, 0) - RLE compact (43 octets)
room_11:
        !byte 229, 229, 229, 160, 117, 48, 35, 80, 85, 16, 13, 0, 13, 5, 7, 5
        !byte 13, 0, 13, 32, 85, 208, 85, 16, 13, 0, 13, 32, 13, 0, 13, 32
        !byte 85, 3, 192, 101, 3, 160, 3, 181, 0, 149, 255
; Salle (12, 0) - RLE compact (38 octets)
room_12:
        !byte 229, 229, 7, 229, 53, 48, 37, 32, 133, 64, 21, 48, 133, 160, 101, 192
        !byte 101, 0, 3, 160, 101, 0, 5, 64, 19, 48, 101, 0, 5, 3, 48, 21
        !byte 3, 32, 101, 0, 181, 255
; Salle (13, 0) - RLE compact (34 octets)
room_13:
        !byte 229, 229, 149, 48, 53, 48, 117, 64, 21, 80, 101, 208, 85, 224, 0, 53
        !byte 224, 16, 37, 64, 19, 144, 37, 48, 3, 21, 3, 112, 3, 229, 37, 0
        !byte 53, 255
; Salle (14, 0) - RLE compact (31 octets)
room_14:
        !byte 228, 228, 228, 228, 181, 116, 101, 7, 53, 116, 101, 0, 53, 116, 101, 0
        !byte 53, 116, 101, 0, 53, 116, 101, 0, 53, 116, 101, 0, 53, 116, 255
; Salle (15, 0) - RLE compact (54 octets)
room_15:
        !byte 36, 213, 84, 213, 84, 5, 176, 5, 84, 5, 16, 19, 0, 3, 7, 3
        !byte 0, 19, 0, 5, 84, 5, 16, 21, 0, 5, 7, 5, 0, 21, 0, 5
        !byte 84, 5, 176, 5, 84, 5, 176, 5, 84, 5, 176, 5, 84, 5, 176, 5
        !byte 84, 85, 48, 53, 36, 255
; Salle (0, 1) - RLE compact (46 octets)
room_16:
        !byte 133, 0, 229, 53, 0, 229, 224, 53, 16, 13, 80, 17, 16, 33, 37, 64
        !byte 13, 48, 19, 16, 35, 37, 32, 13, 32, 13, 128, 37, 64, 13, 64, 17
        !byte 48, 37, 3, 16, 13, 96, 19, 48, 53, 3, 224, 229, 69, 255
; Salle (1, 1) - RLE compact (47 octets)
room_17:
        !byte 133, 0, 229, 53, 12, 149, 224, 0, 53, 33, 16, 17, 96, 13, 16, 37
        !byte 35, 16, 19, 64, 13, 48, 37, 144, 13, 32, 13, 16, 37, 48, 17, 80
        !byte 13, 48, 37, 48, 19, 112, 13, 16, 37, 224, 0, 3, 229, 117, 255
; Salle (2, 1) - RLE compact (50 octets)
room_18:
        !byte 69, 0, 229, 53, 0, 229, 53, 0, 53, 144, 69, 0, 37, 16, 17, 0
        !byte 17, 0, 33, 69, 0, 21, 32, 19, 0, 19, 0, 35, 53, 224, 0, 37
        !byte 128, 17, 0, 17, 32, 37, 128, 19, 0, 19, 32, 37, 3, 224, 0, 229
        !byte 69, 255
; Salle (3, 1) - RLE compact (31 octets)
room_19:
        !byte 181, 0, 229, 53, 0, 101, 64, 101, 0, 53, 32, 33, 32, 85, 0, 37
        !byte 48, 35, 48, 69, 0, 21, 224, 224, 224, 224, 224, 144, 229, 69, 255
; Salle (4, 1) - RLE compact (35 octets)
room_20:
        !byte 229, 229, 149, 224, 0, 53, 224, 16, 37, 64, 13, 16, 13, 16, 13, 32
        !byte 13, 0, 37, 224, 144, 13, 16, 13, 16, 13, 32, 13, 224, 224, 208, 181
        !byte 0, 101, 255
; Salle (5, 1) - RLE compact (32 octets)
room_21:
        !byte 229, 229, 229, 69, 16, 21, 16, 213, 12, 128, 149, 192, 21, 16, 21, 224
        !byte 224, 224, 128, 19, 16, 19, 32, 19, 16, 51, 69, 0, 133, 0, 53, 255
; Salle (6, 1) - RLE compact (30 octets)
room_22:
        !byte 229, 229, 213, 16, 21, 16, 101, 192, 85, 208, 69, 224, 224, 112, 19, 224
        !byte 32, 21, 3, 48, 51, 16, 19, 64, 37, 3, 32, 229, 69, 255
; Salle (7, 1) - RLE compact (36 octets)
room_23:
        !byte 85, 0, 229, 53, 0, 197, 48, 21, 0, 197, 64, 5, 0, 197, 64, 5
        !byte 0, 5, 180, 112, 4, 224, 48, 4, 224, 48, 4, 224, 48, 4, 160, 117
        !byte 4, 48, 101, 255
; Salle (8, 1) - RLE compact (17 octets)
room_24:
        !byte 229, 229, 229, 229, 229, 69, 228, 68, 224, 224, 224, 64, 147, 144, 229, 229
        !byte 255
; Salle (9, 1) - RLE compact (17 octets)
room_25:
        !byte 229, 229, 229, 229, 229, 69, 228, 68, 224, 224, 144, 227, 67, 229, 229, 149
        !byte 255
; Salle (10, 1) - RLE compact (31 octets)
room_26:
        !byte 117, 4, 85, 0, 181, 4, 85, 0, 181, 4, 85, 0, 181, 4, 85, 0
        !byte 53, 116, 101, 0, 53, 224, 224, 96, 179, 112, 181, 112, 229, 117, 255
; Salle (11, 1) - RLE compact (46 octets)
room_27:
        !byte 133, 0, 229, 53, 0, 229, 144, 133, 32, 13, 112, 117, 0, 13, 48, 13
        !byte 0, 13, 32, 53, 96, 13, 80, 13, 64, 51, 0, 13, 48, 13, 0, 13
        !byte 32, 51, 53, 32, 13, 112, 117, 3, 144, 3, 197, 0, 149, 255
; Salle (12, 1) - RLE compact (44 octets)
room_28:
        !byte 101, 0, 229, 53, 0, 229, 5, 224, 0, 37, 224, 16, 37, 80, 13, 0
        !byte 13, 0, 13, 0, 13, 224, 128, 35, 80, 13, 0, 13, 0, 13, 0, 13
        !byte 48, 37, 224, 16, 37, 3, 224, 0, 69, 0, 213, 255
; Salle (13, 1) - RLE compact (41 octets)
room_29:
        !byte 229, 0, 229, 53, 0, 53, 80, 133, 0, 53, 96, 117, 0, 53, 96, 69
        !byte 192, 13, 0, 21, 224, 32, 5, 32, 132, 96, 5, 32, 132, 80, 3, 5
        !byte 3, 16, 132, 53, 0, 53, 16, 132, 255
; Salle (14, 1) - RLE compact (30 octets)
room_30:
        !byte 101, 0, 229, 53, 0, 229, 53, 0, 53, 112, 101, 0, 37, 224, 32, 21
        !byte 224, 208, 132, 19, 128, 132, 21, 128, 132, 21, 128, 132, 165, 255
; Salle (15, 1) - RLE compact (62 octets)
room_31:
        !byte 133, 59, 53, 36, 133, 59, 53, 36, 224, 0, 5, 36, 48, 21, 0, 37
        !byte 16, 21, 16, 5, 36, 48, 19, 0, 3, 7, 3, 16, 19, 16, 5, 36
        !byte 224, 0, 5, 36, 80, 21, 16, 21, 0, 21, 0, 5, 36, 80, 19, 16
        !byte 19, 0, 19, 0, 5, 36, 224, 0, 5, 36, 229, 21, 36, 255

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
; Chars 200..207 (Tuiles 13..14 : 64 octets dont rocher escargot)
        !byte 5, 26, 110, 109, 121, 122, 94, 87   ; char 200
        !byte 80, 92, 151, 231, 119, 119, 87, 87   ; char 201
        !byte 85, 94, 94, 85, 85, 21, 53, 15   ; char 202
        !byte 87, 151, 87, 87, 87, 92, 92, 252   ; char 203
        !byte 0, 0, 0, 0, 0, 0, 0, 0   ; char 204
        !byte 0, 0, 0, 0, 0, 0, 0, 0   ; char 205
        !byte 0, 0, 0, 0, 0, 0, 0, 0   ; char 206
        !byte 0, 0, 0, 0, 0, 0, 0, 0   ; char 207

; Formations d'ennemis dédupliquées (30 formations x 24 octets)
map_enemies:
        ; Formation 0
        !byte TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 1
        !byte TYPE_LYNEL_RED  ,  10,  4,   TYPE_LYNEL_RED  ,   3,  7,   TYPE_LYNEL_RED  ,  16,  7,   TYPE_LYNEL_RED  ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 2
        !byte TYPE_LYNEL_RED  ,  10,  4,   TYPE_LYNEL_RED  ,   3,  4,   TYPE_LYNEL_RED  ,  16,  7,   TYPE_LYNEL_RED  ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 3
        !byte TYPE_TEKTITE_RED,  10,  4,   TYPE_TEKTITE_RED,   3,  7,   TYPE_TEKTITE_RED,   4,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 4
        !byte TYPE_LYNEL_BLUE ,  10,  4,   TYPE_LYNEL_BLUE ,   3,  7,   TYPE_LYNEL_BLUE ,  16,  7,   TYPE_LYNEL_BLUE ,  15,  2,   TYPE_LYNEL_BLUE ,   6,  4,   TYPE_LYNEL_BLUE ,  12,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 5
        !byte TYPE_LYNEL_BLUE ,  10,  4,   TYPE_LEEVER_BLUE,   3,  2,   TYPE_LYNEL_RED  ,  16,  7,   TYPE_LYNEL_BLUE ,   5,  7,   TYPE_LEEVER_RED ,  16,  2,   TYPE_LYNEL_RED  ,  12,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 6
        !byte TYPE_PEAHAT     ,  10,  4,   TYPE_PEAHAT     ,   3,  4,   TYPE_LYNEL_RED  ,  16,  4,   TYPE_LYNEL_BLUE ,   7,  2,   TYPE_LYNEL_RED  ,   7,  6,   TYPE_LYNEL_BLUE ,  11,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 7
        !byte TYPE_LYNEL_RED  ,  10,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 8
        !byte TYPE_TEKTITE_RED,  10,  4,   TYPE_TEKTITE_RED,   3,  4,   TYPE_TEKTITE_RED,  16,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 9
        !byte TYPE_LYNEL_BLUE ,  10,  6,   TYPE_ZORA       ,  10,  4,   TYPE_ZORA       ,   4,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 10
        !byte TYPE_LEEVER_RED ,  10,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 11
        !byte TYPE_TEKTITE_RED,  10,  4,   TYPE_TEKTITE_RED,  16,  3,   TYPE_TEKTITE_RED,  14,  7,   TYPE_TEKTITE_RED,   6,  4,   TYPE_TEKTITE_RED,  13,  2,   TYPE_TEKTITE_RED,  10,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 12
        !byte TYPE_TEKTITE_RED,  10,  4,   TYPE_TEKTITE_RED,   3,  2,   TYPE_TEKTITE_RED,  16,  7,   TYPE_TEKTITE_RED,   6,  6,   TYPE_TEKTITE_RED,  14,  3,   TYPE_TEKTITE_RED,   7,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 13
        !byte TYPE_ZORA       ,  13,  4,   TYPE_ZORA       ,  17,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 14
        !byte TYPE_ZORA       ,  19,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 15
        !byte TYPE_LYNEL_BLUE ,  10,  3,   TYPE_LYNEL_BLUE ,   3,  6,   TYPE_LYNEL_BLUE ,  16,  7,   TYPE_LYNEL_BLUE ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 16
        !byte TYPE_PEAHAT     ,  10,  3,   TYPE_PEAHAT     ,   3,  7,   TYPE_LYNEL_RED  ,  16,  7,   TYPE_LYNEL_BLUE ,   5,  2,   TYPE_LYNEL_RED  ,  15,  2,   TYPE_LYNEL_BLUE ,   8,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 17
        !byte TYPE_LYNEL_BLUE ,  10,  4,   TYPE_LYNEL_BLUE ,   3,  7,   TYPE_LYNEL_BLUE ,  16,  7,   TYPE_LYNEL_BLUE ,  15,  2,   TYPE_LYNEL_BLUE ,   6,  4,   TYPE_LYNEL_BLUE ,   8,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 18
        !byte TYPE_LYNEL_BLUE ,  10,  4,   TYPE_LYNEL_RED  ,   3,  7,   TYPE_LYNEL_BLUE ,  16,  7,   TYPE_LYNEL_RED  ,   4,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 19
        !byte TYPE_LYNEL_RED  ,  10,  4,   TYPE_LYNEL_RED  ,   3,  7,   TYPE_LYNEL_RED  ,  16,  7,   TYPE_LYNEL_RED  ,   5,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 20
        !byte TYPE_PEAHAT     ,  10,  4,   TYPE_PEAHAT     ,   3,  6,   TYPE_LYNEL_RED  ,  16,  7,   TYPE_LYNEL_BLUE ,  15,  2,   TYPE_LYNEL_RED  ,   7,  6,   TYPE_LYNEL_BLUE ,  12,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 21
        !byte TYPE_TEKTITE_RED,  10,  4,   TYPE_TEKTITE_RED,   3,  7,   TYPE_TEKTITE_RED,  16,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 22
        !byte TYPE_TEKTITE_RED,  10,  4,   TYPE_TEKTITE_RED,   3,  7,   TYPE_TEKTITE_RED,  16,  7,   TYPE_ZORA       ,  10,  3,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 23
        !byte TYPE_TEKTITE_RED,  10,  4,   TYPE_TEKTITE_RED,   3,  7,   TYPE_TEKTITE_RED,  16,  5,   TYPE_ZORA       ,  10,  3,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 24
        !byte TYPE_TEKTITE_RED,  10,  4,   TYPE_TEKTITE_RED,   3,  5,   TYPE_TEKTITE_RED,  16,  5,   TYPE_ZORA       ,  10,  3,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 25
        !byte TYPE_TEKTITE_RED,  10,  4,   TYPE_TEKTITE_RED,   3,  5,   TYPE_TEKTITE_RED,  16,  7,   TYPE_TEKTITE_RED,  12,  7,   TYPE_TEKTITE_RED,  14,  4,   TYPE_TEKTITE_RED,   7,  5,   TYPE_ZORA       ,   8,  2,   TYPE_NONE       ,   0,  0
        ; Formation 26
        !byte TYPE_ARMOS      ,   3,  3,   TYPE_ARMOS      ,   7,  3,   TYPE_ARMOS      ,  11,  3,   TYPE_ARMOS      ,  15,  3,   TYPE_ARMOS      ,   3,  5,   TYPE_ARMOS      ,   7,  5,   TYPE_ARMOS      ,  11,  5,   TYPE_ARMOS      ,  15,  5
        ; Formation 27
        !byte TYPE_PEAHAT     ,  10,  4,   TYPE_PEAHAT     ,   3,  7,   TYPE_PEAHAT     ,  16,  3,   TYPE_PEAHAT     ,   5,  2,   TYPE_PEAHAT     ,   9,  7,   TYPE_PEAHAT     ,  13,  4,   TYPE_ZORA       ,  12,  5,   TYPE_ZORA       ,  17,  7
        ; Formation 28
        !byte TYPE_TEKTITE_RED,  10,  4,   TYPE_TEKTITE_RED,   3,  3,   TYPE_TEKTITE_RED,  16,  7,   TYPE_TEKTITE_RED,  15,  2,   TYPE_TEKTITE_RED,  12,  7,   TYPE_TEKTITE_RED,   7,  3,   TYPE_ZORA       ,   8,  5,   TYPE_ZORA       ,   2,  7
        ; Formation 29
        !byte TYPE_PEAHAT     ,  10,  4,   TYPE_PEAHAT     ,   3,  7,   TYPE_PEAHAT     ,  16,  7,   TYPE_PEAHAT     ,   5,  2,   TYPE_PEAHAT     ,  16,  2,   TYPE_PEAHAT     ,   7,  7,   TYPE_ZORA       ,  19,  4,   TYPE_NONE       ,   0,  0
