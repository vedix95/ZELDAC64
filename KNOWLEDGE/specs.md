# 🎮 The Legend of Zelda (Commodore 64 Port) — Complete Specification Document

## ⚠️ Legal Disclaimer & Copyright Notice

**The Legend of Zelda** is a registered trademark of Nintendo Co., Ltd. This project is a **fan-made educational recreation** created by an amateur computing enthusiast using AI assistance.

- ✅ Created for educational preservation and technical exploration
- ❌ NOT affiliated with, endorsed by, or authorized by Nintendo
- ❌ NOT for commercial distribution
- ⚠️ These sprite binary files contain fan-made recreations inspired by original NES Zelda (via ASCII art generation), not Nintendo proprietary assets

## 1. Project Overview

### Goals

- Create a faithful recreation of The Legend of Zelda (1986) for Commodore 64
- ACME 6510 assembler for all source code
- Full Overworld: 128 rooms + GPS radar
- All 9 Dungeons with puzzles, bosses, key-door mechanics
- Secret caves (Snail Rocks) at Zone D-4

### Technical Approach

| Component | Implementation |
|-----------|----------------|
| CPU | MOS Technology 6502/6510 @ 0.985MHz (PAL) |
| Graphics | VIC-II Multicolor mode (40x25 screen, 8 hardware sprites) |
| Assembly | ACME Cross-Assembler |
| Sound | SID 6581 dual stereo capability |
| Memory Management | Magic Desk Type 19 (256KB cartridge) with dynamic banking |

---

## 2. System Architecture

### C64 Memory Map

The Commodore 64 features 64 KB of RAM, shared with ROMs and I/O:

- $0000-$00FF: Zero Page (fast pointers, player state)
- $0400-$07E7: Video RAM (screen display, 40x25 chars)
- $D800-$DBE7: Color RAM (VIC-II color palette)
- $2000-$27FF: Charset RAM (custom font from tiles.txt)
- $DE00: Cartridge bank control register

### Banking Control

; Enable cartridge -> map to $8000..$9FFF
assembly:
CART_ENABLE  = #$37    ; Bank active, reads from cartridge

; Disable cartridge -> normal RAM mode
CART_DISABLE = #$36    ; Use resident engine code in RAM
```

---

## 3. Cartridge Banking Specification

### Magic Desk Type 19 Layout (512KB / 64 Banks x 8KB)

| Bank # | Name           | Range         | Content Description                        | Size     |
|--------|----------------|---------------|--------------------------------------------|----------|
| 0      | BOOT           | $8000-$9FFF   | Cartridge bootloader, CBM80 reset vector  | ~655 B   |
| 1-3    | INTRO          | $8000-$9FFF   | Cinematic intro (waterfall, scroller)      | ~24 KB   |
| 4-9    | CORE           | $8000-$9FFF   | Resident engine: player, AI, inventory     | ~14 KB   |
| 10     | OW_SPRITES     | $8000-$9FFF   | Overworld enemy sprites                    | 8,192 B  |
| 11     | DUNG_SPRITES   | $8000-$9FFF   | Dungeon-specific enemies                   | 8,192 B  |
| 12     | BOSS_SPRITES   | $8000-$9FFF   | Boss sprites (Aquamentus, Gleeok, etc.)   | 8,192 B  |
| 13     | NPC_SPRITES    | $8000-$9FFF   | NPCs: shopkeepers, fairies, Moblins       | 8,192 B  |
| 14-17  | OW_CHUNKS      | $8000-$9FFF   | Overworld chunks (streamed to $C000)       | ~3 KB    |
| 18-26  | DUNGEONS       | $8000-$9FFF   | Individual dungeon levels                  | ~2.3 KB  |
| 27     | OV_INV         | $8000-$9FFF   | Inventory overlay                         | ~4.5 KB  |
| 28     | OV_CAVE        | $8000-$9FFF   | Secret cave renderer                       | ~3.1 KB  |
| 29-31  | Reserved        |               | Future content (Quest 2, new regions)      |          |

### Streaming Workflow

[Cartridge Boot] -> $DE00 = Bank 0 (Unpacker)
```
     -> [Copy Banks 1-3 to RAM $0800-$67FF] (Intro decompress)
         -> [Game Start - SYS 2061] -> Disable cartridge, use resident engine
     ```

---

## 4. Sprite Assets Documentation

### 4.0 Overview: Binary Asset Storage

The following 8KB binary files contain sprite data generated from ASCII art sources (fan-made recreations):

| File           | Size    | Content                       | Bank # | Target Address |
|----------------|---------|-------------------------------|--------|----------------|
| sprites_ow.bin | 8,192 B | Overworld enemies (Dodongo)   | 10     | $2800          |
| sprites_dung.bin| 8,192 B| Dungeon enemies              | 11     | $2800          |
| sprites_boss.bin| 8,192 B| Boss sprites (Aquamentus etc)| 12     | $3400          |
| sprites_npc.bin | 8,192 B| NPCs, chests, fairies        | 13     | $2800          |

### 4.1 Security & Privacy Notes for Binary Data

**Important:** These files are **NOT** Nintendo proprietary assets. They are fan-made recreations created using:
- ASCII art definitions from `assets/*.txt` source files
- Manual recreation inspired by original NES game structure
- Procedural generation via Python tools

**Storage Format for Documentation:**
- Use **hex-encoded** text representations (not Base64 binary images)
- Avoid embedding actual binary image data in documentation
- Document metadata and provenance clearly
- Do not redistribute without consulting Nintendo legal teams

### 4.2 Overworld Enemies Bank (sprites_ow.bin) - Bank 10

**Enemy Roster:**
- Bytes 0–1023   : Stalfos (Skeleton Warrior)
- Bytes 1024–2K  : Armos (Statue Guardians)
- Bytes 2K–3K    : Ghini (Goblin Minions)
- Bytes 3K–4K    : Slimes (Green Blob Enemies)
- Bytes 4K–5K    : Moblins (Troll Minions)
- Bytes 5K–6K    : Dodongo (Tank Enemies)
- Bytes 6K–7K    : Keese (Bat Flying Enemies)
- Bytes 7K–8K    : Goriyas (Fire Throwing Zombies)

### 4.3 Dungeon Enemies Bank (sprites_dung.bin) - Bank 11

**Dungeon-specific Enemies:**
- Bytes 0–1K    : Level 1 (Eagle): Stalfos, Armos, Ghini
- Bytes 1K–2K   : Level 2-3: Keese, Slimes, Dodongo
- Bytes 2K–3K   : Level 4-6: Armos Statues, Octoroks

- Bytes 3K–4K   : Level 7-9 (Demon/Mountain): Gleeok, Manhandla
**Sample Hex Data:**
```
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 82 00 00 96 00 02 aa 80 02 aa 80 0a aa a0
```

### 4.4 Sprites Bosses Bank (sprites_boss.bin) - Bank 12

**Boss Roster:**
- Bytes 0–1023   : Aquamentus (Dragon Horn — Donjon 1)
- Bytes 1024–2K  : Dodongo (Volcano Maw — Donjon 2)
- Bytes 2K–3K    : Manhandla (Multi-Armed Monster — Donjon 3)
- Bytes 3K–4K    : Gleeok (4-Headed Dragon — Donjons 4, D4)
- Bytes 4K–5K    : Digdogger (Butterfly/Snake — Donjon 5)
- Bytes 5K–6K    : Gohma (Giant Eye — Donjon 7)


**NPC Roster:**
### 4.5 Sprites NPCs Bank (sprites_npc.bin) - Bank 13
- Bytes 0–2K     : Old Man (wooden/magical/white sword caves)
- Bytes 2K–3K    : Fairies (heal sprite, heart containers)
- Bytes 4K–5K    : Treasure Chests (opening animation)

- Bytes 3K–4K    : Moblins (standard, secret grotta)
### 4.6 VIC-II Rendering Details

**Sprite Registers:** $07F8–$07FF (8 VIC-II hardware sprites)
**Color RAM:** $D800–$DBE7 (individual char color + multicolor enable)

### Tilemap Generation

Each game tile is 16x16 pixels, composed of a 2x2 block of 8x8 characters:
- Overworld room: 20x10 tiles = 40x20 characters on display
- HUD banner: 40x5 characters (hearts, mini-map, rupee counters)

### Sprite Multiplexer System

To handle Link, weapons, and up to 8 enemies simultaneously:
1. Raster IRQ Slicing:
   - Raster line 0: HUD split, status bar rendering
   - Raster lines 50-220: Active playfield with sprite sort
   - Mid-frame IRQ: Repositions sprite registers

   - Multicolor 0/1 globally assigned for Link/enemies
2. Color Multiplexing:
   - Sprite colors reassigned per enemy type dynamically

```
Bytes 0–511    : Level 1 (Eagle): Stalfos, Armos, Ghini
Bytes 512–1K   : Level 2-3: Keese, Slimes, Dodongo
Bytes 1K–1.5K  : Level 4-6: Armos Statues, Octoroks
Bytes 1.5K–2K  : Level 7-9 (Demon/Mountain): Gleeok, Manhandla
```

**Sample Hex Data:**
```
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 82 00 00 96 00 02 aa 80 02 aa 80 0a aa a0
```

---

## 5. Build System & Tools

### Makefile Targets

```makefile
# Makefile for ACME 6510 Assembly
CC = acme
AS = as6510
LD = ldc2

all: boot.bin intro.bin core.bin

boot.bin: boot.s |

intro.bin: intro.s |
core.bin: core.s sprites/*.bin |

clean:
	- rm -f *.bin *.o

```

### Required Tools

- [ACME](https://www.acme.com/) Cross-Assembler (6510)
- LD C2 Linker for Magic Desk Type 19
- Python scripts for sprite generation (scripts/generate_sprites.py)

---

## 6. File Structure

zelda/
```
├── specs.md                      # This documentation file
├── Makefile                      # Build automation
├── src/
│   ├── boot.s                    # Cartridge bootloader
│   ├── intro.s                   # Cinematic intro sequence
│   └── core.s                    # Resident engine code
│
├── assets/
│   ├── tiles.txt                 # Character set definitions
│   └── enemies.txt               # ASCII art sprite sources
│   ├── ow.bin                    # Overworld enemies (8KB)
├── sprites/
│   ├── dung.bin                  # Dungeon enemies (8KB)
│   ├── boss.bin                  # Boss sprites (8KB)
│   └── npc.bin                   # NPC sprites (8KB)
├── scripts/
│   └── generate_sprites.py       # Python sprite generator
└── output/
    ├── boot.bin                  # Built bootloader
    └── core.bin                  # Resident engine image
```


## 7. Rendering Pipeline

### VIC-II Graphics System
**Display Modes**:
- Multicolor mode (8 colors via 2 bits per char)
- Screen resolution: 40x25 characters = 800x400 pixels
- Sprite priority: Sprites overlay background, sorted by Y position

**Color RAM:** $D800–$DBE7
- Each 2-byte entry: Character color (high byte) + Multicolor flag (low byte)

- Link uses sprites 0-1 (weapon slot + player)
**Sprite Registers:** $07F8–$07FF
- Enemies use remaining slots with dynamic assignment
- 8 hardware sprites, each with X/Y position and priority


---
## 8. Audio Subsystem (SID)

### SID Chip Capabilities

- 3 independent voice channels (noise, wave, triangle)
**Voice Configuration**:
- Dual stereo output via panning

### Music Implementation

- Use ACME 6510 assembler for SID code
- Sample format: SPC compression with custom decompressor
- Real-time synthesis for short sound effects

### Sound Effects

- Weapon sounds: Sword swing, bomb explosion, magic circle
- Item pickup: Rupee chime, heart sound, fairy whistle
- Enemy death: Bone clatter, slime squelch, dragon roar

---
## 9. Security & Privacy Notes


### Binary Data Handling

When working with binary sprite data:
- Always document the provenance of sprite data
- Include clear licensing information for all assets
- Use hex encoding instead of embedding binary images
- Store metadata separately from binary content

**Do Not:**
- Redistribute Nintendo-proprietary ROM data without authorization
- Embed binary images directly in documentation sources

**Best Practices:**
- Use hex-encoded text representations for documentation
- Avoid Base64 binary image data in markdown sources
- Document metadata and provenance clearly for all assets

---

**End of Specification Document**
