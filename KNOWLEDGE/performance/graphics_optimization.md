# Graphics Optimization Documentation

## Purpose
Understand VIC-II limitations and optimization techniques for:
- Memory-efficient rendering
- Sprite management
- Color usage strategies
- Performance considerations

---

## VIC-II Hardware Limitations

### Key Constraints
1. **8 hardware sprites maximum** (only 7 usable in practice)
2. **Sprite sorting**: Must be sorted by Y position for proper rendering
3. **Color RAM limited**: Only 4 bits per character = 4 simultaneous colors
4. **Memory bandwidth**: Limited refresh rate affects data access patterns

### Memory Considerations

#### Video RAM Usage ($0400-$07E7)
- Size: 8,200 bytes (40×25 screen cells)
- Contains visible display only (no off-screen buffers needed in basic mode)
- Must be updated every VSYNC to avoid flicker

#### Color RAM Usage ($D800-$DBE7)
- Size: 950 bytes
- Each 2-byte entry controls one character position
- Stores color pair + enable flag per cell

### Optimization Strategies

#### Sprite Priority Management
```assembly
SPRITE_PRIORITY_RULES:
    1. Link always rendered first (lowest Y)
    2. Enemies sorted by Y position
    3. Background drawn after sprites
    
    ; Calculate priority order
    ; Lower Y coordinate = higher draw priority
```

#### Memory-Bandwidth Optimization
- Copy sprite data to RAM before VIC-II update
- Use zero-page for frequently accessed values
- Batch video frame updates in single operation
- Minimize writes during VSYNC window

---

## Color Usage Strategies

### 4-Bit Multicolor Mode

#### Color Assignment Pattern
```assembly
MULTICOLOR_PALETTE:
    .byte PALETTE_A           ; Background color 0
    .byte PALETTE_B           ; Background color 1  
    .byte PALETTE_C           ; Sprite color 0
    .byte PALETTE_D           ; Sprite color 1
```

#### Color Memory Layout
- Each character cell uses 2 bytes in Color RAM
- High byte: Primary color index (palette A/B or C/D)
- Low byte: Enable flag + secondary color index
- Multicolor mode allows mixing primary and secondary colors

### Practical Color Usage
- Use minimal number of simultaneous colors per screen region
- Reuse sprite color assignments across enemies when possible
- Reserve palette slots for important game objects (hearts, rupees)

---

## Performance Considerations

### Frame Timing Analysis
```
Total Frames Per Second: ~60 Hz (PAL) or 59.94 Hz
  
Per-Frame Operations:
1. VIC-II IRQ handler (~1ms)
2. Video frame update (~5ms)  
3. Sprite position updates (~2ms)
4. Audio effects (~1ms)
```

### Optimization Checklist
- [ ] Cache frequently-used sprite positions in zero page
- [ ] Use raster line interrupts for mid-frame positioning
- [ ] Minimize memory reads during critical sections
- [ ] Batch video RAM writes into single operation
- [ ] Pre-calculate sprite colors where possible

---

## Debugging Graphics Issues

### Common Problems
1. **Sprite flicker**: Caused by reading uninitialized sprites
2. **Wrong color order**: Color RAM values misaligned
3. **Background behind sprites**: Sprite register priority incorrect
4. **Missing characters**: Video RAM not written to all positions

### Diagnostic Steps
- Dump video RAM contents for inspection
- Verify sprite Y coordinates are unique and sorted
- Check Color RAM alignment matches character cell positions
- Use PPU debugger to inspect VIC-II registers in real-time

---

## Important Notes
- Always respect 8-sprite hardware limit
- Remember sprite priority sorting requirement
- Plan color palette assignments before rendering
- Consider using IRQ handlers for precise timing