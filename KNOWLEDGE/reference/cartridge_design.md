# Cartridge Design Documentation

## Purpose
Understand cartridge form factor and hardware design for:
- Magic Desk Type 19 specifications  
- ROM layout requirements
- Circuit board design considerations
- Production manufacturing notes

---

## Magic Desk Type 19 Specifications

### Hardware Overview

```
Cartridge Type: Magic Desk Type 19
Total Size: 8KB + resident area (~24KB)
Chipset: Standard 6502 ROM chips

Memory Map:
    | Address Range | Size  | Contents            | Bank # |
    |---------------|-------|---------------------|--------|
    | $2800-$2FFF   | ~8KB  | Intro + Resident    | 1-3    |
    | $3000-$3FFF   | ~8KB  | Game code part 1    | 4      |
    | $4000-$4FFF   | ~8KB  | Game code part 2    | 5      |
    | ...           | ...   | ...                 | ...    |
```

### Banking Register Layout

```assembly
BANKING_CONTROL_REGISTER:
    Address: $DE00 (cartridge bank control)
    
Value Mapping:
    $36 = Disable cartridge (use resident RAM code at $0800+)
    $37 = Enable cartridge (bank switch with SYS 2061)
    
Usage Flow:
    1. Power-on: Value = $37 (cartridge active)
    2. Bootloader executes (Bank 0, address $2800)
    3. Banking system initialized
```

### ROM-to-RAM Layout

Cartridge ROM is organized as:
- **Bank 0**: Bootloader (~$2800-$37FF)  
- **Bank 1-9**: Game content
- **Bank 0xFF+** (if used): Debug data area

---

## Circuit Design Considerations

### Power Requirements
- Standard C64 power supply (+5V, +12V)
- Battery backup for save functionality (CR2032)
- Optional: External serial port connection (CBM-II modem)

### Connector Pinout (Standard Cartridge Header)
```
Pin 1: Ground
Pin 2: +5V Power  
Pin 3: Address/Data bus lines
...
```

---

## Production Notes

### Manufacturing Checklist
- [ ] Verify ROM chip compatibility
- [ ] Test bank switching functionality  
- [ ] Validate battery-backed save (if implemented)
- [ ] Check serial port communication (for debug builds)
- [ ] Burn firmware to cartridge ROMs

### Shipping Configuration
- Cartridge should work immediately on power-on
- Save data persists through power cycles
- All graphics/audio must test before shipping

---

## Important Notes
- Cartridge design is optional - can run from tape/disk
- Banking system works with standard 6502 cartridges  
- Ensure all ROM chips are compatible with target C64