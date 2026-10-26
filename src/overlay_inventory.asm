; ===========================================================================
; overlay_inventory.asm : Overlay Cartouche pour l'Inventaire Multi-pages
; Banque 27 (CART_BANK_OVL_INV), chargée à $A000 (RAM sous BASIC)
; Gère :
;   - Page 0 : Équipements & Inventaire Slot B (Sélecteur animé)
;   - Page 1 : Carte du Royaume & Morceaux de Triforce
;   - Page 2 : Statistiques de quête & progression
;   - Page 3 : Aide manette Xbox / Clavier C64
; ===========================================================================
!cpu 6510
!source "src/c64.inc"
!source "src/cart_defs.inc"
!source "build/resident_symbols.inc"
!source "build/sprite_ptrs.inc"

* = OVERLAY_RAM_ADDR ; $A000

; Table de vecteurs d'entrée de l'overlay ($A000..$A014)
        jmp ovl_inventory_open          ; $A000
        jmp ovl_inventory_update        ; $A003
        jmp ovl_inventory_close         ; $A006
        jmp inv_p0_irq_row1             ; $A009
        jmp irq_p0_row2                 ; $A00C
        jmp inv_update_cursor           ; $A00F
        jmp ovl_inv_display_current_page ; $A012

!source "src/inventory.asm"
!source "src/inventory_draw.asm"
