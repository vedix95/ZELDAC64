# Modélisons des lettres de 2x2 caractères (16x16) pour Z E L D A
# Le logo NES fait 5 lettres de 16x16 espacées d'1 colonne :
# 5 * 2 + 4 * 1 = 14 colonnes (de col 13 à 26).
# C'est la taille idéale !
# Chaque lettre est composée de 4 glyphes 8x8 : (TL, TR, BL, BR)
# Z:
# TL: %11111111, %11111111, %00000111, %00001110, %00011100, %00111000, %01110000, %11100000
# TR: %11111111, %11111111, %11100000, %01110000, %00111000, %00011100, %00001110, %00000111
# BL: %00000111, %00001110, %00011100, %00111000, %01110000, %11100000, %11111111, %11111111
# BR: %11100000, %01110000, %00111000, %00011100, %00001110, %00000111, %11111111, %11111111
print("16x16 letters designed")
