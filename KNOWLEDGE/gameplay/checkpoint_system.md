# Checkpoint System Documentation

## Purpose
Understand checkpoint/save point mechanics for:
- Dungeon completion tracking
- Quick resume functionality  
- Save state validation

---

## Checkpoint Data Structure

```assembly
CHECKPOINT_RECORD:
    .byte dungeon_id,x         ; Which dungeon checkpoint
    .byte room_index,x         ; Room within dungeon (0-based)
    .byte trigger_flag,x       ; 1 = reached, 0 = not yet
    .byte last_save_tick,x     ; When checkpoint was marked
```

## Checkpoint Usage Flow

### Reaching a Checkpoint
```assembly
REACH_CHECKPOINT:
    ; When Link enters checkpoint area
    
    ; Update checkpoint data
    LDA dungeon_current_id,x
    STA checkpoint_table,addr,x
    
    JMP save_checkpoint_flag
```

### Resume from Checkpoint
```assembly
RESUME_FROM_CHECKPOINT:
    ; Load saved state and restore game flags
    LDA last_room_saved,x      ; Current room to resume in
    STA current_room_x,x       ; Restore position
    
    ; Skip to next dungeon section
    JMP dungeon_entrance_logic
```

---

## Important Notes
- Checkpoints use simple flag system (no complex rollback)
- Consider battery-backed saves for permanent persistence