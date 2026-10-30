# Cartridge Banking System Documentation

## Magic Desk Type 19 Layout (512KB / 64 Banks × 8KB)

| Bank # | Name            | Range      | Content Description                      |
|--------|-----------------|------------|------------------------------------------|
| 0      | BOOT            | $8000-$9FF | Cartridge bootloader, CBM80 reset vector |
| 1-3    | INTRO           | $8000-$9FF| Cinematic intro (waterfall, scroller)    |
| 4-9    | CORE            | $8000-$9FF| Resident engine: player, AI, inventory   |
| 10     | OW_SPRITES      | $8000-$9FF| Overworld enemies                        |
| 11     | DUNG_SPRITES    | $8000-$9FF| Dungeon-specific enemies                 |
| 12     | BOSS_SPRITES    | $8000-$9FF| Boss sprites                             |
| 13     | NPC_SPRITES     | $8000-$9FF| NPCs: shopkeepers, fairies, Moblins      |
| 14-17  | OW_CHUNKS       | $8000-$9FF| Overworld chunks                         |
| 18-26  | DUNGEONS        | $8000-$9FF| Individual dungeon levels                |

### Banking Workflow
```
[Cartridge Boot] → $DE00 = Bank 0 (Unpacker)
      ↓
[Copy Banks 1-3 to RAM $0800-$67FF] (Intro decompress)
      ↓
[Game Start - SYS 2061] → Disable cartridge, use resident engine
      ↓
[Movement Detection] → current_room_y changes?
      Yes              No
      ↓                ↓
 Calculate bank     Stay in same chunk
```

### Important Notes
- Always verify $DE00 register before accessing ROM regions
- Bank 0 contains unpacker code that decompresses intro data
- After intro, disable cartridge to use resident engine from RAM
- Movement triggers bank switching when current_room_y changes