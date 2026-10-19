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
        !byte 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 0, 0, 26, 27, 28
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

; Salle (0, 0) - RLE compact (23 octets)
room_00:
        !byte 229, 229, 229, 229, 229, 213, 160, 133, 0, 147, 133, 0, 229, 53, 0, 229
        !byte 53, 0, 229, 53, 0, 149, 255
; Salle (1, 0) - RLE compact (33 octets)
room_01:
        !byte 229, 229, 181, 16, 117, 80, 37, 32, 117, 96, 5, 224, 64, 3, 224, 32
        !byte 3, 5, 3, 224, 0, 3, 37, 224, 0, 53, 99, 0, 115, 165, 0, 149
        !byte 255
; Salle (2, 0) - RLE compact (32 octets)
room_02:
        !byte 229, 229, 229, 117, 32, 229, 21, 48, 37, 224, 64, 51, 0, 115, 96, 53
        !byte 0, 117, 96, 53, 0, 117, 3, 80, 53, 0, 133, 83, 53, 0, 229, 255
; Salle (3, 0) - RLE compact (32 octets)
room_03:
        !byte 229, 229, 165, 48, 229, 5, 64, 213, 208, 85, 80, 99, 0, 85, 64, 3
        !byte 101, 0, 85, 48, 3, 117, 0, 85, 51, 133, 0, 229, 53, 0, 85, 255
; Salle (4, 0) - RLE compact (32 octets)
room_04:
        !byte 229, 229, 85, 7, 229, 5, 96, 181, 112, 21, 80, 21, 144, 5, 224, 48
        !byte 5, 224, 48, 5, 3, 80, 19, 128, 3, 21, 83, 21, 131, 229, 85, 255
; Salle (5, 0) - RLE compact (42 octets)
room_05:
        !byte 229, 229, 149, 64, 35, 64, 35, 32, 5, 48, 3, 5, 12, 5, 3, 32
        !byte 3, 37, 3, 16, 5, 48, 69, 32, 69, 96, 69, 32, 69, 16, 3, 224
        !byte 48, 5, 51, 208, 3, 69, 211, 229, 101, 255
; Salle (6, 0) - RLE compact (25 octets)
room_06:
        !byte 229, 229, 229, 112, 165, 128, 101, 224, 64, 51, 128, 99, 53, 3, 112, 181
        !byte 51, 32, 3, 229, 5, 35, 229, 197, 255
; Salle (7, 0) - RLE compact (28 octets)
room_07:
        !byte 229, 229, 229, 229, 133, 32, 117, 224, 64, 67, 0, 35, 32, 115, 69, 0
        !byte 37, 35, 197, 0, 229, 53, 0, 229, 53, 0, 213, 255
; Salle (8, 0) - RLE compact (25 octets)
room_08:
        !byte 229, 229, 229, 112, 165, 128, 101, 224, 64, 51, 128, 99, 53, 3, 112, 181
        !byte 51, 32, 3, 229, 5, 35, 229, 197, 255
; Salle (9, 0) - RLE compact (41 octets)
room_09:
        !byte 229, 229, 165, 96, 5, 128, 37, 64, 21, 160, 5, 64, 5, 16, 5, 0
        !byte 21, 0, 5, 16, 5, 16, 5, 3, 64, 21, 160, 21, 96, 5, 128, 3
        !byte 21, 51, 176, 3, 101, 179, 229, 117, 255
; Salle (10, 0) - RLE compact (43 octets)
room_10:
        !byte 229, 101, 7, 229, 37, 32, 180, 32, 21, 32, 180, 32, 21, 32, 180, 32
        !byte 21, 32, 180, 32, 21, 64, 25, 4, 9, 128, 21, 3, 80, 4, 128, 3
        !byte 37, 83, 4, 115, 0, 149, 4, 117, 0, 21, 255
; Salle (11, 0) - RLE compact (45 octets)
room_11:
        !byte 229, 229, 181, 80, 51, 96, 21, 32, 5, 0, 37, 7, 37, 0, 21, 32
        !byte 21, 224, 32, 21, 32, 5, 0, 21, 48, 5, 0, 21, 32, 21, 3, 224
        !byte 16, 37, 19, 208, 3, 69, 67, 0, 115, 165, 0, 149, 255
; Salle (12, 0) - RLE compact (40 octets)
room_12:
        !byte 229, 229, 7, 229, 37, 96, 21, 16, 133, 160, 85, 208, 85, 16, 3, 160
        !byte 85, 16, 5, 96, 19, 16, 85, 16, 5, 3, 80, 21, 3, 0, 85, 16
        !byte 21, 83, 37, 3, 85, 16, 181, 255
; Salle (13, 0) - RLE compact (36 octets)
room_13:
        !byte 229, 229, 149, 48, 21, 112, 85, 224, 0, 53, 224, 32, 21, 224, 48, 5
        !byte 48, 19, 192, 5, 16, 19, 21, 19, 144, 3, 5, 19, 85, 131, 0, 229
        !byte 53, 0, 21, 255
; Salle (14, 0) - RLE compact (34 octets)
room_14:
        !byte 228, 228, 148, 197, 100, 85, 7, 85, 100, 85, 16, 69, 100, 85, 16, 69
        !byte 100, 85, 16, 69, 100, 85, 16, 69, 100, 85, 16, 69, 100, 85, 16, 69
        !byte 100, 255
; Salle (15, 0) - RLE compact (61 octets)
room_15:
        !byte 4, 229, 37, 20, 229, 37, 20, 5, 32, 35, 0, 3, 21, 3, 0, 35
        !byte 0, 5, 20, 5, 32, 37, 0, 5, 7, 21, 0, 37, 0, 5, 20, 5
        !byte 224, 0, 5, 20, 5, 224, 0, 5, 20, 5, 224, 0, 5, 20, 5, 224
        !byte 0, 5, 20, 5, 115, 16, 83, 5, 20, 229, 37, 4, 255
; Salle (0, 1) - RLE compact (48 octets)
room_16:
        !byte 133, 0, 229, 53, 0, 181, 32, 5, 112, 33, 16, 1, 5, 96, 5, 64
        !byte 35, 16, 3, 5, 48, 5, 48, 21, 112, 5, 96, 5, 96, 17, 16, 5
        !byte 3, 32, 5, 144, 19, 16, 21, 19, 224, 0, 53, 227, 3, 229, 69, 255
; Salle (1, 1) - RLE compact (47 octets)
room_17:
        !byte 133, 0, 229, 53, 0, 149, 1, 32, 17, 144, 5, 16, 5, 3, 32, 19
        !byte 96, 5, 64, 5, 144, 21, 48, 5, 16, 5, 16, 33, 112, 5, 64, 5
        !byte 16, 35, 160, 5, 16, 5, 224, 32, 3, 5, 227, 35, 229, 101, 255
; Salle (2, 1) - RLE compact (49 octets)
room_18:
        !byte 53, 0, 229, 53, 0, 229, 53, 0, 53, 32, 17, 16, 17, 0, 1, 53
        !byte 0, 37, 48, 19, 16, 19, 0, 3, 21, 224, 32, 5, 176, 33, 0, 17
        !byte 0, 5, 176, 35, 0, 19, 0, 5, 3, 224, 32, 21, 227, 35, 229, 69
        !byte 255
; Salle (3, 1) - RLE compact (28 octets)
room_19:
        !byte 197, 0, 229, 53, 0, 85, 1, 48, 117, 0, 53, 16, 3, 64, 101, 0
        !byte 37, 224, 224, 224, 224, 224, 112, 227, 67, 229, 69, 255
; Salle (4, 1) - RLE compact (35 octets)
room_20:
        !byte 229, 229, 149, 224, 48, 5, 48, 5, 32, 5, 32, 5, 48, 5, 0, 5
        !byte 224, 128, 5, 32, 5, 32, 5, 48, 5, 224, 224, 176, 195, 0, 83, 197
        !byte 0, 85, 255
; Salle (5, 1) - RLE compact (35 octets)
room_21:
        !byte 229, 229, 229, 69, 144, 149, 160, 37, 16, 37, 224, 224, 224, 96, 35, 16
        !byte 35, 48, 35, 16, 35, 37, 0, 3, 37, 51, 37, 3, 0, 85, 0, 181
        !byte 0, 21, 255
; Salle (6, 1) - RLE compact (32 octets)
room_22:
        !byte 229, 229, 149, 144, 117, 176, 101, 224, 224, 96, 35, 224, 16, 37, 3, 16
        !byte 19, 32, 35, 80, 53, 3, 0, 21, 35, 37, 83, 69, 3, 229, 69, 255
; Salle (7, 1) - RLE compact (36 octets)
room_23:
        !byte 69, 0, 229, 53, 0, 213, 48, 5, 0, 213, 48, 5, 0, 21, 180, 112
        !byte 4, 224, 48, 4, 224, 48, 4, 224, 48, 4, 160, 115, 4, 64, 83, 117
        !byte 4, 64, 85, 255
; Salle (8, 1) - RLE compact (17 octets)
room_24:
        !byte 229, 229, 229, 229, 228, 68, 224, 224, 224, 64, 147, 144, 149, 147, 229, 229
        !byte 255
; Salle (9, 1) - RLE compact (16 octets)
room_25:
        !byte 229, 229, 229, 229, 228, 68, 224, 224, 144, 227, 67, 229, 229, 229, 229, 255
; Salle (10, 1) - RLE compact (29 octets)
room_26:
        !byte 117, 4, 117, 0, 149, 4, 117, 0, 149, 4, 117, 0, 21, 116, 133, 0
        !byte 21, 224, 224, 128, 147, 144, 149, 144, 149, 147, 229, 85, 255
; Salle (11, 1) - RLE compact (47 octets)
room_27:
        !byte 133, 0, 229, 53, 0, 181, 48, 21, 144, 53, 16, 5, 64, 21, 0, 5
        !byte 48, 21, 80, 21, 112, 5, 32, 19, 16, 5, 64, 21, 0, 5, 48, 19
        !byte 21, 48, 21, 144, 53, 19, 192, 3, 85, 67, 0, 99, 229, 117, 255
; Salle (12, 1) - RLE compact (44 octets)
room_28:
        !byte 85, 16, 229, 37, 16, 197, 224, 48, 5, 112, 5, 16, 5, 0, 21, 0
        !byte 5, 224, 96, 3, 112, 5, 16, 5, 0, 21, 0, 5, 16, 5, 224, 48
        !byte 5, 3, 224, 32, 21, 19, 0, 227, 53, 0, 229, 255
; Salle (13, 1) - RLE compact (44 octets)
room_29:
        !byte 229, 21, 0, 229, 53, 0, 21, 80, 165, 0, 21, 80, 101, 160, 5, 0
        !byte 37, 224, 16, 21, 48, 116, 80, 21, 48, 116, 64, 3, 21, 3, 32, 116
        !byte 19, 16, 3, 53, 32, 116, 21, 16, 69, 32, 116, 255
; Salle (14, 1) - RLE compact (29 octets)
room_30:
        !byte 85, 16, 229, 37, 16, 229, 37, 16, 53, 224, 16, 37, 224, 192, 132, 35
        !byte 112, 132, 37, 112, 132, 37, 112, 132, 37, 115, 132, 165, 255
; Salle (15, 1) - RLE compact (60 octets)
room_31:
        !byte 229, 53, 4, 229, 53, 4, 16, 37, 0, 53, 32, 37, 16, 5, 4, 16
        !byte 35, 0, 19, 7, 3, 32, 35, 16, 5, 4, 224, 32, 5, 4, 64, 37
        !byte 16, 37, 0, 37, 0, 5, 4, 64, 35, 16, 35, 0, 35, 0, 5, 4
        !byte 224, 32, 5, 4, 227, 35, 5, 4, 229, 53, 4, 255

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

; Formations d'ennemis dédupliquées (29 formations x 24 octets)
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
        !byte TYPE_PEAHAT     ,  10,  4,   TYPE_PEAHAT     ,   3,  7,   TYPE_PEAHAT     ,  16,  3,   TYPE_PEAHAT     ,   5,  2,   TYPE_PEAHAT     ,   9,  7,   TYPE_PEAHAT     ,  13,  4,   TYPE_ZORA       ,  12,  5,   TYPE_ZORA       ,  17,  7
        ; Formation 27
        !byte TYPE_TEKTITE_RED,  10,  4,   TYPE_TEKTITE_RED,   3,  3,   TYPE_TEKTITE_RED,  16,  7,   TYPE_TEKTITE_RED,  15,  2,   TYPE_TEKTITE_RED,  12,  7,   TYPE_TEKTITE_RED,   7,  3,   TYPE_ZORA       ,   8,  5,   TYPE_ZORA       ,   2,  7
        ; Formation 28
        !byte TYPE_PEAHAT     ,  10,  4,   TYPE_PEAHAT     ,   3,  7,   TYPE_PEAHAT     ,  16,  7,   TYPE_PEAHAT     ,   5,  2,   TYPE_PEAHAT     ,  16,  2,   TYPE_PEAHAT     ,   7,  7,   TYPE_ZORA       ,  19,  4,   TYPE_NONE       ,   0,  0
