#!/usr/bin/env bash
# Vérifie la présence des outils de développement C64.
ok=0
check() {  # nom  obligatoire(1/0)  conseil
    if command -v "$1" >/dev/null 2>&1; then
        printf "  [ok]      %-10s %s\n" "$1" "$(command -v "$1")"
    elif [ "$2" = 1 ]; then
        printf "  [MANQUE]  %-10s -> %s\n" "$1" "$3"; ok=1
    else
        printf "  [option]  %-10s -> %s\n" "$1" "$3"
    fi
}
echo "Outils obligatoires :"
check make   1 "sudo pacman -S make"
check acme     1 "sudo pacman -S acme"
check x64sc    1 "sudo pacman -S vice"
check cartconv 1 "fourni par vice (cartouche CRT)"
echo "Outils optionnels :"
check exomizer 0 "yay -S exomizer  (compression de PRG)"
check petcat   0 "fourni par vice  (BASIC <-> PRG)"
check cl65     0 "sudo pacman -S cc65  (C pour 6502)"
exit $ok
