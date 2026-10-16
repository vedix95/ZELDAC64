; GENERE par tools/tilegen.py depuis assets/tiles.txt et assets/underworld.txt - ne pas editer.
!cpu 6510
* = $a000

map_rooms_w:    !byte 3
map_rooms_h:    !byte 3
map_rooms_cnt:  !byte 9
map_bg_col:     !byte 0   ; noir
map_mc1_col:    !byte 9   ; marron
map_mc2_col:    !byte 12  ; gris

; Table des offsets ry * map_rooms_w (16 octets : $A006..$A015)
map_row_offset:
        !byte 0, 3, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

; Tables des pointeurs (128 octets LO : $A016..$A095 / 128 octets HI : $A096..$A115)
room_tbl_lo:
        !byte <u_room_00, <u_room_01, <u_room_02, <u_room_03, <u_room_04, <u_room_05, <u_room_06, <u_room_07, <u_room_08
        !fill 119, 0
room_tbl_hi:
        !byte >u_room_00, >u_room_01, >u_room_02, >u_room_03, >u_room_04, >u_room_05, >u_room_06, >u_room_07, >u_room_08
        !fill 119, 0

; Table des palettes régionales (128 octets à 0 pour les donjons : $A116..$A195)
room_zone_palette:
        !fill 128, 0

; Salle Souterraine (0, 0) - RLE compact (35 octets)
u_room_00:
        !byte 229, 85, 224, 32, 21, 224, 32, 21, 224, 32, 21, 224, 32, 21, 128, 6
        !byte 112, 21, 128, 6, 112, 21, 128, 6, 112, 21, 128, 6, 112, 133, 0, 22
        !byte 0, 117, 255
; Salle Souterraine (1, 0) - RLE compact (46 octets)
u_room_01:
        !byte 229, 85, 16, 19, 144, 19, 16, 21, 16, 19, 48, 23, 48, 19, 16, 21
        !byte 112, 23, 112, 21, 224, 32, 21, 224, 32, 21, 16, 19, 144, 19, 16, 21
        !byte 16, 19, 144, 19, 16, 21, 224, 32, 133, 0, 22, 0, 117, 255
; Salle Souterraine (2, 0) - RLE compact (45 octets)
u_room_02:
        !byte 229, 85, 116, 16, 116, 21, 116, 16, 116, 21, 32, 22, 112, 22, 32, 21
        !byte 32, 22, 112, 22, 32, 21, 32, 182, 32, 21, 32, 22, 112, 22, 32, 21
        !byte 32, 22, 112, 22, 32, 21, 116, 16, 116, 133, 48, 117, 255
; Salle Souterraine (0, 1) - RLE compact (45 octets)
u_room_03:
        !byte 117, 48, 133, 16, 21, 144, 21, 16, 21, 16, 21, 144, 21, 16, 21, 80
        !byte 85, 80, 21, 80, 85, 80, 21, 80, 85, 80, 21, 16, 21, 144, 21, 16
        !byte 21, 16, 21, 144, 21, 16, 21, 224, 32, 133, 48, 117, 255
; Salle Souterraine (1, 1) - RLE compact (42 octets)
u_room_04:
        !byte 117, 48, 133, 16, 19, 144, 19, 16, 21, 16, 19, 144, 19, 16, 21, 224
        !byte 32, 5, 48, 182, 112, 182, 48, 5, 224, 32, 21, 16, 19, 144, 19, 16
        !byte 21, 16, 19, 144, 19, 16, 133, 48, 117, 255
; Salle Souterraine (2, 1) - RLE compact (46 octets)
u_room_05:
        !byte 117, 48, 133, 228, 36, 21, 20, 16, 148, 16, 20, 21, 20, 16, 148, 16
        !byte 20, 5, 48, 54, 48, 54, 112, 54, 48, 54, 48, 5, 20, 16, 148, 16
        !byte 20, 21, 20, 16, 148, 16, 20, 21, 228, 36, 133, 48, 117, 255
; Salle Souterraine (0, 2) - RLE compact (57 octets)
u_room_06:
        !byte 117, 48, 133, 16, 21, 16, 21, 16, 21, 16, 21, 16, 21, 16, 21, 16
        !byte 21, 16, 21, 16, 21, 16, 21, 224, 32, 21, 224, 32, 21, 16, 21, 16
        !byte 21, 16, 21, 16, 21, 16, 21, 16, 21, 16, 21, 16, 21, 16, 21, 16
        !byte 21, 224, 32, 21, 224, 32, 229, 85, 255
; Salle Souterraine (1, 2) - RLE compact (41 octets)
u_room_07:
        !byte 117, 48, 133, 16, 19, 144, 19, 16, 21, 16, 19, 144, 19, 16, 21, 224
        !byte 32, 21, 224, 32, 21, 224, 32, 21, 224, 32, 21, 16, 19, 144, 19, 16
        !byte 21, 16, 19, 144, 19, 16, 229, 85, 255
; Salle Souterraine (2, 2) - RLE compact (41 octets)
u_room_08:
        !byte 117, 48, 133, 224, 32, 21, 80, 85, 80, 21, 80, 5, 6, 23, 6, 5
        !byte 80, 21, 80, 5, 6, 23, 6, 5, 80, 21, 80, 85, 80, 21, 224, 32
        !byte 21, 224, 32, 21, 224, 32, 229, 85, 255
