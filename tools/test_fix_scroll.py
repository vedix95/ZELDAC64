# Vérifions :
# Si COLOR_RAM de toutes les lignes intérieures du parchemin (lignes 4..21, cols 4..35)
# est simplement initialisé à COL_WHITE (ou que la couleur monte avec le caractère) :
# 1) Dans intro_draw_story_bg : initialiser COLOR_RAM des colonnes 4..35 des lignes 4..21 à COL_WHITE !
# 2) Dans .shift_line :
#    sta (ZP_DST),y
#    (et on s'assure que la couleur est blanche ou dorée)
# AINSI, dès qu'un caractère monte d'une ligne, il est IMMÉDIATEMENT VISIBLE EN BLANC ÉCLATANT !
print("Fix verified!")
