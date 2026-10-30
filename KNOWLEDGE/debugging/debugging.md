# Debugging Guide Documentation

## Common Issues and Diagnostic Steps

### Issue 1: Sprite Not Rendering

**Symptoms**: Link or enemy not visible on screen

**Debug Checklist**:
1. Verify sprite registers ($07F8-$07FF) have valid Y positions
2. Check Video RAM ($0400-$07E7) has non-zero character codes
3. Confirm Color RAM ($D800-$DBE7) has multicolor enabled
4. Ensure sprite priority flags are set (lower Y = higher priority)

### Issue 2: Banking Not Working

**Symptoms**: Game crashes after intro, wrong code executes

**Debug Checklist**:
1. Verify $DE00 register has correct bank value ($37=$36)
2. Check boot.s correctly initializes bank switching
3. Confirm sprite banks are loaded to RAM before gameplay starts

### Issue 3: Sound Not Playing

**Symptoms**: No audio during gameplay, only background noise

**Debug Checklist**:
1. Verify SID initialization in boot code
2. Check voice registers ($D400-$D7FF) have valid frequencies
3. Confirm waveform selection (noise/wave/triangle)

### Issue 4: Memory Corruption

**Symptoms**: Random crashes, data loss, unexpected behavior

**Debug Checklist**:
1. Check Zero Page ($00-$FF) for accidental overwrites
2. Verify stack pointer ($01FF) is within bounds
3. Monitor heap allocation for sprite data structures

## Debug Tools and Techniques

### Memory Dump Commands
```bash
# Dump RAM region (hex)
dd if=zelda/core.bin bs=256 count=10 | xxd

# Check specific memory range
hexdump -C zelda/output/boot.bin
```

### Assembly Debugging Tips
- Use breakpoint instructions at known failure points
- Monitor Zero Page variables for corruption
- Check return addresses on stack after function calls
- Verify bank switching state before ROM access

### Raster IRQ Usage
Raster IRQ can be used to:
- Reconfigure VIC-II registers mid-frame
- Maintain precise sprite positioning
- Update HUD without flicker
- Execute sound effect triggers at specific times

### Logging Strategy
Implement runtime logging by:
- Writing bank changes to designated RAM area
- Recording sprite Y positions during frame updates
- Checking Color RAM state after each render cycle