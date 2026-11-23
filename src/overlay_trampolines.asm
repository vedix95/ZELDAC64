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
        !byte CAVE_TYPE_WARP, CAVE_TYPE_SWORD_MAGIC, 0, CAVE_TYPE_WARP, 0, CAVE_TYPE_SHOP_B, CAVE_TYPE_SHOP_B, CAVE_TYPE_POTION_SHOP
        !byte CAVE_TYPE_MOBLIN, CAVE_TYPE_POTION_SHOP, 0, CAVE_TYPE_HEART_CHOICE, CAVE_TYPE_HEART_GIFT, CAVE_TYPE_MOBLIN, 0, CAVE_TYPE_HEART_GIFT
        ; Rangée 3 (48..63 : A-4 .. P-4)
        !byte 0, CAVE_TYPE_MOBLIN, CAVE_TYPE_SHOP_B, CAVE_TYPE_POTION_SHOP, CAVE_TYPE_SHOP_SECRET, 0, 0, 0
        !byte 0, CAVE_TYPE_FAIRY, CAVE_TYPE_WARP, 0, 0, CAVE_TYPE_MOBLIN, 0, 0
        ; Rangée 4 (64..79 : A-5 .. P-5)
        !byte 0, 0, 0, CAVE_TYPE_FAIRY, CAVE_TYPE_SHOP_B, 0, CAVE_TYPE_SHOP_B, CAVE_TYPE_WARP
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
        ldx #24                         ; 24 pages = 6144 octets (Banque 27 = 8192 o)
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
        ldx #18                         ; 18 pages = 4608 octets (ovl_cave.dat ~4 Ko)
        jsr cart_load_overlay
        jmp $a000                      ; cave_enter

cave_update:
        jmp $a003                      ; cave_update

cave_draw:
        jmp $a006                      ; cave_draw

cave_draw_screen:
        lda #CART_BANK_OVL_CAVE
        ldx #18
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

; ---------------------------------------------------------------------------
; Trampolines Overlay Objets & Événements Spéciaux (Banque 29)
; ---------------------------------------------------------------------------
OVL_ITEMS_PAGES = 20                    ; 20 pages = 5120 octets (ovl_items.dat)

load_ovl_items:
        lda #CART_BANK_OVL_ITEMS
        ldx #OVL_ITEMS_PAGES
        jmp cart_load_overlay

enter_cellar:
        jsr load_ovl_items
        jmp $a00f                       ; ovl_enter_cellar

exit_cellar:
        jsr load_ovl_items
        jmp $a012                       ; ovl_exit_cellar

dungeon_setup_room_41:
        jsr load_ovl_items
        jmp $a015                       ; ovl_d1_hermit_41

open_gameover:
        jsr load_ovl_items
        jmp $a018                       ; ovl_gameover_open

gameover_update:
        jsr load_ovl_items
        jmp $a01b                       ; ovl_gameover_update

open_ending:
        jsr load_ovl_items
        jmp $a01e                       ; ovl_ending_open

ending_update:
        jmp $a021                       ; ovl_ending_update

d9_gate_blocked:
        jsr load_ovl_items
        jmp $a024                       ; ovl_d9_gate_blocked

ovl_use_food:
        jsr load_ovl_items
        jmp $a027                       ; ovl_use_food_exec

dungeon_setup_d7_goriya:
        jsr load_ovl_items
        jmp $a02a                       ; ovl_d7_hungry_goriya_setup

exit_dungeon:
        jsr load_ovl_items
        jmp $a02d                       ; ovl_exit_dungeon

OVL_SAVE_PAGES = 16                     ; 16 pages = 4096 octets (ovl_save.dat)

load_ovl_save:
        lda #CART_BANK_OVL_SAVE
        ldx #OVL_SAVE_PAGES
        jmp cart_load_overlay

save_current_slot:
        jsr load_ovl_save
        jmp $a006                       ; ovl_save_current_slot

save_inc_death:
        jsr load_ovl_save
        jmp $a009                       ; ovl_save_inc_death

; Raccourcis clavier déportés hors basse RAM (< $2000) : Carry=1 => reboucler main_loop
main_handle_hotkeys:
        lda key_d_pressed
        beq +
        jsr open_debug
        sec
        rts
+       lda key_2_pressed
        beq +
        lda current_world_type
        cmp #WORLD_DUNGEON
        beq +
        jsr enter_dungeon
        sec
        rts
+       lda key_1_pressed
        beq +
        lda current_world_type
        cmp #WORLD_OVERWORLD
        beq +
        jsr exit_dungeon
        sec
        rts
+       lda game_state
        cmp #STATE_PLAYING
        bne .hk_done
        lda key_g_pressed
        beq .chk_k4
        jsr open_gameover
        sec
        rts
.chk_k4:
        lda key_4_pressed
        beq .chk_k3
        jsr save_current_slot
        jsr sound_secret_chime
.chk_k3:
        lda key_3_pressed
        beq .hk_done
        lda #0
        sta key_3_pressed
        lda dual_sid_enabled
        eor #1
        sta dual_sid_enabled
        beq .disable_sid2
        lda #15
        jsr sound_set_sid2_volume
        jmp .hk_done
.disable_sid2:
        lda #0
        jsr sound_set_sid2_volume
.hk_done:
        clc
        rts

; ---------------------------------------------------------------------------
; Trampolines Game Over : SAVE + CONTINUE / SAVE + QUIT vers l'intro
; ---------------------------------------------------------------------------
gameover_save_and_continue:
        jsr save_current_slot
        jsr load_ovl_items
        jmp $a039                       ; ovl_gameover_continue

gameover_save_and_quit:
        jsr save_current_slot
        jmp $a00c                       ; ovl_quit_to_intro (Banque 32 déjà chargée !)

collect_loot_drop:
        jsr load_ovl_items
        jmp $a03c                       ; ovl_update_loot
