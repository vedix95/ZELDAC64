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
        !byte 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 3, 3, 0, 0, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3

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
        !byte 229, 229, 229, 229, 229, 229, 229, 53, 160, 133, 1, 229, 53, 1, 229, 53
        !byte 1, 229, 53, 1, 149, 255
; Salle (1, 0) - RLE compact (26 octets)
room_01:
        !byte 229, 229, 229, 85, 64, 117, 0, 85, 64, 101, 16, 85, 80, 37, 224, 64
        !byte 37, 208, 101, 176, 117, 176, 197, 1, 149, 255
; Salle (2, 0) - RLE compact (28 octets)
room_02:
        !byte 229, 229, 229, 229, 181, 16, 229, 37, 32, 69, 224, 64, 69, 1, 85, 112
        !byte 69, 1, 85, 112, 69, 1, 101, 96, 69, 1, 213, 255
; Salle (3, 0) - RLE compact (29 octets)
room_03:
        !byte 229, 229, 197, 16, 229, 37, 32, 229, 21, 48, 197, 192, 101, 96, 69, 1
        !byte 101, 80, 85, 1, 101, 64, 101, 1, 229, 53, 1, 101, 255
; Salle (4, 0) - RLE compact (28 octets)
room_04:
        !byte 229, 229, 53, 7, 229, 37, 48, 229, 112, 165, 128, 53, 48, 21, 144, 37
        !byte 224, 16, 37, 224, 16, 53, 48, 21, 96, 229, 117, 255
; Salle (5, 0) - RLE compact (36 octets)
room_05:
        !byte 229, 229, 229, 160, 53, 80, 21, 48, 21, 32, 37, 64, 5, 12, 21, 16
        !byte 53, 16, 37, 64, 53, 16, 53, 144, 53, 16, 53, 16, 37, 224, 16, 117
        !byte 160, 229, 133, 255
; Salle (6, 0) - RLE compact (22 octets)
room_06:
        !byte 229, 229, 229, 53, 16, 229, 80, 197, 96, 117, 224, 64, 69, 96, 213, 80
        !byte 229, 21, 16, 229, 213, 255
; Salle (7, 0) - RLE compact (24 octets)
room_07:
        !byte 229, 229, 229, 229, 229, 213, 16, 133, 224, 64, 85, 1, 21, 16, 229, 1
        !byte 229, 53, 1, 229, 53, 1, 197, 255
; Salle (8, 0) - RLE compact (22 octets)
room_08:
        !byte 229, 229, 229, 53, 16, 229, 80, 197, 96, 117, 224, 64, 69, 96, 213, 80
        !byte 229, 21, 16, 229, 213, 255
; Salle (9, 0) - RLE compact (38 octets)
room_09:
        !byte 229, 229, 229, 5, 128, 117, 64, 13, 96, 101, 48, 13, 128, 37, 80, 13
        !byte 0, 13, 0, 13, 0, 13, 0, 13, 16, 85, 48, 13, 128, 85, 64, 13
        !byte 96, 149, 128, 229, 149, 255
; Salle (10, 0) - RLE compact (38 octets)
room_10:
        !byte 229, 133, 7, 229, 53, 176, 101, 16, 132, 32, 85, 16, 132, 32, 85, 16
        !byte 132, 32, 85, 16, 132, 32, 85, 48, 9, 4, 9, 96, 101, 48, 4, 96
        !byte 181, 4, 85, 1, 53, 255
; Salle (11, 0) - RLE compact (40 octets)
room_11:
        !byte 229, 229, 229, 160, 117, 48, 47, 80, 85, 16, 14, 0, 14, 15, 7, 15
        !byte 14, 0, 14, 32, 85, 208, 85, 16, 14, 0, 14, 32, 14, 0, 14, 32
        !byte 101, 192, 117, 160, 197, 1, 149, 255
; Salle (12, 0) - RLE compact (36 octets)
room_12:
        !byte 229, 229, 7, 229, 53, 48, 37, 32, 133, 64, 21, 48, 133, 160, 101, 192
        !byte 101, 1, 5, 160, 101, 1, 5, 64, 21, 48, 101, 1, 21, 48, 37, 32
        !byte 101, 1, 181, 255
; Salle (13, 0) - RLE compact (31 octets)
room_13:
        !byte 229, 229, 149, 48, 53, 48, 117, 64, 21, 80, 101, 208, 85, 224, 0, 53
        !byte 224, 16, 37, 64, 21, 144, 37, 48, 53, 112, 229, 53, 1, 53, 255
; Salle (14, 0) - RLE compact (31 octets)
room_14:
        !byte 228, 228, 228, 228, 181, 116, 101, 7, 53, 116, 101, 0, 53, 116, 101, 0
        !byte 53, 116, 101, 0, 53, 116, 101, 1, 53, 116, 101, 1, 53, 116, 255
; Salle (15, 0) - RLE compact (52 octets)
room_15:
        !byte 36, 213, 84, 213, 84, 5, 176, 5, 84, 5, 16, 31, 0, 47, 0, 31
        !byte 0, 5, 84, 5, 16, 31, 0, 15, 7, 15, 0, 31, 0, 5, 84, 5
        !byte 176, 5, 84, 5, 176, 5, 84, 5, 176, 5, 84, 5, 176, 5, 84, 85
        !byte 48, 53, 36, 255
; Salle (0, 1) - RLE compact (44 octets)
room_16:
        !byte 133, 1, 229, 53, 1, 229, 224, 53, 16, 13, 80, 18, 16, 34, 37, 64
        !byte 13, 48, 18, 16, 34, 37, 32, 13, 32, 13, 128, 37, 64, 13, 64, 18
        !byte 48, 53, 16, 13, 96, 18, 48, 69, 224, 229, 69, 255
; Salle (1, 1) - RLE compact (46 octets)
room_17:
        !byte 133, 1, 229, 53, 1, 149, 224, 0, 53, 34, 16, 18, 96, 13, 16, 37
        !byte 34, 16, 18, 64, 13, 48, 37, 144, 13, 32, 13, 16, 37, 48, 18, 80
        !byte 13, 48, 37, 48, 18, 112, 13, 16, 37, 224, 0, 229, 133, 255
; Salle (2, 1) - RLE compact (49 octets)
room_18:
        !byte 69, 1, 229, 53, 1, 229, 53, 1, 53, 144, 69, 1, 37, 16, 18, 0
        !byte 18, 0, 34, 69, 1, 21, 32, 18, 0, 18, 0, 34, 53, 224, 0, 37
        !byte 128, 18, 0, 18, 32, 37, 128, 18, 0, 18, 32, 53, 224, 0, 229, 69
        !byte 255
; Salle (3, 1) - RLE compact (31 octets)
room_19:
        !byte 181, 1, 229, 53, 1, 101, 64, 101, 1, 53, 32, 34, 32, 85, 1, 37
        !byte 48, 34, 48, 69, 1, 21, 224, 224, 224, 224, 224, 144, 229, 69, 255
; Salle (4, 1) - RLE compact (35 octets)
room_20:
        !byte 229, 229, 149, 224, 0, 53, 224, 16, 37, 64, 14, 16, 14, 16, 14, 32
        !byte 14, 0, 37, 224, 144, 14, 16, 14, 16, 14, 32, 14, 224, 224, 208, 181
        !byte 1, 101, 255
; Salle (5, 1) - RLE compact (30 octets)
room_21:
        !byte 229, 229, 229, 69, 16, 21, 16, 213, 144, 149, 192, 21, 16, 21, 224, 224
        !byte 224, 128, 21, 16, 21, 32, 21, 16, 133, 1, 133, 1, 53, 255
; Salle (6, 1) - RLE compact (28 octets)
room_22:
        !byte 229, 229, 213, 16, 21, 16, 101, 192, 85, 208, 69, 224, 224, 112, 21, 224
        !byte 32, 37, 48, 53, 16, 21, 64, 53, 32, 229, 69, 255
; Salle (7, 1) - RLE compact (37 octets)
room_23:
        !byte 85, 1, 229, 53, 1, 197, 48, 21, 1, 197, 64, 5, 1, 197, 64, 5
        !byte 1, 5, 4, 165, 112, 4, 224, 48, 4, 224, 48, 4, 224, 48, 4, 160
        !byte 117, 4, 48, 101, 255
; Salle (8, 1) - RLE compact (16 octets)
room_24:
        !byte 229, 229, 229, 229, 229, 229, 149, 224, 224, 224, 64, 149, 144, 229, 229, 255
; Salle (9, 1) - RLE compact (15 octets)
room_25:
        !byte 229, 229, 229, 229, 229, 229, 149, 224, 224, 144, 229, 229, 229, 229, 255
; Salle (10, 1) - RLE compact (31 octets)
room_26:
        !byte 117, 4, 85, 1, 181, 4, 85, 1, 181, 4, 85, 1, 181, 4, 85, 1
        !byte 181, 4, 85, 1, 53, 224, 224, 96, 181, 112, 181, 112, 229, 117, 255
; Salle (11, 1) - RLE compact (43 octets)
room_27:
        !byte 133, 1, 229, 53, 1, 229, 144, 133, 32, 13, 112, 117, 0, 13, 48, 13
        !byte 0, 13, 32, 53, 96, 13, 80, 13, 64, 53, 0, 13, 48, 13, 0, 13
        !byte 32, 117, 32, 13, 112, 133, 144, 213, 1, 149, 255
; Salle (12, 1) - RLE compact (43 octets)
room_28:
        !byte 101, 1, 229, 53, 1, 229, 5, 224, 0, 37, 224, 16, 37, 80, 14, 0
        !byte 14, 0, 14, 0, 14, 224, 128, 37, 80, 14, 0, 14, 0, 14, 0, 14
        !byte 48, 37, 224, 16, 53, 224, 0, 69, 1, 213, 255
; Salle (13, 1) - RLE compact (39 octets)
room_29:
        !byte 229, 1, 229, 53, 1, 53, 80, 133, 1, 53, 96, 117, 1, 53, 96, 69
        !byte 192, 13, 0, 21, 224, 32, 5, 32, 132, 96, 5, 32, 132, 80, 37, 16
        !byte 132, 53, 1, 53, 16, 132, 255
; Salle (14, 1) - RLE compact (30 octets)
room_30:
        !byte 101, 1, 229, 53, 1, 229, 53, 1, 53, 112, 101, 1, 37, 224, 32, 21
        !byte 224, 208, 132, 21, 128, 132, 21, 128, 132, 21, 128, 132, 165, 255
; Salle (15, 1) - RLE compact (64 octets)
room_31:
        !byte 133, 59, 53, 36, 133, 59, 53, 36, 224, 0, 5, 36, 48, 18, 0, 2
        !byte 15, 2, 16, 18, 16, 5, 36, 48, 18, 0, 2, 7, 2, 16, 18, 16
        !byte 5, 36, 224, 0, 5, 36, 80, 18, 16, 18, 0, 18, 0, 5, 36, 80
        !byte 18, 16, 18, 0, 18, 0, 5, 36, 224, 0, 5, 36, 229, 21, 36, 255

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

; Formations d'ennemis dédupliquées (30 formations x 24 octets)
map_enemies:
        ; Formation 0
        !byte TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 1
        !byte TYPE_LYNEL_RED  ,  11,  3,   TYPE_LYNEL_RED  ,   3,  6,   TYPE_LYNEL_RED  ,  15,  6,   TYPE_LYNEL_RED  ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 2
        !byte TYPE_LYNEL_RED  ,   9,  5,   TYPE_LYNEL_RED  ,   2,  5,   TYPE_LYNEL_RED  ,  16,  7,   TYPE_LYNEL_RED  ,  13,  3,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 3
        !byte TYPE_TEKTITE_RED,   9,  5,   TYPE_TEKTITE_RED,   3,  7,   TYPE_TEKTITE_RED,   4,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 4
        !byte TYPE_LYNEL_BLUE ,  11,  4,   TYPE_LYNEL_BLUE ,   3,  7,   TYPE_LYNEL_BLUE ,  16,  7,   TYPE_LYNEL_BLUE ,  15,  2,   TYPE_LYNEL_BLUE ,   5,  5,   TYPE_LYNEL_BLUE ,  12,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 5
        !byte TYPE_LYNEL_BLUE ,  10,  4,   TYPE_LEEVER_BLUE,   2,  3,   TYPE_LYNEL_RED  ,  16,  7,   TYPE_LYNEL_BLUE ,   5,  7,   TYPE_LEEVER_RED ,  15,  2,   TYPE_LYNEL_RED  ,  12,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 6
        !byte TYPE_PEAHAT     ,  10,  4,   TYPE_PEAHAT     ,   2,  5,   TYPE_LYNEL_RED  ,  15,  5,   TYPE_LYNEL_BLUE ,   6,  3,   TYPE_LYNEL_RED  ,   7,  6,   TYPE_LYNEL_BLUE ,  11,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 7
        !byte TYPE_LYNEL_RED  ,  10,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 8
        !byte TYPE_TEKTITE_RED,  10,  4,   TYPE_TEKTITE_RED,   2,  5,   TYPE_TEKTITE_RED,  15,  5,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 9
        !byte TYPE_LYNEL_BLUE ,   9,  7,   TYPE_ZORA       ,  10,  4,   TYPE_ZORA       ,   5,  3,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 10
        !byte TYPE_LEEVER_RED ,  11,  3,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 11
        !byte TYPE_TEKTITE_RED,  10,  4,   TYPE_TEKTITE_RED,  16,  3,   TYPE_TEKTITE_RED,  13,  6,   TYPE_TEKTITE_RED,   7,  5,   TYPE_TEKTITE_RED,  13,  2,   TYPE_TEKTITE_RED,  10,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 12
        !byte TYPE_TEKTITE_RED,  10,  4,   TYPE_TEKTITE_RED,   3,  2,   TYPE_TEKTITE_RED,  16,  7,   TYPE_TEKTITE_RED,   6,  6,   TYPE_TEKTITE_RED,  13,  4,   TYPE_TEKTITE_RED,   8,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 13
        !byte TYPE_ZORA       ,  13,  4,   TYPE_ZORA       ,  17,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 14
        !byte TYPE_ZORA       ,  18,  3,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 15
        !byte TYPE_LYNEL_BLUE ,  10,  3,   TYPE_LYNEL_BLUE ,   3,  6,   TYPE_LYNEL_BLUE ,  16,  7,   TYPE_LYNEL_BLUE ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 16
        !byte TYPE_PEAHAT     ,  10,  3,   TYPE_PEAHAT     ,   3,  7,   TYPE_LYNEL_RED  ,  16,  7,   TYPE_LYNEL_BLUE ,   5,  2,   TYPE_LYNEL_RED  ,  15,  2,   TYPE_LYNEL_BLUE ,   8,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 17
        !byte TYPE_LYNEL_BLUE ,  10,  4,   TYPE_LYNEL_BLUE ,   3,  7,   TYPE_LYNEL_BLUE ,  17,  6,   TYPE_LYNEL_BLUE ,  15,  2,   TYPE_LYNEL_BLUE ,   5,  3,   TYPE_LYNEL_BLUE ,   8,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 18
        !byte TYPE_LYNEL_BLUE ,   9,  5,   TYPE_LYNEL_RED  ,   3,  7,   TYPE_LYNEL_BLUE ,  16,  7,   TYPE_LYNEL_RED  ,   4,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 19
        !byte TYPE_LYNEL_RED  ,  10,  4,   TYPE_LYNEL_RED  ,   3,  7,   TYPE_LYNEL_RED  ,  16,  7,   TYPE_LYNEL_RED  ,   5,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 20
        !byte TYPE_PEAHAT     ,  10,  4,   TYPE_PEAHAT     ,   3,  6,   TYPE_LYNEL_RED  ,  16,  7,   TYPE_LYNEL_BLUE ,  15,  2,   TYPE_LYNEL_RED  ,   7,  6,   TYPE_LYNEL_BLUE ,  12,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 21
        !byte TYPE_TEKTITE_RED,   9,  3,   TYPE_TEKTITE_RED,   3,  7,   TYPE_TEKTITE_RED,  16,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 22
        !byte TYPE_TEKTITE_RED,   9,  5,   TYPE_TEKTITE_RED,   3,  7,   TYPE_TEKTITE_RED,  16,  7,   TYPE_ZORA       ,   8,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 23
        !byte TYPE_TEKTITE_RED,   9,  5,   TYPE_TEKTITE_RED,   3,  7,   TYPE_TEKTITE_RED,  16,  5,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 24
        !byte TYPE_TEKTITE_RED,   9,  5,   TYPE_TEKTITE_RED,   3,  5,   TYPE_TEKTITE_RED,  16,  5,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 25
        !byte TYPE_TEKTITE_RED,   9,  5,   TYPE_TEKTITE_RED,   3,  5,   TYPE_TEKTITE_RED,  16,  7,   TYPE_TEKTITE_RED,  12,  7,   TYPE_TEKTITE_RED,  15,  3,   TYPE_TEKTITE_RED,   7,  5,   TYPE_ZORA       ,   8,  2,   TYPE_NONE       ,   0,  0
        ; Formation 26
        !byte TYPE_ARMOS      ,   8,  3,   TYPE_ARMOS      ,  10,  3,   TYPE_ARMOS      ,  12,  3,   TYPE_ARMOS      ,  14,  3,   TYPE_ARMOS      ,   8,  5,   TYPE_ARMOS      ,  10,  5,   TYPE_ARMOS      ,  12,  5,   TYPE_ARMOS      ,  14,  5
        ; Formation 27
        !byte TYPE_PEAHAT     ,   9,  5,   TYPE_PEAHAT     ,   3,  7,   TYPE_PEAHAT     ,  15,  2,   TYPE_PEAHAT     ,   5,  2,   TYPE_PEAHAT     ,   9,  7,   TYPE_PEAHAT     ,  13,  4,   TYPE_ZORA       ,  11,  6,   TYPE_ZORA       ,  17,  7
        ; Formation 28
        !byte TYPE_TEKTITE_RED,  11,  3,   TYPE_TEKTITE_RED,   2,  4,   TYPE_TEKTITE_RED,  16,  7,   TYPE_TEKTITE_RED,  15,  2,   TYPE_TEKTITE_RED,  12,  7,   TYPE_TEKTITE_RED,   7,  3,   TYPE_ZORA       ,   7,  6,   TYPE_ZORA       ,   2,  7
        ; Formation 29
        !byte TYPE_PEAHAT     ,  10,  4,   TYPE_PEAHAT     ,   3,  7,   TYPE_PEAHAT     ,  15,  6,   TYPE_PEAHAT     ,   5,  2,   TYPE_PEAHAT     ,  15,  2,   TYPE_PEAHAT     ,   8,  6,   TYPE_ZORA       ,  18,  3,   TYPE_NONE       ,   0,  0
