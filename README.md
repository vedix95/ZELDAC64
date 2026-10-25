# The Legend of Zelda — Port C64

[![GitHub Release](https://img.shields.io/github/v/release/vedix95/ZELDAC64?color=blue&label=Version)](https://github.com/vedix95/ZELDAC64/releases)
[![Build Zelda C64](https://github.com/vedix95/ZELDAC64/actions/workflows/ci.yml/badge.svg)](https://github.com/vedix95/ZELDAC64/actions)
[![Platform: Commodore 64](https://img.shields.io/badge/Platform-Commodore%2064-blue.svg)](https://en.wikipedia.org/wiki/Commodore_64)
[![Assembler: ACME](https://img.shields.io/badge/Assembler-ACME%206510-orange.svg)](https://sourceforge.net/projects/acme-crossass/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Une récréation fidèle et authentique du chef-d'œuvre classique **The Legend of Zelda** (1986) pour l'ordinateur 8-bits **Commodore 64**, entièrement programmée en assembleur 6510 pour l'assembleur [ACME](https://sourceforge.net/projects/acme-crossass/) et testée avec l'émulateur [VICE](https://vice-emu.sourceforge.io/).

> *Ce projet est la création d'un passionné d'informatique rétro réalisée à l'aide de son IA préférée issue de chez Google.*

---

## 💾 Téléchargement Direct & Releases (v0.9.1)

L'image disquette officielle et prête à jouer est disponible au téléchargement sur la page des releases :

- 🎮 **[Télécharger les images disquettes v0.9.1 (`zelda.d64`, `zelda_disk1.d64`, `zelda_disk2.d64`)](https://github.com/vedix95/ZELDAC64/releases/latest)**
- ⚙️ **Distribution tout-en-un 1541 avec Streaming par Chunks** : La disquette `zelda.d64` rassemble l'introduction cinématique, le moteur résident avec musiques in-game 100% authentiques NES cadencées sous interruption raster 50 Hz (sans aucune saccade lors des transitions d'écran), l'Overworld découpé en 4 chunks disque (`OW0` à `OW3`), et les 9 Donjons complets (`DUNG1` à `DUNG9`) chargés à la volée dans une fenêtre mémoire compacte de 4 Ko (`$C000`–`$CFFF`).
- 🏰 **Intégration Complète des 9 Donjons & Tous les Boss NES** : Tous les donjons de Zelda 1 (Niveaux 1 à 9) sont intégrés avec leurs énigmes, volets, portes à clés, salles de la Triforce et l'ensemble de leurs Boss (Aquamentus, Dodongos, Manhandla, Gleeok, Digdogger, Gohma et l'antre de Ganon au Donjon 9).
- 🚀 **Prêt à l'emploi** : La release propose l'image disquette `.d64` standard tout-en-un ainsi que le jeu en double-disquette (`zelda_disk1.d64` pour l'Overworld et `zelda_disk2.d64` pour les Donjons).
- 🛠️ **Nouveautés v0.9.1** : Correction du pipeline d'intégration continue GitHub Actions (conflit de symboles résolu dans `tools/tilegen.py`), stabilisation du menu Debug (élimination des déplacements automatiques et duplication du curseur), affichage corrigé du menu Inventaire et validation automatique des 50 scénarios de jeu par capture d'écran.

Pour lancer directement la disquette dans [VICE](https://vice-emu.sourceforge.io/) :
```sh
x64sc -autostart zelda.d64
```

---

## Captures d'écran

### En jeu (Overworld, Donjons, Monstres & Boss)

| Overworld & Radar GPS | Entrée du Donjon 1 (L'Aigle) |
| :---: | :---: |
| ![Overworld](docs/images/shot_overworld.png) | ![Entrée Donjon 1](docs/images/shot_dungeon1.png) |

| Combat contre le Boss Aquamentus | Salle des Monstres Stalfos (Donjon 1) |
| :---: | :---: |
| ![Boss Aquamentus](docs/images/shot_boss_aquamentus.png) | ![Monstres Stalfos](docs/images/shot_dungeon_enemies.png) |

| Salle de départ & Grotte de l'Épée | Cimetière avec Ghinis | Désert avec Peahats |
| :---: | :---: | :---: |
| ![Salle de départ](docs/images/shot_start.png) | ![Cimetière avec ennemis](docs/images/shot_graveyard.png) | ![Désert](docs/images/shot_desert.png) |

### Cinématique d'Introduction Authentique (Chute d'eau, Parchemin & Bestiaire)

| Écran Titre & Cascade Animée | Déroulement de la Légende d'Hyrule | Présentation de tous les Trésors | Défilé des Monstres (Ghini) |
| :---: | :---: | :---: | :---: |
| ![Cascade Animée](docs/images/shot_intro.png) | ![Parchemin Légende](docs/images/shot_intro_story.png) | ![Trésors d'Hyrule](docs/images/shot_intro_treasures.png) | ![Défilé des Monstres](docs/images/shot_intro_monsters.png) |

| Carte complète de l'Overworld (16×8 écrans — 128 salles) |
| :---: |
| ![Carte Overworld](docs/images/world_preview.png) |

---

## 🎵 Bande-Sonore SID & Extraits Audio MP3

Les musiques du jeu ont été fidèlement retranscrites et synthétisées directement sur la puce sonore analogique **MOS SID 6581/8580** du Commodore 64 à partir des partitions originales NES. Enregistrement direct sous émulation cycle-accurate reSID (48 kHz, 192 kbps) :

| Piste & Scène | Description | Écoute directe | Fichier MP3 |
| :--- | :--- | :---: | :---: |
| 🛡️ **Thème Overworld (Aventure)** | La boucle légendaire d'exploration d'Hyrule, avec sa ligne de basse profonde Voice 3 calibrée à l'octave exacte sans suraigus. | <audio controls src="docs/audio/zelda_overworld.mp3"></audio> | [zelda_overworld.mp3](docs/audio/zelda_overworld.mp3) |
| 🗝️ **Thème des Donjons (Underworld)** | L'atmosphère mystérieuse des Labyrinthes 1 à 8, avec ses arpèges G-mineur entrelacés en onde Pulse 50% sur 2 voix et basse sourde. | <audio controls src="docs/audio/zelda_dungeon.mp3"></audio> | [zelda_dungeon.mp3](docs/audio/zelda_dungeon.mp3) |
| 📜 **Thème d'Introduction & Titre** | La partition épique de l'écran-titre avec cascade et du défilement de la Légende d'Hyrule. | <audio controls src="docs/audio/zelda_intro.mp3"></audio> | [zelda_intro.mp3](docs/audio/zelda_intro.mp3) |

---

## Points forts & Fonctionnalités (Nouveautés v0.9.0)

- **Intégration Complète des 9 Donjons & de tous les Boss NES (v0.9.0)** :
  - **9 Donjons 100% Fonctionnels (`DUNG1` à `DUNG9`)** : Architecture complète des salles étanches, portes verrouillées à clés, portes à volets automatiques, énigmes de blocs mobiles, pièges, salles de la Triforce et trésors.
  - **Tous les Boss de Zelda 1 Implémentés** : Combats contre Aquamentus (N1 & N7), Dodongos (N2 & N8), Manhandla à 4 têtes (N3), Gleeok le dragon bicéphale (N4), Digdogger (N5), Gohma à l'œil unique (N6) et l'antre suprême de Ganon (N9).
  - **Distribution Disquette Double Face / 2 Disquettes** : Création automatique des images disquettes séparées `zelda_disk1.d64` (Overworld) et `zelda_disk2.d64` (Donjons) pour une compatibilité matérielle optimale 1541, en plus de l'image disquette tout-en-un `zelda.d64`.
- **Refonte Complète du Menu d'Inventaire (4 Onglets Haute Résolution)** :
  - **Onglet 1 (Objets B)** : Grille de sélection des 8 armes secondaires avec cadre bleu, boîte d'équipement active, descriptifs détaillés et compteurs de rubis, clés et bombes sans aucun chevauchement.
  - **Onglet 2 (Triforce)** : Grand triangle doré de la Triforce avec mise en surbrillance des fragments récupérés et compteurs de donjons complétés.
  - **Onglet 3 (Arsenal & Reliques Passives)** : Présentation claire des 8 reliques héroïques permanentes (Épée, Bouclier avec véritable sprite d'écu royal, Anneau, Bracelet, Radeau, Échelle, Clé magique et Livre de sorts).
  - **Onglet 4 (Carte Dynamique)** : Affichage automatique de la carte d'Hyrule (16×8) en Overworld ou du plan cartographié du donjon actif avec position de Link, boussole, salle du boss et nom du donjon.
  - **Éradication de la corruption CIA1** : Tracé haute résolution direct sans écrasement des registres de la puce d'E/S CIA1 et bordures nettes en graphismes 164.
- **Menu Debug Multifonctions 3 Pages Entièrement Fiabilisé** :
  - **Page 0 (Téléportation)** : Accès instantané aux 9 Donjons et à n'importe quelle salle de l'Overworld (A-1 à P-8 / 0 à 127). La sortie du donjon ramène Link exactement à l'entrée Overworld officielle du donjon.
  - **Page 1 (Arsenal & Triche)** : Full gear, soin instantané, ajustement des cœurs max, modification des épées, boucliers, anneaux, clés (+5), bombes (+4), rubis (+50) et pièces de Triforce (+1).
  - **Page 2 (Diagnostic & Hardware)** : Coordonnées subpixel de Link, orientation, ID de salle, types d'ennemis actifs, état de la mémoire et bascule Dual SID en temps réel.
  - **Correction du Défilement Intempestif** : Suppression de l'inversion de polarité joystick dans le menu debug (`beq` vs `bne`), temporisation anti-rebond unifiée et affichage propre sans duplication de lignes.
- **Correctifs Cave Souterraine, SFX Épée, Escalier Donjon & Rugissement du Boss (v0.8.9)** :
  - **Rendu complet de la Cave Souterraine (`STATE_CELLAR`, salle `0x22`)** : Correction de la boucle de remplissage des 200 tuiles de briques (`cpx #200` au lieu de `bpl` signé sur `199`), correction de la colonne d'échelle avec motif 2D authentique à barreaux (`cellar_ladder_char_l` / `r`) et piédestal central en briques.
  - **Correction du bruitage d'épée et des SFX (`sound.asm`)** : Séparation des instructions `jmp play_sfx_v3` (qui étaient interprétées comme commentaires après `;` par ACME et tombaient dans `sound_item_fanfare`), restituant le vrai bruitage de coup d'épée (`SFX_SWORD`) et tous les effets sonores.
  - **Escalier secret au centre du diamant (`0x22`) & Tuile d'escalier descendant** : En poussant le bloc gauche du losange (`offset 88` -> `68`), la case `88` devient du sol (`TILE_DUNG_FLOOR`) pour laisser Link entrer au cœur du diamant où se trouve l'unique escalier (`offset 90`), doté d'un nouveau graphisme 3D de marches descendantes (`TILE_DUNG_STAIRS`).
  - **Respiration / Rugissement du Boss (`SFX_BOSS_ROAR`)** : Ajout de l'effet sonore périodique de respiration/rugissement grave d'Aquamentus (`sound_boss_roar`) pendant le combat.
- **Correctifs Gameplay, Audio & Donjon 1 (v0.8.8)** :
  - **Collisions d'eau Overworld corrigées** : L'eau de l'Overworld (`TILE_WATER`) bloque désormais strictement Link tant qu'il ne possède pas l'Échelle (`Stepladder`).
  - **Sprite & Célébration de la Triforce (`0x36`)** : Ajout du véritable sprite triangulaire doré scintillant de la Triforce (`sprite_link_item_triforce`) sur le piédestal et brandi au-dessus des mains de Link pendant la célébration.
  - **Fanfares Authentiques NES 3 Voix (`SongScriptItemTaken0` & `SongScriptEndLevel0`)** : Extraction directe depuis `zelda.nes` de la fanfare de récupération d'objet (avec reprise automatique de la musique de fond) et de la fanfare complète de victoire de la Triforce (41 pas sur 3 voix SID).
  - **Récompense du Boss Aquamentus (`0x35`)** : Correction de la mort d'Aquamentus à l'épée, ouverture automatique de la porte à volet Est et apparition garantie du **Conteneur de Cœur (`DROP_HEART_CONTAINER`)**.
  - **Salle Souterraine de l'Arc (`0x22` / `STATE_CELLAR`)** : Rendu fidèle de la chambre souterraine en briques blanches/grises sur fond noir de la NES avec échelle, piliers, piédestal central et récupération de l'Arc.
- **Optimisation Mémoire C64 & Streaming Disquette par Chunks (`OW0`–`OW3` & `DUNG1`–`DUNG9`)** :
  - **Découpage de l'Overworld en 4 Chunks (`OW0` à `OW3`)** : L'Overworld (128 salles) est découpé en 4 bandes horizontales de 32 salles (~2,8 Ko chacune) chargées automatiquement à la demande depuis la disquette 1541.
  - **Déduplication des tables d'ennemis (`room_enemy_idx`)** : Compression de 55% des fichiers de donjons (~2,1 Ko au lieu de 5 Ko) et des chunks Overworld grâce à l'indexation des formations uniques de monstres.
  - **Gain massif de +8 Ko de RAM résidente (`$A000`–`$BFFF`)** : La fenêtre d'overlay dynamique est réduite de 12 Ko (`$A000`–`$CFFF`) à 4 Ko (`$C000`–`$CFFF`), libérant près de 8 Ko de mémoire vive pour le moteur et les futures fonctionnalités.
- **Musique Continue 50 Hz sous Interruption Raster (`irq_bottom`)** :
  - Le séquenceur musical SID (`music_update`) est désormais exécuté directement dans l'interruption raster matériel à 50 Hz. La musique continue de jouer avec une fluidité absolue sans aucun blocage ni saccade pendant tous les défilements (push-scroll) d'écran à écran, en Overworld comme en Donjon.
- **Donjon 1 (L'Aigle) — Secrets de Blocs Poussables, Ermite & Cave Vue de Côté (2D)** :
  - *Note : Seul le Donjon 1 est implémenté partiellement pour le moment.*
  - **Mécanique authentique de poussée de blocs** : Après avoir éliminé tous les ennemis d'une salle à énigme, maintenir une direction contre le bloc central pendant ~16 frames déclenche son déplacement avec le jingle secret (`SFX_SECRET`).
  - **Salle de l'Ermite (`0x41`) & Énigme de la Salle `0x42`** : Vaincre les Gels en `0x42` puis pousser le bloc central ouvre le volet Ouest vers la salle `0x41` où l'ermite entouré de torches animées révèle l'indice officiel : *"LA PENINSULE TOUT A L'EST / EST LE SECRET."*.
  - **Cave Souterraine Vue de Côté (`STATE_CELLAR`) & Récupération de l'Arc (`0x22`)** : Vaincre les Keese en `0x22` puis pousser le bloc révèle l'escalier secret menant au sous-sol 2D classique en briques. Link descend l'échelle, marche jusqu'au piédestal central, brandit l'**Arc (`ITEM_BOW`)** au-dessus de sa tête avec la fanfare d'objet, puis remonte l'échelle vers la salle `0x22`.
- **Boss Aquamentus Géant Haute Fidélité (`48×42` pixels)** :
  - Extraction directe des tuiles CHR NES `bos1` depuis `zelda.nes` combinée à l'expansion matérielle 2× en X et en Y du VIC-II (`VIC_SPRITE_EXP_X` / `VIC_SPRITE_EXP_Y`), donnant à Aquamentus sa stature imposante face à Link avec boîtes de collision et point de crachat des triples boules de feu ajustés.
- **Moteur Audio SID & Support Dual SID ($D420 stéréo)** :
  - Touche `3` en jeu pour basculer instantanément en mode stéréo Dual SID.
- **HUD sur fond noir, Mini-carte 1:1 & Éditeur visuel intégré** (`tools/editor.py`).

---

## Prérequis

Sur les distributions basées sur Arch Linux :
```sh
sudo pacman -S acme vice python python-pillow
```

Sur Debian / Ubuntu :
```sh
sudo apt-get update
sudo apt-get install -y acme vice python3 python3-pil
```

Vérifier la configuration de votre environnement de développement :
```sh
make check
```

---

## Compilation et Lancement

| Commande | Action |
| :--- | :--- |
| `make` | Compile le projet complet et génère l'image disquette `build/zelda.d64` |
| `make run` | Lance la disquette complète dans VICE (Intro cinéma + enchaînement sur le jeu) |
| `make run-game` | Lance directement le moteur de jeu résident sans passer par l'intro |
| `make debug` | Lance dans VICE avec chargement automatique des labels symboliques (`build/zelda.vs`) |
| `make editor` | Lance l'éditeur de niveau visuel interactif |
| `make preview` | Génère les aperçus graphiques PNG des sprites et du monde dans `build/` |
| `make clean` | Nettoie les fichiers de build temporaires (`build/`) |
| `make distclean` | Nettoie les fichiers de build et les fichiers ASM générés |

---

## Contrôles

### En jeu (Joystick Port 2 ou Clavier)

Le jeu se joue idéalement avec une manette ou un joystick branché sur le **Port 2**. Dans VICE, configurez le joystick dans `Settings > Input devices > Joystick > Joystick #2` (clavier ou manette USB).

| Touche / Action | Rôle |
| :--- | :--- |
| **Joystick Direction** / Pavé numérique | Déplacements de Link (Haut, Bas, Gauche, Droite) |
| **Bouton Feu** / `X` | Coup d'épée (et tir d'épée si PV au maximum) |
| `A` | Utiliser l'arme secondaire active (Boomerang, Bombe, Arc, Bougie) |
| `B` | Ouvrir / Fermer le menu d'inventaire |
| `D` | Ouvrir / Fermer le moniteur de debug (mémoire, registres VIC-II / SID) |
| `3` | Basculer mode Dual SID ($D420 stéréo) / Mono SID ($D400) |
| `Espace` / `Entrée` | Valider / Passer l'écran d'introduction |

---

## Architecture de la Disquette C64 (`zelda.d64`)

La disquette 1541 est formatée sous le nom `zelda,01` et contient les fichiers suivants :

1. `INTRO` (`PRG`) : Programme d'introduction autonome exécuté au démarrage (`$0801`–`$3FFF`), gérant la cascade, le parchemin en défilement vertical fin et la musique SID complète.
2. `ZELDA` (`PRG`) : Moteur de jeu principal résident en mémoire (`$0801`–`$A091`, avec plus de 7,5 Ko libres jusqu'à `$BDFF`), incluant le pilote audio SID 50 Hz sous IRQ et les 83 sprites d'ennemis originaux en `$2800`–`$3FFF`.
3. `OW0` à `OW3` (`DAT`) : Les 4 chunks régionaux de la carte Overworld (32 salles par chunk + formations d'ennemis dédupliquées, ~2,8 Ko chacun), chargés dynamiquement à la demande en `$C000`–`$CFFF`.
4. `DUNG1` à `DUNG9` (`DAT`) : Fichiers autonomes compactés (~1,8 à 2,3 Ko) des 9 donjons d'Hyrule, chargés dynamiquement à `$C000`–`$CFFF`. *(Seul le Donjon 1 est implémenté partiellement pour le moment).*

### Carte mémoire du C64

```
+------------------+ $FFFF
| Vecteurs KERNAL  |
+------------------+ $E000
| ROM KERNAL / I/O | $D000 - $DFFF : Registres VIC-II, SID 1 ($D400), SID 2 ($D420), CIA 1/2, Color RAM
+------------------+ $D000
| Fenêtre Overlay  | $C000 - $CFFF : Chunk Overworld (OW0..OW3) ou Donjon (DUNG1..DUNG9) actif (4 Ko)
+------------------+ $C000
| Tampons Salles   | $BE00 - $BF8F : Tampons RAM décompressés (room_buf & target_room_buf)
| RAM Résidente    | $0801 - $BDFF : Code moteur, IA, cave 2D, HUD, audio SID (~7,5 Ko libres en $A091-$BDFF)
+------------------+ $2000 - $27FF : Jeu de caractères multicolore des tuiles (Charset)
| Mémoire écran    | $0400 - $07E7 : Matrice d'écran vidéo VIC-II ($07F8-$07FF : Pointers sprites)
+------------------+ $0400
| Zone système     | $0200 - $03FF : Vecteurs KERNAL/BASIC, état des salles donjon ($033C)
| Pile processeur  | $0100 - $01FF : Pile matérielle 6502
| Page Zéro ($00)  | $0002 - $00FF : Pointeurs rapides, état du joueur, registres virtuels
+------------------+ $0000
```

---

## Arborescence du Projet

```
.
├── assets/                     # Fichiers sources d'assets (ASCII art, textes, MIDI)
│   ├── link.txt                # Sprites multicolores de Link (4 directions + attaque)
│   ├── enemies.txt             # Sprites multicolores des ennemis et boss
│   ├── extra.txt               # Sprites du Vieil Homme, objets et effets
│   ├── tiles.txt               # Définition des tuiles 16x16 et palettes multicolores
│   ├── world.txt               # Carte Overworld complète (16x8 écrans, 128 salles)
│   ├── underworld.txt          # Carte des donjons Underworld (Level 1)
│   └── *.mid                   # Fichiers MIDI sources transcrits pour le SID
├── docs/                       # Documentation et médias
│   ├── audio/                  # Enregistrements audio SID authentiques (MP3 192k)
│   └── images/                 # Captures d'écran et aperçus pour GitHub
├── LegendOfZeldaNESRecomp/     # Référence complète du décompilateur Zelda NES
├── scripts/                    # Scripts utilitaires shell (vérification d'environnement)
│   └── check-env.sh            # Vérification des dépendances logicielles
├── src/                        # Code source assembleur 6510 (ACME)
│   ├── main.asm                # Point d'entrée, stub BASIC, boucle principale et IRQ
│   ├── sound.asm               # Moteur audio SID (Mono et Dual SID $D420, Overworld & Donjon, SFX)
│   ├── music_data.inc          # [GÉNÉRÉ] Partitions et notes Overworld et Donjon
│   ├── c64.inc                 # Définitions matérielles (VIC-II, SID, CIA, Page Zéro)
│   ├── player.asm              # Déplacements, animations et boîte de collision de Link
│   ├── enemies.asm             # IA des ennemis, tables de comportement, attaques et butin
│   ├── items.asm               # Gestion des armes secondaires, projectiles et ramassage
│   ├── inventory.asm           # Logique du menu d'inventaire
│   ├── inventory_draw.asm      # Rendu graphique en 4 pages du menu d'inventaire
│   ├── hud.asm                 # Rendu dynamique du HUD (cœurs, mini-carte, compteurs, niveau)
│   ├── cave.asm                # Système des grottes secrètes et entrées des 9 donjons
│   ├── tilemap.asm             # Moteur de rendu des tuiles, palettes et transitions
│   ├── sprites.asm             # [GÉNÉRÉ] Données binaires des sprites de Link
│   ├── sprites_enemies.asm     # [GÉNÉRÉ] Données binaires des sprites d'ennemis
│   ├── sprites_extra.asm       # [GÉNÉRÉ] Données binaires des sprites spéciaux et PNJ
│   ├── charset.asm             # [GÉNÉRÉ] Jeu de caractères multicolores VIC-II
│   ├── tiles_data.asm          # [GÉNÉRÉ] Tables de correspondance et attributs des tuiles
│   ├── map_overworld.asm       # [GÉNÉRÉ] Données compilables de la carte Overworld
│   ├── dungeon.asm             # Moteur de règles des donjons (portes, clés, volets, secrets)
│   ├── dung1.asm ... dung9.asm # [GÉNÉRÉ] Fichiers assembleur autonomes des 9 Donjons d'Hyrule
│   ├── disk.asm                # Routines KERNAL IEC de streaming disquette 1541
│   ├── intro.asm               # Logique de la cinématique d'introduction
│   ├── intro_main.asm          # Point d'entrée de l'exécutable autonome d'intro
│   ├── intro_music_data.asm    # Partitions et commandes pour le pilote sonore de l'intro
│   ├── input.asm               # Lecture sécurisée du joystick port 2 et du clavier
│   ├── transition.asm          # Gestion des transitions d'écran à écran
│   └── debug.asm               # Moniteur de debug mémoire et registres matériels
├── tools/                      # Outils Python de conversion, extraction et édition
│   ├── editor.py               # Éditeur visuel interactif web de niveaux et d'ennemis
│   ├── generate_game_audio.py  # Extraction et encodage compact des musiques pour SID
│   ├── convert_nes_underworld.py # Extraction des 9 donjons depuis la ROM NES
│   ├── sprgen.py               # Générateur de sprites C64 depuis l'ASCII art
│   ├── tilegen.py              # Compilateur de tuiles et cartes du monde
│   ├── midi_to_sid.py          # Convertisseur MIDI vers code assembleur SID
│   └── generate_*.py           # Générateurs spécialisés de données et tables
├── Makefile                    # Système de compilation et d'automatisation
├── LICENSE                     # Licence MIT et clause d'avertissement légal
└── README.md                   # Ce fichier
```

---

## Mentions Légales & Droits d'Auteur

*The Legend of Zelda*, ainsi que les personnages, logos, musiques et graphismes associés sont des marques déposées et propriétés exclusives de **Nintendo Co., Ltd.**

Ce projet est un travail d'hommage bénévole, non-commercial et éducatif : la création d'un passionné d'informatique rétro réalisée à l'aide de son IA préférée issue de chez Google afin d'explorer et de célébrer les capacités matérielles du Commodore 64. Il n'est en aucune manière affilié à, autorisé ou approuvé par Nintendo.
