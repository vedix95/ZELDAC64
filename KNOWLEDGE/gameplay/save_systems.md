# Save Systems Documentation

## C64 Save Mechanisms

### Battery-Backed RAM (Standard Cart Design)

#### Memory Layout
```
| Address Range | Size  | Purpose                 |
|---------------|-------|-------------------------|
| $1000-$1FFF   | 4KB   | Player save data        |
| $2000-$27FF   | 2KB   | Inventory persistence   |
| $2800-$37FF   | 2KB   | Progress flags          |
```

#### Save Operation Sequence
1. Clear save data pointer in boot code
2. Set cartridge flag at $DE00 to "save enabled"
3. Write player state to save buffer
4. Execute SYS 2061 for bank switching
5. Halt CPU and reset ($FF)

#### Load Operation Sequence
1. Reset CPU (trigger via $FF write or external)
2. Read save bank data from cartridge
3. Decompress intro if present
4. Restore player state from saved variables

### Magic Desk Type 19 Features
- **Save Battery**: CR2032 cell in Type 19 modules
- **Power-on Reset**: Initializes from battery-backed RAM
- **State Persistence**: Maintains position, inventory, flags

### Save Data Structures

#### Player State Block (8 bytes minimum)
```assembly
PLAYER_BLOCK:
    .byte current_x           ; X position (low byte)
    .byte current_y           ; Y position (high byte + bank)
    .byte life_points         ; Hearts remaining
    .byte weapon_slot         ; Current weapon index
    .byte quest_progress      ; Main story flag
    .byte dungeon_location    ; Last visited level
    .byte flags               ; Misc flags
```

#### Inventory Block (variable size)
- Each item: 2 bytes (type, count)
- Maximum items: depends on available space
- Save only carried items, not equipped weapons

### Debug Mode Save/Load

Implement quick save/load by:
1. Adding command at boot level ($FF reset triggers load)
2. Writing debug data to specific RAM region
3. Using bank 99+ for debugging saves (non-volatile area)

---

## Important Notes
- Battery-backed saves use simple write/read, no compression
- Consider checksum validation for save integrity
- Implement auto-save before major game events