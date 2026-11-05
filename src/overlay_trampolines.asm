; ===========================================================================
; overlay_trampolines.asm : Routines résidentes et trampolines d'overlays cartouche
; Permet à zelda.prg de charger et d'exécuter à la volée les modules secondaires
; (Inventaire, Cavernes, Menu Debug) dans la zone RAM $A000..$BFFF.
; ===========================================================================

!zone overlays_trampolines

!source "src/cave_defs.inc"

; ---------------------------------------------------------------------------
; Variables résidentes persistantes partagées
; ---------------------------------------------------------------------------
game_state:             !byte STATE_PLAYING ; État global du jeu
inv_page:               !byte 0         ; Page active de l'inventaire (0..3)
debug_hook_cmd:         !byte 0         ; Commande de hook de débug
debug_hook_arg:         !byte 0         ; Argument 1 du hook
debug_hook_arg2:        !byte 0         ; Argument 2 du hook
current_cave_type:      !byte 0         ; Type de la caverne en cours de visite

; Persistance des 128 salles de cavernes (allouée en basse RAM résidente sous $2000 dans main.asm)

; Table de mapping des 128 salles Overworld vers leur type de caverne (1ère Quête NES)
room_cave_types:
        ; Rangée 0 (0..15 : A-1 .. P-1)
        !byte 0, CAVE_TYPE_DOOR_REPAIR, CAVE_TYPE_POTION_SHOP, CAVE_TYPE_DOOR_REPAIR, CAVE_TYPE_POTION_SHOP, 0, CAVE_TYPE_WARP, CAVE_TYPE_DOOR_REPAIR
        !byte 0, CAVE_TYPE_HINT_1, CAVE_TYPE_SWORD_WHITE, 0, CAVE_TYPE_SHOP_A, CAVE_TYPE_POTION_SHOP, CAVE_TYPE_HEART_GIFT, CAVE_TYPE_MOBLIN
        ; Rangée 1 (16..31 : A-2 .. P-2)
        !byte CAVE_TYPE_GAMBLE, CAVE_TYPE_HINT_1, CAVE_TYPE_SHOP_B, CAVE_TYPE_MOBLIN, CAVE_TYPE_DOOR_REPAIR, CAVE_TYPE_SHOP_A, CAVE_TYPE_GAMBLE, 0
        !byte CAVE_TYPE_POTION_SHOP, CAVE_TYPE_HINT_2, CAVE_TYPE_HINT_3, 0, CAVE_TYPE_HINT_2, CAVE_TYPE_WARP, CAVE_TYPE_DOOR_REPAIR, CAVE_TYPE_SHOP_SECRET
        ; Rangée 2 (32..47 : A-3 .. P-3)
        !byte CAVE_TYPE_WARP, CAVE_TYPE_SWORD_MAGIC, 0, CAVE_TYPE_WARP, CAVE_TYPE_MOBLIN, CAVE_TYPE_SHOP_B, CAVE_TYPE_SHOP_B, CAVE_TYPE_POTION_SHOP
        !byte CAVE_TYPE_MOBLIN, CAVE_TYPE_POTION_SHOP, 0, CAVE_TYPE_HEART_CHOICE, CAVE_TYPE_HEART_GIFT, CAVE_TYPE_MOBLIN, 0, CAVE_TYPE_HEART_GIFT
        ; Rangée 3 (48..63 : A-4 .. P-4)
        !byte 0, CAVE_TYPE_MOBLIN, CAVE_TYPE_SHOP_B, CAVE_TYPE_POTION_SHOP, CAVE_TYPE_SHOP_SECRET, 0, 0, 0
        !byte 0, CAVE_TYPE_FAIRY, CAVE_TYPE_WARP, 0, 0, CAVE_TYPE_MOBLIN, 0, 0
        ; Rangée 4 (64..79 : A-5 .. P-5)
        !byte 0, 0, 0, CAVE_TYPE_FAIRY, CAVE_TYPE_SHOP_B, CAVE_TYPE_POTION_SHOP, CAVE_TYPE_SHOP_B, CAVE_TYPE_WARP
        !byte CAVE_TYPE_MOBLIN, CAVE_TYPE_WARP, CAVE_TYPE_SHOP_B, CAVE_TYPE_POTION_SHOP, 0, CAVE_TYPE_SHOP_B, CAVE_TYPE_HEART_CHOICE, 0
        ; Rangée 5 (80..95 : A-6 .. P-6)
        !byte 0, CAVE_TYPE_HEART_CHOICE, CAVE_TYPE_MOBLIN, CAVE_TYPE_MOBLIN, 0, 0, CAVE_TYPE_HEART_CHOICE, 0
        !byte CAVE_TYPE_MOBLIN, 0, 0, CAVE_TYPE_HEART_CHOICE, 0, 0, CAVE_TYPE_SHOP_A, CAVE_TYPE_HEART_GIFT
        ; Rangée 6 (96..111 : A-7 .. P-7)
        !byte CAVE_TYPE_GAMBLE, 0, CAVE_TYPE_MOBLIN, CAVE_TYPE_DOOR_REPAIR, CAVE_TYPE_SHOP_SECRET, 0, CAVE_TYPE_SHOP_A, CAVE_TYPE_MOBLIN
        !byte CAVE_TYPE_DOOR_REPAIR, 0, CAVE_TYPE_DOOR_REPAIR, CAVE_TYPE_HEART_GIFT, 0, 0, CAVE_TYPE_HEART_CHOICE, CAVE_TYPE_SHOP_B
        ; Rangée 7 (112..127 : A-8 .. P-8)
        !byte CAVE_TYPE_GAMBLE, CAVE_TYPE_MOBLIN, CAVE_TYPE_MOBLIN, 0, 0, CAVE_TYPE_MOBLIN, CAVE_TYPE_GAMBLE, CAVE_TYPE_SWORD_WOOD
        !byte CAVE_TYPE_POTION_SHOP, CAVE_TYPE_WARP, 0, CAVE_TYPE_WARP, CAVE_TYPE_GAMBLE, CAVE_TYPE_DOOR_REPAIR, 0, 0

; ---------------------------------------------------------------------------
; Trampolines Overlay Inventaire (Banque 27)
; ---------------------------------------------------------------------------
open_inventory:
        jsr cart_load_sprites_npc       ; Charge les sprites d'objets (Banque 13)
        lda #CART_BANK_OVL_INV
        ldx #20                         ; 20 pages = 5120 octets (ovl_inv.dat = 4372 o)
        jsr cart_load_overlay
        jmp $a000                      ; open_inventory

inventory_update:
        jmp $a003                      ; inventory_update

close_inventory:
        jsr $a006                      ; ovl_inventory_close
        lda current_world_type
        cmp #WORLD_DUNGEON
        beq .rst_dung_spr
        jmp cart_load_sprites_ow
.rst_dung_spr:
        jmp cart_load_sprites_dung

inv_display_current_page:
        jmp $a012

; ---------------------------------------------------------------------------
; Trampolines Overlay Cavernes & Échoppes (Banque 28)
; ---------------------------------------------------------------------------
cave_enter:
        lda #CART_BANK_OVL_CAVE
        ldx #16                         ; 16 pages = 4096 octets (ovl_cave.dat = 3141 o)
        jsr cart_load_overlay
        jmp $a000                      ; cave_enter

cave_update:
        jmp $a003                      ; cave_update

cave_draw:
        jmp $a006                      ; cave_draw

cave_draw_screen:
        lda #CART_BANK_OVL_CAVE
        ldx #16
        jsr cart_load_overlay
        jmp $a00f

; ---------------------------------------------------------------------------
; Trampolines Overlay Menu Debug (Banque 30)
; ---------------------------------------------------------------------------
open_debug:
        lda #CART_BANK_OVL_DEBUG
        ldx #16                         ; 16 pages = 4096 octets (ovl_debug.dat = 2715 o)
        jsr cart_load_overlay
        jmp $a000                      ; open_debug

debug_update:
        jmp $a003                      ; debug_update

debug_exec_hook_cmd:
        lda #CART_BANK_OVL_DEBUG
        ldx #16                         ; 16 pages = 4096 octets
        jsr cart_load_overlay
        jmp $a006                      ; debug_exec_hook_cmd

debug_render_screen:
        jmp $a009
