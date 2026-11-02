# Registre des Bugs Résolus et Règles Anti-Régression - Zelda C64

Ce document consigne l'ensemble des anomalies identifiées, leurs causes racines techniques détaillées sur Commodore 64 / NES, les fichiers modifiés et les règles strictes à respecter lors des prochains développements pour éviter toute régression.

---

## 1. Explosion de Bombe : Disparition des Sprites / Jeu Figé
* **Fichiers concernés** : [src/enemies.asm](file:///home/vedix/Documents/C64/zelda/src/enemies.asm), [src/items.asm](file:///home/vedix/Documents/C64/zelda/src/items.asm)
* **Symptôme** : Lorsque la bombe explosait, les sprites à l'écran disparaissaient subitement comme si le jeu était gelé jusqu'à la fin de la déflagration.
* **Cause racine** : Dans la routine d'interruption raster haute [`irq_top`](file:///home/vedix/Documents/C64/zelda/src/enemies.asm#L3060), une condition testait si `item_active == ITEM_BOMB && item_state != 0` et court-circuitait l'appel à `apply_top_sprites`, empêchant le multiplexeur de sprites d'afficher les ennemis et les objets.
* **Correction** : Suppression du saut d'inhibition dans `irq_top`. L'explosion de la bombe met simplement à jour l'animation du sprite bombe sans masquer le multiplexeur VIC-II.
* **Règle anti-régression** : Ne jamais inhiber globalement l'affichage des sprites dans `irq_top` ou `irq_bottom` lors d'un effet d'objet local.

---

## 2. Transition Overworld : Clignotement Blanc / Noir
* **Fichiers concernés** : [src/transition.asm](file:///home/vedix/Documents/C64/zelda/src/transition.asm), [src/main.asm](file:///home/vedix/Documents/C64/zelda/src/main.asm)
* **Symptôme** : Lors du changement de salle dans l'Overworld, un flash blanc ou noir parasite était visible pendant le défilement.
* **Cause racine** : 
  1. Les registres du VIC-II étaient réactivés (unblanking) avant que la Color RAM (`$D800`) et la Screen RAM (`$0400`) ne soient entièrement écrites pour la nouvelle salle.
  2. La routine de streaming cartouche désactivait les interruptions (`SEI`) pendant une copie continue trop longue (13 pages d'un bloc), désynchronisant les interruptions raster VBlank.
* **Correction** : 
  1. Découpage de [`cart_stream_copy`](file:///home/vedix/Documents/C64/zelda/src/main.asm#L300) page par page (256 octets) avec réactivation des interruptions (`CLI`) entre chaque page.
  2. Maintien strict du masquage de l'écran (VIC blanking) jusqu'à la fin complète de la copie mémoire et restauration synchrone avec le VBlank.
* **Règle anti-régression** : Tout streaming cartouche ou chargement de chunk doit relâcher les interruptions régulièrement pour ne pas bloquer le son SID et le raster VIC-II.

---

## 3. Décalage de Collision des Tuiles (Traversée de Décors)
* **Fichiers concernés** : [src/tilemap.asm](file:///home/vedix/Documents/C64/zelda/src/tilemap.asm), [src/player.asm](file:///home/vedix/Documents/C64/zelda/src/player.asm)
* **Symptôme** : Link pouvait traverser des arbres ou des rochers infranchissables, ou se retrouvait bloqué sur des dalles de sol visiblement libres.
* **Cause racine** : Lors du chargement et du décompactage d'une nouvelle salle, le tampon actif `room_buf` et `target_room_buf` n'étaient pas synchronisés avec les offsets de rangée (`tile_row_offset`), créant un décalage d'index entre ce qui était dessiné à l'écran et ce qui était testé par `get_tile_at_point`.
* **Correction** : Réalignement strict de la décompression dans `room_buf` dès la fin du scrolling et validation des calculs d'adresses `ty * 20 + tx`.
* **Règle anti-régression** : Toute modification des tampons d'écran doit préserver l'invariance `room_buf[ty * 20 + tx]` pour garantir la cohérence des collisions.

---

## 4. Donjons : Ennemis Spawnant dans des Blocs / Statues Solides
* **Fichiers concernés** : [tools/build_dungeons.py](file:///home/vedix/Documents/C64/zelda/tools/build_dungeons.py), [src/enemies.asm](file:///home/vedix/Documents/C64/zelda/src/enemies.asm), [src/dung1.asm](file:///home/vedix/Documents/C64/zelda/src/dung1.asm) à [src/dung9.asm](file:///home/vedix/Documents/C64/zelda/src/dung9.asm)
* **Symptôme** : Dans les donjons, des monstres apparaissaient piégés à l'intérieur de blocs diamants (`5`), de statues dragons (`6`) ou de murs.
* **Cause racine** : 
  1. Dans `tools/build_dungeons.py`, des coordonnées génériques de spawn étaient affectées à toutes les salles sans vérifier si la tuile ciblée dans `assets/underworld.txt` était solide (95+ conflits détectés sur les 9 niveaux).
  2. Dans `src/enemies.asm` (`init_slot_from_table`), les coordonnées étaient assignées au sprite sans test de collision préalable.
* **Correction** : 
  1. Ajout de `find_nearest_free_tile` et `sanitize_enemy_spawns` dans `tools/build_dungeons.py` qui repositionnent automatiquement en spirale tout ennemi en conflit vers la dalle de sol libre (`tile == 0`) la plus proche (0 conflit sur les 9 donjons).
  2. Ajout dans `init_slot_from_table` d'un garde-fou runtime appelant `check_point_solid` et décalant de 16 pixels si une collision solide survient.
* **Règle anti-régression** : Ne jamais modifier les tables d'apparition `map_enemies` sans exécuter `python3 tools/build_dungeons.py` qui valide automatiquement les tuiles libres.

---

## 5. Donjons : Blocs Secrets Poussables N'importe Où
* **Fichiers concernés** : [src/dungeon.asm](file:///home/vedix/Documents/C64/zelda/src/dungeon.asm)
* **Symptôme** : N'importe quel bloc d'une salle à volets fermés pouvait être poussé vers le haut, ouvrant les volets sans avoir à tuer les monstres. Des blocs pouvaient aussi être poussés avant d'avoir éliminé les ennemis.
* **Cause racine** : La routine `check_link_pushing_block` basculait sur `.clp_generic` lorsque la salle n'était pas trouvée dans `push_tbl`, autorisant la poussée vers le haut de toute tuile bloc si `dungeon_shutter_closed != 0`.
* **Correction** : 
  1. Suppression totale de `.clp_generic` et `.dpb_generic`.
  2. Condition obligatoire : la poussée est **strictement interdite** tant que tous les ennemis de la salle ne sont pas éliminés (`dungeon_room_state & DUNG_ROOM_CLEARED == 0`) ou si le secret a déjà été révélé (`DUNG_SECRET_REVEALED != 0`).
  3. Seules les salles authentiques de la Quête 1 référencées dans `push_tbl` (ex: salle `$22` pour l'escalier de l'arc, salle `$42` pour l'ermite) autorisent le déplacement.
  4. Dans la salle `$22`, la poussée fait apparaître immédiatement l'escalier à la tuile 90 (`TILE_DUNG_STAIRS`).
* **Règle anti-régression** : Un bloc secret ne doit JAMAIS pouvoir bouger si la salle n'est pas répertoriée dans `push_tbl` ou si `DUNG_ROOM_CLEARED` n'est pas actif.

---

## 6. Audio : Voix Manquante (Canal Muet) Après Fanfare / Ramassage d'Objet
* **Fichiers concernés** : [src/sound.asm](file:///home/vedix/Documents/C64/zelda/src/sound.asm), [src/main.asm](file:///home/vedix/Documents/C64/zelda/src/main.asm), [src/dungeon.asm](file:///home/vedix/Documents/C64/zelda/src/dungeon.asm)
* **Symptôme** : Après avoir ramassé un objet ou une clé dans un donjon, la musique de fond reprenait avec l'un de ses canaux muet (le contre-chant de la Voix 2 manquait).
* **Cause racine** : 
  1. **Matériel SID (MOS 6581/8580)** : L'enveloppe ADSR d'une voix ne se déclenche que lors d'une transition montante `Gate 0 -> 1`. `.init_dungeon_inst` écrivait directement `Gate=1` sans repasser par `Gate=0`. Les voix restaient donc bloquées dans leur état précédent.
  2. Les drapeaux `secret_chime_active`, `sfx_voice` et `sfx_timer` n'étaient pas remis à zéro lors de la reprise musicale, provoquant le saut permanent de la Voix 2 (`jmp .skip_v2`).
  3. Dans l'état cellier (`STATE_CELLAR`), `items_update` n'était pas exécuté dans `src/main.asm`, laissant `secret_chime_active = 1` indéfiniment si Link descendait pendant le carillon secret.
  4. Les drops mineurs de donjon (clés, boussole, carte) déclenchaient à tort `sound_item_fanfare`, coupant et relançant tout le moteur audio.
* **Correction** : 
  1. Écriture obligatoire de `Gate=0` sur les 3 voix avant d'écrire `Gate=1` dans `.init_dungeon_inst` et `.init_overworld_inst`.
  2. Réinitialisation systématique de `secret_chime_active = 0`, `sfx_voice = 0` et `sfx_timer = 0` dans `music_play`, `sound_item_fanfare` et `.step_item_fanfare`.
  3. Réinitialisation de `sfx_voice = 0` à la fin d'un effet sonore dans `music_update`.
  4. Ajout de `jsr items_update` dans `.in_cellar` ([src/main.asm](file:///home/vedix/Documents/C64/zelda/src/main.asm)).
  5. Remplacement de `sound_item_fanfare` par `sound_rupee` (effet court sur Voix 3 sans couper le BGM) pour les clés, cartes et boussoles dans [src/dungeon.asm](file:///home/vedix/Documents/C64/zelda/src/dungeon.asm), conformément à la NES.
* **Règle anti-régression** : 
  - Toujours forcer `Gate=0` avant `Gate=1` lors de la réinitialisation des instruments SID.
  - Toujours s'assurer que `secret_chime_active` et `sfx_voice` sont remis à 0 avant de relancer un morceau BGM.
  - Ne jamais utiliser `sound_item_fanfare` pour des ramassages mineurs continus.

---

## 7. Donjon 4 (Steer) Salle $41 : Disparition Totale des Monstres (Zols) et Sprites Hauts
* **Fichiers concernés** : [src/enemies.asm](file:///home/vedix/Documents/C64/zelda/src/enemies.asm)
* **Symptôme** : Dans la salle `$41` du Donjon 4 (Steer), les 3 Zols et tous les sprites hauts disparaissaient subitement dès l'entrée dans la pièce.
* **Cause racine** : Une condition résiduelle dans [`irq_top`](file:///home/vedix/Documents/C64/zelda/src/enemies.asm#L3060) testait `current_world_type == WORLD_DUNGEON` et `current_room_idx == $41`, et sautait arbitrairement vers `.skip_top`, court-circuitant l'exécution de `apply_top_sprites` et `apply_proj_sprite7`.
* **Correction** : Suppression complète du test d'exclusion conditionnelle dans `irq_top`. Le moteur de tri virtuel gère déjà l'absence de sprites (`sort_cnt == 0`) sans devoir court-circuiter le raster.
* **Règle anti-régression** : Respect strict de la **Règle 1** d'[AGENTS.md](file:///home/vedix/Documents/C64/zelda/AGENTS.md) : ne jamais inhiber le raster ou `apply_top_sprites` en fonction d'un numéro de salle.

---

## 8. Explosion de Bombe : Déformation Hardware Scaling et Rendu Non Conforme NES
* **Fichiers concernés** : [assets/link.txt](file:///home/vedix/Documents/C64/zelda/assets/link.txt), [src/sprites.asm](file:///home/vedix/Documents/C64/zelda/src/sprites.asm), [src/items.asm](file:///home/vedix/Documents/C64/zelda/src/items.asm)
* **Symptôme** : L'explosion de la bombe apparaissait sous la forme d'un pavé rectangulaire géant de 48x42 pixels, flou et tronqué vers le bas, sans animation ni ressemblance avec le motif à lobes et le bouillonnement tourbillonnant de la version NES.
* **Cause racine** :
  1. `sprite_link_proj_explosion` dans `assets/link.txt` n'était qu'un ovale tronqué de 11 lignes de haut avec 10 lignes inférieures totalement vides.
  2. Le code activait `VIC_SPRITE_EXP_X` et `VIC_SPRITE_EXP_Y` sur le Sprite 2, quadruplant la taille de pixels multicolores déjà étirés et provoquant une bouillie géante.
  3. L'explosion n'avait aucune animation multi-phase (déflagration -> pic -> dispersion).
  4. *Contrainte mémoire critique C64* : `src/sprites.asm` touche exactement la limite `$1000` (ROM chargen), interdisant tout ajout de nouveaux sprites dans `assets/link.txt`.
* **Correction** :
  1. Redessin complet du slot existant à `$0FC0` (`sprite_link_proj_explosion`) sur les 21 lignes avec le motif authentique du nuage de détonation à lobes de *The Legend of Zelda* (NES), préservant la taille exacte de 64 octets et l'adresse maximale `$1000`.
  2. Suppression définitive de `VIC_SPRITE_EXP_X` et `VIC_SPRITE_EXP_Y` pour le Sprite 2.
  3. Implémentation d'une animation dynamique en 3 phases fidèles à la NES :
     - **Phase 1 (Frames 24..17)** : Déflagration centrale vive avec flash blanc intense initial.
     - **Phase 2 (Frames 16..7)** : Pleine déflagration bouillonnante avec micro-vibration `(±2 px)` imitant les 4 nuages tourbillonnants NES et cycle rapide `exp_colors`.
     - **Phase 3 (Frames 6..1)** : Anneau de particules de fumée en dissipation utilisant le sprite commun déjà en mémoire `$2800` (`SPR_COMMON_DEATH_1`).
* **Règle anti-régression** : 
  - Ne jamais utiliser le hardware scaling `EXP_X`/`EXP_Y` pour masquer un sprite incomplet ou de mauvaise taille.
  - Ne jamais dépasser `$1000` pour la taille globale de `src/sprites.asm`.

---

## 9. Audio Donjon : Conflit Voix 2 / Voix 3 lors du Ramassage d'Objets Mineurs (Clé, Boussole, Carte)
* **Fichiers concernés** : [src/sound.asm](file:///home/vedix/Documents/C64/zelda/src/sound.asm), [src/items.asm](file:///home/vedix/Documents/C64/zelda/src/items.asm)
* **Symptôme** : Dans les donjons, lorsqu'une clé ou un objet mineur était ramassé au moment de l'ouverture d'un secret, la musique de fond reprenait sans l'arpège de la Voix 2 (contre-chant définitivement muet).
* **Cause racine** : 
  1. Partage erroné de la variable d'état `sfx_voice` et `sfx_timer` entre la Voix 2 (carillon secret) et la Voix 3 (bruitage de clé/rubis `sound_rupee`).
  2. Dans `.stop_chime` ([src/items.asm](file:///home/vedix/Documents/C64/zelda/src/items.asm)), un test résiduel vérifiait `lda sfx_timer; bne .chime_done`. Si Link touchait la clé alors que le carillon s'achevait, `sfx_timer > 0` provoquait l'abandon de la restauration de la Voix 2, la laissant en `Gate OFF` (`%00010000`).
* **Correction** : 
  1. Découplage strict des deux canaux matériels : création de deux routines indépendantes `restore_music_voice_2` et `restore_music_voice_3` dans [src/sound.asm](file:///home/vedix/Documents/C64/zelda/src/sound.asm).
  2. Dans `.stop_chime`, appel direct et inconditionnel de `restore_music_voice_2` sans tester `sfx_timer`.
  3. Restauration systématique de l'ADSR ($09, $C0) et de la forme d'onde Pulse 50% ($0800) en Voix 2, et de l'ADSR ($09, $E2) avec onde Triangle en Voix 3.
* **Règle anti-régression** : 
  - Ne jamais faire dépendre la restauration des registres SID de la Voix 2 du minuteur SFX de la Voix 3.

---

## 10. Multiplexeur Donjon : Disparition des Ennemis en Zone Basse de l'Arène (Raster 230)
* **Fichiers concernés** : [src/enemies.asm](file:///home/vedix/Documents/C64/zelda/src/enemies.asm)
* **Symptôme** : Dans les salles de donjon, des monstres disparaissaient subitement ou se retrouvaient coupés en deux lorsqu'ils descendaient en bas de l'écran (Y $\ge 210$), puis réapparaissaient plus haut.
* **Cause racine** : 
  1. Lorsque la salle compte $\le 4$ ennemis actifs (le cas dans 100% des salles des donjons 2 à 9 et la majorité du donjon 1), `calc_split_line` affectait une ligne arbitraire `multiplex_split_line = 230`.
  2. À raster 230, l'interruption médiane `irq_mid` s'exécutait et appelait `apply_bottom_sprites`. Les slots 4..7 étant inactifs, `draw_virtual_to_spr3..6` désactivait immédiatement les sprites matériels 3, 4, 5 et 6 dans `VIC_SPRITE_EN`.
  3. Tout ennemi situé sous raster 210 (rangées 8 et 9) avait sa moitié basse effacée ou disparaissait entièrement avant le VBlank.
* **Correction** : 
  1. Mode Passe Unique Dynamique : dans `calc_split_line`, si `sort_eff_y[sort_idx[4]] == $FF`, `multiplex_needed` est positionné à 0.
  2. Dans `irq_top`, si `multiplex_needed == 0`, l'IRQ saute directement à raster 250 (`irq_bottom`), sans programmer `irq_mid`. Les sprites 3..6 restent ainsi actifs et affichés en continu de raster 82 à 250.
  3. Pour les rares salles à $> 4$ ennemis : gestion du chevauchement par entrelacement 50 Hz avec bascule de trame `multiplex_frame_toggle` (cyclage matériel propre).
* **Règle anti-régression** : 
  - Ne jamais déclencher d'interruption médiane de multiplexage si le nombre d'ennemis actifs ne dépasse pas le nombre de sprites matériels alloués ($\le 4$).

---

## 11. Overworld : Spawns d'Ennemis dans les Blocs Solides et Murs
* **Fichiers concernés** : [src/map_overworld_enemies.inc](file:///home/vedix/Documents/C64/zelda/src/map_overworld_enemies.inc), [src/enemies.asm](file:///home/vedix/Documents/C64/zelda/src/enemies.asm), [tools/relocate_overworld_spawns.py](file:///home/vedix/Documents/C64/zelda/tools/relocate_overworld_spawns.py), [tools/tilegen.py](file:///home/vedix/Documents/C64/zelda/tools/tilegen.py)
* **Symptôme** : Dans l'Overworld, des monstres apparaissaient piégés à l'intérieur de rochers, de montagnes ou d'arbres, ou des monstres terrestres apparaissaient dans l'eau.
* **Cause racine** : 
  1. 220 apparitions d'ennemis dans `src/map_overworld_enemies.inc` étaient situées sur des tuiles solides (rochers tuile 5, arbres tuile 3, tombes tuile 8).
  2. Le garde-fou runtime de collision dans `init_slot_from_table` ([src/enemies.asm](file:///home/vedix/Documents/C64/zelda/src/enemies.asm#L588)) court-circuitait le test si `current_world_type == WORLD_OVERWORLD` (`beq .spawn_early_rts`), laissant les monstres apparaître dans les blocs sans correction.
* **Correction** : 
  1. Création de [tools/relocate_overworld_spawns.py](file:///home/vedix/Documents/C64/zelda/tools/relocate_overworld_spawns.py) : recherche en spirale et relocalisation automatique de tous les ennemis terrestres sur des dalles libres praticables (`solid == False`, `tile != water`) dans les limites de l'écran ($1 \le tx \le 18$, $1 \le ty \le 8$).
  2. Remplacement des Zoras dans les salles sans eau par `TYPE_NONE` (0 conflit sur les 128 salles).
  3. Régénération de [src/map_overworld_enemies.inc](file:///home/vedix/Documents/C64/zelda/src/map_overworld_enemies.inc) et des 4 chunks cartouche `OW0..OW3`.
  4. Réactivation du garde-fou runtime `check_point_solid` pour l'Overworld dans [src/enemies.asm](file:///home/vedix/Documents/C64/zelda/src/enemies.asm), avec exception uniquement pour Keese, Peahat et Zora.
* **Règle anti-régression** : 
  - Toujours valider les tables d'apparition de l'Overworld avec `test_3_overworld_spawns` (0 collision tolérée).
  - Conserver le garde-fou runtime `check_point_solid` actif quel que soit le monde en jeu.

---

## 12. Bombe : Explosion Authentique NES en Rosace à 7 Nuages
* **Fichiers concernés** : [assets/link.txt](file:///home/vedix/Documents/C64/zelda/assets/link.txt), [src/sprites.asm](file:///home/vedix/Documents/C64/zelda/src/sprites.asm), [src/items.asm](file:///home/vedix/Documents/C64/zelda/src/items.asm)
* **Symptôme** : L'explosion de la bombe ne ressemblait pas à la version NES originale où 7 nuages de fumée distincts forment une rosace complète lors de la déflagration.
* **Cause racine** : Le sprite `sprite_link_proj_explosion` ne représentait qu'un seul nuage unique et compact au centre, sans la structure à 7 lobes géométriques de la NES (Banque 7, tables `$F9D9..$F9E2` `BombCloudOffsets`).
* **Correction** : 
  1. Refonte graphique complète de `proj_explosion` dans [assets/link.txt](file:///home/vedix/Documents/C64/zelda/assets/link.txt) : rosace géométrique à 7 nuages distincts (1 noyau central + 6 satellites disposés en hexagone avec leurs coeurs incandescents et ombrages).
  2. Conservation du format 1:1 natif (24x21 pixels multicolores) sans déformation hardware scaling floue, garantissant un rendu net et fidèle.
  3. Animation dynamique en 3 phases dans [src/items.asm](file:///home/vedix/Documents/C64/zelda/src/items.asm) :
     - Flash blanc/jaune étincelant sur les 7 nuages.
     - Déflagration avec cycle de couleurs NES et vibration subtile simulant le tourbillonnement des 6 satellites.
     - Dissipation centrifuge via `SPR_COMMON_DEATH_1`.
  4. Respect strict de la contrainte mémoire : `src/sprites.asm` reste exactement à `$0FC0..$1000` (strictement $\le \$1000$).
* **Règle anti-régression** : 
  - Ne jamais dépasser `$1000` pour la fin de `src/sprites.asm`.
  - Préserver les 7 lobes de la rosace lors de toute retouche graphique de l'explosion.

---

## 13. Moteur Audio SID : Perte de Voix, Monophonie et Notes Suspendues Donjon/Overworld
* **Fichiers concernés** : [src/sound.asm](file:///home/vedix/Documents/C64/zelda/src/sound.asm), [src/items.asm](file:///home/vedix/Documents/C64/zelda/src/items.asm), [tools/test_4_bugs_stabilisation.py](file:///home/vedix/Documents/C64/zelda/tools/test_4_bugs_stabilisation.py)
* **Symptôme** : Un événement sonore en donjon (déverrouillage d'une porte, ramassage d'une clé/rubis, volets de salle ou défaite de monstres) provoquait la coupure des voix d'harmonie/basse (Voix 2 et/ou Voix 3) ou la suspension d'une note drone, ne laissant qu'une seule note/voix fonctionnelle, persistant même après le retour dans l'Overworld.
* **Cause racine** : 
  1. *Timing Gate OFF $\rightarrow$ Gate ON (Horloge interne SID)* : Les instructions consécutives `sta SID_CTRL` (Gate=0) puis immédiatement `sta SID_CTRL` (Gate=1) ne laissaient le signal Gate bas que pendant 4 à 6 cycles CPU. Le diviseur d'horloge du générateur d'enveloppe ADSR (MOS 6581/8580) n'échantillonne que toutes les 16 périodes. Dans 62.5% des cas, la coupure Gate=0 était ratée ; l'enveloppe tombée à Release=0 ne réarmait jamais son Attack et restait muette de façon permanente.
  2. *Carillon secret (`update_secret_chime`) dans `items_update` au lieu de l'interruption raster 50 Hz* : Lors d'une transition d'écran (porte franchie) ou d'un affichage de sous-écran, la boucle principale ne tournait plus dans `STATE_PLAYING`, figeant `update_secret_chime` en plein milieu des 8 notes du carillon tandis que `music_update` continuait en IRQ avec `secret_chime_active == 1`.
  3. *Désynchronisation de `cur_music_v2_note` et déclenchement aveugle sur HOLD ($FE)* : Pendant l'activité du carillon, `cur_music_v2_note` n'était pas mis à jour. Sur un pas `$FE`, `v2_play` forçait Gate ON sans vérifier `cur_music_v2_note` et sans réécrire la fréquence, réactivant la voix sur la dernière fréquence aiguë laissée par le carillon ($1DA0 / 1390 Hz).
  4. *Initialisation précipitée de `music_play` avec Gate ON* : Dans `.init_overworld_inst` et `.init_dungeon_inst`, les 3 voix étaient activées avec Gate ON avant même que le premier pas musical (step 0) n'ait programmé les fréquences, produisant des bruits parasites ou des notes figées au redémarrage d'un thème.
* **Correction** : 
  1. Insertion d'une pause matérielle calibrée ($\ge 16$ cycles CPU, 8 `nop`) entre chaque mise à 0 de Gate et son activation montante, garantissant mathématiquement l'échantillonnage par le diviseur SID sur chaque réarmement ADSR.
  2. Migration complète de `update_secret_chime`, `sound_secret_chime` et des tables de fréquences dans [src/sound.asm](file:///home/vedix/Documents/C64/zelda/src/sound.asm), exécuté de manière synchrone et inconditionnelle à 50 Hz dans l'interruption `music_update`.
  3. Mise à jour continue de `cur_music_v2_note` sur chaque pas de partition même lorsque le carillon est actif, et ajout d'un garde-fou dans `.v2_play` n'activant Gate sur un pas `$FE` que si `cur_music_v2_note != 0`.
  4. Réinitialisation des registres de contrôle avec **Gate OFF** dans `music_play`, l'activation Gate ON n'intervenant qu'à la programmation des fréquences du pas 0 dans `apply_music_step`.
* **Règle anti-régression** : 
  - Toujours observer un délai minimal de 16 cycles d'horloge (ou un tick complet de trame) entre la coupure `Gate=0` et la montée `Gate=1` sur un canal SID.
  - Tout effet sonore ou carillon multipasse doit progresser dans l'interruption raster (`music_update`) pour rester synchrone avec le matériel audio, indépendamment de l'état de jeu (`game_state`).
  - Ne jamais forcer Gate ON sur un pas de maintien musical (`$FE`) si la note de la voix courante est nulle (`cur_music_vX_note == 0`).

### Bug 14 : Conflit de Canaux Audio Simultanés (Ramassage Clé/Objet & Découverte Secret/Ouverture de Porte)
* **Symptôme** : Dans le donjon, lorsqu'un joueur ramasse une clé tout en touchant une porte verrouillée (ou dans l'Overworld lors d'un ramassage simultané avec un secret), la musique de fond se dégrade et s'effondre en une note unique ("une seule note qui semble fonctionner"), persistant après l'ouverture ou lors du passage en Overworld.
* **Cause racine** :
  1. `dungeon_collect_drop` déclenche `sound_rupee` (Voix 3, durée 8 frames).
  2. Dans la même frame de jeu, `dungeon_check_key_door` ouvre la porte et déclenche `sound_secret_chime` (Voix 2, durée 56 frames).
  3. Les deux canaux musicaux (Voix 2 harmonie et Voix 3 basse) sont réquisitionnés simultanément, ne laissant que la Voix 1 en monophonie.
  4. À la frame 8, la fin du son de clé tentait de restaurer la Voix 3 alors que la partition du Donjon contenait un silence ($00), laissant la Voix 3 coupée tandis que la Voix 2 jouait encore son carillon pour 48 frames, provoquant un vide sonore prolongé et une cacophonie lors des transitions de salle.
* **Correctif appliqué** :
  1. Implémentation d'une file d'attente audio séquentielle bidirectionnelle dans [src/sound.asm](file:///home/vedix/Documents/C64/zelda/src/sound.asm) :
     - Si un son court de ramassage (Voix 3) est en cours, `sound_secret_chime` est mis en attente (`secret_chime_pending = 1`). La Voix 2 continue de jouer le BGM sans perturbation.
     - Dès que le son de ramassage se termine (frame 8), la Voix 3 est restaurée au BGM, et le carillon secret est automatiquement déclenché sur Voix 2.
     - Inversement, si un son de ramassage est appelé pendant le carillon, il est mis en attente (`sfx_rupee_pending = 1`) et déclenché dès la fin du carillon après restauration de la Voix 2.
  2. Réinitialisation inconditionnelle des drapeaux d'attente (`secret_chime_pending = 0`, `sfx_rupee_pending = 0`) dans `music_play`, `music_stop`, et `sound_init` pour éviter tout son parasite en changement de monde.
  3. Validation automatisée complète via [tools/test_audio_queue_conflict.py](file:///home/vedix/Documents/C64/zelda/tools/test_audio_queue_conflict.py) sous VICE.
* **Règle anti-régression** :
  - Ne jamais autoriser deux effets sonores/fanfares majeurs à monopoliser simultanément les Voix 2 et 3 : toujours ordonnancer et sérialiser les sons via la file d'attente (`secret_chime_pending` / `sfx_rupee_pending`).
  - Restaurer systématiquement le canal audio emprunté avant de lancer le son suivant dans la file.

---

## 15. Configuration Matérielle SID au Démarrage & Relocalisation Stéréo Dynamique
* **Fichiers concernés** : [src/intro_main.asm](file:///home/vedix/Documents/C64/zelda/src/intro_main.asm), [src/intro_charset.asm](file:///home/vedix/Documents/C64/zelda/src/intro_charset.asm), [src/main.asm](file:///home/vedix/Documents/C64/zelda/src/main.asm), [src/sound.asm](file:///home/vedix/Documents/C64/zelda/src/sound.asm)
* **Contexte & Besoin** :
  - Permettre aux utilisateurs sur matériel réel (C64 avec MixSID, Ultimate 64, Turbo Chameleon, etc.) ou émulateur (VICE) de choisir la configuration de leur système audio au boot froid de la cartouche : 1 SID Mono standard (compatible 100% C64 d'origine) ou 2 SID Stéréo à l'adresse de leur choix ($D420, $D500 ou $DF00).
  - Présenter un menu visuel prestigieux avec un logo Triforce géant composé de sprites VIC-II matériels agrandis en couleur or (`COL_YELLOW = 7`) au sommet de l'écran, sans corrompre le chargen ni la RAM résidente.
* **Architecture technique implémentée** :
  1. *Menu de Sélection au Boot Froid* :
     - Affichage avant l'intro cascade, proposant 4 options : Mono (1 SID standard), Stéréo $D420 (VICE / StereoSID), Stéréo $D500 (MixSID / SIDFx), Stéréo $DF00 (I/O 2 / Ultimate 64).
     - Logo Triforce composé de 3 sprites matériels expansés (96x84 pixels) logés sous `$1000` (pointeur `$28`, `$0A00`), en conformité stricte avec la règle 7 de `AGENTS.md`.
     - Navigation par Joystick (haut/bas/feu), Clavier (touches 1..4, Espace, Return) et temporisation de sécurité (auto-démarrage mono par défaut après ~10s d'inactivité).
     - Bip sonore de confirmation sur Voix 1 respectant le palier $\ge 16$ cycles Gate 0 -> 1.
  2. *Passage Cartouche $\rightarrow$ Jeu Résident ($0340 buffer cassette)* :
     - Transmission des variables de configuration `selected_dual_sid` et `selected_sid2_addr_idx` au déballeur cartouche en `$0340`, qui les injecte en `$0811` et `$0812` dans le segment de tête de `zelda.prg`.
  3. *Relocalisation Dynamique Zéro Overhead en RAM* :
     - Appel de `sound_set_dual_sid_config` dès l'initialisation de `zelda.prg` : parcours des 79 instructions ciblant `$D420..$D438` dans le code audio résident ($89BC..$93A8) pour patcher in-situ l'octet d'adresse haute ($D4, $D5 ou $DF).
     - En jeu à 50 Hz, aucune indirection ni saut conditionnel : l'exécution reste en instructions 4 cycles natives directes, garantissant 0 microseconde de perte de framerate.
* **Règle anti-régression** :
  - Toujours préserver l'accès natif direct aux registres SID en jeu (relocalisation au boot uniquement).
  - Maintenir les sprites du menu intro sous le plafond strict de `$1000` en banque 0 VIC-II.

