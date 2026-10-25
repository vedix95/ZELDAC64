; ---------------------------------------------------------------------------
; disk.asm : Gestion des I/O disquette C64 (1541 / D64)
;   - Chargement d'overlays KERNAL (OVERWORLD.OVL, DUNGEON.OVL)
;   - Sauvegarde et chargement de SAVE.DAT (3 slots)
; ---------------------------------------------------------------------------

!zone disk

disk_device:    !byte 8                 ; Unité active (8 par défaut)

name_ow_chunk:  !text "OW3"
NAME_OW_CHUNK_LEN = 3

name_dung_file: !text "DUNG1"
NAME_DUNG_LEN   = 5

cached_dungeon_level: !byte 0
cached_ow_chunk:      !byte $ff

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

        ; Désactive le curseur KERNAL pour protéger la RAM écran
        lda #1
        sta CURSOR_FLAG

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
; Indicateur visuel de chargement disquette en bas à droite (Ligne 24, cols 26..39)
; ---------------------------------------------------------------------------
disk_loading_frame: !byte 0
disk_loading_tick:  !byte 0

disk_show_loading:
        ; S'assure que l'écran est visible pour afficher l'indicateur
        lda VIC_CTRL1
        ora #%00010000
        sta VIC_CTRL1

        ; Écrit "[DISK] LOADING... [TRI]" en ligne 24 (colonnes 26..39)
        ldx #0
-       lda .loading_text,x
        sta $07da,x
        lda .loading_cols,x
        sta $dbda,x
        inx
        cpx #14
        bne -
        lda #0
        sta disk_loading_frame
        sta disk_loading_tick
        rts

.loading_text:
        !byte 120, 32, 76, 79, 65, 68, 73, 78, 71, 46, 46, 46, 32, 116
        ; [DISK], ' ', 'L', 'O', 'A', 'D', 'I', 'N', 'G', '.', '.', '.', ' ', [TRIFORCE]

.loading_cols:
        !byte COL_YELLOW, COL_BLACK, COL_WHITE, COL_WHITE, COL_WHITE, COL_WHITE, COL_WHITE, COL_WHITE, COL_WHITE, COL_YELLOW, COL_YELLOW, COL_YELLOW, COL_BLACK, COL_YELLOW

disk_loading_irq:
        inc disk_loading_tick
        lda disk_loading_tick
        and #$07                        ; Anime toutes les 8 interruptions CIA (~7.5 Hz)
        bne +
        jsr disk_loading_animate
+       jmp $ea31                       ; Poursuit l'IRQ système KERNAL

disk_loading_animate:
        inc disk_loading_frame
        lda disk_loading_frame

        ; Clignotement de l'icône disquette (col 26) et de la Triforce (col 39)
        and #$02
        bne +
        lda #COL_YELLOW
        sta $dbda
        lda #COL_ORANGE
        sta $dbe7
        jmp ++
+       lda #COL_WHITE
        sta $dbda
        lda #COL_YELLOW
        sta $dbe7
++
        ; Animation cyclique des 3 points "..." (cols 35..37)
        lda disk_loading_frame
        lsr
        and #$03
        tax
        lda .dot_pat0,x
        sta $07e3
        lda .dot_pat1,x
        sta $07e4
        lda .dot_pat2,x
        sta $07e5
        rts

.dot_pat0: !byte 46, 46, 46, 32
.dot_pat1: !byte 32, 46, 46, 32
.dot_pat2: !byte 32, 32, 46, 32

disk_hide_loading:
        ; Efface l'indicateur de chargement en ligne 24 (colonnes 26..39)
        lda #32                         ; Espace
        ldx #13
-       sta $07da,x
        dex
        bpl -
        lda #COL_BLACK
        ldx #13
-       sta $dbda,x
        dex
        bpl -
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

        jsr disk_show_loading

        jsr disk_prepare_kernal_io

        ; Redirige l'interruption vers notre animation de chargement
        sei
        lda #<disk_loading_irq
        sta $0314
        lda #>disk_loading_irq
        sta $0315
        cli

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
        jsr disk_hide_loading
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
        ora #$30
        sta name_ow_chunk + 2

        lda #0
        sta cached_dungeon_level

        jsr clear_map_memory
        lda #NAME_OW_CHUNK_LEN
        ldx #<name_ow_chunk
        ldy #>name_ow_chunk
        jsr disk_load_file
        bcs .ow_chunk_err

        ; Restaure le jeu de caractères Overworld ($2000 et $2540) et tables
        jsr copy_map_charset
        jsr set_overworld_tables

        lda MAP_ENEMIES_PTR
        sta map_enemies_ptr
        lda MAP_ENEMIES_PTR+1
        sta map_enemies_ptr+1
        clc
        rts

.ow_chunk_err:
        lda #$ff
        sta cached_ow_chunk
        sec
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
        ; Invalide le cache de chunk Overworld
        lda #$ff
        sta cached_ow_chunk

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
        ; 1. Prépare le nom de fichier "DUNG1" .. "DUNG9"
        lda current_dungeon_level
        ora #$30                ; '1'..'9'
        sta name_dung_file + 4

        ; 2. Purge la mémoire carte dynamique ($C000..$CFFF)
        jsr clear_map_memory

        ; 3. Charge le fichier binaire du donjon
        lda #NAME_DUNG_LEN
        ldx #<name_dung_file
        ldy #>name_dung_file
        jsr disk_load_file
        bcs .dung_err

        ; Permute le jeu de caractères pour le Donjon ($2000 et $2540)
        jsr copy_map_charset
        jsr set_dungeon_tables

        ; 4. Extrait le pointeur d'ennemis du donjon depuis l'en-tête (MAP_ENEMIES_PTR)
        lda MAP_ENEMIES_PTR
        sta map_enemies_ptr
        lda MAP_ENEMIES_PTR+1
        sta map_enemies_ptr+1

        ; 5. Met à jour le cache et le type de monde
        lda current_dungeon_level
        sta cached_dungeon_level
        lda #WORLD_DUNGEON
        sta current_world_type

        ; 6. Applique les couleurs authentiques du donjon
        jsr apply_dungeon_colors
        clc
        rts

.dung_err:
        sec
        rts
        rts

; Alias de compatibilité
disk_load_map_underworld:
        jmp disk_load_dungeon
