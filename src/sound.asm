; ===========================================================================
; sound.asm : Moteur Audio & Musical Authentique Zelda C64
; Supporte Single SID (3 voix magnifiques) et Dual SID (Stereo / 6 voix)
; ===========================================================================

!zone sound

MUSIC_NONE              = 0
MUSIC_OVERWORLD         = 1
MUSIC_DUNGEON           = 2
MUSIC_ITEM_FANFARE      = 3
MUSIC_TRIFORCE          = 4
MUSIC_DUNGEON_FINAL     = 5

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
saved_bg_music:         !byte MUSIC_NONE
music_part:             !byte 0                 ; 0 = Part 1, 1 = Part 2
music_step:             !byte 0                 ; index de pas dans la partie
music_delay:            !byte 0                 ; compte à rebours de frames avant le pas suivant
dual_sid_enabled:       !byte 0                 ; 0 = Single SID (standard), 1 = Dual SID (Stereo)
sfx_timer:              !byte 0                 ; durée active de l'effet sonore (frames)
sfx_voice:              !byte 0                 ; voix occupée par le SFX (1, 2 ou 3)
secret_chime_active:    !byte 0                 ; 1 si le carillon triomphal est en cours
secret_chime_timer:     !byte 0                 ; compte à rebours de frames par note du carillon
secret_chime_idx:       !byte 0                 ; index de note du carillon (0..7)
secret_chime_pending:   !byte 0                 ; 1 si le carillon attend la fin d'un son Voix 3 (clé/rupee)
sfx_rupee_pending:      !byte 0                 ; 1 si le son de ramassage attend la fin du carillon
sfx_pending_idx:        !byte 0                 ; index SFX+1 en attente dans la file pendant le carillon
cur_music_v1_note:      !byte 0                 ; dernière note programmée Voix 1
cur_music_v2_note:      !byte 0                 ; dernière note programmée Voix 2
cur_music_v3_note:      !byte 0                 ; dernière note programmée Voix 3

sound_code_start:

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

        ; Silence complet sur SID 2 si Dual SID actif
        lda dual_sid_enabled
        beq +
        ldx #24
        lda #0
-       sta SID2_BASE,x
        dex
        bpl -

        ; Volume maximum sur SID 2 si Dual SID actif
        lda #15
        sta SID2_VOLUME
+

        ; Volume maximum sur SID 1
        lda #15
        sta SID1_VOLUME

        ; Largeur d'impulsion initiale (50% square)
        lda #$00
        sta SID1_V1_PW_LO
        sta SID1_V2_PW_LO
        lda #$08
        sta SID1_V1_PW_HI
        sta SID1_V2_PW_HI

        lda dual_sid_enabled
        beq +
        lda #$00
        sta SID2_V1_PW_LO
        sta SID2_V2_PW_LO
        lda #$08
        sta SID2_V1_PW_HI
        sta SID2_V2_PW_HI
+

        lda #MUSIC_NONE
        sta current_music
        sta saved_bg_music
        lda #0
        sta music_part
        sta music_step
        sta music_delay
        sta sfx_timer
        sta sfx_voice
        sta secret_chime_active
        sta secret_chime_timer
        sta secret_chime_idx
        sta secret_chime_pending
        sta sfx_rupee_pending
        sta sfx_pending_idx
        sta cur_music_v1_note
        sta cur_music_v2_note
        sta cur_music_v3_note
        rts

; ---------------------------------------------------------------------------
; sound_set_dual_sid_config : Configure et relocalise dynamiquement le 2ème SID
; Entrée :
;   A = dual_sid (0 = Single SID Mono, 1 = Dual SID Stéréo)
;   X = sid2_addr_idx (0 = $D420, 1 = $D500, 2 = $DF00)
; ---------------------------------------------------------------------------
sound_set_dual_sid_config:
        sta dual_sid_enabled
        bne +
        rts

+       cpx #3
        bcc +
        ldx #0                          ; Défaut $D420 si index invalide
+
        lda sid2_base_lo_tbl,x
        sta .reloc_base_lo
        lda sid2_base_hi_tbl,x
        sta .reloc_base_hi

        ; Relocalise tous les accès $D420..$D438 entre sound_code_start et sound_code_end
        lda #<sound_code_start
        sta ZP_SCR
        lda #>sound_code_start
        sta ZP_SCR+1

.reloc_scan:
        ldy #2
        lda (ZP_SCR),y
        cmp #$d4
        bne .reloc_next

        dey
        lda (ZP_SCR),y
        cmp #$20
        bcc .reloc_next
        cmp #$39
        bcs .reloc_next

        ; Match trouvé ! Opérande $D420..$D438
        sec
        sbc #$20                        ; Décalage registre $00..$18
        clc
.reloc_base_lo = * + 1
        adc #$20
        sta (ZP_SCR),y

        iny
.reloc_base_hi = * + 1
        lda #$d4
        sta (ZP_SCR),y

.reloc_next:
        inc ZP_SCR
        bne +
        inc ZP_SCR+1
+
        lda ZP_SCR
        cmp #<sound_code_end
        lda ZP_SCR+1
        sbc #>sound_code_end
        bcc .reloc_scan
        rts

sid2_base_lo_tbl:
        !byte $20, $00, $00
sid2_base_hi_tbl:
        !byte $d4, $d5, $df

sound_set_sid2_volume:
        sta SID2_VOLUME
        rts

; ---------------------------------------------------------------------------
; sound_detect_dual_sid : Maintenu pour compatibilité
; ---------------------------------------------------------------------------
sound_detect_dual_sid:
        rts

; ---------------------------------------------------------------------------
; sound_play_dungeon_music : Lance la musique appropriée selon le niveau de Donjon (1..9)
; ---------------------------------------------------------------------------
sound_play_dungeon_music:
        lda current_dungeon_level
        cmp #9
        bne .play_std_dungeon

        ; Niveau 9 (Montagne de la Mort) : Streame la partition Donjon 9 depuis Banque 31 ($8800)
        lda #<bgm_track_buffer
        sta ZP_DST
        lda #>bgm_track_buffer
        sta ZP_DST+1
        lda #<$8800
        sta ZP_SRC
        lda #>$8800
        sta ZP_SRC+1
        lda #CART_BANK_AUDIO
        ldx #2                  ; 2 pages (512 octets, partition 496 octets)
        jsr cart_stream_copy_from
        lda #MUSIC_DUNGEON_FINAL
        jmp music_play

.play_std_dungeon:
        lda #MUSIC_DUNGEON
        jmp music_play

; ---------------------------------------------------------------------------
; sound_restore_standard_bgm : Restaure la partition Standard BGM depuis Banque 31 ($8000)
; ---------------------------------------------------------------------------
sound_restore_standard_bgm:
        lda #<bgm_track_buffer
        sta ZP_DST
        lda #>bgm_track_buffer
        sta ZP_DST+1
        lda #<$8000
        sta ZP_SRC
        lda #>$8000
        sta ZP_SRC+1
        lda #CART_BANK_AUDIO
        ldx #6                  ; 6 pages (1364 octets)
        jmp cart_stream_copy_from

; ---------------------------------------------------------------------------
; music_play : Lance la lecture d'un morceau (A = MUSIC_OVERWORLD / MUSIC_DUNGEON)
; ---------------------------------------------------------------------------
music_play:
        cmp current_music
        beq .already_playing            ; Évite de redémarrer le morceau si déjà en cours
        sta current_music

        lda #15
        sta SID1_VOLUME
        ldy dual_sid_enabled
        beq +
        sta SID2_VOLUME
+
        lda #0
        sta music_part
        sta music_step
        sta music_delay
        sta sfx_timer
        sta sfx_voice
        sta secret_chime_active
        sta secret_chime_timer
        sta secret_chime_idx
        sta secret_chime_pending
        sta sfx_rupee_pending
        sta sfx_pending_idx
        sta cur_music_v1_note
        sta cur_music_v2_note
        sta cur_music_v3_note

        lda current_music
        cmp #MUSIC_OVERWORLD
        beq .init_overworld_inst
        cmp #MUSIC_DUNGEON
        bcs .init_dungeon_inst
.already_playing:
        rts

.init_overworld_inst:
        ; --- Instruments Overworld Authentiques ---
        ; Voix 1 : Cuivre / Lead héroïque (Pulse 50%)
        lda #$00
        sta SID1_V1_PW_LO
        lda #$08                        ; Impulsion 50%
        sta SID1_V1_PW_HI
        lda #$08                        ; Attack 2ms, Decay 750ms
        sta SID1_V1_AD
        lda #$c2                        ; Sustain 12, Release 24ms
        sta SID1_V1_SR
        lda #%01000000                  ; Pulse Gate OFF (attendre apply_music_step)
        sta SID1_V1_CTRL

        ; Voix 2 : Harmonie & Basse héroïque (Sawtooth chaud)
        lda #$07                        ; Attack 2ms, Decay 500ms
        sta SID1_V2_AD
        lda #$a2                        ; Sustain 10, Release 24ms
        sta SID1_V2_SR
        lda #%00100000                  ; Sawtooth Gate OFF (attendre apply_music_step)
        sta SID1_V2_CTRL

        ; Voix 3 : Basse héroïque marchante (Triangle pur)
        lda #$09                        ; Attack 2ms, Decay 750ms
        sta SID1_V3_AD
        lda #$e2                        ; Sustain 14, Release 24ms
        sta SID1_V3_SR
        lda #%00010000                  ; Triangle Gate OFF (attendre apply_music_step)
        sta SID1_V3_CTRL

        ; Si Dual SID, configure SID 2 pour le chorus stéréo
        lda dual_sid_enabled
        beq +
        lda #$00
        sta SID2_V1_PW_LO
        lda #$08
        sta SID2_V1_PW_HI
        lda #$08
        sta SID2_V1_AD
        lda #$c2
        sta SID2_V1_SR
        lda #%01000000
        sta SID2_V1_CTRL
        lda #$07
        sta SID2_V2_AD
        lda #$a2
        sta SID2_V2_SR
        lda #%00100000
        sta SID2_V2_CTRL
        lda #$09
        sta SID2_V3_AD
        lda #$e2
        sta SID2_V3_SR
        lda #%00010000
        sta SID2_V3_CTRL
+       rts


.init_dungeon_inst:
        ; --- Instruments Underworld (Dungeon) Authentiques ---
        ; Voix 1 : Pulse 50% ($0800), arpeggio lead
        lda #$00
        sta SID1_V1_PW_LO
        lda #$08                        ; Impulsion 50%
        sta SID1_V1_PW_HI
        lda #$09                        ; Attack 2ms, Decay 750ms
        sta SID1_V1_AD
        lda #$c0                        ; Sustain 12, Release 6ms
        sta SID1_V1_SR
        lda #%01000000                  ; Pulse Gate OFF (attendre apply_music_step)
        sta SID1_V1_CTRL

        ; Voix 2 : Pulse 50% ($0800), arpeggio contre-chant (NES Square 0)
        lda #$00
        sta SID1_V2_PW_LO
        lda #$08
        sta SID1_V2_PW_HI
        lda #$09
        sta SID1_V2_AD
        lda #$c0
        sta SID1_V2_SR
        lda #%01000000                  ; Pulse Gate OFF (attendre apply_music_step)
        sta SID1_V2_CTRL

        ; Voix 3 : Basse des profondeurs (Triangle pur, octave basse)
        lda #$09
        sta SID1_V3_AD
        lda #$e2
        sta SID1_V3_SR
        lda #%00010000                  ; Triangle Gate OFF (attendre apply_music_step)
        sta SID1_V3_CTRL

        lda dual_sid_enabled
        beq +
        lda #$00
        sta SID2_V1_PW_LO
        lda #$08
        sta SID2_V1_PW_HI
        lda #$09
        sta SID2_V1_AD
        lda #$c0
        sta SID2_V1_SR
        lda #%01000000
        sta SID2_V1_CTRL

        lda #$00
        sta SID2_V2_PW_LO
        lda #$08
        sta SID2_V2_PW_HI
        lda #$09
        sta SID2_V2_AD
        lda #$c0
        sta SID2_V2_SR
        lda #%01000000
        sta SID2_V2_CTRL

        lda #$09
        sta SID2_V3_AD
        lda #$e2
        sta SID2_V3_SR
        lda #%00010000
        sta SID2_V3_CTRL
+       rts

; ---------------------------------------------------------------------------
; music_stop : Coupe la musique et coupe les portes Gate
; ---------------------------------------------------------------------------
music_stop:
        lda #MUSIC_NONE
        sta current_music
        lda #%01000000                  ; Pulse Gate OFF
        sta SID1_V1_CTRL
        lda #%00100000                  ; Sawtooth Gate OFF
        sta SID1_V2_CTRL
        lda #%00010000                  ; Triangle Gate OFF
        sta SID1_V3_CTRL
        lda dual_sid_enabled
        beq +
        lda #%01000000
        sta SID2_V1_CTRL
        lda #%00100000
        sta SID2_V2_CTRL
        lda #%00010000
        sta SID2_V3_CTRL
+       lda #0
        sta sfx_timer
        sta sfx_voice
        sta secret_chime_active
        sta secret_chime_timer
        sta secret_chime_idx
        sta secret_chime_pending
        sta sfx_rupee_pending
        sta sfx_pending_idx
        sta cur_music_v1_note
        sta cur_music_v2_note
        sta cur_music_v3_note
        rts

; ---------------------------------------------------------------------------
; restore_music_voice : Rétablit proprement la voix SID occupée par un SFX
; ---------------------------------------------------------------------------
restore_music_voice:
        lda sfx_voice
        cmp #2
        beq restore_music_voice_2
        jmp restore_music_voice_3

; ---------------------------------------------------------------------------
; restore_music_voice_2 : Rétablissement dédié et indépendant de la Voix 2
; ---------------------------------------------------------------------------
restore_music_voice_2:
        lda current_music
        bne +
        ; Pas de musique active : coupe la voix 2
        lda #%00000000                  ; Voice 2 Gate OFF
        sta SID1_V2_CTRL
        ldy dual_sid_enabled
        beq .r2_rts
        sta SID2_V2_CTRL
.r2_rts:
        rts

+       lda current_music
        cmp #MUSIC_DUNGEON
        bcs .res_v2_uw

        ; Overworld : Sawtooth
        lda #$07
        sta SID1_V2_AD
        lda #$a2
        sta SID1_V2_SR
        ldy dual_sid_enabled
        beq +
        lda #$07
        sta SID2_V2_AD
        lda #$a2
        sta SID2_V2_SR
+       ldx cur_music_v2_note
        beq .mute_v2_ow
        lda music_note_freq_lo,x
        sta SID1_V2_FREQ_LO
        lda music_note_freq_hi,x
        sta SID1_V2_FREQ_HI
        lda #%00100000                  ; Gate OFF (>= 16 cycles pour réarmer ADSR)
        sta SID1_V2_CTRL
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        lda #%00100001                  ; Sawtooth Gate ON
        sta SID1_V2_CTRL
        ldy dual_sid_enabled
        beq +
        lda music_note_freq_lo,x
        clc
        adc #2
        sta SID2_V2_FREQ_LO
        lda music_note_freq_hi,x
        adc #0
        sta SID2_V2_FREQ_HI
        lda #%00100000
        sta SID2_V2_CTRL
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        lda #%00100001
        sta SID2_V2_CTRL
+       rts

.mute_v2_ow:
        lda #%00100000                  ; Sawtooth Gate OFF
        sta SID1_V2_CTRL
        ldy dual_sid_enabled
        beq +
        sta SID2_V2_CTRL
+       rts

.res_v2_uw:
        lda #$00
        sta SID1_V2_PW_LO
        lda #$08
        sta SID1_V2_PW_HI
        lda #$09
        sta SID1_V2_AD
        lda #$c0
        sta SID1_V2_SR

        ldy dual_sid_enabled
        beq +
        lda #$00
        sta SID2_V2_PW_LO
        lda #$08
        sta SID2_V2_PW_HI
        lda #$09
        sta SID2_V2_AD
        lda #$c0
        sta SID2_V2_SR
+       ldx cur_music_v2_note
        beq .mute_v2_uw
        lda music_note_freq_lo,x
        sta SID1_V2_FREQ_LO
        lda music_note_freq_hi,x
        sta SID1_V2_FREQ_HI
        lda #%01000000                  ; Gate OFF (>= 16 cycles pour réarmer ADSR)
        sta SID1_V2_CTRL
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        lda #%01000001                  ; Pulse Gate ON
        sta SID1_V2_CTRL
        ldy dual_sid_enabled
        beq +
        lda #$00
        sta SID2_V2_PW_LO
        lda #$08
        sta SID2_V2_PW_HI
        lda #$09
        sta SID2_V2_AD
        lda #$c0
        sta SID2_V2_SR
        lda music_note_freq_lo,x
        clc
        adc #2
        sta SID2_V2_FREQ_LO
        lda music_note_freq_hi,x
        adc #0
        sta SID2_V2_FREQ_HI
        lda #%01000000
        sta SID2_V2_CTRL
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        lda #%01000001
        sta SID2_V2_CTRL
+       rts

.mute_v2_uw:
        lda #%01000000                  ; Pulse Gate OFF
        sta SID1_V2_CTRL
        ldy dual_sid_enabled
        beq +
        sta SID2_V2_CTRL
+       rts

; ---------------------------------------------------------------------------
; restore_music_voice_3 : Rétablissement dédié et indépendant de la Voix 3
; ---------------------------------------------------------------------------
restore_music_voice_3:
        lda current_music
        bne +
        ; Pas de musique active : coupe la voix 3
        lda #%00010000                  ; Voice 3 Triangle Gate OFF
        sta SID1_V3_CTRL
        ldy dual_sid_enabled
        beq .r3_rts
        sta SID2_V3_CTRL
.r3_rts:
        rts

+       ; 1. Rétablir ADSR de la Voix 3
        lda #$09
        sta SID1_V3_AD
        lda #$e2
        sta SID1_V3_SR
        ldy dual_sid_enabled
        beq +
        lda #$09
        sta SID2_V3_AD
        lda #$e2
        sta SID2_V3_SR
+
        ; 2. Rétablir la note de basse si une note était active
        ldx cur_music_v3_note
        beq .mute_v3
        cpx #$80
        beq .mute_v3                    ; Percussion : ne pas relancer

        lda music_note_freq_lo,x
        sta SID1_V3_FREQ_LO
        lda music_note_freq_hi,x
        sta SID1_V3_FREQ_HI
        lda #%00010000                  ; Gate OFF pour réarmer l'ADSR
        sta SID1_V3_CTRL
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        lda #%00010001                  ; Triangle Gate ON
        sta SID1_V3_CTRL

        ldy dual_sid_enabled
        beq +
        lda music_note_freq_lo,x
        sta SID2_V3_FREQ_LO
        lda music_note_freq_hi,x
        sta SID2_V3_FREQ_HI
        lda #%00010000
        sta SID2_V3_CTRL
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        lda #%00010001
        sta SID2_V3_CTRL
+       rts

.mute_v3:
        lda #%00010000                  ; Gate OFF
        sta SID1_V3_CTRL
        ldy dual_sid_enabled
        beq +
        sta SID2_V3_CTRL
+       rts

; ---------------------------------------------------------------------------
; music_update : Mise à jour par interruption 50 Hz (VBlank)
; ---------------------------------------------------------------------------
music_update:
        ; 1. Mise à jour synchrone 50 Hz du carillon secret
        jsr update_secret_chime

        ; 2. Gestion du compte à rebours d'effet sonore
        lda sfx_timer
        beq .check_pending_chime
        dec sfx_timer
        bne .check_pending_chime
        ; Fin de l'effet sonore : restaure intégralement la voix de musique
        jsr restore_music_voice
        lda #0
        sta sfx_voice

.check_pending_chime:
        lda secret_chime_pending
        beq .check_delay
        lda sfx_timer
        bne .check_delay
        lda #0
        sta secret_chime_pending
        jsr sound_secret_chime

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
        bne +
        jmp .step_overworld
+       cmp #MUSIC_DUNGEON
        bne +
        jmp .step_dungeon
+       cmp #MUSIC_DUNGEON_FINAL
        bne +
        jmp .step_dungeon_final
+       cmp #MUSIC_ITEM_FANFARE
        beq .step_item_fanfare
        cmp #MUSIC_TRIFORCE
        beq .step_triforce
        rts

; ---------------------------------------------------------------------------
; Déroulement Fanfare Objet (SongScriptItemTaken0 - 4 pas, reprise auto BGM)
; ---------------------------------------------------------------------------
.step_item_fanfare:
        ldx music_step
        cpx #MUSIC_ITEM_LEN
        bcc .item_read
        ; Fin de la fanfare d'objet : reprend la musique de fond sauvegardée
        lda #MUSIC_NONE
        sta current_music
        lda #0
        sta secret_chime_active
        sta secret_chime_timer
        sta secret_chime_idx
        sta secret_chime_pending
        sta sfx_rupee_pending
        sta sfx_timer
        sta sfx_voice
        lda saved_bg_music
        beq .stop_fanfare
        jmp music_play
.stop_fanfare:
        jmp music_stop
.item_read:
        lda music_item_fanfare_dur,x
        sta music_delay
        lda music_item_fanfare_v1,x
        sta temp_v1
        lda music_item_fanfare_v2,x
        sta temp_v2
        lda music_item_fanfare_v3,x
        sta temp_v3
        inc music_step
        jmp .apply_music_step

; ---------------------------------------------------------------------------
; Déroulement Fanfare Triforce / Victoire (SongScriptEndLevel0 - 41 pas)
; ---------------------------------------------------------------------------
.step_triforce:
        ldx music_step
        cpx #MUSIC_TRIFORCE_LEN
        bcc .tri_read
        jmp music_stop
.tri_read:
        lda music_triforce_dur,x
        sta music_delay
        lda music_triforce_v1,x
        sta temp_v1
        lda music_triforce_v2,x
        sta temp_v2
        lda music_triforce_v3,x
        sta temp_v3
        inc music_step
        jmp .apply_music_step

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
; Déroulement Underworld / Dungeon (Niveaux 1 à 8)
; ---------------------------------------------------------------------------
.step_dungeon:
        ldx music_step
        cpx #MUSIC_UW_LEN
        bcc .uw_read
        ; Boucle du donjon
        ldx #0
        stx music_step
.uw_read:
        lda #8                          ; Durée constante Underworld D1..D8 (8 frames = 160ms)
        sta music_delay
        lda music_uw_v1,x
        sta temp_v1
        lda music_uw_v2,x
        sta temp_v2
        lda music_uw_v3,x
        sta temp_v3
        inc music_step
        jmp .apply_music_step

; ---------------------------------------------------------------------------
; Déroulement Donjon 9 (SongScriptLastLevel0 - Death Mountain, 124 Pas)
; ---------------------------------------------------------------------------
.step_dungeon_final:
        ldx music_step
        cpx #MUSIC_D9_LEN
        bcc .d9_read
        ; Boucle : retour au début
        ldx #0
        stx music_step

.d9_read:
        lda music_d9_dur,x
        sta music_delay
        lda music_d9_v1,x
        sta temp_v1
        lda music_d9_v2,x
        sta temp_v2
        lda music_d9_v3,x
        sta temp_v3
        inc music_step
        jmp .apply_music_step

; ---------------------------------------------------------------------------
; Application des notes aux registres SID
; ---------------------------------------------------------------------------
.apply_music_step:
        ; --- VOIX 1 : Mélodie Principale ---
        ldx temp_v1
        cpx #$fe
        beq +
        stx cur_music_v1_note
+
        lda sfx_timer
        beq +
        lda sfx_voice
        cmp #1
        bne +
        jmp .skip_v1                    ; Voix 1 occupée par un SFX
+
        ldx temp_v1
        bne +
        jmp .v1_mute
+       cpx #$fe                        ; $FE = TIE / HOLD (prolonger la note sans réarmer l'enveloppe)
        bne +
        jmp .skip_v1
+
        lda music_note_freq_lo,x
        sta SID1_V1_FREQ_LO
        lda music_note_freq_hi,x
        sta SID1_V1_FREQ_HI

        lda #$00
        sta SID1_V1_PW_LO
        lda #$08
        sta SID1_V1_PW_HI
        lda current_music
        cmp #MUSIC_DUNGEON
        bcs .v1_adsr_uw
        lda #$08
        sta SID1_V1_AD
        lda #$c2
        sta SID1_V1_SR
        jmp .v1_adsr_done
.v1_adsr_uw:
        lda #$09
        sta SID1_V1_AD
        lda #$c0
        sta SID1_V1_SR
.v1_adsr_done:
        lda #%01000000                  ; Gate OFF pour réarmer l'ADSR
        sta SID1_V1_CTRL
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
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
        lda #%01000000
        sta SID2_V1_CTRL
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        lda #%01000001
        sta SID2_V1_CTRL
        jmp .skip_v1

.v1_mute:
        lda #%01000000                  ; Gate OFF
        sta SID1_V1_CTRL
        ldy dual_sid_enabled
        beq .skip_v1
        sta SID2_V1_CTRL
.skip_v1:

        ; --- VOIX 2 : Harmonie / Contre-chant ---
        ldx temp_v2
        cpx #$fe
        beq +
        stx cur_music_v2_note
+
        ; Si le carillon secret est actif, ignorer totalement la mise à jour matérielle de la Voix 2
        lda secret_chime_active
        beq +
        jmp .skip_v2
+
        lda sfx_timer
        beq +
        lda sfx_voice
        cmp #2
        bne +
        jmp .skip_v2
+
        ldx temp_v2
        bne .v2_play
        lda current_music
        cmp #MUSIC_DUNGEON
        bcs +
        lda #%00100000                  ; Sawtooth Gate OFF (Overworld)
        jmp ++
+       lda #%01000000                  ; Pulse Gate OFF (Dungeons & Fanfares)
++      sta SID1_V2_CTRL
        ldy dual_sid_enabled
        beq +
        sta SID2_V2_CTRL
+       jmp .skip_v2

.v2_play:
        cpx #$fe                        ; $FE = TIE / HOLD (prolonger l'harmonie sans réarmer)
        bne .v2_new_note
        ; Sur un HOLD ($FE), s'assurer que le Gate est bien ON UNIQUEMENT si une note est active !
        ldx cur_music_v2_note
        bne +
        jmp .skip_v2                    ; Si pas de note active, reste silencieux !
+
        lda current_music
        cmp #MUSIC_DUNGEON
        bcs .v2_hold_uw
        lda #%00100001                  ; Sawtooth Gate ON
        sta SID1_V2_CTRL
        ldy dual_sid_enabled
        beq +
        sta SID2_V2_CTRL
+       jmp .skip_v2
.v2_hold_uw:
        lda #%01000001                  ; Pulse Gate ON
        sta SID1_V2_CTRL
        ldy dual_sid_enabled
        beq +
        sta SID2_V2_CTRL
+       jmp .skip_v2

.v2_new_note:
        lda music_note_freq_lo,x
        sta SID1_V2_FREQ_LO
        lda music_note_freq_hi,x
        sta SID1_V2_FREQ_HI

        lda current_music
        cmp #MUSIC_DUNGEON
        bcs .v2_pulse
        ; Overworld : Sawtooth
        lda #$07
        sta SID1_V2_AD
        lda #$a2
        sta SID1_V2_SR
        lda #%00100000                  ; Gate OFF pour réarmer l'ADSR
        sta SID1_V2_CTRL
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        lda #%00100001                  ; Sawtooth Gate ON
        sta SID1_V2_CTRL
        jmp .v2_dual_sid

.v2_pulse:
        ; Underworld / Fanfares : Pulse 50%
        lda #$00
        sta SID1_V2_PW_LO
        lda #$08
        sta SID1_V2_PW_HI
        lda #$09
        sta SID1_V2_AD
        lda #$c0
        sta SID1_V2_SR
        lda #%01000000                  ; Gate OFF
        sta SID1_V2_CTRL
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        lda #%01000001                  ; Pulse Gate ON
        sta SID1_V2_CTRL

.v2_dual_sid:
        lda dual_sid_enabled
        beq .skip_v2
        lda music_note_freq_lo,x
        clc
        adc #2
        sta SID2_V2_FREQ_LO
        lda music_note_freq_hi,x
        adc #0
        sta SID2_V2_FREQ_HI
        lda current_music
        cmp #MUSIC_DUNGEON
        bcs .v2_dual_pulse
        lda #%00100000
        sta SID2_V2_CTRL
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        lda #%00100001
        sta SID2_V2_CTRL
        jmp .skip_v2
.v2_dual_pulse:
        lda #$00
        sta SID2_V2_PW_LO
        lda #$08
        sta SID2_V2_PW_HI
        lda #$09
        sta SID2_V2_AD
        lda #$c0
        sta SID2_V2_SR
        lda #%01000000
        sta SID2_V2_CTRL
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        lda #%01000001
        sta SID2_V2_CTRL
.skip_v2:

        ; --- VOIX 3 : Percussion ou Basse ---
        lda temp_v3
        cmp #$fe
        beq +
        sta cur_music_v3_note
+
        lda sfx_timer
        beq +
        lda sfx_voice
        cmp #3
        bne +
        jmp .skip_v3                    ; Voix 3 occupée par un SFX
+
        lda temp_v3
        bne +
        jmp .v3_mute
+       cmp #$fe                        ; $FE = TIE / HOLD
        bne .v3_not_hold
        ; Sur un HOLD ($FE), s'assurer que le Gate de basse est bien ON si une note de basse était active
        ldx cur_music_v3_note
        beq .to_skip_v3
        cpx #$80
        beq .to_skip_v3                 ; Percussion n'est pas maintenue
        lda #%00010001                  ; Triangle Gate ON
        sta SID1_V3_CTRL
        ldy dual_sid_enabled
        beq .to_skip_v3
        sta SID2_V3_CTRL
.to_skip_v3:
        jmp .skip_v3

.v3_not_hold:
        cmp #$80
        beq .v3_percussion

        ; Basse mélodique (Overworld & Underworld)
        tax
        lda music_note_freq_lo,x
        sta SID1_V3_FREQ_LO
        lda music_note_freq_hi,x
        sta SID1_V3_FREQ_HI
        lda #$09
        sta SID1_V3_AD
        lda #$e2
        sta SID1_V3_SR
        lda #%00010000                  ; Gate OFF pour réarmer l'ADSR
        sta SID1_V3_CTRL
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        lda #%00010001                  ; Triangle Gate ON
        sta SID1_V3_CTRL

        lda dual_sid_enabled
        beq .skip_v3
        lda music_note_freq_lo,x
        sta SID2_V3_FREQ_LO
        lda music_note_freq_hi,x
        sta SID2_V3_FREQ_HI
        lda #%00010000
        sta SID2_V3_CTRL
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        lda #%00010001
        sta SID2_V3_CTRL
        rts

.v3_percussion:
        ; Caisse claire / Percussion militaire
        lda #$80
        sta SID1_V3_FREQ_LO
        lda #$28
        sta SID1_V3_FREQ_HI
        lda #$04
        sta SID1_V3_AD
        lda #$00
        sta SID1_V3_SR
        lda #%10000000                  ; Bruit Gate OFF
        sta SID1_V3_CTRL
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        lda #%10000001                  ; Bruit Gate ON
        sta SID1_V3_CTRL
        rts

.v3_mute:
        lda #%00010000                  ; Gate OFF
        sta SID1_V3_CTRL
        ldy dual_sid_enabled
        beq .skip_v3
        sta SID2_V3_CTRL
.skip_v3:
        rts

temp_v1:        !byte 0
temp_v2:        !byte 0
temp_v3:        !byte 0

; ===========================================================================
; EFFETS SONORES (SFX)
; En mode Dual SID, jouent sur SID 2 pour préserver 100% de la musique sur SID 1.
; En mode Single SID, s'intègrent sur Voix 3 avec restauration automatique.
; ===========================================================================

SFX_SWORD         = 0
SFX_ENEMY_SHOOT   = 1
SFX_ENEMY_HIT     = 2
SFX_ENEMY_DIE     = 3
SFX_SHIELD_BLOCK  = 4
SFX_RUPEE         = 5
SFX_ARROW         = 6
SFX_BOOMERANG     = 7
SFX_BOMB_EXPLODE  = 8
SFX_CANDLE        = 9
SFX_WAND          = 10
SFX_FOOD          = 11
SFX_POTION        = 12
SFX_LINK_HURT     = 13
SFX_ITEM_FANFARE  = 14
SFX_FLUTE         = 15
SFX_INV_FLIP      = 16
SFX_INV_SELECT    = 17
SFX_BOSS_ROAR     = 18

sfx_saved_x:      !byte 0

sound_sword:
        stx sfx_saved_x
        ldx #SFX_SWORD
        jmp play_sfx_v3
sound_enemy_shoot:
        stx sfx_saved_x
        ldx #SFX_ENEMY_SHOOT
        jmp play_sfx_v3
sound_enemy_hit:
        stx sfx_saved_x
        ldx #SFX_ENEMY_HIT
        jmp play_sfx_v3
sound_enemy_die:
        stx sfx_saved_x
        ldx #SFX_ENEMY_DIE
        jmp play_sfx_v3
sound_shield_block:
        stx sfx_saved_x
        ldx #SFX_SHIELD_BLOCK
        jmp play_sfx_v3
sound_rupee:
        lda secret_chime_active
        beq +
        ; Carillon actif : on met le son de rupee en attente pour jouer à la suite
        lda #1
        sta sfx_rupee_pending
        rts
+       stx sfx_saved_x
        ldx #SFX_RUPEE
        jmp play_sfx_v3
sound_arrow:
        stx sfx_saved_x
        ldx #SFX_ARROW
        jmp play_sfx_v3
sound_boomerang:
        stx sfx_saved_x
        ldx #SFX_BOOMERANG
        jmp play_sfx_v3
sound_bomb_explode:
        stx sfx_saved_x
        ldx #SFX_BOMB_EXPLODE
        jmp play_sfx_v3
sound_candle:
        stx sfx_saved_x
        ldx #SFX_CANDLE
        jmp play_sfx_v3
sound_wand:
        stx sfx_saved_x
        ldx #SFX_WAND
        jmp play_sfx_v3
sound_food:
        stx sfx_saved_x
        ldx #SFX_FOOD
        jmp play_sfx_v3
sound_potion:
        stx sfx_saved_x
        ldx #SFX_POTION
        jmp play_sfx_v3
sound_link_hurt:
        stx sfx_saved_x
        ldx #SFX_LINK_HURT
        jmp play_sfx_v3
sound_flute:
        stx sfx_saved_x
        ldx #SFX_FLUTE
        jmp play_sfx_v3
sound_inv_flip:
        stx sfx_saved_x
        ldx #SFX_INV_FLIP
        jmp play_sfx_v3
sound_inv_select:
        stx sfx_saved_x
        ldx #SFX_INV_SELECT
        jmp play_sfx_v3
sound_boss_roar:
        stx sfx_saved_x
        ldx #SFX_BOSS_ROAR
        jmp play_sfx_v3

sound_item_fanfare:
        lda #0
        sta secret_chime_active
        sta secret_chime_timer
        sta secret_chime_idx
        sta secret_chime_pending
        sta sfx_rupee_pending
        sta sfx_timer
        sta sfx_voice
        lda current_music
        cmp #MUSIC_ITEM_FANFARE
        beq +
        cmp #MUSIC_TRIFORCE
        beq +
        sta saved_bg_music
+       lda #MUSIC_NONE
        sta current_music
        lda #MUSIC_ITEM_FANFARE
        jmp music_play

sound_triforce_fanfare:
        lda #MUSIC_NONE
        sta saved_bg_music
        sta current_music
        lda #MUSIC_TRIFORCE
        jmp music_play

play_sfx_v3:
        lda secret_chime_active
        beq .play_now
        ; Carillon actif : on met le SFX en attente dans la file au lieu de voler Voix 3
        cpx #SFX_RUPEE
        bne +
        lda #1
        sta sfx_rupee_pending
+       inx
        stx sfx_pending_idx
        ldx sfx_saved_x
        rts

.play_now:
        lda #3
        sta sfx_voice
        lda sfx_timer_tbl,x
        sta sfx_timer

        lda sfx_freq_lo_tbl,x
        sta SID1_V3_FREQ_LO
        lda sfx_freq_hi_tbl,x
        sta SID1_V3_FREQ_HI
        lda sfx_ad_tbl,x
        sta SID1_V3_AD
        lda sfx_sr_tbl,x
        sta SID1_V3_SR
        lda #0
        sta SID1_V3_CTRL
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        lda sfx_ctrl_tbl,x
        sta SID1_V3_CTRL

        lda dual_sid_enabled
        beq .sfx_v3_done

        lda sfx_freq_lo_tbl,x
        sta SID2_V3_FREQ_LO
        lda sfx_freq_hi_tbl,x
        sta SID2_V3_FREQ_HI
        lda sfx_ad_tbl,x
        sta SID2_V3_AD
        lda sfx_sr_tbl,x
        sta SID2_V3_SR
        lda #0
        sta SID2_V3_CTRL
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        lda sfx_ctrl_tbl,x
        sta SID2_V3_CTRL

.sfx_v3_done:
        ldx sfx_saved_x
        rts

sfx_timer_tbl:
        !byte 6, 5, 6, 10, 4, 8, 5, 4, 14, 6, 8, 6, 8, 8, 20, 25, 3, 4, 26
sfx_freq_lo_tbl:
        !byte $00, $20, $80, $00, $00, $a0, $80, $00, $00, $40, $00, $00, $80, $00, $80, $80, $00, $00, $60
sfx_freq_hi_tbl:
        !byte $48, $25, $30, $18, $70, $65, $48, $28, $12, $1c, $50, $18, $24, $14, $50, $48, $28, $30, $04
sfx_ad_tbl:
        !byte $09, $06, $04, $0c, $02, $05, $02, $04, $00, $08, $02, $04, $04, $08, $09, $09, $02, $04, $39
sfx_sr_tbl:
        !byte $00, $00, $00, $00, $00, $00, $00, $00, $0a, $00, $00, $00, $00, $00, $40, $40, $00, $00, $64
sfx_ctrl_tbl:
        !byte %10000001, %00100001, %10000001, %10000001, %00010001, %00010001, %10000001, %00010001
        !byte %10000001, %10000001, %00100001, %10000001, %00010001, %10000001, %00010001, %00010001
        !byte %00010001, %00010001, %10000001

; ---------------------------------------------------------------------------
; sound_secret_chime / sound_secret : Déclenche le carillon triomphal
; ---------------------------------------------------------------------------
sound_secret_chime:
sound_secret:
        lda sfx_timer
        beq .start_chime_now
        lda sfx_voice
        cmp #3
        bne .start_chime_now
        ; Un SFX est en cours sur Voix 3 (ex: ramassage de clé) : on met le carillon en attente
        lda #1
        sta secret_chime_pending
        rts

.start_chime_now:
        lda #0
        sta secret_chime_pending
        lda #1
        sta secret_chime_active
        lda #0
        sta secret_chime_idx
        lda #1                          ; Première note dès la prochaine frame
        sta secret_chime_timer
        rts

; ---------------------------------------------------------------------------
; update_secret_chime : Avancement synchrone à 50 Hz dans l'interruption raster
; ---------------------------------------------------------------------------
update_secret_chime:
        lda secret_chime_active
        bne +
        rts
+       dec secret_chime_timer
        beq +
        rts
+       lda #7                          ; 7 frames par note (~0.14s)
        sta secret_chime_timer

        ldx secret_chime_idx
        cpx #8
        bcs .stop_chime

        lda secret_chime_lo,x
        sta SID1_V2_FREQ_LO
        lda secret_chime_hi,x
        sta SID1_V2_FREQ_HI
        lda #15
        sta SID1_VOLUME
        lda #$03
        sta SID1_V2_AD
        lda #$a4
        sta SID1_V2_SR
        lda #%00010000                  ; Triangle Gate OFF (>= 16 cycles pour réarmer)
        sta SID1_V2_CTRL
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        lda #%00010001                  ; Triangle Gate ON
        sta SID1_V2_CTRL

        lda dual_sid_enabled
        beq +
        lda #15
        sta SID2_VOLUME
        lda secret_chime_lo,x
        sta SID2_V2_FREQ_LO
        lda secret_chime_hi,x
        sta SID2_V2_FREQ_HI
        lda #$03
        sta SID2_V2_AD
        lda #$a4
        sta SID2_V2_SR
        lda #%00010000
        sta SID2_V2_CTRL
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        lda #%00010001
        sta SID2_V2_CTRL
+
        inc secret_chime_idx
        rts

.stop_chime:
        lda #%00010000                  ; Gate OFF
        sta SID1_V2_CTRL
        ldy dual_sid_enabled
        beq +
        sta SID2_V2_CTRL
+       lda #0
        sta secret_chime_active
        sta secret_chime_idx
        sta secret_chime_timer
        jsr restore_music_voice_2

        ; Si un son de rupee/clé était en attente, le déclencher immédiatement à la suite !
        lda sfx_rupee_pending
        beq +
        lda #0
        sta sfx_rupee_pending
        sta sfx_pending_idx
        jsr sound_rupee
        rts
+
        ; Tout autre SFX en attente dans la file (épée, monstre, etc.)
        ldx sfx_pending_idx
        beq +
        lda #0
        sta sfx_pending_idx
        dex                             ; Restaure l'index SFX original
        jsr play_sfx_v3
+       rts

.chime_done:
        rts

sound_code_end:

secret_chime_lo:
        !byte $1c, $bd, $d4, $e7, $2f, $91, $5d, $a0
secret_chime_hi:
        !byte $16, $14, $10, $0c, $0c, $11, $17, $1d

; Données musicales incluses
!source "src/music_data.inc"


