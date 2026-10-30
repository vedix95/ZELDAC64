# Enemy AI System Documentation

## AI State Machine Architecture

### Purpose
Understand enemy behavior implementation for:
- Patrol and tracking patterns
- Attack timing and ranges
- Death animation triggers
- Level-specific spawn logic

### State Machine Design

```
ENEMY_STATE_TABLE:
    .byte STATE_IDLE          ; 0 - Waiting
    .byte STATE_PATROL        ; 1 - Moving pattern
    .byte STATE_CHASE         ; 2 - Pursuing Link
    .byte STATE_ATTACK        ; 3 - Attacking
    .byte STATE_DIE           ; 4 - Death sequence
```

### State Definitions

#### STATE_IDLE (0)
- Enemy waits at spawn location
- Random movement timer (10-50 frames)
- May initiate patrol when timer expires

#### STATE_PATROL (1)  
- Follows predefined patrol route
- Patrol points stored in pattern table
- Stop and reset on reaching waypoint

#### STATE_CHASE (2)
- Active pursuit when Link enters detection range
- Update position toward player each frame
- Use collision avoidance if needed

#### STATE_ATTACK (3)
- Fire projectile at close range
- Or melee attack for ranged enemies
- Animation plays during attack window

#### STATE_DIE (4)
- Triggered on damage threshold exceeded
- Play death animation frames
- Drop items/loot if applicable
- Return to idle after completion

### Patrol Pattern System

#### Pattern Storage
```assembly
PATROL_TABLE:
    .byte dx, dy             ; Movement delta per step
    .byte state_next         ; Next state after step
    .byte timer              ; Frames until next action
    .byte loop_count         ; Remaining iterations
```

### AI Decision Tree (Per Enemy Frame)

```
[Frame Start]
    ↓
[Check State == DIE?] → Yes: Play death, return to IDLE
    ↓ No
[Link in Detection Range?]
   YES → TRANSITION TO CHASE
   NO  → Continue current state or patrol timer
    ↓
[Update Position Based on Current State]
    ↓
[Handle Collisions/Obstacles]
    ↓
[Advance Frame Counters]
```

### Enemy-Specific AI Patterns

#### Stalfos (Skeleton)
- Slow patrol in overworld
- Chases Link when approached
- Attacks with melee swipe
- Drops bones on death

#### Armos (Statue)
- Idle until Link approaches
- Transitions to chase mode
- Breaks statue animation mid-chase
- Drops gold if damaged

#### Slimes
- Random bounce movement
- Slow health pool
- Squish effect on death

### Debug AI Tools

- Toggle enemy states via debug key
- Force all enemies into patrol mode
- Disable enemy tracking for stealth testing