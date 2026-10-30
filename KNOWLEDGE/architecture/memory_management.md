# Memory Management Documentation

## Purpose
Understand RAM allocation patterns for:
- Zero page usage conventions
- Stack vs heap considerations
- Resident code memory layout
- Bank switching state tracking

---

## C64 RAM Allocation Overview

### Available Memory Ranges

| Range | Size | Name | Typical Use Case |
|-------|------|------|------------------|
| $00-$FF | 256 bytes | Zero Page | Scratch variables, frequently accessed data |
| $0100-$4E8B | ~20KB | RAM | Stack, heap, save area (if banked) |
| $0600-$07E7 | ~1.5KB | Video RAM | Visible screen content |
| $D800-$DBE7 | ~950 bytes | Color RAM | Character color pairs |
| $DE00 | 1 byte | Bank Control | Cartridge bank switching |

### Zero Page Allocation Conventions

#### Reserved Areas (Critical State)
```assembly
ZERO_PAGE_ALLOCATION:
    $00-$03   : Player position buffer (x, y coordinates)
    $04       : Current state flag (IDLE/CHASE/DIE/etc.)
    $05       : Collision resolution state
    $06-$09   : Sprite priority list (for sorting)
    $0A-$0D   : Temporary computation values
```

#### Stack Usage ($800-$9FF typically)
```assembly
STACK_ALLOCATION:
    .byte stack_ptr_hi,x       ; High byte of stack pointer
    .byte stack_ptr_lo,x       ; Low byte of stack pointer
    
; Function call convention uses push/pop from stack
```

---

## Resident Engine Memory Layout

### Core Resident Code Location

```
Resident Area ($0800 - $67FF = 24KB):
- Bootloader initialization code
- Collision detection routines
- Rendering update functions
- Audio effect handlers
- IRQ handler stub
```

### Memory Copy Strategy

During boot sequence:
1. Copy bank 4 into RAM at $0800
2. Copy bank 5 into RAM after that  
3. Continue until all resident banks copied

---

## Important Notes
- Zero page is precious - allocate carefully
- Consider using RAM area for save data if available
- Track heap vs static allocation patterns