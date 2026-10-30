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
        !byte 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 3, 3, 0, 0, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3

; Index de formation d'ennemis par salle (128 octets : $C196..$C215)
room_enemy_idx:
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 1, 2, 3, 0, 4, 5, 0, 0, 6, 7, 8, 9, 10, 11, 12, 13
        !byte 14, 15, 16, 17, 18, 19, 20, 18, 18, 21, 22, 23, 24, 25, 26, 27
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        !byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

; Salle (0, 4) - RLE compact (50 octets)
room_64:
        !byte 53, 176, 117, 176, 117, 224, 0, 53, 0, 8, 16, 8, 16, 8, 16, 8
        !byte 64, 53, 224, 0, 53, 0, 8, 16, 8, 16, 8, 16, 8, 64, 53, 224
        !byte 0, 53, 0, 8, 16, 8, 16, 8, 16, 8, 64, 69, 224, 229, 5, 1
        !byte 37, 255
; Salle (1, 4) - RLE compact (52 octets)
room_65:
        !byte 53, 176, 51, 53, 176, 51, 224, 0, 51, 64, 8, 16, 8, 16, 8, 16
        !byte 8, 0, 51, 224, 0, 51, 64, 8, 16, 8, 16, 8, 16, 8, 0, 51
        !byte 224, 0, 51, 64, 8, 16, 8, 16, 8, 16, 8, 0, 51, 224, 0, 51
        !byte 229, 5, 51, 255
; Salle (2, 4) - RLE compact (36 octets)
room_66:
        !byte 229, 229, 213, 176, 101, 48, 84, 48, 85, 16, 3, 0, 84, 0, 3, 16
        !byte 85, 48, 84, 48, 85, 16, 3, 0, 84, 0, 3, 16, 85, 208, 101, 176
        !byte 197, 16, 133, 255
; Salle (3, 4) - RLE compact (36 octets)
room_67:
        !byte 229, 229, 213, 176, 101, 48, 84, 48, 85, 16, 3, 0, 84, 0, 3, 16
        !byte 85, 48, 84, 48, 85, 16, 3, 0, 84, 0, 3, 16, 85, 208, 101, 176
        !byte 197, 16, 133, 255
; Salle (4, 4) - RLE compact (41 octets)
room_68:
        !byte 149, 0, 132, 85, 7, 37, 0, 132, 53, 96, 132, 37, 112, 132, 37, 16
        !byte 3, 0, 3, 32, 132, 37, 112, 132, 37, 16, 3, 0, 3, 32, 132, 37
        !byte 112, 132, 53, 96, 132, 133, 16, 132, 255
; Salle (5, 4) - RLE compact (52 octets)
room_69:
        !byte 36, 213, 84, 213, 84, 5, 176, 5, 84, 5, 16, 31, 0, 47, 0, 31
        !byte 0, 5, 84, 5, 16, 31, 0, 15, 7, 15, 0, 31, 0, 5, 84, 5
        !byte 176, 5, 84, 5, 176, 5, 84, 5, 176, 5, 84, 5, 176, 5, 84, 101
        !byte 1, 85, 36, 255
; Salle (6, 4) - RLE compact (22 octets)
room_70:
        !byte 228, 228, 228, 228, 228, 228, 228, 52, 10, 144, 132, 160, 132, 16, 131, 132
        !byte 16, 131, 132, 16, 131, 255
; Salle (7, 4) - RLE compact (15 octets)
room_71:
        !byte 228, 228, 228, 228, 228, 228, 148, 224, 224, 144, 227, 227, 227, 227, 255
; Salle (8, 4) - RLE compact (26 octets)
room_72:
        !byte 132, 16, 131, 132, 16, 131, 132, 80, 67, 132, 80, 67, 132, 80, 67, 224
        !byte 67, 224, 147, 144, 147, 144, 211, 16, 131, 255
; Salle (9, 4) - RLE compact (36 octets)
room_73:
        !byte 131, 16, 227, 35, 16, 195, 32, 19, 16, 195, 32, 19, 16, 195, 224, 0
        !byte 51, 0, 13, 208, 51, 224, 0, 51, 32, 19, 16, 195, 32, 19, 16, 227
        !byte 35, 16, 131, 255
; Salle (10, 4) - RLE compact (30 octets)
room_74:
        !byte 133, 16, 229, 37, 16, 21, 7, 165, 144, 133, 176, 53, 96, 3, 48, 3
        !byte 224, 224, 48, 3, 48, 3, 96, 53, 176, 133, 144, 229, 149, 255
; Salle (11, 4) - RLE compact (57 octets)
room_75:
        !byte 211, 16, 227, 35, 16, 99, 128, 19, 16, 99, 64, 3, 32, 19, 16, 51
        !byte 144, 3, 0, 19, 16, 51, 48, 3, 32, 3, 32, 19, 16, 51, 144, 3
        !byte 0, 19, 16, 99, 64, 3, 32, 19, 16, 99, 128, 19, 16, 99, 0, 3
        !byte 32, 3, 0, 3, 0, 19, 16, 51, 255
; Salle (12, 4) - RLE compact (39 octets)
room_76:
        !byte 133, 1, 229, 53, 1, 213, 48, 5, 1, 37, 16, 133, 48, 5, 1, 37
        !byte 16, 117, 64, 5, 1, 37, 16, 37, 16, 37, 224, 16, 37, 176, 37, 16
        !byte 53, 160, 133, 160, 229, 149, 255
; Salle (13, 4) - RLE compact (72 octets)
room_77:
        !byte 35, 0, 3, 0, 3, 0, 3, 16, 3, 0, 3, 0, 3, 0, 83, 0
        !byte 3, 0, 3, 0, 3, 16, 3, 0, 3, 0, 3, 0, 83, 208, 83, 64
        !byte 3, 48, 3, 32, 35, 48, 3, 0, 3, 48, 3, 32, 3, 176, 3, 48
        !byte 3, 144, 3, 0, 3, 48, 3, 32, 3, 48, 35, 64, 3, 48, 3, 32
        !byte 83, 208, 115, 0, 115, 0, 67, 255
; Salle (14, 4) - RLE compact (25 octets)
room_78:
        !byte 227, 227, 211, 176, 99, 208, 35, 96, 14, 48, 14, 48, 35, 224, 16, 35
        !byte 224, 16, 83, 208, 99, 176, 227, 131, 255
; Salle (15, 4) - RLE compact (35 octets)
room_79:
        !byte 101, 48, 132, 101, 48, 132, 85, 64, 132, 85, 64, 132, 85, 64, 132, 69
        !byte 80, 4, 9, 4, 9, 68, 53, 96, 132, 53, 96, 132, 69, 80, 132, 101
        !byte 48, 132, 255
; Salle (0, 5) - RLE compact (27 octets)
room_80:
        !byte 229, 5, 1, 229, 53, 1, 229, 53, 1, 229, 53, 1, 229, 53, 1, 101
        !byte 192, 101, 192, 101, 192, 101, 192, 101, 176, 53, 255
; Salle (1, 5) - RLE compact (38 octets)
room_81:
        !byte 227, 227, 211, 144, 131, 160, 131, 16, 3, 0, 3, 0, 3, 0, 3, 112
        !byte 35, 224, 16, 35, 16, 3, 0, 3, 0, 3, 0, 3, 112, 35, 160, 147
        !byte 144, 227, 35, 16, 83, 255
; Salle (2, 5) - RLE compact (29 octets)
room_82:
        !byte 131, 16, 227, 35, 16, 195, 224, 0, 51, 16, 211, 80, 211, 80, 211, 80
        !byte 227, 35, 16, 227, 35, 224, 0, 99, 16, 19, 64, 51, 255
; Salle (3, 5) - RLE compact (37 octets)
room_83:
        !byte 131, 16, 227, 35, 16, 131, 224, 0, 115, 192, 99, 48, 3, 160, 51, 112
        !byte 3, 96, 51, 48, 3, 160, 51, 192, 35, 224, 0, 147, 16, 3, 32, 3
        !byte 0, 3, 0, 51, 255
; Salle (4, 5) - RLE compact (37 octets)
room_84:
        !byte 131, 16, 132, 131, 16, 132, 51, 96, 132, 51, 32, 3, 32, 132, 160, 132
        !byte 96, 3, 224, 192, 53, 51, 32, 3, 112, 53, 51, 176, 53, 67, 16, 51
        !byte 16, 19, 0, 53, 255
; Salle (5, 5) - RLE compact (39 octets)
room_85:
        !byte 228, 228, 228, 68, 10, 228, 52, 10, 228, 52, 10, 132, 80, 10, 20, 10
        !byte 144, 53, 32, 20, 96, 117, 32, 20, 96, 117, 32, 20, 96, 117, 32, 20
        !byte 32, 5, 0, 5, 0, 53, 255
; Salle (6, 5) - RLE compact (30 octets)
room_86:
        !byte 132, 16, 131, 132, 16, 131, 132, 160, 132, 160, 132, 32, 3, 0, 19, 224
        !byte 128, 69, 96, 3, 0, 19, 48, 69, 224, 69, 224, 69, 227, 255
; Salle (7, 5) - RLE compact (41 octets)
room_87:
        !byte 227, 227, 147, 224, 208, 3, 0, 3, 32, 3, 0, 35, 224, 144, 3, 0
        !byte 3, 0, 3, 0, 3, 0, 3, 0, 3, 0, 35, 224, 208, 3, 0, 3
        !byte 32, 3, 0, 35, 224, 64, 227, 67, 255
; Salle (8, 5) - RLE compact (63 octets)
room_88:
        !byte 131, 16, 227, 35, 16, 131, 224, 16, 83, 0, 3, 32, 3, 16, 3, 0
        !byte 3, 32, 35, 224, 64, 35, 0, 3, 0, 3, 0, 3, 16, 3, 0, 3
        !byte 0, 3, 224, 128, 35, 0, 3, 32, 3, 16, 3, 0, 3, 32, 35, 224
        !byte 16, 115, 0, 3, 0, 3, 16, 3, 0, 3, 0, 3, 0, 35, 255
; Salle (9, 5) - RLE compact (27 octets)
room_89:
        !byte 131, 16, 227, 35, 16, 227, 35, 16, 227, 35, 16, 131, 224, 224, 224, 80
        !byte 132, 131, 16, 132, 131, 16, 132, 131, 16, 132, 255
; Salle (10, 5) - RLE compact (24 octets)
room_90:
        !byte 227, 227, 227, 224, 67, 224, 224, 3, 224, 128, 132, 80, 3, 48, 132, 160
        !byte 132, 160, 132, 48, 35, 0, 35, 255
; Salle (11, 5) - RLE compact (65 octets)
room_91:
        !byte 35, 0, 3, 32, 3, 0, 3, 0, 19, 16, 99, 0, 3, 32, 3, 0
        !byte 3, 0, 19, 16, 51, 224, 224, 16, 3, 48, 35, 48, 3, 32, 3, 0
        !byte 3, 80, 35, 176, 3, 48, 35, 48, 3, 32, 3, 0, 3, 80, 35, 176
        !byte 3, 48, 35, 224, 64, 35, 0, 3, 32, 3, 0, 3, 0, 19, 0, 67
        !byte 255
; Salle (12, 5) - RLE compact (26 octets)
room_92:
        !byte 227, 227, 147, 224, 227, 51, 0, 227, 51, 80, 211, 80, 211, 80, 211, 0
        !byte 67, 96, 99, 0, 163, 0, 99, 0, 67, 255
; Salle (13, 5) - RLE compact (35 octets)
room_93:
        !byte 67, 0, 115, 0, 147, 0, 115, 0, 147, 0, 115, 0, 147, 0, 115, 0
        !byte 67, 224, 224, 224, 224, 67, 0, 115, 0, 147, 0, 115, 0, 147, 0, 115
        !byte 0, 67, 255
; Salle (14, 5) - RLE compact (37 octets)
room_94:
        !byte 229, 213, 7, 213, 80, 53, 16, 101, 112, 21, 48, 37, 80, 3, 96, 3
        !byte 16, 37, 224, 16, 37, 80, 3, 96, 3, 16, 85, 112, 21, 48, 101, 80
        !byte 53, 16, 229, 133, 255
; Salle (15, 5) - RLE compact (35 octets)
room_95:
        !byte 101, 48, 132, 101, 48, 132, 85, 64, 132, 85, 64, 132, 85, 64, 132, 69
        !byte 80, 4, 9, 4, 9, 68, 53, 96, 132, 53, 96, 132, 69, 80, 132, 101
        !byte 48, 132, 255

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
        !byte TYPE_ARMOS      ,   7,  4,   TYPE_ARMOS      ,  12,  4,   TYPE_MOBLIN_BLUE,   3,  7,   TYPE_MOBLIN_BLUE,  16,  7,   TYPE_MOBLIN_BLUE,   5,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 13
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  6,   TYPE_OCTO_RED   ,   6,  2,   TYPE_OCTO_BLUE  ,   7,  7,   TYPE_OCTO_BLUE  ,  11,  7,   TYPE_ZORA       ,  12,  4,   TYPE_ZORA       ,  17,  7,   TYPE_NONE       ,   0,  0
        ; Formation 14
        !byte TYPE_LYNEL_RED  ,  10,  4,   TYPE_LYNEL_RED  ,   3,  7,   TYPE_LYNEL_RED  ,  16,  7,   TYPE_LYNEL_RED  ,   6,  4,   TYPE_LYNEL_RED  ,   8,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 15
        !byte TYPE_MOBLIN_BLUE,  10,  4,   TYPE_MOBLIN_BLUE,   3,  7,   TYPE_MOBLIN_BLUE,  16,  3,   TYPE_MOBLIN_BLUE,   5,  2,   TYPE_MOBLIN_BLUE,  14,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 16
        !byte TYPE_MOBLIN_BLUE,  10,  7,   TYPE_MOBLIN_RED ,   3,  2,   TYPE_MOBLIN_BLUE,  16,  7,   TYPE_MOBLIN_RED ,   4,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 17
        !byte TYPE_MOBLIN_BLUE,  10,  4,   TYPE_MOBLIN_BLUE,   3,  7,   TYPE_MOBLIN_RED ,  16,  7,   TYPE_MOBLIN_BLUE,   5,  2,   TYPE_MOBLIN_RED ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 18
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  7,   TYPE_OCTO_RED   ,  16,  7,   TYPE_OCTO_BLUE  ,   5,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 19
        !byte TYPE_OCTO_BLUE  ,  10,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 20
        !byte TYPE_OCTO_BLUE  ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  4,   TYPE_OCTO_BLUE  ,  16,  7,   TYPE_OCTO_BLUE  ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 21
        !byte TYPE_PEAHAT     ,  10,  4,   TYPE_PEAHAT     ,   3,  3,   TYPE_PEAHAT     ,  16,  3,   TYPE_PEAHAT     ,   6,  5,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 22
        !byte TYPE_OCTO_BLUE  ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  3,   TYPE_OCTO_BLUE  ,  16,  7,   TYPE_OCTO_BLUE  ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 23
        !byte TYPE_MOBLIN_BLUE,  10,  4,   TYPE_MOBLIN_RED ,   3,  7,   TYPE_MOBLIN_BLUE,  16,  7,   TYPE_MOBLIN_RED ,   5,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 24
        !byte TYPE_MOBLIN_BLUE,   5,  7,   TYPE_MOBLIN_BLUE,  16,  2,   TYPE_MOBLIN_BLUE,  16,  7,   TYPE_MOBLIN_BLUE,  16,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 25
        !byte TYPE_MOBLIN_BLUE,  10,  4,   TYPE_MOBLIN_BLUE,   3,  3,   TYPE_MOBLIN_BLUE,  16,  7,   TYPE_MOBLIN_BLUE,  16,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 26
        !byte TYPE_MOBLIN_BLUE,  10,  4,   TYPE_MOBLIN_BLUE,   3,  7,   TYPE_MOBLIN_BLUE,  16,  7,   TYPE_MOBLIN_BLUE,   5,  2,   TYPE_MOBLIN_BLUE,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Formation 27
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  6,   TYPE_OCTO_RED   ,   6,  2,   TYPE_OCTO_BLUE  ,   7,  7,   TYPE_OCTO_RED   ,  11,  7,   TYPE_ZORA       ,  12,  4,   TYPE_ZORA       ,  17,  7,   TYPE_NONE       ,   0,  0
