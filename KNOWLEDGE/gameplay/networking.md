# Network I/O System Documentation

## C64 Serial Communication (CBM-II / CBM-2001)

### Purpose
Understand the C64 cartridge save system and external communication for:
- Save game functionality (if using serial port)
- Debug communication with external devices
- Data logging to cassette tape

### Serial Port Registers

| Address | Function | Description                     |
|---------|----------|---------------------------------|
| $DF00   | Status   | 0=not ready, 1=ready           |
| $DF02   | Command  | Input command/data             |
| $DF04   | Data     | Read/write data buffer         |

### Save Game Implementation (if applicable)

#### Save Sequence
```assembly
; Initialize serial port
LDA #$FE
STA $DC05                   ; Set baud rate

; Prepare save buffer
LDA #$XX                    ; Bank number
STA save_buffer,addr        ; Store bank ID
```

#### Load Sequence  
```assembly
; Request load operation
LDA #$FF
STA $DF02                   ; Send LOAD command

; Wait for data
LOOP: LDA $DF04
      CMP #$FF
      BNE LOOP
```

### Cassette Loading (Legacy)
- Used for saving game to tape in original C64 era
- Control signals via $DD00-$DFFF range
- Note: Modern cartridges use battery-backed RAM or Magic Desk

### External Debugger Interface
Some development tools use serial port for:
- Live memory inspection
- Remote command execution
- Debug output streaming

---

## Important Notes
- Serial communication requires external hardware (CBM-II modem)
- Not used in final production build
- Included for understanding legacy C64 peripherals