# Cahier de Recettes & Protocole de Validation — The Legend of Zelda (Commodore 64)

Ce document constitue le **Cahier de Recettes officiel et protocole d'assurance qualité (QA)** pour le portage C64 de *The Legend of Zelda*. Il définit les procédures d'acceptation, les contrôles visuels et comportementaux, les standards universels du jeu vidéo, ainsi que la matrice de vérification exhaustive des anomalies consignées dans [bugs.md](file:///home/vedix/Documents/C64/zelda/bugs.md) et [AGENTS.md](file:///home/vedix/Documents/C64/zelda/AGENTS.md).

---

## Sommaire
1. [Fiche d'Identité Technique du Système](#1-fiche-didentité-technique-du-système)
2. [Section 0 : Standards Universels de Gameplay & QA Jeu Vidéo](#2-section-0--standards-universels-de-gameplay--qa-jeu-vidéo)
3. [Section A : Démarrage, Boot Cartouche & Sélection Audio](#3-section-a--démarrage-boot-cartouche--sélection-audio)
4. [Section B : Overworld, Streaming des Chunks & Collisions](#4-section-b--overworld-streaming-des-chunks--collisions)
5. [Section C : Donjons 1 à 9, Architecture & Salles Scellées](#5-section-c--donjons-1-à-9-architecture--salles-scellées)
6. [Section D : Bestiaire, Boss & IA des Monstres](#6-section-d--bestiaire-boss--ia-des-monstres)
7. [Section E : Objets, Armes & Mécanique de l'Échelle](#7-section-e--objets-armes--mécanique-de-léchelle)
8. [Section F : Inventaire 4 Pages & HUD Dynamique](#8-section-f--inventaire-4-pages--hud-dynamique)
9. [Section G : Moteur Sonore SID & Spatialisation Dual SID](#9-section-g--moteur-sonore-sid--spatialisation-dual-sid)
10. [Section H : Overlays Cartouche & Menu Debug](#10-section-h--overlays-cartouche--menu-debug)
11. [Section I : Invariants Matériels & Plafonds Mémoire](#11-section-i--invariants-matériels--plafonds-mémoire)
12. [Matrice de Traçabilité des 23 Bugs & Anomalies Résolus](#12-matrice-de-traçabilité-des-23-bugs--anomalies-résolus)
13. [Grille d'Acceptation et Décision GO / NOGO](#13-grille-dacceptation-et-décision-go--nogo)

---

## 1. Fiche d'Identité Technique du Système

| Composant | Spécification C64 Active | Rôle & Contraintes Critiques |
|---|---|---|
| **CPU** | MOS 6510 / 8502 @ 0.985 MHz (PAL) | Boucle de jeu 50 Hz synchrone avec le raster VIC-II. Pile matérielle `$0100..$01FF`. |
| **GPU / Vidéo** | MOS VIC-II (6569/8565) | 320x200 (Mode Texte Multicolore 40x25, Charset à `$2000`). 8 Sprites matériels avec multiplexeur dynamique. |
| **Audio** | MOS 6581 / 8580 Mono ou Dual SID | Mono `$D400` ; Stéréo configurable `$D420`, `$D500`, `$DF00`. Réarmement ADSR $\ge 16$ cycles. |
| **Support** | Cartouche Magic Desk 512 Ko (64 banques de 8 Ko à `$8000..$9FFF`) | Streaming dynamique de chunks, donjons et overlays en RAM résidente. |
| **Zone Résidente** | `$0800..$9FFF` | Moteur de jeu principal. Plafond strict à `$9FFF` (`OVERLAY_RAM_ADDR = $A000`). |
| **Zone Overlays** | `$A000..$BFFF` | Mémoire d'exécution dynamique (Banques 27 Inventaire, 28 Grottes, 29 Items, 30 Debug). |
| **Streaming Salles**| `$C000..$CFFF` | Tampons de cartes Overworld (OW0..OW3) et Donjons (Dung 1..9). |

---

## 2. Section 0 : Standards Universels de Gameplay & QA Jeu Vidéo

Cette section vérifie les comportements fondamentaux communs à tous les jeux d'action-aventure.

### 2.1 [STD-01] Collisions, Anti-Tunneling & Glissement de Paroi
- **Objectif** : Empêcher toute traversée de décor solide même à vitesse maximale, et assurer un glissement fluide le long des parois.
- **Précondition** : Link en jeu, dans une zone comportant des arbres, rochers ou murs.
- **Actions** :
  1. Diriger Link droit vers un obstacle solide (arbre ou mur) à vitesse nominale.
  2. Maintenir une direction diagonale (ex: Haut + Droite) contre un mur vertical.
- **Constatations sur comportement de jeu** :
  - Link s'arrête net au contact de l'obstacle : aucun franchissement ni téléportation de pixel (anti-tunneling).
  - La composante parallèle du mouvement est conservée : Link glisse le long du mur sans se coincer dans les angles.
- **Capture de contrôle** : `recette_std01_wall_collision.png`.

### 2.2 [STD-02] Dégâts, Recul (Knockback) & Invulnérabilité (I-Frames)
- **Objectif** : Valider le retour d'information lors d'un coup subi par le joueur.
- **Précondition** : Link en présence d'un ennemi mobile (ex: Octorok ou Moblin).
- **Actions** :
  1. Laisser Link entrer en collision avec le monstre ou son projectile.
- **Constatations sur comportement de jeu** :
  - **Hitbox & PV** : Décrémentation immédiate d'un demi-cœur (ou cœur entier) dans le HUD (`hud_cur_hearts`).
  - **Knockback** : Recul physique de Link sur plusieurs pixels dans la direction opposée à l'impact.
  - **I-Frames** : Link passe en état d'invulnérabilité pendant ~0.6 seconde (32 frames, `player_hurt_timer`).
  - **Feedback Visuel** : Clignotement continu du sprite de Link pendant les i-frames.
  - **Feedback Sonore** : Bruitage de blessure percutant sur la Voix 3 (`sound_link_hurt`).
- **Capture de contrôle** : `recette_std02_player_hurt_iframe.png`.

### 2.3 [STD-03] Mort du Joueur & Cycle de Game Over
- **Objectif** : Valider la fin de partie lorsque les points de vie atteignent 0.
- **Précondition** : Link à 1 demi-cœur.
- **Actions** :
  1. Subir un dégât fatal.
- **Constatations sur comportement de jeu** :
  - `hud_cur_hearts` tombe à 0.
  - Blocage des commandes de déplacement de Link.
  - Animation de défaite et transition vers la séquence de reprise/Game Over.
  - Réinitialisation propre des PV au respawn (3 cœurs pleins) sans corruption d'inventaire.
- **Capture de contrôle** : `recette_std03_game_over.png`.

### 2.4 [STD-04] Ergonomie, Réactivité & Anti-Rebond (Debounce)
- **Objectif** : Garantir la réactivité instantanée et éviter les répétitions involontaires lors d'appuis continus.
- **Actions** :
  1. Appuyer brièvement sur le bouton de tir de l'épée.
  2. Maintenir enfoncée la touche d'ouverture de l'inventaire ou le bouton de tir.
- **Constatations sur comportement de jeu** :
  - Lenteur de latence $\le 1$ frame (20 ms à 50 Hz).
  - L'appui continu ne déclenche pas une rafale infinie de coups : le front montant (`edge detection`) impose de relâcher pour réattaquer.
  - L'inventaire ne clignote pas entre ouverture et fermeture lors d'un appui long.

### 2.5 [STD-05] Bornage Arithmétique des Ressources (Clamping & Anti-Underflow)
- **Objectif** : Éviter les dépassements de capacité (overflow) ou valeurs négatives (underflow).
- **Actions** :
  1. Ramasser des cœurs lorsque la vie est au maximum (`hud_cur_hearts == hud_max_hearts`).
  2. Ramasser des rubis jusqu'au plafond (255 rubis).
  3. Tenter d'utiliser une bombe ou une flèche avec un compteur à 0.
- **Constatations sur comportement de jeu** :
  - Clamping haut : les cœurs ne dépassent jamais `hud_max_hearts`.
  - Clamping rubis : arrêt strict à 255 sans retour à 0.
  - Clamping bas : impossible de poser une bombe avec 0 bombe ; aucun compteur ne passe à `$FF` (-1).
- **Capture de contrôle** : `recette_std05_resource_clamping.png`.

### 2.6 [STD-06] Persistance des États de Salle & Non-Duplication
- **Objectif** : Maintenir l'état des énigmes et empêcher l'exploitation de récompenses infinies.
- **Actions** :
  1. Déverrouiller une porte ou pousser un bloc secret révélant un escalier.
  2. Quitter la salle, puis y revenir immédiatement.
  3. Collecter un réceptacle de cœur ou un objet majeur (ex: Boomerang, Arc).
- **Constatations sur comportement de jeu** :
  - La porte reste déverrouillée et l'escalier reste visible (`dungeon_room_state`).
  - L'objet majeur ramassé ne réapparaît pas (zéro duplication).
- **Capture de contrôle** : `recette_std06_persistence_stairs.png`.

### 2.7 [STD-07] Performance & Stress Test 50 Hz sous Charge
- **Objectif** : Éprouver la stabilité sous la charge maximale du moteur.
- **Actions** :
  1. Réunir 4 ennemis actifs simultanés + tirs de projectiles + Link attaquant à l'épée.
- **Constatations sur comportement de jeu** :
  - Le framerate reste stable à 50 Hz sans saccades excessives.
  - La pile matérielle CPU (`$0100..$01FF`) reste parfaitement bornée (aucun crash ni empilement incontrôlé).
  - Le multiplexeur de sprites ne présente aucun saut de trame vertical.

---

## 3. Section A : Démarrage, Boot Cartouche & Sélection Audio

### 3.1 [BOOT-01] Menu de Configuration Audio au Démarrage
- **Objectif** : Permettre le paramétrage audio stéréo sans overhead en cours de jeu.
- **Procédure** :
  1. Démarrer la machine sur la cartouche `zelda.crt`.
  2. Observer l'apparition du menu interactif de sélection SID.
- **Constatations Visuelles (Capture)** :
  - Présence du logo Triforce géant composé de 3 sprites VIC-II matériels expansés couleur or (`COL_YELLOW`).
  - Affichage des 4 options : 1 SID Mono standard, 2 SID Stéréo `$D420`, 2 SID Stéréo `$D500`, 2 SID Stéréo `$DF00`.
  - Curseur réactif au Joystick et au clavier.
- **Constatations Comportementales** :
  - Validation par Bouton Feu ou temporisation automatique (~10s).
  - Émission d'un bip de confirmation respectant le palier bas `Gate=0` $\ge 16$ cycles CPU.
  - Relocalisation dynamique en RAM des 79 instructions ciblant `$D420..$D438` en fonction de l'adresse choisie.
- **Capture de contrôle** : `recette_boot01_sid_menu.png`.

### 3.2 [BOOT-02] Déroulement de l'Intro Cinématique & Écran Titre
- **Objectif** : Valider l'intro déroulante, l'histoire et le thème musical.
- **Procédure** :
  1. Laisser défiler la cascade et le prologue textuel.
- **Constatations Visuelles (Capture)** :
  - Texte déroulant limpide sans déchirement de caractères.
  - Logo Titre Legend of Zelda net, cadre ornemental stable.
- **Constatations Comportementales** :
  - En mode Dual SID, activation du chorus stéréo (+2 de désaccord de fréquence entre SID1 et SID2 sur Voix 1 et 2).
  - Passage fluide vers la boucle principale du jeu (`main_loop`) via `launch_zelda_game`.
- **Capture de contrôle** : `recette_boot02_title_screen.png`.

---

## 4. Section B : Overworld, Streaming des Chunks & Collisions

### 4.1 [OW-01] Rendu de la Clairière Initiale & HUD
- **Objectif** : Valider l'affichage de la salle de départ (Zone 0, Salle `$77`).
- **Constatations Visuelles (Capture)** :
  - Link au centre, orienté vers le nord (grotte de l'épée).
  - Arbres, rochers, ouverture de grotte nettement découpés en tuiles multicolores.
  - HUD complet : Minimap Overworld en haut à gauche, compteurs de rubis/clés/bombes au centre, 3 cœurs de vie en haut à droite.
- **Capture de contrôle** : `recette_ow01_start_room.png`.

### 4.2 [OW-02] Défilement Continu & Streaming Cartouche (Pas de Flash)
- **Objectif** : Valider le défilement dans les 4 directions et le franchissement de chunks cartouche sans flash noir/blanc parasite.
- **Procédure** :
  1. Déplacer Link vers le bord droit (X=284) pour déclencher le scrolling horizontal.
  2. Déplacer Link vers le haut pour franchir la frontière entre Chunk 2 et Chunk 1.
- **Constatations Visuelles (Capture)** :
  - Masquage écran (VIC blanking) maintenu rigoureusement pendant la copie cartouche.
  - Aucun clignotement ni flash blanc/noir à l'écran.
- **Constatations Comportementales** :
  - La routine `cart_stream_copy` découpe le transfert page par page (256 octets) avec relâchement des interruptions (`CLI`), assurant la continuité du son SID et du raster.
  - Décompression fidèle dans `room_buf[ty * 20 + tx]`.
- **Captures de contrôle** : `recette_ow02_transition_mid.png`, `recette_ow02_chunk_switch.png`.

### 4.3 [OW-03] Intégrité des Collisions Décors (Arbres, Eau, Montagnes)
- **Objectif** : Vérifier l'étanchéité des décors naturels.
- **Procédure** :
  1. Tenter d'avancer vers l'eau du littoral (salle `$7F`) sans radeau ni échelle.
  2. Se déplacer contre les rochers de Death Mountain (salle `$05`).
- **Constatations Comportementales** :
  - `check_point_solid` interdit rigoureusement la marche sur l'eau ou les parois montagneuses.
- **Capture de contrôle** : `recette_ow03_coast_water_solid.png`.

---

## 5. Section C : Donjons 1 à 9, Architecture & Salles Scellées

### 5.1 [DUNG-01] Chargement des Donjons en Haute RAM ($C000)
- **Objectif** : Valider le streaming des données donjons depuis les banques 18 à 26 vers `$C000`.
- **Procédure** :
  1. Pénétrer dans le Donjon 1 (Niveau 1 Eagle).
- **Constatations Visuelles (Capture)** :
  - Teinte spécifique du donjon (murs turquoise/bleus, sol sombre).
  - Portes d'entrée et portes verrouillées fermées conformes.
  - Minimap HUD adaptée : tracé de l'arène du donjon avec boussole.
- **Capture de contrôle** : `recette_dung01_level1_entrance.png`.

### 5.2 [DUNG-02] Donjon 4 : Intégrité des 20 Salles & Élimination des Salles Fantômes
- **Objectif** : Confirmer que le Donjon 4 (Snake) comporte strictement ses 20 salles officielles et zéro salle fantôme.
- **Procédure** :
  1. Charger le Donjon 4 via le hook debug.
  2. Vérifier l'en-tête de détection des salles scellées stocké en `$C012..$C013` (`dummy_sealed_room_ptr`).
  3. Inspecter la salle `$41` (pièce des 3 Zols) et la salle `$32` (pièce de l'escalier vers l'échelle).
- **Constatations Visuelles (Capture)** :
  - Salle `$41` : Les 3 Zols sont bien présents, visibles et mobiles (zéro disparition de sprites par `irq_top`).
  - Salle `$32` : Le bloc secret à pousser est présent et aligné.
- **Constatations Comportementales** :
  - Les anciennes fausses salles 0x60, 0x41 fantôme et 0x04 sont inexistantes.
  - La comparaison 16-bit rigoureuse avec `$C012..$C013` empêche l'effacement de la salle 00 sur la minimap.
- **Capture de contrôle** : `recette_dung02_dungeon4_room41.png`.

### 5.3 [DUNG-03] Blocs Secrets Poussables & Tables Strictes
- **Objectif** : Vérifier l'interdiction de pousser un bloc tant que la salle n'est pas vidée de ses monstres.
- **Procédure** :
  1. Entrer dans une salle à secret (ex: Donjon 1 salle `$22`).
  2. Tenter de pousser le bloc secret alors que les ennemis sont encore vivants.
  3. Éliminer tous les ennemis (`DUNG_ROOM_CLEARED = 1`), puis pousser le bloc dans la direction autorisée.
- **Constatations Comportementales** :
  - Tant qu'un ennemi est vivant : le bloc est totalement inamovible.
  - Dès que la salle est nettoyée : la poussée réussit, l'escalier vers le cellier apparaît immédiatement à l'index 90, et le carillon secret retentit.
- **Capture de contrôle** : `recette_dung03_pushed_block_stairs.png`.

### 5.4 [DUNG-04] Confinement Y des Ennemis en Donjon [88, 208]
- **Objectif** : Empêcher les monstres de pénétrer dans le mur nord solide (Y < 88).
- **Procédure** :
  1. Observer la ronde des Goriyas ou Stalfos le long du mur supérieur.
- **Constatations Comportementales** :
  - Bornage strict par `check_bounds_only` : Y reste $\ge 88$. Aucun ennemi ne s'encastre dans le mur nord.
- **Capture de contrôle** : `recette_dung04_goriya_bounds.png`.

---

## 6. Section D : Bestiaire, Boss & IA des Monstres

### 6.1 [EN-01] Monstres Overworld : Conformité Visuelle & Couleurs Propres
- **Objectif** : Valider le rendu 1:1 NES et les palettes dynamiques des ennemis de surface.
- **Constatations Visuelles (Capture)** :
  - **Octorok** : Véritable poulpe à trompe cracheuse (tuiles 34..45), rouge vif (`COL_RED`) ou bleu (`COL_BLUE`) grâce au routage sur la couleur propre `g`.
  - **Moblin** : Silhouette avec lance et foulée articulée.
  - **Lynel** : Centaure doté d'animations complètes sur les 4 directions cardinales (Face, Dos, Profil).
  - **Tektite** : Accroupi au repos et bond déployé en suspension.
  - **Peahat & Leever** : Rotation fluide à hélices et vrille.
  - **Zora** : Ondulation à fleur d'eau et émergence cracheuse.
- **Capture de contrôle** : `recette_en01_overworld_bestiary.png`.

### 6.2 [EN-02] Monstres Donjon : Keese Composite 16x16 & Couleurs Propres
- **Objectif** : Valider l'assemblage complet des Keese et la teinte des créatures souterraines.
- **Constatations Visuelles (Capture)** :
  - Keese : Sprite 16x16 complet avec battement d'ailes déployées (tuiles 0, 2, 1, 3 sans miroir tronqué).
  - Teintes dynamiques propres : Stalfos blanc os (`COL_WHITE`), Zol vert (`COL_GREEN`), Trap cyan (`COL_CYAN`), Wallmaster orange (`COL_ORANGE`).
- **Capture de contrôle** : `recette_en02_keese_stalfos.png`.

### 6.3 [EN-03] IA Spécifiques : Goriya & Boomerang Tête Chercheuse, Wizzrobe
- **Objectif** : Vérifier la trajectoire aller-retour du boomerang ennemi et les patterns Wizzrobe.
- **Constatations Comportementales** :
  - **Goriya** : Détection de couloir de Link (±10 px). Lancer du boomerang sur 28 pas (~56 px), puis retour en tête chercheuse vers `en_proj_owner`, qui récupère son arme.
  - **Wizzrobe Rouge** : Téléportation sur dalle libre du sol (`room_buf == 0`), tir face à Link, puis disparition.
  - **Wizzrobe Bleu** : Glissement continu à travers les murs avec rebond sur les bordures extérieures de l'arène.
- **Capture de contrôle** : `recette_en03_goriya_boomerang.png`.

### 6.4 [EN-04] Boss Multi-Sprites & Gestion du Bit MSB VIC-II ($D010)
- **Objectif** : Valider le rendu monobloc des boss approchant de la bordure droite ($X \ge 240$).
- **Procédure** :
  1. Affronter Dodongo (32x16 pixels) et Aquamentus (24x32 pixels).
  2. Attirer le boss vers la bordure droite de l'écran.
- **Constatations Visuelles (Capture)** :
  - Le boss reste d'un seul bloc jointif : le calcul dynamique du 9ème bit dans `$D010` (`.apply_boss_msb`) empêche toute scission ou téléportation de sa moitié droite sur le bord gauche de l'écran.
  - Gestion autonome des deux Dodongos simultanés (Dodongo 1 sur sprites 3 & 4, Dodongo 2 sur sprites 5 & 6).
- **Capture de contrôle** : `recette_en04_boss_dodongo_msb.png`.

---

## 7. Section E : Objets, Armes & Mécanique de l'Échelle

### 7.1 [ITEM-01] Explosion de Bombe Authentique NES en Rosace à 7 Nuages
- **Objectif** : Valider la conformité visuelle et l'absence de blocage des sprites lors de la détonation.
- **Procédure** :
  1. Poser une bombe (`item_active = ITEM_BOMB`).
  2. Observer l'animation complète de la mèche puis de la déflagration.
- **Constatations Visuelles (Capture)** :
  - Rendu 1:1 net en rosace géométrique à 7 nuages distincts (1 noyau central + 6 satellites en hexagone).
  - Animation dynamique en 3 phases fidèles à la NES :
    - *Phase 1* : Flash blanc intense étincelant.
    - *Phase 2* : Pleine déflagration bouillonnante avec micro-vibration tourbillonnante.
    - *Phase 3* : Dissipation centrifuge via les particules de fumée `SPR_COMMON_DEATH_1`.
  - Aucun usage de `VIC_SPRITE_EXP_X` ni `EXP_Y` (zéro pixel étiré flou).
- **Constatations Comportementales** :
  - Les sprites des monstres et de Link restent affichés en continu pendant toute la durée de l'explosion (`irq_top` ne masque rien).
- **Captures de contrôle** : `recette_item01_bomb_flash.png`, `recette_item01_bomb_cloud.png`.

### 7.2 [ITEM-02] Déploiement de l'Échelle (Stepladder) sans Altération de `room_buf`
- **Objectif** : Valider le franchissement d'un ruisseau sans détruire les ponts existants.
- **Procédure** :
  1. S'approcher d'une rive d'eau avec l'échelle dans l'inventaire.
  2. Franchir le ruisseau sur l'échelle.
- **Constatations Visuelles (Capture)** :
  - L'échelle apparaît sous forme d'entité autonome (Sprite matériel 2, couleur brune `COL_BROWN`).
  - Aucun caractère de tuile n'est écrit dans le tampon de salle `room_buf` (préservation stricte de la géométrie de la carte).
- **Constatations Comportementales** :
  - `check_point_solid` autorise temporairement la marche sur l'index d'eau `ladder_tile_idx`.
  - Dès que Link pose le pied sur la berge opposée (`ladder_stepped_on = 1`), l'échelle se rétracte et disparaît immédiatement (`ladder_tile_idx = $FF`).
- **Capture de contrôle** : `recette_item02_stepladder_crossing.png`.

---

## 8. Section F : Inventaire 4 Pages & HUD Dynamique

### 8.1 [INV-01] Page 0 (Équipement) : Cadre Harmonieux & 6 Reliques Passives
- **Objectif** : Valider la disposition de l'inventaire principal.
- **Constatations Visuelles (Capture)** :
  - Cadre centré sur 18 colonnes (Cols 13..31) avec marges internes $\ge 4$ pixels (zéro dépassement).
  - Sprite de l'arme B sélectionnée centré en (X=64, Y=120) sous "USE B BUTTON FOR THIS".
  - Les 8 armes secondaires réparties dans la grille 4x2 : Boomerang, Bombe, Arc, Bougie, Flûte, Viande, Potion, Baguette.
  - Ligne 6 : Présence des 6 Reliques Passives (Radeau, Livre, Anneau, Échelle, Clé Magique, Bracelet) utilisant les caractères persistants 120..125.
- **Constatations Comportementales** :
  - Les reliques passives restent visibles et intactes même après une entrée en donjon (aucune destruction par la fonte de donjon `$2540`).
- **Capture de contrôle** : `recette_inv01_page0_equipment.png`.

### 8.2 [INV-02] Page 1 (Triforce) : Grande Pyramide Dorée 96x42 Pixels
- **Objectif** : Valider l'assemblage de la Triforce.
- **Constatations Visuelles (Capture)** :
  - Pyramide triangulaire majestueuse (96x42 pixels) formée par 8 fragments biseautés continus et jointifs (`COL_YELLOW`, `COL_ORANGE`, `COL_WHITE`).
  - Socle textuel `+----------+` parfaitement calé sous le pied du triangle à la ligne 11.
  - Label `"TRIFORCE"` centré à la ligne 14.
- **Capture de contrôle** : `recette_inv02_page1_triforce.png`.

### 8.3 [INV-03] Page 2 (Carte Overworld 16x8) : Link sur une Case Unique
- **Objectif** : Valider l'affichage de la carte du monde et le marqueur de Link.
- **Constatations Visuelles (Capture)** :
  - Grille 16x8 nette : chaque salle visitée occupe 1 bloc de caractère dédié suivi d'un espace neutre.
  - La position de Link clignote sur **une seule case** nette (aucun débordement sur 2 cases adjacentes).
- **Capture de contrôle** : `recette_inv03_page2_map.png`.

### 8.4 [INV-04] Page 3 (Carte Donjon) : Carte Interactive & Boussole
- **Objectif** : Valider la carte dynamique en donjon.
- **Constatations Visuelles (Capture)** :
  - Tracé fidèle du plan de l'arène souterraine.
  - Icônes de boussole actives : Triforce ▲ rouge, Link ● jaune, secrets non collectés ◆ or, salles nettoyées ■ cyan.
- **Capture de contrôle** : `recette_inv04_page3_dungeon_map.png`.

---

## 9. Section G : Moteur Sonore SID & Spatialisation Dual SID

### 9.1 [AUDIO-01] Réarmement ADSR & Paliers d'Horloge SID ($\ge 16$ cycles)
- **Objectif** : Empêcher les notes suspendues ou voix muettes après un jingle.
- **Constatations Comportementales** :
  - Toute montée `Gate 0 -> 1` respecte un palier bas d'au moins 16 cycles CPU (8 `nop`), garantissant l'échantillonnage par le diviseur matériel interne du MOS 6581/8580.
  - Initialisation de la musique systématiquement effectuée avec `Gate OFF`.
  - Maintien du bit de forme d'onde sur Gate OFF pour éviter les claquements parasites.

### 9.2 [AUDIO-02] Découplage Voix 2 / Voix 3 & File d'Attente Anti-Conflits
- **Objectif** : Sérialiser les effets sonores concurrents (Clé / Rubis sur Voix 3 vs Carillon secret sur Voix 2).
- **Procédure** :
  1. Ramasser une clé ou un rubis tout en déverrouillant une porte ou révélant un secret dans la même frame.
- **Constatations Comportementales** :
  - Le premier son est émis, et le second est mis en attente (`secret_chime_pending` ou `sfx_rupee_pending`).
  - À la fin du premier son, la voix empruntée est restaurée et le son en attente démarre aussitôt.
  - Aucune voix musicale n'est perdue : polyphonie 3 voix conservée à 100%.

### 9.3 [AUDIO-03] Spatialisation Dual SID & Maintien Stéréo sur Pas de Maintien ($FE)
- **Objectif** : Assurer une spatialisation stéréo stable en donjon et intro.
- **Constatations Comportementales** :
  - Les coups d'épée et SFX sont émis symétriquement sur SID1 et SID2 sous protection continue de `sfx_timer`.
  - Sur chaque pas de maintien musical (`$FE`), le maintien Gate ON est répercuté sur `SID2_V2_CTRL` et `SID2_V3_CTRL`.
  - Restauration intégrale de la PW et de l'enveloppe ADSR sur les deux puces SID lors des sorties de SFX.

### 9.4 [AUDIO-04] Donjon 9 : Thème Étendu Streamé depuis la Banque 31
- **Objectif** : Vérifier la partition authentique et le streaming depuis `CART_BANK_AUDIO`.
- **Procédure** :
  1. Pénétrer dans le Donjon 9 (Death Mountain).
- **Constatations Comportementales** :
  - Streaming dynamique des 2 pages de partition (124 pas authentiques) dans `bgm_track_buffer`.
  - Lecture rythmée en boucle de 22,4 secondes conforme à la NES, sans aucun ralentissement ni désynchronisation.
- **Capture de contrôle** : `recette_audio04_dungeon9_playing.png`.

---

## 10. Section H : Overlays Cartouche & Menu Debug

### 10.1 [OVL-01] Isolation Mémoire Résidente & Plafond $A000
- **Objectif** : Garantir l'absence totale d'écrasement de données résidentes lors du chargement des banques d'overlay.
- **Constatations Comportementales** :
  - Le code résident du moteur de jeu s'achève à `$9F3C` (< `$9FFF`), offrant plus de 190 octets de sécurité sous `$A000`.
  - Les overlays s'exécutent en `$A000..$BFFF` (Banque 27 Inventaire, Banque 28 Grottes, Banque 29 Items, Banque 30 Debug).
  - Après 100 ouvertures/fermetures consécutives de l'inventaire ou du menu debug, les tables musicales BGM et l'état de jeu restent intacts à 100%.

### 10.2 [OVL-02] Menu Debug & Fonctions de Warp
- **Objectif** : Valider les outils de téléportation et d'inspection intégrés.
- **Procédure** :
  1. Ouvrir le menu debug (touche Backarrow `<-`).
  2. Téléporter Link dans l'Overworld ou dans un Donjon (1 à 9).
  3. Retourner en jeu.
- **Constatations Visuelles (Capture)** :
  - Menu debug clair (affichage des coordonnées de Link, salle courante, flags d'items).
  - Téléportation instantanée avec rechargement propre de la banque de sprites correspondante (Banque 10 Overworld ou 11 Donjon).
- **Capture de contrôle** : `recette_ovl02_debug_menu.png`.

### 10.3 [OVL-03] Ramassage d'Objets en Cavernes & Célébration Délimitée (Non-Bouclage)
- **Objectif** : Valider que le ramassage de la première épée (ou de tout objet en boutique/grotte) désactive immédiatement le slot, déclenche la fanfare triomphale et l'animation Item-Get une seule fois, éteint la célébration au bout de 75 frames, et permet à Link de reprendre ses déplacements sans boucle infinie.
- **Constatations Comportementales & Visuelles** :
  - `cave_slot2_active` passe à 0 dès la frame de contact.
  - `cave_pickup_timer` est armé à 75, Sprite 0 passe en pose `SPR_COMMON_ITEM_GET` et Sprite 7 affiche l'objet levé.
  - Après 75 frames, le timer expire à 0, Link revient en pose de marche neutre, Sprite 7 est éteint.
  - Même si Link reste immobile sur l'emplacement du slot, aucune réactivation n'a lieu (0 boucle infinie).
  - Link peut marcher vers le bas (Y=214) et sortir librement de la caverne vers l'Overworld.
- **Script automatisé** : `python3 tools/test_cave_sword_pickup.py`.
- **Captures de contrôle** : `test_cave_pickup_celebration.png`, `test_cave_pickup_finished.png`, `test_cave_pickup_exit_ow.png`.

---

## 11. Section I : Invariants Matériels & Plafonds Mémoire

| Plafond Matériel C64 | Limite Stricte | Adresse Réelle Actuelle | Statut de Conformité |
|---|---|---|---|
| **Sprites Link (Banque 0 VIC)** | $\le \$1000$ (chargen) | `$0800..$1000` (exactement `$1000`) | **CONFORME** (0 débordement) |
| **Charset Résident Multicolore** | Adresse fixe `$2000` | Début `$2000` (code bas $\le \$1ED4$) | **CONFORME** (180+ octets libres) |
| **Zone Haute RAM Résidente** | $\le \$9FFF$ (`$A000`) | S'achève à `$9F3C` | **CONFORME** (196 octets de marge) |
| **Streaming Salles Cartouche** | Base `$C000` | Dédié `$C000..$CFFF` | **CONFORME** |
| **Slots Sprites Donjon** | $\le 75$ slots | 58 slots utilisés | **CONFORME** (17 slots de réserve) |

---

## 12. Section J : Tests Avancés d'Intégrité Matérielle, Topologie & Robustesse

### 12.1 [SPR-01] Audit Statique & Dynamique d'Intégrité Mémoire des Sprites
- **Objectif** : Vérifier que chaque sprite affiché à l'écran correspond rigoureusement à une zone mémoire valide et non-corrompue.
- **Contrôles Statiques** :
  - Audit de l'intégralité des tables de pointeurs assembleur (`octo_ptrs`, `moblin_ptrs`, `keese_ptrs`, `dodongo_ptrs`, etc.).
  - Vérification que 100% des symboles dans `build/sprite_ptrs.inc` sont rigoureusement indexés dans la plage dynamique autorisée `[$A0, $FF]` pour les banques en `$2800..$3FFF` ou `[$20, $3F]` pour Link.
  - Contrôle d'intégrité binaire des 4 banques cartouches (`sprites_ow.bin`, `sprites_dung.bin`, `sprites_boss.bin`, `sprites_npc.bin`) : présence de données bitmap non nulles sur chaque slot.
- **Contrôles Dynamiques en Jeu (VICE)** :
  - Échantillonnage à chaque frame des 8 pointeurs de sprites matériels dans la Screen RAM (`$07F8..$07FF`) et du registre d'activation `$D015` (`VIC_SPRITE_EN`).
  - **Interdiction absolue** : aucun sprite actif ne doit pointer dans `$00..$1F` (Zero Page, pile, RAM écran `$0400`) ou `$40..$9F` (Chargen ROM et Charset RAM `$2000`).
  - Validation du bloc mémoire bitmap (64 octets en RAM pointée) : absence de bloc vierge ou corrompu.
  - Validation de la couleur propre (`$D027..$D02E` $\le 15$) et du bit multicolore `$D01C`.
- **Script automatisé** : `python3 tools/test_sprite_memory_integrity.py`.

### 12.2 [MAP-01] Audit Topologique & Réciprocité des Salles et Portes
- **Objectif** : Garantir la cohérence topologique des 189 salles de donjons et des 128 salles Overworld.
- **Contrôles de Donjons** :
  - Détection automatique de toutes les salles actives (hors `dummy_sealed_room`).
  - Vérification de la réciprocité stricte des portes : toute porte franchissable Nord/Sud ou Est/Ouest doit déboucher sur une salle active comportant la porte opposée correspondante (0 porte borgne tolérée).
  - Absence de murs fermés en face d'une porte ouverte.
- **Contrôles d'Overworld** :
  - Vérification des 128 tables d'apparition d'ennemis de `src/map_overworld_enemies.inc`.
  - Intégrité des 4 chunks cartouche `OW0..OW3`.
- **Script automatisé** : `python3 tools/test_map_topology_reachability.py`.

### 12.3 [STK-01] Endurance de la Pile CPU 6502 & Inviolabilité des Overlays
- **Objectif** : Éprouver la robustesse du moteur sous une série intensive de transitions d'état.
- **Procédure** :
  - Enchaînement de 16 bascules d'état rapides (Jeu normal, Inventaire Pages 0 à 3, Menu Debug, Donjons 1, 2, 4, Overworld).
- **Contrôles Comportementaux** :
  - Pointeur de pile CPU (`SP` en `$0100..$01FF`) : zéro fuite cumulée, pile parfaitement bornée.
  - Haute RAM résidente sous `$A000` (`$9F3C..$9FFF`) : 100% identique avant et après les transitions d'overlays cartouches.
- **Script automatisé** : `python3 tools/test_stack_overlay_endurance.py`.

### 12.4 [ARM-01] Mécanique des Statues Armos & Révélation Canonique des Secrets (E-4, E-3, M-2, N-4, O-5)
- **Objectif** : Valider l'alignement 1:1 des statues de pierre `TILE_STATUE`, le réveil des guerriers Armos au contact, la révélation exclusive des 5 secrets canoniques sous leur statue authentique respective, et la persistance de l'ouverture des escaliers lors des ré-entrées en salle.
- **Scénarios & Constatations** :
  1. **Salle 52 (E-4, 6 statues Armos)** :
     - Les 6 sprites Armos sont ancrés sur les 6 statues de décor aux coordonnées exactes `(4,4), (6,4), (8,4)` et `(4,6), (6,6), (8,6)`.
     - Contact avec statue non-secrète `(4,4)` : l'Armos s'éveille en roaming, la tuile devient herbe libre `TILE_GRASS`, aucun escalier n'apparaît.
     - Contact avec statue secrète milieu-haut `(6,4)` : l'Armos s'éveille, carillon secret, la tuile devient escalier `TILE_CAVE` (tuile 86).
     - Entrée dans l'escalier : Link entre dans l'échoppe de l'Anneau Bleu (250R).
     - Sortie de l'échoppe : Link réapparaît en E-4, l'escalier reste ouvert et praticable, l'Armos du secret ne réapparaît pas sur les marches, et les statues non-secrètes sont réinitialisées.
  2. **Salle 36 (E-3, 10 statues Armos)** :
     - Statue haut-droite `(16,4)` : réveil de l'Armos, révélation de l'escalier `TILE_CAVE` (tuile 96), et octroi du Bracelet de Force (`player_has_bracelet = 1`).
- **Scripts automatisés** : `python3 tools/test_armos_e4_secret.py` et `python3 tools/test_armos_feature.py`.
- **Captures de contrôle** : `armos_e4_01_init.png` à `armos_e4_05_reentered_room.png`, `armos_01_sleeping_statues.png`, `armos_02_awakened_secret.png`.

---

## 13. Matrice de Traçabilité des 25 Bugs & Anomalies Résolus

| ID Bug | Problème Identifié dans les Docs | Preuve de Non-Régression & Test Dédié | Statut |
|---|---|---|:---:|
| **Bug 1** | Explosion bombe figeant les sprites | `test_rules_audit.py` (Test 1 & 2) : sprites actifs pendant l'explosion | **RÉSOLU** |
| **Bug 2** | Flash blanc/noir en transition Overworld | `test_verified_bugs.py` : streaming 256o avec CLI, VIC blanking maintenu | **RÉSOLU** |
| **Bug 3** | Décalage collision tuiles décors | `test_verified_bugs.py` : invariance `room_buf[ty * 20 + tx]` | **RÉSOLU** |
| **Bug 4** | Ennemis spawnant dans des blocs donjon | `test_rules_audit.py` (Test 5) : 0 conflit sur les 498 monstres | **RÉSOLU** |
| **Bug 5** | Poussée permissive de blocs secrets | `test_rules_audit.py` (Test 6) : `push_tbl` exclusive + `DUNG_ROOM_CLEARED` | **RÉSOLU** |
| **Bug 6** | Voix muette après ramassage d'objet | `test_dungeon_music_stability.py` : délai $\ge 16$ cycles Gate 0->1 | **RÉSOLU** |
| **Bug 7** | Monstres disparus salle 0x41 Donjon 4 | `test_rules_audit.py` (Test 1) : 3 Zols visibles et mobiles | **RÉSOLU** |
| **Bug 8 & 12**| Bombe déformée & rosace 7 nuages | `test_rules_audit.py` (Test 2) : motif rosace 1:1, 3 phases animées | **RÉSOLU** |
| **Bug 9** | Conflit Voix 2 / Voix 3 ramassage clé | `test_audio_queue_conflict.py` : découplage `restore_music_voice_2/3` | **RÉSOLU** |
| **Bug 10** | Disparition monstres bas donjon (Y >= 210) | `test_rules_audit.py` (Test 1) : mode passe unique si $\le 4$ monstres | **RÉSOLU** |
| **Bug 11** | Ennemis Overworld dans rochers/arbres | `test_rules_audit.py` (Test 5) : 0 collision sur les 128 salles OW | **RÉSOLU** |
| **Bug 13** | Perte de voix / notes suspendues SID | `test_4_bugs_stabilisation.py` : synchro IRQ 50Hz, Gate OFF à l'init | **RÉSOLU** |
| **Bug 14** | Conflit clé + secret simultanés | `test_audio_queue_conflict.py` : file d'attente séquentielle `pending` | **RÉSOLU** |
| **Bug 15** | Menu SID boot & Triforce or | `test_dual_sid_intro.py` : Triforce sprites $\le \$1000$, patch 79 opcodes | **RÉSOLU** |
| **Bug 16** | Épée inaudible & déconnexion Dual SID | `test_dual_sid_dungeon.py` : protection `sfx_timer`, `ldy dual_sid_enabled` | **RÉSOLU** |
| **Bug 17 & 18**| Inventaire cadre, Triforce, arme centrée| `test_verified_bugs.py` : cadre 18 cols, Sprite 0 à (64, 120), Link 1 case | **RÉSOLU** |
| **Bug 19** | Triforce en piliers disjoints | `test_verified_bugs.py` : pyramide 4 étages biseautés, socle ligne 11 | **RÉSOLU** |
| **Bug 20** | Reliques passives écrasées en donjon | `test_verify_cart_items.py` : reliques dans caractères 120..125 protégés | **RÉSOLU** |
| **Bug 21** | Échelle bloquant les ponts de carte | `test_verified_bugs.py` : entité Sprite 2 autonome, 0 écriture `room_buf` | **RÉSOLU** |
| **Bug 22** | Goriya bloqué mur nord & boomerang | `test_verify_enemy_sprites.py` : Y [88, 208], boomerang tête chercheuse | **RÉSOLU** |
| **Bug 23** | Tables BGM écrasées par overlays ($A000) | `test_dungeon_music_stability.py` : fin résidente $\le \$9FFF$, D9 Bank 31 | **RÉSOLU** |
| **Anomalie 11**| Ralentissement Thème Donjon 9 | `test_dungeon9_audio.py` : table 2 `ow_durs`, 124 pas rythmés (22,4s) | **RÉSOLU** |
| **Anomalie 12**| Sprites monstres ajourés/défectueux | `test_verify_enemy_sprites.py` : Darknut, Dodongo, Ganon 1:1 NES | **RÉSOLU** |
| **Anomalie 13**| Boss scindés bord droit (MSB $D010) | `test_verify_enemy_sprites.py` : routines `.apply_boss_msb` Spr 3..6 | **RÉSOLU** |
| **Anomalie 14**| Monstres Overworld déformés/figés | `tools/capture_ow_enemies.py` : 114 tuiles CHR NES, Lynel 4 directions | **RÉSOLU** |
| **Anomalie 15**| Octorok ressemblant au chevalier Armos | `tools/capture_ow_enemies.py` : tuiles 34..45, couleur propre `g` | **RÉSOLU** |
| **Anomalie 16**| Donjon 4 décalé & Wizzrobe inactif | `test_dungeon4_reconstructed.py` : 20 salles exactes, en-tête `$C012` | **RÉSOLU** |
| **Bug 24** | Boucle infinie ramassage épée en grotte | `test_cave_sword_pickup.py` : préservation registre X, slot désactivé à 0 | **RÉSOLU** |
| **Bug 25** | Statues Armos décalées & secrets erronés | `test_armos_e4_secret.py`, `test_armos_feature.py` : spawn 1:1, 5 secrets First Quest | **RÉSOLU** |

---

## 14. Grille d'Acceptation et Décision GO / NOGO

Pour autoriser une version de livraison du jeu :
1. **Compilation ACME** : 0 erreur, 0 avertissement.
2. **Plafonds Mémoire** : respect absolu des limites `$1000`, `$2000`, `$9FFF` et `$C000`.
3. **Tests Automatisés** : 100% de réussite sur la suite `python3 tools/run_cahier_recettes.py`.
4. **Validation Audio** : 0 voix coupée après 400 frames de jeu et 20 changements de salle.
5. **Validation Visuelle** : conformité intégrale des captures d'écran générées dans `screenshots/recette/`.
