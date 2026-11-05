; ===========================================================================
; intro.asm : Introduction fidele 1:1 de The Legend of Zelda (NES 1986)
; Comprend :
;   1. Ecran Titre & Grand Blason NES "THE LEGEND OF ZELDA"
;      - 109 tuiles authentiques NES restaurees pixel par pixel
;      - Cascade animee centrale avec flux descendant et rides d'eau
;      - Sprites de vagues animant la chute d'eau a 50 fps
;      - Cycle de couleurs complet et authentique (Jour -> Crepuscule -> Nuit)
;   2. Parchemin officiel du prologue (Story Scroll)
;      - Cadre orne et defilement de bas en haut
;      - Link brandissant la Triforce d'Or au centre de l'ecran !
;   3. Defile officiel des tresors (All of Treasures)
;      - Presentation sur 2 colonnes avec icones et noms originaux
;   4. Defile des monstres d'Hyrule (Monsters of Hyrule)
;      - 15 monstres officiels avec sprites animes 2x et lore
;   5. Musique authentique 3 Voix SID de Koji Kondo sans interruption
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
intro_wave_y1:       !byte 114
intro_wave_y2:       !byte 142
intro_blink_timer:   !byte 0
intro_scroll_line:   !byte 0
intro_scroll_tick:   !byte 0
intro_fade_step_idx: !byte 0
intro_fade_tick:     !byte 0
intro_music_part:    !byte 0
intro_music_step:    !byte 0
intro_music_delay:   !byte 0

; Variables du cycle jour-crepuscule-nuit (16 etapes NES)
intro_pal_step:      !byte 0
intro_pal_timer:     !byte 0
intro_wf_day_timer:  !word 0
intro_text_color:    !byte COL_BLACK

; Variables specifiques au defile des monstres
intro_mon_idx:       !byte 0
intro_mon_frame:     !byte 0
intro_mon_tick:      !byte 0
intro_mon_anim_tick: !byte 0

; Constantes de glyphes graphiques
CHAR_WATER_0    = 128
CHAR_WATER_1    = 129
CHAR_WATER_2    = 130
CHAR_WATER_CREST= 131
CHAR_WATER_FOAM = 132
CHAR_LAKE_WAVE  = 133
CHAR_CLIFF_FACE = 134
CHAR_CLIFF_EDG_L= 135
CHAR_CLIFF_EDG_R= 136
CHAR_TREE_TOP   = 137
CHAR_STAR_DOT   = 138
CHAR_COPYRIGHT  = 139

CHAR_TRIFORCE   = 116
CHAR_SWORD      = 117
CHAR_SHIELD     = 118
CHAR_FLUTE      = 119
CHAR_RAFT       = 120
CHAR_LADDER     = 121
CHAR_BRACELET   = 122
CHAR_POTION     = 123
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

!align 63, 0
intro_wave_spr_data:
        !byte 0, 0, 0, 12, 60, 48, 30, 126, 120, 63, 126, 252, 30, 126, 120, 12, 60, 48, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
SPR_BLOCK_WAVE = (intro_wave_spr_data / 64)

!align 63, 0
intro_link_spr_data:
        !byte 0, 170, 0, 2, 170, 128, 10, 170, 160, 42, 170, 168, 170, 170, 170, 0, 255, 0, 3, 255, 192, 1, 85, 64, 5, 85, 80, 15, 255, 240, 3, 255, 192, 5, 85, 80, 21, 85, 84, 21, 85, 84, 15, 255, 240, 21, 85, 84, 5, 0, 80, 15, 0, 240, 15, 0, 240, 63, 195, 252, 0, 0, 0, 0
SPR_BLOCK_LINK = (intro_link_spr_data / 64)

!align 63, 0
intro_spr_buffer:
        !fill 64, 0
SPR_BLOCK_MON = (intro_spr_buffer / 64)

; Tables d'adresses d'ecran et de couleur pour les 25 lignes
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
; intro_init : initialise l'introduction au demarrage
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
        sta intro_pal_step
        sta intro_pal_timer
        sta intro_wf_day_timer
        sta intro_wf_day_timer+1
        lda #COL_BLACK
        sta intro_text_color
        sta intro_mon_idx
        sta intro_mon_frame
        sta intro_mon_tick
        sta intro_mon_anim_tick
        lda #114
        sta intro_wave_y1
        lda #142
        sta intro_wave_y2
        jsr intro_music_init
        jsr intro_draw_waterfall
        rts

; ---------------------------------------------------------------------------
; intro_update : boucle principale appelee chaque frame
; ---------------------------------------------------------------------------
intro_update:
        jsr intro_music_update
        lda btn_a_pressed
        ora btn_x_pressed
        ora btn_b_pressed
        ora joy_pressed
        beq .no_start
        jmp launch_zelda_game

.no_start:
        inc intro_timer
        bne +
        inc intro_timer+1
+       lda intro_phase
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

; --- 1. WATERFALL & TITLE SCREEN ---
.update_waterfall:
        ; Animation des vagues sprites descendantes (2 px par frame)
        lda intro_wave_y1
        clc
        adc #2
        cmp #172
        bcc +
        lda #114
+       sta intro_wave_y1
        sta VIC_SPRITE_Y1
        sta VIC_SPRITE_Y2
        lda #160
        sta VIC_SPRITE_X1
        lda #184
        sta VIC_SPRITE_X2

        lda intro_wave_y2
        clc
        adc #2
        cmp #172
        bcc +
        lda #114
+       sta intro_wave_y2
        sta VIC_SPRITE_Y3
        sta VIC_SPRITE_Y4
        lda #160
        sta VIC_SPRITE_X3
        lda #184
        sta VIC_SPRITE_X4

        ; Animation de l'eau (changement de caractere stream tous les 2 frames)
        inc intro_water_tick
        lda intro_water_tick
        cmp #2
        bcc .wf_blink
        lda #0
        sta intro_water_tick
        inc intro_water_frame
        lda intro_water_frame
        cmp #3
        bcc +
        lda #0
        sta intro_water_frame
+       jsr intro_animate_water

.wf_blink:
        inc intro_blink_timer
        lda intro_blink_timer
        and #%00100000
        beq .hide_text
        jsr intro_show_press_text
        jmp .check_color_cycle
.hide_text:
        jsr intro_hide_press_text

.check_color_cycle:
        ; Gestion du cycle jour -> crepuscule -> nuit (16 etapes)
        lda intro_pal_step
        bne .in_cycle
        ; Etape 0 : Journee ensoleillee pendant environ 6 secondes (320 frames)
        inc intro_wf_day_timer
        bne +
        inc intro_wf_day_timer+1
+       lda intro_wf_day_timer+1
        cmp #1
        bcc .wf_ret
        lda intro_wf_day_timer
        cmp #64                         ; 256 + 64 = 320 frames
        bcc .wf_ret
        inc intro_pal_step
        lda #0
        sta intro_pal_timer
        jmp .apply_pal_step

.in_cycle:
        inc intro_pal_timer
        ldx intro_pal_step
        lda intro_pal_timer
        cmp nes_pal_delays,x
        bcc .wf_ret
        lda #0
        sta intro_pal_timer
        inc intro_pal_step
        lda intro_pal_step
        cmp #16
        bcc .apply_pal_step

        ; Fin du cycle : passage au prologue de l'histoire !
        lda #0
        sta VIC_SPRITE_EN
        lda #INTRO_PHASE_FADE_STORY
        sta intro_phase
        lda #0
        sta intro_fade_step_idx
        sta intro_fade_tick
.wf_ret:
        rts

.apply_pal_step:
        jsr intro_apply_pal_colors
        rts

; --- 2. TRANSITIONS & FADES ---
.update_fade_story:
        inc intro_fade_tick
        lda intro_fade_tick
        cmp #4
        bcc +
        lda #0
        sta intro_fade_tick
        jsr intro_fade_step
        inc intro_fade_step_idx
        lda intro_fade_step_idx
        cmp #4
        bcc +
        lda #INTRO_PHASE_STORY
        sta intro_phase
        lda #0
        sta intro_scroll_line
        sta intro_scroll_tick
        jsr intro_draw_story_bg
+       rts

; --- 3. STORY SCROLL ---
.update_story:
        inc intro_blink_timer
        lda intro_blink_timer
        and #%00100000
        beq +
        jsr intro_show_press_text_parchment
        jmp ++
+       jsr intro_hide_press_text_parchment
++
        lda intro_scroll_line
        cmp #story_line_count
        bcs .story_show_link

        inc intro_scroll_tick
        lda intro_scroll_tick
        cmp #28
        bcc .story_ret
        lda #0
        sta intro_scroll_tick
        jsr intro_scroll_story_step
        inc intro_scroll_line
.story_ret:
        rts

.story_show_link:
        ; Link brandit la Triforce d'Or au centre !
        jsr intro_setup_link_triforce
        inc intro_scroll_tick
        lda intro_scroll_tick
        cmp #130                        ; Pause de 2.6s
        bcc .st_link_ret
        lda #0
        sta VIC_SPRITE_EN
        lda #INTRO_PHASE_FADE_TREAS
        sta intro_phase
        lda #0
        sta intro_fade_step_idx
        sta intro_fade_tick
.st_link_ret:
        rts

.update_fade_treas:
        inc intro_fade_tick
        lda intro_fade_tick
        cmp #4
        bcc +
        lda #0
        sta intro_fade_tick
        jsr intro_fade_step
        inc intro_fade_step_idx
        lda intro_fade_step_idx
        cmp #4
        bcc +
        lda #INTRO_PHASE_TREASURES
        sta intro_phase
        lda #0
        sta intro_scroll_line
        sta intro_scroll_tick
        jsr intro_draw_treasures_bg
+       rts

; --- 5. TREASURES SHOWCASE ---
.update_treasures:
        inc intro_blink_timer
        lda intro_blink_timer
        and #%00100000
        beq +
        jsr intro_show_press_text_parchment
        jmp ++
+       jsr intro_hide_press_text_parchment
++
        lda intro_scroll_line
        cmp #treasure_row_count
        bcs .treasures_hold

        inc intro_scroll_tick
        lda intro_scroll_tick
        cmp #25
        bcc .tr_ret
        lda #0
        sta intro_scroll_tick
        jsr intro_scroll_treasure_step
        inc intro_scroll_line
.tr_ret:
        rts

.treasures_hold:
        inc intro_scroll_tick
        lda intro_scroll_tick
        cmp #100
        bcc +
        lda #INTRO_PHASE_FADE_MONSTERS
        sta intro_phase
        lda #0
        sta intro_fade_step_idx
        sta intro_fade_tick
+       rts

.update_fade_monsters:
        inc intro_fade_tick
        lda intro_fade_tick
        cmp #4
        bcc +
        lda #0
        sta intro_fade_tick
        jsr intro_fade_step
        inc intro_fade_step_idx
        lda intro_fade_step_idx
        cmp #4
        bcc +
        lda #INTRO_PHASE_MONSTERS
        sta intro_phase
        jsr intro_draw_monsters_bg
+       rts

; --- 7. MONSTERS OF HYRULE SHOWCASE ---
.update_monsters:
        inc intro_blink_timer
        lda intro_blink_timer
        and #%00100000
        beq +
        jsr intro_show_press_text_parchment
        jmp ++
+       jsr intro_hide_press_text_parchment
++
        ; Animation de marche frame 0 <-> frame 1
        inc intro_mon_anim_tick
        lda intro_mon_anim_tick
        cmp #14
        bcc +
        lda #0
        sta intro_mon_anim_tick
        lda intro_mon_frame
        eor #1
        sta intro_mon_frame
        jsr intro_copy_monster_sprite_frame
+
        ; Avance vers le monstre suivant
        inc intro_mon_tick
        lda intro_mon_tick
        cmp #140
        bcc .mon_ret
        lda #0
        sta intro_mon_tick
        inc intro_mon_idx
        lda intro_mon_idx
        cmp #15
        bcc .show_next_mon

        ; Tous les monstres ont defile !
        lda #0
        sta VIC_SPRITE_EN
        lda #INTRO_PHASE_FADE_WATER
        sta intro_phase
        lda #0
        sta intro_fade_step_idx
        sta intro_fade_tick
        rts

.show_next_mon:
        jsr intro_display_current_monster
.mon_ret:
        rts

.update_fade_water:
        inc intro_fade_tick
        lda intro_fade_tick
        cmp #4
        bcc +
        lda #0
        sta intro_fade_tick
        jsr intro_fade_step
        inc intro_fade_step_idx
        lda intro_fade_step_idx
        cmp #4
        bcc +
        jsr intro_init
+       rts

; ===========================================================================
; DESSIN DE L'ECRAN TITRE & CASCADE AUTHENTIQUE NES
; ===========================================================================
intro_draw_waterfall:
        lda #COL_ORANGE
        sta VIC_BACKGROUND
        sta VIC_BORDER

        ; Efface l'ecran a 32 (espace) et couleur noir
        ldx #0
.clrwf:
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
        bne .clrwf

        ; --- 1. DESSIN DU GRAND BLASON NES (Lignes 2..13, Cols 9..30) ---
        ; Falaises rangees 0..1 (haut d'ecran au-dessus du blason)
        ldx #0
.sky_cliffs:
        lda intro_scr_lo,x
        sta ZP_SCR
        lda intro_scr_hi,x
        sta ZP_SCR+1
        lda intro_col_hi,x
        sta ZP_COL+1
        lda ZP_SCR
        sta ZP_COL
        ldy #0
-       lda #CHAR_CLIFF_FACE
        sta (ZP_SCR),y
        lda #COL_GREY
        sta (ZP_COL),y
        iny
        cpy #8
        bne -
        lda #CHAR_CLIFF_EDG_L
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y
        ldy #31
        lda #CHAR_CLIFF_EDG_R
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y
        iny
-       lda #CHAR_CLIFF_FACE
        sta (ZP_SCR),y
        lda #COL_GREY
        sta (ZP_COL),y
        iny
        cpy #40
        bne -
        inx
        cpx #2
        bne .sky_cliffs

        lda #<shield_chars_data
        sta ZP_SRC
        lda #>shield_chars_data
        sta ZP_SRC+1

        lda #<shield_colors_data
        sta ZP_DST
        lda #>shield_colors_data
        sta ZP_DST+1

        ldx #0                          ; ligne 0..11 du blason
.sh_row_loop:
        stx ZP_ROW
        txa
        clc
        adc #2                          ; ligne ecran C64 (2..13)
        tay
        lda intro_scr_lo,y
        sta ZP_SCR
        lda intro_scr_hi,y
        sta ZP_SCR+1
        lda intro_col_hi,y
        sta ZP_COL+1
        lda ZP_SCR
        sta ZP_COL

        ; Falaises gauche et droite de la ligne du blason
        ldy #0
-       lda #CHAR_CLIFF_FACE
        sta (ZP_SCR),y
        lda #COL_GREY
        sta (ZP_COL),y
        iny
        cpy #8
        bne -
        lda #CHAR_CLIFF_EDG_L
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y
        ldy #31
        lda #CHAR_CLIFF_EDG_R
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y
        iny
-       lda #CHAR_CLIFF_FACE
        sta (ZP_SCR),y
        lda #COL_GREY
        sta (ZP_COL),y
        iny
        cpy #40
        bne -

        ldy #0                          ; col 0..21 du blason
.sh_col_loop:
        lda (ZP_SRC),y
        beq +
        tax
        tya
        clc
        adc #9                          ; col ecran C64 (9..30)
        tay
        txa
        sta (ZP_SCR),y
        tya
        sec
        sbc #9
        tay
        lda (ZP_DST),y
        tax
        tya
        clc
        adc #9
        tay
        txa
        sta (ZP_COL),y
        tya
        sec
        sbc #9
        tay
+       iny
        cpy #22
        bne .sh_col_loop

        ; Avance pointeurs de 22 octets
        lda ZP_SRC
        clc
        adc #22
        sta ZP_SRC
        bcc +
        inc ZP_SRC+1
+       lda ZP_DST
        clc
        adc #22
        sta ZP_DST
        bcc +
        inc ZP_DST+1
+

        ldx ZP_ROW
        inx
        cpx #12
        beq +
        jmp .sh_row_loop
+

        ; --- 2. FALAISES ROCHEUSES ET FORETS (Lignes 14..20) ---
        ldx #14
.cliff_loop:
        lda intro_scr_lo,x
        sta ZP_SCR
        lda intro_scr_hi,x
        sta ZP_SCR+1
        lda intro_col_hi,x
        sta ZP_COL+1
        lda ZP_SCR
        sta ZP_COL

        lda cliff_left_width-14,x
        sta ZP_TMP

        ; Remplissage rocheux gauche
        ldy #0
.fill_cg:
        lda #CHAR_CLIFF_FACE
        sta (ZP_SCR),y
        lda #COL_GREY
        sta (ZP_COL),y
        iny
        cpy ZP_TMP
        bne .fill_cg

        ; Biseau gauche
        lda #CHAR_CLIFF_EDG_L
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y

        ; Remplissage chute d'eau centrale
.fill_chute:
        iny
        tya
        cmp cliff_right_start-14,x
        beq .chute_done
        lda #CHAR_WATER_0
        cpx #14
        bne +
        lda #CHAR_WATER_CREST
+       sta (ZP_SCR),y
        lda #COL_CYAN
        cpx #14
        bne +
        lda #COL_WHITE
+       sta (ZP_COL),y
        jmp .fill_chute
.chute_done:

        ; Biseau droit
        lda #CHAR_CLIFF_EDG_R
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y

        iny
.fill_cd:
        lda #CHAR_CLIFF_FACE
        sta (ZP_SCR),y
        lda #COL_GREY
        sta (ZP_COL),y
        iny
        cpy #40
        bne .fill_cd

        inx
        cpx #21
        bne .cliff_loop

        ; Pins verts sur les falaises
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
        lda #CHAR_TREE_TOP
        sta (ZP_SCR),y
        lda #COL_GREEN
        sta (ZP_COL),y
        inx
        bne .put_trees
.trees_done:

        ; --- 3. BASSIN D'EAU ET VAGUES (Ligne 21) ---
        ldx #0
.lake_waves:
        lda #CHAR_LAKE_WAVE
        sta SCREEN_RAM+840+4,x
        lda #COL_BLUE
        sta COLOR_RAM+840+4,x
        inx
        cpx #32
        bne .lake_waves

        ; Ecume blanche a la base de la chute (Cols 16..23)
        ldy #16
.foam_base:
        lda #CHAR_WATER_FOAM
        sta SCREEN_RAM+840,y
        lda #COL_WHITE
        sta COLOR_RAM+840,y
        iny
        cpy #24
        bne .foam_base

        ; Mention "PUSH START BUTTON" clignotante
        jsr intro_show_press_text

        ; Mention "(C) 1986 NINTENDO" (Ligne 24)
        ldx #0
.nint:
        lda txt_nintendo,x
        beq +
        sta SCREEN_RAM+960+12,x
        lda #COL_BLACK
        sta COLOR_RAM+960+12,x
        inx
        bne .nint
+

        ; Configuration des 4 sprites de vagues descendantes
        lda #SPR_BLOCK_WAVE
        sta SPRITE_PTR1
        sta SPRITE_PTR2
        sta SPRITE_PTR3
        sta SPRITE_PTR4
        lda #COL_WHITE
        sta VIC_SPRITE_COL1
        sta VIC_SPRITE_COL2
        sta VIC_SPRITE_COL3
        sta VIC_SPRITE_COL4
        lda VIC_SPRITE_EXP_X
        and #%11100001
        sta VIC_SPRITE_EXP_X
        lda VIC_SPRITE_EXP_Y
        and #%11100001
        sta VIC_SPRITE_EXP_Y
        lda VIC_SPRITE_MC
        and #%11100001
        sta VIC_SPRITE_MC
        lda VIC_SPRITE_MSB
        and #%11100001
        sta VIC_SPRITE_MSB
        lda VIC_SPRITE_EN
        ora #%00011110                  ; Active Sprites 1..4
        sta VIC_SPRITE_EN

        jsr intro_animate_water
        rts

; Animation du flux d'eau central dans les cols 17..22
intro_animate_water:
        ldx intro_water_frame
        lda water_char_cycle,x
        sta ZP_TMP

        ldx #14
.wf_anim_line:
        lda intro_scr_lo,x
        sta ZP_SCR
        lda intro_scr_hi,x
        sta ZP_SCR+1
        lda intro_col_hi,x
        sta ZP_COL+1
        lda ZP_SCR
        sta ZP_COL

        ldy #17
.wf_anim_col:
        lda ZP_TMP
        sta (ZP_SCR),y
        lda #COL_CYAN
        sta (ZP_COL),y
        iny
        cpy #23
        bne .wf_anim_col

        inx
        cpx #21
        bne .wf_anim_line
        rts

water_char_cycle: !byte CHAR_WATER_0, CHAR_WATER_1, CHAR_WATER_2

cliff_left_width:  !byte 11, 12, 13, 14, 15, 16, 16
cliff_right_start: !byte 29, 28, 27, 26, 25, 24, 24
tree_row_tbl:      !byte 3, 3, 7, 7, 10, 10, 14, 14, 17, 17, 19, 19, 0
tree_col_tbl:      !byte 3, 36, 5, 34, 2, 37, 3, 36, 6, 33, 8, 31, 0

intro_apply_pal_colors:
        ldx intro_pal_step
        cpx #16
        bcc +
        rts
+       lda pal_bg_colors,x
        sta VIC_BACKGROUND
        cpx #8
        bcc ++
        lda #COL_YELLOW
        sta intro_text_color
        ldy #0
-       lda txt_nintendo,y
        beq ++
        lda #COL_WHITE
        sta COLOR_RAM+960+12,y
        iny
        bne -
++
        lda pal_cliff_colors,x
        sta ZP_TMP                      ; couleur falaise
        lda pal_water_colors,x
        sta ZP_ROW                      ; couleur cascade
        lda pal_tree_colors,x
        sta ZP_COL                      ; couleur pins

        ; Maj couleur vagues sprites
        lda ZP_ROW
        sta VIC_SPRITE_COL1
        sta VIC_SPRITE_COL2
        sta VIC_SPRITE_COL3
        sta VIC_SPRITE_COL4

        ; Maj falaises rangees superieures (0..13)
        ldx #0
.pal_upper_loop:
        lda intro_scr_lo,x
        sta ZP_SCR
        lda intro_col_hi,x
        sta ZP_SCR+1
        ldy #0
-       lda ZP_TMP
        sta (ZP_SCR),y
        iny
        cpy #9
        bne -
        ldy #31
-       lda ZP_TMP
        sta (ZP_SCR),y
        iny
        cpy #40
        bne -
        inx
        cpx #14
        bne .pal_upper_loop

        ; Maj couleurs des lignes 14..20
        ldx #14
.pal_line_loop:
        lda intro_scr_lo,x
        sta ZP_SCR
        lda intro_col_hi,x
        sta ZP_SCR+1

        ; Falaises gauche
        ldy #0
-       lda ZP_TMP
        sta (ZP_SCR),y
        iny
        cpy #17
        bne -
        ; Cascade
-       lda ZP_ROW
        sta (ZP_SCR),y
        iny
        cpy #23
        bne -
        ; Falaises droite
-       lda ZP_TMP
        sta (ZP_SCR),y
        iny
        cpy #40
        bne -
        inx
        cpx #21
        bne .pal_line_loop

        ; Maj vagues lac (ligne 21)
        ldx #0
-       lda ZP_ROW
        sta COLOR_RAM+840+4,x
        inx
        cpx #32
        bne -

        ; Pins verts
        ldx #0
-       lda tree_row_tbl,x
        beq +
        tay
        lda intro_scr_lo,y
        sta ZP_SCR
        lda intro_col_hi,y
        sta ZP_SCR+1
        lda tree_col_tbl,x
        tay
        lda ZP_COL
        sta (ZP_SCR),y
        inx
        bne -

+       rts

nes_pal_delays:
        !byte 8, 8, 6, 5, 4, 3, 2, 2, 2, 192, 6, 4, 192, 3, 4, 4
pal_bg_colors:
        !byte COL_ORANGE, COL_ORANGE, COL_ORANGE, COL_ORANGE, COL_ORANGE
        !byte COL_ORANGE, COL_BROWN,  COL_BROWN,  COL_BLACK,  COL_BLACK
        !byte COL_BLACK,  COL_BLACK,  COL_BLACK,  COL_BLACK,  COL_BLACK, COL_BLACK
pal_cliff_colors:
        !byte COL_GREY,   COL_GREY,   COL_GREY,   COL_GREY,   COL_DGREY
        !byte COL_DGREY,  COL_DGREY,  COL_DGREY,  COL_BLACK,  COL_BLACK
        !byte COL_BLACK,  COL_BLACK,  COL_BLACK,  COL_BLACK,  COL_BLACK, COL_BLACK
pal_water_colors:
        !byte COL_CYAN,   COL_CYAN,   COL_CYAN,  COL_LBLUE, COL_LBLUE
        !byte COL_LBLUE,  COL_CYAN,   COL_CYAN,  COL_CYAN,  COL_LBLUE
        !byte COL_BLUE,   COL_BLACK,  COL_BLACK, COL_BLACK, COL_BLACK, COL_BLACK
pal_tree_colors:
        !byte COL_GREEN,  COL_GREEN,  COL_GREEN, COL_GREEN, COL_GREEN
        !byte COL_DGREY,  COL_DGREY,  COL_BLACK, COL_BLACK, COL_BLACK
        !byte COL_BLACK,  COL_BLACK,  COL_BLACK, COL_BLACK, COL_BLACK, COL_BLACK

intro_show_press_text:
        ldx #0
-       lda txt_press_button,x
        beq +
        sta SCREEN_RAM+880+11,x
        lda intro_text_color
        sta COLOR_RAM+880+11,x
        inx
        bne -
+       rts

intro_hide_press_text:
        ldx #0
        lda #32
-       sta SCREEN_RAM+880+11,x
        inx
        cpx #18
        bne -
        rts

intro_fade_step:
        ldx #0
.fl:    lda COLOR_RAM,x
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
        bne .fl
        rts

color_fade_table:
        !byte COL_BLACK, COL_LGREY, COL_BROWN, COL_LBLUE, COL_BLACK, COL_DGREY, COL_BLACK, COL_ORANGE
        !byte COL_BROWN, COL_BLACK, COL_RED,   COL_BLACK, COL_DGREY, COL_GREEN, COL_BLUE,  COL_GREY

intro_clear_scroll_area:
        lda #COL_BLACK
        sta VIC_BACKGROUND
        sta VIC_BORDER
        ldx #0
.clra:  lda #32
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

intro_draw_parchment_frame:
        ; Haut du rouleau
        lda #160
        sta SCREEN_RAM+40+3
        lda #COL_YELLOW
        sta COLOR_RAM+40+3
        ldx #0
-       lda #161
        sta SCREEN_RAM+40+4,x
        lda #COL_YELLOW
        sta COLOR_RAM+40+4,x
        inx
        cpx #32
        bne -
        lda #162
        sta SCREEN_RAM+40+36
        lda #COL_YELLOW
        sta COLOR_RAM+40+36

        ; Bords déroulés
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
        inx
        cpx #22
        bne .roll_sides

        ; Bas du rouleau
        lda #165
        sta SCREEN_RAM+880+3
        lda #COL_YELLOW
        sta COLOR_RAM+880+3
        ldx #0
-       lda #166
        sta SCREEN_RAM+880+4,x
        lda #COL_YELLOW
        sta COLOR_RAM+880+4,x
        inx
        cpx #32
        bne -
        lda #167
        sta SCREEN_RAM+880+36
        lda #COL_YELLOW
        sta COLOR_RAM+880+36
        rts

intro_show_press_text_parchment:
        ldx #0
-       lda txt_press_button,x
        beq +
        sta SCREEN_RAM+960+11,x
        lda #COL_YELLOW
        sta COLOR_RAM+960+11,x
        inx
        bne -
+       rts

intro_hide_press_text_parchment:
        ldx #0
        lda #32
-       sta SCREEN_RAM+960+11,x
        inx
        cpx #18
        bne -
        rts

intro_draw_story_bg:
        jsr intro_clear_scroll_area
        jsr intro_draw_parchment_frame
        ldx #0
-       lda txt_story_title,x
        beq +
        sta SCREEN_RAM+80+10,x
        lda #COL_YELLOW
        sta COLOR_RAM+80+10,x
        inx
        bne -
+       ldx #0
-       lda #115
        sta SCREEN_RAM+120+10,x
        lda #COL_YELLOW
        sta COLOR_RAM+120+10,x
        inx
        cpx #20
        bne -
        jsr intro_show_press_text_parchment
        rts

intro_scroll_story_step:
        ldx #4
.st_up: lda intro_scr_lo,x
        sta ZP_DST
        lda intro_scr_hi,x
        sta ZP_DST+1
        lda intro_col_hi,x
        sta ZP_COL+1
        lda ZP_DST
        sta ZP_COL

        inx
        lda intro_scr_lo,x
        sta ZP_SRC
        lda intro_scr_hi,x
        sta ZP_SRC+1
        lda intro_col_hi,x
        sta ZP_MAP+1
        lda ZP_SRC
        sta ZP_MAP

        ldy #5
-       lda (ZP_SRC),y
        sta (ZP_DST),y
        lda (ZP_MAP),y
        sta (ZP_COL),y
        iny
        cpy #35
        bne -
        cpx #20
        bne .st_up

        ; Efface ligne 20
        ldy #5
        lda #32
-       sta SCREEN_RAM+800,y
        lda #COL_BLACK
        sta COLOR_RAM+800,y
        iny
        cpy #35
        bne -

        ; Injecte la nouvelle ligne
        lda intro_scroll_line
        cmp #story_line_count
        bcs +
        asl
        tax
        lda story_ptrs,x
        sta ZP_SRC
        lda story_ptrs+1,x
        sta ZP_SRC+1
        ldy #0
-       lda (ZP_SRC),y
        beq +
        sta SCREEN_RAM+800+5,y
        lda #COL_WHITE
        sta COLOR_RAM+800+5,y
        iny
        cpy #30
        bne -
+       rts

intro_setup_link_triforce:
        ; Nettoie le texte sous Link pour le laisser seul et majestueux au centre
        ldx #4
.clr_st_link:
        lda intro_scr_lo,x
        sta ZP_SCR
        lda intro_scr_hi,x
        sta ZP_SCR+1
        ldy #5
        lda #32
-       sta (ZP_SCR),y
        iny
        cpy #35
        bne -
        inx
        cpx #20
        bne .clr_st_link

        lda #SPR_BLOCK_LINK
        sta SPRITE_PTR0
        lda #160
        sta VIC_SPRITE_X0
        lda #135
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
        lda #COL_GREEN
        sta VIC_SPRITE_MC1
        lda #COL_BROWN
        sta VIC_SPRITE_MC2
        lda #COL_YELLOW
        sta VIC_SPRITE_COL0
        lda VIC_SPRITE_EN
        ora #%00000001
        sta VIC_SPRITE_EN
        rts

intro_draw_treasures_bg:
        jsr intro_clear_scroll_area
        jsr intro_draw_parchment_frame
        ldx #0
-       lda txt_treasures_title,x
        beq +
        sta SCREEN_RAM+80+12,x
        lda #COL_YELLOW
        sta COLOR_RAM+80+12,x
        inx
        bne -
+       ldx #0
-       lda #115
        sta SCREEN_RAM+120+10,x
        lda #COL_YELLOW
        sta COLOR_RAM+120+10,x
        inx
        cpx #20
        bne -
        jsr intro_show_press_text_parchment
        rts

intro_scroll_treasure_step:
        ldx #4
.tr_up: lda intro_scr_lo,x
        sta ZP_DST
        lda intro_scr_hi,x
        sta ZP_DST+1
        lda intro_col_hi,x
        sta ZP_COL+1
        lda ZP_DST
        sta ZP_COL

        inx
        lda intro_scr_lo,x
        sta ZP_SRC
        lda intro_scr_hi,x
        sta ZP_SRC+1
        lda intro_col_hi,x
        sta ZP_MAP+1
        lda ZP_SRC
        sta ZP_MAP

        ldy #5
-       lda (ZP_SRC),y
        sta (ZP_DST),y
        lda (ZP_MAP),y
        sta (ZP_COL),y
        iny
        cpy #35
        bne -
        cpx #20
        bne .tr_up

        ; Efface ligne 20
        ldy #5
        lda #32
-       sta SCREEN_RAM+800,y
        lda #COL_BLACK
        sta COLOR_RAM+800,y
        iny
        cpy #35
        bne -

        ; Injecte les 2 tresors
        lda intro_scroll_line
        cmp #treasure_row_count
        bcs .tr_step_done

        tax
        ; Colonne Gauche (Icone col 6, Nom col 8)
        lda tr_l_icons,x
        sta SCREEN_RAM+800+6
        lda tr_l_colors,x
        sta COLOR_RAM+800+6

        txa
        asl
        tay
        lda tr_l_ptrs,y
        sta ZP_SRC
        lda tr_l_ptrs+1,y
        sta ZP_SRC+1

        ldy #0
-       lda (ZP_SRC),y
        beq +
        sta SCREEN_RAM+800+8,y
        lda #COL_WHITE
        sta COLOR_RAM+800+8,y
        iny
        cpy #13
        bne -
+

        ; Colonne Droite (Icone col 22, Nom col 24)
        ldx intro_scroll_line
        lda tr_r_icons,x
        beq .tr_step_done
        sta SCREEN_RAM+800+22
        lda tr_r_colors,x
        sta COLOR_RAM+800+22

        txa
        asl
        tay
        lda tr_r_ptrs,y
        sta ZP_SRC
        lda tr_r_ptrs+1,y
        sta ZP_SRC+1

        ldy #0
-       lda (ZP_SRC),y
        beq +
        sta SCREEN_RAM+800+24,y
        lda #COL_WHITE
        sta COLOR_RAM+800+24,y
        iny
        cpy #12
        bne -
+
.tr_step_done:
        rts

intro_draw_monsters_bg:
        jsr intro_clear_scroll_area
        jsr intro_draw_parchment_frame
        ldx #0
-       lda txt_monsters_title,x
        beq +
        sta SCREEN_RAM+80+11,x
        lda #COL_YELLOW
        sta COLOR_RAM+80+11,x
        inx
        bne -
+       ldx #0
-       lda #115
        sta SCREEN_RAM+120+10,x
        lda #COL_YELLOW
        sta COLOR_RAM+120+10,x
        inx
        cpx #20
        bne -
        lda #0
        sta intro_mon_idx
        sta intro_mon_frame
        sta intro_mon_tick
        sta intro_mon_anim_tick
        jsr intro_display_current_monster
        jsr intro_show_press_text_parchment
        rts

intro_display_current_monster:
        ; Nettoie lignes 5, 14, 16
        ldy #4
        lda #32
-       sta SCREEN_RAM+200,y
        sta SCREEN_RAM+560,y
        sta SCREEN_RAM+640,y
        iny
        cpy #36
        bne -

        ; "MONSTER [XX / 15]" a la ligne 5
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

        ; Nom du monstre a la ligne 14
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

        ; Lore du monstre a la ligne 16
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

        ; Regle couleur sprite
        ldx intro_mon_idx
        lda intro_mon_colors,x
        sta VIC_SPRITE_COL0

        ; Copie frame 0
        lda #0
        sta intro_mon_frame
        jsr intro_copy_monster_sprite_frame

        ; Active Sprite 0 (2x multicolor)
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
        lda #SPR_BLOCK_MON
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
        bne .mon_f1
        lda intro_mon_f0_ptrs,x
        sta ZP_SRC
        lda intro_mon_f0_ptrs+1,x
        sta ZP_SRC+1
        jmp .do_cpy
.mon_f1:
        lda intro_mon_f1_ptrs,x
        sta ZP_SRC
        lda intro_mon_f1_ptrs+1,x
        sta ZP_SRC+1
.do_cpy:
        ldy #63
-       lda (ZP_SRC),y
        sta intro_spr_buffer,y
        dey
        bpl -
        rts

; ===========================================================================
; MOTEUR SONORE ET MUSIQUE AUTHENTIQUE DE ZELDA 1 (SID 3 VOIX + DUAL SID)
; ===========================================================================
INTRO_SID2_BASE         = $d420
INTRO_SID2_V1_FREQ_LO   = INTRO_SID2_BASE + $00
INTRO_SID2_V1_FREQ_HI   = INTRO_SID2_BASE + $01
INTRO_SID2_V1_PW_LO     = INTRO_SID2_BASE + $02
INTRO_SID2_V1_PW_HI     = INTRO_SID2_BASE + $03
INTRO_SID2_V1_CTRL      = INTRO_SID2_BASE + $04
INTRO_SID2_V1_AD        = INTRO_SID2_BASE + $05
INTRO_SID2_V1_SR        = INTRO_SID2_BASE + $06
INTRO_SID2_V2_FREQ_LO   = INTRO_SID2_BASE + $07
INTRO_SID2_V2_FREQ_HI   = INTRO_SID2_BASE + $08
INTRO_SID2_V2_PW_LO     = INTRO_SID2_BASE + $09
INTRO_SID2_V2_PW_HI     = INTRO_SID2_BASE + $0a
INTRO_SID2_V2_CTRL      = INTRO_SID2_BASE + $0b
INTRO_SID2_V2_AD        = INTRO_SID2_BASE + $0c
INTRO_SID2_V2_SR        = INTRO_SID2_BASE + $0d
INTRO_SID2_V3_FREQ_LO   = INTRO_SID2_BASE + $0e
INTRO_SID2_V3_FREQ_HI   = INTRO_SID2_BASE + $0f
INTRO_SID2_V3_CTRL      = INTRO_SID2_BASE + $12
INTRO_SID2_V3_AD        = INTRO_SID2_BASE + $13
INTRO_SID2_V3_SR        = INTRO_SID2_BASE + $14
INTRO_SID2_VOLUME       = INTRO_SID2_BASE + $18

intro_music_code_start:

intro_music_init:
        lda #15
        sta SID_VOLUME
        lda #$00
        sta SID_V1_PW_LO
        lda #$08
        sta SID_V1_PW_HI
        lda #$08
        sta SID_V1_AD
        lda #$c2
        sta SID_V1_SR
        lda #$07
        sta SID_V2_AD
        lda #$a2
        sta SID_V2_SR
        lda #$03
        sta SID_V3_AD
        lda #$00
        sta SID_V3_SR
        lda #0
        sta intro_music_part
        sta intro_music_step
        sta intro_music_delay

        ; Si Dual SID activé, initialise et relocalise SID 2
        ldy selected_dual_sid
        beq +
        jsr intro_reloc_sid2
        lda #15
        sta INTRO_SID2_VOLUME
        lda #$00
        sta INTRO_SID2_V1_PW_LO
        lda #$08
        sta INTRO_SID2_V1_PW_HI
        lda #$08
        sta INTRO_SID2_V1_AD
        lda #$c2
        sta INTRO_SID2_V1_SR
        lda #$07
        sta INTRO_SID2_V2_AD
        lda #$a2
        sta INTRO_SID2_V2_SR
        lda #$03
        sta INTRO_SID2_V3_AD
        lda #$00
        sta INTRO_SID2_V3_SR
+       rts

intro_music_stop:
        lda #%01000000
        sta SID_V1_CTRL
        lda #%00100000
        sta SID_V2_CTRL
        lda #%10000000
        sta SID_V3_CTRL
        ldy selected_dual_sid
        beq +
        lda #%01000000
        sta INTRO_SID2_V1_CTRL
        lda #%00100000
        sta INTRO_SID2_V2_CTRL
        lda #%10000000
        sta INTRO_SID2_V3_CTRL
+       rts

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
        beq +
        lda #%01000000
        sta SID_V1_CTRL
+       lda #%01000001
        sta SID_V1_CTRL

        ; Dual SID : Voix 1 chorus (+2 detune)
        ldy selected_dual_sid
        beq ++
        lda music_cur_v1_lo
        clc
        adc #2
        sta INTRO_SID2_V1_FREQ_LO
        lda music_cur_v1_hi
        adc #0
        sta INTRO_SID2_V1_FREQ_HI
        lda music_cur_v1_trig
        beq +
        lda #%01000000
        sta INTRO_SID2_V1_CTRL
+       lda #%01000001
        sta INTRO_SID2_V1_CTRL
        jmp ++

.v1_mute:
        lda #%01000000
        sta SID_V1_CTRL
        ldy selected_dual_sid
        beq ++
        sta INTRO_SID2_V1_CTRL
++

        lda music_cur_v2_hi
        beq .v2_mute
        sta SID_V2_FREQ_HI
        lda music_cur_v2_lo
        sta SID_V2_FREQ_LO
        lda music_cur_v2_trig
        beq +
        lda #%00100000
        sta SID_V2_CTRL
+       lda #%00100001
        sta SID_V2_CTRL

        ; Dual SID : Voix 2 detune (+2)
        ldy selected_dual_sid
        beq ++
        lda music_cur_v2_lo
        clc
        adc #2
        sta INTRO_SID2_V2_FREQ_LO
        lda music_cur_v2_hi
        adc #0
        sta INTRO_SID2_V2_FREQ_HI
        lda music_cur_v2_trig
        beq +
        lda #%00100000
        sta INTRO_SID2_V2_CTRL
+       lda #%00100001
        sta INTRO_SID2_V2_CTRL
        jmp ++

.v2_mute:
        lda #%00100000
        sta SID_V2_CTRL
        ldy selected_dual_sid
        beq ++
        sta INTRO_SID2_V2_CTRL
++

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

        ldy selected_dual_sid
        beq +++
        lda #$80
        sta INTRO_SID2_V3_FREQ_LO
        lda #$28
        sta INTRO_SID2_V3_FREQ_HI
        lda #%10000000
        sta INTRO_SID2_V3_CTRL
        lda #%10000001
        sta INTRO_SID2_V3_CTRL
        rts

.v3_mute:
        lda #%10000000
        sta SID_V3_CTRL
        ldy selected_dual_sid
        beq +++
        sta INTRO_SID2_V3_CTRL
+++     rts

; ---------------------------------------------------------------------------
; intro_reloc_sid2 : Relocalise dynamiquement INTRO_SID2 ($D420) vers $D500 ou $DF00
; ---------------------------------------------------------------------------
intro_reloc_sid2:
        ldx selected_sid2_addr_idx
        cpx #3
        bcc +
        ldx #0
+       lda .intro_sid2_lo_tbl,x
        sta .i_reloc_lo
        lda .intro_sid2_hi_tbl,x
        sta .i_reloc_hi

        lda #<intro_music_code_start
        sta ZP_SRC
        lda #>intro_music_code_start
        sta ZP_SRC+1

.i_reloc_loop:
        ldy #2
        lda (ZP_SRC),y
        cmp #$d4
        bne .i_reloc_next
        dey
        lda (ZP_SRC),y
        cmp #$20
        bcc .i_reloc_next
        cmp #$39
        bcs .i_reloc_next

        sec
        sbc #$20
        clc
.i_reloc_lo = * + 1
        adc #$20
        sta (ZP_SRC),y
        iny
.i_reloc_hi = * + 1
        lda #$d4
        sta (ZP_SRC),y

.i_reloc_next:
        inc ZP_SRC
        bne +
        inc ZP_SRC+1
+       lda ZP_SRC
        cmp #<intro_music_code_end
        lda ZP_SRC+1
        sbc #>intro_music_code_end
        bcc .i_reloc_loop
        rts

.intro_sid2_lo_tbl:
        !byte $20, $00, $00
.intro_sid2_hi_tbl:
        !byte $d4, $d5, $df

intro_music_code_end:

music_cur_v1_hi:     !byte 0
music_cur_v1_lo:     !byte 0
music_cur_v1_trig:   !byte 0
music_cur_v2_hi:     !byte 0
music_cur_v2_lo:     !byte 0
music_cur_v2_trig:   !byte 0
music_cur_v3_perc:   !byte 0

!source "src/intro_music_data.asm"
!source "src/intro_monsters_data.asm"

; ===========================================================================
; DONNEES DU GRAND BLASON NES (264 octets caracteres, 264 octets couleurs)
; ===========================================================================
shield_chars_data:
        !byte 243, 241, 242, 241, 242, 241, 242, 241, 242, 241, 242, 241, 242, 241, 242, 241, 242, 241, 242, 241, 242, 243
        !byte 239, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 240
        !byte 240, 32, 32, 141, 142, 143, 144, 145, 146, 147, 148, 149, 149, 149, 150, 151, 32, 32, 32, 32, 32, 239
        !byte 239, 32, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 32, 32, 32, 240
        !byte 240, 32, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 32, 32, 239
        !byte 239, 32, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 32, 240
        !byte 240, 140, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 32, 239
        !byte 239, 32, 32, 32, 32, 32, 32, 32, 221, 222, 223, 224, 225, 32, 32, 32, 32, 32, 32, 32, 32, 240
        !byte 240, 32, 226, 227, 228, 228, 228, 32, 229, 230, 231, 232, 233, 228, 228, 228, 228, 244, 245, 238, 32, 239
        !byte 239, 32, 32, 32, 32, 32, 32, 32, 32, 32, 234, 235, 32, 32, 32, 32, 32, 246, 247, 248, 32, 240
        !byte 240, 32, 32, 32, 32, 32, 32, 32, 32, 32, 236, 237, 32, 32, 32, 32, 32, 32, 32, 32, 32, 239
        !byte 243, 241, 242, 241, 242, 241, 242, 241, 242, 241, 242, 241, 242, 241, 242, 241, 242, 241, 242, 241, 242, 243

shield_colors_data:
        !byte 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5
        !byte 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5
        !byte 5, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 5
        !byte 5, 0, 2, 2, 2, 2, 2, 7, 7, 7, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 5
        !byte 5, 0, 2, 2, 2, 2, 7, 7, 7, 7, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 5
        !byte 5, 0, 2, 2, 2, 2, 7, 7, 7, 7, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 5
        !byte 5, 1, 2, 2, 2, 7, 7, 7, 7, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 5
        !byte 5, 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 5
        !byte 5, 0, 1, 1, 1, 1, 1, 0, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 0, 5
        !byte 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 7, 0, 0, 0, 0, 0, 3, 3, 3, 0, 5
        !byte 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5
        !byte 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5

; ===========================================================================
; TEXTES OFFICIELS DE L'HISTOIRE (NES 1986)
; ===========================================================================
txt_press_button:   !text "PUSH START BUTTON", 0
txt_nintendo:       !byte CHAR_COPYRIGHT : !text " 1986 NINTENDO", 0
txt_story_title:    !text "THE LEGEND OF ZELDA", 0

s_line_00: !text "", 0
s_line_01: !text "MANY YEARS AGO PRINCE", 0
s_line_02: !text "DARKNESS GANNON STOLE", 0
s_line_03: !text "ONE OF THE TRIFORCE WITH", 0
s_line_04: !text "POWER. PRINCESS ZELDA", 0
s_line_05: !text "HAD ONE OF THE TRIFORCE", 0
s_line_06: !text "WITH WISDOM. SHE DIVIDED", 0
s_line_07: !text "IT INTO 8 UNITS TO HIDE", 0
s_line_08: !text "IT FROM GANNON BEFORE", 0
s_line_09: !text "SHE WAS CAPTURED.", 0
s_line_10: !text "", 0
s_line_11: !text "  GO FIND THE 8 UNITS", 0
s_line_12: !text "    LINK TO SAVE HER.", 0
s_line_13: !text "", 0
s_line_14: !text "", 0
s_line_15: !text "", 0
s_line_16: !text "", 0
s_line_17: !text "", 0

story_line_count = 18

story_ptrs:
        !word s_line_00, s_line_01, s_line_02, s_line_03, s_line_04, s_line_05
        !word s_line_06, s_line_07, s_line_08, s_line_09, s_line_10, s_line_11
        !word s_line_12, s_line_13, s_line_14, s_line_15, s_line_16, s_line_17

; ===========================================================================
; DEFILE OFFICIEL DES TRESORS DE ZELDA 1 (2 COLONNES)
; ===========================================================================
txt_treasures_title: !byte CHAR_STAR_DOT, CHAR_STAR_DOT : !text " ALL OF TREASURES " : !byte CHAR_STAR_DOT, CHAR_STAR_DOT, 0

tr_l_name_00: !text "HEART CONT.", 0
tr_r_name_00: !text "HEART", 0
tr_l_name_01: !text "FAIRY", 0
tr_r_name_01: !text "CLOCK", 0
tr_l_name_02: !text "RUPY", 0
tr_r_name_02: !text "5 RUPIES", 0
tr_l_name_03: !text "LIFE POTION", 0
tr_r_name_03: !text "2ND POTION", 0
tr_l_name_04: !text "LETTER", 0
tr_r_name_04: !text "FOOD", 0
tr_l_name_05: !text "SWORD", 0
tr_r_name_05: !text "WHITE SWORD", 0
tr_l_name_06: !text "MAGICAL SWORD", 0
tr_r_name_06: !text "MAG. SHIELD", 0
tr_l_name_07: !text "BOOMERANG", 0
tr_r_name_07: !text "MAG. BOOMER.", 0
tr_l_name_08: !text "BOMB", 0
tr_r_name_08: !text "BOW", 0
tr_l_name_09: !text "ARROW", 0
tr_r_name_09: !text "SILVER ARROW", 0
tr_l_name_10: !text "BLUE CANDLE", 0
tr_r_name_10: !text "RED CANDLE", 0
tr_l_name_11: !text "BLUE RING", 0
tr_r_name_11: !text "RED RING", 0
tr_l_name_12: !text "POWER BRAC.", 0
tr_r_name_12: !text "RECORDER", 0
tr_l_name_13: !text "RAFT", 0
tr_r_name_13: !text "STEPLADDER", 0
tr_l_name_14: !text "MAGICAL ROD", 0
tr_r_name_14: !text "BOOK OF MAGIC", 0
tr_l_name_15: !text "KEY", 0
tr_r_name_15: !text "MAGICAL KEY", 0
tr_l_name_16: !text "MAP", 0
tr_r_name_16: !text "COMPASS", 0
tr_l_name_17: !text "TRIFORCE", 0
tr_r_name_17: !text "OF WISDOM", 0

treasure_row_count = 18

tr_l_icons:
        !byte CHAR_HEART_CONT, CHAR_FAIRY, CHAR_RUPEE, CHAR_POTION, CHAR_LETTER, CHAR_SWORD, CHAR_SWORD, CHAR_BOOMERANG, CHAR_BOMB, CHAR_ARROW, CHAR_CANDLE, CHAR_RING, CHAR_BRACELET, CHAR_RAFT, CHAR_ROD, CHAR_KEY, CHAR_MAP, CHAR_TRIFORCE
tr_l_colors:
        !byte COL_RED, COL_WHITE, COL_YELLOW, COL_CYAN, COL_WHITE, COL_BROWN, COL_CYAN, COL_YELLOW, COL_CYAN, COL_BROWN, COL_CYAN, COL_CYAN, COL_ORANGE, COL_BROWN, COL_CYAN, COL_GREY, COL_YELLOW, COL_YELLOW
tr_l_ptrs:
        !word tr_l_name_00, tr_l_name_01, tr_l_name_02, tr_l_name_03, tr_l_name_04, tr_l_name_05
        !word tr_l_name_06, tr_l_name_07, tr_l_name_08, tr_l_name_09, tr_l_name_10, tr_l_name_11
        !word tr_l_name_12, tr_l_name_13, tr_l_name_14, tr_l_name_15, tr_l_name_16, tr_l_name_17
tr_r_icons:
        !byte CHAR_HEART, CHAR_CLOCK, CHAR_RUPEE, CHAR_POTION, CHAR_FOOD, CHAR_SWORD, CHAR_SHIELD, CHAR_BOOMERANG, CHAR_BOW, CHAR_ARROW, CHAR_CANDLE, CHAR_RING, CHAR_FLUTE, CHAR_LADDER, CHAR_BOOK, CHAR_KEY, CHAR_COMPASS, CHAR_TRIFORCE
tr_r_colors:
        !byte COL_RED, COL_YELLOW, COL_CYAN, COL_RED, COL_BROWN, COL_WHITE, COL_RED, COL_CYAN, COL_BROWN, COL_CYAN, COL_RED, COL_RED, COL_CYAN, COL_GREY, COL_ORANGE, COL_YELLOW, COL_CYAN, COL_YELLOW
tr_r_ptrs:
        !word tr_r_name_00, tr_r_name_01, tr_r_name_02, tr_r_name_03, tr_r_name_04, tr_r_name_05
        !word tr_r_name_06, tr_r_name_07, tr_r_name_08, tr_r_name_09, tr_r_name_10, tr_r_name_11
        !word tr_r_name_12, tr_r_name_13, tr_r_name_14, tr_r_name_15, tr_r_name_16, tr_r_name_17

; ===========================================================================
; TITRE DU DEFILE DES MONSTRES
; ===========================================================================
txt_monsters_title: !byte CHAR_STAR_DOT, CHAR_STAR_DOT : !text " MONSTERS OF HYRULE " : !byte CHAR_STAR_DOT, CHAR_STAR_DOT, 0

