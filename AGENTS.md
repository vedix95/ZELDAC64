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
- **Préservation de l'Accumulateur sur Détection Dual SID (`ldy dual_sid_enabled`)** : Ne jamais tester `dual_sid_enabled` avec `lda` immédiatement avant un stockage dans un registre matériel SID2 (`sta SID2_*`). L'instruction `lda dual_sid_enabled` écrase l'accumulateur avec la valeur 1, ce qui corrompt le volume (`SID2_VOLUME = 1` au lieu de 15) et désactive les formes d'onde (`SID2_CTRL = $01` : Gate ON sans triangle/pulse/sawtooth/noise). Toujours tester via `ldy dual_sid_enabled` pour conserver intacte la valeur de `A`.
- **Maintien du Bit de Forme d'Onde sur Gate OFF** : Lors de l'extinction ou d'un silence d'une voix SID (`Gate=0`), ne jamais écrire `CTRL = 0`. Toujours conserver le bit de forme d'onde actif (`%01000000` Pulse / `%00100000` Sawtooth) avec le bit 0 à 0, pour éviter les réinitialisations brutales d'oscillateur et les bruits parasites au réarmement.
- **Indexation 8-bits des Séquences Sonores ($\le 255$ Pas)** : Le registre d'index 6502 étant limité à 8 bits (0..255), toute piste doit être contenue dans un index 8-bit (ex: Donjon 9, 124 pas authentiques), ou obligatoirement scindée en deux volets indexables (ex: Overworld `p1` et `p2`) avec bascule `music_part` si elle dépassait 255 pas, pour éviter tout débordement d'index lors des comparaisons `cpx`.

## 7. Plafond Mémoire des Sprites Link ($1000)
- `src/sprites.asm` (généré depuis `assets/link.txt`) commence sous `$0800` et s'achève exactement à `$1000`, adresse à laquelle commence la ROM des caractères (chargen) pour le VIC-II en banque 0.
- Ne jamais ajouter de sprites bruts dans `assets/link.txt` sans réallouer un slot existant ou déporter les graphismes dans les banques de streaming cartouche sous peine de corrompre la mémoire vidéo.

## 8. Plafond Mémoire du Charset ($2000) et Espace Haute RAM ($4000)
- Le jeu de caractères multicolores résident est implanté à l'adresse fixe `$2000` (`CHARSET_ADDR`).
- Le segment de code et de données résidant sous `$2000` (`tiles_data.asm`, `input.asm`, `player.asm`) ne doit sous aucun prétexte déborder au-delà de `$2000`.
- Tout module volumineux ou déplaçable (ex: `tilemap.asm`) doit être positionné dans la zone de haute RAM au-delà de `$4000` (`* = $4000`), qui bénéficie d'une marge de sécurité de plus de 8 Ko avant la zone de streaming cartouche (`$C000`).
- Ne jamais stocker de glyphes d'interface persistants dans la plage `$2540..$25FF` (caractères 168..199), réservée à la copie des fontes de donjons lors du streaming de salle.

## 9. Déploiement de l'Échelle (Stepladder) et Intégrité de `room_buf`
- L'échelle de Link ne doit jamais modifier le tampon de salle `room_buf` (aucune écriture de `TILE_BRIDGE_H` ou `TILE_BRIDGE_V`).
- L'affichage de l'échelle est délégué à une entité autonome (Sprite 2 du VIC-II, `COL_BROWN`).
- `check_point_solid` n'autorise que le franchissement temporaire de l'index d'eau `ladder_tile_idx` ; dès que Link quitte l'eau pour revenir sur une terre ferme (`ladder_stepped_on == 1`), l'échelle doit se rétracter automatiquement (`ladder_tile_idx = $FF`), préservant ainsi les ponts préexistants sur la carte.

## 10. Confinement des Ennemis en Donjon ($Y \in [88, 208]$)
- Dans `check_bounds_only` ([src/enemies.asm](file:///home/vedix/Documents/C64/zelda/src/enemies.asm)), tout ennemi en mode donjon (`current_world_type != WORLD_OVERWORLD`) doit obligatoirement être borné à `88 <= en_cand_y < 208`.
- Ne jamais autoriser `en_cand_y < 88` en donjon : la rangée 0 de tuiles (Y=80..95) étant un mur de pierre solide, la boîte de collision de l'ennemi (`col_y + 8 < 96`) pénétrerait dans le mur, bloquant simultanément les mouvements vers le haut, la gauche et la droite.

## 11. Isolation des Modules Assembleur (`!zone`)
- Tout module source autonome inclus dans `main.asm` (`items.asm`, `enemies.asm`, `player.asm`, etc.) doit obligatoirement débuter par une directive `!zone <nom_du_module>`.
- Cela prévient toute collision entre labels locaux préfixés par un point (`.wait`, `.return`, etc.) entre deux modules distincts, évitant les erreurs de branchement hors-portée inter-fichiers dans l'assembleur ACME.

## 12. Résolution Dynamique des Symboles pour les Tests VICE
- Dans tout script de test ou de capture via le moniteur VICE (`x64sc -moncommands`), ne jamais coder en dur d'adresses absolues issues d'un ancien build (ex: `g 55c2`).
- Toujours extraire dynamiquement les adresses de points d'arrêt depuis `build/intro.vs` et `build/zelda.vs` (`load_labels`).
- Gérer systématiquement la conversion des captures PCX brutes émises par VICE (`magick <fichier>.png.pcx <fichier>.png && rm <fichier>.png.pcx`).

## 13. Plafond Mémoire Résidente ($A000 - OVERLAY_RAM_ADDR) et Streaming Audio (Banque 31)
- Le segment de code et données résidents du moteur de jeu (`src/main.asm`, `sound.asm`, `hud.asm`, etc.) ne doit **sous aucun prétexte déborder au-delà de `$9FFF`**.
- L'adresse `$A000` (`OVERLAY_RAM_ADDR`) marque le début de la zone d'écrasement dynamique par les modules d'overlay cartouche (inventaire Bank 27, grottes Bank 28, items Bank 29, debug Bank 30). Tout octet résident placé au-delà de `$A000` sera irrémédiablement écrasé par du code machine lors de l'activation d'un overlay.
- Toujours maintenir l'assertion ACME `!if * > OVERLAY_RAM_ADDR { !error ... }` dans `src/main.asm`.
- La banque cartouche 31 (`CART_BANK_AUDIO`) est allouée au stockage et au streaming de pistes audio volumineuses (ex: thème étendu du Donjon 9 `MUSIC_DUNGEON_FINAL`). Tout streaming audio vers `bgm_track_buffer` doit s'exécuter via `cart_stream_copy_from` avec découpage par page et masquage d'interruption découplé (`CLI`).

## 14. Extraction CHR des Sprites de Donjons et Routage Couleur Propre (`g`)
- Lors de l'extraction des monstres de donjons depuis `zelda.nes` :
  - Les sprites composites (ex: Keese 16x16) doivent obligatoirement assembler les tuiles NES correspondantes (tuiles 0, 2, 1, 3 en pose ailes déployées) sans miroir horizontal tronqué.
  - Le pixel principal de teinte (pixel 3 de la ROM NES) doit impérativement être routé sur la lettre `g` dans le convertisseur pour alimenter la couleur dynamique propre du sprite (`VIC_SPRITE_COL0..COL7`), permettant l'application fidèle de `en_base_color` (Stalfos blanc $01, Keese rouge/bleu, Zol/Gel vert $05, Trap cyan $03).

## 15. Détection des Salles Scellées et En-têtes de Donjons ($C012..$C013)
- Ne jamais tester une adresse absolue arbitraire de table de salle (ex: `cmp $c016`) pour déterminer si une salle est scellée ou vide : `$C016` correspond à l'adresse de la salle 00 du Donjon 4, ce qui efface cette salle et génère jusqu'à 108 salles fantômes sur la carte.
- Toute détection d'une salle scellée dans les moteurs d'affichage (HUD ou Inventaire Page 3) doit s'effectuer par comparaison 16-bit rigoureuse avec le pointeur stocké dans l'en-tête du donjon actif à `$C012..$C013` (`dummy_sealed_room_ptr`).




