# Quick Reference Commands Documentation

## Assembly Tools
```bash
# Compile single file
acme src/boot.s

# Link with LD C2
ldc2 boot.o core.o -o boot.bin

# Clean build artifacts
make clean
```

### Python Sprite Generator
```bash
python3 scripts/generate_sprites.py --input assets/enemies.txt --output sprites/ow.bin
```

### Memory Inspection
```bash
# Dump RAM region (hex)
dd if=zelda/core.bin bs=256 count=10 | xxd
```

## Important Notes for AI Agents

When analyzing or modifying this project:

1. **Always verify banking state** before accessing cartridge ROM regions
2. **Use ACME assembler syntax**, not standard 6502 directives
3. **Respect VIC-II limitations**: max 8 sprites, multicolor mode only
4. **Hex-encode all binary data** in documentation (never Base64 images)
5. **Check Zero Page usage** for critical game state variables
6. **Bank switching must occur before gameplay starts**
7. **SID audio requires initialization sequence** (voices on/off control)
8. **Sprite priority**: Lower Y coordinate = higher render priority
9. **Tilemap alignment**: Each tile is 16x16, uses 2x2 character blocks
10. **Legal compliance**: All assets are fan-made recreations

## Summary Checklist for New Developers

- [ ] Understand Magic Desk Type 19 banking ($DE00 register)
- [ ] Read VIC-II programming documentation
- [ ] Review ASCII→Python sprite generation workflow
- [ ] Study Zero Page allocation conventions in assembly
- [ ] Verify ACME assembler cross-references before linking
- [ ] Test sound effects with minimal SID code first
- [ ] Implement proper IRQ handlers for raster line positioning

## File Reference Summary

| File | Purpose | Key Contents |
|------|---------|--------------|
| specs.md | Main specification | Complete project documentation (9 sections) |
| memory.md | Memory architecture | C64 memory map, banking control |
| banking.md | Banking system | Magic Desk Type 19 layout, workflows |
| sprites.md | Sprite assets | Binary file structure, VIC-II details |
| files.md | File organization | Directory tree, Makefile targets |
| rendering.md | Rendering pipeline | VIC-II graphics, sprite registers |
| audio.md | Audio system | SID chip capabilities, sound effects |
| debugging.md | Debugging guide | Issue checklist, diagnostic steps |
| quick_reference.md | Quick commands | Build commands, reference notes |

---

**END OF QUICK REFERENCE DOCUMENTATION**