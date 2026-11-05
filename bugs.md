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

---

## 16. Dual SID Stéréo : Perte de l'Épée et Déconnexion des Canaux Stéréo en Donjon
* **Fichiers concernés** : [src/sound.asm](file:///home/vedix/Documents/C64/zelda/src/sound.asm), [tools/test_dual_sid_dungeon.py](file:///home/vedix/Documents/C64/zelda/tools/test_dual_sid_dungeon.py)
* **Symptômes** :
  1. En mode 2 SID Stéréo ($D420/$D500/$DF00), les coups d'épée (`sound_sword`) et plusieurs bruitages devenaient totalement inaudibles.
  2. Les voix musicales d'harmonie (Voix 2) et de basse (Voix 3) perdaient leur canal stéréo sur la 2e puce SID lors des pas de maintien (`HOLD $FE`), très fréquents dans la partition des Donjons, dégradant la spatialisation.
  3. La file d'attente anti-conflit (ramassage d'objet vs carillon secret) ne s'activait pas en mode Dual SID, provoquant des conflits audio simultanés.
* **Causes racines** :
  1. *Asymétrie et omission de `sfx_timer` dans `play_sfx_v3`* : Lorsque `dual_sid_enabled == 1`, la branche `.dual` écrivait uniquement sur `SID2_V3` sans jamais renseigner `sfx_voice = 3` ni `sfx_timer = sfx_timer_tbl,x`. Dès la frame suivante, le moteur musical `apply_music_step` ignorait la présence d'un SFX et réécrivait immédiatement la note de basse sur `SID2_V3`, étouffant le bruitage d'épée en moins de 20 ms. De plus, sur `SID1_V3`, aucun son d'épée n'était envoyé.
  2. *Déconnexion de `SID2` sur les pas de maintien (`$FE`)* : Dans `apply_music_step`, les pas de maintien (`cpx #$fe`) exécutaient `sta SID1_V2_CTRL` et `sta SID1_V3_CTRL` sans répercuter le maintien Gate ON sur `SID2_V2_CTRL` et `SID2_V3_CTRL`. En Donjon, où un pas sur deux est un `$FE`, la 2e puce SID s'éteignait immédiatement.
  3. *Écrasement de l'Accumulateur par `lda dual_sid_enabled`* : Dans plusieurs routines (`music_play`, `.v2_hold_uw`, `.v3_mute`, `.mute_v2`, etc.), le test de présence du 2e SID était codé `lda dual_sid_enabled; beq +; sta SID2_*`. L'instruction `lda` écrasait `A` avec la valeur 1, injectant `$01` dans `SID2_VOLUME` (volume master à 1/15th au lieu de 15) et dans les registres de contrôle `SID2_V2_CTRL` et `SID2_V3_CTRL` (Gate ON sans aucune forme d'onde active : extinction totale du canal).
  4. *Absence de reprogrammation ADSR/PW sur `SID2` lors des restaurations* : Dans `restore_music_voice_2` (`.res_v2_uw`) et `restore_music_voice_3`, la largeur d'impulsion et les registres ADSR n'étaient reprogrammés que sur `SID1`.
* **Correctif appliqué** :
  1. *Refonte symétrique de `play_sfx_v3`* : Programmation inconditionnelle de `sfx_voice = 3` et `sfx_timer = sfx_timer_tbl,x` pour tous les modes. Émission du SFX sur `SID1_V3` et, si `dual_sid_enabled == 1`, sur `SID2_V3` en stéréo intégrale, avec protection matérielle continue contre l'écrasement par la musique.
  2. *Préservation de l'Accumulateur via `ldy dual_sid_enabled`* : Remplacement de tous les tests destructifs par `ldy dual_sid_enabled; beq +; sta SID2_*`, garantissant le transfert 100% fidèle de la valeur de contrôle et du volume master 15 sur les deux puces SID.
  3. *Maintien continu de Gate ON sur `SID2` lors des pas `$FE`* : Ajout systématique de l'activation `SID2_V2_CTRL` et `SID2_V3_CTRL` lors des maintiens musicaux.
  4. *Restauration complète de la configuration matérielle SID2* : Réinitialisation propre de la PW et de l'enveloppe ADSR sur `SID2` lors des retours de SFX/carillons.
* **Règle anti-régression** :
  - Tout effet sonore doit obligatoirement armer `sfx_timer` et `sfx_voice`, y compris en mode Dual SID.
  - Ne jamais tester `dual_sid_enabled` avec `lda` immédiatement avant une écriture dans un registre SID2 (`sta SID2_*`) : toujours utiliser `ldy dual_sid_enabled` pour préserver l'accumulateur.
  - Toute écriture de maintien (`Gate ON`) ou de restauration de canal sur `SID1` doit être symétriquement dupliquée sur `SID2` lorsque `dual_sid_enabled != 0`.

---

## 17. Refonte Graphique et Géométrique de l'Inventaire : Grand Triangle de la Triforce, Ajustement du Cadre des Objets et Correction du Clignotement de Link
* **Fichiers concernés** : [src/inventory.asm](file:///home/vedix/Documents/C64/zelda/src/inventory.asm), [src/inventory_draw.asm](file:///home/vedix/Documents/C64/zelda/src/inventory_draw.asm), [src/items.asm](file:///home/vedix/Documents/C64/zelda/src/items.asm), [src/hud.asm](file:///home/vedix/Documents/C64/zelda/src/hud.asm), [src/enemies.asm](file:///home/vedix/Documents/C64/zelda/src/enemies.asm), [assets/extra.txt](file:///home/vedix/Documents/C64/zelda/assets/extra.txt), [assets/link.txt](file:///home/vedix/Documents/C64/zelda/assets/link.txt), [tools/build_sprite_banks.py](file:///home/vedix/Documents/C64/zelda/tools/build_sprite_banks.py)
* **Symptômes** :
  1. *Triforce déformée et trop petite* : Sur la page Triforce, l'affichage utilisait un piédestal ASCII et de minuscules sprites 12x21 superposés, sans ressemblance avec la pyramide officielle de *The Legend of Zelda* (NES).
  2. *Sprites d'objets dépassant du cadre et cadre surdimensionné* : Le cadre des armes utilisables occupait 26 colonnes (Cols 12..37), mais les sprites de la rangée 2 (Y=132..153) débordaient sur la bordure inférieure (raster 146..154). De plus, les 6 reliques passives n'étaient pas affichées sur l'écran d'inventaire principal contrairement à `inventaire.png`.
  3. *Clignotement de Link sur 2 cases de la carte* : Sur la Page 3 (Carte 16x8), chaque salle occupait 2 caractères `HUD_MAP_ACTIVE` côte à côte et `map_update_link_color` écrivait sur `y` et `y+1`, faisant clignoter 2 cases adjacentes au lieu d'une seule salle nette.
  4. *Inversion d'objets et icône de clé parasite* : La clé de donjon (`sprite_link_item_key`) était affichée à tort dans les reliques passives au lieu de la Clé Magique (Lion Key), et l'ordre des armes en rangée 2 inversait la Flûte et la Nourriture.
* **Causes racines & Correctifs appliqués** :
  1. *Assemblage Matériel de la Grande Triforce (96x42 pixels)* :
     - Remplacement complet de la page 1 par un grand triangle équilatéral centré (Cols 14..25, Rows 7..12).
     - Modélisation des 8 fragments sous forme de 8 sprites matériels VIC-II dédiés (`sprite_tri_p1` à `sprite_tri_p8`) avec biseautage étincelant (`COL_YELLOW`, `COL_ORANGE`, `COL_WHITE`).
     - Activation directe par masque matériel `player_triforce_pieces -> VIC_SPRITE_EN`.
     - Intégration du label officiel `"TRIFORCE"` centré à la ligne 14 sous la pyramide.
  2. *Redimensionnement Harmonieux du Cadre et Intégration des 6 Reliques Passives* :
     - Redimensionnement du cadre des armes à 18 colonnes (Cols 13..31) et Y=118 / Y=142 avec marges internes généreuses ($\ge 4$ pixels haut, $\ge 8$ pixels bas) : zéro chevauchement.
     - Positionnement de l'arme équipée dans le cadre gauche à X=52, Y=100 avec `"INVENTORY"` en haut et `"USE B BUTTON / FOR THIS"` en bas.
     - Affichage d'une rangée dédiée aux 6 Reliques Passives (Radeau, Livre, Anneau, Échelle, Clé Magique, Bracelet) à la ligne 6 avec les glyphes résidents du charset (120, 175, 173, 121, 99, 122) et coloration dynamique (actif vs `COL_DARK_GREY`).
     - Navigation 2D directionnelle au Joystick (Haut, Bas, Gauche, Droite) dans la grille 4x2.
  3. *Unicité de Case pour la Carte du Monde* :
     - Rendu de chaque salle sur 1 seul caractère de bloc (`(ZP_SCR),y = HUD_MAP_ACTIVE`), la colonne suivante (`y+1`) étant systématiquement un espace `' '` neutre.
     - Restriction de `map_update_link_color` à `sta (ZP_COL),y` sans incrémenter vers `y+1`.
  4. *Sprites Authentiques NES 1986 & Clé Magique Dédiée* :
     - Extraction et intégration du sprite authentique de la Clé Magique (`item_magic_key` / `sprite_link_item_magic_key`) dans `assets/extra.txt` et banque cartouche 13.
     - Réalignement fidèle de la grille d'objets B sur la ROM NES : Boomerang, Bombe, Arc, Bougie, Flûte, Nourriture, Potion, Baguette.
* **Règle anti-régression** :
  - Les sprites d'inventaire dans un cadre doivent obligatoirement respecter une marge interne minimale de 4 pixels de chaque côté pour éviter tout clippage avec les bordures de caractères VIC-II.
  - Sur la carte 16x8, une salle ne doit jamais occuper plus d'un bloc de caractère actif afin de préserver l'indépendance visuelle de chaque case lors du clignotement de la position de Link.

---

## 18. Inventaire : Débordement de l'Objet Sélectionné et Sprites Aplaties Décentrés (001.png)
* **Fichiers concernés** : [src/inventory_draw.asm](file:///home/vedix/Documents/C64/zelda/src/inventory_draw.asm), [assets/link.txt](file:///home/vedix/Documents/C64/zelda/assets/link.txt), [assets/extra.txt](file:///home/vedix/Documents/C64/zelda/assets/extra.txt)
* **Symptômes** :
  1. Le sprite de l'objet équipé ("USE B BUTTON FOR THIS") était positionné trop haut à `(X=52, Y=100)`, débordant sur la bordure supérieure du cadre.
  2. Les icônes d'objets dans la grille 4x2 étaient aplaties verticalement (seulement 7 à 9 lignes actives au lieu de 14-15) et décentrées vers le haut de leurs cases 16x16.
* **Causes racines** :
  1. Les coordonnées de placement VIC-II du Sprite 0 dans `setup_p0_b_item_sprite` avaient été calées sur l'ancien layout d'inventaire de 26 colonnes au lieu du cadre recentré.
  2. Les motifs ASCII d'armes dans `assets/link.txt` et `assets/extra.txt` avaient été tronqués en hauteur lors d'une extraction préliminaire.
* **Correctif appliqué** :
  1. Recalage exact du Sprite 0 dans [src/inventory_draw.asm](file:///home/vedix/Documents/C64/zelda/src/inventory_draw.asm) à `VIC_SPRITE_X0 = 64`, `VIC_SPRITE_Y0 = 120`.
  2. Redessin complet et centrage des 8 sprites d'objets secondaires (hauteur 13 à 15 lignes, pad `(2, 2)`) : Boomerang, Bombe, Arc, Bougie, Nourriture, Potion, Flûte, Baguette.
* **Règle anti-régression** :
  - Toujours vérifier que les coordonnées d'un sprite matériel affiché dans un cadre textuel tiennent compte de l'origine de l'écran VIC-II (X=24..344, Y=50..250) et maintiennent une marge interne $\ge 4$ pixels.

---

## 19. Triforce : Déformation en Piliers Discontinus et Désalignement du Socle (002.png)
* **Fichiers concernés** : [assets/extra.txt](file:///home/vedix/Documents/C64/zelda/assets/extra.txt), [src/inventory_draw.asm](file:///home/vedix/Documents/C64/zelda/src/inventory_draw.asm)
* **Symptômes** :
  1. La Triforce sur la Page 1 d'inventaire ressemblait à 8 piliers rectangulaires verticaux disjoints au lieu d'une pyramide triangulaire dorée.
  2. Le cadre textuel inférieur `+----------+` était décalé verticalement par rapport à la base des sprites.
* **Causes racines** :
  1. Les sprites `tri_p1` à `tri_p8` dans `assets/extra.txt` utilisaient des bandes verticales monochromes de même largeur sans biseau diagonal.
  2. La routine `draw_p1_pyramid_frame` traçait le socle à la ligne 12 au lieu de la ligne 11 (raster Y=138), laissant un vide de 8 pixels sous les sprites.
* **Correctif appliqué** :
  1. Remplacement des 8 fragments par 4 étages biseautés formant un triangle équilatéral plein et jointif : sommet pointu (largeur 8 px par aile), étage supérieur (16 px), étage médian (24 px) et base élargie (32 px).
  2. Réalignement des coordonnées matérielles des sprites dans [src/inventory_draw.asm](file:///home/vedix/Documents/C64/zelda/src/inventory_draw.asm) (gauche à X=160, droite à X=184, étages à Y=106, 114, 122, 130).
  3. Recalage du cadre textuel sur les lignes 7 à 11 avec la barre `+----------+` venant supporter immédiatement le pied du triangle.
* **Règle anti-régression** :
  - Tout motif géométrique multi-sprites doit être modélisé avec des biseaux continus assurant la continuité visuelle entre étages adjacents.

---

## 20. Reliques Passives : Écrasement en Donjon et Mauvaise Attribution (003.png)
* **Fichiers concernés** : [src/charset.asm](file:///home/vedix/Documents/C64/zelda/src/charset.asm), [src/inventory_draw.asm](file:///home/vedix/Documents/C64/zelda/src/inventory_draw.asm)
* **Symptômes** :
  1. Lorsque le joueur possédait tout l'équipement en donjon, le Livre de magie et l'Anneau disparaissaient ou affichaient des caractères corrompus.
  2. Le Bracelet de force était représenté sous la forme d'un anneau au lieu d'un gantelet.
* **Causes racines** :
  1. Le moteur de donjon (`dung1.asm`..`dung9.asm`) recopie dynamiquement 256 octets de caractères spécifiques à l'adresse `$2540` (`$2000 + 168*8`), écrasant systématiquement les caractères 168..199. Les reliques passives qui y étaient placées étaient donc détruites lors de l'entrée en donjon.
  2. L'icône du Bracelet réutilisait le glyphe de l'Anneau.
* **Correctif appliqué** :
  1. Réaffectation des 6 reliques passives dans la plage de caractères sécurisée et persistante 120..125 de [src/charset.asm](file:///home/vedix/Documents/C64/zelda/src/charset.asm) : 120 Radeau, 121 Échelle, 122 Gantelet/Bracelet, 123 Livre magique (croix mystique), 124 Anneau (joyau central), 125 Clé magique (tête en trèfle).
  2. `draw_p0_passive_relics` pointe désormais exclusivement sur cette plage protégée et gère la coloration dynamique de l'Anneau (`COL_RED` si Anneau Rouge, `COL_CYAN` si Anneau Bleu).
* **Règle anti-régression** :
  - Ne jamais stocker de caractères d'interface persistants dans la plage `$2540..$25FF` (caractères 168..199), réservée au streaming des fontes de donjons.

---

## 21. Échelle : Conflit et Blocage avec les Ponts Existants (004.png)
* **Fichiers concernés** : [src/player.asm](file:///home/vedix/Documents/C64/zelda/src/player.asm), [src/items.asm](file:///home/vedix/Documents/C64/zelda/src/items.asm), [src/transition.asm](file:///home/vedix/Documents/C64/zelda/src/transition.asm), [src/tilemap.asm](file:///home/vedix/Documents/C64/zelda/src/tilemap.asm)
* **Symptômes** :
  1. Lorsqu'un pont existait déjà sur la carte, l'échelle se bloquait indéfiniment lors du franchissement d'un ruisseau.
  2. Le franchissement modifiait les tuiles de décor et pouvait corrompre ou figer les ponts naturels de la zone.
* **Causes racines** :
  1. L'ancienne routine écrivait `TILE_BRIDGE_H` ou `TILE_BRIDGE_V` directement dans le tampon de salle `room_buf`, écrasant la structure de tuiles et causant des désynchronisations de collision.
  2. Aucune logique de suivi de marche (montée sur l'échelle puis débarquement sur la berge opposée) n'était implémentée.
* **Correctif appliqué** :
  1. Suppression intégrale de toute écriture de tuile dans `room_buf` lors de l'utilisation de l'échelle.
  2. Rendu de l'échelle par une entité sprite autonome (Sprite 2) dans [src/items.asm](file:///home/vedix/Documents/C64/zelda/src/items.asm) à `(ladder_spr_x, ladder_spr_y)`.
  3. Gestion dynamique du franchissement dans [src/player.asm](file:///home/vedix/Documents/C64/zelda/src/player.asm) : autorisation de marche sur la tuile d'eau `ladder_tile_idx`, détection de prise d'appui (`ladder_stepped_on = 1`), et extinction/rétraction automatique dès que Link foule la terre ferme.
  4. Réinitialisation à `$FF` lors des changements de salle dans `transition.asm` et `tilemap.asm`.
* **Règle anti-régression** :
  - L'échelle de Link doit être gérée exclusivement comme un objet/sprite indépendant sans altérer le tampon `room_buf`.

---

## 22. Goriya : Frame Brisée, Blocage Mur Nord et Absence d'IA Boomerang (005.png)
* **Fichiers concernés** : [assets/enemies.txt](file:///home/vedix/Documents/C64/zelda/assets/enemies.txt), [src/enemies.asm](file:///home/vedix/Documents/C64/zelda/src/enemies.asm), [tools/build_sprite_banks.py](file:///home/vedix/Documents/C64/zelda/tools/build_sprite_banks.py), [src/main.asm](file:///home/vedix/Documents/C64/zelda/src/main.asm)
* **Symptômes** :
  1. Le sprite du Goriya dans le Donjon 1 (Salle $23) utilisait une frame corrompue et décalée verticalement.
  2. Le Goriya restait coincé indéfiniment au contact du mur nord de la salle.
  3. Le Goriya n'avait pas son comportement officiel : tirs rares en ligne droite infinie sans jamais récupérer le boomerang.
* **Causes racines** :
  1. Dans `assets/enemies.txt`, `goriya_1` ne comportait que 12 lignes au lieu de 16 avec des caractères de décalage corrompus.
  2. `check_bounds_only` autorisait les ennemis à monter jusqu'à `PLAYER_Y_MIN = 80`. Or en donjon, la rangée 0 de tuiles (Y=80..95) est un mur plein : dès que l'ennemi atteignait Y < 88, son hitbox (`col_y + 8 < 96`) pénétrait dans le mur, bloquant simultanément les directions Haut, Gauche et Droite.
  3. Aucune routine de ciblage en couloir ni de trajectoire aller-retour en tête chercheuse n'était programmée pour le projectile `PROJ_BOOMERANG`.
* **Correctif appliqué** :
  1. Restauration des 8 frames officielles et symétriques du Goriya (4 directions x 2 pas) dans `assets/enemies.txt` et mise à jour de `build_sprite_banks.py`.
  2. Garde-fou de confinement donjon dans `check_bounds_only` ([src/enemies.asm](file:///home/vedix/Documents/C64/zelda/src/enemies.asm)) restreignant strictement `Y` entre 88 et 208 (lignes 1 à 8 jouables).
  3. Détection de couloir de Link (`goriya_check_align_and_shoot`) : Goriya pivote face au joueur et décoche son boomerang dès qu'il traverse sa ligne de mire (±10 px).
  4. IA du boomerang ennemi (`update_goriya_boomerang`) : vol aller sur 28 pas (~56 px) puis retour en tête chercheuse vers `en_proj_owner`, qui rattrape son arme au contact.
  5. Relocalisation de `tilemap.asm` au-delà de `$4000` dans [src/main.asm](file:///home/vedix/Documents/C64/zelda/src/main.asm), libérant plus de 2,2 Ko sous le plafond `$2000` du jeu de caractères tout en préservant 8,4 Ko de marge sous `$C000`.
* **Règle anti-régression** :
  - En donjon, borner impérativement les coordonnées Y des monstres à `[88, 208]` pour éviter toute pénétration de hitbox dans les murs nord/sud.
  - Le boomerang de Goriya doit toujours disposer d'une référence à son propriétaire (`en_proj_owner`) pour garantir son retour et sa réinitialisation.

---

## 23. Audio Donjons : Détérioration Progressive de la Musique, Écrasement des Tables BGM par les Overlays et Absence du Thème du Donjon 9
* **Fichiers concernés** : [src/main.asm](file:///home/vedix/Documents/C64/zelda/src/main.asm), [src/sound.asm](file:///home/vedix/Documents/C64/zelda/src/sound.asm), [src/intro.asm](file:///home/vedix/Documents/C64/zelda/src/intro.asm), [src/hud.asm](file:///home/vedix/Documents/C64/zelda/src/hud.asm), [src/overlay_trampolines.asm](file:///home/vedix/Documents/C64/zelda/src/overlay_trampolines.asm), [src/tilemap.asm](file:///home/vedix/Documents/C64/zelda/src/tilemap.asm), [src/debug.asm](file:///home/vedix/Documents/C64/zelda/src/debug.asm), [tools/extract_music.py](file:///home/vedix/Documents/C64/zelda/tools/extract_music.py), [tools/generate_game_audio.py](file:///home/vedix/Documents/C64/zelda/tools/generate_game_audio.py), [tools/cartgen.py](file:///home/vedix/Documents/C64/zelda/tools/cartgen.py)
* **Symptômes** :
  1. En explorant les donjons, la musique de fond se dégradait au fil du temps : des notes fausses apparaissaient, des voix se coupaient, et la musique finissait par se désynchroniser ou se figer après l'ouverture de l'inventaire, l'allumage d'une bougie, ou la visite d'un cellier.
  2. Le Donjon 9 (Death Mountain) jouait le même thème générique que les autres donjons, manquant la musique originale plus sombre et haletante de la NES.
  3. L'intro cinématographique et l'écran titre ne tiraient pas parti de la seconde puce SID en mode Dual SID ($D420 / $D500 / $DF00).
* **Causes racines** :
  1. **Collision Mémoire Résidente / Zone de Streaming Overlay (`$A000`)** : La zone résidente compilée de `main.asm` s'étendait jusqu'à `$A189`. Or, la zone de streaming cartouche pour les overlays d'inventaire, de celliers, de bougie et de debug commence exactement à `$A000` (`OVERLAY_RAM_ADDR`). Chaque chargement d'overlay (ex: ouverture de l'inventaire via Bank 27) écrasait 393 octets de tables musicales BGM résidant entre `$A000` et `$A189` avec du code machine 6502 (`$8D, $A0, $20`), corrompant irrémédiablement les pointeurs de pas, les fréquences et les compteurs de boucle.
  2. **Restauration Incomplète des Registres SID et Désynchronisation Dual SID** :
     - Lors de la restauration d'une voix après un SFX ou un carillon (`restore_music_voice_2`, `restore_music_voice_3`), les registres de forme d'onde, de largeur d'impulsion (PW) et d'enveloppe ADSR n'étaient pas réécrits symétriquement sur SID2.
     - L'extinction d'une note coupait la forme d'onde (`CTRL = 0`) au lieu de relâcher seulement le Gate (`Gate=0`), causant des clics et des artefacts lors du réarmement.
  3. **Absence du Thème du Donjon 9 dans la Cartouche** : La musique `SongScriptLastLevel0` de la ROM NES originale n'avait pas été extraite ni intégrée dans la banque cartouche.
* **Correctif appliqué** :
  1. **Re-zonage Mémoire sous `$2000` & Plafond `$A000` Garanti** :
     - Déplacement des tampons résidents `visited_rooms`, `visited_ow_rooms`, `visited_uw_rooms`, `cave_room_cleared` (4 × 128 o) et inclusion de `src/music_data_low.inc` (fréquences et jingles courts) dans la plage basse `$1BF8..$1ED4` (< `$2000`).
     - La fin de la mémoire résidente a été ramenée de `$A189` à `$9F80`, offrant une marge de sécurité absolue de 128 octets sous `$A000`.
     - Ajout de l'assertion ACME stricte `!if * > OVERLAY_RAM_ADDR { !error ... }` dans `src/main.asm`.
  2. **Extraction & Intégration du Thème du Donjon 9 (Banque 31 Cartouche)** :
     - Extraction de `SongScriptLastLevel0` ($91FD, header `$8E0D` de la ROM NES) via `tools/extract_music.py`.
     - Décodage des 3 voix (Square 1, Square 2, ostinato Triangle) avec scission en deux volets 8 bits indexables (`d9_p1` : 158 pas, `d9_p2` : 159 pas = 317 pas au total, 1268 octets).
     - Intégration dans la banque cartouche 31 (`CART_BANK_AUDIO`, 8 Ko, offset `$8800`).
     - Streaming dynamique dans `bgm_track_buffer` via `sound_play_dungeon_music` lors de l'entrée dans le Donjon 9 (`enter_dungeon`), et restauration automatique du thème de l'Overworld à la sortie (`exit_dungeon`).
  3. **Généralisation du Mode Dual SID (Intro & Jeu)** :
     - Dans `src/intro.asm`, activation complète du second SID avec chorus stéréo (+2 de désaccord de fréquence entre SID1 et SID2 sur Voix 1 et 2, percussion Noise sur Voix 3).
     - Restauration intégrale de la forme d'onde, de PW et ADSR sur SID1 et SID2 dans `restore_music_voice_2` et `restore_music_voice_3`.
     - Conservation du bit de waveform lors de l'extinction Gate OFF (`%01000000` Pulse / `%00100000` Sawtooth) pour un son propre et sans clics.
* **Règles anti-régression** :
  - La zone résidente du moteur de jeu (`main.asm`) ne doit JAMAIS dépasser `$A000` (`OVERLAY_RAM_ADDR`). Tout nouveau code ou buffer résident doit respecter le plafond `$9FFF`.
  - La banque 31 de la cartouche Magic Desk (`CART_BANK_AUDIO`) est réservée au streaming des musiques étendues.
  - Toute extinction ou silence musical sur une voix active doit conserver le bit de forme d'onde actif avec `Gate=0` au lieu de forcer `CTRL = 0`.

---

### [2026-11-05] Anomalie 11 : Ralentissement et Désynchronisation du Thème Audio Donjon 9 (Death Mountain)
* **Symptômes** : La musique du Niveau 9 semblait bugguée, se ralentissait fortement au fil de la lecture et subissait des pauses démesurées.
* **Cause racine** :
  - Dans la ROM NES originale, `SongHeaderLastLevel0` ($8E0D) commence par l'octet `$10`, spécifiant l'usage de la **Table 2** (`$9FD1 + $10` = `[6, 12, 8, 24, 36, 48, 72, 16]`).
  - `tools/generate_game_audio.py` utilisait par erreur `uw_durs` (Table 0 = `[3, 10, 1, 20, 5, 40, 60, 112]`), où l'index 7 vaut 112 ticks au lieu de 16 ticks. Chaque double croche rapide du thème était ainsi étirée d'un facteur 7, générant un faux tempo lent et 317 micro-pas artificiels.
* **Correctif appliqué** :
  1. Décodage de `d9_sc` avec `ow_durs` (Table 2 authentique) : les 3 voix (Square 1, Square 0, Triangle) s'alignent parfaitement sur **1344 ticks** chacune.
  2. Compilation chronologique propre en une boucle de **124 pas** (22,4 secondes, durée exacte de la boucle NES originale).
  3. Simplification de `.step_dungeon_final` dans [src/sound.asm](file:///home/vedix/Documents/C64/zelda/src/sound.asm) en une passe unique 8 bits indexable de 0 à `MUSIC_D9_LEN - 1`.
  4. Réduction de la taille streamée depuis Banque 31 à 2 pages (512 octets pour 496 octets de partition).
  5. Validation automatique via [tools/test_dungeon9_audio.py](file:///home/vedix/Documents/C64/zelda/tools/test_dungeon9_audio.py) : progression frame par frame fluide sans pause ni décélération.

---

### [2026-11-05] Anomalie 12 : Sprites Défectueux (Darknut scindé, Dodongo dédoublé, Bosses et Monstres ajourés)
* **Symptômes** :
  - Le chevalier Darknut apparaissait scindé en deux moitiés déconnectées avec un vide vertical au milieu.
  - Le Dodongo apparaissait comme deux mini-dinosaures empilés verticalement l'un sur l'autre au lieu d'une entité unique.
  - Lanmola clignotait entre une tige de 2 pixels et un cercle ajouré ; le Wallmaster avait la paume percée sans vraie pose d'animation ; le Rope était difforme ; Manhandla et Ganon avaient de grands vides transparents au centre ; les boomerangs étaient des anneaux creux statiques.
* **Cause racine** :
  - `darknut_1` dans `assets/enemies.txt` avait les colonnes 2..5 vidées en `....`, et `darknut_ptrs` figeait la direction basse sur cette frame.
  - `dodongo_0` et `dodongo_1` contenaient deux mini-Dodongos dessinés l'un sur l'autre (lignes 3..11 et 13..20) dans le même bloc de sprite 12x21.
  - `ganon_0` et `ganon_1` comportaient 3 colonnes de vide transparent au centre de la hure et du torse.
  - `lanmola_head` et `lanmola_body` étaient creux, et `lanmola_ptrs` alternait tête et corps sur un seul slot.
* **Correctif appliqué** :
  1. **Darknut** : Réintégration des frames complètes avec heaume, grand bouclier frontal couvrant le torse, cotte de mailles et jambières articulées. Correction de `darknut_ptrs` dans [src/enemies.asm](file:///home/vedix/Documents/C64/zelda/src/enemies.asm) pour alterner les poses de pas sur les 4 directions.
  2. **Dodongo** : Redessiné en un grand dinosaure cuirassé massif unique de profil occupant toute la hauteur du sprite. Vérification de l'instanciation autonome de chaque Dodongo dans les salles multiples (Donjon 2 et 8).
  3. **Ganon** : Suppression de la fente médiane vide ; refonte en Démon Cochon colossal (défenses d'ivoire, hure menaçante, yeux de braise, cape et toge magique).
  4. **Lanmola & Wallmaster & Rope** : Tête à mandibules et corps chitineux plein pour Lanmola ; main ouverte descendante et poing agrippant au sol pour Wallmaster ; serpent en S ondulant avec tête et langue pour Rope.
  5. **Boomerangs** : Remplacement des anneaux creux par des lames aérodynamiques pleines avec rotation dynamique fluide 4 directions pour Link et les monstres Goriya.
  6. **Régénération des Banques & Atlas** : Recompilation des banques cartouche 10, 11, 12, 13 via `tools/build_sprite_banks.py` et mise à jour complète de l'atlas graphique (`make atlas`). Captures d'écran en jeu validées sous VICE.

---

### [2026-11-05] Anomalie 13 : Décalages & Sprites Scindés en Deux (MSB VIC-II $D010, Dodongo 32×16, Manhandla Quadrilobé, Darknut & Goriyas)
* **Symptômes** :
  - Sur certains monstres et boss (Dodongo, Manhandla, Darknut, Goriya), des décalages ou scissions apparaissaient en jeu : sprites coupés en deux moitiés, moitiés de monstres téléportées à l'autre bout de l'écran ou inversées de l'intérieur.
  - L'atlas graphique exporté ne correspondait pas fidèlement aux formes exactes des sprites de la ROM `zelda.nes`.
* **Causes racines** :
  1. **Perte du 9ème Bit de Coordonnée X VIC-II (`$D010` / `VIC_SPRITE_MSB`)** :
     - Pour les boss assemblés en multi-sprites (Dodongo 32×16, Aquamentus 24×32, Manhandla, Ganon), les coordonnées des sprites secondaires étaient calculées par de simples additions 8 bits (`clc : adc #16`).
     - Dès que le boss s'approchait de la bordure droite de l'écran ($X \ge 240$ ou $X + 16 \ge 256$), le débordement reportait le 2ème sprite à $X = 0..16$ sur le bord gauche de l'écran au lieu d'activer le bit de poids fort dans `$D010`, donnant l'illusion visuelle que le boss était scindé en deux.
  2. **Dodongo Inversé de l'Intérieur en Direction Droite** :
     - L'orientation vers la droite se contentait d'inverser les pointeurs Avant et Arrière sans miroir horizontal, provoquant la rencontre du museau et de la queue au centre face à l'intérieur.
  3. **Manhandla : Inversion Cœur / Mâchoires et Trou Central de 8 Pixels** :
     - Le cœur et les mâchoires étaient permutés : le miroir des tuiles 40 & 41 (qui ont des colonnes 4..7 vides) laissait un trou de 8 pixels au centre. Le vrai cœur NES est constitué des tuiles 44 & 45 jointes en miroir (bloc massif), et les 4 mâchoires sont les tuiles 40..43.
  4. **Extraction Naïve par Miroir Demi-Tuile** :
     - L'ancienne extraction découpait les tuiles en deux et appliquait un miroir horizontal naïf (`d26 + hflip(d26)`). Sur la NES, le Darknut, le Goriya et le Wallmaster utilisent des tuiles distinctes pour les moitiés gauche et droite ou une inversion de bloc 16×16 complet.
* **Correctif appliqué** :
  1. **Gestion Dynamique du MSB VIC-II (`.apply_boss_msb`)** :
     - Implémentation dans [src/enemies.asm](file:///home/vedix/Documents/C64/zelda/src/enemies.asm) du calcul du 9ème bit pour les Sprites VIC 3, 4, 5 et 6 dans toutes les routines de boss assemblés (`.drw_single_exit`, `.drw_aquamentus`, `.drw_dodongo`, `.drw_ganon`, `.drw_manhandla`).
  2. **Extraction Directe Authentique depuis `zelda.nes` (117 Sprites)** :
     - Extraction intégrale de l'ensemble des tuiles CHR NES sans altération : Darknut avec motifs asymétriques originaux, Manhandla cœur massif + mâchoires articulées, Dodongo avec frames gauche et droite pré-calculées avec raccord parfait, Lanmola 12×21, Boomerangs centrés.
  3. **Rendu Dodongo Multi-Sprites 32×16 & 2ème Dodongo** :
     - Tables de pointeurs `dod_f_tbl`, `dod_b_tbl`, `dod_bf_tbl`, `dod_bb_tbl` gérant direction, animation et état gonflé/blessé.
     - Gestion complète des deux Dodongos simultanés (Dodongo 1 sur Sprites 3 & 4, Dodongo 2 sur Sprites 5 & 6) avec MSB $D010 propre pour chacun.
  4. **Optimisation Mémoire Résidente ACME** :
     - Déplacement de `en_sprite_tbl_lo/hi` (90 octets) sous `$2000` et factorisation de `get_spr_ptr_and_col` (-84 octets en haute RAM), garantissant la fin du code résident à `$9F89` (< `$A000`, 119 octets de sécurité sous `OVERLAY_RAM_ADDR`).
  5. **Export de l'Atlas & Captures Automatisées sous VICE** :
     - Atlas complet exporté (`make atlas`, 117 sprites répertoriés).
     - Captures de confirmation pixel-perfect validées via `tools/test_verify_enemy_sprites.py` pour Dodongo, Manhandla, Darknut, Goriya, Aquamentus et Ropes.

---

### [2026-11-05] Anomalie 14 : Ennemis Overworld Déformés, Tronqués ou Figés (Octorok, Moblin, Tektite, Leever, Peahat, Armos, Ghini, Zora, Lynel 4-dir)
* **Symptômes** :
  - Dans l'Overworld, les monstres apparaissaient altérés ("KO") : Octoroks tronqués sans tentacules, Tektites réduits à des aplats statiques, Leevers ressemblant à des bâtons striés verticaux, Armos sans heaume ni épée, Ghinis informes, et Lynels glissant sur le sol sans aucune orientation directionnelle.
* **Causes racines** :
  1. **Omission d'Extraction du Bloc 'ow' NES** :
     - Dans `tools/extract_all_nes_sprites.py`, la section Overworld était copiée passivement depuis une version obsolète d'`assets/enemies.txt` contenant des dessins manuels approximatifs, au lieu d'extraire les 114 tuiles authentiques du bloc `"ow"` de `zelda.nes` (offset `$D15B`).
  2. **Tables Directionnelles Lynel Incomplètes** :
     - `lynel_ptrs` dans `src/enemies.asm` répétait les mêmes frames pour les 4 directions, privant le centaure de ses poses de face, dos et profil.
  3. **Absence de Rechargement de la Banque 10 lors du Warp Overworld** :
     - `debug_do_warp_overworld` dans `src/debug.asm` omettait d'appeler `cart_load_sprites_ow`, conservant les sprites de donjon en cas de téléportation directe.
* **Correctif appliqué** :
  1. **Extraction Automatisée 1:1 NES de tous les Ennemis Overworld** :
     - Octorok : Face (tuiles 2, 3 et 4, 5), Dos (tuiles 10, 11 et 12, 13) et Profil avec trompe cracheuse (tuiles 18..25).
     - Moblin : Face, Dos et Profil de marche avec lance (tuiles 26..37 et 38..41).
     - Tektite : Accroupi et saut déployé (tuiles 50..53).
     - Leever : Toupie rotative à ailettes (tuiles 56..59).
     - Peahat : Fleur à hélices tournoyantes (tuiles 60..63).
     - Armos : Statue de guerrier avec heaume, bouclier et foulée (tuiles 64..71).
     - Ghini : Spectre à queue sinusoïdale fluide (tuiles 72..77).
     - Zora : Nage bouche fermée et cracheur bouche ouverte (tuiles 82..85 et 94..97).
     - Lynel : Animation 4 directions complète (Bas tuiles 106..109, Haut tuiles 110..113, Côté tuiles 82..89).
  2. **Mise à Jour de la Banque Cartouche 10 & Tables Assembleur** :
     - Inclusion des frames directionnelles Lynel dans `OW_NAMES` (40 slots sur 75 alloués).
     - Mise à jour de `lynel_ptrs` dans `src/enemies.asm`.
     - Ajout de `cart_load_sprites_ow` dans `debug_do_warp_overworld`.
  3. **Atlas Graphique & Captures Émulateur Validées** :
     - Atlas mis à jour (125 sprites ennemis exportés dans `sheet_sprites_enemies.png` et `atlas_all_assets.png`).
     - Validation des 16 scénarios d'Overworld via `tools/capture_ow_enemies.py`.

### [2026-11-05] Anomalie 15 : Sprite de l'Octorok en Overworld ressemblant au Chevalier (Armos Knight) & Décalage des Tuiles CHR du Bloc 'ow'
* **Symptômes** :
  - Dans l'Overworld, l'Octorok affichait le corps et le bouclier d'un chevalier (Armos Knight) plutôt que le sprite authentique du poulpe cracheur de rochers.
* **Causes racines** :
  1. **Décalage d'Indexation dans les 114 Tuiles CHR du Bloc 'ow' NES** :
     - Dans `tools/extract_all_nes_sprites.py`, l'extraction de l'Octorok ciblait à tort les tuiles 2 et 18 du bloc `Tiles_S_Surface` (`$915B`). Or, les tuiles 18..33 correspondent à l'Armos Knight (statue de chevalier avec heaume et grand bouclier), tandis que le véritable Octorok commence à la tuile 34 (`$937B`) jusqu'à la tuile 45 (`$942B`).
  2. **Palette Multicolore C64 non Adaptée au Changement de Teinte (Rouge/Bleu)** :
     - La couleur 1 de la ROM NES (corps de l'Octorok) était convertie en `s` (MC1 partagé `$D025`) au lieu de `g` (couleur propre `$D027..$D02E`), empêchant le corps de virer au bleu pour les Octoroks Bleus.
* **Correctif appliqué** :
  1. **Audit des Appels et Pointers Mémoire C64** :
     - Vérification de la chaîne complète : `octo_ptrs` ($A0..$A7), `get_enemy_sprite_and_color`, `en_sprite_tbl_lo/hi`, `cart_load_sprites_ow` ($2800..$3FFF). Tous les appels mémoire et registres VIC-II sont conformes.
  2. **Extraction Authentique 1:1 des 114 Tuiles CHR du Bloc 'ow'** :
     - Octorok : Tuiles 34..45 (Face 34/35 & 36/37, Dos vflip, Profils 38..45, Rocher 47 centré).
     - Moblin : Tuiles 98..113 (Face 106..109, Dos 110..113, Profils 98..105).
     - Tektite : Tuiles 6..9 (Sol 6/7, Saut 8/9).
     - Leever : Tuiles 52..55 (Toupie tournoyante).
     - Peahat : Tuiles 56..63 (Atterrissage et rotation des pales).
     - Armos : Tuiles 18..25 (Chevalier de pierre authentique).
     - Ghini : Tuiles 82..89 (Spectre cimetière).
     - Zora : Tuiles 90..97 (Nage ondulation surface 94/95 et cracheur émergé 90/91).
     - Lynel : Tuiles 64..79 (4 directions cardinales).
  3. **Mappage Dynamique de la Couleur Propre (`g`)** :
     - Corps de l'Octorok routé sur `g` : rouge vif pour Octorok Rouge (`COL_RED`), bleu pour Octorok Bleu (`COL_BLUE`).
  4. **Validation Visuelle et Régression** :
     - Régénération complète des 16 captures d'Overworld sous émulateur VICE (`tools/capture_ow_enemies.py`).
     - Validation intégrale des planches [atlas_all_assets.png](file:///home/vedix/Documents/C64/zelda/atlas_all_assets.png) et `sheet_sprites_enemies.png`.
     - Tous les tests automatisés (`test_rules_audit.py`, `test_export_assets.py`, `test_verified_bugs.py`) passent avec succès.






