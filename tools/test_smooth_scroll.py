# Modélisons le scrolling ultra-fluide pixel par pixel :
# Le VIC-II possède le registre VIC_CTRL1 ($D011) :
# Bits 0..2 : YSCROLL (0 à 7 pixels de défilement fin vertical)
# Bit 3     : RSEL (0 = 24 lignes, 1 = 25 lignes)
# Bit 4     : BMM (mode bitmap)
# Bit 7     : Raster bit 8

# En réglant YSCROLL de 7 à 0 :
# Tout l'écran monte pixel par pixel (1 pixel par frame ou toutes les 2 frames) !
# Quand YSCROLL atteint 0, au pas suivant :
# On remet YSCROLL à 7 et on décale la mémoire écran d'une ligne de caractères vers le haut !
# C'EST LE SCROLLING VERTICAL MATÉRIEL PIXEL PAR PIXEL OFFICIEL DU COMMODORE 64 !
print("Hardware pixel smooth scroll formulated!")
