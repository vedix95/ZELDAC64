; ===========================================================================
; overlay_debug.asm : Overlay Cartouche pour le Menu Debug & Cheats
; Banque 30 (CART_BANK_OVL_DEBUG), chargée à $A000 (RAM sous BASIC)
; Gère :
;   - Menu de test accessible via la touche 'D'
;   - Téléportation rapide vers n'importe quelle salle Overworld (128 salles)
;   - Téléportation rapide vers n'importe quel donjon (1 à 9)
;   - Cheats : vie max, équipement complet, rubis, clefs, bombes
;   - Hooks automatiques pour tests de non-régression
; ===========================================================================
!cpu 6510
!source "src/c64.inc"
!source "src/cart_defs.inc"
!source "build/resident_symbols.inc"
!source "build/sprite_ptrs.inc"

* = OVERLAY_RAM_ADDR ; $A000

; Table de vecteurs d'entrée de l'overlay ($A000..$A00B)
        jmp ovl_debug_open              ; $A000
        jmp ovl_debug_update            ; $A003
        jmp ovl_debug_exec_hook_cmd     ; $A006
        jmp ovl_debug_render_screen     ; $A009

!source "src/debug.asm"
