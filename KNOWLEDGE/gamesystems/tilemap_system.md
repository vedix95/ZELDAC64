# Tilemap System Documentation

## Purpose
Understand tilemap-based world generation for:
- Overworld room layouts
- Dungeon floor/wall patterns
- Room-to-room connections
- Tile pattern management

---

## Tilemap Data Structure

### Screen Cell Grid System

```assembly
GRID_RESOLUTION:
    Columns: 40 (screen cell width)
    Rows: 25 (screen cell height)
    
Tile Size:
    Each tile = 16×16 pixels = 4×4 screen cells
    
Overworld Room Layout:
    Grid: 20 columns × 10 rows = 200 tiles per room
```

### Room Data Storage

```assembly
ROOM_LAYOUT_DATA:
    .byte tile_row_0,x         ; First row of room (16 bytes for 4 tiles)
    ...                        ; ... more rows
    .byte tile_row_Y,x         ; Last row
    
; Each row contains:
; - Tile pattern index (8 bits)
; - Wall flag bit (optional)
```

---

## Overworld Map System

### Room Connection Logic

```assembly
OVERWORLD_MAP:
    ; 10×5 grid of rooms
    .byte room_0_0             ; Top-left room
    .byte room_0_1             ; ...
    ...                        ; ...
    .byte room_9_4             ; Bottom-right room
    
; Each room contains:
; - Entry point location (door position)
; - Exit triggers (enemy, event)
; - Item placements (rupees, hearts)
```

### Room Connection Patterns

#### Door Placement Rules
- Doors appear on edges connecting rooms
- Entrance/exit marked by specific tile pattern
- Special tiles: fountain, tree, bridge

---

## Dungeon Layout Generation

### Pattern-Based Layouts

```assembly
DUNGEON_PATTERN_TABLE:
    .byte PATTERN_A            ; Standard dungeon layout
    .byte PATTERN_B            ; Castle-themed layout
    .byte PATTERN_C            ; Desert-themed layout
    ...
    
; Each pattern defines:
; - Wall positions (obstacles)
; - Floor tiles (walkable areas)
; - Enemy spawn locations
; - Item drop zones
```

### Layout Generation Algorithm

```
1. Load dungeon pattern from table
2. Copy pattern data to video RAM
3. Apply floor/wall tile codes
4. Spawn enemies at designated positions
5. Place items in item containers
6. Set door exit trigger
```

---

## Tile Pattern Management

### VIC-II Character Patterns

#### Available Patterns (Zero Page Storage)
```assembly
TILE_PATTERN_ZERO_PAGE:
    .byte PATTERN_EMPTY        ; 0 = No character ($41)
    .byte PATTERN_GRASS        ; 1 = Overworld grass
    .byte PATTERN_WATER        ; 2 = Water surface
    .byte PATTERN_STONE        ; 3 = Dungeon floor/wall
    ...
```

### Pattern Assignment System

```assembly
ASSIGN_TILE_PATTERN:
    ; For each grid position:
    LDA pattern_table,x,y      ; Get pattern for X,Y
    STA video_ram,addr,x       ; Write to screen
    
    ; Use different character for walls vs floor
    LDA #$38                   ; Dark wall character (if applicable)
    STA color_ram,walls_addr   ; Wall color
```

---

## Debugging Tilemap Issues

### Common Problems
1. **Wrong tile codes**: Video RAM has invalid character values
2. **Color mismatch**: Color RAM doesn't match tile patterns
3. **Tile alignment**: Tiles not properly aligned to grid boundaries
4. **Memory corruption**: Overwriting adjacent data structures

### Diagnostic Checks
```assembly
VERIFY_TILEMAP_INTEGRITY:
    ; Check all tiles in current room are valid
    LOOP_ROW_0_TO_MAX_ROWS:
        LOOP_COL_0_TO_MAX_COLS:
            LDA video_ram,current_row,current_col,x
            CMP empty_tile_code,x
            BEQ CONTINUE
        
            ; Invalid tile code found - flag for debugging
            JMP TILEMAP_ERROR
            
CONTINUE:
    ; Continue checking next position
```

---

## Important Notes
- Tilemap data must fit in available RAM space
- Consider using pre-built layouts instead of dynamic generation for simplicity
- Ensure tile codes are within VIC-II charset range (0-127)