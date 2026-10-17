; ===========================================================================
; sound.asm : Moteur Audio & Musical Authentique Zelda C64
; Supporte Single SID (3 voix magnifiques) et Dual SID (Stereo / 6 voix)
; ===========================================================================

!zone sound

MUSIC_NONE              = 0
MUSIC_OVERWORLD         = 1
MUSIC_DUNGEON           = 2

SID1_BASE               = $d400
SID2_BASE               = $d420                 ; Adresse standard Stereo SID

; --- Registres SID 1 (Primaire) ---
SID1_V1_FREQ_LO         = SID1_BASE + 0
SID1_V1_FREQ_HI         = SID1_BASE + 1
SID1_V1_PW_LO           = SID1_BASE + 2
SID1_V1_PW_HI           = SID1_BASE + 3
SID1_V1_CTRL            = SID1_BASE + 4
SID1_V1_AD              = SID1_BASE + 5
SID1_V1_SR              = SID1_BASE + 6

SID1_V2_FREQ_LO         = SID1_BASE + 7
SID1_V2_FREQ_HI         = SID1_BASE + 8
SID1_V2_PW_LO           = SID1_BASE + 9
SID1_V2_PW_HI           = SID1_BASE + 10
SID1_V2_CTRL            = SID1_BASE + 11
SID1_V2_AD              = SID1_BASE + 12
SID1_V2_SR              = SID1_BASE + 13

SID1_V3_FREQ_LO         = SID1_BASE + 14
SID1_V3_FREQ_HI         = SID1_BASE + 15
SID1_V3_PW_LO           = SID1_BASE + 16
SID1_V3_PW_HI           = SID1_BASE + 17
SID1_V3_CTRL            = SID1_BASE + 18
SID1_V3_AD              = SID1_BASE + 19
SID1_V3_SR              = SID1_BASE + 20

SID1_FC_LO              = SID1_BASE + 21
SID1_FC_HI              = SID1_BASE + 22
SID1_RES_FILT           = SID1_BASE + 23
SID1_VOLUME             = SID1_BASE + 24

; --- Registres SID 2 (Secondaire / Stereo) ---
SID2_V1_FREQ_LO         = SID2_BASE + 0
SID2_V1_FREQ_HI         = SID2_BASE + 1
SID2_V1_PW_LO           = SID2_BASE + 2
SID2_V1_PW_HI           = SID2_BASE + 3
SID2_V1_CTRL            = SID2_BASE + 4
SID2_V1_AD              = SID2_BASE + 5
SID2_V1_SR              = SID2_BASE + 6

SID2_V2_FREQ_LO         = SID2_BASE + 7
SID2_V2_FREQ_HI         = SID2_BASE + 8
SID2_V2_PW_LO           = SID2_BASE + 9
SID2_V2_PW_HI           = SID2_BASE + 10
SID2_V2_CTRL            = SID2_BASE + 11
SID2_V2_AD              = SID2_BASE + 12
SID2_V2_SR              = SID2_BASE + 13

SID2_V3_FREQ_LO         = SID2_BASE + 14
SID2_V3_FREQ_HI         = SID2_BASE + 15
SID2_V3_PW_LO           = SID2_BASE + 16
SID2_V3_PW_HI           = SID2_BASE + 17
SID2_V3_CTRL            = SID2_BASE + 18
SID2_V3_AD              = SID2_BASE + 19
SID2_V3_SR              = SID2_BASE + 20

SID2_VOLUME             = SID2_BASE + 24

; --- Variables Mémoire Audio ---
current_music:          !byte MUSIC_NONE
music_part:             !byte 0                 ; 0 = Part 1, 1 = Part 2
music_step:             !byte 0                 ; index de pas dans la partie
music_delay:            !byte 0                 ; compte à rebours de frames avant le pas suivant
dual_sid_enabled:       !byte 0                 ; 0 = Single SID (standard), 1 = Dual SID (Stereo)
sfx_timer:              !byte 0                 ; durée active de l'effet sonore (frames)
sfx_voice:              !byte 0                 ; voix occupée par le SFX (1 ou 3)

; ---------------------------------------------------------------------------
; sound_init : Réinitialise les puces SID et prépare le moteur audio
; ---------------------------------------------------------------------------
sound_init:
        ; Silence complet sur SID 1
        ldx #24
        lda #0
-       sta SID1_BASE,x
        dex
        bpl -

        ; Silence complet sur SID 2
        ldx #24
        lda #0
-       sta SID2_BASE,x
        dex
        bpl -

        ; Volume maximum sur SID 1
        lda #15
        sta SID1_VOLUME

        ; Détection / Initialisation Dual SID :
        ; Si dual_sid_enabled est actif, active le volume sur SID 2
        lda dual_sid_enabled
        beq +
        lda #15
        sta SID2_VOLUME
+
        ; Largeur d'impulsion initiale (50% square)
        lda #$00
        sta SID1_V1_PW_LO
        sta SID1_V2_PW_LO
        sta SID2_V1_PW_LO
        sta SID2_V2_PW_LO
        lda #$08
        sta SID1_V1_PW_HI
        sta SID1_V2_PW_HI
        sta SID2_V1_PW_HI
        sta SID2_V2_PW_HI

        lda #MUSIC_NONE
        sta current_music
        lda #0
        sta music_part
        sta music_step
        sta music_delay
        sta sfx_timer
        sta sfx_voice
        rts

; ---------------------------------------------------------------------------
; sound_detect_dual_sid : Teste la présence d'une seconde puce SID en $D420
; ---------------------------------------------------------------------------
sound_detect_dual_sid:
        lda #15
        sta SID2_VOLUME
        ; Teste si le registre répond
        lda SID2_VOLUME
        and #$0f
        cmp #15
        bne .no_sid2
        lda #1
        sta dual_sid_enabled
        rts
.no_sid2:
        lda #0
        sta dual_sid_enabled
        rts

; ---------------------------------------------------------------------------
; music_play : Lance la lecture d'un morceau (A = MUSIC_OVERWORLD / MUSIC_DUNGEON)
; ---------------------------------------------------------------------------
music_play:
        cmp current_music
        beq .already_playing            ; Évite de redémarrer le morceau si déjà en cours
        sta current_music

        lda #0
        sta music_part
        sta music_step
        sta music_delay
        sta sfx_timer

        lda current_music
        cmp #MUSIC_OVERWORLD
        beq .init_overworld_inst
        cmp #MUSIC_DUNGEON
        beq .init_dungeon_inst
        rts

.already_playing:
        rts

.init_overworld_inst:
        ; --- Instruments Overworld ---
        ; Voix 1 : Cuivre / Trompette héroïque (Pulse 50%)
        lda #$09
        sta SID1_V1_AD
        lda #$a0
        sta SID1_V1_SR
        lda #%01000001
        sta SID1_V1_CTRL

        ; Voix 2 : Harmonie / Contre-chant (Sawtooth chaud)
        lda #$09
        sta SID1_V2_AD
        lda #$80
        sta SID1_V2_SR
        lda #%00100001
        sta SID1_V2_CTRL

        ; Voix 3 : Percussion / Basse (Noise / Triangle)
        lda #$00
        sta SID1_V3_AD
        lda #$f0
        sta SID1_V3_SR
        lda #%00010001
        sta SID1_V3_CTRL

        ; Si Dual SID, configure SID 2 pour le chorus stéréo
        lda dual_sid_enabled
        beq +
        lda #$09
        sta SID2_V1_AD
        lda #$a0
        sta SID2_V1_SR
        lda #%01000001
        sta SID2_V1_CTRL
        lda #$09
        sta SID2_V2_AD
        lda #$80
        sta SID2_V2_SR
        lda #%00100001
        sta SID2_V2_CTRL
+       rts

.init_dungeon_inst:
        ; --- Instruments Underworld (Dungeon) ---
        ; Voix 1 : Sonde mystique / Lead gothique (Pulse creux)
        lda #$00
        sta SID1_V1_PW_LO
        lda #$04                        ; Impulsion 25% (timbre sombre et nasillard)
        sta SID1_V1_PW_HI
        lda #$0c
        sta SID1_V1_AD
        lda #$a0
        sta SID1_V1_SR
        lda #%01000001
        sta SID1_V1_CTRL

        ; Voix 2 : Orgue souterrain menaçant (Sawtooth soutenu)
        lda #$0f
        sta SID1_V2_AD
        lda #$90
        sta SID1_V2_SR
        lda #%00100001
        sta SID1_V2_CTRL

        ; Voix 3 : Basse des profondeurs (Triangle pur)
        lda #$00
        sta SID1_V3_AD
        lda #$f0
        sta SID1_V3_SR
        lda #%00010001
        sta SID1_V3_CTRL

        lda dual_sid_enabled
        beq +
        lda #$0c
        sta SID2_V1_AD
        lda #$a0
        sta SID2_V1_SR
        lda #%01000001
        sta SID2_V1_CTRL
        lda #$0f
        sta SID2_V2_AD
        lda #$90
        sta SID2_V2_SR
        lda #%00100001
        sta SID2_V2_CTRL
+       rts

; ---------------------------------------------------------------------------
; music_stop : Coupe la musique et coupe les portes Gate
; ---------------------------------------------------------------------------
music_stop:
        lda #MUSIC_NONE
        sta current_music
        lda #%01000000
        sta SID1_V1_CTRL
        lda #%00100000
        sta SID1_V2_CTRL
        lda #%00010000
        sta SID1_V3_CTRL
        lda #0
        sta sfx_timer
        rts

; ---------------------------------------------------------------------------
; music_update : Mise à jour par interruption 50 Hz (VBlank)
; ---------------------------------------------------------------------------
music_update:
        ; 1. Gestion du compte à rebours d'effet sonore
        lda sfx_timer
        beq .check_delay
        dec sfx_timer
        bne .check_delay
        ; Fin de l'effet sonore : restaure l'instrument de musique
        lda sfx_voice
        cmp #3
        bne .sfx_v1_restore
        lda #%00010001
        sta SID1_V3_CTRL
        jmp .check_delay
.sfx_v1_restore:
        lda #%01000001
        sta SID1_V1_CTRL

.check_delay:
        ; 2. Pas de musique active ?
        lda current_music
        bne +
        rts
+
        ; 3. Compte à rebours du pas musical
        lda music_delay
        beq .next_step
        dec music_delay
        rts

.next_step:
        ; Dispatch selon le morceau actif
        lda current_music
        cmp #MUSIC_OVERWORLD
        beq .step_overworld
        cmp #MUSIC_DUNGEON
        beq .step_dungeon
        rts

; ---------------------------------------------------------------------------
; Déroulement Overworld (Partie 1 & Partie 2)
; ---------------------------------------------------------------------------
.step_overworld:
        lda music_part
        bne .ow_part2

        ; --- Overworld Partie 1 ---
        ldx music_step
        cpx #MUSIC_OW_P1_LEN
        bcc .ow_read_p1
        lda #1
        sta music_part
        ldx #0
        stx music_step
        jmp .ow_part2

.ow_read_p1:
        lda music_ow_p1_dur,x
        sta music_delay
        lda music_ow_p1_v1,x
        sta temp_v1
        lda music_ow_p1_v2,x
        sta temp_v2
        lda music_ow_p1_v3,x
        sta temp_v3
        inc music_step
        jmp .apply_music_step

.ow_part2:
        ; --- Overworld Partie 2 ---
        ldx music_step
        cpx #MUSIC_OW_P2_LEN
        bcc .ow_read_p2
        ; Boucle : retour au début de Partie 1
        lda #0
        sta music_part
        ldx #0
        stx music_step
        jmp .ow_read_p1

.ow_read_p2:
        lda music_ow_p2_dur,x
        sta music_delay
        lda music_ow_p2_v1,x
        sta temp_v1
        lda music_ow_p2_v2,x
        sta temp_v2
        lda music_ow_p2_v3,x
        sta temp_v3
        inc music_step
        jmp .apply_music_step

; ---------------------------------------------------------------------------
; Déroulement Underworld / Dungeon
; ---------------------------------------------------------------------------
.step_dungeon:
        ldx music_step
        cpx #MUSIC_UW_LEN
        bcc .uw_read
        ; Boucle du donjon
        ldx #0
        stx music_step
.uw_read:
        lda music_uw_dur,x
        sta music_delay
        lda music_uw_v1,x
        sta temp_v1
        lda music_uw_v2,x
        sta temp_v2
        lda music_uw_v3,x
        sta temp_v3
        inc music_step

; ---------------------------------------------------------------------------
; Application des notes aux registres SID
; ---------------------------------------------------------------------------
.apply_music_step:
        ; --- VOIX 1 : Mélodie Principale ---
        lda sfx_timer
        beq +
        lda sfx_voice
        cmp #1
        beq .skip_v1                    ; Voix 1 occupée par un SFX
+
        ldx temp_v1
        beq .v1_mute
        lda music_note_freq_lo,x
        sta SID1_V1_FREQ_LO
        lda music_note_freq_hi,x
        sta SID1_V1_FREQ_HI
        lda #%01000001                  ; Pulse Gate ON
        sta SID1_V1_CTRL

        ; Si Dual SID, envoie sur SID 2 avec léger chorus
        lda dual_sid_enabled
        beq .skip_v1
        lda music_note_freq_lo,x
        clc
        adc #2                          ; Detune +2 pour effet stéréo spatial
        sta SID2_V1_FREQ_LO
        lda music_note_freq_hi,x
        adc #0
        sta SID2_V1_FREQ_HI
        lda #%01000001
        sta SID2_V1_CTRL
        jmp .skip_v1

.v1_mute:
        lda #%01000000                  ; Gate OFF
        sta SID1_V1_CTRL
        lda dual_sid_enabled
        beq .skip_v1
        sta SID2_V1_CTRL
.skip_v1:

        ; --- VOIX 2 : Harmonie / Contre-chant ---
        ldx temp_v2
        beq .v2_mute
        lda music_note_freq_lo,x
        sta SID1_V2_FREQ_LO
        lda music_note_freq_hi,x
        sta SID1_V2_FREQ_HI
        lda #%00100001                  ; Sawtooth Gate ON
        sta SID1_V2_CTRL

        lda dual_sid_enabled
        beq .skip_v2
        lda music_note_freq_lo,x
        sta SID2_V2_FREQ_LO
        lda music_note_freq_hi,x
        sta SID2_V2_FREQ_HI
        lda #%00100001
        sta SID2_V2_CTRL
        jmp .skip_v2

.v2_mute:
        lda #%00100000                  ; Gate OFF
        sta SID1_V2_CTRL
        lda dual_sid_enabled
        beq .skip_v2
        sta SID2_V2_CTRL
.skip_v2:

        ; --- VOIX 3 : Percussion ou Basse ---
        lda sfx_timer
        beq +
        lda sfx_voice
        cmp #3
        beq .skip_v3                    ; Voix 3 occupée par un SFX
+
        lda temp_v3
        beq .v3_mute
        cmp #$80
        beq .v3_percussion

        ; Basse mélodique (Underworld)
        tax
        lda music_note_freq_lo,x
        sta SID1_V3_FREQ_LO
        lda music_note_freq_hi,x
        sta SID1_V3_FREQ_HI
        lda #%00010001                  ; Triangle Gate ON
        sta SID1_V3_CTRL
        rts

.v3_percussion:
        ; Caisse claire / Percussion militaire Overworld
        lda #$80
        sta SID1_V3_FREQ_LO
        lda #$28
        sta SID1_V3_FREQ_HI
        lda #$04
        sta SID1_V3_AD
        lda #$00
        sta SID1_V3_SR
        lda #%10000000
        sta SID1_V3_CTRL
        lda #%10000001                  ; Bruit Gate ON
        sta SID1_V3_CTRL
        rts

.v3_mute:
        lda #%00010000                  ; Gate OFF
        sta SID1_V3_CTRL
.skip_v3:
        rts

temp_v1:        !byte 0
temp_v2:        !byte 0
temp_v3:        !byte 0

; ===========================================================================
; EFFETS SONORES (SFX)
; En mode Dual SID, jouent sur SID 2 pour préserver 100% de la musique sur SID 1.
; En mode Single SID, s'intègrent avec sfx_timer sans casser le flux musical.
; ===========================================================================

; Coup d'épée de Link (Bruit tranchant d'acier)
sound_sword:
        lda dual_sid_enabled
        bne .sfx_dual_sword
        ; Single SID : priorité Voix 3
        lda #3
        sta sfx_voice
        lda #6                          ; 6 frames
        sta sfx_timer
        lda #$00
        sta SID1_V3_FREQ_LO
        lda #$48
        sta SID1_V3_FREQ_HI
        lda #$09
        sta SID1_V3_AD
        lda #$00
        sta SID1_V3_SR
        lda #%10000001                  ; Noise
        sta SID1_V3_CTRL
        rts
.sfx_dual_sword:
        lda #$00
        sta SID2_V3_FREQ_LO
        lda #$48
        sta SID2_V3_FREQ_HI
        lda #$09
        sta SID2_V3_AD
        lda #$00
        sta SID2_V3_SR
        lda #%10000001
        sta SID2_V3_CTRL
        rts

; Tir ennemi / rocher craché
sound_enemy_shoot:
        lda dual_sid_enabled
        bne .sfx_dual_shoot
        lda #3
        sta sfx_voice
        lda #5
        sta sfx_timer
        lda #$20
        sta SID1_V3_FREQ_LO
        lda #$25
        sta SID1_V3_FREQ_HI
        lda #$06
        sta SID1_V3_AD
        lda #$00
        sta SID1_V3_SR
        lda #%00100001                  ; Sawtooth
        sta SID1_V3_CTRL
        rts
.sfx_dual_shoot:
        lda #$20
        sta SID2_V3_FREQ_LO
        lda #$25
        sta SID2_V3_FREQ_HI
        lda #$06
        sta SID2_V3_AD
        lda #$00
        sta SID2_V3_SR
        lda #%00100001
        sta SID2_V3_CTRL
        rts

; Impact sur ennemi (Bruit sec)
sound_enemy_hit:
        lda dual_sid_enabled
        bne .sfx_dual_hit
        lda #3
        sta sfx_voice
        lda #6
        sta sfx_timer
        lda #$80
        sta SID1_V3_FREQ_LO
        lda #$30
        sta SID1_V3_FREQ_HI
        lda #$04
        sta SID1_V3_AD
        lda #$00
        sta SID1_V3_SR
        lda #%10000001                  ; Noise
        sta SID1_V3_CTRL
        rts
.sfx_dual_hit:
        lda #$80
        sta SID2_V3_FREQ_LO
        lda #$30
        sta SID2_V3_FREQ_HI
        lda #$04
        sta SID2_V3_AD
        lda #$00
        sta SID2_V3_SR
        lda #%10000001
        sta SID2_V3_CTRL
        rts

; Mort d'ennemi (Nuage de fumée rétro)
sound_enemy_die:
        lda dual_sid_enabled
        bne .sfx_dual_die
        lda #3
        sta sfx_voice
        lda #10
        sta sfx_timer
        lda #$00
        sta SID1_V3_FREQ_LO
        lda #$18
        sta SID1_V3_FREQ_HI
        lda #$0c
        sta SID1_V3_AD
        lda #$00
        sta SID1_V3_SR
        lda #%10000001                  ; Noise
        sta SID1_V3_CTRL
        rts
.sfx_dual_die:
        lda #$00
        sta SID2_V3_FREQ_LO
        lda #$18
        sta SID2_V3_FREQ_HI
        lda #$0c
        sta SID2_V3_AD
        lda #$00
        sta SID2_V3_SR
        lda #%10000001
        sta SID2_V3_CTRL
        rts

; Bouclier bloquant un projectile (Tintement aigu métallique)
sound_shield_block:
        lda dual_sid_enabled
        bne .sfx_dual_shield
        lda #3
        sta sfx_voice
        lda #4
        sta sfx_timer
        lda #$00
        sta SID1_V3_FREQ_LO
        lda #$70
        sta SID1_V3_FREQ_HI
        lda #$02
        sta SID1_V3_AD
        lda #$00
        sta SID1_V3_SR
        lda #%00010001                  ; Triangle
        sta SID1_V3_CTRL
        rts
.sfx_dual_shield:
        lda #$00
        sta SID2_V3_FREQ_LO
        lda #$70
        sta SID2_V3_FREQ_HI
        lda #$02
        sta SID2_V3_AD
        lda #$00
        sta SID2_V3_SR
        lda #%00010001
        sta SID2_V3_CTRL
        rts

; Ramassage de rubis (Jingle mélodieux cristallin)
sound_rupee:
        lda dual_sid_enabled
        bne .sfx_dual_rupee
        lda #1
        sta sfx_voice
        lda #8
        sta sfx_timer
        lda #$a0
        sta SID1_V1_FREQ_LO
        lda #$65
        sta SID1_V1_FREQ_HI
        lda #$05
        sta SID1_V1_AD
        lda #$00
        sta SID1_V1_SR
        lda #%00010001                  ; Triangle
        sta SID1_V1_CTRL
        rts
.sfx_dual_rupee:
        lda #$a0
        sta SID2_V3_FREQ_LO
        lda #$65
        sta SID2_V3_FREQ_HI
        lda #$05
        sta SID2_V3_AD
        lda #$00
        sta SID2_V3_SR
        lda #%00010001
        sta SID2_V3_CTRL
        rts

; Données musicales incluses
!source "src/music_data.inc"
