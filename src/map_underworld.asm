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

; Salle Souterraine (0, 0) - RLE compact (30 octets)
u_room_00:
        !byte 165, 136, 13, 136, 13, 136, 13, 136, 13, 64, 6, 56, 13, 64, 6, 56
        !byte 13, 64, 6, 56, 13, 64, 6, 56, 69, 0, 14, 0, 61, 255
; Salle Souterraine (1, 0) - RLE compact (42 octets)
u_room_01:
        !byte 165, 8, 11, 72, 11, 8, 13, 8, 11, 24, 15, 24, 11, 8, 13, 56
        !byte 15, 56, 13, 136, 13, 136, 13, 8, 11, 72, 11, 8, 13, 8, 11, 72
        !byte 11, 8, 13, 136, 69, 0, 14, 0, 61, 255
; Salle Souterraine (2, 0) - RLE compact (44 octets)
u_room_02:
        !byte 165, 60, 8, 60, 13, 60, 8, 60, 13, 16, 14, 56, 14, 16, 13, 16
        !byte 14, 56, 14, 16, 13, 16, 94, 16, 13, 16, 14, 56, 14, 16, 13, 16
        !byte 14, 56, 14, 16, 13, 60, 8, 60, 69, 24, 61, 255
; Salle Souterraine (0, 1) - RLE compact (44 octets)
u_room_03:
        !byte 61, 24, 69, 8, 13, 72, 13, 8, 13, 8, 13, 72, 13, 8, 13, 40
        !byte 45, 40, 13, 40, 45, 40, 13, 40, 45, 40, 13, 8, 13, 72, 13, 8
        !byte 13, 8, 13, 72, 13, 8, 13, 136, 69, 24, 61, 255
; Salle Souterraine (1, 1) - RLE compact (40 octets)
u_room_04:
        !byte 61, 24, 69, 8, 11, 72, 11, 8, 13, 8, 11, 72, 11, 8, 13, 136
        !byte 5, 24, 94, 56, 94, 24, 5, 136, 13, 8, 11, 72, 11, 8, 13, 8
        !byte 11, 72, 11, 8, 69, 24, 61, 255
; Salle Souterraine (2, 1) - RLE compact (44 octets)
u_room_05:
        !byte 61, 24, 69, 140, 13, 12, 8, 76, 8, 12, 13, 12, 8, 76, 8, 12
        !byte 5, 24, 30, 24, 30, 56, 30, 24, 30, 24, 5, 12, 8, 76, 8, 12
        !byte 13, 12, 8, 76, 8, 12, 13, 140, 69, 24, 61, 255
; Salle Souterraine (0, 2) - RLE compact (52 octets)
u_room_06:
        !byte 61, 24, 69, 8, 13, 8, 13, 8, 13, 8, 13, 8, 13, 8, 13, 8
        !byte 13, 8, 13, 8, 13, 8, 13, 136, 13, 136, 13, 8, 13, 8, 13, 8
        !byte 13, 8, 13, 8, 13, 8, 13, 8, 13, 8, 13, 8, 13, 8, 13, 136
        !byte 13, 136, 165, 255
; Salle Souterraine (1, 2) - RLE compact (36 octets)
u_room_07:
        !byte 61, 24, 69, 8, 11, 72, 11, 8, 13, 8, 11, 72, 11, 8, 13, 136
        !byte 13, 136, 13, 136, 13, 136, 13, 8, 11, 72, 11, 8, 13, 8, 11, 72
        !byte 11, 8, 165, 255
; Salle Souterraine (2, 2) - RLE compact (36 octets)
u_room_08:
        !byte 61, 24, 69, 136, 13, 40, 45, 40, 13, 40, 5, 6, 15, 6, 5, 40
        !byte 13, 40, 5, 6, 15, 6, 5, 40, 13, 40, 45, 40, 13, 136, 13, 136
        !byte 13, 136, 165, 255
