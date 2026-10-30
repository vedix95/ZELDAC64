# Error Handling & Crash Recovery Documentation

## Purpose
Understand error detection and recovery for:
- Crash prevention techniques
- Memory corruption detection
- Invalid state handling
- Graceful degradation strategies

---

## Common Error Categories

### 1. Banking Errors
**Symptoms**: Crashes during intro or gameplay, wrong code executes  
**Causes**: 
- Incorrect $DE00 register value
- Attempting ROM access without bank switch
- Bank data not fully copied to RAM

**Recovery**: Reset via $FF trigger, re-initialize banking system

### 2. Memory Overflow
**Symptoms**: Random behavior, corrupted data after certain events  
**Causes**: 
- Writing beyond zero page allocation  
- Stack pointer out of bounds
- Heap fragmentation (if implemented)

**Detection**: Check zero page boundaries before each write
```assembly
CHECK_ZERO_PAGE_BOUNDS:
    LDA current_ptr,x          ; Current allocation pointer
    CMP zero_page_limit,x      ; Maximum safe limit
    BCC CONTINUE               ; Still in safe range
    JMP MEMORY_ERROR           ; Overflow detected
```

### 3. Sprite Priority Errors
**Symptoms**: Sprites appearing behind background  
**Causes**: 
- Y-coordinate sorting incorrect
- Sprite register not updated properly

**Recovery**: Reorder sprites by Y, reconfigure registers

### 4. IRQ Handler Issues
**Symptoms**: Flickering graphics, timing glitches  
**Causes**: 
- IRQ handler too long (exceeds single frame)
- Handler modifies global state inconsistently

**Detection**: Use timer checks to verify handler execution time

---

## Crash Detection Techniques

### Memory Integrity Checks

```assembly
VERIFY_MEMORY_REGION:
    ; Check for null/invalid pointers in key structures
    LDA ptr_struct,x           ; Load pointer from structure
    CMP NULL_POINTER,x         ; Compare with null marker
    BEQ valid_pointer          ; Valid, continue
    
valid_pointer:
    ; Process as normal
    
MEMORY_ERROR_LABEL:
    ; Handle crash (log to serial or halt)
```

### State Validation

```assembly
VERIFY_STATE_VALIDITY:
    ; Check critical state flags before transitions
    
    LDA current_state,x        ; Get current state
    CMP INVALID_STATE,x        ; Invalid state marker
    BEQ RECOVER_STATE          ; Recover from invalid state
    
    ; Continue normal processing
```

---

## Error Recovery Procedures

### Banking Error Recovery
```assembly
RECOVER_BANKING_ERROR:
    1. Disable cartridge (LDA #$36; STA $DE00)
    2. Halt CPU execution (HLT or reset flag)
    3. Clear error flags in resident memory
    4. Re-initialize banking system
    5. Re-enable cartridge (SYS 2061)
```

### Memory Corruption Recovery
```assembly
RECOVER_MEMORY_CORRUPTION:
    1. Detect corruption via checksum or boundary check
    2. Restore from last known good state
    3. Clear corrupted data region
    4. Reset affected subsystems
```

---

## Debug Error Logging

### Serial Error Output (if available)
```assembly
LOG_ERROR_TO_SERIAL:
    ; Only for debugging builds
    
    LDA error_message,x        ; Load error code
    STA $DF02                 ; Write to serial port
    
    JMP ERROR_HANDLED         ; Continue or reset
```

---

## Important Notes
- Always validate banking state before accessing cartridge ROM
- Check zero page bounds for all pointer arithmetic  
- Implement minimum error handling even in debug builds
- Consider whether errors should crash gracefully or halt entirely