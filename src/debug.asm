; ---------------------------------------------------------------------------
; debug.asm : Écran de diagnostic matériel et mémoire (Touche 'D')
;
; Affiche en temps réel :
;   - Spécifications & limites de la machine (CPU 6510, VIC-II, SID)
;   - Cartographie mémoire complète et mémoire RAM consommée / libre
;   - Budget et statut des 8 sprites matériels
;   - Télémétrie en direct (coordonnées de Link, salle, ennemis, cœurs, raster)
; ---------------------------------------------------------------------------

dbg_anim_tick:          !byte 0
dbg_val:                !word 0
prev_game_state:        !byte 0

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

        ; Efface les 1000 octets de l'écran en noir/espaces
        ldx #0
.clr_dbg:
        lda #32
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
        bne .clr_dbg

        ; Affiche tout le décor statique (titres, limites machine, mémoire)
        jsr debug_draw_static

        ; Affiche la télémétrie temps réel
        jsr debug_render_dynamic
        rts

; ---------------------------------------------------------------------------
; debug_update : boucle d'exécution de l'écran de debug
; ---------------------------------------------------------------------------
debug_update:
        ; Rafraîchit les valeurs dynamiques à chaque trame
        jsr debug_render_dynamic

        ; Animation du message clignotant en bas
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

        ; Touche 'D', Bouton A (Fire) ou Touche Espace : quitte le debug
        lda key_d_pressed
        bne .do_close
        lda btn_a_pressed
        bne .do_close
        lda btn_c_pressed
        bne .do_close
        rts

.do_close:
        jsr close_debug
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

        ; Couleurs normales du jeu
        lda #MAP_BG_COLOR
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
; debug_draw_static : trace les 20 premières lignes d'informations fixes
; ---------------------------------------------------------------------------
debug_draw_static:
        ; Ligne 0 : Titre
        ldx #0
-       lda txt_dbg_title,x
        sta SCREEN_RAM + 0,x
        lda #COL_YELLOW
        sta COLOR_RAM + 0,x
        inx
        cpx #40
        bne -

        ; Ligne 1 : CPU Header
        ldx #0
-       lda txt_dbg_cpu_h,x
        sta SCREEN_RAM + 40,x
        lda #COL_CYAN
        sta COLOR_RAM + 40,x
        inx
        cpx #38
        bne -

        ; Ligne 2 : CPU Specs
        ldx #0
-       lda txt_dbg_cpu_1,x
        sta SCREEN_RAM + 80,x
        lda #COL_WHITE
        sta COLOR_RAM + 80,x
        inx
        cpx #38
        bne -

        ; Ligne 3 : ROM Specs
        ldx #0
-       lda txt_dbg_cpu_2,x
        sta SCREEN_RAM + 120,x
        lda #COL_GREY
        sta COLOR_RAM + 120,x
        inx
        cpx #38
        bne -

        ; Ligne 4 : Memory Header
        ldx #0
-       lda txt_dbg_mem_h,x
        sta SCREEN_RAM + 160,x
        lda #COL_CYAN
        sta COLOR_RAM + 160,x
        inx
        cpx #28
        bne -

        ; Lignes 5..11 : Détail Mémoire
        ldx #0
-       lda txt_dbg_mem_1,x
        sta SCREEN_RAM + 200,x
        lda #COL_WHITE
        sta COLOR_RAM + 200,x
        inx
        cpx #37
        bne -

        ldx #0
-       lda txt_dbg_mem_2,x
        sta SCREEN_RAM + 240,x
        lda #COL_LGREEN
        sta COLOR_RAM + 240,x
        inx
        cpx #37
        bne -

        ldx #0
-       lda txt_dbg_mem_3,x
        sta SCREEN_RAM + 280,x
        lda #COL_WHITE
        sta COLOR_RAM + 280,x
        inx
        cpx #37
        bne -

        ldx #0
-       lda txt_dbg_mem_4,x
        sta SCREEN_RAM + 320,x
        lda #COL_WHITE
        sta COLOR_RAM + 320,x
        inx
        cpx #37
        bne -

        ldx #0
-       lda txt_dbg_mem_5,x
        sta SCREEN_RAM + 360,x
        lda #COL_WHITE
        sta COLOR_RAM + 360,x
        inx
        cpx #37
        bne -

        ldx #0
-       lda txt_dbg_mem_6,x
        sta SCREEN_RAM + 400,x
        lda #COL_WHITE
        sta COLOR_RAM + 400,x
        inx
        cpx #37
        bne -

        ldx #0
-       lda txt_dbg_mem_7,x
        sta SCREEN_RAM + 440,x
        lda #COL_WHITE
        sta COLOR_RAM + 440,x
        inx
        cpx #37
        bne -

        ; Ligne 12 : VIC-II Header
        ldx #0
-       lda txt_dbg_vic_h,x
        sta SCREEN_RAM + 480,x
        lda #COL_CYAN
        sta COLOR_RAM + 480,x
        inx
        cpx #38
        bne -

        ; Lignes 13..15 : VIC-II Details
        ldx #0
-       lda txt_dbg_vic_1,x
        sta SCREEN_RAM + 520,x
        lda #COL_YELLOW
        sta COLOR_RAM + 520,x
        inx
        cpx #39
        bne -

        ldx #0
-       lda txt_dbg_vic_2,x
        sta SCREEN_RAM + 560,x
        lda #COL_GREY
        sta COLOR_RAM + 560,x
        inx
        cpx #38
        bne -

        ldx #0
-       lda txt_dbg_vic_3,x
        sta SCREEN_RAM + 600,x
        lda #COL_GREY
        sta COLOR_RAM + 600,x
        inx
        cpx #38
        bne -

        ; Ligne 16 : SID Header
        ldx #0
-       lda txt_dbg_sid_h,x
        sta SCREEN_RAM + 640,x
        lda #COL_CYAN
        sta COLOR_RAM + 640,x
        inx
        cpx #25
        bne -

        ; Lignes 17..18 : SID Details
        ldx #0
-       lda txt_dbg_sid_1,x
        sta SCREEN_RAM + 680,x
        lda #COL_WHITE
        sta COLOR_RAM + 680,x
        inx
        cpx #38
        bne -

        ldx #0
-       lda txt_dbg_sid_2,x
        sta SCREEN_RAM + 720,x
        lda #COL_GREY
        sta COLOR_RAM + 720,x
        inx
        cpx #38
        bne -

        ; Ligne 19 : Live Header
        ldx #0
-       lda txt_dbg_live_h,x
        sta SCREEN_RAM + 760,x
        lda #COL_CYAN
        sta COLOR_RAM + 760,x
        inx
        cpx #30
        bne -

        ; Ligne 24 : Prompt bas
        ldx #0
-       lda txt_dbg_footer,x
        sta SCREEN_RAM + 960 + 2,x
        lda #COL_LGREEN
        sta COLOR_RAM + 960 + 2,x
        inx
        cpx #36
        bne -
        rts

; ---------------------------------------------------------------------------
; debug_render_dynamic : met à jour les lignes 20 à 23 avec les données du jeu
; ---------------------------------------------------------------------------
debug_render_dynamic:
        ; -------------------------------------------------------------------
        ; Ligne 20 : LINK: X=... Y=... DIR=... ROOM=(.,.)
        ; -------------------------------------------------------------------
        ldx #0
-       lda txt_dyn_link,x
        sta SCREEN_RAM + 800,x
        lda #COL_YELLOW
        sta COLOR_RAM + 800,x
        inx
        cpx #28
        bne -

        ; X de Link (3 chiffres)
        lda player_x
        sta dbg_val
        lda player_x+1
        sta dbg_val+1
        lda #< (SCREEN_RAM + 800 + 8)
        sta ZP_SCR
        lda #> (SCREEN_RAM + 800 + 8)
        sta ZP_SCR+1
        jsr dbg_put_val_3d

        ; Y de Link (3 chiffres)
        lda player_y
        sta dbg_val
        lda #0
        sta dbg_val+1
        lda #< (SCREEN_RAM + 800 + 16)
        sta ZP_SCR
        lda #> (SCREEN_RAM + 800 + 16)
        sta ZP_SCR+1
        jsr dbg_put_val_3d

        ; Direction (D, U, L, R)
        ldx player_dir
        lda txt_dir_letters,x
        sta SCREEN_RAM + 800 + 24

        ; Salle (x, y)
        lda current_room_x
        clc
        adc #'0'
        sta SCREEN_RAM + 800 + 33
        lda current_room_y
        clc
        adc #'0'
        sta SCREEN_RAM + 800 + 35

        ; -------------------------------------------------------------------
        ; Ligne 21 : LIFE: ./.  RUPEES: ..  BOMBS: ..  KEYS: ..
        ; -------------------------------------------------------------------
        ldx #0
-       lda txt_dyn_status,x
        sta SCREEN_RAM + 840,x
        lda #COL_YELLOW
        sta COLOR_RAM + 840,x
        inx
        cpx #38
        bne -

        ; Cœurs actuels / max
        lda hud_cur_hearts
        clc
        adc #'0'
        sta SCREEN_RAM + 840 + 7
        lda hud_max_hearts
        clc
        adc #'0'
        sta SCREEN_RAM + 840 + 9

        ; Rubis (2 chiffres)
        lda #< (SCREEN_RAM + 840 + 20)
        sta ZP_SCR
        lda #> (SCREEN_RAM + 840 + 20)
        sta ZP_SCR+1
        lda hud_rupees
        jsr dbg_put_dec2

        ; Bombes (2 chiffres)
        lda #< (SCREEN_RAM + 840 + 30)
        sta ZP_SCR
        lda #> (SCREEN_RAM + 840 + 30)
        sta ZP_SCR+1
        lda hud_bombs
        jsr dbg_put_dec2

        ; -------------------------------------------------------------------
        ; Ligne 22 : E0: .... HP=. (...,..)  E1: .... HP=.
        ; -------------------------------------------------------------------
        ldx #0
-       lda txt_dyn_enemies,x
        sta SCREEN_RAM + 880,x
        lda #COL_YELLOW
        sta COLOR_RAM + 880,x
        inx
        cpx #38
        bne -

        ; Nom Ennemi 0
        lda en_type
        asl
        asl                             ; * 4
        tax
        ldy #0
-       lda txt_en_types,x
        sta SCREEN_RAM + 880 + 4,y
        inx
        iny
        cpy #4
        bne -

        ; PV Ennemi 0
        lda en_hp
        clc
        adc #'0'
        sta SCREEN_RAM + 880 + 12

        ; Nom Ennemi 1
        lda en_type+1
        asl
        asl
        tax
        ldy #0
-       lda txt_en_types,x
        sta SCREEN_RAM + 880 + 24,y
        inx
        iny
        cpy #4
        bne -

        ; PV Ennemi 1
        lda en_hp+1
        clc
        adc #'0'
        sta SCREEN_RAM + 880 + 32

        ; -------------------------------------------------------------------
        ; Ligne 23 : RASTER: #... ($D012)   ARM B: ....
        ; -------------------------------------------------------------------
        ldx #0
-       lda txt_dyn_raster,x
        sta SCREEN_RAM + 920,x
        lda #COL_YELLOW
        sta COLOR_RAM + 920,x
        inx
        cpx #38
        bne -

        ; Raster courant (3 chiffres)
        lda VIC_RASTER
        sta dbg_val
        lda #0
        sta dbg_val+1
        lda #< (SCREEN_RAM + 920 + 9)
        sta ZP_SCR
        lda #> (SCREEN_RAM + 920 + 9)
        sta ZP_SCR+1
        jsr dbg_put_val_3d

        ; Nom de l'arme équipée B
        lda hud_selected_b
        asl
        asl
        tax
        ldy #0
-       lda txt_b_names,x
        sta SCREEN_RAM + 920 + 32,y
        inx
        iny
        cpy #4
        bne -

        rts

; ---------------------------------------------------------------------------
; dbg_put_val_3d : écrit dbg_val (16 bits) sous forme de 3 chiffres décimaux
; Entrée : ZP_SCR (16 bits) = adresse de destination
; ---------------------------------------------------------------------------
dbg_put_val_3d:
        ; Centaines
        ldy #'0'
.sub_100:
        sec
        lda dbg_val
        sbc #100
        sta ZP_TMP
        lda dbg_val+1
        sbc #0
        bcc .c_done
        sta dbg_val+1
        lda ZP_TMP
        sta dbg_val
        iny
        jmp .sub_100
.c_done:
        tya
        ldy #0
        sta (ZP_SCR),y
        iny

        ; Dizaines
        lda #'0'
        sta ZP_TMP
.sub_10:
        sec
        lda dbg_val
        sbc #10
        bcc .d_done
        sta dbg_val
        inc ZP_TMP
        jmp .sub_10
.d_done:
        lda ZP_TMP
        sta (ZP_SCR),y
        iny

        ; Unités
        lda dbg_val
        clc
        adc #'0'
        sta (ZP_SCR),y
        rts

; ---------------------------------------------------------------------------
; dbg_put_dec2 : écrit A (0..99) sous forme de 2 chiffres décimaux
; Entrée : A = valeur, ZP_SCR (16 bits) = adresse de destination
; ---------------------------------------------------------------------------
dbg_put_dec2:
        ldy #'0'
-       cmp #10
        bcc +
        sbc #10
        iny
        jmp -
+       pha
        tya
        ldy #0
        sta (ZP_SCR),y
        iny
        pla
        clc
        adc #'0'
        sta (ZP_SCR),y
        rts

; ---------------------------------------------------------------------------
; Textes statiques de l'écran de debug
; ---------------------------------------------------------------------------
txt_dbg_title:
        !text "== C64 ZELDA HARDWARE & MEMORY MONITOR ="
txt_dbg_cpu_h:
        !text "[CPU & ARCHITECTURE] 64 KB TOTAL RAM  "
txt_dbg_cpu_1:
        !text " MOS 6510 @ 0.985 MHZ | PAL 50.12 HZ  "
txt_dbg_cpu_2:
        !text " ROM: BASIC $A000, CHAR $D000, KERN $E000"

txt_dbg_mem_h:
        !text "[MEMORY CONSUMPTION & LAYOUT]"
txt_dbg_mem_1:
        !text " PRG LOADED : 17911 BYTES (~17.5 KB) "
txt_dbg_mem_2:
        !text " FREE RAM   : $4E00-$CFFF (33.2 KB!) "
txt_dbg_mem_3:
        !text " SCREEN RAM : $0400-$07E7 (1000 B, 40X25)"
txt_dbg_mem_4:
        !text " SPRITES B0 : $0840-$0FFF (31 SPR, 1984B)"
txt_dbg_mem_5:
        !text " CHARSET 2K : $2000-$27FF (2048 B, 256C)"
txt_dbg_mem_6:
        !text " SPRITES EN : $38C0-$3D80 (19 SPR, 1216B)"
txt_dbg_mem_7:
        !text " CODE & DATA: $1000-$1C40 & $2800-$4DF6 "

txt_dbg_vic_h:
        !text "[VIC-II GRAPHICS & SPRITES (MAX 8)]   "
txt_dbg_vic_1:
        !text " S0:LINK S1:SWD S2:ITM S3:E0 S4:E1 S5:PJ"
txt_dbg_vic_2:
        !text " S6-S7: SPARE / BOMB 3X3 DEFLAGRATION "
txt_dbg_vic_3:
        !text " RES: 320X200 HIRES / 160X200 MULTICOLOR"

txt_dbg_sid_h:
        !text "[SID 8580 SOUND CHIP]    "
txt_dbg_sid_1:
        !text " 3 VOICES (NOISE, SAW, PULSE, TRIANGLE)"
txt_dbg_sid_2:
        !text " V1: SFX ACTIVE | V2-V3: FREE (MUSIC) "

txt_dbg_live_h:
        !text "[LIVE GAME TELEMETRY]         "

txt_dbg_footer:
        !text "[ PRESS 'D', SPACE OR FIRE TO RESUME ]"

txt_dyn_link:
        !text " LINK: X=... Y=... DIR=.  RM=(.,.)"
txt_dyn_status:
        !text " LIFE: ./. HTS  RUPEES: ..  BOMBS: .. "
txt_dyn_enemies:
        !text " E0: .... HP=.       E1: .... HP=.    "
txt_dyn_raster:
        !text " RASTER: #... ($D012)        ITEM B: ...."

txt_dir_letters:
        !text "DULR"

txt_en_types:
        !text "NONE"
        !text "OCTO"
        !text "MOBL"

txt_b_names:
        !text "BOOM"
        !text "BOMB"
        !text "BOW "
        !text "CAND"
