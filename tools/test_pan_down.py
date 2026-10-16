# Modélisons le défilement vertical vers le bas :
# Décaler les lignes 0..23 d'un cran vers le bas (ligne L vers L+1) :
# for r from 23 down to 0:
#   screen[r+1] = screen[r]
#   color[r+1]  = color[r]
#
# Et injecter sur la ligne 0 :
# La nouvelle ligne qui entre par le haut !
print("Pan down algorithm tested")
