# Cheat Codes & Debug Commands Documentation

## Purpose
Understand debugging commands and unlock sequences for:
- In-game cheat activation
- Debug mode triggers  
- Developer console access

---

## Input-Based Cheat Codes

### Reset Trigger (Boot Override)
```assembly
; Writing $FF to cartridge bank control resets game
    LDA #$FF                  ; Force reset flag
    STA $DE00                 ; Trigger CPU reset
    
; Game reloads from save or boots if no save
```

### Debug Mode Enable
```assembly
; Press specific key combination at title screen
; If enabled: enables debug menu access

Debug Menu Features:
    - Memory inspection mode
    - Bank switching toggle
    - Sprite position override
    - Interrupt enable/disable
```

---

## Runtime Debug Commands

### Key Codes (Press During Gameplay)

| Input | Effect | Use Case |
|-------|--------|----------|
| `$`   | Toggle debug console | Enable debug output |
| `D+L` | Dump memory state    | Log current RAM contents |
| `R+G` | Reset to last save   | Recover from soft lock |
| `F+A` | Force frame rate reset | Debug timing issues |

### Console Commands (if debug mode enabled)

```
Available in debug console:
  MEM dump [address]        ; Dump RAM region to hex view
  BANK switch [n]           ; Switch cartridge bank manually  
  SPRITE force [x,y]        ; Force sprite position
  AUDIO mute                ; Mute SID output
  LOG clear                 ; Clear debug log buffer
  SAVE quick                 ; Quick save without save game
```

---

## Important Notes
- Cheat codes may be disabled in production builds
- Debug mode should not exist in final release
- Consider disabling runtime cheats with build flag