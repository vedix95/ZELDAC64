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

; couleur de chaque tuile (+8 = caractere multicolore)
tile_color:
        !byte 13   ; grass
        !byte 13   ; tufts
        !byte 10   ; flowers
        !byte 13   ; tree
        !byte 14   ; water
        !byte 8   ; wall
        !byte 15   ; sand
        !byte 8   ; cave

; drapeaux de chaque tuile (bit 0 = solide)
tile_flags:
        !byte 0   ; grass
        !byte 0   ; tufts
        !byte 0   ; flowers
        !byte TILE_SOLID   ; tree
        !byte TILE_SOLID   ; water
        !byte TILE_SOLID   ; wall
        !byte 0   ; sand
        !byte 0   ; cave

; table ty * MAP_W
tile_row_offset:
        !byte 0, 20, 40, 60, 80, 100, 120, 140, 160, 180

; Pointeur vers la table de rangées dynamique de la carte active ($A006)
world_row_offset = map_row_offset

room_buf:        !fill 200, 0            ; Tampon de la salle active decompressee
target_room_buf: !fill 200, 0            ; Tampon de la salle cible (transition)

; ---------------------------------------------------------------------------
; Decompression RLE compact (1-octet) de la salle pointee par ZP_SRC dans room_buf
; Format : bit 7..3 = (run - 1) [0..30 -> 1..31 tuiles], bit 2..0 = tile (0..7)
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
        clc
        adc #1
        sta ZP_TMP
        pla
        and #7
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
        clc
        adc #1
        sta ZP_TMP
        pla
        and #7
.drt_put:
        sta target_room_buf,x
        inx
        dec ZP_TMP
        bne .drt_put
        cpx #200
        bcc .drt_loop
.drt_done:
        rts

