# Spécification Technique d'Alignement de Carte : The Legend of Zelda (NES vers Commodore 64)
**Objectif :** Corriger la carte 2 (version fangame / démake *Commodore 64*) pour la rendre strictement identique, tuile par tuile (grille $16 \times 11$ tuiles par écran, soit $256 \times 176$ pixels), à la carte originale NES (carte 1), tout en garantissant l'intégrité fonctionnelle des déclencheurs vers les salles souterraines (carte 3) et en respectant les spécificités du moteur graphique C64 (VIC-II / charset de tuiles).

---

## 0. Règle Fondamentale pour l'Agent IA : Gestion des Sprites et Tuiles Manquants (C64)

> **Directive d'injection d'actifs :**  
> Si un élément présent sur la carte NES (Carte 1) est absent, dénaturé ou remplacé par une texture générique sur la carte C64 (Carte 2), **c'est que le sprite, le bloc de caractères (*custom charset*) ou la métatuile n'a pas encore été converti ou créé pour le portage Commodore 64**.  
> L'agent IA ne doit pas masquer ou contourner ce manque par des textures de substitution (buissons génériques, herbe monochrome ou blocs d'eau) : il doit **générer, adapter au format C64 (palette 16 couleurs VIC-II, blocs multicolores $8 \times 8$ ou métatuiles $16 \times 16$) et injecter le sprite ou la tuile manquante** en se référant scrupuleusement à son **nom technique officiel en anglais (nom de l'actif/sprite dans le code source de Zelda 1)** listé ci-dessous.

---

## 1. Dictionnaire Technique des Sprites et Noms d'Origine (Game Engine / ROM)

| Nom FR | Nom Anglais Officiel (Sprite / Tile ID) | Nom interne / ROM Disassembly | Type d'élément (C64 / VIC-II) | Comportement / Hitbox / Déclencheur |
| :--- | :--- | :--- | :--- | :--- |
| **Statue Armos** | `Armos` / `Armos Statue` | `ACTOR_ARMOS` / `TILE_ARMOS` | Sprite matériel / Entité mobile | Solide au repos (**P2**). S'anime au contact de Link ; poussable avec le `Power Bracelet` pour révéler un escalier (`STAIRS`). |
| **Arbre mort / Calciné** | `Dead Tree` / `Dried Tree` | `TILE_DEAD_TREE` / `TILE_STUMP` | Méta-tuile décor ($16 \times 16$ px) | Solide. S'enflamme et disparaît au contact de la flamme de la `Blue Candle` ou `Red Candle` pour générer un escalier. |
| **Buisson / Arbre vert** | `Green Tree` / `Bush` | `TILE_GREEN_TREE` / `TILE_BUSH` | Méta-tuile décor ($16 \times 16$ px) | Obstacle solide délimitant les clairières et labyrinthes (`Lost Woods`). Certains réagissent à la flamme de la `Candle`. |
| **Pierre tombale** | `Tombstone` / `Grave` | `TILE_GRAVESTONE` / `TILE_GRAVE` | Méta-tuile poussable / Solide | Poussable vers le haut sur sol dallé. Déclenche l'apparition d'un fantôme `Ghini` (`ACTOR_GHINI`) ou révèle un escalier secret (**B3**). |
| **Débarcadère / Ponton** | `Raft Dock` / `Dock` | `TILE_DOCK` | Méta-tuile de rive structurelle | Point d'amarrage en planches sur berge (**K1**, **P3**). Déclenche le script de navigation si le `Raft` est en inventaire. |
| **Pont de bois** | `Wooden Bridge` | `TILE_BRIDGE_H` / `TILE_BRIDGE_V` | Méta-tuile de franchissement | Plateforme piétonne franchissant l'eau sans collision bloquante (**G6**, **I4**, **K2**). |
| **Pilier / Stèle sacrée** | `Stone Pillar` / `Monument` | `TILE_PILLAR` / `TILE_MONUMENT` | Méta-tuile clé / Décor minéral | Colonnes claires dressées sur plateforme minérale (**C3**, **D4**, **P1**, **P3**). Réagit à la mélodie de la `Recorder` (`Flute`). |
| **Entrée donjon Niveau 1** | `Hollow Tree Entrance` | `TILE_TREE_ENTRANCE` | Méta-tuile d'entrée donjon | Tronc d'arbre évidé sur l'îlot central (**G5**) menant au **Level 1: The Eagle**. |
| **Entrée donjon Niveau 5** | `Skull Dungeon Entrance` | `TILE_SKULL_ENTRANCE` | Méta-tuile d'entrée donjon | Façade architecturale sculptée dans la roche (**L1**) menant au **Level 5: The Lizard**. |
| **Rocher Spectacle** | `Spectacle Rock` | `TILE_SPECTACLE_ROCK` | Méta-tuile de relief rocheux | Deux monticules rocheux jumeaux arrondis (**P1**). Paroi destructible à la `Bomb` menant au **Level 9: Death Mountain**. |
| **Fontaine des Fées** | `Fairy Pond` / `Fairy Spring` | `ROOM_FAIRY_SPRING` | Méta-tuile hydrologique | Bassin d'eau maçonné clos (**J4**, **K6**) générant une grande Fée régénératrice (`ACTOR_FAIRY`). |
| **Entrée de grotte standard** | `Cave Entrance` | `TILE_CAVE_OPENING` | Méta-tuile de téléportation | Arche sombre dans la roche marron ou grise menant à une salle souterraine. |
| **Mur fissurable** | `Bombable Wall` | `WALL_BOMB_TARGET` | Propriété de collision murale | Paroi rocheuse normale cédant sous l'explosion d'une `Bomb` pour laisser place à `TILE_CAVE_OPENING`. |
| **Sol dallé du cimetière** | `Graveyard Pavement` | `TILE_GRAVEYARD_DIRT` | Texture de sol (Floor) | Dalles en pierre texturée grise (remplace le fond noir uni sans relief du C64). |
| **Terre ocre / Sable** | `Brown Dirt` / `Sand Ground` | `TILE_DIRT_PATH` / `TILE_SAND` | Texture de sol (Floor) | Sol ocre intermédiaire (colonnes A à K, lignes 2 à 5) séparant les montagnes du sud herbeux. |

---

## 2. Corrections Topographiques et Hydrologiques Prioritaires

### A. Suppression des cours d'eau parasites
* **H2, I2, J2 :** Supprimer intégralement le cours d'eau horizontal bleu reliant K2 à H2 (anomalie de tracé sur la version C64).  
  * *Restauration :* Rétablir la falaise `Brown Mountain` au nord et le sentier pédestre continu `Brown Dirt` au sud.
* **K2 :** Rétablir le cours vertical rectiligne de la cascade (`Waterfall`). L'eau ne doit en aucun cas bifurquer vers l'ouest.

### B. Restauration des lacs majeurs et îles de donjons
* **G5 (et bordures E5, F5, H5) — Lac du Niveau 1 :**
  * Supprimer la plaine herbeuse continue issue du tracé C64.
  * Reconstruire le vaste plan d'eau bleu entourant l'île centrale (**G5**).
  * Réinsérer le sprite/métatuile manquant `Hollow Tree Entrance` (**Level 1: The Eagle**), les 3 éléments de décor sur l'îlot, et le `Wooden Bridge` sud vers **G6**.
* **H4 — Lac du Niveau 4 :**
  * Reconstruire le plan d'eau carré ceinturant l'île rocheuse du donjon (**Level 4: The Snake**).
  * Rétablir le `Wooden Bridge` reliant l'île vers l'écran **I4** à l'est.
* **J4 & K6 — Bassins des Fées (`Fairy Pond`) :**
  * **J4 :** Restaurer le bassin d'eau rectangulaire fermé au centre de la plaine.
  * **K6 :** Rétablir le grand lac carré bleu occupant la majeure partie de l'écran.

### C. Réajustement de la ligne côtière et de l'océan (`Ocean Shore`)
* **L8 & M8 :**
  * **L8 :** Intégrer la morsure de l'océan (`Coast Water`) dans le coin inférieur droit de l'écran.
  * **M8 :** Rétablir l'océan sur **toute la moitié inférieure** de l'écran (actuellement comblée par erreur en terre verte sur la version C64).
* **N8, O8, P8 :** Rehausser le trait de côte ; l'eau doit couvrir le tiers inférieur de chaque écran.
* **P3, P4, P5, P6 (Façade Est) :** Réélargir l'océan : il doit occuper la moitié droite entière de chaque écran.

### D. Débarcadères de Radeau (`Raft Dock`)
* **K1 :** Positionner le sprite `Raft Dock` sur la rive sud du plan d'eau supérieur.
* **P3 :** Restaurer le sprite `Raft Dock` sur la rive continentale droite face à l'îlot secret.

---

## 3. Rectification des Biomes, Falaises et Tuiles Spéciales

* **Cimetière (A3, A4, A5, B3, B4, B5) :**
  * Supprimer le fond noir opaque (*void* non texturé typique d'un charset C64 incomplet).
  * Appliquer la texture de sol `Graveyard Pavement` (dallage minéral gris).
  * Réaligner les rangées de `Tombstone` selon les coordonnées strictes de la carte NES.
* **Anomalie visuelle A6 :**
  * Supprimer le bloc noir opaque recouvrant le quart supérieur gauche.
  * Reconstituer la falaise de pierre grise et le passage praticable vers le sud.
* **Plateformes à stèles sacrées (`Stone Pillar`) :**
  * **C3 :** Remplacer les buissons par une plateforme minérale grise entourée de **8 `Stone Pillar` blancs**.
  * **D4 :** Reconstruire le rectangle surélevé de dalles grises supportant **8 `Stone Pillar` blancs** (emplacement du **Level 7: The Demon**).
* **Entrées de donjons majeurs :**
  * **P1 :** Reconstituer le `Spectacle Rock` et positionner les **3 `Stone Pillar` blancs** de garde devant l'entrée du **Level 9**.
  * **L1 :** Remplacer la simple caverne ronde par le sprite architectural `Skull Dungeon Entrance` (**Level 5**).
  * **P3 :** Appliquer le tileset de falaise blanc/gris (`Graveyard Rock`) sur l'îlot secret.
* **Harmonisation des sols (Lignes 2 à 5, Colonnes A à K) :**
  * Remplacer la texture d'herbe verte uniforme par le sol en terre battue ocre `Brown Dirt`.

---

## 4. Positionnement Micro-Topologique : Végétation et Sprites

### A. Remplacements critiques de sprites manquants
* **P2 :** Remplacer les buissons par **8 sprites d'entités `Armos`** (2 rangées de 4). Créer/injecter le sprite Armos aux contraintes C64 (multicolore VIC-II) s'il n'est pas encore compilé. Ne pas utiliser de méta-tuile d'arbre.
* **E7 & F7 vs E8 & F8 :**
  * **E7 et F7 :** Sol ocre impératif + **6 `Dead Tree` marrons** par écran (2 colonnes verticales de 3).
  * **E8 et F8 :** Sol herbeux vert + **6 `Green Tree` feuillus** par écran (2 colonnes de 3).
* **B7, C7, D7 :** Convertir le sol en `Brown Dirt` et remplacer les buissons par des `Dead Tree` (**6 en B7**, **5 en C7**, **3 en D7**).

### B. Grilles géométriques régulières
* **E3 & F3 :** Aligner sur chaque écran une matrice exacte $3 \times 3$ de **9 `Dead Tree` marrons** sur sol ocre.
* **N4 (*Lost Woods*) :** Aligner une matrice $4 \times 4$ de **16 `Green Tree` pleins**. Calibrer les blocs de tuiles C64 pour que chaque couloir de passage mesure précisément 1 tuile ($16 \times 16$ px / 2 blocs de caractères) sans débordement de hitbox ni collision bloquante.
* **J6 :** Aligner le bosquet de **12 `Green Tree`** sur la grille exacte de la carte 1.
* **O6 :** Placer **1 `Green Tree` (buisson isolé)** au centre exact de la clairière circulaire.

### C. Arbres morts isolés des corniches rocheuses du Nord (`Dead Tree`)
* **A2 :** 11 `Dead Tree` (3 nord-ouest, 3 centre, 5 sud-est).
* **B2 :** 7 `Dead Tree` (3 ouest, 4 est).
* **C2 :** 8 `Dead Tree` en 2 colonnes verticales.
* **D2 :** 6 `Dead Tree` (3 nord, 3 sud).
* **F2 :** 6 `Dead Tree` le long du chemin.
* **J1 :** 6 `Dead Tree` disposés en chevron (formation en V inversé).
* **J2 :** 4 `Dead Tree` au sol (actuellement recouverts par le faux canal sur le démake C64).
* **L2 :** 8 `Dead Tree` encadrant l'ouverture de la grotte.
* **M2 :** 10 `Dead Tree` disposés en 2 rangées horizontales régulières.
* **N2 :** 8 `Dead Tree` (le 5ᵉ cache l'accès au **Level 8: The Lion**).
* **M3 :** 4 `Dead Tree` au pied de la falaise.
* **A8 :** 4 `Dead Tree` marrons en diagonale dans le renfoncement sud-ouest.
* **K8 :** 2 `Dead Tree` au pied de la falaise sud.

### D. Buissons secrets isolés (`Green Tree`)
* **I3 :** 1 `Green Tree` isolé en bas à droite (cache un escalier secret).
* **D5 :** 2 `Dead Tree` espacés sur sol ocre.
* **C5 :** Supprimer tous les buissons entourant le point d'eau (sol 100 % minéral rocheux).
* **H6 :** 5 `Green Tree` continus au centre + 1 isolé au nord + 1 isolé au sud.
* **I6 :** 2 `Green Tree` isolés dans la plaine sud.
* **H7 :** 5 `Green Tree` formant un arc de cercle.
* **I7 & J7 :** 4 `Green Tree` isolés par écran aux intersections.
* **H8 (Écran de départ) :** 3 buissons en escalier dans le coin sud-ouest ; 4 buissons groupés dans le coin sud-est.

---

## 5. Matrice d'Intégrité des Salles Souterraines (Carte 3)

Chaque action sur l'Overworld (utilisation de `Candle`, `Bomb`, `Recorder`, `Raft`, ou déplacement physique d'un `Armos` ou d'une `Tombstone`) déclenche l'accès à une salle souterraine précise. La conformité des tuiles et des sprites est obligatoire pour garantir le fonctionnement des scripts dans le moteur C64 :

| Coordonnée | Élément Overworld déclencheur | Type de Salle Souterraine associée | Nom interne / Acteurs | Impact si non corrigé sur C64 |
| :--- | :--- | :--- | :--- | :--- |
| **B3** | `Tombstone` centrale supérieure à pousser | Don de la **Magical Sword** | `ACTOR_OLD_MAN` + `ITEM_MAGICAL_SWORD` | Collision bloquée ou impossible à pousser. |
| **H8** | Entrée de grotte ouverte au centre | Don de la **Wooden Sword** | `ACTOR_OLD_MAN` + `ITEM_WOODEN_SWORD` | Entrée de départ du jeu introuvable. |
| **K1** | Entrée de grotte ouverte dans la falaise | Don de la **White Sword** | `ACTOR_OLD_MAN` + `ITEM_WHITE_SWORD` | Bloque l'accès à l'amélioration d'arme. |
| **P1** | Grotte entre les `Spectacle Rock` (`Bomb`) | **Level 9: Death Mountain** (Donjon final) | Donjon Level 9 | Entrée du boss de fin inaccessible. |
| **D4** | Dallage sacré aux 8 `Stone Pillar` (`Recorder`) | **Level 7: The Demon** (Donjon) | Donjon Level 7 | La Flûte n'assèche pas le lac / donjon verrouillé. |
| **N2** | 5ᵉ `Dead Tree` à consumer (`Candle`) | **Level 8: The Lion** (Donjon) | Donjon Level 8 | Mauvais type d'arbre : la flamme ne révèle aucun escalier. |
| **G5** | `Hollow Tree Entrance` au centre de l'île | **Level 1: The Eagle** (Donjon) | Donjon Level 1 | Pas de lac = île et entrée absentes. |
| **P2** | Statue `Armos` centrale à toucher/pousser | **Secret Shop** (Flèches & Équipement) | `ACTOR_MERCHANT` + `STAIRS` | Sprite buisson = aucune détection de poussée. |
| **P3** | `Raft Dock` vers l'îlot est | **Heart Container** (Vieillard) | `ACTOR_OLD_MAN` + `ITEM_HEART_CONTAINER` | Sans débarcadère, Link ne peut pas naviguer. |
| **A2, I3, M3, J5** | Falaises fissurables (`Bomb`) / Buisson (`Candle`) | **Heart Containers** supplémentaires | `ACTOR_OLD_MAN` + `ITEM_HEART_CONTAINER` | Grottes fermées ou détruites par des éléments parasites. |
| **D3, I3, L7, N8** | Arbres secrets / Paliers de téléportation | **Warp Zones** (Téléportation rapide) | `WARP_STAIRS` | Rupture du transit instantané sur la carte. |
| **C7, D7, E7, H7** | `Dead Tree` et `Green Tree` secrets (`Candle`) | **Secret Moblins** & **Potion Shops** | `ACTOR_SECRET_MOBLIN` / `ACTOR_OLD_WOMAN` | Impossibilité de financer l'équipement et de se soigner. |
| **I2, J2** | Parois rocheuses nord (`Bomb`) | **Boutiques & Indices de progression** | `ACTOR_MERCHANT` / `ACTOR_OLD_MAN` | Noyées sous le faux canal d'eau horizontal. |