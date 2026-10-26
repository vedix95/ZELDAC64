; ===========================================================================
; overlay_cave.asm : Overlay Cartouche pour les Cavernes et Échoppes
; Banque 28 (CART_BANK_OVL_CAVE), chargée à $A000 (RAM sous BASIC)
; Gère :
;   - Grottes secrètes (Vieil Homme "C'est dangereux d'y aller tout seul")
;   - Boutiques d'objets (Bouclier magique, Bougie, Anneau bleu, Cœurs)
;   - Échoppes de jeu de hasard & Moblins secrets ("It's a secret to everybody")
;   - Caves de donjons (Cellar pour trésor secondaire)
; ===========================================================================
!cpu 6510
!source "src/c64.inc"
!source "src/cart_defs.inc"
!source "build/resident_symbols.inc"
!source "build/sprite_ptrs.inc"

* = OVERLAY_RAM_ADDR ; $A000

; Table de vecteurs d'entrée de l'overlay ($A000..$A011)
        jmp ovl_cave_enter              ; $A000
        jmp ovl_cave_update             ; $A003
        jmp ovl_cave_draw               ; $A006
        jmp cellar_update               ; $A009
        jmp cellar_draw                 ; $A00C
        jmp ovl_cave_draw_screen        ; $A00F

!source "src/cave.asm"
