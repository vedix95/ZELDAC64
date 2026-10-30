# Version Control & Build Management Documentation

## Purpose
Understand version control and build automation for:
- Git integration with assembly projects
- Makefile target definitions  
- Release packaging notes
- Asset tracking workflow

---

## Project Directory Structure

```
/home/vedix/Documents/C64/zelda/
├── KINOWLEDGE/              # This documentation directory
│   ├── INDEX.md
│   ├── specs.md            # Main project spec (~800 lines)
│   ├── memory.md
│   ├── banking.md
│   ├── sprites.md
│   ├── rendering.md
│   └── ... (19 total files)
├── src/                     # Assembly source files
│   ├── boot.s              # Cartridge bootloader
│   ├── intro.s             # Title screen sequence
│   └── core.s              # Resident engine code
├── assets/                  # Text sprite sources
│   └── enemies.txt         # ASCII art sprite definitions
├── output/                  # Compiled binary outputs
│   ├── boot.bin            # Bootloader image
│   └── core.bin            # Core engine ROM image  
├── scripts/                 # Build automation
│   └── generate_sprites.py
└── Makefile                 # Build targets
```

---

## Makefile Targets

### Primary Targets

```makefile
all: boot.bin intro.bin core.bin

boot.bin: src/boot.s        # Compile bootloader
    acme src/boot.s         # Assemble with ACME
    ld output/boot.o        # Link bootloader image
    
intro.bin: src/intro.s      # Compile intro sequence  
    acme src/intro.s
    ld output/intro.o
    
core.bin: src/core.s assets/*.txt   # Compile core engine
    acme src/core.s
    python3 scripts/generate_sprites.py \
        --input assets/enemies.txt \
        --output sprites/ow.bin
```

### Clean Target

```makefile
clean:
    rm -f *.o *.bin output/*
```

---

## Git Integration Notes

### Assembly Project Best Practices

```bash
# Recommended .gitignore for C64 projects
output/*.bin                      # Binary outputs (generated)
*.pyc                              # Python cache files  
__pycache__/                       # Python bytecode
build/                             # Temporary build artifacts
```

### Version Tagging Convention

```bash
v1.0.0-alpha            # Early development
v1.0.0-beta             # Feature complete, bug fixes
v1.0.0                  # Production release
v2.0.0                  # Major version update
```

---

## Important Notes
- Version control may not be needed for simple projects  
- Consider using git LFS for large binary assets
- Always commit source files with their corresponding documentation