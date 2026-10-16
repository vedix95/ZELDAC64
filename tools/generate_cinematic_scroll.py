# Implémentons la descente cinématique de la cascade vers le parchemin déroulé :
# Phases :
# INTRO_PHASE_WATERFALL = 0  (Écran titre cascade 6s)
# INTRO_PHASE_PAN_DOWN  = 1  (La caméra descend le long de la cascade, 24 crans)
# INTRO_PHASE_STORY     = 2  (Le texte de l'histoire défile du bas vers le haut dans le parchemin)
# INTRO_PHASE_TREASURES = 3  (Les trésors défilent du bas vers le haut)

# 1. Mise à jour des constantes et aiguillages dans src/intro.asm
with open('src/intro.asm', 'r') as f:
    text = f.read()

# Remplacer les phases :
text = text.replace("""INTRO_PHASE_WATERFALL = 0
INTRO_PHASE_STORY     = 1
INTRO_PHASE_TREASURES = 2""",
"""INTRO_PHASE_WATERFALL = 0
INTRO_PHASE_PAN_DOWN  = 1
INTRO_PHASE_STORY     = 2
INTRO_PHASE_TREASURES = 3""")

# Ajouter la variable pan_step si besoin
text = text.replace("intro_scroll_tick:  !byte 0", "intro_scroll_tick:  !byte 0\nintro_pan_step:     !byte 0")

# Dispatch dans intro_update :
p_dispatch = text.find("; Selon la phase active\n        lda intro_phase")
p_dispatch_end = text.find("; ---------------------------------------------------------------------------\n; 1. MISE A JOUR DE LA CASCADE")

new_dispatch = """; Selon la phase active
        lda intro_phase
        cmp #INTRO_PHASE_WATERFALL
        beq .update_waterfall
        cmp #INTRO_PHASE_PAN_DOWN
        beq .update_pan_down
        cmp #INTRO_PHASE_STORY
        beq .update_story
        jmp .update_treasures

"""

text = text[:p_dispatch] + new_dispatch + text[p_dispatch_end:]

# Transition de WATERFALL vers PAN_DOWN au lieu de directement STORY :
text = text.replace("lda #INTRO_PHASE_STORY\n        sta intro_phase\n        lda #0\n        sta intro_scroll_line\n        sta intro_scroll_tick\n        jsr intro_draw_story_bg",
"""lda #INTRO_PHASE_PAN_DOWN
        sta intro_phase
        lda #0
        sta intro_pan_step
        sta intro_scroll_tick""")

# Ajouter la logique de PAN_DOWN :
p_wf_section = text.find("; 2. MISE A JOUR DE L'HISTOIRE")
pan_down_code = """; ---------------------------------------------------------------------------
; 1bis. DESCENTE DE LA CASCADE (PAN DOWN CINEMATIQUE)
; ---------------------------------------------------------------------------
.update_pan_down:
        ; Vitesse : 1 ligne toutes les 3 frames (très fluide)
        inc intro_scroll_tick
        lda intro_scroll_tick
        cmp #3
        bcc .pan_done
        lda #0
        sta intro_scroll_tick

        jsr intro_pan_down_step
        inc intro_pan_step
        lda intro_pan_step
        cmp #24                         ; 24 lignes de descente pour révéler le parchemin
        bcc .pan_done

        ; Une fois la descente finie, on passe au défilement de l'histoire dans le parchemin
        lda #INTRO_PHASE_STORY
        sta intro_phase
        lda #0
        sta intro_scroll_line
        sta intro_scroll_tick
.pan_done:
        rts

"""

text = text[:p_wf_section] + pan_down_code + text[p_wf_section:]

# Ajouter la routine intro_pan_down_step :
p_step_pos = text.find("intro_draw_story_bg:")

pan_routine = """intro_pan_down_step:
        ; Décale toutes les lignes 0..23 d'un cran vers le haut (l'écran descend vers le bas)
        ldx #0
.pan_shift:
        lda intro_scr_lo,x
        sta ZP_DST
        lda intro_scr_hi,x
        sta ZP_DST+1

        inx
        lda intro_scr_lo,x
        sta ZP_SRC
        lda intro_scr_hi,x
        sta ZP_SRC+1

        ldy #0
.pan_row_copy:
        lda (ZP_SRC),y
        sta (ZP_DST),y
        lda COLOR_RAM+40,y             ; Sauvegarde couleur
        iny
        cpy #40
        bne .pan_row_copy

        ; Copie aussi les couleurs de la ligne
        dex
        lda intro_scr_lo,x
        sta ZP_DST
        lda intro_col_hi,x
        sta ZP_DST+1
        inx
        lda intro_scr_lo,x
        sta ZP_SRC
        lda intro_col_hi,x
        sta ZP_SRC+1
        ldy #0
.pan_col_copy:
        lda (ZP_SRC),y
        sta (ZP_DST),y
        iny
        cpy #40
        bne .pan_col_copy

        cpx #24
        bne .pan_shift

        ; Injecte la nouvelle ligne sur la ligne 24 qui entre par le bas :
        ; Selon l'avancement de intro_pan_step (0..23) :
        ; 0..2   : Eau du lac et reflets
        ; 3      : Haut du rouleau de parchemin (160, 161, 162)
        ; 4      : Titre "HISTOIRE D'HYRULE"
        ; 5      : Filet d'or (115)
        ; 6..22  : Bords latéraux du parchemin (163 à gauche, 164 à droite)
        ; 23     : Bas du rouleau de parchemin (165, 166, 167)
        ldx intro_pan_step
        cpx #3
        bcc .inject_lake
        beq .inject_scroll_top
        cpx #4
        beq .inject_scroll_title
        cpx #5
        beq .inject_scroll_sep
        cpx #23
        beq .inject_scroll_bot

        ; Bords latéraux de parchemin (corps déroulé)
        ldy #0
        lda #32
.clr_p24:
        sta SCREEN_RAM+960,y
        lda #COL_BLACK
        sta COLOR_RAM+960,y
        iny
        cpy #40
        bne .clr_p24

        lda #163
        sta SCREEN_RAM+960+3
        lda #COL_YELLOW
        sta COLOR_RAM+960+3
        lda #164
        sta SCREEN_RAM+960+36
        lda #COL_YELLOW
        sta COLOR_RAM+960+36
        rts

.inject_lake:
        ldy #0
.inj_l:
        lda #134
        sta SCREEN_RAM+960,y
        lda #COL_BLUE
        sta COLOR_RAM+960,y
        iny
        cpy #40
        bne .inj_l
        rts

.inject_scroll_top:
        ldy #0
        lda #32
.inj_st_clr:
        sta SCREEN_RAM+960,y
        lda #COL_BLACK
        sta COLOR_RAM+960,y
        iny
        cpy #40
        bne .inj_st_clr

        lda #160
        sta SCREEN_RAM+960+3
        lda #COL_YELLOW
        sta COLOR_RAM+960+3
        ldy #4
.inj_st_bar:
        lda #161
        sta SCREEN_RAM+960,y
        lda #COL_YELLOW
        sta COLOR_RAM+960,y
        iny
        cpy #36
        bne .inj_st_bar
        lda #162
        sta SCREEN_RAM+960+36
        lda #COL_YELLOW
        sta COLOR_RAM+960+36
        rts

.inject_scroll_title:
        ldy #0
        lda #32
.inj_st_clr2:
        sta SCREEN_RAM+960,y
        lda #COL_BLACK
        sta COLOR_RAM+960,y
        iny
        cpy #40
        bne .inj_st_clr2

        lda #163
        sta SCREEN_RAM+960+3
        lda #COL_YELLOW
        sta COLOR_RAM+960+3
        lda #164
        sta SCREEN_RAM+960+36
        lda #COL_YELLOW
        sta COLOR_RAM+960+36

        ldx #0
.inj_ttl:
        lda txt_story_title,x
        beq +
        sta SCREEN_RAM+960+11,x
        lda #COL_YELLOW
        sta COLOR_RAM+960+11,x
        inx
        bne .inj_ttl
+       rts

.inject_scroll_sep:
        ldy #0
        lda #32
.inj_st_clr3:
        sta SCREEN_RAM+960,y
        lda #COL_BLACK
        sta COLOR_RAM+960,y
        iny
        cpy #40
        bne .inj_st_clr3

        lda #163
        sta SCREEN_RAM+960+3
        lda #COL_YELLOW
        sta COLOR_RAM+960+3
        lda #164
        sta SCREEN_RAM+960+36
        lda #COL_YELLOW
        sta COLOR_RAM+960+36

        ldx #0
.inj_sep:
        lda #115
        sta SCREEN_RAM+960+10,x
        lda #COL_YELLOW
        sta COLOR_RAM+960+10,x
        inx
        cpx #20
        bne .inj_sep
        rts

.inject_scroll_bot:
        ldy #0
        lda #32
.inj_st_clr4:
        sta SCREEN_RAM+960,y
        lda #COL_BLACK
        sta COLOR_RAM+960,y
        iny
        cpy #40
        bne .inj_st_clr4

        lda #165
        sta SCREEN_RAM+960+3
        lda #COL_YELLOW
        sta COLOR_RAM+960+3
        ldy #4
.inj_sb_bar:
        lda #166
        sta SCREEN_RAM+960,y
        lda #COL_YELLOW
        sta COLOR_RAM+960,y
        iny
        cpy #36
        bne .inj_sb_bar
        lda #167
        sta SCREEN_RAM+960+36
        lda #COL_YELLOW
        sta COLOR_RAM+960+36
        rts

"""

text = text[:p_step_pos] + pan_routine + text[p_step_pos:]

# Ajuster la cadence du scrolling de l'histoire pour qu'il soit rapide et captivant (toutes les 40 frames au lieu de 60) :
text = text.replace("cmp #60                         ; une nouvelle ligne toutes les 1.2s",
                    "cmp #35                         ; une nouvelle ligne toutes les 0.7s")

with open('src/intro.asm', 'w') as f:
    f.write(text)

print("Generated cinematic pan-down and upward-scrolling engine!")
