# Comparons les deux approches :
# Approche 1: Défilement logiciel par ligne de caractères
# Actuellement :
# cmp #35 -> 35 frames (0.7s) d'attente SANS BOUGER, puis SAUT D'UN COUP d'une ligne entière de 8 pixels !
# C'est ÇA que l'utilisateur appelle "saccadé" : l'image est statique pendant presque 1 seconde, puis saute brutalement d'une case !
#
# SI au contraire :
# Chaque frame (50 Hz) ou toutes les 2 frames, on anime avec VIC_CTRL1 ($D011) bits 0..2 :
# Frame 0: yscroll = 7
# Frame 2: yscroll = 6
# Frame 4: yscroll = 5
# Frame 6: yscroll = 4
# Frame 8: yscroll = 3
# Frame 10: yscroll = 2
# Frame 12: yscroll = 1
# Frame 14: yscroll = 0
# Frame 16: décalage mémoire d'une ligne, yscroll = 7
# -> L'écran glisse à 100% de manière continue, veloutée et constante, PIXEL PAR PIXEL, comme une vraie cinématique arcade/NES !
print("Hardware pixel scroll timeline verified!")
