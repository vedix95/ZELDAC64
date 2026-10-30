# Level Streaming System Documentation

## Purpose
Understand level loading and streaming for:
- Room to room transitions
- Dungeon generation/loading  
- Chunk-based overworld navigation
- Level data persistence

---

## Bank-Based Level Loading

### Level Storage Structure

```assembly
LEVEL_BANK_MAP:
    .byte boot          ; Bank 0 - Cartridge loader
    .byte intro1        ; Bank 1 - Intro region
    .byte intro2        ; Bank 2 - Intro continuation
    .byte intro3        ; Bank 3 - Intro finish
    .byte core_1        ; Bank 4 - Core engine part 1
    .byte core_2        ; Bank 5 - Core engine part 2
    .byte level_01      ; Bank 6 - Eagle dungeon
    .byte level_02      ; Bank 7 - Dوق dungeon
    ...                 ; Additional level banks
```

### Loading Sequence

#### Transition to New Level
```assembly
LOAD_NEW_LEVEL:
    ; Disable cartridge to use resident engine
    LDA #$36
    STA $DE00
    
    ; Copy bank 4-9 into RAM ($0800-$67FF)
    JSR copy_bank_4_to_ram
    JSR copy_bank_5_to_ram
    ...
    
    ; Enable cartridge (SYS 2061)
    LDA #$37
    STA $DE00
    
    ; Bank switch to level data
    LDA level_bank_number,x
    STA $DE00
    
    ; Jump to level entry point
    JMP level_start_addr,x
```

### Level Data Structure

Each dungeon/level contains:
- **Layout tiles**: Floor/wall maps
- **Entity spawns**: Enemy positions at start
- **Item locations**: Rupees, weapons, hearts
- **Door connections**: Exit/entrance points

---

## Overworld Navigation System

### Room Chunk Management

```
Overworld Grid: 10×5 rooms
Each room: 20×10 tiles = 40×20 screen cells
```

#### Current Room Tracking
```assembly
ROOM_DATA:
    .byte current_room_x        ; 0-9 (horizontal position)
    .byte current_room_y        ; 0-4 (vertical position)
    .byte room_loaded_flag      ; 1 = loaded, 0 = not yet
    .byte bank_number           ; Which cartridge bank to switch
```

#### Room Transition Logic
```assembly
CHECK_ROOM_CHANGE:
    ; Compare new position with current room
    LDA player_room_x_target
    STA temp_player_x
    
    LDA current_room_x,x        ; Check if movement changed room
    BEQ stay_in_same_room       ; No change, skip loading
    JSR load_new_room_x         ; Load X adjacent room
    JMP update_display
```

### Loading Optimization

1. **Pre-load strategy**: Load rooms as player approaches edge
2. **Bank switching**: Use $DE00 to switch banks before render
3. **Unpacker utilization**: Bank 0 contains decompression routine

---

## Dungeon Generation System

### Level Header Structure

```assembly
DUNGEON_HEADER:
    .byte dungeon_id            ; Unique identifier (1-9)
    .byte map_size_x            ; Width in tiles
    .byte map_size_y            ; Height in tiles
    .byte floor_pattern_id      ; Which tile pattern to use
    .byte enemy_spawn_count      ; Total enemies at start
    .byte item_spawn_count      ; Starting pickups
    .byte exit_trigger_addr     ; Address of exit logic
```

### Room-to-Dungeon Transition
1. Link enters dungeon door
2. Bank switch to dungeon-specific code
3. Load dungeon layout tiles
4. Spawn enemy entities from spawn list
5. Execute dungeon entrance animation

---

## Important Notes
- Level loading should occur during VSYNC to avoid glitches
- Use bank switching efficiently to minimize ROM reads
- Consider using RAM-backed saves for quick dungeon transitions