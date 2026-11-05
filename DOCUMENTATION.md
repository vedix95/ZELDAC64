# The Legend of Zelda C64 — Technical Architecture Documentation

This document provides a comprehensive technical overview of the Zelda C64 implementation, designed for the Commodore 64 (MOS 6510 CPU at ~0.985 MHz PAL / ~1.023 MHz NTSC, VIC-II graphics, SID 6581/8580 sound generator).

> *Création d'un passionné d'informatique rétro réalisée à l'aide de son IA préférée issue de chez Google.*

---

## 1. System Architecture

### 1.1 Memory Map & 6510 Banking

The Commodore 64 features 64 KB of RAM, but shares its address space with ROMs (BASIC, KERNAL, Character ROM) and hardware I/O registers ($D000–$DFFF). The processor port at `$0001` controls the active memory configuration:

| Memory Range | Mode / Configuration | Usage |
| :--- | :--- | :--- |
| `$0000 - $0001` | 6510 On-chip Direction / Port | Memory banking control register (`$35`, `$36`, `$37`) |
| `$0002 - $00FF` | Zero Page | Fast pointers (`ZP_SRC`, `ZP_DST`), player state, world coordinates, frame counter |
| `$0100 - $01FF` | Stack | 6510 CPU hardware stack |
| `$0200 - $03FF` | System Variables & Buffers | Tape buffer (`$0340..$03BF` cartridge unpacker, `$033C` dungeon state) |
| `$0400 - $07E7` | Video Matrix (Screen RAM) | 40×25 character grid displaying the active room (1000 bytes) |
| `$07F8 - $07FF` | Sprite Pointers | 8 hardware sprite data block pointers for VIC-II Bank 0 |
| `$0801 - $1FFF` | Code & Resident Logic | BASIC upstart (`SYS 2061`), main loop, input, Link player engine & collision |
| `$2000 - $27FF` | Multicolor Character Set | Custom 256-character font generated from `assets/tiles.txt` |
| `$2800 - $3FFF` | Dynamic Sprite Streaming Zone | Streamed from Cartridge Banks 10..13 (OW, Dung, Boss, NPC) |
| `$4000 - $9FFF` | Resident Game Engines & Audio | `tilemap.asm`, `transition.asm`, `items.asm`, `enemies.asm`, `dungeon.asm`, `hud.asm`, `sound.asm` |
| `$A000 - $BFFF` | Cartridge Overlays | On-demand streamed modules: Inventory/Map ($A000), Caves ($A000), Debug ($A000) |
| `$C000 - $CCFF` | Streamed Map Data | Active Overworld chunk or Dungeon room layout |
| `$CD00 - $CEFF` | High RAM Work Buffers | Active room buffer (`room_buf` at `$CD00`), transition buffer (`target_room_buf` at `$CE00`) |
| `$D000 - $DFFF` | VIC-II, SID, CIAs & Color RAM | Hardware registers and Color RAM at `$D800 - $DBE7` |
| `$E000 - $FFFF` | KERNAL ROM / RAM | Operating system routines for IEC disk I/O, reset and NMI vectors |

---

## 2. Cartridge Architecture & Memory Streaming Engine

To accommodate the full 128-room overworld, 9 dungeons, complete monster bestiary and overlay subscreens within the 64 KB RAM ceiling, the project uses a 512 KB (64 banks of 8 KB) Magic Desk Cartridge streaming architecture.

### 2.1 Cartridge Layout (`zelda.crt` - Magic Desk 512 KB)

The cartridge banks are organized as follows:
- **Bank 00**: Cartridge bootloader (`cart_boot.asm`, CBM80 hardware reset vector), unrolls the cinematic intro.
- **Banks 01..03**: Cinematic intro PRG (`$0800`–`$6800`) with animated waterfall, scroller, Triforce, item gallery, monster showcase and SID music.
- **Banks 04..09**: Resident Zelda game engine (`$0800`–`$C800`), unpacked into RAM in 0.2s when pressing Start/Fire.
- **Banks 10..13**: Dedicated Sprite Banks (Overworld, Dungeons, Bosses, NPCs & Objects), streamed directly into `$2800`–`$3FFF`.
- **Banks 14..17**: 4 regional Overworld chunks (`OW0` to `OW3`), streamed on-demand directly into `$C000`.
- **Banks 18..26**: 9 complete Underworld Dungeons (`DUNG1` to `DUNG9`), streamed on-demand directly into `$C000`.
- **Banks 27..30**: High-level game overlays loaded to `$A000`:
  - **Bank 27**: Inventory Subscreen & Full 16x8 Hyrule World Map (`ovl_inv.dat`).
  - **Bank 28**: Secret Caves, Shops & Merchant Dialogues (`ovl_cave.dat`).
  - **Bank 29**: Special Item Logics (`ovl_items.dat`).
  - **Bank 30**: Diagnostic & Debug Menu (`ovl_debug.dat`).
- **Bank 31**: Extended Audio Streaming Bank (`CART_BANK_AUDIO`, `cart_audio.bin`), streaming Death Mountain / Dungeon 9 extended 124-step authentic theme directly into `bgm_track_buffer`.
- **Banks 32..63**: Free expansion headroom (256 KB available).

### 2.2 Instant Memory Streaming (`src/main.asm` -> `cart_stream_copy`)

When moving between Overworld chunks, entering/exiting dungeons, or loading overlays:
1. **Zero Disk Latency**: The latch at `$DE00` commutates the corresponding 8 KB ROM bank into `$8000`–`$9FFF`.
2. **Interrupt-Safe Block Copy**: Interrupts are masked (`SEI`) page-by-page while `cart_stream_copy` transfers 256-byte blocks, releasing interrupts (`CLI; NOP; NOP`) between pages to preserve raster VBlank and SID audio synthesis.
3. **Charset & Palette Sync**: In dungeons, room-specific font overlays are streamed to `$2540` while reserving characters 120..125 for persistent passive relics.

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

## 5. Audio Subsystem (Single SID 6581/8580 & Dual SID Stereo Engine)

Music and sound effects are processed in `src/sound.asm`, `src/intro_music_data.asm`, `src/music_data_low.inc`, and `src/music_data.inc`, executed every frame during the vertical blank (50 Hz PAL / 60 Hz NTSC):

### 5.1 Voice Allocation & Waveforms
- **Voice 1**: Lead melody (Pulse wave with modulated duty cycle).
- **Voice 2**: Harmony / Counter-melody (Triangle and Sawtooth waves) & Secret chime fanfare.
- **Voice 3**: Bassline & Sound Effects (Triangle bass, Noise percussion, item drop chimes, sword beams, bombs).
- **ADSR Envelope Engine**: Dynamic attack, decay, sustain, and release control per instrument note with minimum 16-cycle Gate 0 -> 1 reset windows.

### 5.2 Dual SID Stereo Support ($D420 / $D500 / $DF00)
The engine automatically detects and supports a secondary SID chip:
- **Intro & Logo**: Stereo chorus with +2 frequency detune on Voice 1 & Voice 2, and dedicated Noise percussion on Voice 3.
- **In-Game Playfield**: Stereo spatialization for Overworld and Dungeon themes.
- **Symmetric SFX Dispatch**: Sound effects trigger symmetrically across SID1 and SID2 on Voice 3 under `sfx_timer` protection, preventing audio clipping.
- **Dual SID Register Integrity**: Non-destructive `ldy dual_sid_enabled` accumulator preservation and full restoration of PW and ADSR registers on both chips.

### 5.3 Dungeon 9 Extended Theme & Cartridge Streaming
- **Authentic NES Score**: Extracted from NES ROM `zelda.nes` (`SongScriptLastLevel0`), featuring 3 distinct voices (Square 1, Square 0, and Triangle bass) decoded with authentic NoteLengthTable 2 ($10).
- **Synchronized 124-Step Sequence**: Totaling 1344 NES audio ticks across all 3 channels, the track forms a clean 124-step loop (496 bytes) with single-pass 8-bit indexing and zero tempo slowdown.
- **Cartridge Bank 31 Streaming**: Stored in Cartridge Bank 31 (`CART_BANK_AUDIO`), streamed on demand (2 pages = 512 bytes) to `bgm_track_buffer` upon entering Death Mountain, and automatically swapped back to Overworld music upon exit.

### 5.4 Memory Layout & Overlay Collision Protection
- **Low Memory Zone (`$1BF8..$1ED4`)**: Pitch frequency tables (`freq_tbl_lo/hi`) and short fanfares reside under `$2000`, safe from dynamic overlays.
- **Resident RAM Ceiling (`$9F80`)**: All persistent game variables, enemy engines, and BGM tables end at `$9F80`, guaranteeing a 128-byte safety margin below `$A000` (`OVERLAY_RAM_ADDR`). Overlays streaming into `$A000..$BFFF` (inventory, caves, debug) cannot corrupt the audio engine.

---

## 6. Build Pipeline & Tools

| Tool | Purpose | Source Assets | Target Output |
| :--- | :--- | :--- | :--- |
| `tools/sprgen.py` | Converts ASCII art sprites into 64-byte C64 sprite binary data | `assets/link.txt`, `enemies.txt`, `extra.txt` | `src/sprites*.asm` |
| `tools/tilegen.py` | Assembles charsets, tilesets, and overworld/underworld rooms | `assets/tiles.txt`, `world.txt`, `underworld.txt` | `src/charset.asm`, `src/tiles_data.asm`, `src/map_*.asm` |
| `tools/cartgen.py` | Packages 64 banks of 8 KB into Magic Desk CRT image | `build/*.prg`, `build/*.dat`, `build/cart_audio.bin` | `build/zelda.crt` |
| `tools/render_maps.py` | Renders high-resolution PNG maps of Overworld & all 9 Dungeons | `assets/world.txt`, `underworld.txt` | `build/map_*.png` |
| `tools/export_assets_sheet.py` | Extracts all tiles, sprites & animated cycles into annotated contact sheets | `assets/tiles.txt`, `assets/*.txt` | `build/atlas_all_assets.png`, `build/sheet_*.png` |
| `tools/midi_to_sid.py` | Transcribes MIDI tracks into 6510 frequency and duration tables | `assets/*.mid` | `src/intro_music_data.asm` |
| `tools/extract_music.py` | Extracts authentic NES music scripts from `zelda.nes` | `zelda.nes` | `assets/music_data.json` |
| `tools/generate_game_audio.py` | Decodes audio tracks into assembly and cart binary | `assets/music_data.json` | `src/music_data*.inc`, `build/cart_audio.bin` |
| `ACME` | Cross-assembler for 6502/6510 producing CBM binaries | `src/*.asm` | `build/*.prg`, `build/*.dat` |
| `cartconv` | VICE utility packaging raw binary banks into Magic Desk CRT | `build/zelda_banks.bin` | `build/zelda.crt` |

---

## 7. Advanced Game Subsystems

### 7.1 Inventory Subscreen & Golden Triforce (`src/inventory_draw.asm`)
The inventory overlay (`Bank 27`, loaded to `$A000`) features 4 subscreen pages:
- **Page 0 (Equipment & B-Item Selector)**:
  - 4×2 grid of selectable secondary weapons (Boomerang, Bomb, Bow, Candle, Food, Potion, Whistle, Wand) with 16×16 sprites rendered in authentic 13–15 line proportions.
  - Selected item displayed via Sprite 0 centered at `(X=64, Y=120)`.
  - 6 persistent passive relics (Raft, Stepladder, Power Bracelet gauntlet, Magic Book, Ring, Magic Key) mapped to protected character codes 120..125, immune to dungeon font streaming overwrites.
- **Page 1 (Triforce of Wisdom Pyramidal Assembly)**:
  - 8-piece Triforce assembled as a seamless, equilateral solid triangle (4 tiers, 96×42 pixels) with diagonal beveled edges.
  - Hardware sprite alignment at `X=160` (left wing) and `X=184` (right wing) across Y-scanlines 106, 114, 122, 130.
  - Textual frame base `+----------+` aligned at Line 11 (raster Y=138).
- **Page 2 (Quest Status & Heart Containers)**:
  - Detailed hero statistics, sword tier, shield type, and tunic color.
- **Page 3 (Full Hyrule 16×8 Minimap)**:
  - Complete 128-room map with single-block active room indicator and non-interfering Link flashing dot.

### 7.2 Autonomous Stepladder Engine (`src/player.asm`, `src/items.asm`)
- **Zero Room Buffer Mutation**: Stepladder deployment does not alter `room_buf` (`TILE_BRIDGE_H/V`), preventing tile map corruption and avoiding bridge lockups.
- **Autonomous Sprite Rendering**: Displayed via Sprite 2 (`COL_BROWN`) at computed water tile coordinates `(ladder_spr_x, ladder_spr_y)`.
- **Stepping Logic**: Link steps onto the ladder across 1 tile of water (`ladder_stepped_on = 1`), and the ladder cleanly retracts (`ladder_tile_idx = $FF`) upon stepping onto solid land on the far shore.

### 7.3 Goriya Bestiary & Homing Boomerang AI (`src/enemies.asm`)
- **8-Directional Frames**: 4 cardinal orientations × 2 walk animation steps (`goriya_down_*`, `up_*`, `left_*`, `right_*`) with authentic canine snout, eyes, and held boomerang.
- **Dungeon Boundary Confinement**: `check_bounds_only` enforces strict Y-boundaries `88 <= Y < 208` in dungeon mode, preventing enemies from penetrating Row 0 (top stone wall Y=80..95) and eliminating wall lockups.
- **Corridor Alignment Detection**: `goriya_check_align_and_shoot` checks if Link crosses Goriya's horizontal or vertical line of sight (±10 px), causing Goriya to immediately face Link and throw the boomerang.
- **Homing Return Trajectory**: Boomerang travels 28 frames forward, then enters return phase (`en_proj_returning = 1`), homing in on Goriya (`en_proj_owner`) in 2-axis tracking until caught within 10 pixels. Shield blocking or player hit deflects the boomerang into return phase rather than instantly destroying it.

### 7.4 Visual Asset Atlas & Contact Sheet Engine (`tools/export_assets_sheet.py`)
- **Automated Multi-Sheet Extraction**: Standalone pure-Python renderer (using standard library `zlib` and `struct`) converting ASCII raw assets into high-resolution PNG contact sheets with pixel-perfect C64 aspect ratio (2:1 multicolor scaling).
- **Master Atlas (`build/atlas_all_assets.png`)**: Single consolidated 1920×3399 poster encompassing:
  - Section 1: Overworld tiles (16 tiles across 4 regional palettes: Plains, Mountain, Coast, Graveyard).
  - Section 2: Underworld dungeon tiles (16 authentic NES tiles: doors, diamond blocks, dragon statues, secret stairs).
  - Section 3: Link hero sprites (walk cycles 4 dir, sword thrusts, item get, secondary projectiles).
  - Section 4: Monster bestiary (89 enemy & boss frames: Octoroks, Moblins, Tektites, Leevers, Goriyas, Aquamentus, Dodongo, Ganon...).
  - Section 5: Inventory items, relics, NPCs, and assembled 8-piece Triforce pyramid showcase.
  - Section 6: Animated cycle strips with timing indicators (`2 Frames @ 8 FPS`, `3 Phases @ 24 Ticks`).
- **Dedicated Modular Sheets**: `build/sheet_tiles.png`, `build/sheet_sprites_link.png`, `build/sheet_sprites_enemies.png`, `build/sheet_sprites_items.png`, and `build/sheet_animations.png`.
- **Make Target**: Run `make atlas` or `make assets-sheet` to regenerate all contact sheets in seconds.
