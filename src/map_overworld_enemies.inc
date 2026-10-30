!source "src/enemy_types.inc"

world_enemies:
map_enemies:
        ; Salle   0 : ( 0,  0) A-1
        !byte TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle   1 : ( 1,  0) B-1
        !byte TYPE_LYNEL_RED  ,  10,  4,   TYPE_LYNEL_RED  ,   3,  7,   TYPE_LYNEL_RED  ,  16,  7,   TYPE_LYNEL_RED  ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle   2 : ( 2,  0) C-1
        !byte TYPE_LYNEL_RED  ,  10,  4,   TYPE_LYNEL_RED  ,   3,  4,   TYPE_LYNEL_RED  ,  16,  7,   TYPE_LYNEL_RED  ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle   3 : ( 3,  0) D-1
        !byte TYPE_TEKTITE_RED,  10,  4,   TYPE_TEKTITE_RED,   3,  7,   TYPE_TEKTITE_RED,   4,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle   4 : ( 4,  0) E-1
        !byte TYPE_LYNEL_BLUE ,  10,  4,   TYPE_LYNEL_BLUE ,   3,  7,   TYPE_LYNEL_BLUE ,  16,  7,   TYPE_LYNEL_BLUE ,  15,  2,   TYPE_LYNEL_BLUE ,   6,  4,   TYPE_LYNEL_BLUE ,  12,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle   5 : ( 5,  0) F-1
        !byte TYPE_LYNEL_BLUE ,  10,  4,   TYPE_LEEVER_BLUE,   3,  2,   TYPE_LYNEL_RED  ,  16,  7,   TYPE_LYNEL_BLUE ,   5,  7,   TYPE_LEEVER_RED ,  16,  2,   TYPE_LYNEL_RED  ,  12,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle   6 : ( 6,  0) G-1
        !byte TYPE_PEAHAT     ,  10,  4,   TYPE_PEAHAT     ,   3,  4,   TYPE_LYNEL_RED  ,  16,  4,   TYPE_LYNEL_BLUE ,   7,  2,   TYPE_LYNEL_RED  ,   7,  6,   TYPE_LYNEL_BLUE ,  11,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle   7 : ( 7,  0) H-1
        !byte TYPE_LYNEL_RED  ,  10,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle   8 : ( 8,  0) I-1
        !byte TYPE_TEKTITE_RED,  10,  4,   TYPE_TEKTITE_RED,   3,  4,   TYPE_TEKTITE_RED,  16,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle   9 : ( 9,  0) J-1
        !byte TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  10 : (10,  0) K-1
        !byte TYPE_LYNEL_BLUE ,  10,  6,   TYPE_ZORA       ,  10,  4,   TYPE_ZORA       ,   4,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  11 : (11,  0) L-1
        !byte TYPE_LEEVER_RED ,  10,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  12 : (12,  0) M-1
        !byte TYPE_TEKTITE_RED,  10,  4,   TYPE_TEKTITE_RED,  16,  3,   TYPE_TEKTITE_RED,  14,  7,   TYPE_TEKTITE_RED,   6,  4,   TYPE_TEKTITE_RED,  13,  2,   TYPE_TEKTITE_RED,  10,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  13 : (13,  0) N-1
        !byte TYPE_TEKTITE_RED,  10,  4,   TYPE_TEKTITE_RED,   3,  2,   TYPE_TEKTITE_RED,  16,  7,   TYPE_TEKTITE_RED,   6,  6,   TYPE_TEKTITE_RED,  14,  3,   TYPE_TEKTITE_RED,   7,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  14 : (14,  0) O-1
        !byte TYPE_ZORA       ,  13,  4,   TYPE_ZORA       ,  17,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  15 : (15,  0) P-1
        !byte TYPE_ZORA       ,  19,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  16 : ( 0,  1) A-2
        !byte TYPE_LYNEL_BLUE ,  10,  3,   TYPE_LYNEL_BLUE ,   3,  6,   TYPE_LYNEL_BLUE ,  16,  7,   TYPE_LYNEL_BLUE ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  17 : ( 1,  1) B-2
        !byte TYPE_PEAHAT     ,  10,  3,   TYPE_PEAHAT     ,   3,  7,   TYPE_LYNEL_RED  ,  16,  7,   TYPE_LYNEL_BLUE ,   5,  2,   TYPE_LYNEL_RED  ,  15,  2,   TYPE_LYNEL_BLUE ,   8,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  18 : ( 2,  1) C-2
        !byte TYPE_LYNEL_BLUE ,  10,  4,   TYPE_LYNEL_BLUE ,   3,  7,   TYPE_LYNEL_BLUE ,  16,  7,   TYPE_LYNEL_BLUE ,  15,  2,   TYPE_LYNEL_BLUE ,   6,  4,   TYPE_LYNEL_BLUE ,   8,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  19 : ( 3,  1) D-2
        !byte TYPE_LYNEL_BLUE ,  10,  4,   TYPE_LYNEL_RED  ,   3,  7,   TYPE_LYNEL_BLUE ,  16,  7,   TYPE_LYNEL_RED  ,   4,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  20 : ( 4,  1) E-2
        !byte TYPE_LYNEL_RED  ,  10,  4,   TYPE_LYNEL_RED  ,   3,  7,   TYPE_LYNEL_RED  ,  16,  7,   TYPE_LYNEL_RED  ,   5,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  21 : ( 5,  1) F-2
        !byte TYPE_PEAHAT     ,  10,  4,   TYPE_PEAHAT     ,   3,  6,   TYPE_LYNEL_RED  ,  16,  7,   TYPE_LYNEL_BLUE ,  15,  2,   TYPE_LYNEL_RED  ,   7,  6,   TYPE_LYNEL_BLUE ,  12,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  22 : ( 6,  1) G-2
        !byte TYPE_TEKTITE_RED,  10,  4,   TYPE_TEKTITE_RED,   3,  7,   TYPE_TEKTITE_RED,  16,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  23 : ( 7,  1) H-2
        !byte TYPE_TEKTITE_RED,  10,  4,   TYPE_TEKTITE_RED,   3,  7,   TYPE_TEKTITE_RED,  16,  7,   TYPE_ZORA       ,  10,  3,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  24 : ( 8,  1) I-2
        !byte TYPE_TEKTITE_RED,  10,  4,   TYPE_TEKTITE_RED,   3,  7,   TYPE_TEKTITE_RED,  16,  5,   TYPE_ZORA       ,  10,  3,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  25 : ( 9,  1) J-2
        !byte TYPE_TEKTITE_RED,  10,  4,   TYPE_TEKTITE_RED,   3,  5,   TYPE_TEKTITE_RED,  16,  5,   TYPE_ZORA       ,  10,  3,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  26 : (10,  1) K-2
        !byte TYPE_TEKTITE_RED,  10,  4,   TYPE_TEKTITE_RED,   3,  5,   TYPE_TEKTITE_RED,  16,  7,   TYPE_TEKTITE_RED,  12,  7,   TYPE_TEKTITE_RED,  14,  4,   TYPE_TEKTITE_RED,   7,  5,   TYPE_ZORA       ,   8,  2,   TYPE_NONE       ,   0,  0
        ; Salle  27 : (11,  1) L-2
        !byte TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  28 : (12,  1) M-2
        !byte TYPE_ARMOS      ,   9,  4,   TYPE_ARMOS      ,  11,  4,   TYPE_ARMOS      ,  13,  4,   TYPE_ARMOS      ,  15,  4,   TYPE_ARMOS      ,   9,  6,   TYPE_ARMOS      ,  11,  6,   TYPE_ARMOS      ,  13,  6,   TYPE_ARMOS      ,  15,  6
        ; Salle  29 : (13,  1) N-2
        !byte TYPE_PEAHAT     ,  10,  4,   TYPE_PEAHAT     ,   3,  7,   TYPE_PEAHAT     ,  16,  3,   TYPE_PEAHAT     ,   5,  2,   TYPE_PEAHAT     ,   9,  7,   TYPE_PEAHAT     ,  13,  4,   TYPE_ZORA       ,  12,  5,   TYPE_ZORA       ,  17,  7
        ; Salle  30 : (14,  1) O-2
        !byte TYPE_TEKTITE_RED,  10,  4,   TYPE_TEKTITE_RED,   3,  3,   TYPE_TEKTITE_RED,  16,  7,   TYPE_TEKTITE_RED,  15,  2,   TYPE_TEKTITE_RED,  12,  7,   TYPE_TEKTITE_RED,   7,  3,   TYPE_ZORA       ,   8,  5,   TYPE_ZORA       ,   2,  7
        ; Salle  31 : (15,  1) P-2
        !byte TYPE_PEAHAT     ,  10,  4,   TYPE_PEAHAT     ,   3,  7,   TYPE_PEAHAT     ,  16,  7,   TYPE_PEAHAT     ,   5,  2,   TYPE_PEAHAT     ,  16,  2,   TYPE_PEAHAT     ,   7,  7,   TYPE_ZORA       ,  19,  4,   TYPE_NONE       ,   0,  0
        ; Salle  32 : ( 0,  2) A-3
        !byte TYPE_GHINI      ,  10,  4,   TYPE_GHINI      ,   3,  7,   TYPE_GHINI      ,  16,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  33 : ( 1,  2) B-3
        !byte TYPE_GHINI      ,  10,  4,   TYPE_GHINI      ,   3,  7,   TYPE_GHINI      ,  16,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  34 : ( 2,  2) C-3
        !byte TYPE_LYNEL_RED  ,   9,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  35 : ( 3,  2) D-3
        !byte TYPE_LYNEL_RED  ,   9,  4,   TYPE_LYNEL_RED  ,  16,  7,   TYPE_LYNEL_RED  ,   3,  7,   TYPE_LYNEL_RED  ,  14,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  36 : ( 4,  2) E-3 - Statues Armos (Guerriers de pierre endormis)
        !byte TYPE_ARMOS      ,   4,  4,   TYPE_ARMOS      ,   7,  4,   TYPE_ARMOS      ,  10,  4,   TYPE_ARMOS      ,  13,  4,   TYPE_ARMOS      ,  16,  4,   TYPE_ARMOS      ,   4,  6,   TYPE_ARMOS      ,  10,  6,   TYPE_ARMOS      ,  16,  6
        ; Salle  37 : ( 5,  2) F-3 - Statues Armos avec Grotte Secrète
        !byte TYPE_ARMOS      ,   4,  4,   TYPE_ARMOS      ,   7,  4,   TYPE_ARMOS      ,  10,  4,   TYPE_ARMOS      ,  13,  4,   TYPE_ARMOS      ,   4,  6,   TYPE_ARMOS      ,   7,  6,   TYPE_ARMOS      ,  10,  6,   TYPE_ARMOS      ,  13,  6
        ; Salle  38 : ( 6,  2) G-3
        !byte TYPE_PEAHAT     ,  10,  4,   TYPE_PEAHAT     ,   3,  7,   TYPE_PEAHAT     ,  16,  3,   TYPE_PEAHAT     ,   5,  2,   TYPE_PEAHAT     ,   7,  6,   TYPE_PEAHAT     ,  13,  4,   TYPE_ZORA       ,  12,  5,   TYPE_ZORA       ,  17,  7
        ; Salle  39 : ( 7,  2) H-3
        !byte TYPE_PEAHAT     ,  10,  4,   TYPE_PEAHAT     ,   3,  3,   TYPE_PEAHAT     ,  16,  3,   TYPE_PEAHAT     ,   7,  3,   TYPE_PEAHAT     ,  13,  2,   TYPE_PEAHAT     ,   9,  2,   TYPE_ZORA       ,   9,  4,   TYPE_ZORA       ,  17,  7
        ; Salle  40 : ( 8,  2) I-3
        !byte TYPE_PEAHAT     ,  10,  4,   TYPE_PEAHAT     ,   3,  2,   TYPE_PEAHAT     ,  16,  7,   TYPE_PEAHAT     ,  16,  2,   TYPE_PEAHAT     ,   7,  2,   TYPE_PEAHAT     ,  12,  7,   TYPE_ZORA       ,   8,  8,   TYPE_NONE       ,   0,  0
        ; Salle  41 : ( 9,  2) J-3
        !byte TYPE_LEEVER_RED ,  10,  4,   TYPE_PEAHAT     ,   3,  7,   TYPE_LEEVER_RED ,  16,  7,   TYPE_PEAHAT     ,   5,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  42 : (10,  2) K-3
        !byte TYPE_LEEVER_BLUE,  10,  4,   TYPE_PEAHAT     ,   3,  7,   TYPE_LEEVER_BLUE,  16,  7,   TYPE_PEAHAT     ,   5,  2,   TYPE_LEEVER_BLUE,  15,  2,   TYPE_PEAHAT     ,   7,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  43 : (11,  2) L-3
        !byte TYPE_LEEVER_BLUE,  10,  4,   TYPE_PEAHAT     ,   3,  7,   TYPE_LEEVER_RED ,  16,  7,   TYPE_PEAHAT     ,   5,  2,   TYPE_LEEVER_BLUE,  15,  2,   TYPE_PEAHAT     ,   7,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  44 : (12,  2) M-3
        !byte TYPE_TEKTITE_RED,  10,  6,   TYPE_TEKTITE_RED,   3,  2,   TYPE_TEKTITE_RED,  15,  2,   TYPE_TEKTITE_RED,   5,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  45 : (13,  2) N-3
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  7,   TYPE_OCTO_RED   ,  16,  7,   TYPE_OCTO_BLUE  ,   5,  2,   TYPE_OCTO_RED   ,   7,  7,   TYPE_ZORA       ,  12,  3,   TYPE_ZORA       ,  17,  2,   TYPE_NONE       ,   0,  0
        ; Salle  46 : (14,  2) O-3
        !byte TYPE_OCTO_BLUE  ,   9,  4,   TYPE_OCTO_BLUE  ,   3,  7,   TYPE_OCTO_BLUE  ,  11,  7,   TYPE_OCTO_BLUE  ,   7,  7,   TYPE_ZORA       ,  10,  4,   TYPE_ZORA       ,   2,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  47 : (15,  2) P-3
        !byte TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  48 : ( 0,  3) A-4
        !byte TYPE_GHINI      ,  10,  4,   TYPE_GHINI      ,   3,  7,   TYPE_GHINI      ,  16,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  49 : ( 1,  3) B-4
        !byte TYPE_GHINI      ,  10,  4,   TYPE_GHINI      ,   3,  7,   TYPE_GHINI      ,  16,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  50 : ( 2,  3) C-4
        !byte TYPE_PEAHAT     ,  10,  4,   TYPE_PEAHAT     ,   3,  2,   TYPE_LYNEL_RED  ,  16,  7,   TYPE_LYNEL_BLUE ,   5,  7,   TYPE_LYNEL_RED  ,  15,  2,   TYPE_LYNEL_BLUE ,  12,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  51 : ( 3,  3) D-4
        !byte TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  52 : ( 4,  3) E-4
        !byte TYPE_ARMOS      ,   4,  4,   TYPE_ARMOS      ,   6,  4,   TYPE_ARMOS      ,   8,  4,   TYPE_ARMOS      ,   4,  6,   TYPE_ARMOS      ,   6,  6,   TYPE_ARMOS      ,   8,  6,   TYPE_ZORA       ,  12,  5,   TYPE_ZORA       ,  17,  7
        ; Salle  53 : ( 5,  3) F-4
        !byte TYPE_ZORA       ,  10,  5,   TYPE_ZORA       ,   2,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  54 : ( 6,  3) G-4
        !byte TYPE_ZORA       ,  10,  5,   TYPE_ZORA       ,   2,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  55 : ( 7,  3) H-4
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_ZORA       ,  19,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  56 : ( 8,  3) I-4
        !byte TYPE_OCTO_BLUE  ,  10,  4,   TYPE_OCTO_RED   ,  16,  7,   TYPE_OCTO_RED   ,  15,  2,   TYPE_OCTO_RED   ,  12,  7,   TYPE_OCTO_RED   ,   9,  7,   TYPE_ZORA       ,   8,  4,   TYPE_ZORA       ,   2,  7,   TYPE_NONE       ,   0,  0
        ; Salle  57 : ( 9,  3) J-4
        !byte TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  58 : (10,  3) K-4
        !byte TYPE_LEEVER_BLUE,  10,  4,   TYPE_PEAHAT     ,   3,  7,   TYPE_LEEVER_RED ,  16,  7,   TYPE_PEAHAT     ,   5,  2,   TYPE_LEEVER_BLUE,  15,  2,   TYPE_PEAHAT     ,   7,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  59 : (11,  3) L-4
        !byte TYPE_LEEVER_BLUE,  10,  4,   TYPE_PEAHAT     ,   3,  7,   TYPE_LEEVER_BLUE,  16,  7,   TYPE_PEAHAT     ,   5,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  60 : (12,  3) M-4
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  61 : (13,  3) N-4
        !byte TYPE_ARMOS      ,   8,  4,   TYPE_ARMOS      ,  11,  4,   TYPE_MOBLIN_BLUE,   3,  7,   TYPE_MOBLIN_BLUE,  16,  7,   TYPE_MOBLIN_BLUE,   4,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  62 : (14,  3) O-4
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  2,   TYPE_OCTO_RED   ,  16,  7,   TYPE_OCTO_BLUE  ,   5,  7,   TYPE_OCTO_RED   ,   7,  2,   TYPE_ZORA       ,  12,  3,   TYPE_ZORA       ,  17,  2,   TYPE_NONE       ,   0,  0
        ; Salle  63 : (15,  3) P-4
        !byte TYPE_OCTO_BLUE  ,   9,  4,   TYPE_ZORA       ,  10,  4,   TYPE_ZORA       ,   2,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  64 : ( 0,  4) A-5
        !byte TYPE_GHINI      ,  10,  4,   TYPE_GHINI      ,   3,  2,   TYPE_GHINI      ,  16,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  65 : ( 1,  4) B-5
        !byte TYPE_GHINI      ,  10,  4,   TYPE_GHINI      ,   3,  7,   TYPE_GHINI      ,  16,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  66 : ( 2,  4) C-5
        !byte TYPE_MOBLIN_RED ,  10,  6,   TYPE_ZORA       ,  10,  4,   TYPE_ZORA       ,   6,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  67 : ( 3,  4) D-5
        !byte TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  68 : ( 4,  4) E-5
        !byte TYPE_OCTO_BLUE  ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  7,   TYPE_OCTO_BLUE  ,   4,  2,   TYPE_OCTO_BLUE  ,   7,  7,   TYPE_ZORA       ,  12,  1,   TYPE_ZORA       ,  19,  9,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  69 : ( 5,  4) F-5
        !byte TYPE_PEAHAT     ,   9,  4,   TYPE_ZORA       ,  19,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  70 : ( 6,  4) G-5
        !byte TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  71 : ( 7,  4) H-5
        !byte TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  72 : ( 8,  4) I-5
        !byte TYPE_LEEVER_RED ,  10,  4,   TYPE_LEEVER_RED ,   3,  5,   TYPE_LEEVER_RED ,  16,  7,   TYPE_LEEVER_RED ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  73 : ( 9,  4) J-5
        !byte TYPE_OCTO_BLUE  ,  10,  4,   TYPE_OCTO_RED   ,   3,  7,   TYPE_OCTO_RED   ,  16,  3,   TYPE_OCTO_RED   ,   5,  2,   TYPE_OCTO_RED   ,   7,  5,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  74 : (10,  4) K-5
        !byte TYPE_TEKTITE_BLUE,  10,  4,   TYPE_TEKTITE_BLUE,   3,  2,   TYPE_TEKTITE_BLUE,  16,  7,   TYPE_TEKTITE_BLUE,   5,  7,   TYPE_TEKTITE_BLUE,  15,  2,   TYPE_TEKTITE_BLUE,   7,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  75 : (11,  4) L-5
        !byte TYPE_MOBLIN_RED ,  10,  4,   TYPE_MOBLIN_RED ,   3,  7,   TYPE_MOBLIN_RED ,  16,  7,   TYPE_MOBLIN_RED ,   5,  2,   TYPE_MOBLIN_RED ,  16,  2,   TYPE_MOBLIN_RED ,   7,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  76 : (12,  4) M-5
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  7,   TYPE_OCTO_RED   ,  16,  7,   TYPE_OCTO_BLUE  ,   5,  2,   TYPE_OCTO_RED   ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  77 : (13,  4) N-5
        !byte TYPE_MOBLIN_BLUE,  10,  4,   TYPE_MOBLIN_BLUE,   3,  7,   TYPE_MOBLIN_BLUE,  16,  7,   TYPE_MOBLIN_BLUE,   5,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  78 : (14,  4) O-5
        !byte TYPE_ARMOS      ,   7,  4,   TYPE_ARMOS      ,  12,  4,   TYPE_MOBLIN_BLUE,   3,  7,   TYPE_MOBLIN_BLUE,  16,  7,   TYPE_MOBLIN_BLUE,   5,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  79 : (15,  4) P-5
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  6,   TYPE_OCTO_RED   ,   6,  2,   TYPE_OCTO_BLUE  ,   7,  7,   TYPE_OCTO_BLUE  ,  11,  7,   TYPE_ZORA       ,  12,  4,   TYPE_ZORA       ,  17,  7,   TYPE_NONE       ,   0,  0
        ; Salle  80 : ( 0,  5) A-6
        !byte TYPE_LYNEL_RED  ,  10,  4,   TYPE_LYNEL_RED  ,   3,  7,   TYPE_LYNEL_RED  ,  16,  7,   TYPE_LYNEL_RED  ,   6,  4,   TYPE_LYNEL_RED  ,   8,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  81 : ( 1,  5) B-6
        !byte TYPE_MOBLIN_BLUE,  10,  4,   TYPE_MOBLIN_BLUE,   3,  7,   TYPE_MOBLIN_BLUE,  16,  3,   TYPE_MOBLIN_BLUE,   5,  2,   TYPE_MOBLIN_BLUE,  14,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  82 : ( 2,  5) C-6
        !byte TYPE_MOBLIN_BLUE,  10,  7,   TYPE_MOBLIN_RED ,   3,  2,   TYPE_MOBLIN_BLUE,  16,  7,   TYPE_MOBLIN_RED ,   4,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  83 : ( 3,  5) D-6
        !byte TYPE_MOBLIN_BLUE,  10,  4,   TYPE_MOBLIN_BLUE,   3,  7,   TYPE_MOBLIN_RED ,  16,  7,   TYPE_MOBLIN_BLUE,   5,  2,   TYPE_MOBLIN_RED ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  84 : ( 4,  5) E-6
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  7,   TYPE_OCTO_RED   ,  16,  7,   TYPE_OCTO_BLUE  ,   5,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  85 : ( 5,  5) F-6
        !byte TYPE_OCTO_BLUE  ,  10,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  86 : ( 6,  5) G-6
        !byte TYPE_OCTO_BLUE  ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  4,   TYPE_OCTO_BLUE  ,  16,  7,   TYPE_OCTO_BLUE  ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  87 : ( 7,  5) H-6
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  7,   TYPE_OCTO_RED   ,  16,  7,   TYPE_OCTO_BLUE  ,   5,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  88 : ( 8,  5) I-6
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  7,   TYPE_OCTO_RED   ,  16,  7,   TYPE_OCTO_BLUE  ,   5,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  89 : ( 9,  5) J-6
        !byte TYPE_PEAHAT     ,  10,  4,   TYPE_PEAHAT     ,   3,  3,   TYPE_PEAHAT     ,  16,  3,   TYPE_PEAHAT     ,   6,  5,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  90 : (10,  5) K-6
        !byte TYPE_OCTO_BLUE  ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  3,   TYPE_OCTO_BLUE  ,  16,  7,   TYPE_OCTO_BLUE  ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  91 : (11,  5) L-6
        !byte TYPE_MOBLIN_BLUE,  10,  4,   TYPE_MOBLIN_RED ,   3,  7,   TYPE_MOBLIN_BLUE,  16,  7,   TYPE_MOBLIN_RED ,   5,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  92 : (12,  5) M-6
        !byte TYPE_MOBLIN_BLUE,   5,  7,   TYPE_MOBLIN_BLUE,  16,  2,   TYPE_MOBLIN_BLUE,  16,  7,   TYPE_MOBLIN_BLUE,  16,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  93 : (13,  5) N-6
        !byte TYPE_MOBLIN_BLUE,  10,  4,   TYPE_MOBLIN_BLUE,   3,  3,   TYPE_MOBLIN_BLUE,  16,  7,   TYPE_MOBLIN_BLUE,  16,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  94 : (14,  5) O-6
        !byte TYPE_MOBLIN_BLUE,  10,  4,   TYPE_MOBLIN_BLUE,   3,  7,   TYPE_MOBLIN_BLUE,  16,  7,   TYPE_MOBLIN_BLUE,   5,  2,   TYPE_MOBLIN_BLUE,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  95 : (15,  5) P-6
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  6,   TYPE_OCTO_RED   ,   6,  2,   TYPE_OCTO_BLUE  ,   7,  7,   TYPE_OCTO_RED   ,  11,  7,   TYPE_ZORA       ,  12,  4,   TYPE_ZORA       ,  17,  7,   TYPE_NONE       ,   0,  0
        ; Salle  96 : ( 0,  6) A-7
        !byte TYPE_PEAHAT     ,  10,  4,   TYPE_PEAHAT     ,   3,  7,   TYPE_LYNEL_RED  ,  16,  7,   TYPE_LYNEL_BLUE ,   5,  2,   TYPE_LYNEL_RED  ,  15,  2,   TYPE_LYNEL_BLUE ,   7,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  97 : ( 1,  6) B-7
        !byte TYPE_MOBLIN_BLUE,  10,  4,   TYPE_MOBLIN_BLUE,   3,  3,   TYPE_MOBLIN_BLUE,  16,  3,   TYPE_MOBLIN_BLUE,  14,  7,   TYPE_MOBLIN_BLUE,   6,  5,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  98 : ( 2,  6) C-7
        !byte TYPE_MOBLIN_BLUE,   9,  4,   TYPE_MOBLIN_BLUE,  16,  2,   TYPE_MOBLIN_BLUE,   3,  3,   TYPE_MOBLIN_BLUE,  13,  5,   TYPE_MOBLIN_BLUE,  12,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle  99 : ( 3,  6) D-7
        !byte TYPE_MOBLIN_BLUE,  10,  4,   TYPE_OCTO_RED   ,   3,  7,   TYPE_MOBLIN_RED ,  16,  7,   TYPE_OCTO_RED   ,   5,  2,   TYPE_MOBLIN_RED ,  15,  2,   TYPE_MOBLIN_RED ,   7,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle 100 : ( 4,  6) E-7
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  2,   TYPE_OCTO_RED   ,  16,  7,   TYPE_OCTO_BLUE  ,   5,  7,   TYPE_OCTO_RED   ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle 101 : ( 5,  6) F-7
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  7,   TYPE_OCTO_RED   ,  16,  7,   TYPE_OCTO_BLUE  ,   5,  2,   TYPE_ZORA       ,   8,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle 102 : ( 6,  6) G-7
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  7,   TYPE_OCTO_RED   ,  16,  7,   TYPE_OCTO_BLUE  ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle 103 : ( 7,  6) H-7
        !byte TYPE_OCTO_BLUE  ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  7,   TYPE_OCTO_BLUE  ,  16,  7,   TYPE_OCTO_BLUE  ,   5,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle 104 : ( 8,  6) I-7
        !byte TYPE_OCTO_BLUE  ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  7,   TYPE_OCTO_BLUE  ,  16,  7,   TYPE_OCTO_BLUE  ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle 105 : ( 9,  6) J-7
        !byte TYPE_OCTO_BLUE  ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  7,   TYPE_OCTO_BLUE  ,  16,  7,   TYPE_OCTO_BLUE  ,   5,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle 106 : (10,  6) K-7
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  7,   TYPE_OCTO_RED   ,  16,  7,   TYPE_OCTO_BLUE  ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle 107 : (11,  6) L-7
        !byte TYPE_MOBLIN_BLUE,  10,  4,   TYPE_OCTO_RED   ,   3,  7,   TYPE_MOBLIN_RED ,  16,  7,   TYPE_OCTO_RED   ,   5,  2,   TYPE_MOBLIN_RED ,  15,  2,   TYPE_MOBLIN_RED ,   7,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle 108 : (12,  6) M-7
        !byte TYPE_MOBLIN_RED ,  10,  4,   TYPE_MOBLIN_RED ,   3,  3,   TYPE_MOBLIN_RED ,  16,  7,   TYPE_MOBLIN_RED ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle 109 : (13,  6) N-7
        !byte TYPE_MOBLIN_RED ,   4,  4,   TYPE_MOBLIN_RED ,  16,  2,   TYPE_MOBLIN_RED ,   3,  7,   TYPE_MOBLIN_RED ,  16,  5,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle 110 : (14,  6) O-7
        !byte TYPE_MOBLIN_BLUE,  10,  3,   TYPE_OCTO_RED   ,   3,  7,   TYPE_MOBLIN_RED ,  16,  7,   TYPE_OCTO_RED   ,  15,  2,   TYPE_MOBLIN_RED ,   3,  2,   TYPE_MOBLIN_RED ,   8,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle 111 : (15,  6) P-7
        !byte TYPE_OCTO_BLUE  ,  10,  4,   TYPE_OCTO_RED   ,   3,  7,   TYPE_OCTO_RED   ,   5,  2,   TYPE_OCTO_RED   ,   7,  7,   TYPE_OCTO_RED   ,  11,  7,   TYPE_ZORA       ,  12,  4,   TYPE_ZORA       ,  17,  7,   TYPE_NONE       ,   0,  0
        ; Salle 112 : ( 0,  7) A-8
        !byte TYPE_PEAHAT     ,  10,  4,   TYPE_PEAHAT     ,   3,  3,   TYPE_PEAHAT     ,  16,  7,   TYPE_PEAHAT     ,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle 113 : ( 1,  7) B-8
        !byte TYPE_MOBLIN_BLUE,  10,  4,   TYPE_MOBLIN_BLUE,   3,  7,   TYPE_MOBLIN_BLUE,  16,  7,   TYPE_MOBLIN_BLUE,   5,  2,   TYPE_MOBLIN_BLUE,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle 114 : ( 2,  7) C-8
        !byte TYPE_MOBLIN_BLUE,   7,  4,   TYPE_MOBLIN_BLUE,  16,  7,   TYPE_MOBLIN_RED ,  11,  7,   TYPE_MOBLIN_BLUE,   3,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle 115 : ( 3,  7) D-8
        !byte TYPE_MOBLIN_BLUE,  10,  4,   TYPE_MOBLIN_BLUE,   3,  7,   TYPE_MOBLIN_BLUE,  16,  7,   TYPE_MOBLIN_BLUE,  15,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle 116 : ( 4,  7) E-8
        !byte TYPE_TEKTITE_RED,   9,  4,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle 117 : ( 5,  7) F-8
        !byte TYPE_LEEVER_BLUE,  10,  4,   TYPE_PEAHAT     ,   3,  7,   TYPE_LEEVER_RED ,  16,  7,   TYPE_PEAHAT     ,   5,  2,   TYPE_LEEVER_BLUE,  15,  2,   TYPE_PEAHAT     ,  12,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle 118 : ( 6,  7) G-8
        !byte TYPE_TEKTITE_RED,  10,  4,   TYPE_TEKTITE_RED,   3,  7,   TYPE_TEKTITE_RED,  16,  7,   TYPE_TEKTITE_RED,   5,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle 119 : ( 7,  7) H-8
        !byte TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle 120 : ( 8,  7) I-8
        !byte TYPE_OCTO_BLUE  ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  7,   TYPE_OCTO_BLUE  ,  16,  7,   TYPE_OCTO_BLUE  ,   5,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle 121 : ( 9,  7) J-8
        !byte TYPE_TEKTITE_BLUE,  10,  3,   TYPE_TEKTITE_BLUE,   3,  7,   TYPE_TEKTITE_BLUE,  16,  6,   TYPE_TEKTITE_BLUE,   8,  7,   TYPE_TEKTITE_BLUE,  14,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle 122 : (10,  7) K-8
        !byte TYPE_TEKTITE_BLUE,  10,  4,   TYPE_TEKTITE_BLUE,   3,  4,   TYPE_TEKTITE_BLUE,  16,  4,   TYPE_TEKTITE_BLUE,   7,  2,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle 123 : (11,  7) L-8
        !byte TYPE_LEEVER_RED ,  10,  4,   TYPE_LEEVER_RED ,   3,  4,   TYPE_LEEVER_RED ,  16,  2,   TYPE_LEEVER_RED ,   7,  3,   TYPE_LEEVER_RED ,  13,  3,   TYPE_LEEVER_RED ,   8,  6,   TYPE_ZORA       ,  10,  5,   TYPE_ZORA       ,  17,  7
        ; Salle 124 : (12,  7) M-8
        !byte TYPE_LEEVER_RED ,  10,  4,   TYPE_LEEVER_RED ,   3,  2,   TYPE_LEEVER_RED ,  16,  2,   TYPE_LEEVER_RED ,   7,  2,   TYPE_LEEVER_RED ,  13,  3,   TYPE_LEEVER_RED ,   5,  4,   TYPE_ZORA       ,  10,  5,   TYPE_ZORA       ,   2,  7
        ; Salle 125 : (13,  7) N-8
        !byte TYPE_OCTO_BLUE  ,  10,  4,   TYPE_OCTO_BLUE  ,   3,  2,   TYPE_OCTO_BLUE  ,  16,  2,   TYPE_OCTO_BLUE  ,   7,  2,   TYPE_ZORA       ,  10,  5,   TYPE_ZORA       ,   2,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle 126 : (14,  7) O-8
        !byte TYPE_OCTO_RED   ,  10,  4,   TYPE_OCTO_RED   ,   3,  3,   TYPE_OCTO_RED   ,  16,  3,   TYPE_OCTO_RED   ,   7,  3,   TYPE_ZORA       ,  10,  5,   TYPE_ZORA       ,   2,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
        ; Salle 127 : (15,  7) P-8
        !byte TYPE_OCTO_BLUE  ,  10,  3,   TYPE_ZORA       ,  10,  4,   TYPE_ZORA       ,   2,  7,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0,   TYPE_NONE       ,   0,  0
