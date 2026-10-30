# File Organization Documentation

## Complete Project Directory Tree

```
zelda/
├── specs.md                      # Main specification document
├── Makefile                      # Build automation targets
├── src/                          # Assembly source files
│   ├── boot.s                    # Cartridge bootloader
│   ├── intro.s                   # Cinematic intro sequence
│   └── core.s                    # Resident engine code
├── assets/                       # Character/sprite source data
│   ├── tiles.txt                 # VIC-II charset definitions
│   └── enemies.txt               # ASCII art sprite sources
├── sprites/                      # Binary sprite assets (hex-encoded)
│   ├── ow.bin                    # Overworld enemies (8KB, Bank 10)
│   ├── dung.bin                  # Dungeon enemies (8KB, Bank 11)
│   ├── boss.bin                  # Boss sprites (8KB, Bank 12)
│   └── npc.bin                   # NPC sprites (8KB, Bank 13)
├── scripts/                      # Build tooling
│   └── generate_sprites.py       # Python sprite generator
└── output/                       # Compiled binary outputs
    ├── boot.bin                  # Built bootloader image
    └── core.bin                  # Resident engine disk image
```

### Makefile Targets Reference

```makefile
all: boot.bin intro.bin core.bin

boot.bin: boot.s |              # Cartridge bootloader
intro.bin: intro.s |             # Cinematic intro sequence
core.bin: core.s sprites/*.bin | # Resident engine with sprite overlay

clean:                          # Remove all .bin and .o files
```

### Build Toolchain Requirements
- **ACME Cross-Assembler**: For 6510 assembly source compilation
- **LD C2 Linker**: For Magic Desk Type 19 256KB cartridge linking
- **Python Scripts**: For sprite generation from ASCII sources
- **Hex Editor**: For binary file editing and verification

### File Naming Conventions
- Source files use `.s` extension (assembly)
- Binary outputs use `.bin` extension  
- Asset text files use `.txt` extension
- Python scripts use `.py` extension
- Always use lowercase for directory names