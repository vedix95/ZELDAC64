# Testing Guide Documentation

## Purpose
Understand testing strategies and QA procedures for:
- Unit testing assembly routines
- Integration testing subsystems  
- Regression test cases
- Debug build configurations

---

## Test Case Categories

### Category 1: Banking Tests

```assembly
TEST_BANKING_SCENARIOS:
    1. Switch between all banks (0-9)
    2. Verify each bank contains expected code
    3. Check bank switching doesn't corrupt RAM
    
Test Procedure:
    Loop bank_counter from 0 to 9:
        Perform bank switch
        Execute known-good routine
        Compare results to expected values
```

### Category 2: Rendering Tests

```assembly
TEST_RENDERING_SCENARIOS:
    1. Render single sprite at various positions
    2. Render all 8 sprites simultaneously
    3. Test sprite priority sorting
    4. Verify color RAM display
    
Test Output Check:
    Capture screen contents at VSYNC
    Compare against known-good pattern
    Flag any visible anomalies
```

### Category 3: Audio Tests

```assembly
TEST_AUDIO_SCENARIOS:
    1. Play each waveform type (wave, triangle, noise)
    2. Test voice panning combinations
    3. Verify sample playback timing
    4. Check SFX trigger events
    
Test Output:
    Listen to audio output
    Check for clipping/distortion
```

### Category 4: Collision Tests

```assembly
TEST_COLLISION_SCENARIOS:
    1. Link walks into walls (stop movement)
    2. Enemy collides with walls
    3. Projectile hits enemy/player
    4. Multiple entities at same position
    
Expected Behavior:
    - Walls block movement
    - Entities don't pass through each other
```

### Category 5: Memory Tests

```assembly
TEST_MEMORY_BOUNDS:
    1. Write/read all zero page bytes
    2. Verify stack pointer operations
    3. Check video RAM integrity
    4. Monitor for memory corruption
    
Stress Test:
    Rapidly allocate/deallocate buffers
    Monitor for crashes or data loss
```

---

## Regression Testing

### Critical Paths to Test After Each Change

| Component | Tests to Run |
|-----------|-------------|
| Boot sequence | All boot steps complete successfully |
| Banking system | All bank switches work correctly |
| Rendering pipeline | Sprites render correctly at all positions |
| Audio system | SFX play without errors or crashes |
| Level streaming | Rooms load and unload properly |

### Test Regression Checklist

```bash
# Automated test suite (if available)
test_boot_sequence
test_banking_operations
test_sprite_rendering  
test_audio_playback
test_collision_detection
test_level_loading
```

---

## Debug Build Configuration

### Compile-Time Debug Flags

```assembly
DEBUG_BUILD_DEFINES:
    .define DEBUG_LOG       ; Enable logging to serial/debug output
    .define ASSERT_ENABLED  ; Add assert statements throughout code
    .define VERIFY_BANKING  ; Add bank state verification
```

### Runtime Debug Features

#### Memory Dump Routine
```assembly
MEMORY_DUMP_DEBUG:
    LDA $0800,x              ; Start of resident area
    STA debug_ram_buffer,x   ; Copy to debug buffer
```

#### State Snapshot Routine
```assembly
SNAPSHOT_STATE_DEBUG:
    ; Dump all critical state variables
    ; Useful for crash analysis
```

---

## Testing Tools & Methods

### Using ACME Assembler Debug Features

1. **Breakpoint instructions** at known failure points
2. **Watch registers** during execution
3. **Single-step through code** when debugging specific issues

### External Tools (if available)

- Hex editor for binary inspection
- Memory viewer for RAM state
- Waveform visualizer for audio testing