; ---------------------------------------------------------------------------
; cart_stream.asm : Moteur de Streaming ROM Cartouche Magic Desk (Type 19)
; Remplace intégralement l'ancien pilote disquette IEC (1541) par du streaming
; instantané depuis les 32 banques de 8 Ko de la cartouche (0 délai, 0 disque).
; ---------------------------------------------------------------------------

!zone cart_stream

cached_dungeon_level:   !byte 0
cached_ow_chunk:        !byte $ff

; Les constantes CART_REG, CART_DISABLE, CART_BANK_* sont définies dans src/cart_defs.inc

; ---------------------------------------------------------------------------
; disk_ensure_ow_chunk : Vérifie que le chunk Overworld pour current_room_y est en RAM
; ---------------------------------------------------------------------------
disk_ensure_ow_chunk:
        lda current_room_y
        lsr
        and #3
        ; Fallthrough vers disk_ensure_ow_chunk_a

; ---------------------------------------------------------------------------
; disk_ensure_ow_chunk_a : Charge le chunk Overworld A (0..3) s'il n'est pas déjà en RAM
; ---------------------------------------------------------------------------
disk_ensure_ow_chunk_a:
        and #3
        cmp cached_ow_chunk
        bne .load_ow_chunk
        clc
        rts

.load_ow_chunk:
        sta cached_ow_chunk

        lda #0
        sta cached_dungeon_level

        ; --- Streaming ROM Cartouche instantané ---
        lda cached_ow_chunk
        clc
        adc #CART_BANK_OW0
        sta CART_REG
        jsr cart_copy_to_c000
        lda #CART_DISABLE
        sta CART_REG

.ow_chunk_loaded:
        ; Restaure le jeu de caractères Overworld ($2000, $2540, $2640) et tables
        jsr copy_map_charset
        jsr set_overworld_tables

        lda MAP_ENEMIES_PTR
        sta map_enemies_ptr
        lda MAP_ENEMIES_PTR+1
        sta map_enemies_ptr+1
        clc
        rts

; ---------------------------------------------------------------------------
; disk_load_map_overworld : Purge la mémoire et charge le chunk Overworld actif
; ---------------------------------------------------------------------------
disk_load_map_overworld:
        ; Force le rechargement du chunk Overworld correspondant à current_room_y
        lda #0
        sta cached_dungeon_level
        lda #$ff
        sta cached_ow_chunk

        jsr disk_ensure_ow_chunk
        bcs .ow_err

        ; Restaure le jeu de caractères Overworld ($2000 et $2540)
        jsr copy_map_charset
        jsr set_overworld_tables
        jsr apply_map_colors
        lda #WORLD_OVERWORLD
        sta current_world_type
        clc
        rts

.ow_err:
        sec
        rts

; ---------------------------------------------------------------------------
; copy_map_charset : Copie 576 octets de caractères depuis MAP_CHARSET_PTR
;   - 256 octets vers $2000 (caractères 0..31, tuiles 0..7)
;   - 256 octets vers $2540 (caractères 168..199, tuiles 8..12)
;   - 64 octets vers $2640 (caractères 200..207, tuiles 13..14 dont rocher escargot)
; ---------------------------------------------------------------------------
copy_map_charset:
        lda MAP_CHARSET_PTR
        sta ZP_SRC
        lda MAP_CHARSET_PTR+1
        sta ZP_SRC+1
        ora ZP_SRC
        beq .no_copy

        ldy #0
-       lda (ZP_SRC),y
        sta $2000,y
        iny
        bne -

        inc ZP_SRC+1
-       lda (ZP_SRC),y
        sta $2540,y
        iny
        bne -

        inc ZP_SRC+1
        ldy #63
-       lda (ZP_SRC),y
        sta $2640,y
        dey
        bpl -
.no_copy:
        rts

set_dungeon_tables:
        ldx #15
-       lda dung_tile_char_base,x
        sta tile_char_base,x
        lda dung_tile_flags,x
        sta tile_flags,x
        dex
        bpl -
        rts

set_overworld_tables:
        ldx #15
-       lda ow_tile_char_base,x
        sta tile_char_base,x
        lda ow_tile_flags,x
        sta tile_flags,x
        dex
        bpl -
        rts

; ---------------------------------------------------------------------------
; disk_load_dungeon : Charge le donjon correspondant à current_dungeon_level
;   - Streaming instantané depuis les Banques 14..22 de la cartouche Magic Desk
;   - Cache RAM : si déjà en mémoire, aucun rechargement requis
;   - Mise à jour dynamique de map_enemies_ptr et des couleurs
; ---------------------------------------------------------------------------
disk_load_dungeon:
        ; Invalide le cache de chunk Overworld
        lda #$ff
        sta cached_ow_chunk

        ; Valider current_dungeon_level (1..9)
        lda current_dungeon_level
        bne +
        lda #1
        sta current_dungeon_level
+       cmp cached_dungeon_level
        bne .load_dung
        ; Déjà en cache RAM ! Applique les couleurs et sort instantanément
        jsr copy_map_charset
        jsr set_dungeon_tables
        jsr apply_dungeon_colors
        lda #WORLD_DUNGEON
        sta current_world_type
        clc
        rts

.load_dung:
        ; --- Chargement instantané par cartouche (Streaming ROM) ---
        lda current_dungeon_level
        clc
        adc #CART_BANK_DUNG_BASE
        sta CART_REG
        jsr cart_copy_to_c000
        lda #CART_DISABLE
        sta CART_REG

        ; Permute le jeu de caractères pour le Donjon ($2000 et $2540)
        jsr copy_map_charset
        jsr set_dungeon_tables

        ; Extrait le pointeur d'ennemis du donjon depuis l'en-tête (MAP_ENEMIES_PTR)
        lda MAP_ENEMIES_PTR
        sta map_enemies_ptr
        lda MAP_ENEMIES_PTR+1
        sta map_enemies_ptr+1

        ; Met à jour le cache et le type de monde
        lda current_dungeon_level
        sta cached_dungeon_level
        lda #WORLD_DUNGEON
        sta current_world_type

        ; Applique les couleurs authentiques du donjon
        jsr apply_dungeon_colors
        clc
        rts

; Alias de compatibilité
disk_load_map_underworld:
        jmp disk_load_dungeon
