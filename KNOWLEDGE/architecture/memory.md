# Memory Architecture Documentation

## C64 Native Memory Map

| Address Range | Size   | Purpose                  | Usage Notes                    |
|---------------|--------|--------------------------|--------------------------------|
| $0000-$00FF   | 256 B  | Zero Page                | Fast variables, pointers       |
| $0100-$03FF   | 768 B  | System Area              | OS routines, IRQ handlers      |
| $0400-$07E7   | 8,200B | Video RAM                | Screen display (40x25 chars)   |
| $0800-$0DFF   | 2,048B | Sprite Data              | Player/enemy sprite tiles      |
| $1000-$1FFF   | 4,096B | User Stack               | Program stack, interrupts      |
| $2000-$27FF   | 2,048B | Charset RAM              | Custom font definitions        |
| $C000-$DFFF   | 16KB   | Cartridge Overwrite Area | Resident engine code           |
| $DE00         | 1 Byte | Bank Control Register    | $37=enabled, $36=disabled      |

### Banking Control Assembly
```assembly
; Enable cartridge -> map to $8000..$9FFF
CART_ENABLE  = #$37    ; Bank active, reads from cartridge

; Disable cartridge -> normal RAM mode
CART_DISABLE = #$36    ; Use resident engine code in RAM
```

### Resident Engine Area (SYS 2061)
When cartridge is enabled ($DE00=$37), the game code resides in:
- **Address**: $8000-$9FFF (256KB logical mapping)
- **Bank Switching**: Magic Desk Type 19 controls which 8KB banks map here