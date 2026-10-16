# Script générant le nouveau src/intro.asm complet et magnifique
intro_code = ''' ; ===========================================================================
; intro.asm : Introduction légendaire de The Legend of Zelda (1986)
;
; Comprend :
;   1. Écran Titre & Cascade animée (Waterfall Title Screen)
;      - Grand logo majestueux "THE LEGEND OF ZELDA" avec Triforces dorées
;      - Falaises étagées de Death Mountain avec roches texturées et pins
;      - Chute d'eau centrale animée à double flux descendant et écume
;      - Bassin d'eau bleu avec vagues et reflets
;      - Mention clignotante "PRESS BUTTON TO PLAY" et Copyright Nintendo 1986
;   2. Déroulement de l'histoire (Story Scroll)
;      - Prologue officiel de Zelda 1 défilant avec fluidité
;   3. Défilé des trésors de Zelda 1 (All Treasures of Hyrule)
;      - Présentation de tous les objets légendaires avec leurs icônes et noms
;   4. Musique complète et authentique de Koji Kondo (SID 3 Voix)
;      - Transcrite directement à partir du fichier MIDI officiel du jeu
;      - Voix 1 : Mélodie Lead puissante (Fanfare + Thème principal)
;      - Voix 2 : Arpèges montants d'ouverture et basse héroïque
;      - Voix 3 : Percussion de marche militaire
; ===========================================================================

!zone intro

INTRO_PHASE_WATERFALL = 0
INTRO_PHASE_STORY     = 1
INTRO_PHASE_TREASURES = 2

intro_phase:        !byte INTRO_PHASE_WATERFALL
intro_timer:        !word 0
intro_water_frame:  !byte 0
intro_water_tick:   !byte 0
intro_blink_timer:  !byte 0
intro_scroll_line:  !byte 0
intro_scroll_tick:  !byte 0
intro_music_step:   !byte 0
intro_music_delay:  !byte 0

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
        sta intro_music_step
        sta intro_music_delay

        ; Masque tous les sprites pendant l'écran titre
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
        jsr intro_start_game
        rts

.no_start_button:
        inc intro_timer
        bne +
        inc intro_timer+1
+
        ; Selon la phase active
        lda intro_phase
        cmp #INTRO_PHASE_WATERFALL
        beq .update_waterfall
        cmp #INTRO_PHASE_STORY
        beq .update_story
        jmp .update_treasures

; ---------------------------------------------------------------------------
; 1. MISE A JOUR DE LA CASCADE (WATERFALL)
; ---------------------------------------------------------------------------
.update_waterfall:
        ; Animation de l'eau (toutes les 4 frames)
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
        ; Clignotement du texte "PRESS BUTTON TO PLAY"
        inc intro_blink_timer
        lda intro_blink_timer
        and #%00100000
        beq .hide_text
        jsr intro_show_press_text
        jmp .check_wf_timeout
.hide_text:
        jsr intro_hide_press_text

.check_wf_timeout:
        ; Après environ 12 secondes (600 frames), passage au prologue de l'histoire
        lda intro_timer+1
        cmp #2
        bcc .wf_done
        lda intro_timer
        cmp #88
        bcc .wf_done

        ; Bascule vers l'histoire
        lda #INTRO_PHASE_STORY
        sta intro_phase
        lda #0
        sta intro_scroll_line
        sta intro_scroll_tick
        jsr intro_draw_story_bg
.wf_done:
        rts

; ---------------------------------------------------------------------------
; 2. MISE A JOUR DE L'HISTOIRE (STORY SCROLL)
; ---------------------------------------------------------------------------
.update_story:
        inc intro_scroll_tick
        lda intro_scroll_tick
        cmp #60                         ; une nouvelle ligne toutes les 1.2s
        bcc .story_done
        lda #0
        sta intro_scroll_tick

        jsr intro_scroll_story_step
        inc intro_scroll_line
        lda intro_scroll_line
        cmp #26                         ; Fin de l'histoire
        bcc .story_done

        ; Bascule vers la liste des trésors
        lda #INTRO_PHASE_TREASURES
        sta intro_phase
        lda #0
        sta intro_scroll_line
        sta intro_scroll_tick
        jsr intro_draw_treasures_bg
.story_done:
        rts

; ---------------------------------------------------------------------------
; 3. MISE A JOUR DES TRESORS (TREASURE SHOWCASE)
; ---------------------------------------------------------------------------
.update_treasures:
        inc intro_scroll_tick
        lda intro_scroll_tick
        cmp #50                         ; un trésor toutes les secondes
        bcc .tr_done
        lda #0
        sta intro_scroll_tick

        jsr intro_scroll_treasure_step
        inc intro_scroll_line
        lda intro_scroll_line
        cmp #20                         ; Fin des trésors
        bcc .tr_done

        ; Retour à la cascade
        lda #INTRO_PHASE_WATERFALL
        sta intro_phase
        lda #0
        sta intro_timer
        sta intro_timer+1
        jsr intro_draw_waterfall
.tr_done:
        rts

; ---------------------------------------------------------------------------
; intro_start_game : transition de l'intro vers le jeu d'aventure
; ---------------------------------------------------------------------------
intro_start_game:
        ; Couper la musique d'intro
        jsr intro_music_stop

        ; Jingle victorieux de départ
        lda #15
        sta SID_VOLUME
        lda #$80
        sta SID_V1_FREQ_LO
        lda #$44
        sta SID_V1_FREQ_HI
        lda #$09
        sta SID_V1_AD
        lda #$00
        sta SID_V1_SR
        lda #%00010001
        sta SID_V1_CTRL

        ; Bascule en mode jeu
        lda #STATE_PLAYING
        sta game_state

        ; Réinitialise l'environnement de jeu Overworld
        jsr init_video
        jsr clear_screen
        jsr load_room
        jsr hud_init
        jsr player_init
        jsr items_init
        jsr enemies_init
        jsr enemies_prep_multiplexer
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
        lda #32                         ; Espace
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

        ; --- 1. LOGO MAJESTUEUX "THE LEGEND OF ZELDA" (Lignes 1..4) ---
        ; "T H E   L E G E N D   O F" (Ligne 1, centré)
        ldx #0
.tlo:
        lda txt_title_legend,x
        beq +
        sta SCREEN_RAM+40+8,x
        lda #COL_WHITE
        sta COLOR_RAM+40+8,x
        inx
        bne .tlo
+
        ; "Z  E  L  D  A" en or éclatant (Ligne 2, centré)
        ldx #0
.tzelda:
        lda txt_title_zelda,x
        beq +
        sta SCREEN_RAM+80+13,x
        lda #COL_YELLOW
        sta COLOR_RAM+80+13,x
        inx
        bne .tzelda
+
        ; Deux grandes Triforces royales d'or encadrant le titre
        lda #CHAR_TRIFORCE
        sta SCREEN_RAM+80+6
        sta SCREEN_RAM+80+33
        lda #COL_YELLOW
        sta COLOR_RAM+80+6
        sta COLOR_RAM+80+33

        ; Filet d'or décoratif sous le logo (Ligne 3)
        ldx #0
.sep:
        lda #115                        ; Barre médiane fine
        sta SCREEN_RAM+120+6,x
        lda #COL_YELLOW
        sta COLOR_RAM+120+6,x
        inx
        cpx #28
        bne .sep

        ; --- 2. RELIEF DES FALAISES DE DEATH MOUNTAIN (Lignes 5..18) ---
        ; Falaises rocheuses étagées à gauche (cols 0..16) et à droite (cols 23..39)
        ldx #5                          ; De la ligne 5 à la ligne 18
.cliff_row:
        lda intro_scr_lo,x
        sta ZP_SCR
        lda intro_scr_hi,x
        sta ZP_SCR+1
        lda intro_col_hi,x
        sta ZP_COL+1
        lda ZP_SCR
        sta ZP_COL

        ; Détermination de la largeur rocheuse selon la hauteur
        lda cliff_left_width-5,x
        sta ZP_TMP                      ; largeur gauche
        lda cliff_right_start-5,x
        sta ZP_ROW                      ; début droite

        ; Côté gauche : rochers et dégradé
        ldy #0
.cg:
        lda #108                        ; Pierre rocheuse
        sta (ZP_SCR),y
        lda #COL_GREY
        sta (ZP_COL),y
        iny
        cpy ZP_TMP
        bne .cg

        ; Pins / verdure sur la crête gauche
        dey
        lda #'T'
        sta (ZP_SCR),y
        lda #COL_GREEN
        sta (ZP_COL),y

        ; Côté droit : rochers et dégradé
        ldy ZP_ROW
        lda #'T'
        sta (ZP_SCR),y
        lda #COL_GREEN
        sta (ZP_COL),y
        iny
.cd:
        lda #108
        sta (ZP_SCR),y
        lda #COL_GREY
        sta (ZP_COL),y
        iny
        cpy #40
        bne .cd

        inx
        cpx #19
        bne .cliff_row

        ; --- 3. BASSIN D'EAU EN BAS (Lignes 19..20) ---
        ; Surface d'eau profonde bleue
        ldx #0
.lake:
        lda #108                        ; surface d'eau pleine
        sta SCREEN_RAM+760+8,x
        sta SCREEN_RAM+800+6,x
        lda #COL_BLUE
        sta COLOR_RAM+760+8,x
        sta COLOR_RAM+800+6,x
        inx
        cpx #24
        bne .lake

        ; --- 4. MENTIONS DU BAS (Lignes 22..24) ---
        ; "PRESS BUTTON TO PLAY"
        jsr intro_show_press_text

        ; "@ 1986 NINTENDO"
        ldx #0
.nint:
        lda txt_nintendo,x
        beq +
        sta SCREEN_RAM+960+13,x
        lda #COL_GREY
        sta COLOR_RAM+960+13,x
        inx
        bne .nint
+
        ; Dessin initial de la cascade
        jsr intro_animate_water
        rts

; Tables de relief des falaises (pour lignes 5..18)
cliff_left_width:
        !byte 14, 15, 15, 16, 16, 17, 17, 17, 17, 17, 17, 17, 17, 17
cliff_right_start:
        !byte 26, 25, 25, 24, 24, 23, 23, 23, 23, 23, 23, 23, 23, 23

; ---------------------------------------------------------------------------
; intro_animate_water : anime le flux descendant de la cascade (cols 17..22)
; ---------------------------------------------------------------------------
intro_animate_water:
        ; Choix du caractère de flux selon la frame
        ldx intro_water_frame
        lda water_char_cycle,x
        sta ZP_TMP

        ; Parcourt les lignes 5 à 18 pour la cascade centrale
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

        ; 6 colonnes de cascade (17..22)
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

        ; Écume bouillonnante blanche au pied de la cascade (Ligne 19, cols 16..23)
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
        sta SCREEN_RAM+880+10,x
        lda #COL_YELLOW
        sta COLOR_RAM+880+10,x
        inx
        bne .spt
+       rts

intro_hide_press_text:
        ldx #0
        lda #32
.hpt:
        sta SCREEN_RAM+880+10,x
        inx
        cpx #20
        bne .hpt
        rts

; ---------------------------------------------------------------------------
; DESSIN ET DEFILEMENT DU PROLOGUE DE L'HISTOIRE (STORY SCROLL)
; ---------------------------------------------------------------------------
intro_draw_story_bg:
        jsr intro_clear_scroll_area

        ; Titre fixe en haut
        ldx #0
.ttl:
        lda txt_story_title,x
        beq +
        sta SCREEN_RAM+40+11,x
        lda #COL_YELLOW
        sta COLOR_RAM+40+11,x
        inx
        bne .ttl
+
        ; Filet d'or décoratif
        ldx #0
.sep2:
        lda #115
        sta SCREEN_RAM+80+4,x
        lda #COL_YELLOW
        sta COLOR_RAM+80+4,x
        inx
        cpx #32
        bne .sep2
        rts

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

intro_scroll_story_step:
        ; Décale les lignes de texte de la zone de défilement (lignes 3..21) d'un cran vers le haut
        ldx #3
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

        ldy #2
.shift_line:
        lda (ZP_SRC),y
        sta (ZP_DST),y
        iny
        cpy #38
        bne .shift_line

        cpx #21
        bne .scroll_up

        ; Injecte la nouvelle ligne sur la ligne 21
        lda intro_scroll_line
        cmp #story_line_count
        bcs .blank_line

        asl
        tax
        lda story_ptrs,x
        sta ZP_SRC
        lda story_ptrs+1,x
        sta ZP_SRC+1

        ; Nettoie la ligne 21
        ldy #0
        lda #32
.clr21:
        sta SCREEN_RAM+840,y
        iny
        cpy #40
        bne .clr21

        ; Copie le texte centré sur la ligne 21
        ldy #0
.put_line:
        lda (ZP_SRC),y
        beq .line_done
        sta SCREEN_RAM+840+3,y
        lda #COL_WHITE
        sta COLOR_RAM+840+3,y
        iny
        cpy #34
        bne .put_line
.line_done:
        rts

.blank_line:
        ldy #0
        lda #32
.clrb:  sta SCREEN_RAM+840,y
        iny
        cpy #40
        bne .clrb
        rts

; ---------------------------------------------------------------------------
; DESSIN ET DEFILEMENT DES TRESORS DE ZELDA 1 (TREASURES SHOWCASE)
; ---------------------------------------------------------------------------
intro_draw_treasures_bg:
        jsr intro_clear_scroll_area

        ldx #0
.ttltr:
        lda txt_treasures_title,x
        beq +
        sta SCREEN_RAM+40+8,x
        lda #COL_YELLOW
        sta COLOR_RAM+40+8,x
        inx
        bne .ttltr
+
        ldx #0
.sep3:
        lda #115
        sta SCREEN_RAM+80+4,x
        lda #COL_YELLOW
        sta COLOR_RAM+80+4,x
        inx
        cpx #32
        bne .sep3
        rts

intro_scroll_treasure_step:
        ; Décale vers le haut les lignes 3..21
        ldx #3
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

        ldy #2
.shift_tr:
        lda (ZP_SRC),y
        sta (ZP_DST),y
        iny
        cpy #38
        bne .shift_tr

        cpx #21
        bne .scroll_tr_up

        ; Injecte le trésor sur la ligne 21
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

        ; Nettoie la ligne 21
        ldy #0
        lda #32
.clr_tr21:
        sta SCREEN_RAM+840,y
        iny
        cpy #40
        bne .clr_tr21

        ; Dessine l'icône de l'objet à la colonne 6
        lda ZP_TMP
        sta SCREEN_RAM+840+6
        lda ZP_ROW
        sta COLOR_RAM+840+6

        ; Tiret
        lda #'-'
        sta SCREEN_RAM+840+8
        lda #COL_GREY
        sta COLOR_RAM+840+8

        ; Nom de l'objet à partir de la colonne 10
        ldy #0
.put_tr:
        lda (ZP_SRC),y
        beq .tr_done_line
        sta SCREEN_RAM+840+10,y
        lda #COL_WHITE
        sta COLOR_RAM+840+10,y
        iny
        cpy #28
        bne .put_tr
.tr_done_line:
        rts

.tr_blank:
        ldy #0
        lda #32
.clrtb: sta SCREEN_RAM+840,y
        iny
        cpy #40
        bne .clrtb
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
        lda #$08                        ; Pulse width 50% ($0800)
        sta SID_V1_PW_HI
        lda #$08                        ; Attack 0, Decay 8
        sta SID_V1_AD
        lda #$c2                        ; Sustain 12, Release 2
        sta SID_V1_SR

        ; Voix 2 : Harmonie & Basse héroïque (Sawtooth)
        lda #$07                        ; Attack 0, Decay 7
        sta SID_V2_AD
        lda #$a2                        ; Sustain 10, Release 2
        sta SID_V2_SR

        ; Voix 3 : Percussion caisse claire militaire (Noise)
        lda #$03                        ; Attack 0, Decay 3
        sta SID_V3_AD
        lda #$00                        ; Sustain 0
        sta SID_V3_SR

        lda #0
        sta intro_music_step
        sta intro_music_delay
        rts

intro_music_stop:
        lda #%01000000                  ; Gate off Voix 1
        sta SID_V1_CTRL
        lda #%00100000                  ; Gate off Voix 2
        sta SID_V2_CTRL
        lda #%10000000                  ; Gate off Voix 3
        sta SID_V3_CTRL
        rts

intro_music_update:
        lda intro_music_delay
        beq .next_note
        dec intro_music_delay
        rts

.next_note:
        ldx intro_music_step
        cpx #music_length
        bcc +
        ldx #0                          ; Boucle musicale infinie
        stx intro_music_step
+
        ; Durée du pas
        lda music_dur,x
        sta intro_music_delay

        ; --- VOIX 1 (LEAD) ---
        lda music_v1_hi,x
        beq .v1_mute
        sta SID_V1_FREQ_HI
        lda music_v1_lo,x
        sta SID_V1_FREQ_LO

        lda music_v1_trig,x
        beq .v1_no_retrigger
        ; Retrigger propre
        lda #%01000000                  ; Gate OFF
        sta SID_V1_CTRL
.v1_no_retrigger:
        lda #%01000001                  ; Gate ON, Pulse
        sta SID_V1_CTRL
        jmp +
.v1_mute:
        lda #%01000000                  ; Gate OFF
        sta SID_V1_CTRL
+

        ; --- VOIX 2 (BASSE & ARPEGES) ---
        lda music_v2_hi,x
        beq .v2_mute
        sta SID_V2_FREQ_HI
        lda music_v2_lo,x
        sta SID_V2_FREQ_LO

        lda music_v2_trig,x
        beq .v2_no_retrigger
        lda #%00100000                  ; Gate OFF
        sta SID_V2_CTRL
.v2_no_retrigger:
        lda #%00100001                  ; Gate ON, Sawtooth
        sta SID_V2_CTRL
        jmp +
.v2_mute:
        lda #%00100000                  ; Gate OFF
        sta SID_V2_CTRL
+

        ; --- VOIX 3 (PERCUSSION MILITAIRE) ---
        lda music_v3_perc,x
        beq .v3_mute
        lda #$80
        sta SID_V3_FREQ_LO
        lda #$28
        sta SID_V3_FREQ_HI
        lda #%10000000                  ; Gate OFF
        sta SID_V3_CTRL
        lda #%10000001                  ; Gate ON, Noise
        sta SID_V3_CTRL
        jmp .v3_done
.v3_mute:
        lda #%10000000                  ; Gate OFF
        sta SID_V3_CTRL
.v3_done:

        inc intro_music_step
        rts

; Inclusion directe des données de partition musicale authentiques
!source "src/intro_music_data.asm"

; ===========================================================================
; TEXTES ET DONNEES DE L'INTRODUCTION
; ===========================================================================

txt_title_legend:   !text "THE  LEGEND  OF", 0
txt_title_zelda:    !text "Z E L D A", 0
txt_press_button:   !text "PRESS BUTTON TO PLAY", 0
txt_nintendo:       !text "@ 1986 NINTENDO", 0

txt_story_title:    !text "HISTOIRE D'HYRULE", 0

; Lignes du prologue défilant (34 caractères max par ligne)
s_line_01:  !text "IL Y A BIEN LONGTEMPS, DANS LE", 0
s_line_02:  !text "ROYAUME D'HYRULE...", 0
s_line_03:  !text "", 0
s_line_04:  !text "UNE LEGENDE SE TRANSMETTAIT", 0
s_line_05:  !text "DE GENERATION EN GENERATION.", 0
s_line_06:  !text "", 0
s_line_07:  !text "UN JOUR, LE PRINCE DES TENEBRES", 0
s_line_08:  !text "GANON ENVAHIT LE ROYAUME", 0
s_line_09:  !text "AVEC SON ARMEE DE MONSTRES,", 0
s_line_10:  !text "ET S'EMPARA DE LA TRIFORCE", 0
s_line_11:  !text "DE LA FORCE !", 0
s_line_12:  !text "", 0
s_line_13:  !text "CRAIGNANT SES DESSEINS DIABOLIQUES,", 0
s_line_14:  !text "LA PRINCESSE ZELDA BRISA", 0
s_line_15:  !text "LA TRIFORCE DE LA SAGESSE", 0
s_line_16:  !text "EN HUIT FRAGMENTS QU'ELLE CACHA", 0
s_line_17:  !text "DANS LES PROFONDEURS DU PAYS.", 0
s_line_18:  !text "", 0
s_line_19:  !text "AVANT D'ETRE CAPTUREE,", 0
s_line_20:  !text "ELLE ORDIA A SA NOURRICE IMPA", 0
s_line_21:  !text "DE TROUVER UN BRAVE GUERRIER.", 0
s_line_22:  !text "", 0
s_line_23:  !text "UN JEUNE HOMME NOMME LINK", 0
s_line_24:  !text "SE DRESSA ALORS FACE AU DESTIN.", 0
s_line_25:  !text "", 0
s_line_26:  !text "AIDE LINK A SAUVER HYRULE !", 0

story_line_count = 26

story_ptrs:
        !word s_line_01, s_line_02, s_line_03, s_line_04, s_line_05
        !word s_line_06, s_line_07, s_line_08, s_line_09, s_line_10
        !word s_line_11, s_line_12, s_line_13, s_line_14, s_line_15
        !word s_line_16, s_line_17, s_line_18, s_line_19, s_line_20
        !word s_line_21, s_line_22, s_line_23, s_line_24, s_line_25
        !word s_line_26

txt_treasures_title: !text "TRESORS DE LA QUETE", 0

t_name_01:  !text "TRIFORCE DE LA SAGESSE", 0
t_name_02:  !text "EPEE MAGIQUE DU HEROS", 0
t_name_03:  !text "BOUCLIER MAGIQUE", 0
t_name_04:  !text "BOOMERANG MAGIQUE", 0
t_name_05:  !text "BOMBES EXPLOSIVES", 0
t_name_06:  !text "ARC ET FLECHES D'ARGENT", 0
t_name_07:  !text "BOUGIE BLEUE DE LUMIERE", 0
t_name_08:  !text "CONTENEUR DE COEUR", 0
t_name_09:  !text "FLUTE ENCHANTEE", 0
t_name_10:  !text "RADEAU DE NAVIGATION", 0
t_name_11:  !text "ECHELLE DES RAVINS", 0
t_name_12:  !text "BRACELET DE PUISSANCE", 0
t_name_13:  !text "POTION DE VIE ROUGE", 0

treasure_count = 13

treasure_icons:
        !byte CHAR_TRIFORCE, CHAR_SWORD, CHAR_SHIELD, 110, 111
        !byte 112, 113, 114, CHAR_FLUTE, CHAR_RAFT
        !byte CHAR_LADDER, CHAR_BRACELET, CHAR_POTION

treasure_colors:
        !byte COL_YELLOW, COL_WHITE, COL_LRED, COL_YELLOW, COL_LBLUE
        !byte COL_BROWN, COL_RED, COL_RED, COL_CYAN, COL_BROWN
        !byte COL_GREY, COL_ORANGE, COL_RED

treasure_ptrs:
        !word t_name_01, t_name_02, t_name_03, t_name_04, t_name_05
        !word t_name_06, t_name_07, t_name_08, t_name_09, t_name_10
        !word t_name_11, t_name_12, t_name_13
'''

with open('src/intro.asm', 'w') as f:
    f.write(intro_code)

print("src/intro.asm successfully generated!")
