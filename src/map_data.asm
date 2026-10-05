; GENERE par tools/tilegen.py depuis assets/tiles.txt et assets/map.txt - ne pas editer.
MAP_W           = 20
MAP_H           = 12
MAP_BG_COLOR    = 13
MAP_MC1_COLOR   = 8
MAP_MC2_COLOR   = 1

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

; carte : 1 octet par tuile, ligne par ligne
map_data:
        !byte 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 7, 5, 5, 5, 5, 5, 5, 5, 5, 5
        !byte 3, 3, 0, 1, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 1, 0, 0, 0, 3, 3
        !byte 3, 0, 1, 2, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 4, 4, 4, 0, 3
        !byte 3, 0, 1, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 4, 4, 4, 4, 4, 3
        !byte 3, 0, 0, 2, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 4, 4, 4, 4, 4, 3
        !byte 3, 0, 3, 3, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 4, 4, 4, 4, 3
        !byte 3, 0, 3, 3, 0, 2, 0, 0, 0, 0, 6, 0, 0, 0, 4, 4, 4, 0, 0, 3
        !byte 3, 0, 1, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 1, 0, 0, 3
        !byte 3, 0, 0, 2, 0, 0, 0, 0, 0, 0, 6, 0, 0, 2, 0, 0, 0, 0, 0, 3
        !byte 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 6, 0, 0, 0, 0, 0, 0, 3, 3
        !byte 3, 3, 0, 0, 0, 0, 0, 0, 0, 0, 6, 6, 0, 0, 0, 0, 0, 0, 3, 3
        !byte 3, 3, 3, 3, 0, 0, 0, 0, 0, 0, 6, 6, 0, 0, 0, 0, 3, 3, 3, 3
