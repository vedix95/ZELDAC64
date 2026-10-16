#!/usr/bin/env python3
"""Génère tous les sprites additionnels officiels de The Legend of Zelda 1 (NES 1986)
pour Commodore 64 VIC-II et les ajoute dans assets/enemies.txt.
"""

NEW_SPRITES = """
# ===========================================================================
# NOUVEAUX ENNEMIS OFFICIELS ZELDA 1 NES (1986)
# ===========================================================================

# ---------------------------------------------------------------------------
# 3. TEKTITE (Araignée sauteuse rouge & bleue)
# ---------------------------------------------------------------------------
[tektite_0]
..gggg..
.gssssg.
gssbbssg
gssbbssg
.gssssg.
..gggg..
.gg..gg.
gg....gg
g.g..g.g
g.gggg.g
g......g
g......g
.b....b.
.b....b.
........
........

[tektite_1]
..gggg..
.gssssg.
gssbbssg
gssbbssg
.gssssg.
..gggg..
gggggggg
g......g
g.gggg.g
g.g..g.g
gg....gg
g......g
b......b
.b....b.
........
........

# ---------------------------------------------------------------------------
# 4. LEEVER (Créature fouisseuse rotative rouge & bleue)
# ---------------------------------------------------------------------------
[leever_0]
...gg...
..gggg..
.ggssgg.
ggssssgg
ggsbbsgg
gssbbssg
gssbbssg
ggsbbsgg
.ggssgg.
g.gggg.g
gg.gg.gg
.gggggg.
..bbbb..
...bb...
........
........

[leever_1]
..gggg..
.ggssgg.
ggssssgg
ggsbbsgg
gssbbssg
gssbbssg
ggsbbsgg
.ggssgg.
..gggg..
gg.gg.gg
g.gggg.g
.gggggg.
..bbbb..
...bb...
........
........

# ---------------------------------------------------------------------------
# 5. PEAHAT (Plante carnivore hélicoptère)
# ---------------------------------------------------------------------------
[peahat_0]
...gg...
..gggg..
.ggssgg.
ggssssgg
.ggssgg.
..gggg..
...gg...
..bbbb..
.bb..bb.
bb....bb
.bb..bb.
..bbbb..
...gg...
..gggg..
...gg...
........

[peahat_1]
gg....gg
.gg..gg.
..gggg..
.ggssgg.
ggssssgg
.ggssgg.
..gggg..
.bb..bb.
bb....bb
.bb..bb.
..bbbb..
...gg...
..gggg..
...gg...
........
........

# ---------------------------------------------------------------------------
# 6. ARMOS (Guerrier de pierre endormi)
# ---------------------------------------------------------------------------
[armos_0]
..bbbb..
.bggggb.
.bssssb.
.bsbbsb.
.bssssb.
.bggggb.
bggggggb
bggssggb
bggssggb
bggggggb
.bbbbbb.
.bggggb.
.bggggb.
.bb..bb.
.bb..bb.
........

[armos_1]
..bbbb..
.bggggb.
.bssssb.
.bsbbsb.
.bssssb.
.bggggb.
bggggggb
bggssggb
bggssggb
bggggggb
.bbbbbb.
.bgg.bgg
.bgg..bb
.bb.....
........
........

# ---------------------------------------------------------------------------
# 7. GHINI (Fantôme à œil unique du cimetière)
# ---------------------------------------------------------------------------
[ghini_0]
..bbbb..
.bggggb.
bggggggb
bggssggb
bgsbbsgb
bgsbbsgb
bggssggb
bggggggb
.bggggb.
.bggggb.
..bggb..
..bggb..
...bggb.
....bbb.
........
........

[ghini_1]
..bbbb..
.bggggb.
bggggggb
bggssggb
bgsbbsgb
bgsbbsgb
bggssggb
bggggggb
.bggggb.
.bggggb.
..bggb..
..bggb..
.bggb...
.bbb....
........
........

# ---------------------------------------------------------------------------
# 8. ZORA (Monstre des rivières cracheur de feu)
# ---------------------------------------------------------------------------
[zora_0]
..g..g..
.gg..gg.
.gggggg.
gssssssg
gssbbssg
gssssssg
.gssssg.
.gggggg.
..gggg..
...gg...
..gggg..
.gggggg.
........
........
........
........

[zora_1]
..g..g..
.gg..gg.
.gggggg.
gssssssg
gssbbssg
gssssssg
.gsbbsg.
.gsbbsg.
..gggg..
...gg...
..gggg..
.gggggg.
........
........
........
........

# ---------------------------------------------------------------------------
# 9. LYNEL (Centaure lion redoutable rouge & bleu)
# ---------------------------------------------------------------------------
[lynel_0]
.g.gg.g.
.gggggg.
.gssssg.
.gsbbsg.
.gssssg.
.gggggg.
.ggggggb
bggggggb
bggggggb
.bbbbbb.
.gg..gg.
.gg..gg.
.gg..gg.
.bb..bb.
.bb..bb.
........

[lynel_1]
.g.gg.g.
.gggggg.
.gssssg.
.gsbbsg.
.gssssg.
.gggggg.
bgggggg.
bggggggb
bggggggb
.bbbbbb.
..gggg..
..gggg..
.gg..gg.
.bb..bb.
..b..b..
........

# ---------------------------------------------------------------------------
# 10. KEESE (Chauve-souris des donjons)
# ---------------------------------------------------------------------------
[keese_0]
g......g
gg....gg
bgg..ggb
bggssggb
.gsbbsg.
.gssssg.
..gggg..
...bb...
........
........
........
........
........
........
........
........

[keese_1]
..gggg..
.gsbbsg.
.gssssg.
bggssggb
bgg..ggb
gg....gg
g......g
...bb...
........
........
........
........
........
........
........
........

# ---------------------------------------------------------------------------
# 11. ZOL & GEL (Slimes des donjons)
# ---------------------------------------------------------------------------
[zol_0]
........
........
........
..gggg..
.gggggg.
gssssssg
gssbbssg
gssbbssg
gssssssg
gggggggg
gggggggg
.bbbbbb.
........
........
........
........

[zol_1]
........
..gggg..
.gggggg.
gssssssg
gssbbssg
gssbbssg
gssssssg
gggggggg
gggggggg
.gggggg.
..bbbb..
........
........
........
........
........

[gel]
........
........
........
........
........
........
..gggg..
.gssssg.
.gsbbsg.
.gssssg.
.gggggg.
..bbbb..
........
........
........
........

# ---------------------------------------------------------------------------
# 12. ROPE (Serpent rapide à charge frontale)
# ---------------------------------------------------------------------------
[rope_0]
........
........
........
.gggg...
gssssg..
gsbbsg..
gssssggg
.ggggggg
..gggggg
...ggggg
....gggg
.....ggg
......bb
........
........
........

[rope_1]
........
........
........
.gggg...
gssssg..
gsbbsg..
gssssg..
.ggggggg
..gggggg
.ggggggg
gggg....
ggg.....
bb......
........
........
........

# ---------------------------------------------------------------------------
# 13. STALFOS (Guerrier squelette à double épée)
# ---------------------------------------------------------------------------
[stalfos_0]
b.bbbb.b
b.bggb.b
b.bssb.b
b.bsbb.b
b.bggb.b
b.bggb.b
b.bbbb.b
b..gg..b
b.gggg.b
b..gg..b
...gg...
..g..g..
..g..g..
..b..b..
..b..b..
........

[stalfos_1]
b.bbbb.b
b.bggb.b
b.bssb.b
b.bsbb.b
b.bggb.b
b.bggb.b
b.bbbb.b
b..gg..b
b.gggg.b
b..gg..b
...gg...
...gg...
..g..g..
..b..b..
...b..b.
........

# ---------------------------------------------------------------------------
# 14. GORIYA (Démon chien lanceur de boomerang rouge & bleu)
# ---------------------------------------------------------------------------
[goriya_0]
..gggg..
.gssssg.
gssssssg
gsbbsbbg
gssssssg
.gssssg.
.gggggg.
.ggggggb
bggggggb
.bbbbbb.
..gggg..
.gg..gg.
.gg..gg.
.bb..bb.
.bb.....
........

[goriya_1]
..gggg..
.gssssg.
gssssssg
gsbbsbbg
gssssssg
.gssssg.
.gggggg.
bgggggg.
bggggggb
.bbbbbb.
..gggg..
.gg..gg.
.gg..gg.
.bb..bb.
.....bb.
........

# ---------------------------------------------------------------------------
# 15. DARKNUT (Chevalier en armure à bouclier frontal invincible)
# ---------------------------------------------------------------------------
[darknut_0]
..bbbb..
.bggggb.
.bssssb.
.bsbbsb.
.bssssb.
.bbbbbb.
bssssssb
bssssssb
bssssssb
.bbbbbb.
.bggggb.
.bggggb.
.bggggb.
.bb..bb.
.bb..bb.
........

[darknut_1]
..bbbb..
.bggggb.
.bssssb.
.bsbbsb.
.bssssb.
.bbbbbb.
bssssssb
bssssssb
bssssssb
.bbbbbb.
.bggggb.
..bggb..
.bggggb.
.bb..bb.
..b..b..
........

# ---------------------------------------------------------------------------
# 16. WIZZROBE (Sorcier téléporteur et jeteur de sorts)
# ---------------------------------------------------------------------------
[wizzrobe_0]
...gg...
..gggg..
.gssssg.
.gsbbsg.
.gssssg.
.gggggg.
bgggggg.
.bggggb.
.bggggb.
.bggggb.
.bggggb.
.bggggb.
.bbbbbb.
..bbbb..
...bb...
........

[wizzrobe_1]
...gg..b
..gggg.b
.gssssgb
.gsbbsgb
.gssssgb
.gggggg.
bgggggg.
.bggggb.
.bggggb.
.bggggb.
.bggggb.
.bggggb.
.bbbbbb.
..bbbb..
...bb...
........

# ---------------------------------------------------------------------------
# 17. WALLMASTER (Main spectrale des murs)
# ---------------------------------------------------------------------------
[wallmaster_0]
..b..b..
.bb..bb.
.bb..bb.
.bb..bb.
.bbbbbb.
.bggggb.
bggggggb
bggggggb
bggggggb
.bggggb.
.bggggb.
..bbbb..
...bb...
........
........
........

[wallmaster_1]
........
..bbbb..
.bbbbbb.
.bggggb.
bggggggb
bggggggb
bggggggb
.bggggb.
.bggggb.
..bbbb..
...bb...
........
........
........
........
........

# ---------------------------------------------------------------------------
# 18. LIKE LIKE (Mangeur de bouclier)
# ---------------------------------------------------------------------------
[likelike_0]
.bbbbbb.
bssssssb
bssssssb
.bbbbbb.
bggggggb
bggggggb
.bbbbbb.
bssssssb
bssssssb
.bbbbbb.
bggggggb
bggggggb
.bbbbbb.
..bbbb..
........
........

[likelike_1]
..bbbb..
.bssssb.
.bssssb.
.bbbbbb.
bggggggb
bggggggb
.bbbbbb.
bssssssb
bssssssb
.bbbbbb.
bggggggb
bggggggb
.bbbbbb.
..bbbb..
........
........

# ---------------------------------------------------------------------------
# 19. POLS VOICE (Créature aux grandes oreilles sauteuse)
# ---------------------------------------------------------------------------
[polsvoice_0]
.g....g.
.g....g.
.gg..gg.
.gs..sg.
.gs..sg.
.gggggg.
gssssssg
gssbbssg
gssssssg
.gssssg.
.gggggg.
.gggggg.
..gggg..
.bb..bb.
.bb..bb.
........

[polsvoice_1]
........
.g....g.
.g....g.
.gg..gg.
.gs..sg.
.gggggg.
gssssssg
gssbbssg
gssssssg
.gssssg.
.gggggg.
.gggggg.
..gggg..
bb....bb
.bb..bb.
........

# ---------------------------------------------------------------------------
# 20. GIBDO (Momie antique)
# ---------------------------------------------------------------------------
[gibdo_0]
..bbbb..
.bssssb.
.bsbbsb.
.bsbbsb.
.bssssb.
.bbbbbb.
bssssssb
bsbbbsbb
bssssssb
bsbbbsbb
bssssssb
.bbbbbb.
.bssssb.
.bssssb.
.bb..bb.
.bb..bb.

[gibdo_1]
..bbbb..
.bssssb.
.bsbbsb.
.bsbbsb.
.bssssb.
.bbbbbb.
bssssssb
bsbbbsbb
bssssssb
bsbbbsbb
bssssssb
.bbbbbb.
.bssssb.
..bssb..
.bb..bb.
..b..b..

# ---------------------------------------------------------------------------
# 21. VIRE (Démon ailé se divisant en Keeses)
# ---------------------------------------------------------------------------
[vire_0]
g......g
gg....gg
ggg..ggg
.gggggg.
.gssssg.
.gsbbsg.
.gssssg.
..gggg..
..gggg..
.gggggg.
.gg..gg.
.gg..gg.
.bb..bb.
.bb..bb.
........
........

[vire_1]
........
..gggg..
.gssssg.
.gsbbsg.
.gssssg.
ggg..ggg
gg....gg
g.gggg.g
..gggg..
.gggggg.
.gg..gg.
.gg..gg.
.bb..bb.
.bb..bb.
........
........

# ---------------------------------------------------------------------------
# 22. BUBBLE (Crâne étincelant bloquant l'épée)
# ---------------------------------------------------------------------------
[bubble_0]
...ss...
..ssss..
.ssbbss.
ssbbbbss
ssbbbbss
.ssbbss.
..ssss..
...ss...
...gg...
..gggg..
.g....g.
g......g
.g....g.
..gggg..
...gg...
........

[bubble_1]
...gg...
..gggg..
.ggbbgg.
ggbbbbgg
ggbbbbgg
.ggbbgg.
..gggg..
...gg...
...ss...
..ssss..
.s....s.
s......s
.s....s.
..ssss..
...ss...
........

# ---------------------------------------------------------------------------
# 23. BLADE TRAP (Piège métallique à lames rétractables)
# ---------------------------------------------------------------------------
[trap]
b..bb..b
bb.bb.bb
.bbbbbb.
..bbbb..
bbbbbbbb
bbbbbbbb
..bbbb..
.bbbbbb.
bb.bb.bb
b..bb..b
........
........
........
........
........
........

# ---------------------------------------------------------------------------
# 24. LANMOLA (Mille-pattes géant segmenté)
# ---------------------------------------------------------------------------
[lanmola_head]
..bbbb..
.bggggb.
bggssggb
bgsbbsgb
bgsbbsgb
bggssggb
.bggggb.
..bbbb..
.b....b.
b......b
........
........
........
........
........
........

[lanmola_body]
..bbbb..
.bggggb.
bggggggb
bggssggb
bggssggb
bggggggb
.bggggb.
..bbbb..
........
........
........
........
........
........
........
........

# ---------------------------------------------------------------------------
# 25. AQUAMENTUS (Dragon cornu à crachat triple)
# ---------------------------------------------------------------------------
[aquamentus_0]
...s....
..ssg...
.ssssgg.
gssssssg
gssbbssg
gssssssg
.gggggg.
bggggggb
bggggggb
bggggggb
.bbbbbb.
.gg..gg.
.gg..gg.
.bb..bb.
.bb..bb.
........

[aquamentus_1]
...s....
..ssg...
.ssssgg.
gssssssg
gssbbssg
gssssssg
.gsbbsg.
bggggggb
bggggggb
bggggggb
.bbbbbb.
..gggg..
.gg..gg.
.bb..bb.
..b..b..
........

# ---------------------------------------------------------------------------
# 26. DODONGO (Dinosaure blindé mangeur de bombes)
# ---------------------------------------------------------------------------
[dodongo_0]
..gggg..
.gggggg.
.gssssg.
.gsbbsg.
.gssssg.
gggggggg
gggggggg
gggggggg
gggggggg
.bbbbbb.
.gg..gg.
.gg..gg.
.gg..gg.
.bb..bb.
.bb..bb.
........

[dodongo_1]
..gggg..
.gggggg.
.gssssg.
.gsbbsg.
.gssssg.
gggggggg
gggggggg
gggggggg
gggggggg
.bbbbbb.
..gggg..
..gggg..
.gg..gg.
.bb..bb.
..b..b..
........

# ---------------------------------------------------------------------------
# 27. MANHANDLA (Plante carnivore géante à 4 mâchoires)
# ---------------------------------------------------------------------------
[manhandla_core]
..bbbb..
.bggggb.
bggggggb
bggssggb
bggssggb
bggggggb
.bggggb.
..bbbb..
........
........
........
........
........
........
........
........

[manhandla_jaw]
.g....g.
.gg..gg.
gssssssg
gssbbssg
gssbbssg
gssssssg
.gggggg.
..bbbb..
........
........
........
........
........
........
........
........

# ---------------------------------------------------------------------------
# 28. GLEEOK (Hydre draconique multi-têtes)
# ---------------------------------------------------------------------------
[gleeok_0]
.g....g.
.gg..gg.
.gggggg.
gssssssg
gssbbssg
gssssssg
.gggggg.
..gggg..
...gg...
...gg...
..gggg..
.gggggg.
........
........
........
........

[gleeok_1]
.g....g.
.gg..gg.
.gggggg.
gssssssg
gssbbssg
gsbbbbsg
.gsbbsg.
..gggg..
...gg...
...gg...
..gggg..
.gggggg.
........
........
........
........

# ---------------------------------------------------------------------------
# 29. DIGDOGGER (Oursin géant sensible à la flûte)
# ---------------------------------------------------------------------------
[digdogger]
.g.gg.g.
gg.gg.gg
.gggggg.
gssssssg
gssbbssg
gssssssg
.gggggg.
gg.gg.gg
.g.gg.g.
..bbbb..
...bb...
........
........
........
........
........

# ---------------------------------------------------------------------------
# 30. GOHMA (Arachnide cuirassé à l'œil vulnérable aux flèches)
# ---------------------------------------------------------------------------
[gohma_closed]
..gggg..
.gggggg.
gggggggg
gggggggg
.bbbbbb.
bssssssb
bssssssb
.bbbbbb.
gggggggg
gggggggg
.gggggg.
..bbbb..
........
........
........
........

[gohma_open]
..gggg..
.gggggg.
gggggggg
gggggggg
.bbbbbb.
bssbbssb
bssbbssb
.bbbbbb.
gggggggg
gggggggg
.gggggg.
..bbbb..
........
........
........
........

# ---------------------------------------------------------------------------
# 31. PATRA (Boss œil volant et yeux orbitaux)
# ---------------------------------------------------------------------------
[patra_center]
..gggg..
.gssssg.
gssssssg
gssbbssg
gssbbssg
gssssssg
.gssssg.
..gggg..
..bbbb..
........
........
........
........
........
........
........

[patra_orb]
........
........
........
..gggg..
.gssssg.
.gsbbsg.
.gssssg.
..gggg..
..bbbb..
........
........
........
........
........
........
........

# ---------------------------------------------------------------------------
# 32. GANON (Seigneur Démon Cochon - Boss Final)
# ---------------------------------------------------------------------------
[ganon_0]
.g.gg.g.
.gggggg.
gssssssg
gssbbssg
gssssssg
.gssssg.
bggggggb
bggggggb
bggggggb
.bbbbbb.
.gg..gg.
.gg..gg.
.gg..gg.
.bb..bb.
.bb..bb.
........

[ganon_1]
.g.gg.g.
.gggggg.
gssssssg
gssbbssg
gssssssg
.gssssg.
bggggggb
bggggggb
bggggggb
.bbbbbb.
..gggg..
..gggg..
.gg..gg.
.bb..bb.
..b..b..
........

# ---------------------------------------------------------------------------
# 33. PROJECTILES ENNEMIS OFFICIELS
# ---------------------------------------------------------------------------
[proj_fireball] pad 0 0
...gg...
..gssg..
.gssssg.
gssbbssg
gssbbssg
.gssssg.
..gssg..
...gg...

[proj_magic] pad 0 0
.bbbbbb.
bssssssb
bssbbssb
bssssssb
.bbbbbb.

[proj_boom_en] pad 0 0
.bbbb...
bb..bb..
b....b..
b....b..
.bb..bb.
..bbbb..
"""

with open("assets/enemies.txt", "a", encoding="utf-8") as f:
    f.write(NEW_SPRITES)
print("Tous les sprites officiels de Zelda 1 NES ont ete ajoutes avec succes dans assets/enemies.txt !")
