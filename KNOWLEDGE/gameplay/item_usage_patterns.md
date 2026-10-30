# Item Usage Patterns Documentation

## Purpose
Understand item interaction patterns and game logic for:
- Weapon pickup mechanics  
- Item container systems
- Quest progression triggers
- Inventory management rules
- Item restoration logic

---

## Weapon Pickup Rules

### Sword Upgrade System

```assembly
WEAPON_UPGRADE_FLOW:
    ; Link starts with sword slot = $00 (none)
    
    Dungeon 1 Boss Defeated:
        . Get short sword (weapon_slot = 1)
        . Sword icon appears next to player sprite
    
    Dungeon 2 Boss Defeated: 
        . Get long sword (weapon_slot = 2)
        . Can hit enemies from further range
        
    Final Boss Requirement:
        . Must have maximum weapon before encounter
```

### Weapon Slot Management

```assembly
WEAPON_SLOT_RULES:
    Link holds one weapon at a time
    
    Weapon slot values:
        $00 = None (no weapon equipped)
        $01 = Short sword
        $02 = Long sword  
        $03 = Fire bow
        
    Pickup logic:
        . New weapon replaces current in slot
        . Previous weapon remains available in dungeon (as item pickup)
```

---

## Arrow Usage System

### Ammunition Tracking

```assembly
ARROW_COUNT_RULES:
    Starts with 8 arrows per container
    
    Arrow mechanics:
        . Bow must be equipped to use
        . Each arrow shot decreases count by 1
        . Empty container shows icon without arrows
        
    Refill Locations:
        . Dungeon entrance (if game has restock mechanic)
        . Item pickup zones in dungeons
```

### Bow Usage Patterns

```assembly
BOW_USAGE_PATTERNS:
    Distance shots:
        . Hits enemies at range >1 tile
        . Lower hit probability vs melee weapons
        
    Close-range usage:
        . Wastes arrows on nearby targets
        . Melee preferred for close combat
```

---

## Bomb Bag System

### Bomb Usage Rules

```assembly
BOMB_MECHANICS:
    Starts with 1 bomb in bag
    
    Activation sequence:
        1. Press item button to activate bomb
        2. Bomb appears at Link's position (small sprite)
        3. Countdown timer begins (~30 frames)
        4. Circular explosion pattern triggers
        
    Explosion radius: ~8 tiles from center point
    
    Refill locations:
        . Dungeon boss rooms
        . Special refill stations
```

### Wall Destruction Rules

```assembly
WALL_DESTRUCTION_PATTERNS:
    Bombable walls have specific tile pattern
    
    Detection logic:
        . Compare wall tile type against destructible list
        . Only certain materials can be destroyed
        
    Damage types:
        . Soft bricks: One bomb destroys
        . Hard stone: Multiple bombs required
```

---

## Magic Spell System (if implemented)

### Spell Book Mechanics

```assembly
SPELL_BOOK_RULES:
    Starts with basic spells only
    
    Spell progression:
        . Fire spell learned mid-game
        . Shock spell unlocked later
        . Heal spell available early
        
    Mana management:
        . Spells consume MP (mana points)
        . MP regenerates slowly over time
```

### Spell Effect Rules

```assembly
SPELL_EFFECT_PATTERNS:
    Fire spell:
        - Creates fire projectile
        - Burns enemies on contact
        
    Shock spell:
        - Electric arc damage
        - Hits multiple targets in line
```

---

## Heart Container System

### Life Restoration Logic

```assembly
HEART_CONTAINER_RULES:
    Defeat dungeon boss → unlock life upgrade option
    
    Progress tracking:
        . Current hearts (1-9)
        . Pieces collected for next level
        
    Upgrade locations:
        . Specific NPCs in shops
        . Item pickup from chests after boss kill
```

### Life Piece Pickup Rules

```assembly
LIFE_PIECE_MERCANISM:
    Red heart container item found in dungeons
    
    Usage:
        . Can be equipped or unequipped
        . Shows when hearts are empty
        
    Maximum health capped at 9 hearts (C64 limit)
```

---

## Item Container Rules

### Storage System

```assembly
ITEM_CONTAINER_SYSTEM:
    Each item has dedicated storage slot
    
    Max container sizes:
        . Arrows: 8 per container
        . Bombs: Limited count (varies by type)
        . Other items: Single use typically
        
    Display rules:
        . Empty containers show blank icon
        . Partially filled shows item symbol + count
```

---

## Quest Trigger Rules

### Story Progression Logic

```assembly
QUEST_TRIGGER_PATTERNS:
    Boss key pickup:
        . Only available after defeating previous dungeon boss
        . Found in chests at specific locations
        
    Golden key requirement:
        . Used for final boss encounter only
        . Collected near end of game
    
    NPC quest flags:
        . Certain NPCs give quests mid-game
        . Quest completion triggers new events
```

---

## Important Notes - Item Rules

### C64 Limitations

- Limited item storage (must choose what to carry)
- No permanent save without external memory
- Item restocking depends on game implementation
- Single player experience simplifies ruleset

### Design Considerations

- Balance weapon power progression
- Ensure arrow usage feels meaningful
- Bomb timing provides puzzle element