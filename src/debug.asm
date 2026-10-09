; ---------------------------------------------------------------------------
; debug.asm : Moniteur de diagnostic matériel et mémoire multi-pages
;             avec jauges graphiques et navigation au joystick (Touche 'D')
;
; 3 Pages distinctes, aérées et ultra-lisibles :
;   - Page 1 : Architecture machine, RAM 64 Ko, PRG et cartographie détaillée
;   - Page 2 : Limites matérielles VIC-II (8 sprites), charge CPU (raster) et SID (3 voix)
;   - Page 3 : Télémétrie en direct (Link, santé, inventaire, monstres et PV)
; ---------------------------------------------------------------------------

GAUGE_CAP_L     = 107                   ; Caractère bord gauche [
GAUGE_FULL      = 108                   ; Caractère segment plein █
GAUGE_HALF      = 109                   ; Caractère demi-segment ▌
GAUGE_EMPTY     = 110                   ; Caractère segment vide ═
GAUGE_CAP_R     = 111                   ; Caractère bord droit ]

dbg_cur_page:       !byte 0             ; 0 = Système & RAM, 1 = VIC-II & Limites, 2 = Télémétrie
dbg_prev_page:      !byte $ff           ; Pour forcer le tracé au premier affichage
dbg_anim_tick:      !byte 0
dbg_val:            !word 0
prev_game_state:    !byte 0
dbg_gauge_fill:     !byte 0
dbg_gauge_total:    !byte 0
dbg_tmp:            !byte 0

; Tables de saut pour les adresses écran par ligne (0..24)
screen_row_lo:
        !byte <(SCREEN_RAM + 0),   <(SCREEN_RAM + 40),  <(SCREEN_RAM + 80),  <(SCREEN_RAM + 120)
        !byte <(SCREEN_RAM + 160), <(SCREEN_RAM + 200), <(SCREEN_RAM + 240), <(SCREEN_RAM + 280)
        !byte <(SCREEN_RAM + 320), <(SCREEN_RAM + 360), <(SCREEN_RAM + 400), <(SCREEN_RAM + 440)
        !byte <(SCREEN_RAM + 480), <(SCREEN_RAM + 520), <(SCREEN_RAM + 560), <(SCREEN_RAM + 600)
        !byte <(SCREEN_RAM + 640), <(SCREEN_RAM + 680), <(SCREEN_RAM + 720), <(SCREEN_RAM + 760)
        !byte <(SCREEN_RAM + 800), <(SCREEN_RAM + 840), <(SCREEN_RAM + 880), <(SCREEN_RAM + 920)
        !byte <(SCREEN_RAM + 960)

screen_row_hi:
        !byte >(SCREEN_RAM + 0),   >(SCREEN_RAM + 40),  >(SCREEN_RAM + 80),  >(SCREEN_RAM + 120)
        !byte >(SCREEN_RAM + 160), >(SCREEN_RAM + 200), >(SCREEN_RAM + 240), >(SCREEN_RAM + 280)
        !byte >(SCREEN_RAM + 320), >(SCREEN_RAM + 360), >(SCREEN_RAM + 400), >(SCREEN_RAM + 440)
        !byte >(SCREEN_RAM + 480), >(SCREEN_RAM + 520), >(SCREEN_RAM + 560), >(SCREEN_RAM + 600)
        !byte >(SCREEN_RAM + 640), >(SCREEN_RAM + 680), >(SCREEN_RAM + 720), >(SCREEN_RAM + 760)
        !byte >(SCREEN_RAM + 800), >(SCREEN_RAM + 840), >(SCREEN_RAM + 880), >(SCREEN_RAM + 920)
        !byte >(SCREEN_RAM + 960)

; ---------------------------------------------------------------------------
; open_debug : active l'écran de debug
; ---------------------------------------------------------------------------
open_debug:
        lda game_state
        sta prev_game_state
        lda #STATE_DEBUG
        sta game_state

        ; Masque tous les sprites du jeu
        lda #0
        sta VIC_SPRITE_EN

        ; Fond et bordure noirs pour lisibilité maximale
        lda #COL_BLACK
        sta VIC_BACKGROUND
        sta VIC_BORDER

        ; Bip sonore SID d'ouverture du moniteur
        lda #15
        sta SID_VOLUME
        lda #$80
        sta SID_V1_FREQ_LO
        lda #$40
        sta SID_V1_FREQ_HI
        lda #$04
        sta SID_V1_AD
        lda #$00
        sta SID_V1_SR
        lda #%00010001                  ; Triangle
        sta SID_V1_CTRL

        lda #0
        sta dbg_cur_page
        lda #$ff
        sta dbg_prev_page

        jsr debug_show_current_page
        rts

; ---------------------------------------------------------------------------
; debug_update : boucle d'exécution de l'écran de debug
; ---------------------------------------------------------------------------
debug_update:
        ; 1. Quitter le debug : Touche 'D' ou Bouton B
        lda key_d_pressed
        bne +
        lda btn_b_pressed
        beq .no_close
+       jsr close_debug
        rts

.no_close:

        ; 2. Navigation Joystick GAUCHE : Page précédente
        lda joy
        and #JOY_LEFT
        beq .no_j_left
        lda joy_prev
        and #JOY_LEFT
        bne .no_j_left
        lda dbg_cur_page
        beq .wrap_p_max
        dec dbg_cur_page
        jmp .p_changed
.wrap_p_max:
        lda #2
        sta dbg_cur_page
        jmp .p_changed
.no_j_left:

        ; 3. Navigation Joystick DROITE : Page suivante
        lda joy
        and #JOY_RIGHT
        beq .no_j_right
        lda joy_prev
        and #JOY_RIGHT
        bne .no_j_right
        lda dbg_cur_page
        cmp #2
        beq .wrap_p_min
        inc dbg_cur_page
        jmp .p_changed
.wrap_p_min:
        lda #0
        sta dbg_cur_page
        jmp .p_changed
.no_j_right:

        ; 4. Bouton A ou Bouton X : Page suivante (cycle)
        lda btn_a_pressed
        bne .next_p
        lda btn_x_pressed
        bne .next_p
        jmp .do_render

.next_p:
        lda dbg_cur_page
        cmp #2
        beq .wrap_cyc_min
        inc dbg_cur_page
        jmp .p_changed
.wrap_cyc_min:
        lda #0
        sta dbg_cur_page

.p_changed:
        jsr sound_page_flip
        jsr debug_show_current_page
        rts

.do_render:
        ; Animation du message clignotant en bas (Ligne 24)
        inc dbg_anim_tick
        lda dbg_anim_tick
        and #16
        bne .fl_yellow
        lda #COL_LGREEN
        jmp .set_fl_col
.fl_yellow:
        lda #COL_YELLOW
.set_fl_col:
        ldx #0
.fl_loop:
        sta COLOR_RAM + 960 + 2,x
        inx
        cpx #36
        bne .fl_loop

        ; Rafraîchit les valeurs dynamiques de la page courante
        jsr debug_render_dynamic
        rts

; ---------------------------------------------------------------------------
; sound_page_flip : petit son aigu de changement d'onglet
; ---------------------------------------------------------------------------
sound_page_flip:
        lda #15
        sta SID_VOLUME
        lda #$20
        sta SID_V1_FREQ_LO
        lda #$58
        sta SID_V1_FREQ_HI
        lda #$02
        sta SID_V1_AD
        lda #$00
        sta SID_V1_SR
        lda #%00010001                  ; Triangle gate ON
        sta SID_V1_CTRL
        rts

; ---------------------------------------------------------------------------
; close_debug : ferme le debug et restaure l'affichage du jeu
; ---------------------------------------------------------------------------
close_debug:
        ; Couper le son
        lda #%00010000
        sta SID_V1_CTRL

        lda prev_game_state
        cmp #STATE_INVENTORY
        bne .restore_play
        jsr open_inventory
        rts

.restore_play:
        lda #STATE_PLAYING
        sta game_state

        lda #COL_BLACK
        sta VIC_BACKGROUND
        lda #COL_BLACK
        sta VIC_BORDER

        ; Restaure la salle, le HUD et les sprites
        jsr load_room
        jsr hud_init
        jsr player_draw
        jsr items_draw
        jsr enemies_draw
        rts

; ---------------------------------------------------------------------------
; debug_clear_screen : efface l'écran (espaces et couleurs)
; ---------------------------------------------------------------------------
debug_clear_screen:
        ldx #0
.clr_loop:
        lda #32                         ; espace
        sta SCREEN_RAM,x
        sta SCREEN_RAM+$100,x
        sta SCREEN_RAM+$200,x
        sta SCREEN_RAM+$2e8,x
        lda #COL_WHITE
        sta COLOR_RAM,x
        sta COLOR_RAM+$100,x
        sta COLOR_RAM+$200,x
        sta COLOR_RAM+$2e8,x
        inx
        bne .clr_loop
        rts

; ---------------------------------------------------------------------------
; set_row_addr : positionne ZP_SCR et ZP_COL pour une ligne et une colonne
; Entrée : X = ligne (0..24), Y = colonne (0..39)
; ---------------------------------------------------------------------------
set_row_addr:
        lda screen_row_lo,x
        sta ZP_SCR
        sta ZP_COL
        lda screen_row_hi,x
        sta ZP_SCR+1
        clc
        adc #($d8 - $04)
        sta ZP_COL+1
        tya
        beq +
        clc
        adc ZP_SCR
        sta ZP_SCR
        sta ZP_COL
        bcc +
        inc ZP_SCR+1
        inc ZP_COL+1
+       rts

; ---------------------------------------------------------------------------
; dbg_print_fixed : écrit une chaîne de longueur fixe
; Entrée : ZP_SRC (16 bits) = texte, A = couleur, X = longueur
; ---------------------------------------------------------------------------
dbg_print_fixed:
        sta dbg_tmp
        stx dbg_gauge_total
        ldy #0
.p_loop:
        lda (ZP_SRC),y
        sta (ZP_SCR),y
        lda dbg_tmp
        sta (ZP_COL),y
        iny
        cpy dbg_gauge_total
        bne .p_loop
        rts

; ---------------------------------------------------------------------------
; dbg_draw_gauge : trace une jauge graphique bordée avec segments
; Entrée :
;   ZP_SCR / ZP_COL : adresse écran de départ
;   A = nombre de segments pleins (0..X)
;   X = nombre total de segments intérieurs
;   ZP_TMP = couleur segments pleins
;   ZP_BASE = couleur segments vides
; ---------------------------------------------------------------------------
dbg_draw_gauge:
        sta dbg_gauge_fill
        stx dbg_gauge_total

        ; Cap gauche
        ldy #0
        lda #GAUGE_CAP_L
        sta (ZP_SCR),y
        lda #COL_WHITE
        sta (ZP_COL),y
        iny

        ; Segments intérieurs
        ldx #0
.g_loop:
        cpx dbg_gauge_fill
        bcs .g_empty
        lda #GAUGE_FULL
        sta (ZP_SCR),y
        lda ZP_TMP
        sta (ZP_COL),y
        jmp .g_next
.g_empty:
        lda #GAUGE_EMPTY
        sta (ZP_SCR),y
        lda ZP_BASE
        sta (ZP_COL),y
.g_next:
        iny
        inx
        cpx dbg_gauge_total
        bne .g_loop

        ; Cap droit
        lda #GAUGE_CAP_R
        sta (ZP_SCR),y
        lda #COL_WHITE
        sta (ZP_COL),y
        rts

; ---------------------------------------------------------------------------
; debug_show_current_page : trace l'en-tête, le pied de page et le contenu statique
; ---------------------------------------------------------------------------
debug_show_current_page:
        jsr debug_clear_screen

        ; Ligne 1 et Ligne 23 : séparateurs bleus
        ldx #1
        ldy #0
        jsr set_row_addr
        ldy #0
        lda #'-'
-       sta (ZP_SCR),y
        lda #COL_BLUE
        sta (ZP_COL),y
        iny
        cpy #40
        bne -

        ldx #23
        ldy #0
        jsr set_row_addr
        ldy #0
        lda #'-'
-       sta (ZP_SCR),y
        lda #COL_BLUE
        sta (ZP_COL),y
        iny
        cpy #40
        bne -

        ; Ligne 24 : Navigation d'aide en bas
        ldx #24
        ldy #0
        jsr set_row_addr
        lda #<txt_dbg_footer
        sta ZP_SRC
        lda #>txt_dbg_footer
        sta ZP_SRC+1
        lda #COL_LGREEN
        ldx #40
        jsr dbg_print_fixed

        ; Dispatch selon la page
        lda dbg_cur_page
        beq .show_p0
        cmp #1
        beq .show_p1
        jmp .show_p2

.show_p0:
        jsr debug_draw_page0
        jmp .done_show
.show_p1:
        jsr debug_draw_page1
        jmp .done_show
.show_p2:
        jsr debug_draw_page2

.done_show:
        jsr debug_render_dynamic
        rts

; ---------------------------------------------------------------------------
; PAGE 0 : ARCHITECTURE & CONSOMMATION RAM
; ---------------------------------------------------------------------------
debug_draw_page0:
        ; Header Page 1
        ldx #0
        ldy #0
        jsr set_row_addr
        lda #<txt_hdr_page0
        sta ZP_SRC
        lda #>txt_hdr_page0
        sta ZP_SRC+1
        lda #COL_YELLOW
        ldx #40
        jsr dbg_print_fixed

        ; Ligne 3 : Titre CPU
        ldx #3
        ldy #1
        jsr set_row_addr
        lda #<txt_p0_cpu_h
        sta ZP_SRC
        lda #>txt_p0_cpu_h
        sta ZP_SRC+1
        lda #COL_CYAN
        ldx #30
        jsr dbg_print_fixed

        ; Ligne 4 : Specs CPU
        ldx #4
        ldy #2
        jsr set_row_addr
        lda #<txt_p0_cpu_1
        sta ZP_SRC
        lda #>txt_p0_cpu_1
        sta ZP_SRC+1
        lda #COL_WHITE
        ldx #37
        jsr dbg_print_fixed

        ; Ligne 5 : ROMs
        ldx #5
        ldy #2
        jsr set_row_addr
        lda #<txt_p0_cpu_2
        sta ZP_SRC
        lda #>txt_p0_cpu_2
        sta ZP_SRC+1
        lda #COL_GREY
        ldx #37
        jsr dbg_print_fixed

        ; Ligne 7 : Titre RAM Globale
        ldx #7
        ldy #1
        jsr set_row_addr
        lda #<txt_p0_ram_h
        sta ZP_SRC
        lda #>txt_p0_ram_h
        sta ZP_SRC+1
        lda #COL_CYAN
        ldx #32
        jsr dbg_print_fixed

        ; Ligne 8 : Valeur RAM Occupée
        ldx #8
        ldy #2
        jsr set_row_addr
        lda #<txt_p0_ram_val
        sta ZP_SRC
        lda #>txt_p0_ram_val
        sta ZP_SRC+1
        lda #COL_YELLOW
        ldx #36
        jsr dbg_print_fixed

        ; Ligne 9 : Jauge RAM globale (18 segments -> 9 pleins = 48%)
        ldx #9
        ldy #2
        jsr set_row_addr
        lda #COL_GREEN
        sta ZP_TMP
        lda #COL_DGREY
        sta ZP_BASE
        lda #9                          ; 9 / 18 = 50%
        ldx #18
        jsr dbg_draw_gauge

        ; Texte à côté de la jauge : " (33.2 KB LIBRE)"
        ldx #9
        ldy #23
        jsr set_row_addr
        lda #<txt_p0_ram_free
        sta ZP_SRC
        lda #>txt_p0_ram_free
        sta ZP_SRC+1
        lda #COL_LGREEN
        ldx #16
        jsr dbg_print_fixed

        ; Ligne 11 : Titre Détail Zones Mémoire
        ldx #11
        ldy #1
        jsr set_row_addr
        lda #<txt_p0_zones_h
        sta ZP_SRC
        lda #>txt_p0_zones_h
        sta ZP_SRC+1
        lda #COL_CYAN
        ldx #28
        jsr dbg_print_fixed

        ; Ligne 12 : PRG Zelda
        ldx #12
        ldy #2
        jsr set_row_addr
        lda #<txt_p0_prg_txt
        sta ZP_SRC
        lda #>txt_p0_prg_txt
        sta ZP_SRC+1
        lda #COL_WHITE
        ldx #37
        jsr dbg_print_fixed

        ; Ligne 13 : Jauge PRG (12 segments -> 3 pleins = 27%)
        ldx #13
        ldy #4
        jsr set_row_addr
        lda #COL_CYAN
        sta ZP_TMP
        lda #COL_DGREY
        sta ZP_BASE
        lda #3
        ldx #12
        jsr dbg_draw_gauge

        ldx #13
        ldy #19
        jsr set_row_addr
        lda #<txt_p0_prg_pct
        sta ZP_SRC
        lda #>txt_p0_prg_pct
        sta ZP_SRC+1
        lda #COL_CYAN
        ldx #18
        jsr dbg_print_fixed

        ; Ligne 14 : RAM Libre
        ldx #14
        ldy #2
        jsr set_row_addr
        lda #<txt_p0_free_txt
        sta ZP_SRC
        lda #>txt_p0_free_txt
        sta ZP_SRC+1
        lda #COL_WHITE
        ldx #37
        jsr dbg_print_fixed

        ; Ligne 15 : Jauge RAM Libre (12 segments -> 6 pleins = 52%)
        ldx #15
        ldy #4
        jsr set_row_addr
        lda #COL_LGREEN
        sta ZP_TMP
        lda #COL_DGREY
        sta ZP_BASE
        lda #6
        ldx #12
        jsr dbg_draw_gauge

        ldx #15
        ldy #19
        jsr set_row_addr
        lda #<txt_p0_free_pct
        sta ZP_SRC
        lda #>txt_p0_free_pct
        sta ZP_SRC+1
        lda #COL_LGREEN
        ldx #18
        jsr dbg_print_fixed

        ; Ligne 16 : Titre Vidéo
        ldx #16
        ldy #2
        jsr set_row_addr
        lda #<txt_p0_vic_h
        sta ZP_SRC
        lda #>txt_p0_vic_h
        sta ZP_SRC+1
        lda #COL_WHITE
        ldx #35
        jsr dbg_print_fixed

        ; Lignes 17..21 : Adresses VIC-II
        ldx #17
        ldy #3
        jsr set_row_addr
        lda #<txt_p0_v1
        sta ZP_SRC
        lda #>txt_p0_v1
        sta ZP_SRC+1
        lda #COL_GREY
        ldx #36
        jsr dbg_print_fixed

        ldx #18
        ldy #3
        jsr set_row_addr
        lda #<txt_p0_v2
        sta ZP_SRC
        lda #>txt_p0_v2
        sta ZP_SRC+1
        lda #COL_GREY
        ldx #36
        jsr dbg_print_fixed

        ldx #19
        ldy #3
        jsr set_row_addr
        lda #<txt_p0_v3
        sta ZP_SRC
        lda #>txt_p0_v3
        sta ZP_SRC+1
        lda #COL_GREY
        ldx #36
        jsr dbg_print_fixed

        ldx #20
        ldy #3
        jsr set_row_addr
        lda #<txt_p0_v4
        sta ZP_SRC
        lda #>txt_p0_v4
        sta ZP_SRC+1
        lda #COL_GREY
        ldx #36
        jsr dbg_print_fixed

        ldx #21
        ldy #3
        jsr set_row_addr
        lda #<txt_p0_v5
        sta ZP_SRC
        lda #>txt_p0_v5
        sta ZP_SRC+1
        lda #COL_GREY
        ldx #36
        jsr dbg_print_fixed
        rts

; ---------------------------------------------------------------------------
; PAGE 1 : PROCESSEURS & LIMITES MATÉRIELLES (VIC-II & SID)
; ---------------------------------------------------------------------------
debug_draw_page1:
        ; Header Page 2
        ldx #0
        ldy #0
        jsr set_row_addr
        lda #<txt_hdr_page1
        sta ZP_SRC
        lda #>txt_hdr_page1
        sta ZP_SRC+1
        lda #COL_YELLOW
        ldx #40
        jsr dbg_print_fixed

        ; Ligne 3 : Titre Sprites
        ldx #3
        ldy #1
        jsr set_row_addr
        lda #<txt_p1_spr_h
        sta ZP_SRC
        lda #>txt_p1_spr_h
        sta ZP_SRC+1
        lda #COL_CYAN
        ldx #38
        jsr dbg_print_fixed

        ; Ligne 4 : Budget Sprites
        ldx #4
        ldy #2
        jsr set_row_addr
        lda #<txt_p1_spr_val
        sta ZP_SRC
        lda #>txt_p1_spr_val
        sta ZP_SRC+1
        lda #COL_YELLOW
        ldx #34
        jsr dbg_print_fixed

        ; Ligne 5 : Jauge 8 sprites matériels (6 pleins, 2 vides)
        ldx #5
        ldy #2
        jsr set_row_addr
        lda #COL_YELLOW
        sta ZP_TMP
        lda #COL_DGREY
        sta ZP_BASE
        lda #6
        ldx #8
        jsr dbg_draw_gauge

        ldx #5
        ldy #13
        jsr set_row_addr
        lda #<txt_p1_spr_rem
        sta ZP_SRC
        lda #>txt_p1_spr_rem
        sta ZP_SRC+1
        lda #COL_LGREEN
        ldx #25
        jsr dbg_print_fixed

        ; Lignes 6..9 : Détail des 8 sprites
        ldx #6
        ldy #2
        jsr set_row_addr
        lda #<txt_p1_s0
        sta ZP_SRC
        lda #>txt_p1_s0
        sta ZP_SRC+1
        lda #COL_WHITE
        ldx #37
        jsr dbg_print_fixed

        ldx #7
        ldy #2
        jsr set_row_addr
        lda #<txt_p1_s1
        sta ZP_SRC
        lda #>txt_p1_s1
        sta ZP_SRC+1
        lda #COL_WHITE
        ldx #37
        jsr dbg_print_fixed

        ldx #8
        ldy #2
        jsr set_row_addr
        lda #<txt_p1_s2
        sta ZP_SRC
        lda #>txt_p1_s2
        sta ZP_SRC+1
        lda #COL_WHITE
        ldx #37
        jsr dbg_print_fixed

        ldx #9
        ldy #2
        jsr set_row_addr
        lda #<txt_p1_s3
        sta ZP_SRC
        lda #>txt_p1_s3
        sta ZP_SRC+1
        lda #COL_GREY
        ldx #37
        jsr dbg_print_fixed

        ; Ligne 11 : Titre Raster CPU
        ldx #11
        ldy #1
        jsr set_row_addr
        lda #<txt_p1_rast_h
        sta ZP_SRC
        lda #>txt_p1_rast_h
        sta ZP_SRC+1
        lda #COL_CYAN
        ldx #37
        jsr dbg_print_fixed

        ; Ligne 12 : Budget trame
        ldx #12
        ldy #2
        jsr set_row_addr
        lda #<txt_p1_rast_lim
        sta ZP_SRC
        lda #>txt_p1_rast_lim
        sta ZP_SRC+1
        lda #COL_WHITE
        ldx #37
        jsr dbg_print_fixed

        ; Ligne 15 : Résolution VIC-II
        ldx #15
        ldy #2
        jsr set_row_addr
        lda #<txt_p1_res
        sta ZP_SRC
        lda #>txt_p1_res
        sta ZP_SRC+1
        lda #COL_GREY
        ldx #37
        jsr dbg_print_fixed

        ; Ligne 17 : Titre SID
        ldx #17
        ldy #1
        jsr set_row_addr
        lda #<txt_p1_sid_h
        sta ZP_SRC
        lda #>txt_p1_sid_h
        sta ZP_SRC+1
        lda #COL_CYAN
        ldx #38
        jsr dbg_print_fixed

        ; Ligne 18 : Voix SID
        ldx #18
        ldy #2
        jsr set_row_addr
        lda #<txt_p1_sid_val
        sta ZP_SRC
        lda #>txt_p1_sid_val
        sta ZP_SRC+1
        lda #COL_YELLOW
        ldx #34
        jsr dbg_print_fixed

        ; Ligne 19 : Jauge 3 Voix SID (6 segments -> 2 pleins, 4 vides)
        ldx #19
        ldy #2
        jsr set_row_addr
        lda #COL_CYAN
        sta ZP_TMP
        lda #COL_DGREY
        sta ZP_BASE
        lda #2
        ldx #6
        jsr dbg_draw_gauge

        ldx #19
        ldy #11
        jsr set_row_addr
        lda #<txt_p1_sid_rem
        sta ZP_SRC
        lda #>txt_p1_sid_rem
        sta ZP_SRC+1
        lda #COL_LGREEN
        ldx #27
        jsr dbg_print_fixed

        ; Lignes 20..22 : Détail des voix
        ldx #20
        ldy #2
        jsr set_row_addr
        lda #<txt_p1_v1
        sta ZP_SRC
        lda #>txt_p1_v1
        sta ZP_SRC+1
        lda #COL_WHITE
        ldx #37
        jsr dbg_print_fixed

        ldx #21
        ldy #2
        jsr set_row_addr
        lda #<txt_p1_v2
        sta ZP_SRC
        lda #>txt_p1_v2
        sta ZP_SRC+1
        lda #COL_GREY
        ldx #37
        jsr dbg_print_fixed

        ldx #22
        ldy #2
        jsr set_row_addr
        lda #<txt_p1_v3
        sta ZP_SRC
        lda #>txt_p1_v3
        sta ZP_SRC+1
        lda #COL_GREY
        ldx #37
        jsr dbg_print_fixed
        rts

; ---------------------------------------------------------------------------
; PAGE 2 : TÉLÉMÉTRIE DU JEU & COMBAT EN DIRECT
; ---------------------------------------------------------------------------
debug_draw_page2:
        ; Header Page 3
        ldx #0
        ldy #0
        jsr set_row_addr
        lda #<txt_hdr_page2
        sta ZP_SRC
        lda #>txt_hdr_page2
        sta ZP_SRC+1
        lda #COL_YELLOW
        ldx #40
        jsr dbg_print_fixed

        ; Ligne 3 : Titre Link
        ldx #3
        ldy #1
        jsr set_row_addr
        lda #<txt_p2_link_h
        sta ZP_SRC
        lda #>txt_p2_link_h
        sta ZP_SRC+1
        lda #COL_CYAN
        ldx #32
        jsr dbg_print_fixed

        ; Ligne 9 : Titre Ressources
        ldx #9
        ldy #1
        jsr set_row_addr
        lda #<txt_p2_res_h
        sta ZP_SRC
        lda #>txt_p2_res_h
        sta ZP_SRC+1
        lda #COL_CYAN
        ldx #32
        jsr dbg_print_fixed

        ; Ligne 14 : Titre Monstres
        ldx #14
        ldy #1
        jsr set_row_addr
        lda #<txt_p2_mon_h
        sta ZP_SRC
        lda #>txt_p2_mon_h
        sta ZP_SRC+1
        lda #COL_CYAN
        ldx #32
        jsr dbg_print_fixed

        ; Ligne 21 : Titre Moteur
        ldx #21
        ldy #1
        jsr set_row_addr
        lda #<txt_p2_eng_h
        sta ZP_SRC
        lda #>txt_p2_eng_h
        sta ZP_SRC+1
        lda #COL_LGREEN
        ldx #38
        jsr dbg_print_fixed

        ; Ligne 22 : Scrolling
        ldx #22
        ldy #2
        jsr set_row_addr
        lda #<txt_p2_eng_sub
        sta ZP_SRC
        lda #>txt_p2_eng_sub
        sta ZP_SRC+1
        lda #COL_GREY
        ldx #37
        jsr dbg_print_fixed
        rts

; ---------------------------------------------------------------------------
; debug_render_dynamic : rafraîchit les valeurs dynamiques selon la page
; ---------------------------------------------------------------------------
debug_render_dynamic:
        lda dbg_cur_page
        beq .dyn_page0
        cmp #1
        beq .dyn_page1
        jmp .dyn_page2

.dyn_page0:
        rts                             ; Page 0 est entièrement statique

.dyn_page1:
        ; Rafraîchit Raster et Charge CPU en temps réel
        ; Ligne 13 : Ligne raster lue de $D012
        ldx #13
        ldy #2
        jsr set_row_addr
        lda #<txt_p1_rast_lbl
        sta ZP_SRC
        lda #>txt_p1_rast_lbl
        sta ZP_SRC+1
        lda #COL_WHITE
        ldx #24
        jsr dbg_print_fixed

        lda VIC_RASTER
        sta dbg_val
        lda #0
        sta dbg_val+1
        ldx #13
        ldy #26
        jsr set_row_addr
        jsr dbg_put_val_3d

        ; Ligne 14 : Jauge de charge CPU (0..16 segments)
        ldx #14
        ldy #2
        jsr set_row_addr
        lda #<txt_p1_load_lbl
        sta ZP_SRC
        lda #>txt_p1_load_lbl
        sta ZP_SRC+1
        lda #COL_WHITE
        ldx #13
        jsr dbg_print_fixed

        ; Calcule le nombre de segments (raster / 16)
        lda VIC_RASTER
        lsr
        lsr
        lsr
        lsr                             ; 0..16
        cmp #16
        bcc +
        lda #16
+       sta dbg_tmp

        ldx #14
        ldy #15
        jsr set_row_addr
        lda #COL_GREEN
        cmp #12
        bcc ++
        lda #COL_LRED                   ; rouge si charge haute
++      sta ZP_TMP
        lda #COL_DGREY
        sta ZP_BASE
        lda dbg_tmp
        ldx #16
        jsr dbg_draw_gauge
        rts

.dyn_page2:
        ; -------------------------------------------------------------------
        ; TÉLÉMÉTRIE LINK (Lignes 4..7)
        ; -------------------------------------------------------------------
        ; Ligne 4 : " POSITION: X=... Y=...   SALLE: (.,.)"
        ldx #4
        ldy #2
        jsr set_row_addr
        lda #<txt_p2_link_pos
        sta ZP_SRC
        lda #>txt_p2_link_pos
        sta ZP_SRC+1
        lda #COL_WHITE
        ldx #37
        jsr dbg_print_fixed

        ; Écrit X Link
        lda player_x
        sta dbg_val
        lda #0
        sta dbg_val+1
        ldx #4
        ldy #14
        jsr set_row_addr
        jsr dbg_put_val_3d

        ; Écrit Y Link
        lda player_y
        sta dbg_val
        ldx #4
        ldy #21
        jsr set_row_addr
        jsr dbg_put_val_3d

        ; Salle (rx, ry)
        ldx #4
        ldy #33
        jsr set_row_addr
        lda current_room_x
        clc
        adc #'0'
        ldy #0
        sta (ZP_SCR),y
        lda current_room_y
        clc
        adc #'0'
        ldy #2
        sta (ZP_SCR),y

        ; Ligne 5 : Direction Link
        ldx #5
        ldy #2
        jsr set_row_addr
        lda #<txt_p2_link_dir
        sta ZP_SRC
        lda #>txt_p2_link_dir
        sta ZP_SRC+1
        lda #COL_GREY
        ldx #37
        jsr dbg_print_fixed

        lda player_dir
        and #3
        tax
        lda txt_dir_letters,x
        ldx #5
        ldy #13
        jsr set_row_addr
        ldy #0
        sta (ZP_SCR),y

        ; Ligne 6 : Cœurs et Jauge de vie
        ldx #6
        ldy #2
        jsr set_row_addr
        lda #<txt_p2_link_hp
        sta ZP_SRC
        lda #>txt_p2_link_hp
        sta ZP_SRC+1
        lda #COL_LRED
        ldx #22
        jsr dbg_print_fixed

        lda hud_cur_hearts
        clc
        adc #'0'
        ldy #10
        sta (ZP_SCR),y
        lda hud_max_hearts
        clc
        adc #'0'
        ldy #12
        sta (ZP_SCR),y

        ; Jauge de coeurs (3 coeurs)
        ldx #6
        ldy #25
        jsr set_row_addr
        ldx #0
.hp_hearts:
        cpx hud_cur_hearts
        bcs .h_empty
        lda #HUD_HEART_FULL             ; 96
        sta (ZP_SCR),y
        lda #COL_LRED
        sta (ZP_COL),y
        jmp .h_next
.h_empty:
        lda #HUD_HEART_EMPTY            ; 97
        sta (ZP_SCR),y
        lda #COL_DGREY
        sta (ZP_COL),y
.h_next:
        iny
        inx
        cpx #3
        bne .hp_hearts

        ; Ligne 7 : Équipement [X] EPEE  [A] ITEM
        ldx #7
        ldy #2
        jsr set_row_addr
        lda #<txt_p2_link_eq
        sta ZP_SRC
        lda #>txt_p2_link_eq
        sta ZP_SRC+1
        lda #COL_YELLOW
        ldx #26
        jsr dbg_print_fixed

        lda hud_selected_b
        asl
        asl
        tax
        ldy #0
-       lda b_item_names,x
        sta (ZP_SCR),y
        lda #COL_YELLOW
        sta (ZP_COL),y
        inx
        iny
        cpy #4
        bne -

        ; -------------------------------------------------------------------
        ; RESSOURCES DU JOUEUR (Lignes 10..12)
        ; -------------------------------------------------------------------
        ; Ligne 10 : Rubis
        ldx #10
        ldy #2
        jsr set_row_addr
        lda #<txt_p2_rub
        sta ZP_SRC
        lda #>txt_p2_rub
        sta ZP_SRC+1
        lda #COL_WHITE
        ldx #15
        jsr dbg_print_fixed

        lda hud_rupees
        sta dbg_val
        lda #0
        sta dbg_val+1
        ldx #10
        ldy #10
        jsr set_row_addr
        jsr dbg_put_val_3d

        ; Jauge Rubis (10 segments)
        lda hud_rupees
        lsr
        lsr
        lsr
        lsr
        cmp #10
        bcc +
        lda #10
+       sta dbg_tmp
        ldx #10
        ldy #18
        jsr set_row_addr
        lda #COL_GREEN
        sta ZP_TMP
        lda #COL_DGREY
        sta ZP_BASE
        lda dbg_tmp
        ldx #10
        jsr dbg_draw_gauge

        ; Ligne 11 : Bombes
        ldx #11
        ldy #2
        jsr set_row_addr
        lda #<txt_p2_bom
        sta ZP_SRC
        lda #>txt_p2_bom
        sta ZP_SRC+1
        lda #COL_WHITE
        ldx #15
        jsr dbg_print_fixed

        lda hud_bombs
        clc
        adc #'0'
        ldx #11
        ldy #11
        jsr set_row_addr
        ldy #0
        sta (ZP_SCR),y

        ; Jauge Bombes (8 segments = 8 bombes max)
        lda hud_bombs
        cmp #8
        bcc +
        lda #8
+       sta dbg_tmp
        ldx #11
        ldy #18
        jsr set_row_addr
        lda #COL_ORANGE
        sta ZP_TMP
        lda #COL_DGREY
        sta ZP_BASE
        lda dbg_tmp
        ldx #8
        jsr dbg_draw_gauge

        ; Ligne 12 : Clefs
        ldx #12
        ldy #2
        jsr set_row_addr
        lda #<txt_p2_key
        sta ZP_SRC
        lda #>txt_p2_key
        sta ZP_SRC+1
        lda #COL_WHITE
        ldx #15
        jsr dbg_print_fixed

        lda hud_keys
        clc
        adc #'0'
        ldx #12
        ldy #11
        jsr set_row_addr
        ldy #0
        sta (ZP_SCR),y

        ; -------------------------------------------------------------------
        ; MONSTRES EN DIRECT (Lignes 15..19)
        ; -------------------------------------------------------------------
        ; Ennemi 0 : Ligne 15
        ldx #15
        ldy #2
        jsr set_row_addr
        lda #<txt_p2_e0_lbl
        sta ZP_SRC
        lda #>txt_p2_e0_lbl
        sta ZP_SRC+1
        lda #COL_WHITE
        ldx #37
        jsr dbg_print_fixed

        lda en_type+0
        asl
        asl
        tax
        ldy #5
-       lda txt_en_types,x
        sta (ZP_SCR),y
        inx
        iny
        cpy #9
        bne -

        lda en_hp+0
        clc
        adc #'0'
        ldy #14
        sta (ZP_SCR),y

        ; Jauge PV Ennemi 0 (Ligne 16)
        ldx #16
        ldy #6
        jsr set_row_addr
        lda #<txt_p2_hp_lbl
        sta ZP_SRC
        lda #>txt_p2_hp_lbl
        sta ZP_SRC+1
        lda #COL_GREY
        ldx #5
        jsr dbg_print_fixed

        lda en_hp+0
        asl                             ; * 2
        cmp #6
        bcc +
        lda #6
+       sta dbg_tmp
        ldx #16
        ldy #11
        jsr set_row_addr
        lda #COL_LRED
        sta ZP_TMP
        lda #COL_DGREY
        sta ZP_BASE
        lda dbg_tmp
        ldx #6
        jsr dbg_draw_gauge

        ; Ennemi 1 : Ligne 17
        ldx #17
        ldy #2
        jsr set_row_addr
        lda #<txt_p2_e1_lbl
        sta ZP_SRC
        lda #>txt_p2_e1_lbl
        sta ZP_SRC+1
        lda #COL_WHITE
        ldx #37
        jsr dbg_print_fixed

        lda en_type+1
        asl
        asl
        tax
        ldy #5
-       lda txt_en_types,x
        sta (ZP_SCR),y
        inx
        iny
        cpy #9
        bne -

        lda en_hp+1
        clc
        adc #'0'
        ldy #14
        sta (ZP_SCR),y

        ; Jauge PV Ennemi 1 (Ligne 18)
        ldx #18
        ldy #6
        jsr set_row_addr
        lda #<txt_p2_hp_lbl
        sta ZP_SRC
        lda #>txt_p2_hp_lbl
        sta ZP_SRC+1
        lda #COL_GREY
        ldx #5
        jsr dbg_print_fixed

        lda en_hp+1
        asl                             ; * 2
        cmp #6
        bcc +
        lda #6
+       sta dbg_tmp
        ldx #18
        ldy #11
        jsr set_row_addr
        lda #COL_LRED
        sta ZP_TMP
        lda #COL_DGREY
        sta ZP_BASE
        lda dbg_tmp
        ldx #6
        jsr dbg_draw_gauge

        ; Ligne 19 : Projectile
        ldx #19
        ldy #2
        jsr set_row_addr
        lda #<txt_p2_proj
        sta ZP_SRC
        lda #>txt_p2_proj
        sta ZP_SRC+1
        lda #COL_GREY
        ldx #37
        jsr dbg_print_fixed
        rts

; ---------------------------------------------------------------------------
; dbg_put_val_3d : écrit dbg_val sous forme de 3 chiffres décimaux
; ---------------------------------------------------------------------------
dbg_put_val_3d:
        ldy #'0'
.sub_100:
        sec
        lda dbg_val
        sbc #100
        sta dbg_tmp
        lda dbg_val+1
        sbc #0
        bcc .c_done
        sta dbg_val+1
        lda dbg_tmp
        sta dbg_val
        iny
        jmp .sub_100
.c_done:
        tya
        ldy #0
        sta (ZP_SCR),y
        iny

        lda #'0'
        sta dbg_tmp
.sub_10:
        sec
        lda dbg_val
        sbc #10
        bcc .d_done
        sta dbg_val
        inc dbg_tmp
        jmp .sub_10
.d_done:
        lda dbg_tmp
        sta (ZP_SCR),y
        iny

        lda dbg_val
        clc
        adc #'0'
        sta (ZP_SCR),y
        rts

; ---------------------------------------------------------------------------
; Textes et libellés du moniteur multi-pages
; ---------------------------------------------------------------------------
txt_dbg_footer:
        !text " [JOY G/D] PAGE   [A/X] SUIVANT   [B] JEU"

; --- En-têtes de pages ---
txt_hdr_page0:
        !text "<<< PAGE 1/3: SYSTEME & MEMOIRE >>>     "
txt_hdr_page1:
        !text "<<< PAGE 2/3: VIC-II & MATERIEL >>>     "
txt_hdr_page2:
        !text "<<< PAGE 3/3: TELEMETRIE DE JEU >>>     "

; --- Textes Page 0 ---
txt_p0_cpu_h:
        !text "[PROCESSEUR & ARCHITECTURE C64]"
txt_p0_cpu_1:
        !text " CPU: MOS 6510 @ 0.985 MHZ  PAL 50 HZ"
txt_p0_cpu_2:
        !text " ROM: BASIC $A000  CHAR $D000  KERN $E000"
txt_p0_ram_h:
        !text "[ALLOCATION RAM GLOBALE : 64 KO]"
txt_p0_ram_val:
        !text " TOTAL UTILISE : 30.8 KB / 64 KB (48%)"
txt_p0_ram_free:
        !text "(33.2 KB LIBRE) "
txt_p0_zones_h:
        !text "[DETAIL DES ZONES MEMOIRES] "
txt_p0_prg_txt:
        !text " 1. CODE & DONNEES PRG     : 17.5 KB "
txt_p0_prg_pct:
        !text "(27% DE LA RAM)   "
txt_p0_free_txt:
        !text " 2. MEMOIRE LIBRE LE JEU   : 33.2 KB "
txt_p0_free_pct:
        !text "(52% DE LA RAM)   "
txt_p0_vic_h:
        !text " 3. RESSOURCES GRAPHIQUES VIC-II  "
txt_p0_v1:
        !text "    ECRAN / HUD    : $0400 (1000 B) "
txt_p0_v2:
        !text "    SPRITES B0     : $0840 (1984 B) "
txt_p0_v3:
        !text "    CHARSET 2K     : $2000 (2048 B) "
txt_p0_v4:
        !text "    SPRITES ENNEMI : $38C0 (1216 B) "
txt_p0_v5:
        !text "    MONDE 3X3      : $2800 (1800 B) "

; --- Textes Page 1 ---
txt_p1_spr_h:
        !text "[VIC-II 8565 : 8 SPRITES MATERIELS]   "
txt_p1_spr_val:
        !text " BUDGET SPRITES: 6 / 8 ACTIFS (75%)"
txt_p1_spr_rem:
        !text "(2 DISPONIBLES EN RESERVE)"
txt_p1_s0:
        !text "  S0: LINK (JOUEUR)  S1: EPEE (ATTACK)"
txt_p1_s1:
        !text "  S2: OBJET ARME     S3: ENNEMI 0     "
txt_p1_s2:
        !text "  S4: ENNEMI 1       S5: PROJECTILE   "
txt_p1_s3:
        !text "  S6-S7: SPARES / BOMBE 3X3 EXPLOSION "
txt_p1_rast_h:
        !text "[TEMPS DE CALCUL CPU (RASTER 50 HZ)] "
txt_p1_rast_lim:
        !text " BUDGET TRAME: 312 LIGNES PAL (20 MS)"
txt_p1_rast_lbl:
        !text " LIGNE RASTER ACTUELLE :                "
txt_p1_load_lbl:
        !text " CHARGE CPU : "
txt_p1_res:
        !text " RESOLUTION : 160X200 MC / 320X200 HRES "
txt_p1_sid_h:
        !text "[PUCE SONORE SID 8580 : 3 VOIX MAX]   "
txt_p1_sid_val:
        !text " CANAUX ACTIFS : 1 / 3 VOIX  (33%) "
txt_p1_sid_rem:
        !text "(2 LIBRES POUR MUSIQUE)    "
txt_p1_v1:
        !text "  V1: SFX (BRUITAGES, TIRS, IMPACTS)  "
txt_p1_v2:
        !text "  V2: LIBRE (CANAL RESERVE MONDE)     "
txt_p1_v3:
        !text "  V3: LIBRE (CANAL RESERVE BASSE)     "

; --- Textes Page 2 ---
txt_p2_link_h:
        !text "[STATUT DU JOUEUR : LINK]       "
txt_p2_link_pos:
        !text " POSITION: X=... Y=...   SALLE: (.,.) "
txt_p2_link_dir:
        !text " DIRECTION: ....   MOUVEMENT : FLUIDE "
txt_p2_link_hp:
        !text " SANTE: ./. COEURS    "
txt_p2_link_eq:
        !text " EQUIPEMENT: [X] EPEE  [A] "
txt_p2_res_h:
        !text "[RESSOURCES & BUTIN]            "
txt_p2_rub:
        !text " RUBIS : .../255"
txt_p2_bom:
        !text " BOMBES: ./8    "
txt_p2_key:
        !text " CLEFS : ./9    "
txt_p2_mon_h:
        !text "[MONSTRES ACTIFS DANS LA SALLE] "
txt_p2_e0_lbl:
        !text " E0: .... HP: .  POS: (SALLE ACTIVE) "
txt_p2_hp_lbl:
        !text "VIE: "
txt_p2_e1_lbl:
        !text " E1: .... HP: .  POS: (SALLE ACTIVE) "
txt_p2_proj:
        !text " PROJECTILE : ACTIF   COLLISION: ON   "
txt_p2_eng_h:
        !text "[MOTEUR DE JEU C64 : 50 FPS PAL FLUIDE]"
txt_p2_eng_sub:
        !text " TRANSITIONS SALLES MATRICIELLES: ON  "

txt_dir_letters:
        !text "DULR"
txt_en_types:
        !text "NONE"
        !text "OCTO"
        !text "MOBL"
