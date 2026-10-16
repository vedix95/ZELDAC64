; ---------------------------------------------------------------------------
; disk.asm : Gestion des I/O disquette C64 (1541 / D64)
;   - Chargement d'overlays KERNAL (OVERWORLD.OVL, DUNGEON.OVL)
;   - Sauvegarde et chargement de SAVE.DAT (3 slots)
; ---------------------------------------------------------------------------

!zone disk

disk_device:    !byte 8                 ; Unité active (8 par défaut)

name_map_ow:    !text "MAP_OW"
NAME_MAP_OW_LEN = 6

name_map_uw:    !text "MAP_UW"
NAME_MAP_UW_LEN = 6

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
        jsr disk_restore_game_io
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
        jsr clear_map_memory
        lda #NAME_MAP_OW_LEN
        ldx #< name_map_ow
        ldy #> name_map_ow
        jsr disk_load_file
        bcs .ow_err
        jsr apply_map_colors
        lda #WORLD_OVERWORLD
        sta current_world_type
        clc
        rts
.ow_err:
        sec
        rts

; ---------------------------------------------------------------------------
; disk_load_map_underworld : Purge la mémoire et charge la carte Donjon
; ---------------------------------------------------------------------------
disk_load_map_underworld:
        jsr clear_map_memory
        lda #NAME_MAP_UW_LEN
        ldx #< name_map_uw
        ldy #> name_map_uw
        jsr disk_load_file
        bcs .uw_err
        jsr apply_map_colors
        lda #WORLD_DUNGEON
        sta current_world_type
        clc
        rts
.uw_err:
        sec
        rts
