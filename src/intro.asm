; ===========================================================================
; intro.asm : Introduction légendaire de The Legend of Zelda (1986)
;
; Comprend :
;   1. Écran Titre & Cascade animée (Waterfall Title Screen)
;      - Grand logo majestueux "THE LEGEND OF ZELDA" avec Triforces dorées
;      - Falaises étagées de Death Mountain avec roches texturées et pins
;      - Chute d'eau centrale animée à double flux descendant et écume
;      - Bassin d'eau bleu avec vagues et reflets
;      - Mention clignotante "PUSH START BUTTON" et Copyright Nintendo 1986
;   2. Déroulement de l'histoire (Story Scroll)
;      - Prologue officiel de 1986 défilant dans le parchemin royal
;   3. Défilé des trésors de Zelda 1 (All of Treasures)
;      - Présentation de tous les 34 objets et armes légendaires avec leurs icônes
;   4. Défilé des monstres d'Hyrule (Monsters of Hyrule Parade)
;      - Présentation des 15 monstres officiels avec sprites animés 2x
;   5. Musique complète et authentique de Koji Kondo (SID 3 Voix)
; ===========================================================================

!zone intro

INTRO_PHASE_WATERFALL     = 0
INTRO_PHASE_FADE_STORY    = 1
INTRO_PHASE_STORY         = 2
INTRO_PHASE_FADE_TREAS    = 3
INTRO_PHASE_TREASURES     = 4
INTRO_PHASE_FADE_MONSTERS = 5
INTRO_PHASE_MONSTERS      = 6
INTRO_PHASE_FADE_WATER    = 7

intro_phase:         !byte INTRO_PHASE_WATERFALL
intro_timer:         !word 0
intro_water_frame:   !byte 0
intro_water_tick:    !byte 0
intro_blink_timer:   !byte 0
intro_scroll_line:   !byte 0
intro_scroll_tick:   !byte 0
intro_fade_step_idx: !byte 0
intro_fade_tick:     !byte 0
intro_music_part:    !byte 0
intro_music_step:    !byte 0
intro_music_delay:   !byte 0

; Variables spécifiques au défilé des monstres
intro_mon_idx:       !byte 0
intro_mon_frame:     !byte 0
intro_mon_tick:      !byte 0
intro_mon_anim_tick: !byte 0

music_cur_v1_hi:     !byte 0
music_cur_v1_lo:     !byte 0
music_cur_v1_trig:   !byte 0
music_cur_v2_hi:     !byte 0
music_cur_v2_lo:     !byte 0
music_cur_v2_trig:   !byte 0
music_cur_v3_perc:   !byte 0

CHAR_TRIFORCE   = 116
CHAR_SWORD      = 117
CHAR_SHIELD     = 118
CHAR_FLUTE      = 119
CHAR_RAFT       = 120
CHAR_LADDER     = 121
CHAR_BRACELET   = 122
CHAR_POTION     = 123
CHAR_WATER_0    = 124
CHAR_WATER_1    = 125
CHAR_WATER_2    = 126
CHAR_WATER_FOAM = 127

CHAR_ARROW      = 172
CHAR_RING       = 173
CHAR_ROD        = 174
CHAR_BOOK       = 175
CHAR_MAP        = 176
CHAR_COMPASS    = 177
CHAR_HEART_CONT = 178
CHAR_FAIRY      = 179
CHAR_CLOCK      = 180
CHAR_FOOD       = 181
CHAR_LETTER     = 182

CHAR_HEART      = 96
CHAR_RUPEE      = 98
CHAR_KEY        = 99
CHAR_BOMB       = 100
CHAR_BOOMERANG  = 101
CHAR_BOW        = 102
CHAR_CANDLE     = 103

; Buffer mémoire aligné pour le sprite du monstre actif
!align 63, 0
intro_spr_buffer:
        !fill 64, 0
intro_spr_block = (intro_spr_buffer / 64)

; Tables d'adresses d'écran et de couleur pour les 25 lignes (0..24)
intro_scr_lo:
        !byte <(SCREEN_RAM + 0),   <(SCREEN_RAM + 40),  <(SCREEN_RAM + 80),  <(SCREEN_RAM + 120)
        !byte <(SCREEN_RAM + 160), <(SCREEN_RAM + 200), <(SCREEN_RAM + 240), <(SCREEN_RAM + 280)
        !byte <(SCREEN_RAM + 320), <(SCREEN_RAM + 360), <(SCREEN_RAM + 400), <(SCREEN_RAM + 440)
        !byte <(SCREEN_RAM + 480), <(SCREEN_RAM + 520), <(SCREEN_RAM + 560), <(SCREEN_RAM + 600)
        !byte <(SCREEN_RAM + 640), <(SCREEN_RAM + 680), <(SCREEN_RAM + 720), <(SCREEN_RAM + 760)
        !byte <(SCREEN_RAM + 800), <(SCREEN_RAM + 840), <(SCREEN_RAM + 880), <(SCREEN_RAM + 920)
        !byte <(SCREEN_RAM + 960)

intro_scr_hi:
        !byte >(SCREEN_RAM + 0),   >(SCREEN_RAM + 40),  >(SCREEN_RAM + 80),  >(SCREEN_RAM + 120)
        !byte >(SCREEN_RAM + 160), >(SCREEN_RAM + 200), >(SCREEN_RAM + 240), >(SCREEN_RAM + 280)
        !byte >(SCREEN_RAM + 320), >(SCREEN_RAM + 360), >(SCREEN_RAM + 400), >(SCREEN_RAM + 440)
        !byte >(SCREEN_RAM + 480), >(SCREEN_RAM + 520), >(SCREEN_RAM + 560), >(SCREEN_RAM + 600)
        !byte >(SCREEN_RAM + 640), >(SCREEN_RAM + 680), >(SCREEN_RAM + 720), >(SCREEN_RAM + 760)
        !byte >(SCREEN_RAM + 800), >(SCREEN_RAM + 840), >(SCREEN_RAM + 880), >(SCREEN_RAM + 920)
        !byte >(SCREEN_RAM + 960)

intro_col_hi:
        !byte >(COLOR_RAM + 0),   >(COLOR_RAM + 40),  >(COLOR_RAM + 80),  >(COLOR_RAM + 120)
        !byte >(COLOR_RAM + 160), >(COLOR_RAM + 200), >(COLOR_RAM + 240), >(COLOR_RAM + 280)
        !byte >(COLOR_RAM + 320), >(COLOR_RAM + 360), >(COLOR_RAM + 400), >(COLOR_RAM + 440)
        !byte >(COLOR_RAM + 480), >(COLOR_RAM + 520), >(COLOR_RAM + 560), >(COLOR_RAM + 600)
        !byte >(COLOR_RAM + 640), >(COLOR_RAM + 680), >(COLOR_RAM + 720), >(COLOR_RAM + 760)
        !byte >(COLOR_RAM + 800), >(COLOR_RAM + 840), >(COLOR_RAM + 880), >(COLOR_RAM + 920)
        !byte >(COLOR_RAM + 960)

; ---------------------------------------------------------------------------
; intro_init : initialise l'introduction au démarrage de la machine
; ---------------------------------------------------------------------------
intro_init:
        lda #INTRO_PHASE_WATERFALL
        sta intro_phase
        lda #0
        sta intro_timer
        sta intro_timer+1
        sta intro_water_frame
        sta intro_water_tick
        sta intro_blink_timer
        sta intro_scroll_line
        sta intro_scroll_tick
        sta intro_fade_step_idx
        sta intro_fade_tick
        sta intro_music_part
        sta intro_music_step
        sta intro_music_delay
        sta intro_mon_idx
        sta intro_mon_frame
        sta intro_mon_tick
        sta intro_mon_anim_tick

        ; Masque tous les sprites au début
        lda #0
        sta VIC_SPRITE_EN

        ; Initialisation du SID pour la musique
        jsr intro_music_init

        ; Affiche l'écran splendide de la cascade
        jsr intro_draw_waterfall
        rts

; ---------------------------------------------------------------------------
; intro_update : boucle principale appelée chaque frame par main_loop
; ---------------------------------------------------------------------------
intro_update:
        ; 1. Mise à jour de la musique SID authentique
        jsr intro_music_update

        ; 2. Vérification si le joueur appuie sur un bouton pour démarrer
        lda btn_a_pressed
        ora btn_x_pressed
        ora btn_b_pressed
        ora joy_pressed
        beq .no_start_button

        ; Le joueur lance la partie !
        jmp launch_zelda_game

.no_start_button:
        inc intro_timer
        bne +
        inc intro_timer+1
+
        ; Selon la phase active
        lda intro_phase
        bne +
        jmp .update_waterfall
+       cmp #INTRO_PHASE_FADE_STORY
        bne +
        jmp .update_fade_story
+       cmp #INTRO_PHASE_STORY
        bne +
        jmp .update_story
+       cmp #INTRO_PHASE_FADE_TREAS
        bne +
        jmp .update_fade_treas
+       cmp #INTRO_PHASE_TREASURES
        bne +
        jmp .update_treasures
+       cmp #INTRO_PHASE_FADE_MONSTERS
        bne +
        jmp .update_fade_monsters
+       cmp #INTRO_PHASE_MONSTERS
        bne +
        jmp .update_monsters
+       jmp .update_fade_water

; ---------------------------------------------------------------------------
; 1. MISE A JOUR DE LA CASCADE (WATERFALL)
; ---------------------------------------------------------------------------
.update_waterfall:
        inc intro_water_tick
        lda intro_water_tick
        cmp #4
        bcc .wf_blink
        lda #0
        sta intro_water_tick

        inc intro_water_frame
        lda intro_water_frame
        cmp #3
        bcc +
        lda #0
        sta intro_water_frame
+
        jsr intro_animate_water

.wf_blink:
        inc intro_blink_timer
        lda intro_blink_timer
        and #%00100000
        beq .hide_text
        jsr intro_show_press_text
        jmp .check_wf_timeout
.hide_text:
        jsr intro_hide_press_text

.check_wf_timeout:
        ; Après environ 10 secondes (500 frames), fondu doux vers le prologue de l'histoire
        lda intro_timer+1
        cmp #1
        bcc .wf_done
        lda intro_timer
        cmp #244                        ; 256 + 244 = 500 frames
        bcc .wf_done

        lda #INTRO_PHASE_FADE_STORY
        sta intro_phase
        lda #0
        sta intro_fade_step_idx
        sta intro_fade_tick
.wf_done:
        rts

; ---------------------------------------------------------------------------
; 2. FONDU DOUX VERS L'HISTOIRE (FADE OUT TO BLACK)
; ---------------------------------------------------------------------------
.update_fade_story:
        inc intro_fade_tick
        lda intro_fade_tick
        cmp #4
        bcc .fade_s_wait
        lda #0
        sta intro_fade_tick

        jsr intro_fade_step
        inc intro_fade_step_idx
        lda intro_fade_step_idx
        cmp #4
        bcc .fade_s_wait

        lda #INTRO_PHASE_STORY
        sta intro_phase
        lda #0
        sta intro_scroll_line
        sta intro_scroll_tick
        jsr intro_draw_story_bg
.fade_s_wait:
        rts

; ---------------------------------------------------------------------------
; 3. DEFILEMENT DE L'HISTOIRE DANS LE PARCHEMIN (STORY SCROLL)
; ---------------------------------------------------------------------------
.update_story:
        inc intro_blink_timer
        lda intro_blink_timer
        and #%00100000
        beq .hide_st_prompt
        jsr intro_show_press_text_parchment
        jmp .st_scroll
.hide_st_prompt:
        jsr intro_hide_press_text_parchment

.st_scroll:
        inc intro_scroll_tick
        lda intro_scroll_tick
        cmp #35                         ; Une nouvelle ligne toutes les 0.7s
        bcc .story_done
        lda #0
        sta intro_scroll_tick

        jsr intro_scroll_story_step
        inc intro_scroll_line
        lda intro_scroll_line
        cmp #story_line_count
        bcc .story_done

        lda #INTRO_PHASE_FADE_TREAS
        sta intro_phase
        lda #0
        sta intro_fade_step_idx
        sta intro_fade_tick
.story_done:
        rts

; ---------------------------------------------------------------------------
; 4. FONDU DOUX VERS LES TRESORS (FADE OUT TO BLACK)
; ---------------------------------------------------------------------------
.update_fade_treas:
        inc intro_fade_tick
        lda intro_fade_tick
        cmp #4
        bcc .fade_t_wait
        lda #0
        sta intro_fade_tick

        jsr intro_fade_step
        inc intro_fade_step_idx
        lda intro_fade_step_idx
        cmp #4
        bcc .fade_t_wait

        lda #INTRO_PHASE_TREASURES
        sta intro_phase
        lda #0
        sta intro_scroll_line
        sta intro_scroll_tick
        jsr intro_draw_treasures_bg
.fade_t_wait:
        rts

; ---------------------------------------------------------------------------
; 5. PRESENTATION DES TRESORS (TREASURE SHOWCASE)
; ---------------------------------------------------------------------------
.update_treasures:
        inc intro_blink_timer
        lda intro_blink_timer
        and #%00100000
        beq .hide_tr_prompt
        jsr intro_show_press_text_parchment
        jmp .tr_scroll
.hide_tr_prompt:
        jsr intro_hide_press_text_parchment

.tr_scroll:
        inc intro_scroll_tick
        lda intro_scroll_tick
        cmp #38                         ; Défilement fluide de chaque objet
        bcc .tr_done
        lda #0
        sta intro_scroll_tick

        jsr intro_scroll_treasure_step
        inc intro_scroll_line
        lda intro_scroll_line
        cmp #treasure_count
        bcc .tr_done

        ; Bascule vers le défilé des monstres !
        lda #INTRO_PHASE_FADE_MONSTERS
        sta intro_phase
        lda #0
        sta intro_fade_step_idx
        sta intro_fade_tick
.tr_done:
        rts

; ---------------------------------------------------------------------------
; 6. FONDU DOUX VERS LES MONSTRES (FADE OUT TO BLACK)
; ---------------------------------------------------------------------------
.update_fade_monsters:
        inc intro_fade_tick
        lda intro_fade_tick
        cmp #4
        bcc .fade_m_wait
        lda #0
        sta intro_fade_tick

        jsr intro_fade_step
        inc intro_fade_step_idx
        lda intro_fade_step_idx
        cmp #4
        bcc .fade_m_wait

        lda #INTRO_PHASE_MONSTERS
        sta intro_phase
        jsr intro_draw_monsters_bg
.fade_m_wait:
        rts

; ---------------------------------------------------------------------------
; 7. DEFILE DES MONSTRES D'HYRULE (MONSTER SHOWCASE)
; ---------------------------------------------------------------------------
.update_monsters:
        ; Clignotement du texte "PUSH START BUTTON"
        inc intro_blink_timer
        lda intro_blink_timer
        and #%00100000
        beq .hide_mon_prompt
        jsr intro_show_press_text_parchment
        jmp .anim_mon
.hide_mon_prompt:
        jsr intro_hide_press_text_parchment

.anim_mon:
        ; Animation marche (Frame 0 <-> Frame 1 toutes les 16 frames)
        inc intro_mon_anim_tick
        lda intro_mon_anim_tick
        cmp #16
        bcc .mon_advance
        lda #0
        sta intro_mon_anim_tick
        lda intro_mon_frame
        eor #1
        sta intro_mon_frame
        jsr intro_copy_monster_sprite_frame

.mon_advance:
        ; Défilement vers le monstre suivant toutes les 140 frames (~2.8s)
        inc intro_mon_tick
        lda intro_mon_tick
        cmp #140
        bcc .mon_done
        lda #0
        sta intro_mon_tick
        sta intro_mon_anim_tick

        inc intro_mon_idx
        lda intro_mon_idx
        cmp #INTRO_MONSTER_COUNT
        bcc .show_next_mon

        ; Tous les monstres ont défilé !
        ; Masque Sprite 0
        lda #0
        sta VIC_SPRITE_EN

        ; Fondu vers la cascade
        lda #INTRO_PHASE_FADE_WATER
        sta intro_phase
        lda #0
        sta intro_fade_step_idx
        sta intro_fade_tick
        rts

.show_next_mon:
        jsr intro_display_current_monster
.mon_done:
        rts

; ---------------------------------------------------------------------------
; 8. FONDU DOUX VERS LA CASCADE (FADE OUT TO BLACK)
; ---------------------------------------------------------------------------
.update_fade_water:
        inc intro_fade_tick
        lda intro_fade_tick
        cmp #4
        bcc .fade_w_wait
        lda #0
        sta intro_fade_tick

        jsr intro_fade_step
        inc intro_fade_step_idx
        lda intro_fade_step_idx
        cmp #4
        bcc .fade_w_wait

        lda #INTRO_PHASE_WATERFALL
        sta intro_phase
        lda #0
        sta intro_timer
        sta intro_timer+1
        jsr intro_draw_waterfall
.fade_w_wait:
        rts

; ---------------------------------------------------------------------------
; DESSIN DE L'ECRAN DE LA CASCADE (WATERFALL TITLE SCREEN)
; ---------------------------------------------------------------------------
intro_draw_waterfall:
        lda #COL_BLACK
        sta VIC_BACKGROUND
        sta VIC_BORDER

        ; Efface l'écran (1000 caractères espace) et met les couleurs à noir
        ldx #0
.clr:
        lda #32
        sta SCREEN_RAM,x
        sta SCREEN_RAM+$100,x
        sta SCREEN_RAM+$200,x
        sta SCREEN_RAM+$2e8,x
        lda #COL_BLACK
        sta COLOR_RAM,x
        sta COLOR_RAM+$100,x
        sta COLOR_RAM+$200,x
        sta COLOR_RAM+$2e8,x
        inx
        bne .clr

        ; --- 1. LOGO MAJESTUEUX "THE LEGEND OF ZELDA" ---
        ; "THE  LEGEND  OF" (Ligne 1, col 13)
        ldx #0
.tlo:
        lda txt_title_legend,x
        beq +
        sta SCREEN_RAM+40+13,x
        lda #COL_WHITE
        sta COLOR_RAM+40+13,x
        inx
        bne .tlo
+
        ; Grand logo 16x16 doré "Z E L D A" (Lignes 2..3, cols 13..27)
        ldx #0
.put_logo:
        lda zelda_logo_top,x
        beq +
        sta SCREEN_RAM+80+13,x
        lda #COL_YELLOW
        sta COLOR_RAM+80+13,x

        lda zelda_logo_bot,x
        sta SCREEN_RAM+120+13,x
        lda #COL_YELLOW
        sta COLOR_RAM+120+13,x
        inx
        bne .put_logo
+
        ; Grandes Triforces royales dorées encadrant le titre
        lda #156
        sta SCREEN_RAM+80+7
        lda #157
        sta SCREEN_RAM+80+8
        lda #158
        sta SCREEN_RAM+120+7
        lda #159
        sta SCREEN_RAM+120+8

        lda #COL_YELLOW
        sta COLOR_RAM+80+7
        sta COLOR_RAM+80+8
        sta COLOR_RAM+120+7
        sta COLOR_RAM+120+8

        lda #156
        sta SCREEN_RAM+80+31
        lda #157
        sta SCREEN_RAM+80+32
        lda #158
        sta SCREEN_RAM+120+31
        lda #159
        sta SCREEN_RAM+120+32

        lda #COL_YELLOW
        sta COLOR_RAM+80+31
        sta COLOR_RAM+80+32
        sta COLOR_RAM+120+31
        sta COLOR_RAM+120+32

        ; Ligne de filet d'or sous le logo (Ligne 4, cols 6..33)
        ldx #0
.sep_gold:
        lda #115
        sta SCREEN_RAM+160+6,x
        lda #COL_YELLOW
        sta COLOR_RAM+160+6,x
        inx
        cpx #28
        bne .sep_gold

        ; --- 2. FALAISES ÉTAGÉES ET FORETS DE DEATH MOUNTAIN (Lignes 5..18) ---
        ldx #5
.cliff_loop:
        lda intro_scr_lo,x
        sta ZP_SCR
        lda intro_scr_hi,x
        sta ZP_SCR+1
        lda intro_col_hi,x
        sta ZP_COL+1
        lda ZP_SCR
        sta ZP_COL

        lda cliff_left_width-5,x
        sta ZP_TMP
        lda cliff_right_start-5,x
        sta ZP_ROW

        ; Remplissage rocheux gauche
        ldy #0
.fill_cg:
        lda #128                        ; Pierre texturée
        sta (ZP_SCR),y
        lda #COL_GREY
        sta (ZP_COL),y
        iny
        cpy ZP_TMP
        bne .fill_cg

        ; Biseau gauche éclairé
        lda #130
        sta (ZP_SCR),y
        lda #COL_LGREY
        sta (ZP_COL),y

        ; Biseau droit ombré
        ldy ZP_ROW
        dey
        lda #131
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y
        iny

        ; Remplissage rocheux droit
.fill_cd:
        lda #128
        sta (ZP_SCR),y
        lda #COL_GREY
        sta (ZP_COL),y
        iny
        cpy #40
        bne .fill_cd

        inx
        cpx #19
        bne .cliff_loop

        ; Pins et sapins verts sur les paliers rocheux
        ldx #0
.put_trees:
        lda tree_row_tbl,x
        beq .trees_done
        tay
        lda intro_scr_lo,y
        sta ZP_SCR
        lda intro_scr_hi,y
        sta ZP_SCR+1
        lda intro_col_hi,y
        sta ZP_COL+1
        lda ZP_SCR
        sta ZP_COL

        lda tree_col_tbl,x
        tay
        lda #132                        ; Pin vert
        sta (ZP_SCR),y
        lda #COL_GREEN
        sta (ZP_COL),y

        inx
        bne .put_trees
.trees_done:

        ; --- 3. BASSIN D'EAU EN BAS (Lignes 19..20) ---
        ldx #0
.lake_waves1:
        lda #134                        ; Vagues
        sta SCREEN_RAM+760+6,x
        sta SCREEN_RAM+760+24,x
        lda #COL_BLUE
        sta COLOR_RAM+760+6,x
        sta COLOR_RAM+760+24,x
        inx
        cpx #10
        bne .lake_waves1

        ldx #0
.lake_main:
        lda #134
        sta SCREEN_RAM+800+4,x
        lda #COL_BLUE
        sta COLOR_RAM+800+4,x
        inx
        cpx #32
        bne .lake_main

        ; --- 4. MENTIONS DU BAS (Lignes 22..24) ---
        jsr intro_show_press_text

        ldx #0
.nint:
        lda txt_nintendo,x
        beq +
        sta SCREEN_RAM+960+12,x
        lda #COL_LGREY
        sta COLOR_RAM+960+12,x
        inx
        bne .nint
+
        jsr intro_animate_water
        rts

; Données du logo 16x16 Z E L D A
zelda_logo_top:
        !byte 136, 137, 32, 140, 141, 32, 144, 145, 32, 148, 149, 32, 152, 153, 0

zelda_logo_bot:
        !byte 138, 139, 32, 142, 143, 32, 146, 147, 32, 150, 151, 32, 154, 155, 0

cliff_left_width:
        !byte 11, 12, 13, 14, 15, 15, 16, 16, 16, 16, 17, 17, 17, 17
cliff_right_start:
        !byte 29, 28, 27, 26, 25, 25, 24, 24, 24, 24, 23, 23, 23, 23

tree_row_tbl:
        !byte 5, 5, 8, 8, 12, 12, 0
tree_col_tbl:
        !byte 3, 36, 6, 33, 8, 31, 0

; ---------------------------------------------------------------------------
; intro_animate_water : anime le flux descendant de la cascade (cols 17..22)
; ---------------------------------------------------------------------------
intro_animate_water:
        ldx intro_water_frame
        lda water_char_cycle,x
        sta ZP_TMP

        ldx #5
.wf_line:
        lda intro_scr_lo,x
        sta ZP_SCR
        lda intro_scr_hi,x
        sta ZP_SCR+1
        lda intro_col_hi,x
        sta ZP_COL+1
        lda ZP_SCR
        sta ZP_COL

        ldy #17
.wf_col:
        lda ZP_TMP
        sta (ZP_SCR),y
        lda #COL_LBLUE
        sta (ZP_COL),y
        iny
        cpy #23
        bne .wf_col

        inx
        cpx #19
        bne .wf_line

        ldy #16
.foam:
        lda #CHAR_WATER_FOAM
        sta SCREEN_RAM+760,y
        lda #COL_WHITE
        sta COLOR_RAM+760,y
        iny
        cpy #24
        bne .foam
        rts

water_char_cycle:
        !byte CHAR_WATER_0, CHAR_WATER_1, CHAR_WATER_2

intro_show_press_text:
        ldx #0
.spt:
        lda txt_press_button,x
        beq +
        sta SCREEN_RAM+880+11,x
        lda #COL_YELLOW
        sta COLOR_RAM+880+11,x
        inx
        bne .spt
+       rts

intro_hide_press_text:
        ldx #0
        lda #32
.hpt:
        sta SCREEN_RAM+880+11,x
        inx
        cpx #18
        bne .hpt
        rts

; ---------------------------------------------------------------------------
; FONDU EN NOIR DOUX ET AUTHENTIQUE (PALETTE FADE OUT)
; ---------------------------------------------------------------------------
intro_fade_step:
        ldx #0
.fade_l:
        lda COLOR_RAM,x
        and #$0f
        tay
        lda color_fade_table,y
        sta COLOR_RAM,x

        lda COLOR_RAM+$100,x
        and #$0f
        tay
        lda color_fade_table,y
        sta COLOR_RAM+$100,x

        lda COLOR_RAM+$200,x
        and #$0f
        tay
        lda color_fade_table,y
        sta COLOR_RAM+$200,x

        lda COLOR_RAM+$2e8,x
        and #$0f
        tay
        lda color_fade_table,y
        sta COLOR_RAM+$2e8,x

        inx
        bne .fade_l
        rts

color_fade_table:
        !byte COL_BLACK         ; 0: Noir -> Noir
        !byte COL_LGREY         ; 1: Blanc -> Gris clair
        !byte COL_BROWN         ; 2: Rouge -> Marron
        !byte COL_LBLUE         ; 3: Cyan -> Bleu clair
        !byte COL_BLACK         ; 4: Violet -> Noir
        !byte COL_DGREY         ; 5: Vert -> Gris foncé
        !byte COL_BLACK         ; 6: Bleu -> Noir
        !byte COL_ORANGE        ; 7: Jaune -> Orange
        !byte COL_BROWN         ; 8: Orange -> Marron
        !byte COL_BLACK         ; 9: Marron -> Noir
        !byte COL_RED           ; 10: Rouge clair -> Rouge
        !byte COL_BLACK         ; 11: Gris foncé -> Noir
        !byte COL_DGREY         ; 12: Gris moyen -> Gris foncé
        !byte COL_GREEN         ; 13: Vert clair -> Vert
        !byte COL_BLUE          ; 14: Bleu clair -> Bleu
        !byte COL_GREY          ; 15: Gris clair -> Gris moyen

intro_clear_scroll_area:
        lda #COL_BLACK
        sta VIC_BACKGROUND
        sta VIC_BORDER
        ldx #0
.clra:
        lda #32
        sta SCREEN_RAM,x
        sta SCREEN_RAM+$100,x
        sta SCREEN_RAM+$200,x
        sta SCREEN_RAM+$2e8,x
        lda #COL_BLACK
        sta COLOR_RAM,x
        sta COLOR_RAM+$100,x
        sta COLOR_RAM+$200,x
        sta COLOR_RAM+$2e8,x
        inx
        bne .clra
        rts

; ---------------------------------------------------------------------------
; DESSIN DU CADRE DU PARCHEMIN ROYAL
; ---------------------------------------------------------------------------
intro_draw_parchment_frame:
        ; Haut du rouleau (Ligne 1)
        lda #160
        sta SCREEN_RAM+40+3
        lda #COL_YELLOW
        sta COLOR_RAM+40+3

        ldx #0
.roll_top:
        lda #161
        sta SCREEN_RAM+40+4,x
        lda #COL_YELLOW
        sta COLOR_RAM+40+4,x
        inx
        cpx #32
        bne .roll_top

        lda #162
        sta SCREEN_RAM+40+36
        lda #COL_YELLOW
        sta COLOR_RAM+40+36

        ; Bords déroulés gauche et droite (Lignes 2..21)
        ldx #2
.roll_sides:
        lda intro_scr_lo,x
        sta ZP_SCR
        lda intro_scr_hi,x
        sta ZP_SCR+1
        lda intro_col_hi,x
        sta ZP_COL+1
        lda ZP_SCR
        sta ZP_COL

        ldy #3
        lda #163
        sta (ZP_SCR),y
        lda #COL_YELLOW
        sta (ZP_COL),y

        ldy #36
        lda #164
        sta (ZP_SCR),y
        lda #COL_YELLOW
        sta (ZP_COL),y

        cpx #4
        bcc +
        cpx #21
        bcs +
        ldy #4
.init_col_white:
        lda #COL_WHITE
        sta (ZP_COL),y
        iny
        cpy #36
        bne .init_col_white
+
        inx
        cpx #22
        bne .roll_sides

        ; Bas du rouleau (Ligne 22)
        lda #165
        sta SCREEN_RAM+880+3
        lda #COL_YELLOW
        sta COLOR_RAM+880+3

        ldx #0
.roll_bot:
        lda #166
        sta SCREEN_RAM+880+4,x
        lda #COL_YELLOW
        sta COLOR_RAM+880+4,x
        inx
        cpx #32
        bne .roll_bot

        lda #167
        sta SCREEN_RAM+880+36
        lda #COL_YELLOW
        sta COLOR_RAM+880+36
        rts

intro_show_press_text_parchment:
        ldx #0
.spp:
        lda txt_press_button,x
        beq +
        sta SCREEN_RAM+960+11,x
        lda #COL_YELLOW
        sta COLOR_RAM+960+11,x
        inx
        bne .spp
+       rts

intro_hide_press_text_parchment:
        ldx #0
        lda #32
.hpp:
        sta SCREEN_RAM+960+11,x
        inx
        cpx #18
        bne .hpp
        rts

; ---------------------------------------------------------------------------
; DESSIN DE L'HISTOIRE D'HYRULE
; ---------------------------------------------------------------------------
intro_draw_story_bg:
        jsr intro_clear_scroll_area
        jsr intro_draw_parchment_frame

        ldx #0
.ttl:
        lda txt_story_title,x
        beq +
        sta SCREEN_RAM+80+10,x
        lda #COL_YELLOW
        sta COLOR_RAM+80+10,x
        inx
        bne .ttl
+
        ldx #0
.sep2:
        lda #115
        sta SCREEN_RAM+120+10,x
        lda #COL_YELLOW
        sta COLOR_RAM+120+10,x
        inx
        cpx #20
        bne .sep2

        jsr intro_show_press_text_parchment
        rts

intro_scroll_story_step:
        ; Décale vers le haut les lignes de texte (lignes 4..20, cols 5..34)
        ldx #4
.scroll_up:
        lda intro_scr_lo,x
        sta ZP_DST
        lda intro_scr_hi,x
        sta ZP_DST+1

        inx
        lda intro_scr_lo,x
        sta ZP_SRC
        lda intro_scr_hi,x
        sta ZP_SRC+1

        ldy #5
.shift_line:
        lda (ZP_SRC),y
        sta (ZP_DST),y
        iny
        cpy #35
        bne .shift_line

        cpx #20
        bne .scroll_up

        ; Injecte la nouvelle ligne sur la ligne 20
        lda intro_scroll_line
        cmp #story_line_count
        bcs .blank_line

        asl
        tax
        lda story_ptrs,x
        sta ZP_SRC
        lda story_ptrs+1,x
        sta ZP_SRC+1

        ldy #5
        lda #32
.clr20:
        sta SCREEN_RAM+800,y
        iny
        cpy #35
        bne .clr20

        ldy #0
.put_line:
        lda (ZP_SRC),y
        beq .line_done
        sta SCREEN_RAM+800+5,y
        lda #COL_WHITE
        sta COLOR_RAM+800+5,y
        iny
        cpy #30
        bne .put_line
.line_done:
        rts

.blank_line:
        ldy #5
        lda #32
.clrb:  sta SCREEN_RAM+800,y
        iny
        cpy #35
        bne .clrb
        rts

; ---------------------------------------------------------------------------
; DESSIN ET DEFILEMENT DES TRESORS (ALL OF TREASURES)
; ---------------------------------------------------------------------------
intro_draw_treasures_bg:
        jsr intro_clear_scroll_area
        jsr intro_draw_parchment_frame

        ldx #0
.ttltr:
        lda txt_treasures_title,x
        beq +
        sta SCREEN_RAM+80+12,x
        lda #COL_YELLOW
        sta COLOR_RAM+80+12,x
        inx
        bne .ttltr
+
        ldx #0
.sep3:
        lda #115
        sta SCREEN_RAM+120+10,x
        lda #COL_YELLOW
        sta COLOR_RAM+120+10,x
        inx
        cpx #20
        bne .sep3

        jsr intro_show_press_text_parchment
        rts

intro_scroll_treasure_step:
        ldx #4
.scroll_tr_up:
        lda intro_scr_lo,x
        sta ZP_DST
        lda intro_scr_hi,x
        sta ZP_DST+1

        inx
        lda intro_scr_lo,x
        sta ZP_SRC
        lda intro_scr_hi,x
        sta ZP_SRC+1

        ldy #5
.shift_tr:
        lda (ZP_SRC),y
        sta (ZP_DST),y
        iny
        cpy #35
        bne .shift_tr

        cpx #20
        bne .scroll_tr_up

        ; Injecte le trésor sur la ligne 20
        lda intro_scroll_line
        cmp #treasure_count
        bcs .tr_blank

        tax
        lda treasure_icons,x
        sta ZP_TMP
        lda treasure_colors,x
        sta ZP_ROW

        txa
        asl
        tax
        lda treasure_ptrs,x
        sta ZP_SRC
        lda treasure_ptrs+1,x
        sta ZP_SRC+1

        ldy #5
        lda #32
.clr_tr20:
        sta SCREEN_RAM+800,y
        iny
        cpy #35
        bne .clr_tr20

        ; Dessine l'icône de l'objet à la colonne 6
        lda ZP_TMP
        sta SCREEN_RAM+800+6
        lda ZP_ROW
        sta COLOR_RAM+800+6

        ; Tiret à la colonne 8
        lda #'-'
        sta SCREEN_RAM+800+8
        lda #COL_GREY
        sta COLOR_RAM+800+8

        ; Nom de l'objet à partir de la colonne 10
        ldy #0
.put_tr:
        lda (ZP_SRC),y
        beq .tr_done_line
        sta SCREEN_RAM+800+10,y
        lda #COL_WHITE
        sta COLOR_RAM+800+10,y
        iny
        cpy #24
        bne .put_tr
.tr_done_line:
        rts

.tr_blank:
        ldy #5
        lda #32
.clrtb: sta SCREEN_RAM+800,y
        iny
        cpy #35
        bne .clrtb
        rts

; ---------------------------------------------------------------------------
; DESSIN ET DEFILE DES MONSTRES D'HYRULE
; ---------------------------------------------------------------------------
intro_draw_monsters_bg:
        jsr intro_clear_scroll_area
        jsr intro_draw_parchment_frame

        ; Titre centré
        ldx #0
.ttl_mon:
        lda txt_monsters_title,x
        beq +
        sta SCREEN_RAM+80+11,x
        lda #COL_YELLOW
        sta COLOR_RAM+80+11,x
        inx
        bne .ttl_mon
+
        ldx #0
.sep:
        lda #115
        sta SCREEN_RAM+120+10,x
        lda #COL_YELLOW
        sta COLOR_RAM+120+10,x
        inx
        cpx #20
        bne .sep

        lda #0
        sta intro_mon_idx
        sta intro_mon_frame
        sta intro_mon_tick
        sta intro_mon_anim_tick

        jsr intro_display_current_monster
        jsr intro_show_press_text_parchment
        rts

intro_display_current_monster:
        ; 1. Nettoie les lignes de texte du monstre (lignes 5, 14, 16)
        ldy #4
        lda #32
.clrm_l5:
        sta SCREEN_RAM+200,y
        iny
        cpy #36
        bne .clrm_l5

        ldy #4
.clrm_l14:
        sta SCREEN_RAM+560,y
        iny
        cpy #36
        bne .clrm_l14

        ldy #4
.clrm_l16:
        sta SCREEN_RAM+640,y
        iny
        cpy #36
        bne .clrm_l16

        ; 2. Affiche "MONSTER [XX / 15]" à la ligne 5, col 12
        ldx intro_mon_idx
        txa
        asl
        tax
        lda intro_mon_num_ptrs,x
        sta ZP_SRC
        lda intro_mon_num_ptrs+1,x
        sta ZP_SRC+1
        ldy #0
-       lda (ZP_SRC),y
        beq +
        sta SCREEN_RAM+200+12,y
        lda #COL_GREY
        sta COLOR_RAM+200+12,y
        iny
        bne -
+
        ; 3. Affiche le nom du monstre à la ligne 14, centré
        ldx intro_mon_idx
        lda intro_mon_name_offsets,x
        sta ZP_TMP
        txa
        asl
        tax
        lda intro_mon_name_ptrs,x
        sta ZP_SRC
        lda intro_mon_name_ptrs+1,x
        sta ZP_SRC+1
        ldy #0
-       lda (ZP_SRC),y
        beq +
        ldx ZP_TMP
        sta SCREEN_RAM+560,x
        lda #COL_YELLOW
        sta COLOR_RAM+560,x
        inc ZP_TMP
        iny
        bne -
+
        ; 4. Affiche la description / lore à la ligne 16, centré
        ldx intro_mon_idx
        lda intro_mon_lore_offsets,x
        sta ZP_TMP
        txa
        asl
        tax
        lda intro_mon_lore_ptrs,x
        sta ZP_SRC
        lda intro_mon_lore_ptrs+1,x
        sta ZP_SRC+1
        ldy #0
-       lda (ZP_SRC),y
        beq +
        ldx ZP_TMP
        sta SCREEN_RAM+640,x
        lda #COL_WHITE
        sta COLOR_RAM+640,x
        inc ZP_TMP
        iny
        bne -
+

        ; 5. Règle la couleur propre de Sprite 0
        ldx intro_mon_idx
        lda intro_mon_colors,x
        sta VIC_SPRITE_COL0

        ; 6. Copie Frame 0 dans intro_spr_buffer
        lda #0
        sta intro_mon_frame
        jsr intro_copy_monster_sprite_frame

        ; 7. Active et configure Sprite 0
        lda #160
        sta VIC_SPRITE_X0
        lda #108
        sta VIC_SPRITE_Y0
        lda VIC_SPRITE_MSB
        and #%11111110
        sta VIC_SPRITE_MSB
        lda VIC_SPRITE_EXP_X
        ora #%00000001
        sta VIC_SPRITE_EXP_X
        lda VIC_SPRITE_EXP_Y
        ora #%00000001
        sta VIC_SPRITE_EXP_Y
        lda VIC_SPRITE_MC
        ora #%00000001
        sta VIC_SPRITE_MC
        lda #COL_LRED
        sta VIC_SPRITE_MC1
        lda #COL_BROWN
        sta VIC_SPRITE_MC2
        lda #intro_spr_block
        sta SPRITE_PTR0
        lda VIC_SPRITE_EN
        ora #%00000001
        sta VIC_SPRITE_EN
        rts

intro_copy_monster_sprite_frame:
        ldx intro_mon_idx
        txa
        asl
        tax
        lda intro_mon_frame
        bne .use_f1
        lda intro_mon_f0_ptrs,x
        sta ZP_SRC
        lda intro_mon_f0_ptrs+1,x
        sta ZP_SRC+1
        jmp .do_copy
.use_f1:
        lda intro_mon_f1_ptrs,x
        sta ZP_SRC
        lda intro_mon_f1_ptrs+1,x
        sta ZP_SRC+1
.do_copy:
        ldy #63
-       lda (ZP_SRC),y
        sta intro_spr_buffer,y
        dey
        bpl -
        rts

; ===========================================================================
; MOTEUR SONORE ET MUSIQUE AUTHENTIQUE DE ZELDA 1 (SID 3 VOIX)
; ===========================================================================
intro_music_init:
        lda #15
        sta SID_VOLUME

        ; Voix 1 : Mélodie Lead puissante (Pulse 50%)
        lda #$00
        sta SID_V1_PW_LO
        lda #$08
        sta SID_V1_PW_HI
        lda #$08
        sta SID_V1_AD
        lda #$c2
        sta SID_V1_SR

        ; Voix 2 : Harmonie & Basse héroïque (Sawtooth)
        lda #$07
        sta SID_V2_AD
        lda #$a2
        sta SID_V2_SR

        ; Voix 3 : Percussion caisse claire militaire (Noise)
        lda #$03
        sta SID_V3_AD
        lda #$00
        sta SID_V3_SR

        lda #0
        sta intro_music_part
        sta intro_music_step
        sta intro_music_delay
        rts

intro_music_stop:
        lda #%01000000
        sta SID_V1_CTRL
        lda #%00100000
        sta SID_V2_CTRL
        lda #%10000000
        sta SID_V3_CTRL
        rts

intro_music_update:
        lda intro_music_delay
        beq .next_note
        dec intro_music_delay
        rts

.next_note:
        lda intro_music_part
        bne .in_part2

        ldx intro_music_step
        cpx #music_p1_len
        bcc .read_p1
        lda #1
        sta intro_music_part
        ldx #0
        stx intro_music_step
        jmp .read_p2

.read_p1:
        lda music_p1_dur,x
        sta intro_music_delay

        lda music_p1_v1_hi,x
        sta music_cur_v1_hi
        lda music_p1_v1_lo,x
        sta music_cur_v1_lo
        lda music_p1_v1_trig,x
        sta music_cur_v1_trig

        lda music_p1_v2_hi,x
        sta music_cur_v2_hi
        lda music_p1_v2_lo,x
        sta music_cur_v2_lo
        lda music_p1_v2_trig,x
        sta music_cur_v2_trig

        lda music_p1_v3_perc,x
        sta music_cur_v3_perc

        inc intro_music_step
        jmp .apply_to_sid

.in_part2:
        ldx intro_music_step
        cpx #music_p2_len
        bcc .read_p2
        lda #0
        sta intro_music_part
        ldx #music_loop_step
        stx intro_music_step
        jmp .read_p1

.read_p2:
        lda music_p2_dur,x
        sta intro_music_delay

        lda music_p2_v1_hi,x
        sta music_cur_v1_hi
        lda music_p2_v1_lo,x
        sta music_cur_v1_lo
        lda music_p2_v1_trig,x
        sta music_cur_v1_trig

        lda music_p2_v2_hi,x
        sta music_cur_v2_hi
        lda music_p2_v2_lo,x
        sta music_cur_v2_lo
        lda music_p2_v2_trig,x
        sta music_cur_v2_trig

        lda music_p2_v3_perc,x
        sta music_cur_v3_perc

        inc intro_music_step

.apply_to_sid:
        lda music_cur_v1_hi
        beq .v1_mute
        sta SID_V1_FREQ_HI
        lda music_cur_v1_lo
        sta SID_V1_FREQ_LO

        lda music_cur_v1_trig
        beq .v1_no_retrigger
        lda #%01000000
        sta SID_V1_CTRL
.v1_no_retrigger:
        lda #%01000001
        sta SID_V1_CTRL
        jmp +
.v1_mute:
        lda #%01000000
        sta SID_V1_CTRL
+

        lda music_cur_v2_hi
        beq .v2_mute
        sta SID_V2_FREQ_HI
        lda music_cur_v2_lo
        sta SID_V2_FREQ_LO

        lda music_cur_v2_trig
        beq .v2_no_retrigger
        lda #%00100000
        sta SID_V2_CTRL
.v2_no_retrigger:
        lda #%00100001
        sta SID_V2_CTRL
        jmp +
.v2_mute:
        lda #%00100000
        sta SID_V2_CTRL
+

        lda music_cur_v3_perc
        beq .v3_mute
        lda #$80
        sta SID_V3_FREQ_LO
        lda #$28
        sta SID_V3_FREQ_HI
        lda #%10000000
        sta SID_V3_CTRL
        lda #%10000001
        sta SID_V3_CTRL
        rts
.v3_mute:
        lda #%10000000
        sta SID_V3_CTRL
        rts

; Inclusion directe des données de partition musicale authentiques
!source "src/intro_music_data.asm"

; Inclusion directe des données de monstres authentiques
!source "src/intro_monsters_data.asm"

; ===========================================================================
; TEXTES ET DONNEES DE L'INTRODUCTION
; ===========================================================================

txt_title_legend:   !text "THE  LEGEND  OF", 0
txt_title_zelda:    !text "Z E L D A", 0
txt_press_button:   !text "PUSH START BUTTON", 0
txt_nintendo:       !text "@ 1986 NINTENDO", 0

txt_story_title:    !text "THE LEGEND OF ZELDA", 0

s_line_01:  !text "", 0
s_line_02:  !text "MANY YEARS AGO PRINCE", 0
s_line_03:  !text "DARKNESS GANNON STOLE", 0
s_line_04:  !text "ONE OF THE TRIFORCE", 0
s_line_05:  !text "WITH POWER.", 0
s_line_06:  !text "", 0
s_line_07:  !text "PRINCESS ZELDA HAD ONE", 0
s_line_08:  !text "OF THE TRIFORCE WITH", 0
s_line_09:  !text "WISDOM.", 0
s_line_10:  !text "", 0
s_line_11:  !text "SHE DIVIDED IT INTO", 0
s_line_12:  !text "8 UNITS TO HIDE IT", 0
s_line_13:  !text "FROM GANNON BEFORE SHE", 0
s_line_14:  !text "WAS CAPTURED.", 0
s_line_15:  !text "", 0
s_line_16:  !text "GO FIND THE 8 UNITS", 0
s_line_17:  !text "LINK TO SAVE HER.", 0
s_line_18:  !text "", 0
s_line_19:  !text "", 0

story_line_count = 19

story_ptrs:
        !word s_line_01, s_line_02, s_line_03, s_line_04, s_line_05
        !word s_line_06, s_line_07, s_line_08, s_line_09, s_line_10
        !word s_line_11, s_line_12, s_line_13, s_line_14, s_line_15
        !word s_line_16, s_line_17, s_line_18, s_line_19

txt_treasures_title: !text "ALL OF TREASURES", 0

t_name_01:  !text "TRIFORCE OF WISDOM", 0
t_name_02:  !text "SWORD", 0
t_name_03:  !text "WHITE SWORD", 0
t_name_04:  !text "MAGICAL SWORD", 0
t_name_05:  !text "MAGICAL SHIELD", 0
t_name_06:  !text "BOOMERANG", 0
t_name_07:  !text "MAGICAL BOOMERANG", 0
t_name_08:  !text "BOMB", 0
t_name_09:  !text "BOW", 0
t_name_10:  !text "ARROW", 0
t_name_11:  !text "SILVER ARROW", 0
t_name_12:  !text "BLUE CANDLE", 0
t_name_13:  !text "RED CANDLE", 0
t_name_14:  !text "BLUE RING", 0
t_name_15:  !text "RED RING", 0
t_name_16:  !text "POWER BRACELET", 0
t_name_17:  !text "RECORDER", 0
t_name_18:  !text "RAFT", 0
t_name_19:  !text "STEPLADDER", 0
t_name_20:  !text "MAGICAL ROD", 0
t_name_21:  !text "BOOK OF MAGIC", 0
t_name_22:  !text "KEY", 0
t_name_23:  !text "MAGICAL KEY", 0
t_name_24:  !text "MAP", 0
t_name_25:  !text "COMPASS", 0
t_name_26:  !text "HEART", 0
t_name_27:  !text "HEART CONTAINER", 0
t_name_28:  !text "FAIRY", 0
t_name_29:  !text "CLOCK", 0
t_name_30:  !text "RUPY", 0
t_name_31:  !text "LIFE POTION", 0
t_name_32:  !text "2ND POTION", 0
t_name_33:  !text "FOOD", 0
t_name_34:  !text "LETTER", 0

treasure_count = 34

treasure_icons:
        !byte CHAR_TRIFORCE, CHAR_SWORD, CHAR_SWORD, CHAR_SWORD, CHAR_SHIELD
        !byte CHAR_BOOMERANG, CHAR_BOOMERANG, CHAR_BOMB, CHAR_BOW, CHAR_ARROW
        !byte CHAR_ARROW, CHAR_CANDLE, CHAR_CANDLE, CHAR_RING, CHAR_RING
        !byte CHAR_BRACELET, CHAR_FLUTE, CHAR_RAFT, CHAR_LADDER, CHAR_ROD
        !byte CHAR_BOOK, CHAR_KEY, CHAR_KEY, CHAR_MAP, CHAR_COMPASS
        !byte CHAR_HEART, CHAR_HEART_CONT, CHAR_FAIRY, CHAR_CLOCK, CHAR_RUPEE
        !byte CHAR_POTION, CHAR_POTION, CHAR_FOOD, CHAR_LETTER

treasure_colors:
        !byte COL_YELLOW, COL_BROWN, COL_WHITE, COL_CYAN, COL_RED
        !byte COL_YELLOW, COL_CYAN, COL_CYAN, COL_BROWN, COL_BROWN
        !byte COL_CYAN, COL_CYAN, COL_RED, COL_CYAN, COL_RED
        !byte COL_ORANGE, COL_CYAN, COL_BROWN, COL_GREY, COL_CYAN
        !byte COL_ORANGE, COL_GREY, COL_YELLOW, COL_YELLOW, COL_CYAN
        !byte COL_RED, COL_RED, COL_WHITE, COL_YELLOW, COL_YELLOW
        !byte COL_CYAN, COL_RED, COL_BROWN, COL_WHITE

treasure_ptrs:
        !word t_name_01, t_name_02, t_name_03, t_name_04, t_name_05
        !word t_name_06, t_name_07, t_name_08, t_name_09, t_name_10
        !word t_name_11, t_name_12, t_name_13, t_name_14, t_name_15
        !word t_name_16, t_name_17, t_name_18, t_name_19, t_name_20
        !word t_name_21, t_name_22, t_name_23, t_name_24, t_name_25
        !word t_name_26, t_name_27, t_name_28, t_name_29, t_name_30
        !word t_name_31, t_name_32, t_name_33, t_name_34

txt_monsters_title: !text "MONSTERS OF HYRULE", 0
