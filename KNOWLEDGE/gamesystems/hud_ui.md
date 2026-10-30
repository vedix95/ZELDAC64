# HUD/UI System Documentation

## Purpose
Understand heads-up display implementation for:
- Hearts/lives display (status bar)
- Rupee counters
- Weapon icons
- Map/mini-map indicator

---

## Video RAM Display Areas

### Status Bar Layout ($07C4 - $07E7)

```assembly
STATUS_BAR_SEGMENTS:
    .byte heart_section       ; First 4 chars (2 tiles wide)
    .byte space1              ; Spacer
    .byte weapon_icon         ; Weapon symbol
    .byte space2              ; Spacer
    .byte bomb_counter        ; Bombs remaining display
```

### Heart Display Logic

#### Hearts Rendering
- Each heart: 2 character cells ($07C4-$07E3 for first 5 hearts)
- Unused hearts show as blank/hollow pattern
- Color: Red for active hearts, black for hollow (multicolor mode)

#### Heart Data Structure
```assembly
HEART_DATA_BUFFER:
    .byte heart_1             ; Always displayed
    .byte heart_2             ; Always displayed  
    .byte heart_3             ; Always displayed
    .byte heart_4             ; Always displayed
    .byte heart_5             ; Last upgrade target
```

---

## Weapon Icon Display

### Weapon Sprite Placement
- Position: HUD area, typically at (18, 22) - screen cell coordinates
- Uses one of 8 VIC-II sprites
- Updates on weapon change events

#### Weapon Icon Table
```assembly
WEAPON_ICON_TABLE:
    .byte icon_none          ; 0 = No weapon (blank pattern)
    .byte icon_bow           ; 1 = Bow drawn
    .byte icon_sword         ; 2 = Short sword
    .byte icon_long_sword    ; 3 = Long sword
```

---

## HUD Update Routine

#### Per-Frame HUD Refresh
```assembly
UPDATE_HUD:
    ; Load heart data to status bar RAM
    LDA hearts_current,x
    STA video_ram,heart_start
    
    ; Clear unused hearts (show hollow)
    LDA #$00                 ; Blank character pattern
    STA video_ram,$XX        ; Next 4 hearts
    
    ; Update weapon icon display
    LDA weapon_icon,x
    STA video_ram,weapon_pos
    
    ; Refresh bomb counter if needed
    LDA bombs_remaining,x
    STA bomb_display_addr
```

---

## Color RAM Configuration

### HUD Multicolor Setup
```assembly
CONFIG_HUD_COLORS:
    ; Enable multicolor mode for status bar
    LDA #$0F                ; All colors enabled
    STA color_ram_start,x   ; Set palette indices
    
    ; Configure each segment's color pair
    ; Low byte enables color pairs, high byte sets palette
```

---

## Important Notes
- HUD updates should occur every frame (or use IRQ)
- Consider sprite caching for weapon icons to avoid flicker
- Use raster IRQ if updating mid-screen is needed
- Color RAM values must match VIC-II multicolor format