# Combat Mechanics Documentation

## Purpose
Understand combat rules and enemy behaviors for:
- Enemy attack patterns  
- Player defensive mechanics
- Weapon damage values
- Boss battle strategies

---

## Basic Combat Rules

### Melee Attack System

```assembly
MELEE_ATTACK_RULES:
    Sword swing animation takes ~10 frames
    
    Hit detection:
        1. Press attack button
        2. Animation plays immediately
        3. Strike zone checks for enemies
        
    Damage application:
        . Hits register on frame contact
        . Multiple hits may be needed vs armored targets
```

### Projectile Attack Rules

```assembly
PROJECTILE_ATTACK_RULES:
    Arrows/Bombs have flight delay
    
    Hit detection timing:
        - Fire immediately at press
        - Tracks to target if multiple enemies present
        - Stops after hitting first target
    
    Accuracy rules:
        . Aimed shots hit intended target
        . Spread attacks hit random enemies in range
```

---

## Enemy Behavior Patterns

### Basic Enemy Types & Behaviors

```assembly
ENEMY_BEHAVIOR_TYPES:
    
    Type 1 - Static Guard:
        - Patrols fixed path
        - Attacks when Link enters range
        - Weak point: Rear
    
    Type 2 - Chaser:
        - Follows Link continuously
        - Stops attacking when out of view
        - Vulnerable from front
        
    Type 3 - Shooter:
        - Stands in position
        - Fires projectiles at approach
        - Requires dodge mechanic
```

### Enemy Attack Patterns

```assembly
ENEMY_ATTACK_PATTERNS:
    
    Pattern 1 - Swing Attack:
        - Animation plays on cooldown
        - Warning telegraph possible
        
    Pattern 2 - Projectile:
        - Charges before firing
        - Aims at current position
        
    Pattern 3 - Rush Attack:
        - Teleports or runs closer
        - Fast but short-range
```

### Enemy AI States (Simple)

```assembly
ENEMY_AI_STATE_MACHINE:

    Idle State:
        . Patrol between waypoints
        . Face toward last movement direction
    
    Alert State:
        . Activated when player detected
        . Stop patrol, face player
        
    Attack State:
        . Choose attack pattern based on state
        . Execute animation with cooldown
        
    Death/Defeated State:
        . Animation plays briefly
        . Remove from active sprites list
```

---

## Boss Battle Rules

### Phase-Based Combat

```assembly
BOSS_PHASE_SYSTEM:
    
    Phase 1 - Tutorial Phase:
        . Simple attack pattern
        . Introduce mechanics
        
    Phase 2 - Main Encounter:
        . Full attack repertoire
        . Increased aggression
    
    Phase 3 - Critical Health:
        . Boss uses special attacks
        . Vulnerability windows open
```

### Boss Weakness Triggers

```assembly
BOSS_WEAKNESS_CONDITIONS:
    
    Trigger conditions:
        - Deplete shield HP bar first
        - Strike vulnerable back spot
        - Wait for opening animation
        
    Reward phases:
        - New weapon becomes effective
        - Damage multiplier increases
```

---

## Player Defensive Mechanics

### Blocking System (if implemented)

```assembly
BLOCKING_MECHANICS:
    
    Shield activation:
        . Press item button to activate shield
        . Icon shows when ready
        
    Block state rules:
        - Reduces damage significantly
        - Cannot dodge while blocking
        - Blocks projectiles and melee
    
    Block counters:
        - Time out after duration
        - Breakable on sustained hits
```

### Evasion Patterns

```assembly
EVASION_PATTERNS:
    
    Roll mechanic:
        . Quick movement animation
        . Short cooldown window
        
    Dodge rules:
        - Only available when not blocking
        - Vulnerable during roll animation
        - Resets enemy attack windows
```

---

## Combat State Machine

### Player Action Flow

```assembly
PLAYER_COMBAT_STATES:

    Idle State:
        . Not engaged in combat
        . Can move freely
        
    Attacking State:
        . Animation plays
        . Cannot block/evade during swing
        
    Blocking State:
        . Shield active
        . Reduced damage incoming
        
    Dashing State:
        . Quick movement burst
        . Vulnerable but evasive
    
    Hit State:
        . Invulnerable briefly
        . Cannot take other actions
```

---

## Damage Calculation Rules

### Health System

```assembly
HEALTH_MANAGEMENT_RULES:

    Damage types:
        - Melee attack: Fixed value per hit
        - Projectile: Randomized or fixed
        - Boss attack: Variable based on health
    
    Healing mechanics:
        - Heart pickup restores full life
        - Magic heal spell (if available)
        
    Max health cap: 9 hearts (C64 limit)
```

---

## Combat Tips & Best Practices

### Effective Strategies

1. **Keep distance** when enemy shoots projectiles
2. **Approach** when melee attacks dominate  
3. **Time blocks** during attack animations
4. **Use arrows** for out-of-reach enemies
5. **Wait for openings** before striking bosses

---

## Important Notes - Combat Design

### C64 Constraints

- No complex hitbox systems (simple rectangle checks)
- Limited simultaneous combat entities
- Audio feedback only (no visual particles for hits)
- Simple health display per player

### Balance Considerations

- Weapon damage should scale with progression
- Boss difficulty increases mid-game
- Player has time to react (forgiving timing windows)