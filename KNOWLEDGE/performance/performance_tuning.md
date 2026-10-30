# Performance Tuning Documentation

## Purpose
Understand optimization techniques and performance considerations for:
- Efficient rendering cycles
- Memory access patterns  
- Timing-critical code sections
- IRQ handler optimization

---

## Timing Analysis

### Available Time Budget (Per Frame)

```assembly
FRAME_TIME_BUDGET:
    Total available: ~16.7ms @ 60Hz
    
Breakdown:
    - VSYNC to next VSYNC: 16.7ms
    - IRQ handler: ~1ms allowed
    - Rendering updates: ~5ms recommended
    - Sprite positioning: ~2ms
    
Time Remaining after critical sections: ~0-3ms
```

### Critical Path Optimization

#### Zero Page Allocation (Fastest Access)
```assembly
OPTIMIZE_ACCESS_PATTERNS:
    ; Put frequently-used variables in zero page
    ; Example player position access:
    
    LDA player_x,zp            ; Fast zero page access
    CMP enemy_x,zp             ; Direct comparison
    BEQ collision_detected
    
    ; Avoid stack access for hot paths
```

#### Bank Switching Minimization
```assembly
MINIMIZE_BANK_SWITCHES:
    ; Check if bank switch needed before switching
    LDA current_bank,x         ; Current cartridge bank
    CMP target_bank,x          ; Desired bank
    BEQ use_current_bank       ; Already on right bank
    
bank_switch_needed:
    LDA new_bank_number        ; Target bank
    STA $DE00                  ; Switch banks (SYS 2061)
    
use_current_bank:
    JMP continue_processing
```

---

## Rendering Optimization

### Video RAM Update Strategy

```assembly
OPTIMIZE_VIDEO_RAM_WRITES:
    ; Batch writes instead of individual byte writes
    
    ; Write entire pattern in single operation
    LDA pattern_byte,x         ; Load from data structure
    STA video_ram,loop_addr    ; Store to screen
    
    ; Use DMA or memory copy routines if available
```

### Sprite Position Update Optimization

```assembly
OPTIMIZE_SPRITE_POSITIONS:
    ; Only update sprite Y when position changes
    
    ; Cache previous positions for delta checking
    LDA player_prev_y,zp       ; Previous frame position
    CMP player_curr_y,x        ; Current frame position
    BNE UPDATE_SPRITE          ; Position changed, update it
    
SKIP_SPRITE_UPDATE:
    JMP continue_frame
UPDATE_SPRITE:
    ; Update sprite registers here
```

---

## Memory Access Optimization

### Common Patterns to Avoid

```assembly
AVOID_SLOW_PATTERNS:
    1. Multiple bank switches per frame
    2. Reading from cartridge without checking state
    3. Writing video RAM during non-VSYNC
    4. Recursive function calls in tight loops
```

### Fast Access Patterns

```assembly
PREFER_FAST_ACCESS:
    1. Zero page variables for hot data
    2. Stack for function-local values
    3. Static allocation for constants
    4. Pre-computed lookups (tables)
```

---

## IRQ Handler Optimization

### Timing Constraints

```assembly
IRQ_HANDLER_TIME_LIMIT:
    Must complete within ~1ms
    
    Allowed operations:
    - Read/write RAM
    - Update video RAM at VSYNC
    - Reconfigure VIC-II registers
    
    Forbidden during IRQ:
    - Bank switching (SYS 2061)
    - Memory copying across banks
```

### Minimal IRQ Handler Example

```assembly
MINIMAL_IRQ_HANDLER:
    ; Quick timing check
    LDA frame_counter,zp       ; Current frame number
    BEQ next_irq               ; Not our turn, skip
    
    ; Our update time (rendering)
    JSR update_video_frame,x   ; Critical rendering work
    
next_irq:
    RTI                        ; Return from interrupt
```

---

## Important Notes
- Profile code before and after optimization
- Use timers to measure actual execution times
- Consider profiling during VSYNC timing
- Some optimizations may affect compatibility - test thoroughly