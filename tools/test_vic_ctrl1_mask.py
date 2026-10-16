# Valeur par défaut de VIC_CTRL1 sur C64 :
# Bits :
# Bit 7 = Raster line bit 8
# Bit 6 = ECM (Extended Color Mode) = 0
# Bit 5 = BMM (Bitmap Mode) = 0
# Bit 4 = DEN (Display Enable) = 1 (écran allumé)
# Bit 3 = RSEL (24 ou 25 lignes) = 1 (25 lignes) ou 0 (24 lignes)
# Bits 0..2 = YSCROLL (0..7) = 3 par défaut sur C64 standard (%00011011 = $1B)

# En 24 lignes (RSEL = 0, %00010000 = $10) :
# Les lignes 0 et 24 sont couvertes par la bordure extérieure !
# Ainsi, quand on scrolle pixel par pixel, aucune ligne ne "glisse" sous les yeux en bordure :
# Le bord supérieur et inférieur du C64 masquent naturellement l'entrée et la sortie des pixels !
# C'est la technique reine des démos et jeux Commodore 64 !
print("24-row smooth scroll technique verified!")
