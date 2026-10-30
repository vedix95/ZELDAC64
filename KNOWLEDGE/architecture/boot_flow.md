# Boot & Initialization Flow Documentation

## Purpose
Understand the complete cartridge initialization sequence for:
- Bootloader execution flow
- Video RAM initialization
- Banking setup timing
- Interrupt handler registration

---

## Complete Boot Sequence

### Phase 1: Reset Handling ($FF)

```assembly
BOOT_SEQUENCE:
    ; Step 0: Power-on reset or manual boot trigger
    SYS #$FF                  ; Reset CPU from any bank
    
    ; Step 1: Jump to bootloader (Bank 0, address $2800)
    JMP boot_entry_point,x    ; Bank 0 entry at $2800
    
    ; Bootloader resides in ROM Bank 0
    ; Resident code loaded into RAM by bootloader
```

### Phase 2: Video Initialization

```assembly
INIT_VIDEO_SYSTEM:
    ; Clear video RAM (or load initial pattern)
    LDA #$41                  ; Background character (space)
    
    ; Write to entire screen area
    LOOP_SCREEN_Y_0_TO_25:
        LOOP_SCREEN_X_0_TO_39:
            STA video_ram,loop_addr,x
            
    ; Initialize Color RAM (multicolor mode off initially)
    LDA #$FF                  ; All characters single color
    STA color_ram_start,x     ; Apply to all cells
    
    ; Enable sprite registers
    LDA #$FF
    STA sprite_reg_0,y        ; Configure all 8 sprites
```

### Phase 3: Banking Setup

```assembly
SETUP_BANKING_SYSTEM:
    ; Initialize bank control register
    LDA #$37                  ; Bank 1-9 resident (default)
    STA $DE00                 ; Store in bank register
    
    ; Set interrupt handler address  
    LDA IRQ_handler_addr_lo,x
    STA $02FF,x              ; Vertical blank IRQ base
    
    LDA IRQ_handler_addr_hi,x
    STA $03FF,x              ; High byte
```

### Phase 4: Audio Initialization

```assembly
INIT_SID_AUDIO:
    ; Reset SID chip to default state
    LDA #$FF                  ; Enable all voices
    STA $DC00,x               ; Voice control register
    
    ; Disable audio temporarily (will enable later)
    LDA #$FE                  ; All voices off
    STA $D700,x               ; Audio master control
```

---

## Video RAM Layout ($0400-$07E7)

### Memory Mapped Grid

```
Address Range: $0400 - $07E7  (1,556 bytes visible area)
Screen Format:
    - Columns: 0-39 (40 screen cells wide)
    - Rows: 0-24 (25 rows high)
    
Coordinate System:
    Row 0 at top of screen
    Column 0 at left edge
    
Video RAM Addressing:
    Base: $0400 (address in RAM)
    Each cell: 1 byte per row
```

---

## Color RAM Layout ($D800-$DBE7)

### Memory Mapped Structure

```
Address Range: $D800 - $DBE7 (950 bytes)
Purpose: Store color pairs for each character position

Color Storage Format:
    High byte: Primary color index (palette A/B)
    Low byte: Enable flag + secondary palette index
    
Layout by Row:
    .byte color_pair_row_0,x      ; First row of characters
    ...                           ; Each row in sequence
    .byte color_pair_row_24,x     ; Last row
```

---

## IRQ Handler Registration

### Vertical Blank Interrupt

```assembly
CONFIGURE_IRQ_HANDLER:
    ; IRQ handler runs at VSYNC (every frame)
    
    ; Set handler address registers
    LDA IRQ_addr_lo,x             ; Low byte of handler
    STA $02FF,x                  ; IRQ vector low byte
    
    LDA IRQ_addr_hi,x             ; High byte of handler  
    STA $03FF,x                  ; IRQ vector high byte
    
    ; Enable interrupts (in resident mode)
    SEI                          ; Disable (safe during boot)
    
    LDA #$0A                    ; Re-enable after initialization
    STA $DC0D,x                  ; Interrupt enable register
```

---

## Important Notes
- Boot sequence must complete before any banking operations
- Video RAM should be initialized with background pattern first
- Color RAM can be fully populated after sprite positions are set
- IRQ handlers should be minimal (use for timing or simple state updates)