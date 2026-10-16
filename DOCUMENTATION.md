# The Legend of Zelda C64 — Technical Architecture Documentation

This document provides a comprehensive technical overview of the Zelda C64 implementation, designed for the Commodore 64 (MOS 6510 CPU at ~0.985 MHz PAL / ~1.023 MHz NTSC, VIC-II graphics, SID 6581/8580 sound generator).

---

## 1. System Architecture

### 1.1 Memory Map & 6510 Banking

The Commodore 64 features 64 KB of RAM, but shares its address space with ROMs (BASIC, KERNAL, Character ROM) and hardware I/O registers ($D000–$DFFF). The processor port at `$0001` controls the active memory configuration:

| Memory Range | Mode / Configuration | Usage |
| :--- | :--- | :--- |
| `$0000 - $0001` | 6510 On-chip Direction / Port | Memory banking control register (`$35`, `$36`, `$37`) |
| `$0002 - $00FF` | Zero Page | Fast pointers (`ZP_SRC`, `ZP_DEST`), player state, world coordinates, frame counter |
| `$0100 - $01FF` | Stack | 6510 CPU hardware stack |
| `$0200 - $03FF` | System Variables | Interrupt vectors, KERNAL disk communication parameters |
| `$0400 - $07E7` | Video Matrix (Screen RAM) | 40×25 character grid displaying the active room (1000 bytes) |
| `$07F8 - $07FF` | Sprite Pointers | 8 hardware sprite data block pointers for VIC-II |
| `$0801 - $1FFF` | Code & System Data | BASIC upstart (`SYS 2061`), main loop, raster interrupt service routine |
| `$2000 - $27FF` | Multicolor Character Set | Custom 256-character font generated from `assets/tiles.txt` |
| `$2800 - $7FFF` | Resident Engine Code & Data | Sprite multiplexer, player engine, enemy AI, inventory renderer, items |
| `$8000 - $9FFF` | Dynamic Scratch RAM | Audio buffers, decompression tables, level editor buffers |
| `$A000 - $CFFF` | Map Dynamic Overlay Zone | Dynamic map data stream-loaded from D64 disk (`MAP_OW` or `MAP_UW`) |
| `$D000 - $DFFF` | VIC-II, SID, CIAs & Color RAM | Hardware registers and Color RAM at `$D800 - $DBE7` |
| `$E000 - $FFFF` | KERNAL ROM / RAM | Operating system routines for IEC disk I/O, reset and NMI vectors |

---

## 2. D64 Disk Structure & Streaming Engine

To accommodate the full 128-room overworld and underground dungeons within the 64 KB RAM ceiling, the project uses a modular disk overlay architecture.

### 2.1 Disk Layout (`zelda.d64`)

The 1541 disk image (35 tracks, 683 sectors) contains:
- `INTRO`: Standalone prologue executable containing the animated waterfall, parchment text scroller, item gallery, and full SID soundtrack.
- `ZELDA`: Main game engine resident binary.
- `MAP_OW`: Compiled binary data for all 128 Overworld rooms (16×8 grid).
- `MAP_UW`: Compiled binary data for Underworld dungeon rooms.

### 2.2 KERNAL Streaming I/O (`src/disk.asm`)

When switching between the Overworld and Underworld (or loading a game):
1. **DMA & IRQ Safe Shutdown**: Sprites and raster IRQs are safely disabled to avoid timing jitter on the IEC bus.
2. **Device Detection**: Detects boot device number from `$BA` (defaults to Unit 8).
3. **KERNAL Calls**:
   - `SETNAM` (`$FFBD`): Sets filename (`MAP_OW` or `MAP_UW`).
   - `SETLFS` (`$FFBA`): Sets logical file number, device (8), and secondary address (0).
   - `OPEN` (`$FFC0`) and `CHKIN` (`$FFC6`): Establishes IEC serial input channel.
   - `CHRIN` (`$FFCF`): Streams byte payloads directly into `$A000`–`$CFFF`.
   - `CLOSE` (`$FFC3`) and `CLRCHN` (`$FFCC`): Closes the channel and restores default I/O.
4. **Engine Resume**: Reinitializes VIC-II registers, reactivates raster interrupts, and resumes gameplay.

---

## 3. Video & Rendering Pipeline

### 3.1 VIC-II Multicolor Mode

The graphics engine operates in standard Multicolor Character Mode:
- **Screen Memory**: `$0400`–`$07E7`.
- **Character Base**: `$2000` (VIC-II register `$D018` set to `%00011000` = screen at `$0400`, charset at `$2000`).
- **Color Layers**:
  - Background 0 (`$D021`): Transparent / Base background color (black).
  - Background 1 (`$D022`): Multicolor 1 (shared across all characters).
  - Background 2 (`$D023`): Multicolor 2 (shared across all characters).
  - Color RAM (`$D800`): Individual character color (bits 0–2: color; bit 3: multicolor enable).

### 3.2 Tilemap Generation (`tools/tilegen.py`)

Each game tile is 16×16 pixels, composed of a 2×2 block of 8×8 characters.
- Overworld room: 20×10 tiles = 40×20 characters on the 40×25 display.
- HUD top banner: 40×5 characters displaying life hearts, mini-map, rupee/key/bomb counts, and active items.

---

## 4. Sprite Multiplexer & Interrupt Handler

The Commodore 64 VIC-II hardware supports 8 hardware sprites per scanline. To support Link, weapons, and up to 8 simultaneous enemies, a dynamic raster interrupt multiplexer is implemented in `src/main.asm` and `src/enemies.asm`:

1. **Raster IRQ Slicing**:
   - Raster line 0: HUD split, status bar rendering, and frame counter tick.
   - Raster lines 50–220: Active playfield. Sprites are sorted vertically by Y-coordinate.
   - Mid-frame IRQ: Repositions hardware sprite registers and swaps sprite data pointers at `$07F8`–`$07FF` once the raster beam has passed previous sprite boundaries.
2. **Color Multiplexing**:
   - Multicolor 0 (`$D025`) and Multicolor 1 (`$D026`) are globally assigned for Link and enemy palettes.
   - Sprite individual colors (`$D027`–`$D02E`) are reassigned dynamically per enemy type.

---

## 5. Audio Subsystem (SID 6581/8580)

Music and sound effects are processed in `src/intro_music_data.asm` and executed on every frame during the vertical blank (50 Hz PAL / 60 Hz NTSC):

- **Voice 1**: Lead melody (Pulse wave with modulated duty cycle).
- **Voice 2**: Harmony / Counter-melody (Triangle and Sawtooth waves).
- **Voice 3**: Bassline & Percussion (Triangle wave bass + Noise burst percussion).
- **ADSR Envelope Engine**: Dynamic attack, decay, sustain, and release control per instrument note.

---

## 6. Build Pipeline & Tools

| Tool | Purpose | Source Assets | Target Output |
| :--- | :--- | :--- | :--- |
| `tools/sprgen.py` | Converts ASCII art sprites into 64-byte C64 sprite binary data | `assets/link.txt`, `enemies.txt`, `extra.txt` | `src/sprites*.asm` |
| `tools/tilegen.py` | Assembles charsets, tilesets, and overworld/underworld rooms | `assets/tiles.txt`, `world.txt`, `underworld.txt` | `src/charset.asm`, `src/tiles_data.asm`, `src/map_*.asm` |
| `tools/editor.py` | Interactive Python HTTP server with canvas GUI to paint rooms and edit enemies | `assets/world.txt`, `underworld.txt` | Direct asset updates + instant ACME recompile |
| `tools/convert_nes_world.py` | Extracts authentic NES overworld room layouts into C64 tile format | `assets/nes/*.txt` | `assets/world.txt` |
| `tools/extract_nes_sprites.py` | Extracts 2bpp NES pattern tables into C64 multicolor sprite format | `zelda.nes` | `assets/*.txt` |
| `tools/midi_to_sid.py` | Transcribes MIDI tracks into 6510 frequency and duration tables | `assets/*.mid` | `src/intro_music_data.asm` |
| `ACME` | Cross-assembler for 6502/6510 producing CBM binaries | `src/*.asm` | `build/*.prg`, `build/*.dat` |
| `c1541` | VICE disk utility building bootable 1541 D64 disk image | `build/*.prg`, `build/*.dat` | `build/zelda.d64` |