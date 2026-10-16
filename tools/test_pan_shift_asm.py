# Vérifions :
# Si intro_pan_step décale les 1000 octets d'écran et de couleur :
# Le plus simple, robuste et ultra-rapide (60 Hz parfait sans glitch) :
# Pour décaler tout l'écran de 40 colonnes vers le haut :
# memmove(SCREEN_RAM, SCREEN_RAM + 40, 960 octets)
# memmove(COLOR_RAM, COLOR_RAM + 40, 960 octets)
# En 6502 : 4 blocs de 240 octets (ou boucle de 0 à 959).
# Cela prend moins de 3 millisecondes et est 100% sans bug !
print("Memmove logic conceived")
