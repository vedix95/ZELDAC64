# Zelda C64

Projet Commodore 64 en assembleur 6510 (ACME), testé avec VICE.

## Prérequis

```sh
sudo pacman -S acme      # assembleur
# vice est déjà installé (x64sc, c1541, petcat)
make check               # vérifie tout
```

## Commandes

| Commande     | Effet                                              |
|--------------|----------------------------------------------------|
| `make`       | assemble `src/main.asm` en `build/zelda.prg`        |
| `make run`   | assemble et lance dans VICE (`x64sc`)              |
| `make debug` | idem, avec les labels chargés dans le moniteur VICE |
| `make d64`   | crée `build/zelda.d64`                             |
| `make clean` | supprime `build/`                                  |

Dans le moniteur VICE (`Alt+H`), les labels sont utilisables :
`break start`, `d start`, `m frame`.

## Arborescence

```
src/main.asm      point d'entrée : stub BASIC, init, boucle principale
src/input.asm     lecture du joystick (port 2)
src/player.asm    position, déplacement, bornes et affichage de Link
src/tilemap.asm   init vidéo multicolore, effacement écran, dessin de la carte
src/c64.inc       constantes VIC-II / SID / CIA / KERNAL / couleurs / joystick
src/sprites.asm   GÉNÉRÉ depuis assets/link.txt
src/charset.asm   GÉNÉRÉ depuis assets/tiles.txt (jeu de caractères)
src/map_data.asm  GÉNÉRÉ depuis assets/tiles.txt + assets/world.txt (9 salles)
assets/link.txt   sprites de Link en ASCII art (4 directions, multicolore)
assets/tiles.txt  tuiles 16x16 en ASCII art + palette globale
assets/world.txt  monde 3x3 écrans (60x36 tuiles), dessiné d'un seul bloc
tools/            sprgen.py (sprites), tilegen.py (tuiles, monde et preview)
scripts/          outils (check-env.sh)
build/            sortie (ignorée par git)
```

Les fichiers `GÉNÉRÉ` sont commités mais ne s'éditent pas à la main : `make`
les régénère quand les assets changent.

## Sprites

Éditer `assets/link.txt` (`.` transparent, `s` peau, `g` vert, `b` marron),
puis `make preview` génère `build/link_preview.png` pour voir le résultat.

## Monde et multi-écrans

Le monde fait **3x3 écrans** (9 salles de 20x12 tuiles = 60x36 tuiles au total),
dessiné en ASCII dans [assets/world.txt](file:///home/vedix/Documents/C64/zelda/assets/world.txt).

- **Exploration fluide à la Zelda** : quand Link traverse le bord d'un écran (gauche, droite, haut, bas), l'écran bascule immédiatement sur la salle voisine et Link apparaît de l'autre côté.
- **Carrefour central** : Link commence au centre du monde (salle 1,1) au croisement des routes, avec 8 salles à explorer autour (montagnes et grottes au nord, lac à l'est, étangs et forêts au sud et à l'ouest).
- **Aperçu du monde entier** : `make preview` génère [build/world_preview.png](file:///home/vedix/Documents/C64/zelda/build/world_preview.png) qui montre la carte complète de 1920x1152 pixels.

Pour ajouter une tuile : l'ajouter dans `assets/tiles.txt` avec un symbole,
puis l'utiliser dans `assets/map.txt`. `make preview` produit
`build/map_preview.png`.

## Mémoire

| Adresse        | Contenu                                                  |
|----------------|----------------------------------------------------------|
| `$0400-$07E7`  | écran (texte), pointeurs de sprites en `$07F8`           |
| `$0801-$1FFF`  | code, tables, carte, sprites                             |
| `$2000-$27FF`  | jeu de caractères des tuiles (adresse fixe, voir `c64.inc`) |

Le PRG contient des zéros entre la fin du code et `$2000` : c'est voulu.

## Contrôles

Joystick port 2. Dans VICE, activer l'émulation clavier du joystick dans
`Settings > Input devices > Joystick` (jeu de touches numpad ou personnalisé)
et choisir le port 2. Feu : Link devient blanc.

Nouveaux fichiers : créer `src/foo.asm` et l'inclure depuis `main.asm`
avec `!source "src/foo.asm"`. Le Makefile détecte les changements tout seul.
