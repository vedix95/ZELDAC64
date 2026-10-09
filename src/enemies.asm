; ---------------------------------------------------------------------------
; enemies.asm : Système complet d'ennemis Zelda (Octorok et Moblin)
;
; Gère :
;   - 2 ennemis simultanés par salle (Sprites VIC 3 et 4)
;   - 1 projectile ennemi (Rocher d'Octorok ou Lance de Moblin, Sprite VIC 5)
;   - Déplacements autonomes et évitement des collisions avec le décor
;   - Attaques à distance (crachat de rocher, lancer de lance)
;   - Système de parade au bouclier de Link (renvoi/blocage des tirs !)
;   - Réactions aux coups d'épée (recul, clignotement blanc, points de vie)
;   - Réactions aux armes secondaires (flèche mortelle, boomerang étourdissant,
;     déflagration 3x3 de bombe destructrice)
;   - Animation de mort en nuage de fumée rétro et butin (Rubis / Cœurs)
;   - Sons SID dédiés (coups, mort, tir, parade, ramassage)
; ---------------------------------------------------------------------------

MAX_ENEMIES             = 2

TYPE_NONE               = 0
TYPE_OCTO               = 1
TYPE_MOBLIN             = 2

EN_STATE_DEAD           = 0
EN_STATE_WALK           = 1
EN_STATE_HURT           = 2             ; touché / recul / étourdi
EN_STATE_DYING          = 3             ; nuage de fumée de mort

OCTO_HP                 = 1
MOBLIN_HP               = 2

; Variables globales des ennemis (pour 2 slots d'ennemis : index 0 et 1)
en_type:                !byte 0, 0
en_state:               !byte 0, 0
en_hp:                  !byte 0, 0
en_x:                   !word 0, 0      ; position X (16 bits)
en_y:                   !byte 0, 0      ; position Y (8 bits)
en_dir:                 !byte 0, 0      ; DIR_DOWN, UP, LEFT, RIGHT
en_timer:               !byte 0, 0      ; compte à rebours d'action/changement
en_anim:                !byte 0, 0      ; image courante (0 ou 1)
en_anim_tick:           !byte 0, 0      ; temporisateur d'alternance des pas
en_hurt_timer:          !byte 0, 0      ; temporisateur d'invincibilité/recul

; Projectile ennemi (1 seul actif à la fois, Sprite 5)
en_proj_active:         !byte 0
en_proj_type:           !byte 0         ; TYPE_OCTO (rocher) ou TYPE_MOBLIN (lance)
en_proj_x:              !word 0
en_proj_y:              !byte 0
en_proj_dir:            !byte 0

; Variables temporaires locales
en_idx:                 !byte 0
en_dx:                  !word 0
en_dy:                  !byte 0
en_tmp_x:               !word 0
en_tmp_y:               !byte 0
en_recul_dir:           !byte 0

; Invulnérabilité et clignotement de Link
player_hurt_timer:      !byte 0

; Générateur pseudo-aléatoire (LFSR 8 bits)
rand_seed:              !byte $a5

; Tables des pointeurs de sprites selon (direction * 2 + anim)
octo_ptrs:
        !byte < (sprite_enemies_octo_down_0 / 64)
        !byte < (sprite_enemies_octo_down_1 / 64)
        !byte < (sprite_enemies_octo_up_0 / 64)
        !byte < (sprite_enemies_octo_up_1 / 64)
        !byte < (sprite_enemies_octo_left_0 / 64)
        !byte < (sprite_enemies_octo_left_1 / 64)
        !byte < (sprite_enemies_octo_right_0 / 64)
        !byte < (sprite_enemies_octo_right_1 / 64)

moblin_ptrs:
        !byte < (sprite_enemies_moblin_down_0 / 64)
        !byte < (sprite_enemies_moblin_down_1 / 64)
        !byte < (sprite_enemies_moblin_up_0 / 64)
        !byte < (sprite_enemies_moblin_up_1 / 64)
        !byte < (sprite_enemies_moblin_left_0 / 64)
        !byte < (sprite_enemies_moblin_left_1 / 64)
        !byte < (sprite_enemies_moblin_right_0 / 64)
        !byte < (sprite_enemies_moblin_right_1 / 64)

; ---------------------------------------------------------------------------
; Table de spawn des ennemis pour les 9 salles (indices 0..8)
; Format par salle :
;   Ennemi 0 : type, spawn_tile_x, spawn_tile_y
;   Ennemi 1 : type, spawn_tile_x, spawn_tile_y
; ---------------------------------------------------------------------------
world_enemies:
        ; Salle 0 : (0, 0) Grotte Montagne - 2 Octoroks
        !byte TYPE_OCTO,   5, 4,   TYPE_OCTO,   14, 5
        ; Salle 1 : (1, 0) Sanctuaire Nord - 1 Moblin, 1 Octorok
        !byte TYPE_MOBLIN, 6, 4,   TYPE_OCTO,   13, 5
        ; Salle 2 : (2, 0) Lac Bleu - 2 Octoroks
        !byte TYPE_OCTO,   4, 3,   TYPE_OCTO,    6, 7
        ; Salle 3 : (0, 1) Forêt Ouest - 2 Moblins
        !byte TYPE_MOBLIN, 7, 3,   TYPE_MOBLIN, 12, 6
        ; Salle 4 : (1, 1) Le Carrefour - 1 Moblin, 1 Octorok
        !byte TYPE_MOBLIN, 6, 4,   TYPE_OCTO,   13, 5
        ; Salle 5 : (2, 1) Rivage Est - 2 Octoroks
        !byte TYPE_OCTO,   5, 3,   TYPE_OCTO,   11, 6
        ; Salle 6 : (0, 2) Bosquet Perdu - 1 Octorok, 1 Moblin
        !byte TYPE_OCTO,   8, 4,   TYPE_MOBLIN, 13, 6
        ; Salle 7 : (1, 2) Départ Zelda 1 - Sanctuaire sans ennemis
        !byte TYPE_NONE,   0, 0,   TYPE_NONE,    0, 0
        ; Salle 8 : (2, 2) Labyrinthe - 2 Moblins
        !byte TYPE_MOBLIN, 7, 3,   TYPE_MOBLIN, 12, 6

; ---------------------------------------------------------------------------
; get_rand : nombre pseudo-aléatoire 8 bits dans A
; ---------------------------------------------------------------------------
get_rand:
        lda rand_seed
        asl
        bcc +
        eor #$1d
+       sta rand_seed
        rts

; ---------------------------------------------------------------------------
; enemies_init : initialisation globale au lancement du jeu
; ---------------------------------------------------------------------------
enemies_init:
        lda #0
        sta player_hurt_timer
        sta en_proj_active
        sta en_type
        sta en_type+1
        sta en_state
        sta en_state+1
        jsr enemies_room_init
        rts

; ---------------------------------------------------------------------------
; enemies_room_init : fait apparaître les ennemis de la salle courante
; ---------------------------------------------------------------------------
enemies_room_init:
        lda #0
        sta en_proj_active              ; réinitialise les projectiles en vol

        ; Index de la salle (0..8) * 6 octets
        lda current_room_idx
        asl                             ; * 2
        sta ZP_TMP
        asl                             ; * 4
        clc
        adc ZP_TMP                      ; * 6
        tax

        ; --- Ennemi 0 ---
        lda world_enemies,x
        sta en_type
        beq .init_en1                   ; TYPE_NONE
        lda #EN_STATE_WALK
        sta en_state
        lda #DIR_DOWN
        sta en_dir
        lda #0
        sta en_anim
        sta en_anim_tick
        sta en_hurt_timer
        lda #30
        sta en_timer

        ; PV selon type
        lda en_type
        cmp #TYPE_OCTO
        bne +
        lda #OCTO_HP
        jmp ++
+       lda #MOBLIN_HP
++      sta en_hp

        ; Coordonnées sprite : X = 24 + tile_x * 16 - 4
        lda world_enemies+1,x           ; tile_x
        asl
        asl
        asl
        asl                             ; tile_x * 16
        clc
        adc #20                         ; + 24 - 4
        sta en_x
        lda #0
        adc #0
        sta en_x+1

        ; Y = 82 + tile_y * 16 - 2
        lda world_enemies+2,x           ; tile_y
        asl
        asl
        asl
        asl                             ; tile_y * 16
        clc
        adc #80                         ; + 82 - 2
        sta en_y

.init_en1:
        ; --- Ennemi 1 ---
        lda world_enemies+3,x
        sta en_type+1
        beq .init_done
        lda #EN_STATE_WALK
        sta en_state+1
        lda #DIR_DOWN
        sta en_dir+1
        lda #0
        sta en_anim+1
        sta en_anim_tick+1
        sta en_hurt_timer+1
        lda #45
        sta en_timer+1

        ; PV selon type
        lda en_type+1
        cmp #TYPE_OCTO
        bne +
        lda #OCTO_HP
        jmp ++
+       lda #MOBLIN_HP
++      sta en_hp+1

        ; Coordonnées sprite : X = 24 + tile_x * 16 - 4
        lda world_enemies+4,x           ; tile_x
        asl
        asl
        asl
        asl
        clc
        adc #20
        sta en_x+2
        lda #0
        adc #0
        sta en_x+3

        ; Y = 82 + tile_y * 16 - 2
        lda world_enemies+5,x           ; tile_y
        asl
        asl
        asl
        asl
        clc
        adc #80
        sta en_y+1

.init_done:
        rts

; ---------------------------------------------------------------------------
; enemies_update : appelé à chaque frame de jeu
; ---------------------------------------------------------------------------
enemies_update:
        ; Décompte de l'invincibilité de Link
        lda player_hurt_timer
        beq +
        dec player_hurt_timer
+
        ; Mise à jour de chaque ennemi
        ldx #0
        stx en_idx
        jsr update_single_enemy

        ldx #1
        stx en_idx
        jsr update_single_enemy

        ; Mise à jour du projectile ennemi
        jsr update_enemy_projectile

        ; Détection des interactions / combats
        jsr check_sword_hits
        jsr check_item_hits
        jsr check_link_body_hits

        rts

; ---------------------------------------------------------------------------
; update_single_enemy : logique IA d'un ennemi (index dans en_idx)
; ---------------------------------------------------------------------------
update_single_enemy:
        ldx en_idx
        lda en_state,x
        bne +
        rts                             ; Mort / Inactif
+
        cmp #EN_STATE_DYING
        bne +
        jmp .update_dying
+       cmp #EN_STATE_HURT
        bne +
        jmp .update_hurt
+
        ; --- ÉTAT NORMAL (EN_STATE_WALK) ---
        ; 1. Avance de 1 pixel dans sa direction
        lda en_dir,x
        cmp #DIR_UP
        beq .walk_up
        cmp #DIR_DOWN
        beq .walk_dn
        cmp #DIR_LEFT
        beq .walk_lf

        ; Droite
        ldy en_idx
        bne +
        clc
        lda en_x
        adc #1
        sta en_x
        lda en_x+1
        adc #0
        sta en_x+1
        jmp .check_bounds
+       clc
        lda en_x+2
        adc #1
        sta en_x+2
        lda en_x+3
        adc #0
        sta en_x+3
        jmp .check_bounds

.walk_up:
        sec
        lda en_y,x
        sbc #1
        sta en_y,x
        jmp .check_bounds
.walk_dn:
        clc
        lda en_y,x
        adc #1
        sta en_y,x
        jmp .check_bounds
.walk_lf:
        ldy en_idx
        bne +
        sec
        lda en_x
        sbc #1
        sta en_x
        lda en_x+1
        sbc #0
        sta en_x+1
        jmp .check_bounds
+       sec
        lda en_x+2
        sbc #1
        sta en_x+2
        lda en_x+3
        sbc #0
        sta en_x+3
        jmp .check_bounds

.check_bounds:
        ldx en_idx
        ; Vérification des bords de l'écran
        lda en_y,x
        cmp #PLAYER_Y_MIN
        bcc .pick_new_dir
        cmp #PLAYER_Y_MAX
        bcs .pick_new_dir

        ; Test de collision avec le décor via check_point_solid
        ldy en_idx
        bne +
        clc
        lda en_x
        adc #8
        sta col_x
        lda en_x+1
        adc #0
        sta col_x+1
        jmp ++
+       clc
        lda en_x+2
        adc #8
        sta col_x
        lda en_x+3
        adc #0
        sta col_x+1
++
        ldx en_idx
        clc
        lda en_y,x
        adc #12
        sta col_y
        jsr check_point_solid
        bcc .bounds_ok                  ; libre !

.pick_new_dir:
        ; Obstacle ou bord atteint : choisit une nouvelle direction
        ldx en_idx
        jsr get_rand
        and #3
        sta en_dir,x
        jsr get_rand
        and #31
        clc
        adc #20
        sta en_timer,x
        jmp .anim_step

.bounds_ok:
        ldx en_idx
        ; Minuteur d'action
        dec en_timer,x
        bne .anim_step

        ; Temps écoulé : choisit aléatoirement entre tourner ou tirer
        jsr get_rand
        and #%00000111
        cmp #2
        bcs .just_turn                  ; 6 chances sur 8 : change de direction

        ; 2 chances sur 8 : Tir à distance ! (si projectile libre)
        lda en_proj_active
        bne .just_turn
        jsr enemy_shoot

.just_turn:
        ldx en_idx
        jsr get_rand
        and #3
        sta en_dir,x
        jsr get_rand
        and #63
        clc
        adc #30
        sta en_timer,x

.anim_step:
        ldx en_idx
        inc en_anim_tick,x
        lda en_anim_tick,x
        cmp #8
        bcc .step_end
        lda #0
        sta en_anim_tick,x
        lda en_anim,x
        eor #1
        sta en_anim,x
.step_end:
        rts

.update_hurt:
        ; Ennemi touché : recul et fin du flash
        ldx en_idx
        dec en_hurt_timer,x
        bne +
        lda #EN_STATE_WALK
        sta en_state,x
+       rts

.update_dying:
        ; Animation du nuage de fumée de mort
        ldx en_idx
        dec en_timer,x
        bne +
        lda #EN_STATE_DEAD
        sta en_state,x
        ; Récompense : chance de butin (Rubis ou Cœur)
        jsr spawn_loot
+       rts

; ---------------------------------------------------------------------------
; enemy_shoot : fait tirer l'ennemi courant (index dans en_idx)
; ---------------------------------------------------------------------------
enemy_shoot:
        ldx en_idx
        lda #1
        sta en_proj_active
        lda en_type,x
        sta en_proj_type
        lda en_dir,x
        sta en_proj_dir

        ldy en_idx
        bne +
        lda en_x
        sta en_proj_x
        lda en_x+1
        sta en_proj_x+1
        jmp ++
+       lda en_x+2
        sta en_proj_x
        lda en_x+3
        sta en_proj_x+1
++
        ldx en_idx
        lda en_y,x
        sta en_proj_y

        ; Bruitage de tir
        jsr sound_enemy_shoot
        rts

; ---------------------------------------------------------------------------
; update_enemy_projectile : avance le rocher ou la lance
; ---------------------------------------------------------------------------
update_enemy_projectile:
        lda en_proj_active
        bne +
        rts
+
        lda en_proj_dir
        cmp #DIR_UP
        beq .pj_up
        cmp #DIR_DOWN
        beq .pj_dn
        cmp #DIR_LEFT
        beq .pj_lf

        ; Droite (+2 px)
        clc
        lda en_proj_x
        adc #2
        sta en_proj_x
        lda en_proj_x+1
        adc #0
        sta en_proj_x+1
        jmp .pj_chk
.pj_lf:
        sec
        lda en_proj_x
        sbc #2
        sta en_proj_x
        lda en_proj_x+1
        sbc #0
        sta en_proj_x+1
        jmp .pj_chk
.pj_up:
        sec
        lda en_proj_y
        sbc #2
        sta en_proj_y
        jmp .pj_chk
.pj_dn:
        clc
        lda en_proj_y
        adc #2
        sta en_proj_y

.pj_chk:
        ; Hors écran ?
        lda en_proj_y
        cmp #PLAYER_Y_MIN
        bcc .pj_kill
        cmp #PLAYER_Y_MAX
        bcs .pj_kill

        ; Test de parade au bouclier de Link ou dégâts
        jsr check_projectile_hit_link
        rts

.pj_kill:
        lda #0
        sta en_proj_active
        rts

; ---------------------------------------------------------------------------
; check_projectile_hit_link : parade au bouclier ou blessure de Link
; ---------------------------------------------------------------------------
check_projectile_hit_link:
        ; Distance X (16 bits)
        sec
        lda en_proj_x
        sbc player_x
        sta en_dx
        lda en_proj_x+1
        sbc player_x+1
        cmp #0
        bne .pj_dx_neg
        lda en_dx
        cmp #12
        bcs .pj_no_hit
        jmp .pj_chk_y
.pj_dx_neg:
        cmp #$ff
        bne .pj_no_hit
        lda en_dx
        cmp #$f4
        bcc .pj_no_hit

.pj_chk_y:
        ; Distance Y
        sec
        lda en_proj_y
        sbc player_y
        bcs +
        eor #$ff
        adc #1
+       cmp #12
        bcs .pj_no_hit

        ; --- CONTACT AVEC LINK ---
        ; Link pare-t-il avec son bouclier ?
        ; Condition : Link n'attaque pas et fait face au projectile arrivant
        lda player_attacking
        bne .link_takes_proj_hit

        ; Direction opposée ?
        ; Proj vers BAS (0) <-> Link vers HAUT (1)
        ; Proj vers HAUT (1) <-> Link vers BAS (0)
        ; Proj vers GAUCHE (2) <-> Link vers DROITE (3)
        ; Proj vers DROITE (3) <-> Link vers GAUCHE (2)
        lda en_proj_dir
        eor #1                          ; inverse UP/DOWN ou LEFT/RIGHT
        cmp player_dir
        bne .link_takes_proj_hit

        ; PARÉ AU BOUCLIER !
        lda #0
        sta en_proj_active
        jsr sound_shield_block
        rts

.link_takes_proj_hit:
        lda #0
        sta en_proj_active
        jsr hurt_link
.pj_no_hit:
        rts

; ---------------------------------------------------------------------------
; check_sword_hits : teste si l'épée de Link tranche un ennemi
; ---------------------------------------------------------------------------
check_sword_hits:
        lda player_attacking
        bne +
        rts
+
        ; Calcule le point central de l'épée selon la direction de Link
        lda player_dir
        cmp #DIR_UP
        beq .sw_up
        cmp #DIR_DOWN
        beq .sw_dn
        cmp #DIR_LEFT
        beq .sw_lf

        ; Droite (+16 px)
        clc
        lda player_x
        adc #16
        sta en_tmp_x
        lda player_x+1
        adc #0
        sta en_tmp_x+1
        lda player_y
        clc
        adc #4
        sta en_tmp_y
        jmp .test_enemies_sword
.sw_lf:
        sec
        lda player_x
        sbc #16
        sta en_tmp_x
        lda player_x+1
        sbc #0
        sta en_tmp_x+1
        lda player_y
        clc
        adc #4
        sta en_tmp_y
        jmp .test_enemies_sword
.sw_up:
        lda player_x
        sta en_tmp_x
        lda player_x+1
        sta en_tmp_x+1
        sec
        lda player_y
        sbc #16
        sta en_tmp_y
        jmp .test_enemies_sword
.sw_dn:
        lda player_x
        sta en_tmp_x
        lda player_x+1
        sta en_tmp_x+1
        clc
        lda player_y
        adc #16
        sta en_tmp_y

.test_enemies_sword:
        ldx #0
        jsr test_sword_single
        ldx #1
        jsr test_sword_single
        rts

test_sword_single:
        stx en_idx
        lda en_state,x
        cmp #EN_STATE_WALK
        beq +
        rts                             ; ne peut être touché que s'il marche
+
        ; Distance X
        ldy en_idx
        bne .sw_e1
        sec
        lda en_tmp_x
        sbc en_x
        sta en_dx
        lda en_tmp_x+1
        sbc en_x+1
        jmp .sw_dx_eval
.sw_e1:
        sec
        lda en_tmp_x
        sbc en_x+2
        sta en_dx
        lda en_tmp_x+1
        sbc en_x+3

.sw_dx_eval:
        cmp #0
        bne +
        lda en_dx
        cmp #16
        bcs .sw_miss
        jmp .sw_chk_y
+       cmp #$ff
        bne .sw_miss
        lda en_dx
        cmp #$f0                        ; -16
        bcc .sw_miss

.sw_chk_y:
        ldx en_idx
        sec
        lda en_tmp_y
        sbc en_y,x
        bcs +
        eor #$ff
        adc #1
+       cmp #16
        bcs .sw_miss

        ; --- TOUCHÉ PAR L'ÉPÉE ! ---
        ldx en_idx
        dec en_hp,x
        beq .en_killed

        ; Ennemi blessé : recul et clignotement
        lda #EN_STATE_HURT
        sta en_state,x
        lda #10
        sta en_hurt_timer,x
        jsr sound_enemy_hit
        rts

.en_killed:
        lda #EN_STATE_DYING
        sta en_state,x
        lda #16                         ; durée du nuage de fumée
        sta en_timer,x
        jsr sound_enemy_die
.sw_miss:
        rts

; ---------------------------------------------------------------------------
; check_item_hits : interactions des armes secondaires avec les ennemis
; ---------------------------------------------------------------------------
check_item_hits:
        lda item_active
        bne +
        rts
+
        ldx #0
        jsr test_item_single
        ldx #1
        jsr test_item_single
        rts

test_item_single:
        stx en_idx
        lda en_state,x
        cmp #EN_STATE_WALK
        beq +
        rts
+
        ; Calcule distance X avec item_x
        ldy en_idx
        bne .it_e1
        sec
        lda item_x
        sbc en_x
        sta en_dx
        lda item_x+1
        sbc en_x+1
        jmp .it_dx_eval
.it_e1:
        sec
        lda item_x
        sbc en_x+2
        sta en_dx
        lda item_x+1
        sbc en_x+3

.it_dx_eval:
        cmp #0
        bne +
        lda en_dx
        cmp #16
        bcs .it_miss
        jmp .it_chk_y
+       cmp #$ff
        bne .it_miss
        lda en_dx
        cmp #$f0
        bcc .it_miss

.it_chk_y:
        ldx en_idx
        sec
        lda item_y
        sbc en_y,x
        bcs +
        eor #$ff
        adc #1
+       cmp #16
        bcs .it_miss

        ; --- IMPACT DE L'ARME SECONDAIRE ---
        lda item_active
        cmp #ITEM_BOW
        beq .arrow_hit
        cmp #ITEM_BOOMERANG
        beq .boom_hit
        cmp #ITEM_BOMB
        beq .bomb_blast_hit
        rts

.arrow_hit:
        ; Flèche mortelle
        lda #ITEM_NONE
        sta item_active
        ldx en_idx
        lda #EN_STATE_DYING
        sta en_state,x
        lda #16
        sta en_timer,x
        jsr sound_enemy_die
        rts

.boom_hit:
        ; Boomerang : étourdit le Moblin ou élimine l'Octorok
        ldx en_idx
        lda en_type,x
        cmp #TYPE_OCTO
        beq .arrow_hit                  ; Octorok meurt immédiatement
        ; Moblin est étourdi pendant 1.5s
        lda #EN_STATE_HURT
        sta en_state,x
        lda #75
        sta en_hurt_timer,x
        lda #1
        sta item_state                  ; le boomerang fait demi-tour
        jsr sound_shield_block
        rts

.bomb_blast_hit:
        ; Déflagration de bombe : mort instantanée
        lda item_state
        beq .it_miss                    ; pas encore explosée
        ldx en_idx
        lda #EN_STATE_DYING
        sta en_state,x
        lda #16
        sta en_timer,x
        jsr sound_enemy_die
.it_miss:
        rts

; ---------------------------------------------------------------------------
; check_link_body_hits : contact direct du corps d'un ennemi avec Link
; ---------------------------------------------------------------------------
check_link_body_hits:
        ldx #0
        jsr test_body_single
        ldx #1
        jsr test_body_single
        rts

test_body_single:
        stx en_idx
        lda en_state,x
        cmp #EN_STATE_WALK
        beq +
        rts
+
        ldy en_idx
        bne .bd_e1
        sec
        lda en_x
        sbc player_x
        sta en_dx
        lda en_x+1
        sbc player_x+1
        jmp .bd_dx_eval
.bd_e1:
        sec
        lda en_x+2
        sbc player_x
        sta en_dx
        lda en_x+3
        sbc player_x+1

.bd_dx_eval:
        cmp #0
        bne +
        lda en_dx
        cmp #12
        bcs .bd_miss
        jmp .bd_chk_y
+       cmp #$ff
        bne .bd_miss
        lda en_dx
        cmp #$f4
        bcc .bd_miss

.bd_chk_y:
        ldx en_idx
        sec
        lda en_y,x
        sbc player_y
        bcs +
        eor #$ff
        adc #1
+       cmp #12
        bcs .bd_miss

        ; Contact direct : Link est blessé
        jsr hurt_link
.bd_miss:
        rts

; ---------------------------------------------------------------------------
; hurt_link : inflige des dégâts à Link, recul et bruitage
; ---------------------------------------------------------------------------
hurt_link:
        lda player_hurt_timer
        beq +
        rts                             ; encore invincible
+       lda #32                         ; ~0.6s d'invulnérabilité
        sta player_hurt_timer

        lda hud_cur_hearts
        beq .dead_link
        dec hud_cur_hearts
        jsr hud_render

.dead_link:
        ; Son de blessure Link (bruit blanc grave)
        lda #15
        sta SID_VOLUME
        lda #$00
        sta SID_V1_FREQ_LO
        lda #$14
        sta SID_V1_FREQ_HI
        lda #$08
        sta SID_V1_AD
        lda #$00
        sta SID_V1_SR
        lda #%10000001
        sta SID_V1_CTRL
        rts

; ---------------------------------------------------------------------------
; spawn_loot : récompense aléatoire à la mort d'un ennemi
; ---------------------------------------------------------------------------
spawn_loot:
        jsr get_rand
        and #3
        beq .give_heart                 ; 25% : Cœur de vie
        cmp #1
        beq .give_rupee                 ; 25% : Rubis
        cmp #2
        beq .give_rupee                 ; 25% : Rubis
        rts                             ; 25% : rien

.give_rupee:
        inc hud_rupees
        jsr hud_render
        jsr sound_rupee
        rts

.give_heart:
        lda hud_cur_hearts
        cmp hud_max_hearts
        bcs +
        inc hud_cur_hearts
        jsr hud_render
        jsr sound_rupee
+       rts

; ---------------------------------------------------------------------------
; enemies_draw : affiche les sprites 3, 4 (ennemis) et 5 (projectile)
; ---------------------------------------------------------------------------
enemies_draw:
        ; Si la bombe explose en 3x3, elle occupe les sprites 2..6
        lda item_active
        cmp #ITEM_BOMB
        bne .draw_all
        lda item_state
        beq .draw_all
        rts                             ; laisse l'explosion afficher ses 5 sprites

.draw_all:
        ; --- DESSIN ENNEMI 0 (Sprite 3) ---
        ldx #0
        lda en_state
        bne .drw_e0
        ; Désactive Sprite 3
        lda VIC_SPRITE_EN
        and #%11110111
        sta VIC_SPRITE_EN
        jmp .draw_e1

.drw_e0:
        lda en_x
        sta VIC_SPRITE_X3
        lda en_y
        sta VIC_SPRITE_Y3

        ; MSB horizontal (bit 3)
        lda VIC_SPRITE_MSB
        and #%11110111
        sta ZP_TMP
        lda en_x+1
        beq +
        lda ZP_TMP
        ora #%00001000
        sta ZP_TMP
+       lda ZP_TMP
        sta VIC_SPRITE_MSB

        ; Choix du pointeur et couleur
        lda en_state
        cmp #EN_STATE_DYING
        beq .e0_dying
        cmp #EN_STATE_HURT
        beq .e0_flash

        ; Couleur normale rouge
        lda #COL_RED
        sta VIC_SPRITE_COL3

        lda en_type
        cmp #TYPE_OCTO
        bne +
        lda en_dir
        asl
        ora en_anim
        tax
        lda octo_ptrs,x
        sta SPRITE_PTR3
        jmp .e0_enable
+       lda en_dir
        asl
        ora en_anim
        tax
        lda moblin_ptrs,x
        sta SPRITE_PTR3
        jmp .e0_enable

.e0_flash:
        lda #COL_WHITE                  ; clignote en blanc quand touché
        sta VIC_SPRITE_COL3
        lda #< (sprite_link_proj_explosion / 64)
        sta SPRITE_PTR3
        jmp .e0_enable

.e0_dying:
        lda #COL_ORANGE
        sta VIC_SPRITE_COL3
        lda #< (sprite_link_proj_explosion / 64)
        sta SPRITE_PTR3

.e0_enable:
        lda VIC_SPRITE_EN
        ora #%00001000                  ; active Sprite 3
        sta VIC_SPRITE_EN
        lda VIC_SPRITE_MC
        ora #%00001000
        sta VIC_SPRITE_MC

.draw_e1:
        ; --- DESSIN ENNEMI 1 (Sprite 4) ---
        lda en_state+1
        bne .drw_e1_active
        ; Désactive Sprite 4
        lda VIC_SPRITE_EN
        and #%11101111
        sta VIC_SPRITE_EN
        jmp .draw_proj

.drw_e1_active:
        lda en_x+2
        sta VIC_SPRITE_X4
        lda en_y+1
        sta VIC_SPRITE_Y4

        ; MSB horizontal (bit 4)
        lda VIC_SPRITE_MSB
        and #%11101111
        sta ZP_TMP
        lda en_x+3
        beq +
        lda ZP_TMP
        ora #%00010000
        sta ZP_TMP
+       lda ZP_TMP
        sta VIC_SPRITE_MSB

        lda en_state+1
        cmp #EN_STATE_DYING
        beq .e1_dying
        cmp #EN_STATE_HURT
        beq .e1_flash

        lda #COL_RED
        sta VIC_SPRITE_COL4

        lda en_type+1
        cmp #TYPE_OCTO
        bne +
        lda en_dir+1
        asl
        ora en_anim+1
        tax
        lda octo_ptrs,x
        sta SPRITE_PTR4
        jmp .e1_enable
+       lda en_dir+1
        asl
        ora en_anim+1
        tax
        lda moblin_ptrs,x
        sta SPRITE_PTR4
        jmp .e1_enable

.e1_flash:
        lda #COL_WHITE
        sta VIC_SPRITE_COL4
        lda #< (sprite_link_proj_explosion / 64)
        sta SPRITE_PTR4
        jmp .e1_enable

.e1_dying:
        lda #COL_YELLOW
        sta VIC_SPRITE_COL4
        lda #< (sprite_link_proj_explosion / 64)
        sta SPRITE_PTR4

.e1_enable:
        lda VIC_SPRITE_EN
        ora #%00010000                  ; active Sprite 4
        sta VIC_SPRITE_EN
        lda VIC_SPRITE_MC
        ora #%00010000
        sta VIC_SPRITE_MC

.draw_proj:
        ; --- DESSIN PROJECTILE ENNEMI (Sprite 5) ---
        lda en_proj_active
        bne .drw_proj_active
        lda VIC_SPRITE_EN
        and #%11011111                  ; désactive Sprite 5
        sta VIC_SPRITE_EN
        rts

.drw_proj_active:
        lda en_proj_x
        sta VIC_SPRITE_X5
        lda en_proj_y
        sta VIC_SPRITE_Y5

        ; MSB horizontal (bit 5)
        lda VIC_SPRITE_MSB
        and #%11011111
        sta ZP_TMP
        lda en_proj_x+1
        beq +
        lda ZP_TMP
        ora #%00100000
        sta ZP_TMP
+       lda ZP_TMP
        sta VIC_SPRITE_MSB

        lda en_proj_type
        cmp #TYPE_OCTO
        bne .pj_moblin

        ; Rocher d'Octorok
        lda #< (sprite_enemies_octo_rock / 64)
        sta SPRITE_PTR5
        lda #COL_LRED
        sta VIC_SPRITE_COL5
        jmp .pj_enable

.pj_moblin:
        ; Lance de Moblin (horizontale ou verticale)
        lda en_proj_dir
        cmp #DIR_LEFT
        beq .spear_h
        cmp #DIR_RIGHT
        beq .spear_h
        lda #< (sprite_enemies_moblin_spear_v / 64)
        sta SPRITE_PTR5
        jmp +
.spear_h:
        lda #< (sprite_enemies_moblin_spear_h / 64)
        sta SPRITE_PTR5
+       lda #COL_LRED
        sta VIC_SPRITE_COL5

.pj_enable:
        lda VIC_SPRITE_EN
        ora #%00100000                  ; active Sprite 5
        sta VIC_SPRITE_EN
        lda VIC_SPRITE_MC
        ora #%00100000
        sta VIC_SPRITE_MC
        rts

; ---------------------------------------------------------------------------
; Effets sonores SID pour les ennemis
; ---------------------------------------------------------------------------
sound_enemy_shoot:
        lda #15
        sta SID_VOLUME
        lda #$20
        sta SID_V1_FREQ_LO
        lda #$25
        sta SID_V1_FREQ_HI
        lda #$06
        sta SID_V1_AD
        lda #$00
        sta SID_V1_SR
        lda #%00100001                  ; Dent de scie courte (pop de tir)
        sta SID_V1_CTRL
        rts

sound_enemy_hit:
        lda #15
        sta SID_VOLUME
        lda #$80
        sta SID_V1_FREQ_LO
        lda #$30
        sta SID_V1_FREQ_HI
        lda #$04
        sta SID_V1_AD
        lda #$00
        sta SID_V1_SR
        lda #%10000001                  ; Bruit sec d'impact
        sta SID_V1_CTRL
        rts

sound_enemy_die:
        lda #15
        sta SID_VOLUME
        lda #$00
        sta SID_V1_FREQ_LO
        lda #$18
        sta SID_V1_FREQ_HI
        lda #$0c
        sta SID_V1_AD
        lda #$00
        sta SID_V1_SR
        lda #%10000001                  ; Souffle d'explosion rétro
        sta SID_V1_CTRL
        rts

sound_shield_block:
        lda #15
        sta SID_VOLUME
        lda #$00
        sta SID_V1_FREQ_LO
        lda #$70
        sta SID_V1_FREQ_HI              ; Tintement aigu métallique "clink !"
        lda #$02
        sta SID_V1_AD
        lda #$00
        sta SID_V1_SR
        lda #%00010001                  ; Triangle
        sta SID_V1_CTRL
        rts

sound_rupee:
        lda #15
        sta SID_VOLUME
        lda #$a0
        sta SID_V1_FREQ_LO
        lda #$65
        sta SID_V1_FREQ_HI              ; Jingle mélodieux de récompense
        lda #$05
        sta SID_V1_AD
        lda #$00
        sta SID_V1_SR
        lda #%00010001                  ; Triangle
        sta SID_V1_CTRL
        rts
