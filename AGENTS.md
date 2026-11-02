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
- **Réarmement ADSR** : L'enveloppe SID ne se déclenche que sur une transition montante `Gate 0 -> 1`. Toujours forcer `Gate=0` sur les 3 voix avant de programmer `Gate=1` lors de l'initialisation ou de la reprise d'un thème (`.init_dungeon_inst`, `.init_overworld_inst`).
- **Gestion des Drapeaux SFX & Découplage des Voix** : Les canaux Voix 2 (carillon secret / contre-chant) et Voix 3 (SFX / basse) sont strictement découplés (`restore_music_voice_2` et `restore_music_voice_3`). `.stop_chime` doit appeler `restore_music_voice_2` de manière inconditionnelle sans jamais être bloqué par `sfx_timer`.
- **Boucle des Celliers** : Toujours exécuter `jsr items_update` dans l'état `.in_cellar` (`src/main.asm`) pour permettre l'extinction normale des minuteurs sonores.
- **Drops Mineurs** : Les ramassages standards en donjon (petites clés, carte, boussole) doivent jouer un effet sonore court (`sound_rupee` sur Voix 3) sans interrompre la musique de fond BGM.

## 7. Plafond Mémoire des Sprites Link ($1000)
- `src/sprites.asm` (généré depuis `assets/link.txt`) commence sous `$0800` et s'achève exactement à `$1000`, adresse à laquelle commence la ROM des caractères (chargen) pour le VIC-II en banque 0.
- Ne jamais ajouter de sprites bruts dans `assets/link.txt` sans réallouer un slot existant ou déporter les graphismes dans les banques de streaming cartouche sous peine de corrompre la mémoire vidéo.
