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
intro_sub_timer:     !word 0
intro_water_frame:   !byte 0
intro_water_tick:    !byte 0
intro_wave_y1:       !byte 114
intro_wave_y2:       !byte 142
intro_blink_timer:   !byte 0
intro_scroll_line:   !byte 0
intro_scroll_tick:   !byte 0
intro_fine_scroll_y:    !byte 7
intro_fine_scroll_tick: !byte 0
intro_fade_step_idx: !byte 0
intro_fade_tick:     !byte 0
intro_music_part:    !byte 0
intro_music_step:    !byte 0
intro_music_delay:   !byte 0

; Variables du cycle jour-crepuscule-nuit (16 etapes NES)
intro_pal_step:      !byte 0
intro_pal_timer:     !byte 0
intro_wf_day_timer:  !word 0
intro_text_color:    !byte COL_WHITE

intro_frame_ready:   !byte 0

; Tables des 12 slots de tresors actifs (couvrant toute la hauteur de l ecran)
treas_active:        !fill 12, 0
treas_y:             !fill 12, 0
treas_spr_l:         !fill 12, 0
treas_col_l:         !fill 12, 0
treas_spr_r:         !fill 12, 0
treas_col_r:         !fill 12, 0
treas_cur_slot:      !byte 0
treas_spr_mask:      !byte 0

; Variables specifiques au defile des monstres
intro_mon_idx:       !byte 0
intro_mon_frame:     !byte 0
intro_mon_tick:      !byte 0
intro_mon_anim_tick: !byte 0
intro_tmp_slot:      !byte 0

MAX_MON_SLOTS        = 6
mon_slot_active:     !fill MAX_MON_SLOTS, 0
mon_slot_y:          !fill MAX_MON_SLOTS, 0
mon_slot_id:         !fill MAX_MON_SLOTS, 0
mon_slot_frame:      !fill MAX_MON_SLOTS, 0

mon_bit_mask:        !byte %00000001, %00000010, %00000100, %00001000, %00010000, %00100000
mon_bit_inv:         !byte %11111110, %11111101, %11111011, %11110111, %11101111, %11011111

mon_buf_lo:
        !byte <(intro_mon_spr_buffers + 0*64), <(intro_mon_spr_buffers + 1*64)
        !byte <(intro_mon_spr_buffers + 2*64), <(intro_mon_spr_buffers + 3*64)
        !byte <(intro_mon_spr_buffers + 4*64), <(intro_mon_spr_buffers + 5*64)
mon_buf_hi:
        !byte >(intro_mon_spr_buffers + 0*64), >(intro_mon_spr_buffers + 1*64)
        !byte >(intro_mon_spr_buffers + 2*64), >(intro_mon_spr_buffers + 3*64)
        !byte >(intro_mon_spr_buffers + 4*64), >(intro_mon_spr_buffers + 5*64)

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

; Glyphes de bordures officielles NES
CHAR_FRAME_TL   = 249
CHAR_FRAME_TR   = 250
CHAR_FRAME_BL   = 251
CHAR_FRAME_BR   = 252
CHAR_FRAME_H    = 253
CHAR_FRAME_V    = 254
CHAR_FRAME_X    = 255

!align 63, 0
intro_wave_spr_data:
        !byte 0, 0, 0, 12, 60, 48, 30, 126, 120, 63, 126, 252, 30, 126, 120, 12, 60, 48, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
SPR_BLOCK_WAVE = (intro_wave_spr_data / 64)
!align 63, 0
intro_glint_spr_data:
        !byte 0, 0, 0, 0, 16, 0, 0, 16, 0, 0, 56, 0, 1, 254, 128, 0, 56, 0, 0, 16, 0, 0, 16, 0, 0, 0, 0
        !fill 37, 0
SPR_BLOCK_GLINT = (intro_glint_spr_data / 64)

!align 63, 0
intro_link_spr_data:
        !byte %00000000, %00000000, %00000000
        !byte %00000000, %00000000, %00000000
        !byte %00000000, %10101010, %00000000
        !byte %00000010, %10101010, %10000000
        !byte %00001010, %10101010, %10100000
        !byte %00001010, %10101010, %10100000
        !byte %00001111, %01010101, %11110000
        !byte %00001101, %11010111, %01110000
        !byte %00000001, %01010101, %01000000
        !byte %00000100, %01010101, %00010000
        !byte %00000110, %10101010, %10010000
        !byte %00000110, %10101010, %10010000
        !byte %00000010, %10101010, %10000000
        !byte %00000011, %11111111, %11000000
        !byte %00000010, %10101010, %10000000
        !byte %00000010, %10101010, %10000000
        !byte %00000011, %11000011, %11000000
        !byte %00000011, %11000011, %11000000
        !byte %00000000, %00000000, %00000000
        !byte %00000000, %00000000, %00000000
        !byte %00000000, %00000000, %00000000
        !byte 0
SPR_BLOCK_LINK = (intro_link_spr_data / 64)
SPR_BLOCK_TRIFORCE = (spr_triforce_triangle / 64)



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

; ===========================================================================
; GESTIONNAIRE D'INTERRUPTION RASTER VIC-II A 2 PHASES (MULTIPLEXEUR 16 SPRITES)
; ===========================================================================

intro_tmp_y: !byte 0
intro_tmp_row: !byte 0
intro_buf_idx: !byte 0
intro_screen_memsetup: !byte $18
intro_spr_bits:
        !byte %00000001, %00000010, %00000100, %00001000
        !byte %00010000, %00100000, %01000000, %10000000

intro_init_raster_irq:
        sei
        lda #$7f
        sta $dc0d                       ; Desactive interruptions timers CIA 1
        lda $dc0d                       ; Ack CIA 1
        lda #%00000001
        sta VIC_IRQ_ENABLE              ; Active interruption raster VIC-II
        lda #250
        sta VIC_RASTER                  ; Premiere phase a raster 250 (VBlank)
        lda VIC_CTRL1
        and #%01111111                  ; Raster bit 8 = 0
        sta VIC_CTRL1

        lda #<irq_intro_bottom
        sta $0314
        lda #>irq_intro_bottom
        sta $0315
        asl VIC_IRQ_FLAG                ; Ack tout flag residuel
        cli
        rts

irq_intro_top:
        lda intro_phase
        cmp #INTRO_PHASE_TREASURES
        bne .top_skip
        lda intro_scroll_line
        cmp #50
        bcs .top_skip
        jsr intro_apply_treas_sprites_p1

.top_skip:
        lda #115
        sta VIC_RASTER
        lda #<irq_intro_mid1
        sta $0314
        lda #>irq_intro_mid1
        sta $0315
        asl VIC_IRQ_FLAG
        jmp $ea81

irq_intro_mid1:
        lda intro_phase
        cmp #INTRO_PHASE_TREASURES
        bne .m1_skip
        lda intro_scroll_line
        cmp #50
        bcs .m1_skip
        jsr intro_apply_treas_sprites_p2

.m1_skip:
        lda #180
        sta VIC_RASTER
        lda #<irq_intro_mid2
        sta $0314
        lda #>irq_intro_mid2
        sta $0315
        asl VIC_IRQ_FLAG
        jmp $ea81

irq_intro_mid2:
        lda intro_phase
        cmp #INTRO_PHASE_TREASURES
        bne .m2_skip
        lda intro_scroll_line
        cmp #50
        bcs .m2_skip
        jsr intro_apply_treas_sprites_p3

.m2_skip:
        lda #250
        sta VIC_RASTER
        lda #<irq_intro_bottom
        sta $0314
        lda #>irq_intro_bottom
        sta $0315
        asl VIC_IRQ_FLAG
        jmp $ea81

irq_intro_bottom:
        inc intro_frame_ready

        lda intro_screen_memsetup
        sta VIC_MEMSETUP

        lda intro_phase
        cmp #INTRO_PHASE_STORY
        beq .apply_scroll_y
        cmp #INTRO_PHASE_TREASURES
        beq .apply_scroll_y
        cmp #INTRO_PHASE_MONSTERS
        beq .apply_scroll_y
        bne .bottom_raster

.apply_scroll_y:
        lda #%00010000                  ; 24 lignes, DEN=1
        ora intro_fine_scroll_y
        sta VIC_CTRL1

.bottom_raster:
        lda #50
        sta VIC_RASTER
        lda #<irq_intro_top
        sta $0314
        lda #>irq_intro_top
        sta $0315
        asl VIC_IRQ_FLAG
        jmp $ea81

; Routine commune d'assignation d'une paire de sprites gauche/droite
intro_set_treas_pair:
        lda treas_spr_l,y
        sta SPRITE_PTR0,x
        sta $0ff8,x
        lda treas_col_l,y
        sta VIC_SPRITE_COL0,x
        lda treas_y,y
        sta intro_tmp_y

        txa
        asl
        tay
        lda #64
        sta VIC_SPRITE_X0,y
        lda intro_tmp_y
        sta VIC_SPRITE_Y0,y

        lda intro_spr_bits,x
        ora treas_spr_mask
        sta treas_spr_mask

        inx                             ; Sprite droit (1, 3, 5, 7)
        ldy treas_cur_slot
        lda treas_spr_r,y
        sta SPRITE_PTR0,x
        sta $0ff8,x
        lda treas_col_r,y
        sta VIC_SPRITE_COL0,x

        txa
        asl
        tay
        lda #192
        sta VIC_SPRITE_X0,y
        lda intro_tmp_y
        sta VIC_SPRITE_Y0,y

        lda intro_spr_bits,x
        ora treas_spr_mask
        sta treas_spr_mask

        inx                             ; Paire suivante
        rts

; Phase 1 : Sprites en haut d'ecran (Y dans [50..114])
intro_apply_treas_sprites_p1:
        lda #0
        sta treas_spr_mask
        sta treas_cur_slot
        ldx #0                          ; Index sprite gauche (0, 2, 4, 6)

.p1_loop:
        ldy treas_cur_slot
        lda treas_active,y
        beq .p1_next_slot
        lda treas_y,y
        cmp #115
        bcs .p1_next_slot              ; Y >= 115 -> phase suivante
        cmp #50
        bcc .p1_next_slot              ; Y < 50 -> hors ecran

        jsr intro_set_treas_pair
        cpx #8
        beq .p1_done

.p1_next_slot:
        inc treas_cur_slot
        lda treas_cur_slot
        cmp #12
        bne .p1_loop

.p1_done:
        lda treas_spr_mask
        sta VIC_SPRITE_EN
        lda #%11111111
        sta VIC_SPRITE_MC               ; Tous multicolores
        lda #COL_WHITE
        sta VIC_SPRITE_MC1              ; Blanc (eclats / lame / contour)
        lda #COL_BROWN
        sta VIC_SPRITE_MC2              ; Marron / or
        lda #0
        sta VIC_SPRITE_EXP_X
        sta VIC_SPRITE_EXP_Y
        sta VIC_SPRITE_MSB
        rts

; Phase 2 : Sprites au milieu d'ecran (Y dans [115..179])
intro_apply_treas_sprites_p2:
        lda #0
        sta treas_spr_mask
        sta treas_cur_slot
        ldx #0

.p2_loop:
        ldy treas_cur_slot
        lda treas_active,y
        beq .p2_next_slot
        lda treas_y,y
        cmp #115
        bcc .p2_next_slot              ; Y < 115 -> deja affiche en phase 1
        cmp #180
        bcs .p2_next_slot              ; Y >= 180 -> pour phase 3

        jsr intro_set_treas_pair
        cpx #8
        beq .p2_done

.p2_next_slot:
        inc treas_cur_slot
        lda treas_cur_slot
        cmp #12
        bne .p2_loop

.p2_done:
        lda treas_spr_mask
        sta VIC_SPRITE_EN
        rts

; Phase 3 : Sprites en bas d'ecran (Y dans [180..248])
intro_apply_treas_sprites_p3:
        lda #0
        sta treas_spr_mask
        sta treas_cur_slot
        ldx #0

.p3_loop:
        ldy treas_cur_slot
        lda treas_active,y
        beq .p3_next_slot
        lda treas_y,y
        cmp #180
        bcc .p3_next_slot              ; Y < 180 -> deja affiche en phase 2
        cmp #248
        bcs .p3_next_slot              ; Y >= 248 -> hors ecran en bas

        jsr intro_set_treas_pair
        cpx #8
        beq .p3_done

.p3_next_slot:
        inc treas_cur_slot
        lda treas_cur_slot
        cmp #12
        bne .p3_loop

.p3_done:
        lda treas_spr_mask
        sta VIC_SPRITE_EN
        rts

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
        lda #0
        sta intro_buf_idx
        lda #$18
        sta intro_screen_memsetup
        sta VIC_MEMSETUP
        jsr intro_music_init
        jsr intro_draw_waterfall
        ldx #11
        lda #0
-       sta treas_active,x
        dex
        bpl -
        ldx #MAX_MON_SLOTS-1
-       sta mon_slot_active,x
        dex
        bpl -
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
        sta intro_sub_timer
        sta intro_sub_timer+1
        lda #7
        sta intro_fine_scroll_y
        lda #0
        sta intro_fine_scroll_tick
        jsr intro_clear_scroll_area
        lda #%00010000 | 7              ; Active mode 24 lignes (RSEL=0) pour scrolling invisible
        sta VIC_CTRL1
+       rts

; --- 3. STORY SCROLL UNIFIE 1:1 NES (SMOOTH HARDWARE SCROLL 50 HZ) ---
.update_story:
        lda intro_scroll_line
        cmp #story_total_steps
        bcs .story_all_done

        ; Defilement fluide au pixel pres (1 pixel toutes les 2 frames = 25 px/s)
        inc intro_fine_scroll_tick
        lda intro_fine_scroll_tick
        cmp #2
        bcc .story_ret
        lda #0
        sta intro_fine_scroll_tick

        dec intro_fine_scroll_y
        lda intro_fine_scroll_y
        and #%00000111
        sta intro_fine_scroll_y
        cmp #7
        bne .story_ret

        ; Boucle 0->7 : decalage d'une ligne de caracteres et injection
        jsr intro_scroll_up_one_line
        jsr intro_inject_story_line
        inc intro_scroll_line

.story_ret:
        rts

.story_all_done:
        jsr intro_clear_scroll_area
        lda #INTRO_PHASE_TREASURES
        sta intro_phase
        lda #0
        sta intro_scroll_line
        sta intro_scroll_tick
        sta intro_sub_timer
        sta intro_sub_timer+1
        lda #7
        sta intro_fine_scroll_y
        rts

.update_fade_treas:
        lda #INTRO_PHASE_TREASURES
        sta intro_phase
        lda #0
        sta intro_scroll_line
        sta intro_scroll_tick
        sta intro_sub_timer
        sta intro_sub_timer+1
        lda #7
        sta intro_fine_scroll_y
        rts

; --- 4. ALL OF TREASURES SHOWCASE SCROLL (SMOOTH HARDWARE SCROLL) ---
.update_treasures:
        lda intro_scroll_line
        cmp #58                         ; Pause Link tenant la pancarte au centre (lignes 10..13)
        bne .tr_scroll_flow

        lda intro_sub_timer
        ora intro_sub_timer+1
        bne +
        ldx #11
        lda #0
-       sta treas_active,x
        dex
        bpl -
        sta VIC_SPRITE_EN
        jsr intro_setup_link_sign
+       inc intro_sub_timer
        bne +
        inc intro_sub_timer+1
+       lda intro_sub_timer+1
        bne .tr_sign_done
        lda intro_sub_timer
        cmp #140                        ; Pause de 2.8s
        bcc .tr_ret

.tr_sign_done:
        lda #0
        sta VIC_SPRITE_EN
        inc intro_scroll_line
        lda #0
        sta intro_sub_timer
        sta intro_sub_timer+1
        rts

.tr_scroll_flow:
        lda intro_scroll_line
        cmp #treasure_total_steps
        bcs .treasures_all_done

        inc intro_fine_scroll_tick
        lda intro_fine_scroll_tick
        cmp #2
        bcc .tr_ret
        lda #0
        sta intro_fine_scroll_tick

        ; Synchronisation de tous les slots de tresors actifs au pixel pres
        ldx #0
-       lda treas_active,x
        beq +
        dec treas_y,x
        lda treas_y,x
        cmp #50
        bcs +
        lda #0
        sta treas_active,x
+       inx
        cpx #12
        bne -

        ; Si Link (Sprite 0) est actif, il monte avec la pancarte
        lda VIC_SPRITE_EN
        and #%00000001
        beq +
        dec VIC_SPRITE_Y0
        lda VIC_SPRITE_Y0
        cmp #50
        bcs +
        lda #0
        sta VIC_SPRITE_EN
+

        dec intro_fine_scroll_y
        lda intro_fine_scroll_y
        and #%00000111
        sta intro_fine_scroll_y
        cmp #7
        bne .tr_ret

        jsr intro_scroll_up_one_line
        jsr intro_inject_treasure_step
        inc intro_scroll_line

.tr_ret:
        rts

.treasures_all_done:
        lda #0
        sta VIC_SPRITE_EN
        sta VIC_SPRITE_MC
        lda #INTRO_PHASE_MONSTERS
        sta intro_phase
        lda #0
        sta intro_scroll_line
        sta intro_fine_scroll_tick
        sta intro_sub_timer
        sta intro_sub_timer+1
        sta intro_mon_anim_tick
        ldx #MAX_MON_SLOTS-1
        lda #0
-       sta mon_slot_active,x
        dex
        bpl -
        lda #7
        sta intro_fine_scroll_y
        rts

.update_fade_monsters:
        lda #INTRO_PHASE_MONSTERS
        sta intro_phase
        lda #0
        sta intro_scroll_line
        sta intro_fine_scroll_tick
        sta intro_sub_timer
        sta intro_sub_timer+1
        sta intro_mon_anim_tick
        ldx #MAX_MON_SLOTS-1
        lda #0
-       sta mon_slot_active,x
        dex
        bpl -
        lda #7
        sta intro_fine_scroll_y
        rts

; --- 5. ALL OF MONSTERS SHOWCASE SCROLL (MULTI-MONSTRE ANIME ET SYNCHRONE) ---
.update_monsters:
        ; Animation de marche frame 0 <-> frame 1 tous les 8 frames pour tous les monstres actifs
        inc intro_mon_anim_tick
        lda intro_mon_anim_tick
        cmp #8
        bcc .anim_done
        lda #0
        sta intro_mon_anim_tick

        ldx #0
.mon_anim_loop:
        lda mon_slot_active,x
        beq .next_mon_anim
        lda mon_slot_frame,x
        eor #1
        sta mon_slot_frame,x
        jsr intro_copy_slot_sprite_frame
.next_mon_anim:
        inx
        cpx #MAX_MON_SLOTS
        bne .mon_anim_loop
.anim_done:

        lda intro_scroll_line
        cmp #monster_total_steps
        bcs .monsters_done

        inc intro_fine_scroll_tick
        lda intro_fine_scroll_tick
        cmp #2
        bcc .mon_ret
        lda #0
        sta intro_fine_scroll_tick

        ; Synchronisation de tous les slots de monstres actifs au pixel pres
        ldx #0
.mon_y_loop:
        lda mon_slot_active,x
        beq .next_mon_y
        dec mon_slot_y,x
        txa
        asl
        tay
        lda mon_slot_y,x
        sta VIC_SPRITE_Y0,y
        cmp #50
        bcs .next_mon_y
        ; Monstre sorti par le haut de l'ecran (Y < 50) : desactivation du slot
        lda #0
        sta mon_slot_active,x
        lda VIC_SPRITE_EN
        and mon_bit_inv,x
        sta VIC_SPRITE_EN
.next_mon_y:
        inx
        cpx #MAX_MON_SLOTS
        bne .mon_y_loop

        dec intro_fine_scroll_y
        lda intro_fine_scroll_y
        and #%00000111
        sta intro_fine_scroll_y
        cmp #7
        bne .mon_ret

        jsr intro_scroll_up_one_line
        jsr intro_inject_monster_step
        inc intro_scroll_line

.mon_ret:
        rts

.monsters_done:
        jsr intro_clear_scroll_area
        lda #0
        sta VIC_SPRITE_EN
        sta VIC_SPRITE_MC
        lda #$18
        sta intro_screen_memsetup
        sta VIC_MEMSETUP
        lda #%00011011                  ; Restaure le mode normal 25 lignes au retour waterfall
        sta VIC_CTRL1
        lda #INTRO_PHASE_FADE_WATER
        sta intro_phase
        lda #0
        sta intro_fade_step_idx
        sta intro_fade_tick
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
        lda #COL_BLACK
        sta VIC_BACKGROUND
        sta VIC_BORDER

        ; 1. Remplissage initial :
        ;    - Ciel rose/peche NES (CHAR_SOLID 154, COL_LRED) sur lignes 0..17 (720 octets)
        ;    - Noir (32, COL_BLACK) sur lignes 18..24 (280 octets)
        ldx #0
.clrwf1:
        lda #154                        ; CHAR_SOLID (bloc plein pour ciel rose)
        sta SCREEN_RAM,x
        sta SCREEN_RAM+$100,x
        lda #COL_LRED                   ; Ciel rose au lever du jour
        sta COLOR_RAM,x
        sta COLOR_RAM+$100,x
        inx
        bne .clrwf1

        ldx #0
.clrwf2:
        lda #154
        sta SCREEN_RAM+$200,x
        lda #COL_LRED
        sta COLOR_RAM+$200,x
        inx
        cpx #208                        ; 512 + 208 = 720 octets (lignes 0..17)
        bne .clrwf2

        ; Reste de l'ecran (lignes 18..24, 280 octets) : noir / espace
-       lda #32
        sta SCREEN_RAM+$200,x
        lda #COL_BLACK
        sta COLOR_RAM+$200,x
        inx
        bne -

        ldx #0
-       lda #32
        sta SCREEN_RAM+$300,x
        lda #COL_BLACK
        sta COLOR_RAM+$300,x
        inx
        cpx #232                        ; 768 + 232 = 1000 octets
        bne -

        ; 2. Falaise discrete haute (Ligne 1, coin superieur droit)
        lda #CHAR_CLIFF_EDG_R
        sta SCREEN_RAM+40+38
        lda #COL_GREY
        sta COLOR_RAM+40+38
        lda #CHAR_CLIFF_FACE
        sta SCREEN_RAM+40+39
        lda #COL_DGREY
        sta COLOR_RAM+40+39

        ; 3. Piliers rocheux lateraux du haut (Lignes 2..13, cols 0..1 et 38..39)
        ldx #2
.wf_upper_pillars:
        lda intro_scr_lo,x
        sta ZP_SCR
        lda intro_scr_hi,x
        sta ZP_SCR+1
        lda intro_col_hi,x
        sta ZP_COL+1
        lda ZP_SCR
        sta ZP_COL

        ; Pilier gauche (col 0..1)
        ldy #0
        lda #CHAR_CLIFF_FACE
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y
        iny
        lda #CHAR_CLIFF_EDG_L
        sta (ZP_SCR),y
        lda #COL_GREY
        sta (ZP_COL),y

        ; Pilier droit (col 38..39)
        ldy #38
        lda #CHAR_CLIFF_EDG_R
        sta (ZP_SCR),y
        lda #COL_GREY
        sta (ZP_COL),y
        iny
        lda #CHAR_CLIFF_FACE
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y

        inx
        cpx #14
        bne .wf_upper_pillars

        ; 4. Grand Blason ZELDA NES (Lignes 2..13, Cols 9..30)
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

        ldy #0                          ; col 0..21 du blason
.sh_col_loop:
        lda (ZP_SRC),y
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

        iny
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

        ; 5. Chute d'eau sous le blason & falaises moyennes (Lignes 14..17)
        ldx #14
.wf_mid_loop:
        lda intro_scr_lo,x
        sta ZP_SCR
        lda intro_scr_hi,x
        sta ZP_SCR+1
        lda intro_col_hi,x
        sta ZP_COL+1
        lda ZP_SCR
        sta ZP_COL

        ; Falaise gauche (cols 0..2)
        ldy #0
        lda #CHAR_CLIFF_FACE
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y
        iny
        lda #CHAR_CLIFF_FACE
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y
        iny
        lda #CHAR_CLIFF_EDG_L
        sta (ZP_SCR),y
        lda #COL_GREY
        sta (ZP_COL),y

        ; Chute centrale (cols 16..23)
        ldy #16
-       lda #CHAR_WATER_0
        cpx #14
        bne +
        lda #CHAR_WATER_CREST
+       sta (ZP_SCR),y
        lda #COL_CYAN
        cpx #14
        bne +
        lda #COL_WHITE
+       sta (ZP_COL),y
        iny
        cpy #24
        bne -

        ; Falaise droite (cols 37..39)
        ldy #37
        lda #CHAR_CLIFF_EDG_R
        sta (ZP_SCR),y
        lda #COL_GREY
        sta (ZP_COL),y
        iny
        lda #CHAR_CLIFF_FACE
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y
        iny
        lda #CHAR_CLIFF_FACE
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y

        inx
        cpx #18
        bne .wf_mid_loop

        ; 6. Plateau rocheux inferieur (Lignes 18..20)
        ; Ligne 18 :
        lda intro_scr_lo+18
        sta ZP_SCR
        lda intro_scr_hi+18
        sta ZP_SCR+1
        lda intro_col_hi+18
        sta ZP_COL+1
        lda ZP_SCR
        sta ZP_COL

        ldy #0
-       lda #CHAR_CLIFF_FACE
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y
        iny
        cpy #5
        bne -
        lda #CHAR_CLIFF_EDG_L
        sta (ZP_SCR),y
        lda #COL_GREY
        sta (ZP_COL),y

        ldy #16
-       lda #CHAR_WATER_0
        sta (ZP_SCR),y
        lda #COL_CYAN
        sta (ZP_COL),y
        iny
        cpy #24
        bne -

        ldy #34
        lda #CHAR_CLIFF_EDG_R
        sta (ZP_SCR),y
        lda #COL_GREY
        sta (ZP_COL),y
        iny
-       lda #CHAR_CLIFF_FACE
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y
        iny
        cpy #40
        bne -

        ; Ligne 19 : avec pins verts
        lda intro_scr_lo+19
        sta ZP_SCR
        lda intro_scr_hi+19
        sta ZP_SCR+1
        lda intro_col_hi+19
        sta ZP_COL+1
        lda ZP_SCR
        sta ZP_COL

        ldy #0
-       lda #CHAR_CLIFF_FACE
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y
        iny
        cpy #11
        bne -
-       lda #CHAR_TREE_TOP
        sta (ZP_SCR),y
        lda #COL_GREEN
        sta (ZP_COL),y
        iny
        cpy #16
        bne -

        ; Cascade
-       lda #CHAR_WATER_0
        sta (ZP_SCR),y
        lda #COL_CYAN
        sta (ZP_COL),y
        iny
        cpy #24
        bne -

        ; Falaise droite
-       lda #CHAR_CLIFF_FACE
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y
        iny
        cpy #40
        bne -

        ; Ligne 20 :
        lda intro_scr_lo+20
        sta ZP_SCR
        lda intro_scr_hi+20
        sta ZP_SCR+1
        lda intro_col_hi+20
        sta ZP_COL+1
        lda ZP_SCR
        sta ZP_COL

        ldy #0
-       lda #CHAR_CLIFF_FACE
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y
        iny
        cpy #16
        bne -
-       lda #CHAR_WATER_0
        sta (ZP_SCR),y
        lda #COL_CYAN
        sta (ZP_COL),y
        iny
        cpy #24
        bne -
-       lda #CHAR_CLIFF_FACE
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y
        iny
        cpy #40
        bne -

        ; 7. Bassin d'eau & ecume (Ligne 21)
        ldy #0
-       lda #CHAR_CLIFF_FACE
        sta SCREEN_RAM+840,y
        lda #COL_DGREY
        sta COLOR_RAM+840,y
        iny
        cpy #4
        bne -
-       lda #CHAR_LAKE_WAVE
        sta SCREEN_RAM+840,y
        lda #COL_BLUE
        sta COLOR_RAM+840,y
        iny
        cpy #16
        bne -
-       lda #CHAR_WATER_FOAM
        sta SCREEN_RAM+840,y
        lda #COL_WHITE
        sta COLOR_RAM+840,y
        iny
        cpy #24
        bne -
-       lda #CHAR_LAKE_WAVE
        sta SCREEN_RAM+840,y
        lda #COL_BLUE
        sta COLOR_RAM+840,y
        iny
        cpy #36
        bne -
-       lda #CHAR_CLIFF_FACE
        sta SCREEN_RAM+840,y
        lda #COL_DGREY
        sta COLOR_RAM+840,y
        iny
        cpy #40
        bne -

        ; 8. Textes "PUSH START BUTTON" et copyright
        jsr intro_show_press_text

        ldx #0
.nint:
        lda txt_nintendo,x
        beq +
        sta SCREEN_RAM+960+12,x
        lda #COL_WHITE
        sta COLOR_RAM+960+12,x
        inx
        bne .nint
+

        ; 9. Sprites de vagues et etincelle
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

; Animation du flux d'eau central dans les cols 16..23
intro_animate_water:
        ; Animation etincelle scintillante sur le blason (Sprite 0)
        inc intro_blink_timer
        lda intro_blink_timer
        and #%00011111                  ; Periode de 32 frames
        cmp #12                         ; Activee pendant 12 frames
        bcs .glint_off

        ; Etoile visible
        lda intro_blink_timer
        lsr
        lsr
        lsr
        lsr
        lsr
        and #%00000011                  ; Index 0..3
        tax
        lda glint_x_tbl,x
        sta VIC_SPRITE_X0
        lda glint_y_tbl,x
        sta VIC_SPRITE_Y0
        lda #SPR_BLOCK_GLINT
        sta SPRITE_PTR0
        lda #COL_WHITE
        sta VIC_SPRITE_COL0
        lda VIC_SPRITE_EN
        ora #%00000001
        sta VIC_SPRITE_EN
        jmp .glint_done

.glint_off:
        lda VIC_SPRITE_EN
        and #%11111110
        sta VIC_SPRITE_EN
.glint_done:
        ldx intro_water_frame
        lda water_char_cycle,x
        sta ZP_TMP

        ldx #15
.wf_anim_line:
        lda intro_scr_lo,x
        sta ZP_SCR
        lda intro_scr_hi,x
        sta ZP_SCR+1

        ldy #16
.wf_anim_col:
        lda ZP_TMP
        sta (ZP_SCR),y
        iny
        cpy #24
        bne .wf_anim_col

        inx
        cpx #21
        bne .wf_anim_line
        rts

water_char_cycle: !byte CHAR_WATER_0, CHAR_WATER_1, CHAR_WATER_2
glint_x_tbl: !byte 120, 160, 200, 160
glint_y_tbl: !byte 72,  88,  72,  115

intro_apply_pal_colors:
        ldx intro_pal_step
        cpx #16
        bcc +
        rts
+       lda pal_bg_colors,x
        sta VIC_BACKGROUND

        ; Pointeur vers debut de SCREEN_RAM ($0400) et COLOR_RAM ($D800)
        lda #<SCREEN_RAM
        sta ZP_SCR
        lda #>SCREEN_RAM
        sta ZP_SCR+1
        lda #<COLOR_RAM
        sta ZP_COL
        lda #>COLOR_RAM
        sta ZP_COL+1

        lda intro_pal_step
        sta ZP_TMP                      ; etape de palette active

        lda #4
        sta ZP_ROW                      ; compteur de 4 pages

.pal_page_loop:
        ldy #0
.pal_tile_loop:
        lda (ZP_SCR),y
        cmp #154                        ; Ciel rose/peche NES
        bne +
        ldx ZP_TMP
        lda pal_bg_colors,x
        sta (ZP_COL),y
        jmp .pal_tile_next

+       cmp #CHAR_CLIFF_FACE
        beq .pal_tile_cliff
        cmp #CHAR_CLIFF_EDG_L
        beq .pal_tile_cliff
        cmp #CHAR_CLIFF_EDG_R
        bne +
.pal_tile_cliff:
        ldx ZP_TMP
        lda pal_cliff_colors,x
        sta (ZP_COL),y
        jmp .pal_tile_next

+       cmp #CHAR_TREE_TOP
        bne +
        ldx ZP_TMP
        lda pal_tree_colors,x
        sta (ZP_COL),y
        jmp .pal_tile_next

+       cmp #CHAR_WATER_0
        bcc .pal_tile_next
        cmp #CHAR_LAKE_WAVE+1
        bcs .pal_tile_next
        ldx ZP_TMP
        lda pal_water_colors,x
        sta (ZP_COL),y

.pal_tile_next:
        iny
        lda ZP_ROW
        cmp #1                          ; Derniere page ($0700) ?
        bne +
        cpy #232                        ; Limite exacte a 1000 octets d'ecran
        beq .pal_pages_done
+       cpy #0
        bne .pal_tile_loop

        inc ZP_SCR+1
        inc ZP_COL+1
        dec ZP_ROW
        bne .pal_page_loop

.pal_pages_done:
        ; Maj couleur vagues sprites
        ldx ZP_TMP
        lda pal_water_colors,x
        sta VIC_SPRITE_COL1
        sta VIC_SPRITE_COL2
        sta VIC_SPRITE_COL3
        sta VIC_SPRITE_COL4

        cpx #8
        bcc .pal_done
        lda #COL_WHITE
        ldy #0
-       lda txt_nintendo,y
        beq .pal_done
        sta COLOR_RAM+960+12,y
        iny
        bne -
.pal_done:
        rts

nes_pal_delays:
        !byte 8, 8, 6, 5, 4, 3, 2, 2, 2, 192, 6, 4, 192, 3, 4, 4
pal_bg_colors:
        !byte COL_LRED,   COL_LRED,   COL_LRED,   COL_PURPLE, COL_CYAN
        !byte COL_LBLUE,  COL_BLUE,   COL_BLUE,   COL_DGREY,  COL_BLACK
        !byte COL_BLACK,  COL_BLACK,  COL_BLACK,  COL_BLACK,  COL_BLACK, COL_BLACK
pal_cliff_colors:
        !byte COL_DGREY,  COL_DGREY,  COL_DGREY,  COL_DGREY,  COL_DGREY
        !byte COL_DGREY,  COL_DGREY,  COL_DGREY,  COL_DGREY,  COL_BLACK
        !byte COL_BLACK,  COL_BLACK,  COL_BLACK,  COL_BLACK,  COL_BLACK, COL_BLACK
pal_water_colors:
        !byte COL_CYAN,   COL_CYAN,   COL_CYAN,   COL_CYAN,   COL_CYAN
        !byte COL_LBLUE,  COL_BLUE,   COL_BLUE,   COL_BLUE,   COL_BLUE
        !byte COL_BLUE,   COL_BLACK,  COL_BLACK,  COL_BLACK,  COL_BLACK, COL_BLACK
pal_tree_colors:
        !byte COL_GREEN,  COL_GREEN,  COL_GREEN,  COL_GREEN,  COL_GREEN
        !byte COL_DGREY,  COL_DGREY,  COL_BLACK,  COL_BLACK,  COL_BLACK
        !byte COL_BLACK,  COL_BLACK,  COL_BLACK,  COL_BLACK,  COL_BLACK, COL_BLACK

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
        lda #0
        sta intro_buf_idx
        lda #$18
        sta intro_screen_memsetup
        sta VIC_MEMSETUP
        ldx #0
.clra:  lda #32
        sta SCREEN_RAM,x
        sta SCREEN_RAM+$100,x
        sta SCREEN_RAM+$200,x
        sta SCREEN_RAM+$2e8,x
        sta $0c00,x
        sta $0c00+$100,x
        sta $0c00+$200,x
        sta $0c00+$2e8,x
        inx
        bne .clra

        ; Pre-coloration de COLOR_RAM
        lda intro_phase
        cmp #INTRO_PHASE_STORY
        beq .clr_story_col

        ; Tresors et monstres : tout le texte en blanc
        ldx #0
        lda #COL_WHITE
-       sta COLOR_RAM,x
        sta COLOR_RAM+$100,x
        sta COLOR_RAM+$200,x
        sta COLOR_RAM+$2e8,x
        inx
        bne -
        jmp .clr_sprites

.clr_story_col:
        ; Histoire : col 6 bleu clair, col 7..32 blanc, col 33 bleu clair, marges noir
        ldx #0
.row_col:
        lda intro_col_hi,x
        sta ZP_DST+1
        lda intro_scr_lo,x
        sta ZP_DST
        ldy #0
-       lda #COL_BLACK
        sta (ZP_DST),y
        iny
        cpy #6
        bne -
        lda #COL_LBLUE
        sta (ZP_DST),y
        iny
-       lda #COL_WHITE
        sta (ZP_DST),y
        iny
        cpy #33
        bne -
        lda #COL_LBLUE
        sta (ZP_DST),y
        iny
-       lda #COL_BLACK
        sta (ZP_DST),y
        iny
        cpy #40
        bne -
        inx
        cpx #25
        bne .row_col

.clr_sprites:
        ; Reinitialise tous les slots de tresors
        ldx #11
        lda #0
-       sta treas_active,x
        dex
        bpl -
        sta VIC_SPRITE_EN
        sta VIC_SPRITE_EXP_X
        sta VIC_SPRITE_EXP_Y
        rts

; ===========================================================================
; MOTEUR DE DEFILEMENT VERTICAL DOUBLE-BUFFER 50 HZ (SCROLLING 1:1 NES)
; ===========================================================================

; Decale tout l'ecran de 1 ligne vers le haut dans le tampon inactif
; (Buffer 0: $0400 <-> Buffer 1: $0C00) pour une fluidite absolue sans dechirement.
intro_scroll_up_one_line:
        lda intro_buf_idx
        bne .scroll_1_to_0

        ; Buffer 0 ($0400) est actuellement affiche.
        ; On copie $0400 (lignes 1..24) vers $0C00 (lignes 0..23)
        ldx #0
-       lda SCREEN_RAM+40,x
        sta $0c00,x
        lda SCREEN_RAM+40+$100,x
        sta $0c00+$100,x
        lda SCREEN_RAM+40+$200,x
        sta $0c00+$200,x
        inx
        bne -
        ldx #0
-       lda SCREEN_RAM+40+$300,x
        sta $0c00+$300,x
        inx
        cpx #192
        bne -
        ; Efface ligne 24 de $0C00 ($0FC0..$0FE7)
        lda #32
        ldx #0
-       sta $0fc0,x
        inx
        cpx #40
        bne -
        lda #1
        sta intro_buf_idx
        lda #$38
        sta intro_screen_memsetup
        rts

.scroll_1_to_0:
        ; Buffer 1 ($0C00) est actuellement affiche.
        ; On copie $0C00 (lignes 1..24) vers $0400 (lignes 0..23)
        ldx #0
-       lda $0c00+40,x
        sta SCREEN_RAM,x
        lda $0c00+40+$100,x
        sta SCREEN_RAM+$100,x
        lda $0c00+40+$200,x
        sta SCREEN_RAM+$200,x
        inx
        bne -
        ldx #0
-       lda $0c00+40+$300,x
        sta SCREEN_RAM+$300,x
        inx
        cpx #192
        bne -
        ; Efface ligne 24 de $0400 ($07C0..$07E7)
        lda #32
        ldx #0
-       sta SCREEN_RAM+960,x
        inx
        cpx #40
        bne -
        lda #0
        sta intro_buf_idx
        lda #$18
        sta intro_screen_memsetup
        rts

; Injecte une ligne de 40 colonnes pointee par ZP_SRC sur la ligne 24 du tampon actif
intro_inject_text_line_24:
        ldy #0
.inj_l: lda (ZP_SRC),y
        beq .inj_pad
        ldx intro_buf_idx
        bne +
        sta SCREEN_RAM+960,y
        jmp ++
+       sta $0fc0,y
++      iny
        cpy #40
        bne .inj_l
        rts

.inj_pad:
        lda #32
        ldx intro_buf_idx
        bne +
-       sta SCREEN_RAM+960,y
        iny
        cpy #40
        bne -
        rts
+
-       sta $0fc0,y
        iny
        cpy #40
        bne -
        rts

; Injecte la ligne d'histoire correspondant a intro_scroll_line
intro_inject_story_line:
        lda intro_scroll_line
        cmp #story_total_steps
        bcs .st_inj_done
        cmp #22
        bcs .st_blank
        asl
        tax
        lda story_ptrs,x
        sta ZP_SRC
        lda story_ptrs+1,x
        sta ZP_SRC+1
        jmp intro_inject_text_line_24
.st_blank:
        lda #<s_line_blank
        sta ZP_SRC
        lda #>s_line_blank
        sta ZP_SRC+1
        jmp intro_inject_text_line_24
.st_inj_done:
        rts

; Injecte un pas du defile des 35 tresors
intro_inject_treasure_step:
        lda intro_scroll_line
        cmp #2
        bne +
        jmp .inj_tr_head
+       cmp #41
        bne +
        jmp .inj_tr_foot
+       cmp #44
        bne +
        jmp .inj_tr_sign0
+       cmp #45
        bne +
        jmp .inj_tr_sign1
+       cmp #46
        bne +
        jmp .inj_tr_sign2
+       cmp #47
        bne +
        jmp .inj_tr_sign3
+
        ; Rangees de tresors (4..39 -> 18 items, 2 pas par item, espacement 16 px)
        cmp #4
        bcc +
        cmp #40
        bcs +

        ; Test pas pair
        lsr
        bcc .is_even_step
+       rts

.is_even_step:
        sec
        sbc #2                          ; A = (intro_scroll_line / 2) - 2 = row index 0..17
        sta intro_tmp_row

        ; Nom Colonne Gauche (colonnes 8..19)
        asl
        tay
        lda tr_l_ptrs,y
        sta ZP_SRC
        lda tr_l_ptrs+1,y
        sta ZP_SRC+1
        ldy #0
-       lda (ZP_SRC),y
        beq +
        ldx intro_buf_idx
        bne .l_b1
        sta SCREEN_RAM+960+8,y
        jmp .l_cont
.l_b1:  sta $0fc0+8,y
.l_cont:
        iny
        cpy #13
        bne -
+
        ; Nom Colonne Droite (colonnes 24..35)
        lda intro_tmp_row
        asl
        tay
        lda tr_r_ptrs,y
        sta ZP_SRC
        lda tr_r_ptrs+1,y
        sta ZP_SRC+1
        ldy #0
-       lda (ZP_SRC),y
        beq +
        ldx intro_buf_idx
        bne .r_b1
        sta SCREEN_RAM+960+24,y
        jmp .r_cont
.r_b1:  sta $0fc0+24,y
.r_cont:
        iny
        cpy #13
        bne -
+
        ; Active une rangee de sprites materiels (slot libre dans treas_active)
        ldy #0
-       lda treas_active,y
        beq .found_free_slot
        iny
        cpy #12
        bne -
        rts

.found_free_slot:
        lda #1
        sta treas_active,y
        lda #242                        ; Entre par le bas de l'ecran
        sta treas_y,y
        ldx intro_tmp_row
        lda tr_l_spr_blocks,x
        sta treas_spr_l,y
        lda tr_l_spr_colors,x
        sta treas_col_l,y
        lda tr_r_spr_blocks,x
        sta treas_spr_r,y
        lda tr_r_spr_colors,x
        sta treas_col_r,y
        rts

.inj_tr_rts:
        rts

.inj_tr_done:
        rts

.inj_tr_head:
        lda #<txt_treasures_header
        sta ZP_SRC
        lda #>txt_treasures_header
        sta ZP_SRC+1
        jmp intro_inject_text_line_24

.inj_tr_foot:
        lda #<txt_treasures_footer
        sta ZP_SRC
        lda #>txt_treasures_footer
        sta ZP_SRC+1
        jmp intro_inject_text_line_24

.inj_tr_sign0:
        lda #<txt_sign_0
        sta ZP_SRC
        lda #>txt_sign_0
        sta ZP_SRC+1
        jmp intro_inject_text_line_24

.inj_tr_sign1:
        lda #<txt_sign_1
        sta ZP_SRC
        lda #>txt_sign_1
        sta ZP_SRC+1
        jmp intro_inject_text_line_24

.inj_tr_sign2:
        lda #<txt_sign_2
        sta ZP_SRC
        lda #>txt_sign_2
        sta ZP_SRC+1
        jmp intro_inject_text_line_24

.inj_tr_sign3:
        lda #<txt_sign_3
        sta ZP_SRC
        lda #>txt_sign_3
        sta ZP_SRC+1
        jmp intro_inject_text_line_24

; Configure Link tenant la pancarte du manuel
intro_setup_link_sign:
        lda #SPR_BLOCK_LINK
        sta SPRITE_PTR0
        sta $0ff8
        lda #172                        ; Centre horizontal sous la pancarte
        sta VIC_SPRITE_X0
        lda #162                        ; Directement sous la bordure de la pancarte
        sta VIC_SPRITE_Y0
        lda VIC_SPRITE_MSB
        and #%11111110
        sta VIC_SPRITE_MSB
        lda #0
        sta VIC_SPRITE_EXP_X
        sta VIC_SPRITE_EXP_Y
        lda VIC_SPRITE_MC
        ora #%00000001
        sta VIC_SPRITE_MC
        lda #COL_LRED
        sta VIC_SPRITE_MC1              ; Peau
        lda #COL_BROWN
        sta VIC_SPRITE_MC2              ; Bottes / ceinturon
        lda #COL_GREEN
        sta VIC_SPRITE_COL0             ; Tunique verte authentique
        lda #%00000001
        sta VIC_SPRITE_EN
        rts

; Injecte un pas du defile des 15 monstres
intro_inject_monster_step:
        lda intro_scroll_line
        cmp #2
        bne +
        jmp .inj_mon_head
+       cmp #66
        bne +
        jmp .inj_mon_foot
+       cmp #6
        bcc .inj_mon_ret
        cmp #63
        bcs .inj_mon_ret

        sec
        sbc #6
        tay
        and #%00000011
        bne .inj_mon_ret                ; Pas un multiple de 4 : ligne vide

        tya
        lsr
        lsr                             ; A = 0..14
        sta intro_mon_idx
        tax
        jmp .do_inj_mon

.inj_mon_ret:
        rts

.do_inj_mon:

        ; Affiche le nom du monstre a col 16
        txa
        asl
        tay
        lda intro_mon_name_ptrs,y
        sta ZP_SRC
        lda intro_mon_name_ptrs+1,y
        sta ZP_SRC+1
        ldy #0
-       lda (ZP_SRC),y
        beq +
        ldx intro_buf_idx
        bne .m_b1
        sta SCREEN_RAM+960+16,y
        jmp .m_cont
.m_b1:  sta $0fc0+16,y
.m_cont:
        iny
        cpy #16
        bne -
+
        ; Trouve un slot de sprite libre parmi les 6 slots
        ldx #0
-       lda mon_slot_active,x
        beq .found_mon_slot
        inx
        cpx #MAX_MON_SLOTS
        bne -
        rts

.found_mon_slot:
        lda #1
        sta mon_slot_active,x
        lda #242
        sta mon_slot_y,x
        lda intro_mon_idx
        sta mon_slot_id,x
        lda #0
        sta mon_slot_frame,x

        jsr intro_copy_slot_sprite_frame

        txa
        asl
        tay
        lda #120                        ; Col 15 (X=120) immediatement a gauche du nom
        sta VIC_SPRITE_X0,y
        lda #242                        ; Y=242 entre par le bas avec le nom
        sta VIC_SPRITE_Y0,y

        txa
        clc
        adc #SPR_BLOCK_MON0
        sta SPRITE_PTR0,x
        sta $0ff8,x

        ldy intro_mon_idx
        lda intro_mon_colors,y
        sta VIC_SPRITE_COL0,x

        lda #COL_LRED
        sta VIC_SPRITE_MC1
        lda #COL_BROWN
        sta VIC_SPRITE_MC2

        lda VIC_SPRITE_MSB
        and mon_bit_inv,x
        sta VIC_SPRITE_MSB

        lda VIC_SPRITE_EXP_X
        and mon_bit_inv,x
        sta VIC_SPRITE_EXP_X

        lda VIC_SPRITE_EXP_Y
        and mon_bit_inv,x
        sta VIC_SPRITE_EXP_Y

        lda VIC_SPRITE_MC
        ora mon_bit_mask,x
        sta VIC_SPRITE_MC

        lda VIC_SPRITE_EN
        ora mon_bit_mask,x
        sta VIC_SPRITE_EN
        rts

.inj_mon_head:
        lda #<txt_monsters_header
        sta ZP_SRC
        lda #>txt_monsters_header
        sta ZP_SRC+1
        jmp intro_inject_text_line_24

.inj_mon_foot:
        lda #<txt_treasures_footer
        sta ZP_SRC
        lda #>txt_treasures_footer
        sta ZP_SRC+1
        jmp intro_inject_text_line_24

intro_copy_slot_sprite_frame:
        stx intro_tmp_slot

        lda mon_buf_lo,x
        sta ZP_DST
        lda mon_buf_hi,x
        sta ZP_DST+1

        ldy mon_slot_id,x
        tya
        asl
        tay
        lda mon_slot_frame,x
        bne .copy_f1
        lda intro_mon_f0_ptrs,y
        sta ZP_SRC
        lda intro_mon_f0_ptrs+1,y
        sta ZP_SRC+1
        jmp .do_copy_frame
.copy_f1:
        lda intro_mon_f1_ptrs,y
        sta ZP_SRC
        lda intro_mon_f1_ptrs+1,y
        sta ZP_SRC+1

.do_copy_frame:
        ldy #63
-       lda (ZP_SRC),y
        sta (ZP_DST),y
        dey
        bpl -
        ldx intro_tmp_slot
        rts

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
        !byte 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
        !byte 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7
        !byte 7, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 7
        !byte 7, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 7
        !byte 7, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 7
        !byte 7, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 7
        !byte 7, 7, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 7
        !byte 7, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 7
        !byte 7, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 3, 7, 0, 7
        !byte 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 3, 3, 3, 0, 7
        !byte 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7
        !byte 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
; ===========================================================================
; TEXTES OFFICIELS DE L'HISTOIRE (NES 1986)
; ===========================================================================
txt_press_button:   !text "PUSH START BUTTON", 0
txt_nintendo:       !byte CHAR_COPYRIGHT : !text " 1986 NINTENDO", 0

s_line_blank: !fill 40, 32 : !byte 0

s_line_00: !text "      ", CHAR_FRAME_TL, CHAR_FRAME_H, CHAR_FRAME_H, CHAR_FRAME_X, " THE LEGEND OF ZELDA ", CHAR_FRAME_X, CHAR_FRAME_H, CHAR_FRAME_TR, "      ", 0
s_line_01: !text "      ", CHAR_FRAME_V, "                          ", CHAR_FRAME_V, "      ", 0
s_line_02: !text "      ", CHAR_FRAME_V, "  MANY YEARS AGO PRINCE   ", CHAR_FRAME_V, "      ", 0
s_line_03: !text "      ", CHAR_FRAME_V, "  DARKNESS GANNON STOLE   ", CHAR_FRAME_V, "      ", 0
s_line_04: !text "      ", CHAR_FRAME_V, "  ONE OF THE TRIFORCE WITH", CHAR_FRAME_V, "      ", 0
s_line_05: !text "      ", CHAR_FRAME_V, "  POWER. PRINCESS ZELDA   ", CHAR_FRAME_V, "      ", 0
s_line_06: !text "      ", CHAR_FRAME_V, "  HAD ONE OF THE TRIFORCE ", CHAR_FRAME_V, "      ", 0
s_line_07: !text "      ", CHAR_FRAME_V, "  WITH WISDOM. SHE DIVIDED", CHAR_FRAME_V, "      ", 0
s_line_08: !text "      ", CHAR_FRAME_V, "  IT INTO 8 UNITS TO HIDE ", CHAR_FRAME_V, "      ", 0
s_line_09: !text "      ", CHAR_FRAME_V, "  IT FROM GANNON BEFORE   ", CHAR_FRAME_V, "      ", 0
s_line_10: !text "      ", CHAR_FRAME_V, "  SHE WAS CAPTURED.       ", CHAR_FRAME_V, "      ", 0
s_line_11: !text "      ", CHAR_FRAME_V, "                          ", CHAR_FRAME_V, "      ", 0
s_line_12: !text "      ", CHAR_FRAME_V, "    GO FIND THE 8 UNITS   ", CHAR_FRAME_V, "      ", 0
s_line_13: !text "      ", CHAR_FRAME_V, "    LINK TO SAVE HER.     ", CHAR_FRAME_V, "      ", 0
s_line_14: !text "      ", CHAR_FRAME_V, "                          ", CHAR_FRAME_V, "      ", 0
s_line_15: !text "      ", CHAR_FRAME_V, "                          ", CHAR_FRAME_V, "      ", 0
s_line_16: !text "      ", CHAR_FRAME_V, "                          ", CHAR_FRAME_V, "      ", 0
s_line_17: !text "      ", CHAR_FRAME_V, "                          ", CHAR_FRAME_V, "      ", 0
s_line_18: !text "      ", CHAR_FRAME_V, "                          ", CHAR_FRAME_V, "      ", 0
s_line_19: !text "      ", CHAR_FRAME_BL
           !fill 26, CHAR_FRAME_H
           !byte CHAR_FRAME_BR
           !text "      ", 0

story_line_count = 20
story_total_steps = 48

story_ptrs:
        !word s_line_blank, s_line_blank
        !word s_line_00, s_line_01, s_line_02, s_line_03, s_line_04, s_line_05
        !word s_line_06, s_line_07, s_line_08, s_line_09, s_line_10, s_line_11
        !word s_line_12, s_line_13, s_line_14, s_line_15, s_line_16, s_line_17
        !word s_line_18, s_line_19

; ===========================================================================
; DEFILE OFFICIEL DES TRESORS DE ZELDA 1 (2 COLONNES)
; ===========================================================================
txt_treasures_header: !text "      ", CHAR_STAR_DOT, CHAR_STAR_DOT, " ALL OF TREASURES ", CHAR_STAR_DOT, CHAR_STAR_DOT, "      ", 0
txt_treasures_footer: !text "                ", CHAR_STAR_DOT, CHAR_STAR_DOT, "                ", 0

txt_sign_0: !text "      ", CHAR_FRAME_TL : !fill 26, CHAR_FRAME_H : !byte CHAR_FRAME_TR : !text "      ", 0
txt_sign_1: !text "      ", CHAR_FRAME_V, "    PLEASE LOOK UP THE    ", CHAR_FRAME_V, "      ", 0
txt_sign_2: !text "      ", CHAR_FRAME_V, "    MANUAL FOR DETAILS.   ", CHAR_FRAME_V, "      ", 0
txt_sign_3: !text "      ", CHAR_FRAME_BL : !fill 26, CHAR_FRAME_H : !byte CHAR_FRAME_BR : !text "      ", 0

treasure_total_steps = 70

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

; Sprites et couleurs 1:1 NES pour les 35 tresors
!source "src/intro_items_tables.inc"

tr_l_ptrs:
        !word tr_l_name_00, tr_l_name_01, tr_l_name_02, tr_l_name_03, tr_l_name_04, tr_l_name_05
        !word tr_l_name_06, tr_l_name_07, tr_l_name_08, tr_l_name_09, tr_l_name_10, tr_l_name_11
        !word tr_l_name_12, tr_l_name_13, tr_l_name_14, tr_l_name_15, tr_l_name_16, tr_l_name_17

tr_r_ptrs:
        !word tr_r_name_00, tr_r_name_01, tr_r_name_02, tr_r_name_03, tr_r_name_04, tr_r_name_05
        !word tr_r_name_06, tr_r_name_07, tr_r_name_08, tr_r_name_09, tr_r_name_10, tr_r_name_11
        !word tr_r_name_12, tr_r_name_13, tr_r_name_14, tr_r_name_15, tr_r_name_16, tr_r_name_17

; ===========================================================================
; DEFILE DES 15 MONSTRES D'HYRULE
; ===========================================================================
txt_monsters_header: !text "       ", CHAR_STAR_DOT, CHAR_STAR_DOT, " ALL OF MONSTERS ", CHAR_STAR_DOT, CHAR_STAR_DOT, "      ", 0

monster_total_steps = 90
