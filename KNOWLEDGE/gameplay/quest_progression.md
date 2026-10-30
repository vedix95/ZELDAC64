# Quest Progression System Documentation

## Purpose
Understand quest flow and progression triggers for:
- Main story questline  
- Side quest mechanics
- NPC interaction sequences
- Victory condition definition
- Game over scenarios

---

## Main Quest Flow (C64 Zelda Style)

### Story Arc Structure

```assembly
MAIN_QUEST_FLOW:
    Act 1 - Intro & Training
        . Meet initial guide character (Sheikah-like figure)
        . Tutorial dungeon with weak enemies
        . Learn basic controls and item usage
        
    Act 2 - First Dungeon Bosses
        . Visit each of first few dungeons
        . Defeat boss in each location
        . Collect dungeon-specific weapon
        
    Act 3 - Mid-Game Challenges
        . Face stronger enemy types
        . Discover new abilities/items
        . Return to main hub area
        
    Act 4 - Final Stretch
        . Access secret/hidden areas
        . Prepare for final confrontation
        . Face game-ending boss
    
    Act 5 - Victory & Credits
```

### Dungeon Progression Rules

```assembly
DUNGEON_ENTRY_RULES:
    Each dungeon numbered sequentially (1-9)
    
    Entry requirements per dungeon:
        . Key item needed to enter door
        . Specific weapon to defeat boss
        . Previous dungeon items collected
        
    Exit logic:
        . Stairs at back lead to overworld
        . Can return via warp point or stairs
```

---

## Side Quest Mechanics

### Hidden Objective Types

```assembly
SIDE_QUEST_CATEGORIES:
    1. Collect all rupees in region
    2. Find hidden chests/containers
    3. Rescue trapped NPC characters  
    4. Complete optional puzzles
    5. Secret character encounters
    
Quest Completion Rewards:
    - Hidden item locations unlocked
    - Cutscenes triggered
    - Title screen credit shown
```

### Quest Flag Tracking

```assembly
QUEST_STATE_STORAGE:
    .byte quest_1_completed      ; Boolean flag
    .byte quest_2_completed
    .byte main_story_progressed  ; Story stage
    
Quest trigger logic:
    Check flags before offering side objectives
```

---

## NPC Interaction Rules

### Quest-Giver NPCs

```assembly
NPC_QUEST_GIVERS:
    Fixed positions per location
    
    Common roles:
        - Merchant (item sales)
        - Guard (story hints)
        - Helper (ability upgrades)
        
    Trigger conditions:
        . Specific story flag set
        . Player reaches NPC zone
```

### Dialogue System Rules

```assembly
NPC_DIALOGUE_SYSTEM:
    Linear dialogue trees only
    
    Interaction pattern:
        1. Press interaction key near NPC
        2. Fixed dialogue plays (no branching)
        3. Quest triggered if available
        
    No deep conversation mechanics (C64 limit)
```

---

## Victory Conditions

### Game Win Requirements

```assembly
VICTORY_CONDITIONS:
    Main quest complete when:
        . All dungeon bosses defeated
        . Final boss vanquished
        . Ending cutscene plays
    
    Optional completion check:
        . Side objectives all done?
        . All items collected?
    
    Victory screen shows:
        - Credits roll
        - "The End" message
```

### Game Over Scenarios

```assembly
DEFEAT_CONDITIONS:
    Game over triggers:
        1. Lose all life points (hearts)
        
    Death penalties:
        . Return to save point/checkpoint
        . Items remain collected
        
    No permanent death mechanics in classic C64 Zelda
```

---

## Boss Battle Rules

### Encounter Triggers

```assembly
BOSS_ENGAGEMENT_RULES:
    Boss appears when:
        1. Link enters boss arena door
        2. All previous enemies defeated
        
    Boss fight phases:
        . Introduction animation
        . Active battle sequence  
        . Victory/defeat outcomes
    
    Boss defeat rewards:
        - Dungeon weapon unlocked
        - Life upgrade opportunity
        - Cutscene showing story progression
```

### Boss Weakness Patterns

```assembly
BOSS_WEAKNESS_PATTERNS:
    Each boss has specific attack pattern
    
    Common weaknesses:
        . Certain weapons more effective
        . Avoid enemy projectiles (dodge)
        . Strike during opening animation window
        
    Boss health ranges:
        . Early dungeon bosses: 2-4 hits
        . Mid-game bosses: 5-8 hits  
        . Final boss: Progressive phases
```

---

## Quest Completion Rewards

### Achievement Triggers

```assembly
COMPLETION_REWARDS:
    Main story complete → Victory cutscene
    Side objectives done → Hidden area unlocked
    All items collected → Secret bonus level (optional)
    
Reward examples:
    - Special title screen credits
    - "Perfect Play" achievement
```

---

## Important Notes - Quest Systems

### C64 Limitations

- No complex branching quest trees
- Linear story progression only
- Limited dialogue storage space
- Single-player focus simplifies design

### Design Tradeoffs

- Keep quests simple for performance
- Avoid too many concurrent objectives
- Use flags rather than state machines for tracking