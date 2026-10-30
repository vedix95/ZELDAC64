# Sprite Asset Structure Documentation

## Binary Asset Files (8KB Each)

| File           | Size    | Bank # | Target Address | Contains                  |
|----------------|---------|--------|----------------|---------------------------|
| sprites_ow.bin | 8,192 B | 10     | $2800          | Overworld enemies         |
| sprites_dung.bin| 8,192B| 11     | $2800          | Dungeon-specific enemies  |
| sprites_boss.bin| 8,192B| 12     | $3400          | Boss sprites              |
| sprites_npc.bin | 8,192B| 13     | $2800          | NPCs, chests, fairies     |

### VIC-II Rendering Details

**Video RAM**: $0400–$07E7 (8,200 bytes = 40x25 character cells)
**Color RAM**: $D800–$DBE7 (individual char color + multicolor enable)
**Sprite Registers**: $07F8–$07FF (8 VIC-II hardware sprites)

### Tilemap Generation
Each game tile is 16×16 pixels, composed of a 2×2 block of 8×8 characters:
- Overworld room: 20×10 tiles = 40×20 characters on display
- HUD banner: 40×5 characters (hearts, mini-map, rupee counters)

### Sprite Multiplexer System

To handle Link, weapons, and up to 8 enemies simultaneously:

1. **Raster IRQ Slicing**:
   - Raster line 0: HUD split, status bar rendering
   - Raster lines 50–220: Active playfield with sprite sort
   - Mid-frame IRQ: Repositions sprite registers

2. **Color Multiplexing**:
   - Multicolor 0/1 globally assigned for Link/enemies
   - Sprite colors reassigned per enemy type dynamically

### Debugging Tips
- Always verify sprite Y positions are unique (priority by Y coordinate)
- Check Color RAM multicolor flags are set correctly
- Use raster IRQ to reposition sprites mid-frame if needed
- Never exceed 8 active sprites in a single frame