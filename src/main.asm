; ---------------------------------------------------------------------------
; main.asm : point d'entrée
; Création d'un passionné à l'aide de son IA préférée issue de chez Google
; Assembleur : ACME   -   Cible : C64 (6510)
; ---------------------------------------------------------------------------
!cpu 6510
!source "src/c64.inc"
!source "src/cart_defs.inc"
!source "build/sprite_ptrs.inc"

; --- Stub BASIC : 10 SYS 2061 -------------------------------------------
* = $0801
        !word basic_end         ; pointeur vers la ligne suivante
        !word 10                ; numéro de ligne
        !byte $9e               ; token SYS
        !text "2061"
        !byte 0                 ; fin de ligne
basic_end:
        !word 0                 ; fin du programme BASIC

; --- Programme ----------------------------------------------------------
start:
!if start != 2061 {
        !error "L'adresse de start doit etre 2061 (SYS 2061)"
}
        jmp game_init

cart_present:
        !byte 0                         ; 0 = Disquette, 1 = Cartouche Magic Desk (Type 19)
cfg_dual_sid:
        !byte 0                         ; $0811: 0 = Mono (Single SID), 1 = Dual SID (Stereo)
cfg_sid2_addr_idx:
        !byte 0                         ; $0812: 0 = $D420, 1 = $D500, 2 = $DF00

; Les sprites doivent impérativement être en-dessous de $1000 (ou au-delà de $2000)
; car pour le VIC-II (banque 0), la zone $1000-$1FFF voit la ROM des caractères (chargen).
!align 63, 0
!source "src/sprites.asm"
!if * > $1000 {
        !error "Les sprites Link debordent sur la zone ROM chargen ($1000)"
}

!ifndef START_IN_DUNGEON {
        START_IN_DUNGEON = 0 ; 0 = Overworld normal, 1 = Donjon 1 Entrée, 2 = Donjon 1 Boss Aquamentus, 3 = Donjon 1 Stalfos
}
!ifndef START_IN_INVENTORY {
        START_IN_INVENTORY = 0 ; 1 = Ouvre directement l'inventaire au lancement
}
!ifndef START_IN_DEBUG {
        START_IN_DEBUG     = 0 ; 1 = Ouvre directement le menu debug au lancement
}

game_init:
        ; Désactive la ROM BASIC ($A000-$BFFF) pour libérer les 64 Ko de RAM
        ; $36 (%00110110) : RAM à $A000-$BFFF, I/O à $D000-$DFFF, KERNAL ACTIF à $E000-$FFFF
        lda #$36
        sta CPU_PORT

        ; Configure immédiatement le VIC-II vers SCREEN_RAM ($0400) et CHARSET_ADDR ($2000)
        lda #MEMSETUP_VALUE
        sta VIC_MEMSETUP

!if START_IN_DUNGEON == 0 {
        jsr disk_load_map_overworld
        jsr cart_load_sprites_ow
        lda #WORLD_OVERWORLD
        sta current_world_type
} else {
        lda #1
        sta current_dungeon_level
        jsr disk_load_dungeon
        jsr cart_load_sprites_dung
        lda #WORLD_DUNGEON
        sta current_world_type
!if START_IN_DUNGEON == 1 {
        lda #3
        sta current_room_x
        lda #7
        sta current_room_y
} else if START_IN_DUNGEON == 2 {
        lda #5
        sta current_room_x
        lda #3
        sta current_room_y
        lda #70
        sta player_x
        lda #0
        sta player_x+1
        lda #144
        sta player_y
        lda #DIR_RIGHT
        sta player_dir
} else if START_IN_DUNGEON == 3 {
        lda #4
        sta current_room_x
        lda #7
        sta current_room_y
}
}
        jsr init_video
        jsr clear_screen
        jsr dungeon_init
        jsr load_room
        jsr hud_init
        jsr player_init
        jsr items_init
        jsr enemies_init
!if START_IN_DUNGEON != 0 {
        jsr dungeon_on_enter_room
}
        jsr player_draw
        jsr enemies_prep_multiplexer
        lda cfg_dual_sid
        ldx cfg_sid2_addr_idx
        jsr sound_set_dual_sid_config
        jsr sound_init
        jsr init_raster_irq
!if START_IN_DUNGEON == 0 {
        lda #MUSIC_OVERWORLD
} else {
        lda #MUSIC_DUNGEON
}
        jsr music_play

        lda #STATE_PLAYING
        sta game_state

!if START_IN_INVENTORY == 1 {
        jsr open_inventory
}
!if START_IN_DEBUG == 1 {
        jsr open_debug
}

main_loop:
        jsr wait_frame
        jsr read_input

        ; Auto-warp debug hook (activable par mémoire ou moniteur)
        lda debug_hook_cmd
        beq +
        cmp #3
        beq .hook_inv_resident
        jsr debug_exec_hook_cmd
        jmp +
.hook_inv_resident:
        ; Ouverture de l'inventaire depuis le code résident : l'overlay
        ; inventaire écrase $A000, donc on ne peut pas l'appeler depuis
        ; l'overlay debug qui contient le hook.
        jsr open_inventory
        lda debug_hook_arg
        sta inv_page
        jsr inv_display_current_page
        lda #0
        sta debug_hook_cmd
+
        ; Dispatch selon l'état de jeu
        lda game_state
        cmp #STATE_DEBUG
        bne +
        jmp .in_debug
+       cmp #STATE_INVENTORY
        bne +
        jmp .in_inventory
+       cmp #STATE_CAVE
        bne +
        jmp .in_cave
+       cmp #STATE_CELLAR
        bne +
        jmp .in_cellar
+       cmp #STATE_RAFT
        bne +
        jmp .in_raft
+

        ; Touche D : ouvre l'écran de debug depuis le jeu normal
        lda key_d_pressed
        beq +
        jsr open_debug
        jmp main_loop
+
        ; Touche 2 : Bascule vers le Donjon (recharge map_uw)
        lda key_2_pressed
        beq +
        lda current_world_type
        cmp #WORLD_DUNGEON
        beq +
        jsr enter_dungeon
        jmp main_loop
+
        ; Touche 1 : Bascule vers l'Overworld (recharge map_ow)
        lda key_1_pressed
        beq +
        lda current_world_type
        cmp #WORLD_OVERWORLD
        beq +
        jsr exit_dungeon
        jmp main_loop
+
        ; Touche 3 : Bascule Dual SID (Mono 1 SID / Stéréo 2 SIDs $D420)
        lda game_state
        cmp #STATE_PLAYING
        bne +
        lda key_3_pressed
        beq +
        lda #0
        sta key_3_pressed
        lda dual_sid_enabled
        eor #1
        sta dual_sid_enabled
        beq .disable_sid2
        lda #15
        jsr sound_set_sid2_volume
        jmp +
.disable_sid2:
        lda #0
        jsr sound_set_sid2_volume
+

        ; --- ÉTAT DE JEU NORMAL ---
        ; Bouton B (Manette Xbox Bouton B / Touche 'B') : ouvre l'inventaire
        lda btn_b_pressed
        beq .play_frame
        jsr open_inventory
        jmp main_loop

.play_frame:
        jsr player_update
        lda game_state
        cmp #STATE_PLAYING
        bne .skip_play_draw
        jsr items_update
        jsr enemies_update
        jsr dungeon_update
        lda game_state
        cmp #STATE_PLAYING
        bne .skip_play_draw
        jsr player_draw
        jsr items_draw
        jsr enemies_prep_multiplexer
        jsr hud_blink_update
.skip_play_draw:
        jmp main_loop

.in_inventory:
        jsr inventory_update
        jmp main_loop

.in_cave:
        jsr cave_update
        jsr cave_draw
        jmp main_loop

.in_cellar:
        jsr cellar_update
        jsr items_update
        jsr cellar_draw
        jmp main_loop

.in_raft:
        jsr raft_update
        jsr player_draw
        jmp main_loop

.in_debug:
        jsr debug_update
        jmp main_loop

; Synchronisation sur l'interruption raster VBlank (50 Hz).
wait_frame:
        lda #0
        sta frame_ready
.wait:
        lda frame_ready
        beq .wait
        rts

!source "src/tiles_data.asm"
!source "src/input.asm"
!source "src/player.asm"

; Buffers de travail résidents non volatils
dungeon_room_state   = $033c           ; 128 octets en tampon cassette ($033c..$03bb)
room_buf             = $cd00           ; 200 octets en zone haute ($cd00..$cdc7)
target_room_buf      = $ce00           ; 200 octets en zone haute dynamique ($ce00..$cec7)

; Tampons d'état persistants sous $2000 ($1BF8..$1FFF = 1032 octets libres)
visited_rooms:
visited_ow_rooms:    !fill 128, 0
visited_uw_rooms:    !fill 128, 0
cave_room_cleared:   !fill 128, 0

; Tables de fréquences audio et fanfares ponctuelles sous $2000
!source "src/music_data_low.inc"

; Tables de statistiques des ennemis Zelda (logées sous $2000 pour alléger la haute RAM)
en_base_hp:
        !byte 0, 1, 2, 2, 3, 1, 1, 2, 4, 2, 3, 9, 2, 4, 6, 1, 1, 2, 1, 1, 2, 3, 5, 4, 8, 5, 10, 2, 9, 10, 6, 4, 255, 255, 2, 4, 6, 8, 8, 8, 8, 2, 4, 10, 16

en_base_damage:
        !byte 0, 1, 1, 1, 2, 1, 1, 1, 2, 1, 2, 2, 1, 4, 4, 1, 1, 2, 1, 1, 1, 1, 2, 2, 4, 2, 4, 1, 2, 2, 2, 2, 0, 2, 2, 4, 1, 2, 2, 2, 2, 2, 2, 2, 4

en_base_color:
        !byte COL_BLACK, COL_RED, COL_BLUE, COL_RED, COL_BLUE, COL_RED, COL_BLUE, COL_RED, COL_BLUE, COL_ORANGE, COL_BROWN, COL_CYAN, COL_GREEN, COL_RED, COL_BLUE, COL_RED, COL_BLUE, COL_GREEN, COL_GREEN, COL_ORANGE, COL_WHITE, COL_RED, COL_BLUE, COL_RED, COL_BLUE, COL_RED, COL_BLUE, COL_ORANGE, COL_ORANGE, COL_LIGHT_RED, COL_LGREY, COL_BLUE, COL_PURPLE, COL_CYAN, COL_RED, COL_BLUE, COL_GREEN, COL_BROWN, COL_GREEN, COL_GREEN, COL_ORANGE, COL_RED, COL_BLUE, COL_ORANGE, COL_PURPLE

en_ai_type:
        !byte AI_ROAM, AI_ROAM, AI_ROAM, AI_ROAM, AI_ROAM, AI_HOP, AI_HOP, AI_BURROW, AI_BURROW, AI_FLY, AI_STATUE, AI_FLY, AI_WATER, AI_ROAM, AI_ROAM, AI_FLY, AI_FLY, AI_SLIME, AI_SLIME, AI_RUSH, AI_ROAM, AI_ROAM, AI_ROAM, AI_SHIELD, AI_SHIELD, AI_TELEPORT, AI_TELEPORT, AI_ROAM, AI_ROAM, AI_HOP, AI_ROAM, AI_FLY, AI_FLY, AI_RUSH, AI_ROAM, AI_ROAM, AI_BOSS, AI_BOSS, AI_BOSS, AI_BOSS, AI_BOSS, AI_BOSS, AI_BOSS, AI_FLY, AI_BOSS

en_proj_type_tbl:
        !byte PROJ_NONE, PROJ_ROCK, PROJ_ROCK, PROJ_SPEAR, PROJ_SPEAR, PROJ_NONE, PROJ_NONE, PROJ_NONE, PROJ_NONE, PROJ_NONE, PROJ_NONE, PROJ_NONE, PROJ_FIREBALL, PROJ_MAGIC, PROJ_MAGIC, PROJ_NONE, PROJ_NONE, PROJ_NONE, PROJ_NONE, PROJ_NONE, PROJ_NONE, PROJ_BOOMERANG, PROJ_BOOMERANG, PROJ_NONE, PROJ_NONE, PROJ_MAGIC, PROJ_MAGIC, PROJ_NONE, PROJ_NONE, PROJ_NONE, PROJ_NONE, PROJ_NONE, PROJ_NONE, PROJ_NONE, PROJ_NONE, PROJ_NONE, PROJ_FIREBALL, PROJ_NONE, PROJ_FIREBALL, PROJ_FIREBALL, PROJ_NONE, PROJ_FIREBALL, PROJ_FIREBALL, PROJ_FIREBALL, PROJ_FIREBALL

en_sprite_tbl_lo:
        !byte <none_ptrs, <octo_ptrs, <octo_ptrs, <moblin_ptrs, <moblin_ptrs, <tektite_ptrs, <tektite_ptrs, <leever_ptrs, <leever_ptrs, <peahat_ptrs, <armos_ptrs, <ghini_ptrs, <zora_ptrs, <lynel_ptrs, <lynel_ptrs, <keese_ptrs, <keese_ptrs, <zol_ptrs, <gel_ptrs, <rope_ptrs, <stalfos_ptrs, <goriya_ptrs, <goriya_ptrs, <darknut_ptrs, <darknut_ptrs, <wizzrobe_ptrs, <wizzrobe_ptrs, <wallmaster_ptrs, <likelike_ptrs, <polsvoice_ptrs, <gibdo_ptrs, <vire_ptrs, <bubble_ptrs, <trap_ptrs, <lanmola_ptrs, <lanmola_ptrs, <aquamentus_ptrs, <dodongo_ptrs, <manhandla_ptrs, <gleeok_ptrs, <digdogger_ptrs, <gohma_ptrs, <gohma_ptrs, <patra_ptrs, <ganon_ptrs

en_sprite_tbl_hi:
        !byte >none_ptrs, >octo_ptrs, >octo_ptrs, >moblin_ptrs, >moblin_ptrs, >tektite_ptrs, >tektite_ptrs, >leever_ptrs, >leever_ptrs, >peahat_ptrs, >armos_ptrs, >ghini_ptrs, >zora_ptrs, >lynel_ptrs, >lynel_ptrs, >keese_ptrs, >keese_ptrs, >zol_ptrs, >gel_ptrs, >rope_ptrs, >stalfos_ptrs, >goriya_ptrs, >goriya_ptrs, >darknut_ptrs, >darknut_ptrs, >wizzrobe_ptrs, >wizzrobe_ptrs, >wallmaster_ptrs, >likelike_ptrs, >polsvoice_ptrs, >gibdo_ptrs, >vire_ptrs, >bubble_ptrs, >trap_ptrs, >lanmola_ptrs, >lanmola_ptrs, >aquamentus_ptrs, >dodongo_ptrs, >manhandla_ptrs, >gleeok_ptrs, >digdogger_ptrs, >gohma_ptrs, >gohma_ptrs, >patra_ptrs, >ganon_ptrs

; Le jeu de caractères est à une adresse fixe ($2000)
!if * > CHARSET_ADDR {
        !error "Le code et les buffers debordent sur le jeu de caracteres ($2000)"
}
* = CHARSET_ADDR
!source "src/charset.asm"

; Zone des sprites dynamiques ($2800..$3FFF = 6 Ko en VIC Banque 0)
; Remplie à la volée par streaming cartouche (cart_load_sprites_ow, dung, boss, npc)
; Pas de données statiques ici dans le PRG résident.

; Code CPU au-delà de la banque VIC 0 ($4000..$CFFF)
; $4000..$7FFF est toujours 100% RAM en modes CPU_PORT $36 et $37.
* = $4000

current_cart_bank: !byte 0

; ---------------------------------------------------------------------------
; cart_stream_copy : Copie rapide de pages ROM ($8000..) vers ZP_DST en RAM
; Entrée : A = Banque cartouche, X = Nombre de pages (256 o), ZP_DST = Adresse RAM cible
; ---------------------------------------------------------------------------
cart_stream_copy:
        sta current_cart_bank
        php
        lda #<$8000
        sta ZP_SRC
        lda #>$8000
        sta ZP_SRC+1
        jmp .csc_page_loop

; cart_stream_copy_from : Copie rapide depuis ZP_SRC vers ZP_DST en RAM
; Entrée : A = Banque cartouche, X = Nombre de pages, ZP_SRC, ZP_DST
cart_stream_copy_from:
        sta current_cart_bank
        php

.csc_page_loop:
        sei
        lda current_cart_bank
        sta CART_REG            ; Sélectionne la banque cartouche à $DE00
        lda #$37
        sta CPU_PORT            ; Active LORAM=1 pour lire la ROM cartouche à $8000

        ldy #0
-       lda (ZP_SRC),y
        sta (ZP_DST),y
        iny
        bne -
        inc ZP_SRC+1
        inc ZP_DST+1

        lda #$36
        sta CPU_PORT            ; Rétablit le mode RAM de jeu sous BASIC
        lda #CART_DISABLE
        sta CART_REG            ; Déconnecte la cartouche
        cli                     ; Laisse passer les interruptions raster et audio
        nop
        nop

        dex
        bne .csc_page_loop

        plp
        rts

; cart_copy_to_c000 : Rétro-compatibilité pour les chunks et donjons
cart_copy_to_c000:
        sta current_cart_bank
        php
        ldx #13                 ; 13 pages = 3328 octets ($C000..$CCFF)
        lda #<$8000
        sta ZP_SRC
        lda #>$8000
        sta ZP_SRC+1
        lda #<$c000
        sta ZP_DST
        lda #>$c000
        sta ZP_DST+1

.c0_page_loop:
        sei
        lda current_cart_bank
        sta CART_REG            ; Active la banque cartouche
        lda #$37
        sta CPU_PORT            ; Active LORAM=1 pour lire la ROM cartouche à $8000

        ldy #0
-       lda (ZP_SRC),y
        sta (ZP_DST),y
        iny
        bne -
        inc ZP_SRC+1
        inc ZP_DST+1

        lda #$36
        sta CPU_PORT            ; Rétablit le mode RAM de jeu sous BASIC
        lda #CART_DISABLE
        sta CART_REG            ; Déconnecte la cartouche
        cli                     ; Laisse passer les interruptions raster et audio
        nop
        nop

        dex
        bne .c0_page_loop

        plp
        rts

; Helpers de streaming contextuel de sprites
cart_load_sprites_ow:
        lda #<SPRITE_BUF_ADDR
        sta ZP_DST
        lda #>SPRITE_BUF_ADDR
        sta ZP_DST+1
        ldx #24                 ; 24 pages = 6144 octets ($2800..$3FFF)
        lda #CART_BANK_SPR_OW
        jmp cart_stream_copy

cart_load_sprites_dung:
        lda #<SPRITE_BUF_ADDR
        sta ZP_DST
        lda #>SPRITE_BUF_ADDR
        sta ZP_DST+1
        ldx #24
        lda #CART_BANK_SPR_DUNG
        jmp cart_stream_copy

cart_load_sprites_npc:
        lda #<SPRITE_BUF_ADDR
        sta ZP_DST
        lda #>SPRITE_BUF_ADDR
        sta ZP_DST+1
        ldx #24
        lda #CART_BANK_SPR_NPC
        jmp cart_stream_copy

cart_load_sprites_boss:
        lda #<$3400
        sta ZP_DST
        lda #>$3400
        sta ZP_DST+1
        ldx #12                 ; 12 pages = 3072 octets ($3400..$3FFF)
        lda #CART_BANK_SPR_BOSS
        jmp cart_stream_copy

; cart_load_overlay : Charge un overlay dans $A000 (A = Banque, X = nb pages)
cart_load_overlay:
        pha
        lda #<OVERLAY_RAM_ADDR
        sta ZP_DST
        lda #>OVERLAY_RAM_ADDR
        sta ZP_DST+1
        pla
        jmp cart_stream_copy

!source "src/tilemap.asm"
!source "src/transition.asm"
!source "src/items.asm"
!source "src/enemies.asm"
!source "src/dungeon.asm"
!source "src/hud.asm"
; Trampolines et persistance des Overlays Cartouche ($A000..$BFFF)
; Les modules Inventaire, Cavernes et Debug sont streamés à la demande.
!source "src/overlay_trampolines.asm"

; Moteur de Streaming Cartouche pour les cartes ($C000..$CCFF)
!source "src/disk.asm"

; Moteur Audio et partitions (Single SID + Dual SID)
!source "src/sound.asm"

!if * > OVERLAY_RAM_ADDR {
        !error "Le programme resident deborde sur la zone des overlays ($A000)"
}


