; GENERE par tools/tilegen.py - Donnees de tuiles et decompressor resident
MAP_W           = 20
MAP_H           = 10
MAP_BG_COLOR    = 13
MAP_MC1_COLOR   = 8
MAP_MC2_COLOR   = 1

WORLD_ROOMS_X   = 16
WORLD_ROOMS_Y   = 8
WORLD_ROOMS_CNT = 128

TILE_SOLID      = %00000001

TILE_GRASS = 0
TILE_TUFTS = 1
TILE_FLOWERS = 2
TILE_TREE = 3
TILE_WATER = 4
TILE_WALL = 5
TILE_SAND = 6
TILE_CAVE = 7
TILE_GRAVE = 8
TILE_BRIDGE_H = 9
TILE_BRIDGE_V = 10
TILE_WALL_PASS = 11
TILE_WALL_BOMB = 12

; Constantes des tuiles de donjon (16 tuiles 16x16)
TILE_DUNG_FLOOR         = 0     ; Sol en dalle
TILE_DUNG_WALL_TOP      = 1     ; Mur superieur
TILE_DUNG_WALL_BOT      = 2     ; Mur inferieur
TILE_DUNG_WALL_LEFT     = 3     ; Mur gauche
TILE_DUNG_WALL_RIGHT    = 4     ; Mur droit
TILE_DUNG_BLOCK         = 5     ; Bloc diamant 3D
TILE_DUNG_STATUE        = 6     ; Statue dragon
TILE_DUNG_STAIRS        = 7     ; Escalier secret
TILE_DUNG_CORNER_TL     = 8     ; Biseau 45 haut-gauche
TILE_DUNG_CORNER_TR     = 9     ; Biseau 45 haut-droit
TILE_DUNG_CORNER_BL     = 10    ; Biseau 45 bas-gauche
TILE_DUNG_CORNER_BR     = 11    ; Biseau 45 bas-droit
TILE_DUNG_DOOR_OPEN     = 12    ; Porte ouverte (passage)
TILE_DUNG_DOOR_LOCKED   = 13    ; Porte verrouillee avec serrure
TILE_DUNG_DOOR_SHUTTER  = 14    ; Volet / herse metallique
TILE_DUNG_DOOR_BOMB     = 15    ; Mur fissure a la bombe

ow_tile_char_base:
        !byte 0, 4, 8, 12, 16, 20, 24, 28, 168, 184, 188, 192, 196, 0, 0, 0
dung_tile_char_base:
        !byte 0, 4, 8, 12, 16, 20, 24, 28, 168, 172, 176, 180, 184, 188, 192, 196

; Caractere de base de chaque tuile (2x2 = 4 caracteres)
tile_char_base:
        !byte 0, 4, 8, 12, 16, 20, 24, 28, 168, 184, 188, 192, 196, 0, 0, 0

; Couleurs de chaque zone regionale (+8 pour mode multicolore)
zone0_tile_color:
        !byte 8, 9, 9, 8, 14, 8, 8, 8, 9, 8, 8, 8, 8, 0, 0, 0
zone1_tile_color:
        !byte 10, 15, 15, 10, 14, 10, 15, 8, 9, 8, 8, 10, 10, 0, 0, 0
zone2_tile_color:
        !byte 13, 13, 10, 13, 14, 8, 15, 8, 9, 8, 8, 8, 8, 0, 0, 0
zone3_tile_color:
        !byte 13, 13, 10, 13, 14, 8, 15, 8, 9, 8, 8, 8, 8, 0, 0, 0
zone_dungeon_tile_color:
        !byte 8, 19, 10, 11, 14, 11, 20, 8, 8, 8, 8, 11, 11, 0, 0, 0

zone_color_lo:
        !byte <zone0_tile_color, <zone1_tile_color, <zone2_tile_color, <zone3_tile_color
zone_color_hi:
        !byte >zone0_tile_color, >zone1_tile_color, >zone2_tile_color, >zone3_tile_color

zone_bg_color:
        !byte 11, 9, 13, 13
zone_mc1_color:
        !byte 0, 8, 8, 8
zone_mc2_color:
        !byte 1, 1, 1, 1

; Tampon de couleur des tuiles de la salle active
active_tile_color:
        !fill 16, 0
tile_color = active_tile_color

ow_tile_flags:
        !byte 0, 0, 0, TILE_SOLID, TILE_SOLID, TILE_SOLID, 0, 0, TILE_SOLID, 0, 0, 0, TILE_SOLID, 0, 0, 0
dung_tile_flags:
        !byte 0, TILE_SOLID, TILE_SOLID, TILE_SOLID, TILE_SOLID, TILE_SOLID, TILE_SOLID, 0, TILE_SOLID, TILE_SOLID, TILE_SOLID, TILE_SOLID, 0, TILE_SOLID, TILE_SOLID, TILE_SOLID

; drapeaux de chaque tuile (bit 0 = solide)
tile_flags:
        !byte 0, 0, 0, TILE_SOLID, TILE_SOLID, TILE_SOLID, 0, 0, TILE_SOLID, 0, 0, 0, TILE_SOLID, 0, 0, 0

; table ty * MAP_W
tile_row_offset:
        !byte 0, 20, 40, 60, 80, 100, 120, 140, 160, 180

; Pointeur vers la table de rangées dynamique de la carte active ($C006)
world_row_offset = map_row_offset

; Les tampons room_buf et target_room_buf sont alloués proprement en BSS résident dans main.asm

; ---------------------------------------------------------------------------
; Decompression RLE compact (1-octet) de la salle pointee par ZP_SRC dans room_buf
; Format : bit 7..4 = (run - 1) [0..14 -> 1..15 tuiles], bit 3..0 = tile (0..15)
; Fin de salle : $FF
; ---------------------------------------------------------------------------
decompress_room_main:
        ldy #0
        ldx #0
.drm_loop:
        lda (ZP_SRC),y
        cmp #$ff
        beq .drm_done
        iny
        pha
        lsr
        lsr
        lsr
        lsr
        clc
        adc #1
        sta ZP_TMP
        pla
        and #$0f
.drm_put:
        sta room_buf,x
        inx
        dec ZP_TMP
        bne .drm_put
        cpx #200
        bcc .drm_loop
.drm_done:
        rts

; ---------------------------------------------------------------------------
; Decompression RLE compact (1-octet) dans target_room_buf
; ---------------------------------------------------------------------------
decompress_room_target:
        ldy #0
        ldx #0
.drt_loop:
        lda (ZP_SRC),y
        cmp #$ff
        beq .drt_done
        iny
        pha
        lsr
        lsr
        lsr
        lsr
        clc
        adc #1
        sta ZP_TMP
        pla
        and #$0f
.drt_put:
        sta target_room_buf,x
        inx
        dec ZP_TMP
        bne .drt_put
        cpx #200
        bcc .drt_loop
.drt_done:
        rts

