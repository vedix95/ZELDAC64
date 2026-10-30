# Inventory System Documentation

## Purpose
Understand item management for:
- Rupee collection and display
- Weapon/equipment system
- Heart container progression
- Collectible tracking (bombs, arrows)

---

## Data Structure Design

### Inventory Array Layout

```assembly
INVENTORY_SYSTEM:
    .byte player_x,x            ; Track current position on screen
    .byte player_y,x            ; Y coordinate
    .byte weapon_index,x        ; 0=none, 1=sword, 2=bomb, etc.
    .byte rupees_total,x        ; Total collected so far
    .byte hearts_current,x      ; Lives remaining
    .byte max_hearts,x          ; Progress toward new container
    .byte bombs_count,x         ; Bombs collected
    .byte arrows_count,x        ; Arrows collected
    .byte other_items,x         ; Other pickups (keys, etc.)
```

### Weapon System

#### Weapon States
```assembly
WEAPON_TABLE:
    .byte WEAPON_NONE          ; 0 = No weapon
    .byte WEAPON_BOW           ; 1 = Bow
    .byte WEAPON_SHORT_SWORD   ; 2 = Short sword
    .byte WEAPON_LONG_SWORD    ; 3 = Long sword
    .byte WEAPON_FIRE_SHOOTER  ; 4 = Fire bow
    .byte WEAPON_BOMB          ; 5 = Bomb bag (1 bomb)
```

#### Weapon Progression Logic
- Each dungeon has a specific weapon to obtain
- Weapons are stored in cartridge ROM
- Loading new weapon requires bank switch or RAM copy
- Track which weapons have been obtained for quest completion

### Rupee Tracking System

#### Rupee Color Codes
```assembly
RUPEE_COLOR_TABLE:
    .byte RUPEE_GREEN          ; 5 rupees (forest, early game)
    .byte RUPEE_BLUE           ; 20 rupees
    .byte RUPEE_RED            ; 50 rupees
    .byte RUPEE_PURPLE         ; 200 rupees
```

#### Rupee Display Logic
- Update HUD with total rupee count
- Show color-coded breakdown in mini-map area
- Save rupee totals for each dungeon separately if desired

---

## Heart Container Progression

### Tracking System
```assembly
HEART_DATA:
    .byte current_life         ; Current hearts (1-9)
    .byte progress_current     ; Current quest progress (0-8)
    .byte progress_max         ; Maximum hearts possible (usually 9)
```

### Heart Container Logic
1. Defeat boss in dungeon → unlock max health option
2. Pick up heart pieces during exploration
3. Collect enough pieces to upgrade to next container level
4. Save heart count to inventory array
5. Display hearts on HUD status bar

---

## Pickup Handling

#### Pickup Collision Event
```assembly
HANDLE_PICKUP:
    ; Check if Link collides with rupee
    IF collision AND rupee_not_collected:
        ADD rupee_value TO rupees_total,x
        SET rupee_flag = 0 (already collected)
        PLAY chime_sound
        UPDATE HUD
```

#### Bomb Usage System
- Track bombs remaining in bag (starts at 1, refills in dungeon entrances)
- Bomb drop animation triggered on use
- Update HUD bomb counter when bomb count reaches 0
- Refill logic: check if player is at dungeon entrance

---

## Important Notes
- Inventory updates should occur during rendering phase
- Use sprite multiplexing to show weapon icon next to Link
- Consider saving all inventory data for auto-save functionality