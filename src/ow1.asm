; GENERE par tools/tilegen.py - Chunk Overworld 1 (Salles 32..63)
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
        !byte <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32
        !byte <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32
        !byte <room_32, <room_33, <room_34, <room_35, <room_36, <room_37, <room_38, <room_39, <room_40, <room_41, <room_42, <room_43, <room_44, <room_45, <room_46, <room_47
        !byte <room_48, <room_49, <room_50, <room_51, <room_52, <room_53, <room_54, <room_55, <room_56, <room_57, <room_58, <room_59, <room_60, <room_61, <room_62, <room_63
        !byte <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32
        !byte <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32
        !byte <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32
        !byte <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32, <room_32
room_tbl_hi:
        !byte >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32
        !byte >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32
        !byte >room_32, >room_33, >room_34, >room_35, >room_36, >room_37, >room_38, >room_39, >room_40, >room_41, >room_42, >room_43, >room_44, >room_45, >room_46, >room_47
        !byte >room_48, >room_49, >room_50, >room_51, >room_52, >room_53, >room_54, >room_55, >room_56, >room_57, >room_58, >room_59, >room_60, >room_61, >room_62, >room_63
        !byte >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32
        !byte >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32
        !byte >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32
        !byte >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32, >room_32

; Table des zones régionales par salle (128 octets : $C116..$C195)
room_zone_palette:
        !byte 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 3, 3, 0, 0, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3

; Index de formation d'ennemis par salle (128 octets : $C196..$C215)
room_enemy_idx:
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0
        !byte 1, 2, 16, 0, 17, 18, 19, 20, 21, 0, 22, 23, 24, 25, 26, 27
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

; Salle (0, 2) - RLE compact (47 octets)
room_32:
        !byte 229, 229, 229, 224, 53, 0, 8, 16, 8, 16, 8, 16, 8, 64, 53, 224
        !byte 0, 53, 0, 8, 16, 8, 16, 8, 16, 8, 64, 53, 224, 0, 53, 0
        !byte 8, 16, 8, 16, 8, 16, 8, 64, 53, 224, 0, 53, 176, 53, 255
; Salle (1, 2) - RLE compact (52 octets)
room_33:
        !byte 229, 5, 51, 229, 5, 51, 224, 0, 51, 64, 8, 16, 8, 16, 8, 16
        !byte 8, 0, 51, 224, 0, 51, 64, 8, 16, 8, 16, 8, 16, 8, 0, 51
        !byte 224, 0, 51, 64, 8, 16, 8, 16, 8, 16, 8, 0, 51, 224, 0, 51
        !byte 53, 176, 51, 255
; Salle (2, 2) - RLE compact (32 octets)
room_34:
        !byte 229, 229, 213, 176, 117, 48, 63, 48, 117, 0, 34, 15, 23, 15, 34, 0
        !byte 117, 176, 117, 0, 34, 48, 34, 0, 117, 176, 117, 176, 197, 1, 149, 255
; Salle (3, 2) - RLE compact (44 octets)
room_35:
        !byte 229, 229, 213, 64, 53, 96, 37, 96, 21, 112, 37, 32, 13, 32, 21, 112
        !byte 37, 16, 13, 0, 13, 16, 21, 112, 37, 32, 13, 32, 21, 112, 37, 96
        !byte 21, 112, 53, 64, 53, 96, 117, 1, 85, 1, 53, 255
; Salle (4, 2) - RLE compact (38 octets)
room_36:
        !byte 181, 1, 229, 53, 1, 101, 64, 21, 224, 224, 96, 14, 16, 14, 16, 14
        !byte 16, 14, 16, 14, 224, 176, 14, 16, 14, 16, 14, 16, 14, 16, 14, 224
        !byte 192, 21, 192, 229, 69, 255
; Salle (5, 2) - RLE compact (49 octets)
room_37:
        !byte 69, 1, 133, 1, 133, 1, 85, 7, 21, 1, 53, 224, 0, 53, 224, 16
        !byte 37, 48, 14, 16, 14, 16, 14, 16, 14, 32, 37, 224, 16, 37, 48, 14
        !byte 16, 14, 16, 14, 16, 14, 32, 37, 224, 16, 37, 224, 0, 149, 1, 197
        !byte 255
; Salle (6, 2) - RLE compact (33 octets)
room_38:
        !byte 229, 229, 213, 32, 53, 0, 165, 64, 21, 16, 165, 224, 16, 37, 224, 16
        !byte 37, 112, 132, 37, 64, 21, 0, 132, 53, 32, 53, 132, 53, 16, 69, 132
        !byte 255
; Salle (7, 2) - RLE compact (29 octets)
room_39:
        !byte 117, 4, 48, 229, 4, 48, 229, 4, 48, 37, 48, 117, 4, 48, 37, 176
        !byte 4, 224, 48, 4, 9, 144, 228, 228, 228, 228, 228, 68, 255
; Salle (8, 2) - RLE compact (32 octets)
room_40:
        !byte 227, 227, 147, 224, 0, 3, 224, 0, 3, 224, 80, 3, 224, 16, 3, 80
        !byte 132, 80, 3, 48, 132, 48, 3, 80, 132, 96, 3, 32, 132, 16, 131, 255
; Salle (9, 2) - RLE compact (16 octets)
room_41:
        !byte 229, 229, 149, 230, 230, 230, 230, 230, 230, 230, 230, 230, 70, 229, 69, 255
; Salle (10, 2) - RLE compact (17 octets)
room_42:
        !byte 229, 229, 149, 230, 230, 230, 230, 230, 230, 230, 230, 230, 70, 53, 198, 37
        !byte 255
; Salle (11, 2) - RLE compact (20 octets)
room_43:
        !byte 133, 1, 229, 53, 1, 149, 230, 230, 230, 230, 230, 230, 230, 230, 230, 70
        !byte 37, 198, 53, 255
; Salle (12, 2) - RLE compact (27 octets)
room_44:
        !byte 69, 1, 229, 53, 1, 213, 208, 85, 112, 53, 16, 85, 96, 85, 0, 85
        !byte 96, 85, 208, 85, 224, 224, 224, 16, 229, 69, 255
; Salle (13, 2) - RLE compact (35 octets)
room_45:
        !byte 53, 1, 53, 16, 132, 53, 1, 53, 16, 132, 53, 1, 5, 64, 132, 53
        !byte 1, 5, 64, 132, 53, 1, 5, 64, 132, 224, 224, 224, 224, 224, 64, 133
        !byte 16, 133, 255
; Salle (14, 2) - RLE compact (20 octets)
room_46:
        !byte 228, 228, 228, 228, 228, 228, 148, 144, 9, 132, 160, 132, 160, 132, 160, 132
        !byte 53, 96, 132, 255
; Salle (15, 2) - RLE compact (34 octets)
room_47:
        !byte 229, 229, 197, 176, 117, 0, 31, 0, 47, 0, 31, 16, 117, 0, 31, 0
        !byte 15, 7, 15, 0, 31, 16, 117, 176, 117, 176, 117, 176, 117, 176, 197, 1
        !byte 165, 255
; Salle (0, 3) - RLE compact (50 octets)
room_48:
        !byte 53, 176, 117, 176, 117, 224, 0, 53, 0, 8, 16, 8, 16, 8, 16, 8
        !byte 64, 53, 224, 0, 53, 0, 8, 16, 8, 16, 8, 16, 8, 64, 53, 224
        !byte 0, 53, 0, 8, 16, 8, 16, 8, 16, 8, 64, 53, 224, 0, 53, 176
        !byte 53, 255
; Salle (1, 3) - RLE compact (46 octets)
room_49:
        !byte 53, 176, 51, 53, 176, 51, 224, 0, 51, 64, 8, 16, 8, 16, 8, 16
        !byte 8, 0, 51, 224, 144, 8, 16, 8, 16, 8, 16, 8, 224, 224, 8, 16
        !byte 8, 16, 8, 16, 8, 0, 51, 224, 0, 51, 53, 176, 51, 255
; Salle (2, 3) - RLE compact (33 octets)
room_50:
        !byte 133, 1, 229, 53, 1, 229, 53, 1, 5, 16, 165, 16, 37, 1, 5, 32
        !byte 85, 96, 21, 1, 5, 48, 69, 224, 224, 64, 133, 160, 149, 144, 229, 149
        !byte 255
; Salle (3, 3) - RLE compact (46 octets)
room_51:
        !byte 117, 1, 85, 1, 181, 1, 85, 1, 117, 176, 117, 176, 117, 0, 2, 0
        !byte 2, 0, 13, 0, 2, 0, 2, 16, 53, 224, 0, 117, 0, 2, 0, 2
        !byte 0, 2, 0, 2, 0, 2, 16, 117, 176, 117, 176, 229, 133, 255
; Salle (4, 3) - RLE compact (35 octets)
room_52:
        !byte 229, 229, 213, 176, 101, 192, 101, 0, 14, 0, 14, 0, 14, 112, 85, 208
        !byte 85, 0, 14, 0, 14, 0, 14, 16, 132, 37, 112, 132, 53, 96, 132, 149
        !byte 0, 132, 255
; Salle (5, 3) - RLE compact (23 octets)
room_53:
        !byte 85, 1, 229, 53, 1, 229, 53, 1, 229, 53, 1, 229, 53, 208, 85, 208
        !byte 228, 228, 228, 228, 228, 68, 255
; Salle (6, 3) - RLE compact (26 octets)
room_54:
        !byte 53, 16, 69, 132, 53, 16, 69, 132, 53, 16, 69, 132, 53, 16, 69, 132
        !byte 160, 132, 160, 228, 228, 228, 228, 228, 212, 255
; Salle (7, 3) - RLE compact (60 octets)
room_55:
        !byte 36, 213, 84, 213, 84, 5, 176, 5, 84, 5, 0, 18, 0, 2, 15, 2
        !byte 0, 18, 16, 5, 84, 5, 0, 18, 0, 2, 7, 2, 0, 18, 16, 5
        !byte 84, 5, 192, 41, 36, 5, 16, 18, 32, 18, 32, 5, 84, 5, 16, 18
        !byte 32, 18, 32, 5, 84, 5, 176, 5, 84, 213, 36, 255
; Salle (8, 3) - RLE compact (39 octets)
room_56:
        !byte 132, 16, 131, 132, 16, 131, 132, 32, 3, 48, 35, 132, 112, 35, 132, 64
        !byte 3, 16, 35, 137, 112, 35, 132, 64, 3, 16, 35, 132, 112, 35, 132, 32
        !byte 3, 48, 35, 132, 16, 131, 255
; Salle (9, 3) - RLE compact (36 octets)
room_57:
        !byte 229, 229, 213, 176, 101, 48, 84, 48, 85, 16, 3, 0, 84, 0, 3, 16
        !byte 85, 48, 84, 48, 85, 16, 3, 0, 84, 0, 3, 16, 85, 208, 101, 176
        !byte 197, 16, 133, 255
; Salle (10, 3) - RLE compact (29 octets)
room_58:
        !byte 53, 198, 101, 198, 101, 230, 6, 53, 230, 6, 53, 230, 6, 53, 230, 6
        !byte 53, 230, 6, 53, 230, 6, 53, 230, 6, 133, 22, 133, 255
; Salle (11, 3) - RLE compact (30 octets)
room_59:
        !byte 37, 198, 101, 198, 53, 230, 6, 53, 230, 6, 53, 230, 6, 53, 230, 6
        !byte 53, 230, 6, 53, 230, 6, 53, 230, 6, 229, 37, 22, 53, 255
; Salle (12, 3) - RLE compact (40 octets)
room_60:
        !byte 229, 229, 229, 160, 117, 48, 47, 80, 85, 16, 14, 0, 14, 15, 7, 15
        !byte 14, 0, 14, 32, 85, 208, 85, 16, 14, 0, 14, 32, 14, 0, 14, 32
        !byte 101, 192, 117, 160, 197, 1, 149, 255
; Salle (13, 3) - RLE compact (61 octets)
room_61:
        !byte 131, 16, 227, 35, 16, 179, 208, 83, 0, 3, 0, 3, 80, 3, 32, 83
        !byte 64, 14, 16, 14, 32, 3, 0, 83, 0, 3, 0, 3, 80, 3, 32, 83
        !byte 176, 3, 0, 83, 0, 3, 0, 3, 80, 3, 32, 83, 208, 83, 0, 3
        !byte 0, 3, 0, 3, 16, 3, 0, 3, 0, 3, 0, 35, 255
; Salle (14, 3) - RLE compact (29 octets)
room_62:
        !byte 53, 96, 132, 53, 96, 132, 53, 96, 132, 53, 96, 132, 53, 96, 132, 53
        !byte 224, 0, 53, 224, 0, 53, 224, 0, 69, 224, 229, 69, 255
; Salle (15, 3) - RLE compact (21 octets)
room_63:
        !byte 228, 228, 228, 228, 228, 196, 9, 164, 144, 9, 132, 160, 132, 160, 132, 160
        !byte 132, 101, 48, 132, 255

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

; Formations d'ennemis dédupliquées (28 formations x 24 octets)
map_enemies:
        ; Formation 0
        !byte TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 1
        !byte TYPE_GHINI      ,  10,  4,   TYPE_GHINI      ,   4,  6,   TYPE_GHINI      ,  16,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 2
        !byte TYPE_GHINI      ,  10,  4,   TYPE_GHINI      ,   3,  7,   TYPE_GHINI      ,  15,  6,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 3
        !byte TYPE_LYNEL_RED  ,   9,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 4
        !byte TYPE_LYNEL_RED  ,   9,  4,   TYPE_LYNEL_RED  ,  16,  7,   TYPE_LYNEL_RED  ,   3,  7,   TYPE_LYNEL_RED  ,  14,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 5
        !byte TYPE_ARMOS      ,   3,  3,   TYPE_ARMOS      ,   6,  3,   TYPE_ARMOS      ,   9,  3,   TYPE_ARMOS      ,  12,  3,   TYPE_ARMOS      ,  15,  3,   TYPE_ARMOS      ,   3,  5,   TYPE_ARMOS      ,   9,  5,   TYPE_ARMOS      ,  15,  5
        ; Formation 6
        !byte TYPE_ARMOS      ,   3,  3,   TYPE_ARMOS      ,   6,  3,   TYPE_ARMOS      ,   9,  3,   TYPE_ARMOS      ,  12,  3,   TYPE_ARMOS      ,   3,  5,   TYPE_ARMOS      ,   6,  5,   TYPE_ARMOS      ,   9,  5,   TYPE_ARMOS      ,  12,  5
        ; Formation 7
        !byte TYPE_PEAHAT     ,  10,  4,   TYPE_PEAHAT     ,   3,  7,   TYPE_PEAHAT     ,  15,  4,   TYPE_PEAHAT     ,   5,  2,   TYPE_PEAHAT     ,   7,  6,   TYPE_PEAHAT     ,  13,  4,   TYPE_ZORA       ,  11,  6,   TYPE_ZORA       ,  17,  7
        ; Formation 8
        !byte TYPE_PEAHAT     ,  10,  4,   TYPE_PEAHAT     ,   2,  4,   TYPE_PEAHAT     ,  16,  3,   TYPE_PEAHAT     ,   6,  4,   TYPE_PEAHAT     ,  12,  1,   TYPE_PEAHAT     ,   9,  2,   TYPE_ZORA       ,   8,  3,   TYPE_ZORA       ,  17,  7
        ; Formation 9
        !byte TYPE_PEAHAT     ,  10,  4,   TYPE_PEAHAT     ,   3,  2,   TYPE_PEAHAT     ,  16,  7,   TYPE_PEAHAT     ,  15,  2,   TYPE_PEAHAT     ,   7,  2,   TYPE_PEAHAT     ,  12,  7,   TYPE_ZORA       ,   8,  8,   TYPE_NONE       ,   0,  0
        ; Formation 10
        !byte TYPE_LEEVER_RED ,  10,  4,   TYPE_PEAHAT     ,   3,  7,   TYPE_LEEVER_RED ,  16,  7,   TYPE_PEAHAT     ,   5,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 11
        !byte TYPE_LEEVER_BLUE,  10,  4,   TYPE_PEAHAT     ,   3,  7,   TYPE_LEEVER_BLUE,  16,  7,   TYPE_PEAHAT     ,   5,  2,   TYPE_LEEVER_BLUE,  15,  2,   TYPE_PEAHAT     ,   7,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 12
        !byte TYPE_LEEVER_BLUE,  10,  4,   TYPE_PEAHAT     ,   3,  7,   TYPE_LEEVER_RED ,  16,  7,   TYPE_PEAHAT     ,   5,  2,   TYPE_LEEVER_BLUE,  15,  2,   TYPE_PEAHAT     ,   7,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 13
        !byte TYPE_TEKTITE_RED,   9,  7,   TYPE_TEKTITE_RED,   3,  2,   TYPE_TEKTITE_RED,  13,  2,   TYPE_TEKTITE_RED,   5,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 14
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  7,   TYPE_OCTO_RED   ,  16,  7,   TYPE_OCTO_BLUE  ,   4,  1,   TYPE_OCTO_RED   ,   7,  7,   TYPE_ZORA       ,  12,  3,   TYPE_ZORA       ,  17,  2,   TYPE_NONE       ,   0,  0
        ; Formation 15
        !byte TYPE_OCTO_BLUE  ,   8,  5,   TYPE_OCTO_BLUE  ,   3,  7,   TYPE_OCTO_BLUE  ,  10,  6,   TYPE_OCTO_BLUE  ,   7,  7,   TYPE_ZORA       ,  10,  4,   TYPE_ZORA       ,   2,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 16
        !byte TYPE_PEAHAT     ,   9,  3,   TYPE_PEAHAT     ,   4,  3,   TYPE_LYNEL_RED  ,  14,  5,   TYPE_LYNEL_BLUE ,   5,  7,   TYPE_LYNEL_RED  ,  13,  3,   TYPE_LYNEL_BLUE ,  12,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 17
        !byte TYPE_ARMOS      ,   3,  3,   TYPE_ARMOS      ,   5,  3,   TYPE_ARMOS      ,   7,  3,   TYPE_ARMOS      ,   3,  5,   TYPE_ARMOS      ,   5,  5,   TYPE_ARMOS      ,   7,  5,   TYPE_ZORA       ,  11,  6,   TYPE_ZORA       ,  17,  7
        ; Formation 18
        !byte TYPE_ZORA       ,   9,  6,   TYPE_ZORA       ,   2,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 19
        !byte TYPE_ZORA       ,  11,  4,   TYPE_ZORA       ,   2,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 20
        !byte TYPE_OCTO_RED   ,  11,  3,   TYPE_ZORA       ,  18,  3,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 21
        !byte TYPE_OCTO_BLUE  ,  10,  4,   TYPE_OCTO_RED   ,  16,  7,   TYPE_OCTO_RED   ,  15,  2,   TYPE_OCTO_RED   ,  12,  7,   TYPE_OCTO_RED   ,   9,  7,   TYPE_ZORA       ,   8,  4,   TYPE_ZORA       ,   2,  7,   TYPE_NONE       ,   0,  0
        ; Formation 22
        !byte TYPE_LEEVER_BLUE,  10,  4,   TYPE_PEAHAT     ,   4,  6,   TYPE_LEEVER_RED ,  16,  7,   TYPE_PEAHAT     ,   5,  2,   TYPE_LEEVER_BLUE,  15,  2,   TYPE_PEAHAT     ,   7,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 23
        !byte TYPE_LEEVER_BLUE,  10,  4,   TYPE_PEAHAT     ,   3,  7,   TYPE_LEEVER_BLUE,  15,  6,   TYPE_PEAHAT     ,   5,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 24
        !byte TYPE_OCTO_RED   ,  11,  3,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 25
        !byte TYPE_ARMOS      ,   7,  3,   TYPE_ARMOS      ,  10,  3,   TYPE_MOBLIN_BLUE,   3,  7,   TYPE_MOBLIN_BLUE,  16,  7,   TYPE_MOBLIN_BLUE,   4,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 26
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_OCTO_BLUE  ,   4,  1,   TYPE_OCTO_RED   ,  16,  7,   TYPE_OCTO_BLUE  ,   5,  7,   TYPE_OCTO_RED   ,   7,  2,   TYPE_ZORA       ,  12,  3,   TYPE_ZORA       ,  17,  2,   TYPE_NONE       ,   0,  0
        ; Formation 27
        !byte TYPE_OCTO_BLUE  ,   8,  4,   TYPE_ZORA       ,  10,  4,   TYPE_ZORA       ,   2,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
