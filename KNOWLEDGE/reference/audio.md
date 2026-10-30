# Audio System (SID) Documentation

## SID 6581 Chip Capabilities

**Voice Configuration:**
- 3 independent voice channels per processor
- Each channel supports: noise, wave, triangle waveforms
- Dual stereo output via panning control

### Music Implementation Strategy
- **Assembler**: ACME 6510 for SID instruction sequences
- **Sample Format**: SPC compression with custom decompressor for music tracks
- **Real-time Synthesis**: Used for short sound effects (SFX)

### Sound Effects Catalog

| Category      | Examples                            |
|---------------|-------------------------------------|
| Weapon        | Sword swing, bomb explosion, magic circle |
| Items         | Rupee chime, heart pickup, fairy whistle   |
| Enemy Death   | Bone clatter, slime squelch, dragon roar    |
| Environment    | Water ripple, wind howl, door creak      |

### SID Voice Registers

| Register | Address | Description                      |
|----------|---------|----------------------------------|
| Voice 0  | $D400   | Voice 0 frequency, waveform     |
| Voice 1  | $D402   | Voice 1 frequency, waveform     |
| Voice 2  | $D404   | Voice 2 frequency, waveform     |

### SID Initialization Sequence
```assembly
; Example initialization pattern
CLI                         ; Disable interrupts
LDA #$FF                    ; Clear voice control bits
STA $DC00                   ; Enable all voices
LDA #frequency              ; Set pitch
STA $D4XX                   ; Voice register (varies by voice)
SEI                         ; Re-enable interrupts
```

### Debugging Audio Issues
1. Verify SID initialization in boot code
2. Check voice registers ($D400-$D7FF) have valid frequencies
3. Confirm waveform selection (noise/wave/triangle)
4. Test with simple frequency sweep routine
5. Use oscilloscope to visualize SID output