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
        !byte 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 3, 3, 0, 0, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 0, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3

; Index de formation d'ennemis par salle (128 octets : $C196..$C215)
room_enemy_idx:
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 0
        !byte 1, 1, 15, 0, 16, 17, 17, 18, 19, 0, 11, 20, 21, 22, 23, 24
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

; Salle (0, 2) - RLE compact (47 octets)
room_32:
        !byte 229, 229, 229, 230, 53, 6, 8, 22, 8, 22, 8, 22, 8, 70, 53, 230
        !byte 6, 53, 6, 8, 22, 8, 22, 8, 22, 8, 70, 53, 230, 6, 53, 6
        !byte 8, 22, 8, 22, 8, 22, 8, 70, 53, 230, 6, 53, 182, 53, 255
; Salle (1, 2) - RLE compact (48 octets)
room_33:
        !byte 229, 229, 149, 230, 6, 53, 70, 8, 22, 8, 22, 8, 22, 8, 6, 53
        !byte 230, 6, 53, 70, 8, 22, 8, 22, 8, 22, 8, 6, 53, 230, 6, 53
        !byte 70, 8, 22, 8, 22, 8, 22, 8, 6, 53, 230, 6, 117, 182, 53, 255
; Salle (2, 2) - RLE compact (32 octets)
room_34:
        !byte 229, 229, 213, 182, 117, 54, 53, 54, 117, 6, 45, 5, 23, 5, 45, 6
        !byte 117, 182, 117, 6, 45, 54, 45, 6, 117, 182, 117, 182, 197, 0, 149, 255
; Salle (3, 2) - RLE compact (47 octets)
room_35:
        !byte 229, 229, 213, 64, 53, 96, 37, 96, 21, 112, 37, 32, 13, 32, 21, 112
        !byte 37, 16, 13, 0, 13, 16, 21, 112, 37, 32, 13, 32, 21, 112, 37, 96
        !byte 21, 112, 37, 3, 64, 3, 21, 3, 96, 117, 0, 85, 0, 53, 255
; Salle (4, 2) - RLE compact (38 octets)
room_36:
        !byte 181, 0, 229, 53, 0, 101, 64, 21, 224, 224, 96, 13, 16, 13, 16, 13
        !byte 16, 13, 16, 13, 224, 176, 13, 16, 13, 16, 13, 16, 13, 16, 13, 224
        !byte 192, 19, 192, 229, 69, 255
; Salle (5, 2) - RLE compact (50 octets)
room_37:
        !byte 69, 0, 133, 0, 133, 0, 85, 7, 21, 0, 53, 224, 0, 53, 224, 16
        !byte 37, 48, 13, 16, 13, 16, 13, 16, 13, 32, 37, 224, 16, 37, 48, 13
        !byte 16, 13, 16, 13, 16, 13, 32, 37, 224, 16, 37, 224, 0, 3, 133, 0
        !byte 197, 255
; Salle (6, 2) - RLE compact (36 octets)
room_38:
        !byte 229, 229, 213, 32, 53, 0, 165, 64, 21, 16, 165, 224, 16, 37, 224, 16
        !byte 37, 112, 132, 37, 64, 19, 0, 132, 37, 3, 32, 3, 21, 3, 132, 53
        !byte 16, 69, 132, 255
; Salle (7, 2) - RLE compact (29 octets)
room_39:
        !byte 117, 4, 48, 229, 4, 48, 229, 4, 48, 37, 48, 117, 4, 48, 37, 176
        !byte 4, 224, 48, 4, 9, 144, 228, 228, 228, 228, 228, 68, 255
; Salle (8, 2) - RLE compact (35 octets)
room_40:
        !byte 227, 227, 147, 224, 0, 3, 224, 0, 3, 224, 80, 3, 224, 16, 3, 80
        !byte 52, 69, 80, 3, 48, 52, 67, 48, 3, 80, 52, 67, 96, 3, 32, 132
        !byte 16, 131, 255
; Salle (9, 2) - RLE compact (16 octets)
room_41:
        !byte 229, 229, 149, 230, 230, 230, 230, 230, 230, 230, 230, 230, 70, 229, 69, 255
; Salle (10, 2) - RLE compact (17 octets)
room_42:
        !byte 229, 229, 149, 230, 230, 230, 230, 230, 230, 230, 230, 230, 70, 53, 198, 37
        !byte 255
; Salle (11, 2) - RLE compact (18 octets)
room_43:
        !byte 229, 229, 12, 133, 230, 230, 230, 230, 230, 230, 230, 230, 230, 70, 37, 198
        !byte 53, 255
; Salle (12, 2) - RLE compact (31 octets)
room_44:
        !byte 69, 0, 229, 53, 0, 213, 208, 85, 112, 3, 21, 3, 16, 85, 96, 3
        !byte 53, 3, 0, 85, 96, 85, 208, 85, 224, 224, 224, 16, 229, 69, 255
; Salle (13, 2) - RLE compact (35 octets)
room_45:
        !byte 53, 0, 53, 16, 132, 53, 0, 53, 16, 132, 53, 0, 5, 64, 132, 53
        !byte 0, 5, 64, 132, 53, 0, 5, 64, 132, 224, 224, 224, 224, 224, 64, 133
        !byte 16, 133, 255
; Salle (14, 2) - RLE compact (20 octets)
room_46:
        !byte 228, 228, 228, 228, 228, 228, 148, 144, 9, 132, 160, 132, 160, 132, 160, 132
        !byte 53, 96, 132, 255
; Salle (15, 2) - RLE compact (36 octets)
room_47:
        !byte 229, 229, 197, 182, 117, 6, 21, 6, 5, 4, 5, 6, 21, 22, 117, 6
        !byte 21, 6, 5, 7, 5, 6, 21, 22, 117, 182, 117, 182, 117, 182, 117, 182
        !byte 197, 0, 165, 255
; Salle (0, 3) - RLE compact (50 octets)
room_48:
        !byte 53, 182, 117, 182, 117, 230, 6, 53, 6, 8, 22, 8, 22, 8, 22, 8
        !byte 70, 53, 230, 6, 53, 6, 8, 22, 8, 22, 8, 22, 8, 70, 53, 230
        !byte 6, 53, 6, 8, 22, 8, 22, 8, 22, 8, 70, 53, 230, 6, 53, 182
        !byte 53, 255
; Salle (1, 3) - RLE compact (44 octets)
room_49:
        !byte 53, 182, 117, 182, 53, 230, 6, 53, 70, 8, 22, 8, 22, 8, 22, 8
        !byte 6, 53, 230, 150, 8, 22, 8, 22, 8, 22, 8, 230, 230, 8, 22, 8
        !byte 22, 8, 22, 8, 6, 53, 230, 6, 117, 182, 53, 255
; Salle (2, 3) - RLE compact (35 octets)
room_50:
        !byte 133, 0, 229, 53, 0, 229, 53, 0, 5, 16, 165, 16, 37, 0, 5, 32
        !byte 85, 96, 5, 12, 0, 5, 48, 69, 224, 224, 64, 131, 160, 133, 3, 144
        !byte 229, 149, 255
; Salle (3, 3) - RLE compact (47 octets)
room_51:
        !byte 117, 0, 85, 0, 181, 0, 85, 0, 117, 182, 117, 182, 117, 6, 13, 6
        !byte 13, 6, 13, 6, 13, 6, 13, 22, 53, 48, 182, 53, 51, 6, 13, 6
        !byte 13, 6, 13, 6, 13, 6, 13, 22, 117, 182, 117, 182, 229, 133, 255
; Salle (4, 3) - RLE compact (36 octets)
room_52:
        !byte 229, 229, 213, 176, 101, 192, 101, 0, 13, 0, 13, 0, 13, 112, 85, 208
        !byte 85, 0, 13, 0, 13, 0, 13, 16, 132, 37, 112, 132, 37, 3, 96, 132
        !byte 149, 0, 132, 255
; Salle (5, 3) - RLE compact (23 octets)
room_53:
        !byte 85, 0, 229, 53, 0, 229, 53, 0, 229, 53, 0, 229, 53, 208, 85, 208
        !byte 228, 228, 228, 228, 228, 68, 255
; Salle (6, 3) - RLE compact (26 octets)
room_54:
        !byte 53, 16, 69, 132, 53, 16, 69, 132, 53, 16, 69, 132, 53, 16, 69, 132
        !byte 160, 132, 160, 228, 228, 228, 228, 228, 212, 255
; Salle (7, 3) - RLE compact (58 octets)
room_55:
        !byte 36, 213, 84, 213, 84, 5, 176, 5, 84, 5, 0, 17, 0, 33, 0, 17
        !byte 16, 5, 84, 5, 0, 19, 0, 3, 7, 3, 0, 19, 16, 5, 84, 5
        !byte 192, 41, 36, 5, 16, 17, 32, 17, 32, 3, 84, 5, 16, 19, 32, 19
        !byte 32, 5, 84, 5, 176, 5, 84, 213, 36, 255
; Salle (8, 3) - RLE compact (40 octets)
room_56:
        !byte 132, 16, 131, 132, 12, 0, 131, 132, 32, 3, 48, 35, 132, 112, 35, 132
        !byte 64, 3, 16, 35, 137, 112, 35, 132, 64, 3, 16, 35, 132, 112, 35, 132
        !byte 32, 3, 48, 35, 132, 16, 131, 255
; Salle (9, 3) - RLE compact (38 octets)
room_57:
        !byte 229, 229, 213, 176, 101, 48, 85, 48, 85, 16, 3, 0, 83, 0, 3, 16
        !byte 85, 48, 83, 48, 85, 16, 3, 0, 83, 0, 3, 16, 85, 208, 85, 3
        !byte 176, 3, 181, 16, 133, 255
; Salle (10, 3) - RLE compact (30 octets)
room_58:
        !byte 53, 198, 101, 198, 101, 230, 6, 37, 12, 230, 6, 53, 230, 6, 53, 230
        !byte 6, 53, 230, 6, 53, 230, 6, 53, 230, 6, 133, 22, 133, 255
; Salle (11, 3) - RLE compact (30 octets)
room_59:
        !byte 37, 198, 101, 198, 53, 230, 6, 53, 230, 6, 53, 230, 6, 53, 230, 6
        !byte 53, 230, 6, 53, 230, 6, 53, 230, 6, 229, 37, 22, 53, 255
; Salle (12, 3) - RLE compact (43 octets)
room_60:
        !byte 229, 229, 229, 160, 117, 48, 35, 80, 85, 16, 3, 0, 3, 5, 7, 5
        !byte 3, 0, 3, 32, 85, 208, 85, 16, 3, 0, 3, 32, 3, 0, 3, 32
        !byte 85, 3, 192, 101, 3, 160, 3, 181, 0, 149, 255
; Salle (13, 3) - RLE compact (61 octets)
room_61:
        !byte 131, 16, 227, 35, 16, 179, 208, 83, 0, 3, 0, 3, 80, 3, 32, 83
        !byte 64, 3, 16, 3, 32, 3, 0, 83, 0, 3, 0, 3, 80, 3, 32, 83
        !byte 176, 3, 0, 83, 0, 3, 0, 3, 80, 3, 32, 83, 208, 83, 0, 3
        !byte 0, 3, 0, 3, 16, 3, 0, 3, 0, 3, 0, 35, 255
; Salle (14, 3) - RLE compact (30 octets)
room_62:
        !byte 53, 96, 132, 53, 96, 132, 53, 96, 132, 53, 96, 132, 53, 96, 132, 53
        !byte 224, 0, 53, 224, 0, 53, 224, 0, 53, 3, 224, 229, 69, 255
; Salle (15, 3) - RLE compact (23 octets)
room_63:
        !byte 116, 0, 228, 228, 228, 228, 228, 52, 9, 164, 144, 9, 132, 160, 132, 160
        !byte 132, 160, 132, 101, 48, 132, 255

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

; Formations d'ennemis dédupliquées (25 formations x 24 octets)
map_enemies:
        ; Formation 0
        !byte TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 1
        !byte TYPE_GHINI      ,  10,  4,   TYPE_GHINI      ,   3,  7,   TYPE_GHINI      ,  16,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 2
        !byte TYPE_LYNEL_RED  ,   9,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 3
        !byte TYPE_LYNEL_RED  ,   9,  4,   TYPE_LYNEL_RED  ,  16,  7,   TYPE_LYNEL_RED  ,   3,  7,   TYPE_LYNEL_RED  ,  14,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 4
        !byte TYPE_ARMOS      ,   2,  3,   TYPE_ARMOS      ,   6,  3,   TYPE_ARMOS      ,  10,  3,   TYPE_ARMOS      ,  14,  3,   TYPE_ARMOS      ,   2,  5,   TYPE_ARMOS      ,   6,  5,   TYPE_ARMOS      ,  10,  5,   TYPE_ARMOS      ,  14,  5
        ; Formation 5
        !byte TYPE_ARMOS      ,   3,  3,   TYPE_ARMOS      ,   7,  3,   TYPE_ARMOS      ,  11,  3,   TYPE_ARMOS      ,  15,  3,   TYPE_ARMOS      ,   3,  5,   TYPE_ARMOS      ,   7,  5,   TYPE_ARMOS      ,  11,  5,   TYPE_ARMOS      ,  15,  5
        ; Formation 6
        !byte TYPE_PEAHAT     ,  10,  4,   TYPE_PEAHAT     ,   3,  7,   TYPE_PEAHAT     ,  16,  3,   TYPE_PEAHAT     ,   5,  2,   TYPE_PEAHAT     ,   7,  6,   TYPE_PEAHAT     ,  13,  4,   TYPE_ZORA       ,  12,  5,   TYPE_ZORA       ,  17,  7
        ; Formation 7
        !byte TYPE_PEAHAT     ,  10,  4,   TYPE_PEAHAT     ,   3,  3,   TYPE_PEAHAT     ,  16,  3,   TYPE_PEAHAT     ,   7,  3,   TYPE_PEAHAT     ,  13,  2,   TYPE_PEAHAT     ,   9,  2,   TYPE_ZORA       ,   9,  4,   TYPE_ZORA       ,  17,  7
        ; Formation 8
        !byte TYPE_PEAHAT     ,  10,  4,   TYPE_PEAHAT     ,   3,  2,   TYPE_PEAHAT     ,  16,  7,   TYPE_PEAHAT     ,  16,  2,   TYPE_PEAHAT     ,   7,  2,   TYPE_PEAHAT     ,  12,  7,   TYPE_ZORA       ,   8,  8,   TYPE_NONE       ,   0,  0
        ; Formation 9
        !byte TYPE_LEEVER_RED ,  10,  4,   TYPE_PEAHAT     ,   3,  7,   TYPE_LEEVER_RED ,  16,  7,   TYPE_PEAHAT     ,   5,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 10
        !byte TYPE_LEEVER_BLUE,  10,  4,   TYPE_PEAHAT     ,   3,  7,   TYPE_LEEVER_BLUE,  16,  7,   TYPE_PEAHAT     ,   5,  2,   TYPE_LEEVER_BLUE,  15,  2,   TYPE_PEAHAT     ,   7,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 11
        !byte TYPE_LEEVER_BLUE,  10,  4,   TYPE_PEAHAT     ,   3,  7,   TYPE_LEEVER_RED ,  16,  7,   TYPE_PEAHAT     ,   5,  2,   TYPE_LEEVER_BLUE,  15,  2,   TYPE_PEAHAT     ,   7,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 12
        !byte TYPE_TEKTITE_RED,  10,  6,   TYPE_TEKTITE_RED,   3,  2,   TYPE_TEKTITE_RED,  15,  2,   TYPE_TEKTITE_RED,   5,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 13
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  7,   TYPE_OCTO_RED   ,  16,  7,   TYPE_OCTO_BLUE  ,   5,  2,   TYPE_OCTO_RED   ,   7,  7,   TYPE_ZORA       ,  12,  3,   TYPE_ZORA       ,  17,  2,   TYPE_NONE       ,   0,  0
        ; Formation 14
        !byte TYPE_OCTO_BLUE  ,   9,  4,   TYPE_OCTO_BLUE  ,   3,  7,   TYPE_OCTO_BLUE  ,  11,  7,   TYPE_OCTO_BLUE  ,   7,  7,   TYPE_ZORA       ,  10,  4,   TYPE_ZORA       ,   2,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 15
        !byte TYPE_PEAHAT     ,  10,  4,   TYPE_PEAHAT     ,   3,  2,   TYPE_LYNEL_RED  ,  16,  7,   TYPE_LYNEL_BLUE ,   5,  7,   TYPE_LYNEL_RED  ,  15,  2,   TYPE_LYNEL_BLUE ,  12,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 16
        !byte TYPE_LEEVER_BLUE,  10,  4,   TYPE_LEEVER_BLUE,   3,  7,   TYPE_LEEVER_BLUE,  16,  2,   TYPE_LEEVER_BLUE,   5,  2,   TYPE_ZORA       ,  12,  5,   TYPE_ZORA       ,  17,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 17
        !byte TYPE_ZORA       ,  10,  5,   TYPE_ZORA       ,   2,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 18
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_ZORA       ,  19,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 19
        !byte TYPE_OCTO_BLUE  ,  10,  4,   TYPE_OCTO_RED   ,  16,  7,   TYPE_OCTO_RED   ,  15,  2,   TYPE_OCTO_RED   ,  12,  7,   TYPE_OCTO_RED   ,   9,  7,   TYPE_ZORA       ,   8,  4,   TYPE_ZORA       ,   2,  7,   TYPE_NONE       ,   0,  0
        ; Formation 20
        !byte TYPE_LEEVER_BLUE,  10,  4,   TYPE_PEAHAT     ,   3,  7,   TYPE_LEEVER_BLUE,  16,  7,   TYPE_PEAHAT     ,   5,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 21
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 22
        !byte TYPE_MOBLIN_BLUE,  10,  4,   TYPE_MOBLIN_BLUE,   3,  7,   TYPE_MOBLIN_BLUE,  16,  7,   TYPE_MOBLIN_BLUE,   4,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 23
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  2,   TYPE_OCTO_RED   ,  16,  7,   TYPE_OCTO_BLUE  ,   5,  7,   TYPE_OCTO_RED   ,   7,  2,   TYPE_ZORA       ,  12,  3,   TYPE_ZORA       ,  17,  2,   TYPE_NONE       ,   0,  0
        ; Formation 24
        !byte TYPE_OCTO_BLUE  ,   9,  4,   TYPE_ZORA       ,  10,  4,   TYPE_ZORA       ,   2,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
