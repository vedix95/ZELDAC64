# World Alignment Rules Documentation

## Purpose
Understand alignment and positioning rules for:
- Sprite positioning grid system  
- Room layout constraints
- Object placement patterns
- Camera/screen boundary logic

---

## Grid-Based Positioning System

### Screen Cell Grid (C64 VIC-II)

```
Grid Resolution: 40 columns × 25 rows
Tile Size: 16×16 pixels = 4 screen cells
Character Cells: Each cell maps to one video RAM position

Alignment Rules:
    - All sprites must align to 4×4 pixel blocks (screen cells)
    - Objects cannot occupy partial tiles
    - Screen update occurs every VSYNC
    
Sprite Y-Sort Priority:
    Lower sprite Y = rendered ABOVE higher sprite Y
    Background characters rendered last (after all sprites)
```

### Object Placement Constraints

#### Character Cell Alignment
```assembly
PLACE_OBJECT_ON_GRID:
    ; Objects must align to screen cell boundaries
    
    Valid X positions: 0-39 (40 columns)
    Valid Y positions: 0-24 (25 rows)
    
    Each object occupies:
        - Sprite position: Single screen cell
        - Character position: Video RAM grid location
        
    No sub-pixel positioning supported
```

#### Dungeon Object Rules
```assembly
DUNGEON_OBJECT_ALIGNMENT:
    Walls/doors aligned to tilemap grid
    
    Enemy spawn positions:
        Predefined in dungeon header table
        Each enemy occupies own screen cell region
        
    Item containers:
        Fixed layout locations defined by level data
```

---

## Room Boundary Alignment Rules

### Overworld Room Layout

```
Room Dimensions: 40×20 tiles = 80×40 screen cells per room
Total Grid: 10 rooms × 5 rows = 50 rooms total

Boundary Rules:
    - Link cannot enter walls (solid edges)
    - Room doors appear at predefined edge locations
    - Fountain/tree/bush decorations placed at specific points
    
Door Placement:
    - Only on room boundaries
    - Entrance/exit aligned with adjacent room connection
```

### Dungeon Floor Layout

```assembly
DUNGEON_FLOOR_RULES:
    Walls placed on tilemap grid only
    
    Stairs:
        Fixed positions (usually at corners)
        Single set per floor level
        
    Boss Room:
        Special indicator (different tile pattern)
        Located at dungeon entrance/exit
```

---

## NPC Positioning Rules

### Static NPC Placement

```assembly
NPC_POSITION_CONSTRAINTS:
    Merchants placed at fixed locations
    
    Guard positions:
        - Entrance to each dungeon
        - Fixed patrol route points
        
    Event NPCs:
        Positioned per level data table
```

### Patrol Movement (if implemented)

```assembly
NPC_PATROL_RULES:
    Guards follow predefined waypoints
    
    Waypoint sequence stored in table:
        .byte guard_waypoint_0,y       ; First position
        .byte guard_waypoint_1,y       ; Second position
        ...
        
    Move from waypoint A to B when triggered
```

---

## Camera Boundary Rules (C64 Limitations)

### No True Camera Scrolling

```assembly
STATIC_VIEWPORT_RULE:
    ; C64 Zelda has fixed viewport
    
    Overworld: Shows entire dungeon room at once
    Dungeon rooms: View all walls/items simultaneously
    
    No zoom-in/zoom-out supported
    Fixed screen size (25×40 cells)
```

### Screen Edge Clipping Rules

```assembly
OBJECT_CLIP_RULES:
    Objects near edge visible but may be cut off by viewport
    
    No wrap-around logic
    Objects outside viewport not rendered
    
    Sprites clipped if Y > 24 or Y < 0
```

---

## Z-Depth Rendering Rules

### Single-Plane Depth System

```assembly
SIMPLE_DEPTH_RENDERING:
    ; C64 VIC-II has no true 3D depth
    
    All sprites render at same Z-plane
    Foreground/background determined by Y position only
    
    No depth buffers or Z-sorting needed
```

### Sprite Occlusion Rules

```
1. Lower sprite Y rendered first (behind)
2. Higher sprite Y rendered last (in front)  
3. Background drawn after all sprites
4. Sprites never clip into background characters
```

---

## Important Notes - C64 Alignment System

### Hardware Constraints

- **Screen cells**: 4×4 pixel blocks minimum for objects
- **Character positions**: Each position needs video RAM byte
- **Color RAM**: Must align with character cell grid
- **Sprite priority**: Strict Y-sort ordering required

### Performance Considerations

- Sprite positions must be set before VSYNC
- Character data in video RAM updated per frame
- Color RAM aligned to character grid boundaries