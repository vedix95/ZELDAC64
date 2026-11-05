---
name: c64-zelda-verification
description: >-
  Procédure de vérification rigoureuse pour Zelda C64 : compilation ACME,
  contrôle des plafonds mémoire ($1000, $2000, $A000, $C000), génération des banques
  cartouche, tests Dual SID stéréo, planches d'atlas et captures d'écran sous VICE avec résolution dynamique des symboles.
---

# Protocole de Vérification et de Test Automatisé — Zelda C64

Ce guide décrit le protocole standardisé à appliquer après toute modification du code assembleur MOS 6510, des graphismes de sprites/tuiles ou du moteur cartouche.

---

## 1. Synchronisation des Actifs et des Banques de Sprites

Si des modifications touchent aux graphismes dans `assets/enemies.txt`, `assets/link.txt` ou `assets/extra.txt` :

```bash
# Régénération des banques binaires et de build/sprite_ptrs.inc
python3 tools/build_sprite_banks.py
```

### Vérifications :
- S'assurer que le nombre de slots dans `sprites_dung.bin` ne dépasse pas 75 (slots 75..95 réservés aux sprites communs).
- Vérifier la régénération sans erreur de `build/sprite_ptrs.inc`.

---

## 2. Compilation Complète et Intégrité Mémoire

Exécuter la chaîne de compilation complète :

```bash
make clean && make
```

### Invariants et Plafonds Mémoire à Contrôler :
1. **Sprites Link ($1000)** :
   - `src/sprites.asm` doit débuter sous `$0800` et se terminer à `$1000` au plus tard (début de la ROM chargen VIC-II en banque 0).
2. **Plafond du Charset ($2000)** :
   - Le code résident sous `$2000` (`tiles_data.asm`, `input.asm`, `player.asm`) doit finir strictement avant `$2000`.
   - Contrôler le rapport d'assemblage :
     ```bash
     grep -A 5 "CHARSET_ADDR" build/zelda.rep
     ```
   - Si un débordement survient, relocaliser le module ou code lourd dans la haute RAM au-delà de `$4000`.
3. **Plafond Mémoire Résidente ($A000 - OVERLAY_RAM_ADDR)** :
   - Le code et les données résidents du moteur (`main.asm`, `sound.asm`, `hud.asm`, etc.) ne doivent **sous aucun prétexte déborder au-delà de `$9FFF`**.
   - L'espace `$A000..$BFFF` est la zone d'écrasement dynamique par les overlays cartouche (Inventaire Banque 27, Grottes Banque 28, Items Banque 29, Debug Banque 30).
   - Contrôler systématiquement le rapport d'assemblage ACME :
     ```bash
     grep -A 2 "OVERLAY_RAM_ADDR" build/zelda.rep
     ```
   - Maintenir impérativement l'assertion ACME `!if * > OVERLAY_RAM_ADDR { !error ... }` dans `src/main.asm`.
4. **Zone de Streaming Cartouche ($C000)** :
   - L'adresse `$C000` (`MAP_DATA_ADDR`) est réservée au streaming des données de salles Overworld et Donjons.

---

## 3. Automatisation des Tests sous VICE (`x64sc`)

Ne jamais lancer de tests avec des adresses de points d'arrêt codées en dur (ex: `55c2`). Toujours extraire dynamiquement les adresses courantes depuis les fichiers de symboles :

```python
def load_labels(vs_path):
    labels = {}
    with open(vs_path) as f:
        for line in f:
            parts = line.strip().split()
            if len(parts) >= 3 and parts[0] == 'al':
                addr = int(parts[1].split(':')[-1], 16)
                name = parts[2].lstrip('.')
                labels[name] = addr
    return labels

intro_labels = load_labels("build/intro.vs")
zelda_labels = load_labels("build/zelda.vs")

launch_addr = intro_labels['launch_zelda_game']  # Déballage cartouche
main_addr   = zelda_labels['main_loop']          # Boucle de jeu
```

### Exécution du Moniteur VICE en Mode Warp :
```bash
x64sc -default -cartcrt build/zelda.crt -warp -limitcycles 200000000 -moncommands /tmp/script.mon
```

### Séquence d'Avancement Frame par Frame Sécurisée :
Pour éviter tout blocage indéfini ou timeout dans les scripts de moniteur batch, toujours encadrer chaque étape d'avancement :
```text
bk main_addr
g
del
```
Ne jamais émettre `g` sans point d'arrêt actif. Terminer systématiquement les scripts moniteur par la commande `quit`.


---

## 4. Post-Traitement des Captures d'Écran

VICE génère fréquemment les fichiers avec l'extension `.png.pcx` en mode moniteur batch sans libpng natif. Toujours exécuter la conversion automatique :

```bash
for f in screenshots/*.pcx; do
    [ -f "$f" ] && magick "$f" "${f%.pcx}" && rm "$f"
done
```

---

## 5. Exécution de la Suite de Tests Globale

Pour valider l'ensemble des 50 écrans du jeu (Overworld, Donjons 1 à 9, Bosses, Inventaire 4 pages, Menus Debug) :

```bash
python3 tools/take_50_screenshots.py
```

---

## 6. Vérification Audio et Dual SID Stéréo ($D420)

Pour tester la stabilité sonore et la spatialisation Dual SID sans régression :
1. **Émulation Dual SID dans VICE** :
   Toujours passer les arguments d'adresse explicites sous peine de lire un miroir de SID 1 :
   ```bash
   x64sc -default -cartcrt build/zelda.crt -sidextra 1 -sid2address 0xd420 -warp ...
   ```
2. **Suites de Tests Audio Automatisées** :
   - `python3 tools/test_dual_sid_intro.py` : valide l'effet chorus stéréo (+2 detune) et la détection $D420.
   - `python3 tools/test_dual_sid_dungeon.py` : valide la spatialisation stéréo et les SFX symétriques en donjon.
   - `python3 tools/test_dungeon_music_stability.py` : simule 400 frames avec chargements répétés d'overlays cartouche pour vérifier l'absence d'écrasement de notes.
   - `python3 tools/test_dungeon9_audio.py` : valide le streaming du thème étendu du Donjon 9 depuis la Banque 31 (`CART_BANK_AUDIO`).
   - `python3 tools/test_audio_queue_conflict.py` : valide la sérialisation des sons prioritaires (SFX vs Carillon secret).

---

## 7. Validation de l'Atlas Visuel et Planches de Contact

Après toute modification des graphismes de tuiles ou sprites :
```bash
# Générer toutes les planches de contact (Master + 5 dédiées) :
make atlas

# Valider l'intégrité des fichiers PNG, dimensions et arguments CLI :
python3 tools/test_export_assets.py
```

