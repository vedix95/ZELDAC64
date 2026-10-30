# Rendering Pipeline Documentation

## VIC-II Graphics System

**Display Modes:**
- Multicolor mode (8 colors via 2 bits per character)
- Screen resolution: 40×25 characters = 800×400 pixels
- Sprite priority: Sprites overlay background, sorted by Y position

### Color RAM Structure ($D800–$DBE7)

Each 2-byte entry contains:
- High byte: Character color index (0-F)
- Low byte: Multicolor enable flag + palette index

### Rendering Cycle (Per Frame)

1. VIC-II IRQ Triggered (every VSYNC)
2. Load new video frame to $0400-$07E7
3. Configure sprite registers ($07F8-$07FF)
   - Set X/Y positions for Link and active enemies
   - Assign multicolor indices
4. Update Color RAM ($D800-$DBE7)
   - Set character colors for tiles
   - Enable/disable multicolor mode per region
5. Execute raster IRQ handlers (mid-frame positioning)

### 8 Hardware Sprites

| Slot | Primary Use                     |
|------|----------------------------------|
| 0-1  | Link character + weapon slot    |
| 2-7  | Dynamic enemy assignment         |
| 8    | Reserved/unused                 |

### Debugging Checklist

When sprites don't render:
1. Verify sprite registers ($07F8-$07FF) have valid Y positions
2. Check Video RAM ($0400-$07E7) has non-zero character codes
3. Confirm Color RAM ($D800-$DBE7) has multicolor enabled
4. Ensure sprite priority flags are set (lower Y = higher priority)
5. Use PPU debugger to inspect VIC-II registers live

### Performance Notes
- Multicolor mode is most memory-efficient
- Sprite positions must be sorted by Y for proper rendering
- Consider using sprite multiplexing for more active objects
- Raster IRQ helps maintain precise sprite positioning