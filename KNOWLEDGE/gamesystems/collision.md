# Collision Detection System Documentation

## Purpose
Understand collision detection implementation for:
- Link vs walls/objects
- Enemy vs environment
- Projectile vs entities
- Item pickup triggers

---

## Grid-Based Collision (Tilemap)

### Tile Coordinate System

```
Screen Resolution: 40 columns × 25 rows
Tile Size: 16×16 pixels (4 screen cells per tile)
```

### Collision Check Functions

#### Wall Collision (Link Movement)
```assembly
CHECK_WALL_COLLISION:
    ; Get current grid position
    LDA current_room_y          ; Y coordinate (screen cells)
    LSR                         ; Divide by 2 for tile row
    CLC
    ADC #$04                    ; +4 for room offset
    
    LDA current_room_x          ; X coordinate  
    LSR
    STA temp_x,addr             ; Store grid X
    
    ; Map to wall data structure
    STA wall_data,x             ; Check at [temp_y][temp_x]
    
    ; If wall bit set: STOP movement
```

#### Entity Collision (Player vs Enemy)
```assembly
CHECK_ENTITY_COLLISION:
    LDA player_sprite.y
    LDA enemy_sprite.y
    
    CMP                      ; Compare Y positions
    BEQ check_x_collision    ; Same row, check X
    RET                       ; Different rows, no collision
    
check_x_collision:
    LDA player_sprite.x
    LDA enemy_sprite.x
    BNE  not_colliding        ; Same column offset, no overlap
    ; Calculate bounds...
```

### Hitbox Types

#### Link Hitboxes
- Attack range: Sword/weapon specific
- Body collision: Full sprite bounding box
- Magic circle: Expanding radius hit detection

#### Enemy Hitboxes
- Melee enemies: Forward-facing cone
- Projectile enemies: Small circular hitbox
- Flying enemies: Reduced collision area

### Collision Optimization

1. **Tilemap culling**: Only check walls in current room
2. **Sprite Y-sorting**: Process sprites by Y position
3. **Distance checks**: Use Manhattan distance for rough bounds
4. **AABB testing**: Axis-aligned bounding box overlap

---

## Object-Based Collision (Overworld)

### Chunk-Based Collision System

```assembly
OVERWORLD_COLLISION:
    LDA current_chunk,x         ; Get chunk data
    
    ; Check object bits in chunk
    BIT chunk_objects,x
        
    ; If collision bit set: resolve
```

### Resolving Collisions

1. **Wall collision**: Stop movement, play bump sound
2. **Enemy collision**: 
   - Take damage if enemy is hostile
   - Defeat enemy if Link has weapon
   - Push player back if hit
3. **Projectile collision**: Check projectile vs enemy/player hitboxes

---

## Important Notes
- Collision must occur before rendering update
- Use tilemap for static objects, bounding boxes for dynamic
- Handle collisions consistently across all subsystems