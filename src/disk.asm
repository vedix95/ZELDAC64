; ---------------------------------------------------------------------------
; disk.asm : Gestion des I/O disquette C64 (1541 / D64)
;   - Chargement d'overlays KERNAL (OVERWORLD.OVL, DUNGEON.OVL)
;   - Sauvegarde et chargement de SAVE.DAT (3 slots)
; ---------------------------------------------------------------------------

!zone disk

disk_device:    !byte 8                 ; Unité active (8 par défaut)

name_map_ow:    !text "MAP_OW"
NAME_MAP_OW_LEN = 6

name_dung_file: !text "DUNG1"
NAME_DUNG_LEN   = 5

cached_dungeon_level: !byte 0

name_savedat:   !text "SAVE.DAT"
NAME_SAVEDAT_LEN   = 8

; ---------------------------------------------------------------------------
; disk_init : Détecte l'unité de disquette active depuis la Page Zéro KERNAL ($BA)
; ---------------------------------------------------------------------------
disk_init:
        lda DEVICE_NUM
        cmp #8
        bcc .set_def
        cmp #12
        bcs .set_def
        sta disk_device
        rts
.set_def:
        lda #8
        sta disk_device
        rts

; ---------------------------------------------------------------------------
; clear_map_memory : Vide intégralement la zone mémoire dynamique ($A000..$CFFF)
; ---------------------------------------------------------------------------
clear_map_memory:
        lda #<MAP_DATA_ADDR
        sta ZP_SRC
        lda #>MAP_DATA_ADDR
        sta ZP_SRC+1
        ldx #MAP_DATA_MAX_PAGES         ; 48 pages x 256 octets = 12 Ko
        ldy #0
        lda #0
.clr_loop:
        sta (ZP_SRC),y
        iny
        bne .clr_loop
        inc ZP_SRC+1
        dex
        bne .clr_loop
        rts

; ---------------------------------------------------------------------------
; disk_prepare_kernal_io : Prépare le C64 pour un appel KERNAL IEC
;   - Coupe le son SID
;   - Désactive les sprites (évite les perturbations de timing DMA sur le bus IEC)
;   - Désactive l'interruption raster du jeu
;   - Rétablit l'IRQ standard KERNAL ($EA31) et les timers CIA
; ---------------------------------------------------------------------------
disk_prepare_kernal_io:
        sei
        ; Coupe le volume SID
        lda #0
        sta SID_VOLUME

        ; Désactive temporairement les sprites pendant l'I/O disquette
        sta VIC_SPRITE_EN

        ; Coupe l'IRQ raster du VIC-II
        sta VIC_IRQ_ENABLE
        asl VIC_IRQ_FLAG

        ; Restaure le vecteur IRQ KERNAL normal ($EA31)
        lda #$31
        sta $0314
        lda #$ea
        sta $0315

        ; Réactive le timer CIA1 pour le bus série KERNAL IEC
        lda #$81
        sta CIA1_ICR

        ; S'assure que KERNAL et I/O sont actifs
        lda #$36
        sta CPU_PORT
        cli
        rts

; ---------------------------------------------------------------------------
; disk_restore_game_io : Rétablit l'environnement de jeu après accès disque
; ---------------------------------------------------------------------------
disk_restore_game_io:
        sei
        ; Réactive le son au volume maximum
        lda #15
        sta SID_VOLUME

        ; Réinstalle notre interruption raster multiplexeur
        jsr init_raster_irq
        cli
        rts

; ---------------------------------------------------------------------------
; disk_load_file : Charge un fichier binaire à son adresse d'origine (Sec=1)
; Entrée :
;   A = longueur du nom de fichier
;   X = pointeur bas (lo) vers le nom
;   Y = pointeur haut (hi) vers le nom
; Sortie :
;   Carry = 0 : Succès
;   Carry = 1 : Erreur
; ---------------------------------------------------------------------------
disk_load_file:
        sta .namelen
        stx ZP_SRC
        sty ZP_SRC+1

        jsr disk_prepare_kernal_io

        ; SETNAM
        lda .namelen
        ldx ZP_SRC
        ldy ZP_SRC+1
        jsr SETNAM

        ; SETLFS : LFN=1, Device=disk_device, Sec=1 (adresse d'origine)
        lda #1
        ldx disk_device
        ldy #1
        jsr SETLFS

        ; LOAD : A=0 (chargement en RAM)
        lda #0
        jsr LOAD

        php                             ; préserve le code de statut (Carry)
        tax
        jsr disk_restore_game_io
        txa
        plp                             ; restaure Carry (0=ok, 1=erreur)
        rts

.namelen: !byte 0

; ---------------------------------------------------------------------------
; disk_save_file : Sauvegarde un bloc de mémoire sur disquette
; Entrée :
;   A = longueur du nom de fichier
;   X = pointeur bas vers le nom
;   Y = pointeur haut vers le nom
;   ZP_SRC ($0c-$0d) = adresse de début
;   ZP_DST ($0e-$0f) = adresse de fin + 1
; Sortie :
;   Carry = 0 : Succès
;   Carry = 1 : Erreur
; ---------------------------------------------------------------------------
disk_save_file:
        sta .snamelen
        stx ZP_TGT
        sty ZP_TGT+1

        jsr disk_prepare_kernal_io

        ; SETNAM
        lda .snamelen
        ldx ZP_TGT
        ldy ZP_TGT+1
        jsr SETNAM

        ; SETLFS : LFN=1, Device=disk_device, Sec=0
        lda #1
        ldx disk_device
        ldy #0
        jsr SETLFS

        ; SAVE : A = pointeur zéro page vers début, X/Y = adresse fin + 1
        lda #ZP_SRC
        ldx ZP_DST
        ldy ZP_DST+1
        jsr SAVE

        php
        jsr disk_restore_game_io
        plp
        rts

.snamelen: !byte 0

; ---------------------------------------------------------------------------
; disk_load_map_overworld : Purge la mémoire et charge la carte Overworld
; ---------------------------------------------------------------------------
disk_load_map_overworld:
        ; Invalide le cache donjon
        lda #0
        sta cached_dungeon_level

        ; Restaure le pointeur d'ennemis Overworld ($B800)
        lda #<$b800
        sta map_enemies_ptr
        lda #>$b800
        sta map_enemies_ptr+1

        ; Masque l'écran pendant le chargement (bus IEC / DMA propre)
        lda VIC_CTRL1
        and #%11101111
        sta VIC_CTRL1

        jsr clear_map_memory
        lda #NAME_MAP_OW_LEN
        ldx #<name_map_ow
        ldy #>name_map_ow
        jsr disk_load_file
        bcs .ow_err

        ; Restaure le jeu de caractères Overworld ($2000 et $2540)
        jsr copy_map_charset
        jsr set_overworld_tables

        ; Réinitialise le cache de donjon
        lda #0
        sta cached_dungeon_level

        jsr apply_map_colors
        lda #WORLD_OVERWORLD
        sta current_world_type

        lda VIC_CTRL1
        ora #%00010000
        sta VIC_CTRL1
        clc
        rts

.ow_err:
        lda VIC_CTRL1
        ora #%00010000
        sta VIC_CTRL1
        sec
        rts

; ---------------------------------------------------------------------------
; copy_map_charset : Copie 512 octets de caractères depuis MAP_CHARSET_PTR
;   - 256 octets vers $2000 (caractères 0..31, tuiles 0..7)
;   - 256 octets vers $2540 (caractères 168..199, tuiles 8..15)
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
; disk_load_dungeon : Charge le fichier donjon correspondant à current_dungeon_level
;   - Optimisation cache : si déjà en RAM, évite l'I/O disquette (0 délai)
;   - Masquage écran (blanking DMA) pendant la lecture IEC
;   - Mise à jour dynamique de map_enemies_ptr et des couleurs
; ---------------------------------------------------------------------------
disk_load_dungeon:
        ; Valider current_dungeon_level (1..9)
        lda current_dungeon_level
        bne +
        lda #1
        sta current_dungeon_level
+       cmp cached_dungeon_level
        bne .load_from_disk
        ; Déjà en cache RAM ! Applique les couleurs et sort instantanément
        jsr copy_map_charset
        jsr set_dungeon_tables
        jsr apply_dungeon_colors
        lda #WORLD_DUNGEON
        sta current_world_type
        clc
        rts

.load_from_disk:
        ; 1. Masquer l'écran pour un accès DMA / bus IEC silencieux et propre
        lda VIC_CTRL1
        and #%11101111          ; Bit 4 = 0 (écran masqué)
        sta VIC_CTRL1

        ; 2. Prépare le nom de fichier "DUNG1" .. "DUNG9"
        lda current_dungeon_level
        ora #$30                ; '1'..'9'
        sta name_dung_file + 4

        ; 3. Purge la mémoire carte dynamique ($A000..$CFFF)
        jsr clear_map_memory

        ; 4. Charge le fichier binaire du donjon
        lda #NAME_DUNG_LEN
        ldx #<name_dung_file
        ldy #>name_dung_file
        jsr disk_load_file
        bcs .dung_err

        ; Permute le jeu de caractères pour le Donjon ($2000 et $2540)
        jsr copy_map_charset
        jsr set_dungeon_tables

        ; 5. Extrait le pointeur d'ennemis du donjon depuis l'en-tête ($A116)
        lda $a116
        sta map_enemies_ptr
        lda $a117
        sta map_enemies_ptr+1

        ; 6. Met à jour le cache et le type de monde
        lda current_dungeon_level
        sta cached_dungeon_level
        lda #WORLD_DUNGEON
        sta current_world_type

        ; 7. Applique les couleurs authentiques du donjon
        jsr apply_dungeon_colors

        ; 8. Réactive l'affichage écran
        lda VIC_CTRL1
        ora #%00010000          ; Bit 4 = 1 (écran visible)
        sta VIC_CTRL1
        clc
        rts

.dung_err:
        lda VIC_CTRL1
        ora #%00010000
        sta VIC_CTRL1
        sec
        rts

; Alias de compatibilité
disk_load_map_underworld:
        jmp disk_load_dungeon
