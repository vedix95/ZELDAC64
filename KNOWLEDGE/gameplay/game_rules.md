# Game Rules Documentation

## Purpose
Understand official and implicit Zelda game rules for:
- Movement restrictions
- Combat mechanics  
- Puzzle solving patterns
- NPC interaction logic
- World physics engine

---

## Official C64 Zelda Game Rules

### Movement Rules

```
1. Link can only move to adjacent tiles (no diagonal)
2. Walls block movement unless doors are opened
3. Water requires swim ability learned mid-game
4. Stairs teleport to next floor level
5. Hidden passages require bomb activation
```

### Combat Rules

```
1. Enemies defeat via melee or projectile attack
2. Bosses require specific strategy (weak points/timing)
3. Bomb items consume one when activated (delayed explosion)
4. Arrow ammunition limited per item container
5. Hearts restore after defeating boss in current dungeon
```

### Item Usage Rules

```
1. Bombs have short fuse before detonation
2. Arrows require bow weapon to use
3. Magic requires spellbook + MP management
4. Swords require sword slot equipment change
5. Shield blocks projectiles but takes damage if hit
```

---

## Implicit Alignment Rules

### World Alignment System

#### Tile Grid Alignment
```assembly
TILE_GRID_ALIGNMENT:
    ; All game objects snap to 16x16 pixel grid
    
    Link Position Alignment:
        - X/Y always multiple of 16 pixels
        - Movement updates at frame boundaries
        - Sub-pixel movement not supported
        
    Object Snap Rules:
        - Sprites align to screen cell grid (4×4 per tile)
        - Items placed in item containers (fixed positions)
        - Doors aligned with room edges
```

#### Z-Depth Alignment (Overworld Only)
```assembly
OVERWORLD_Z_ALIGNED:
    ; Simple single-plane rendering
    
    No true 3D: All sprites render on same "depth plane"
    Foreground vs background determined by Y position only
    Higher sprite Y = rendered below lower Y sprites
```

---

## Implicit Physics Rules (Undocumented)

### Collision Response

```assembly
HARD_WALL_COLLISION:
    Rule 1: Link cannot walk through walls
    Rule 2: Bump sound plays on wall collision
    Rule 3: Movement stops for current frame only
    
    Soft-Collision Objects:
        - Enemies: Pushed back slightly when hit
        - Projectiles: Stop immediately on impact
```

### Gravity & Falling Rules

```assembly
NO_GRAVITY_MODE:
    Rule 1: No gravity simulation in classic Zelda C64
    Rule 2: All sprites maintain fixed Y unless acted upon
    
    Dungeon Exception:
        - Stairs change floor level instantly
        - No falling mechanics (no chasms)
```

### Time-Based Rules

```assembly
DAY_NIGHT_CYCLE_DISABLED:
    Rule: Classic C64 Zelda has no day/night cycle
    
    Weather Rules:
        - No weather effects (C64 hardware limits)
        - Static overworld environment
```

---

## Puzzle Solution Rules

### Key Rules

```
1. Keys are one-time use (unless item shop restock)
2. Boss keys open boss door only
3. Small key opens small door in current dungeon
4. Big key opens big door (multiple locations)
5. Golden key used for final boss encounter
```

### Bomb Usage Rules

```
1. Activated bombs have 30-frame delay before explosion
2. Bombs explode in circular pattern (radius ~8 tiles)
3. Multiple bombs can be chained to destroy walls
4. Overworld bomb usage limited to destructible walls only
5. Bomb item refills at dungeon entrance/exit
```

### Magic Spell Rules

```
1. Fire spell: Burns enemies on contact
2. Shock spell: Electric arc damage
3. Heal spell: Restores hearts (limited charges)
4. Magic requires MP management (replenishes over time)
5. Magical items consumed on successful use
```

---

## NPC Interaction Rules

### Merchant Shop Rules

```
1. Items purchased with rupees only
2. Restock timer after purchase (or manual restock)
3. Certain shops only available in specific locations
4. Item prices increase if all stock sold out
5. Shop closes when Link exits and re-enters location
```

### NPC Dialogue Rules

```
1. NPCs say fixed phrases per encounter
2. Quest-specific dialogue triggers based on game state
3. No branching NPC conversations (linear text only)
4. NPC positions static after initial placement
5. Certain NPCs become unavailable after story progress
```

---

## Important Notes - C64 Zelda Specifics

### Hardware-Limited Rules

- **No true 3D**: All depth simulated via sprite Y-sorting
- **Limited colors**: Max 4 simultaneous colors per character
- **8 sprites max**: Must multiplex for many entities
- **Audio limited**: SID chip only (no advanced synthesis)

### Performance Constraints

- Rendering must complete within VSYNC window
- Bank switching occurs during intro/loading sequences
- IRQ handlers minimal to preserve frame timing