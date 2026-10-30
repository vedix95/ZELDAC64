# Project Roadmap & Milestones Documentation

## Purpose
Understand project milestones and development priorities for:
- Tracking current implementation status
- Identifying missing features
- Prioritizing future work
- Version control context

---

## Current Implementation Status

### ✅ Completed Components (Fully Implemented)

| Component | File Location | Description |
|-----------|---------------|-------------|
| Bootloader | `src/boot.s` | Cartridge initialization code |
| Intro Sequence | `src/intro.s` | Title screen & cinematic intro |
| Core Engine | `src/core.s` | Resident engine (6KB ROM space) |
| Memory Map | `memory.md` | Complete memory architecture |
| Banking System | `banking.md` | Magic Desk Type 19 cartridge banking |

### 🟡 In Progress Components

| Component | File Location | Description | Status |
|-----------|---------------|-------------|--------|
| Sprites | `sprites/ow.bin`, `sprites/dung.bin` | Overworld & dungeon enemy sprites | Binary data stored as hex |
| Level Streaming | `level_streaming.md` | Room-to-room transitions | Implemented |
| Collision Detection | `collision.md` | Entity-vs-environment physics | Implemented |

### 🟡 Partially Completed Components

| Component | File Location | Description | Status |
|-----------|---------------|-------------|--------|
| Audio System | `audio.md` | SID sound effects & initialization | Basic functionality |
| HUD/UI Display | `hud_ui.md` | Hearts, rupees, weapon icons | Rendered |
| Inventory Management | `inventory_system.md` | Rupee tracking, weapons, hearts | Data structures |

### ⏳ Future Development Priorities

1. **Save Game System** (`save_systems.md`) - Battery-backed storage
2. **Enemy AI Enhancement** (`enemy_ai.md`) - Advanced behaviors
3. **Dungeon Content** - Actual level layouts (not documented yet)
4. **Sound Music Implementation** - Expand SID usage beyond SFX
5. **Boss Battle Logic** - Specific boss encounter mechanics
6. **Cutscene Animation System** - Dialogue & story sequences

---

## Component Dependency Graph

```
Bootloader → Intro Sequence → Core Engine
                                         ↓
    ┌───────────────────────┬────────────┴──────────────┬────────────┐
    ↓                       ↓                           ↓            ↓
Memory Map              Banking System           Sprites       HUD/UI
    │                     │                        │             │
    └─────────┬───────────┴────────────────────────┼─────────────┘
              ↓                                    ↓
        Rendering               Audio          Collision
                              Side Effects     Detection
```

---

## Known Missing Components

1. **Actual dungeon level data** - Layout tiles not yet implemented
2. **Boss encounter logic** - Specific boss AI behaviors
3. **Dialogue system** - Text display & branching dialogue
4. **Save game persistence** - Battery-backed storage (optional)
5. **Full music tracks** - Background melody composition

---

## Development Milestones

### Phase 1: Core Engine (✅ Complete)
- Bootloader & intro sequence
- Basic engine structure
- Banking system integration

### Phase 2: Graphics System (🟡 In Progress)
- Sprite rendering for enemies
- HUD display implementation
- Collision detection

### Phase 3: Content Implementation (⏳ Planned)
- Level layouts
- Boss encounters  
- Dialogue sequences
- Music tracks

---

## Important Notes
- Not all planned features will be implemented in final release
- Consider what content is essential for gameplay completeness
- Evaluate whether to include optional features (save system, etc.)
- Document tradeoffs when cutting features for cartridge space constraints