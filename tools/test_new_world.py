#!/usr/bin/env python3
import os, sys

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
NES_DIR = os.path.join(BASE_DIR, "assets", "nes")
TILES_FILE = os.path.join(NES_DIR, "nes_zelda_overworld_tile_map.txt")
BLOCKS_FILE = os.path.join(NES_DIR, "nes_zelda_overworld_blocking_map.txt")

WATER_TILES = {'50', '51', '52', '64', '65', '66', '78', '79', '7a', '90', '96'}
BRIDGE_H_TILES = {'8c', '8d', '8e', '8f', '91'}
BRIDGE_V_TILES = {'92', '93', '97'}
GRAVE_TILES = {'21', '22'}
CAVE_TILES = {'12'}
ROAD_TILES = {'00', '0e', '40'}
SHRUB_TILES = {'03', '04', '05', '07'}
WALKABLE_PATHS = {'14', '1a', '20'}
TREE_TILES = {
    '15', '1b', '17', '19', '1c', '1d', '1e', '1f',
    '28', '29', '2a', '2b', '2c', '2d', '2e', '2f',
    '30', '31', '32', '33', '34', '6a', '6b', '6c',
    '7e', '7f', '80'
}
WALL_TILES = {
    '3c', '3d', '3e', '42', '43', '44', '45', '46', '47',
    '48', '49', '4a', '4b', '4d', '35', '36', '37', '38',
    '39', '56', '57', '58', '08', '09', '0a', '0b',
    '16', '01', '3f', '41'
}

SOLID = {'#', 'T', '~', 'G', 'B'}

COL_MAP = [0, 1, 2, 2, 3, 4, 5, 5, 6, 7, 8, 8, 9, 10, 11, 11, 12, 13, 14, 15]
ROW_MAP = [0, 1, 3, 4, 5, 6, 7, 8, 9, 10]

def get_tile_symbol(t, b, x, y):
    if t in CAVE_TILES:
        return 'O'
    if t in GRAVE_TILES:
        return 'G'
    if t in BRIDGE_H_TILES:
        return '='
    if t in BRIDGE_V_TILES:
        return 'I'
    if t in WATER_TILES:
        return '~'
    if t in WALKABLE_PATHS:
        return '.'
    if t in ROAD_TILES:
        return '_'
    if t in SHRUB_TILES:
        return ','
    if t in TREE_TILES:
        return 'T'
    if t in WALL_TILES:
        return '#'
    if b == '.':
        return '.'
    return '#'

with open(TILES_FILE) as f:
    nes_tiles = [l.strip().split() for l in f if l.strip()]
with open(BLOCKS_FILE) as f:
    nes_blocks = [l.strip() for l in f if l.strip()]

rooms = {}
for ry in range(8):
    for rx in range(16):
        c64_room = []
        for cy, ny in enumerate(ROW_MAP):
            row = []
            for cx, nx in enumerate(COL_MAP):
                nes_x = rx * 16 + nx
                nes_y = ry * 11 + ny
                sym = get_tile_symbol(
                    nes_tiles[nes_y][nes_x],
                    nes_blocks[nes_y][nes_x],
                    nes_x, nes_y
                )
                row.append(sym)
            c64_room.append(row)
        rooms[(rx, ry)] = c64_room

print('Initial extraction done.')
