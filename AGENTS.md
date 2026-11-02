# Directives de Développement et Invariants Techniques - Zelda C64

Ce projet est un portage fidèle du jeu original *The Legend of Zelda* (NES) sur Commodore 64 (processeur MOS 6510, vidéo VIC-II, son SID 6581/8580, cartouche Magic Desk).
Avant toute modification ou ajout de code, consulter le registre des anomalies dans [bugs.md](./bugs.md) et respecter impérativement les garde-fous ci-dessous.

## 1. Multiplexeur de Sprites et Interruptions Raster (VIC-II)
- Ne jamais inhiber globalement les sprites (`apply_top_sprites`, `apply_bottom_sprites`) dans les routines d'interruption raster (`irq_top`, `irq_bottom`) lors de l'activation ou de l'animation d'un objet (ex: bombe).
- L'affichage des sprites du joueur, des monstres et des armes doit rester continu sous peine de figer visuellement la scène.
- **Passe Unique Dynamique ($\le 4$ ennemis)** : Si le nombre d'ennemis actifs est $\le 4$ (`sort_eff_y[sort_idx[4]] == $FF`), ne jamais programmer `irq_mid` à raster 230 ; sauter directement à raster 250 (`irq_bottom`) pour éviter d'éteindre prématurément les sprites 3..6 en bas de l'écran.

## 2. Transitions d'Écran et Streaming Cartouche
- Lors d'une transition ou d'un chargement de salle/chunk, maintenir le masquage écran (VIC blanking) jusqu'à ce que la Screen RAM ($0400) et la Color RAM ($D800) soient intégralement écrites.
- Ne jamais bloquer les interruptions (`SEI`) de manière prolongée pendant un transfert cartouche (`cart_stream_copy`) : découper la copie page par page (256 octets) avec un relâchement `CLI` pour préserver le timing VBlank et le son SID.

## 3. Invariance des Collisions et Tampons de Tuiles
- La table de collision en jeu dépend strictement de l'invariance `room_buf[ty * 20 + tx]`.
- Lors du défilement ou du chargement d'une salle, s'assurer que les calculs de pointeurs de rangée (`tile_row_offset`) et les coordonnées `(x, y)` transmises à `get_tile_at_point` / `check_point_solid` restent parfaitement alignés.

## 4. Apparition des Ennemis (Spawns Donjon & Overworld)
- Tout ennemi apparaissant dans une salle de donjon ou d'Overworld doit obligatoirement être positionné sur une tuile libre traversable (`solid == False`, `tile != water` pour monstres terrestres ; `tile == 4` pour Zora).
- Les tables d'ennemis de donjon doivent être générées via `tools/build_dungeons.py`, et celles de l'Overworld via `tools/relocate_overworld_spawns.py`, qui intègrent la relocalisation automatique en spirale des tuiles solides.
- Conserver le garde-fou runtime dans `src/enemies.asm` (`init_slot_from_table`) testant la collision avec `check_point_solid` pour tous les mondes (sauf exceptions volantes Keese/Peahat et aquatique Zora).

## 5. Blocs Secrets Poussables en Donjon
- Ne jamais implémenter de fallback permissif de poussée (pas de `.clp_generic` ni de `.dpb_generic`).
- Un bloc secret ne peut bouger que si :
  1. Tous les ennemis de la salle sont vaincus (`dungeon_room_state & DUNG_ROOM_CLEARED != 0`).
  2. Le secret n'a pas déjà été activé (`dungeon_room_state & DUNG_SECRET_REVEALED == 0`).
  3. La salle, les coordonnées du bloc et la direction autorisée sont explicitement répertoriées dans `push_tbl`.

## 6. Moteur Sonore SID et Fanfares
- **Réarmement ADSR & Délai d'Échantillonnage ($\ge 16$ cycles)** : L'enveloppe SID ne se déclenche que sur une transition montante `Gate 0 -> 1`. Le diviseur d'horloge interne de l'enveloppe échantillonne Gate toutes les 16 périodes CPU : toujours respecter un palier bas `Gate=0` d'au moins 16 cycles (8 `nop`) avant de programmer `Gate=1` pour que le réarmement ne soit jamais manqué.
- **Initialisation avec Gate OFF** : Dans `.init_dungeon_inst` et `.init_overworld_inst`, programmer systématiquement les registres de contrôle avec `Gate=0` ; la montée à `Gate=1` est réservée à `apply_music_step` lors de l'assignation de la fréquence de note.
- **Gestion des Drapeaux SFX & Découplage des Voix** : Les canaux Voix 2 (carillon secret / contre-chant) et Voix 3 (SFX / basse) sont strictement découplés (`restore_music_voice_2` et `restore_music_voice_3`). `.stop_chime` doit appeler `restore_music_voice_2` de manière inconditionnelle.
- **Exécution Synchrone du Carillon (50 Hz IRQ)** : `update_secret_chime` doit s'exécuter dans `music_update` (raster IRQ) pour ne jamais geler lors des transitions d'écran (`STATE_TRANSITION`) ou des menus inventaire/grottes.
- **Boucle des Celliers** : Toujours exécuter `jsr items_update` dans l'état `.in_cellar` (`src/main.asm`) pour permettre l'extinction normale des minuteurs d'objets.
- **Drops Mineurs** : Les ramassages standards en donjon (petites clés, carte, boussole) doivent jouer un effet sonore court (`sound_rupee` sur Voix 3) sans interrompre la musique de fond BGM.
- **Sérialisation des Sons en Conflit (File d'Attente)** : Ne jamais réquisitionner simultanément la Voix 2 (carillon) et la Voix 3 (SFX objet/clé). Si deux sons sont appelés dans la même frame ou pendant la lecture d'un autre son, les ordonnancer séquentiellement via les drapeaux d'attente (`secret_chime_pending` / `sfx_rupee_pending`) et toujours restaurer le canal audio emprunté avant de lancer le son suivant.
- **Symétrie Dual SID & Traçabilité SFX (`sfx_timer`)** : Ne jamais omettre l'armement de `sfx_timer` et `sfx_voice` dans les routines d'effets sonores en mode Dual SID. Les effets sonores doivent être émis de façon symétrique sur `SID1_V3` et `SID2_V3` sous protection continue de `sfx_timer` pour éviter tout écrasement immédiat par la basse BGM.
- **Maintien des Canaux Stéréo sur Pas de Maintien (`HOLD $FE`)** : Sur un pas de maintien musical (`$FE`), programmer systématiquement le maintien Gate ON sur les deux puces SID (`SID1` et `SID2`) pour les voix d'harmonie (Voix 2) et de basse (Voix 3), évitant l'extinction asymétrique de la seconde puce SID.
- **Restauration Intégrale des Registres Stéréo SID2** : Lors de la restauration d'une voix après un SFX ou un carillon (`restore_music_voice_2`, `restore_music_voice_3`), reprogrammer intégralement la largeur d'impulsion (PW) et l'enveloppe ADSR sur `SID2` tout comme sur `SID1`.

## 7. Plafond Mémoire des Sprites Link ($1000)
- `src/sprites.asm` (généré depuis `assets/link.txt`) commence sous `$0800` et s'achève exactement à `$1000`, adresse à laquelle commence la ROM des caractères (chargen) pour le VIC-II en banque 0.
- Ne jamais ajouter de sprites bruts dans `assets/link.txt` sans réallouer un slot existant ou déporter les graphismes dans les banques de streaming cartouche sous peine de corrompre la mémoire vidéo.
