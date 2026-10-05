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
src/main.asm     point d'entrée : stub BASIC, init, boucle principale
src/input.asm    lecture du joystick (port 2)
src/player.asm   position, déplacement, bornes et affichage de Link
src/sprites.asm  données des sprites (alignées sur 64 octets)
src/c64.inc      constantes VIC-II / SID / CIA / KERNAL / couleurs / joystick
scripts/         outils (check-env.sh)
build/           sortie (ignorée par git)
```

## Contrôles

Joystick port 2. Dans VICE, activer l'émulation clavier du joystick dans
`Settings > Input devices > Joystick` (jeu de touches numpad ou personnalisé)
et choisir le port 2. Feu : Link devient blanc.

Nouveaux fichiers : créer `src/foo.asm` et l'inclure depuis `main.asm`
avec `!source "src/foo.asm"`. Le Makefile détecte les changements tout seul.
