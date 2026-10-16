; ============================================================================
; gameplay.asm : Système d'améliorations de gameplay - Version minimale fonctionnelle
; ============================================================================

; --- Variables de gameplay ---
gameplay_items:     !byte 0, 0, 0  ; Tableau des objets collectés (3 items max)

; --- Fonctions de gameplay ---
gameplay_init:
        ; Initialisation du système de gameplay
        rts



; --- Collecte d'un objet ---
gameplay_collect_item:
        ; Entrée : A = item_id (1-3)
        ; Sortie : Z = 1 si succès, 0 si déjà possédé
        cmp #1
        beq .collect_sword
        cmp #2
        beq .collect_shield
        cmp #3
        beq .collect_boots
        lda #0
        rts

.collect_sword:
        lda gameplay_items
        cmp #1
        beq .already_have
        lda #1
        sta gameplay_items
        jmp .success

.collect_shield:
        lda gameplay_items+1
        cmp #1
        beq .already_have
        lda #1
        sta gameplay_items+1
        jmp .success

.collect_boots:
        lda gameplay_items+2
        cmp #1
        beq .already_have
        lda #1
        sta gameplay_items+2
        jmp .success

.already_have:
        lda #0
        rts

.success:
        lda #1
        rts