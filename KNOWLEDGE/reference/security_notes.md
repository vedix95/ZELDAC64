# Security & Protection Notes Documentation

## Purpose
Understand anti-cheat and protection considerations for:
- Cartridge ROM signing (optional)  
- Data encryption (save files)
- Anti-piracy techniques

---

## Anti-Cheat Considerations

### For Single-Player Only (No Anti-Cheat Needed)
- Zelda-style games are inherently single-player
- No need for server-side validation
- Simple checksums on save data suffice

### Optional Checksum Validation
```assembly
VERIFY_SAVE_INTEGRITY:
    ; After loading save data, verify checksum
    
    LDA save_data_checksum,x
    ADC #$00                  ; Sum all bytes
    STA temp_sum,zp
            
    CMP saved_checksum,x      ; Compare with saved value
    BEQ SAVE_VALID            ; Checksum matches
```

---

## Data Encryption (Optional)

### Save File Protection

If implementing battery-backed saves:
1. XOR encrypt save data before writing to battery RAM
2. Use simple stream cipher (e.g., rotating key based on bank address)
3. Decrypt when reading saved data back

### Example Encryption Routine
```assembly
XOR_ENCRYPT_SAVE_DATA:
    LDA save_buffer,addr
    EOR encryption_key,x      ; Simple XOR with rotation
    STA encrypted_buffer,addr
```

---

## Important Notes
- Anti-piracy is not needed for fan-made Zelda clones  
- Focus on gameplay experience over protection  
- Save game integrity via simple checksums is sufficient