# ASCII Art Sprite Source Documentation

## Purpose
Understand ASCII art sprite creation and conversion process for:
- Enemy sprite design workflow
- Character pattern definition
- Conversion to VIC-II display format
- Storage as hex-encoded binary data

---

## Sprite Data Format

### ASCII Art Definition System

```
Format Specification:
- Each character represents 4 pixels (2×2 block)
- Space = transparent background
- Special characters for patterns:
  # = dark sprite pixel
  o = bright sprite pixel  
  . = mid-gray pixel
  ' = outline pixel
```

### Example Enemy Sprite Definition

```
Stalfos (Skeleton Warrior):

    SS      SS    ; Head outline
   SS     SS     
  S S    S S      
  #  SS  #        ; Body pattern
  #  SS  #       
 # SS    #        
# SS    #         
SS       SS      ; Legs
    
Display Size:
- ASCII source: ~8x4 characters  
- VIC-II output: 32×16 pixels (40×20 screen cells)
- Scaling factor: Each character maps to 4×4 pixel block
```

### Conversion Pipeline

```
ASCII Source → Python Script → Binary Output (.bin file)

Step 1: Parse ASCII characters
Step 2: Map each character to 4×4 pixel grid
Step 3: Convert to VIC-II charset codes (0-127)
Step 4: Generate hex-encoded binary data
Step 5: Store in sprites/ directory
```

---

## Sprite Design Guidelines

### Tile Layout Rules

```assembly
TILE_WIDTH: 8 pixels (2 screen cells wide)
TILE_HEIGHT: 8 pixels (2 screen cells high)
TILE_SIZE_BYTES: 2 bytes per tile in Color RAM

Sprite Storage Organization:
- Each file: 8,192 bytes = 4,096 tiles × 2 bytes
- Tile data stored sequentially
- Unused tiles should use background character ($41)
```

### Character Palette Mapping

| ASCII Char | VIC-II Code | Appearance              | Use Case          |
|------------|-------------|-------------------------|--------------------|
| ` ` (space)| `$40`       | Empty/transparent       | Background areas   |
| `#`        | `$38`-`$3F` | Dark sprite pixel       | Body/muscles       |
| `o`        | `$01`-`$0A` | Bright sprite pixel     | Highlights/details  |
| `'`        | `$0B`-`$27` | Outline pixels          | Edges/shadows      |

---

## Sprite Categories

### Overworld Enemies (`ow.bin`)
- Stalfos: Slow, melee attack skeleton warrior
- Armos: Statue enemies that activate when approached  
- Slimes: Bouncy, low health blobs
- Chorus Fruit: Flying insectoid enemies

### Dungeon Enemies (`dung.bin`)
- Specific boss patterns
- Special enemies unique to each dungeon
- Item-dropping variants

---

## Conversion Script Usage

```bash
# Generate sprite from ASCII source file
python3 scripts/generate_sprites.py \
    --input assets/enemies.txt \
    --output sprites/ow.bin
    
# Generate dungeon-specific sprites  
python3 scripts/generate_sprites.py \
    --input assets/dungeon_enemies.txt \
    --output sprites/dung.bin
```

---

## Important Notes
- ASCII art is designed for simple shapes, not detailed characters
- Consider using more detailed sprite files if available
- Always validate generated binary against expected output
- Store hex-encoded versions in knowledge base for reference