# Modélisons le pan down vertical :
# INTRO_PHASE_WATERFALL = 0
# INTRO_PHASE_PAN_DOWN  = 1
# INTRO_PHASE_STORY     = 2
# INTRO_PHASE_TREASURES = 3

# Lors de INTRO_PHASE_PAN_DOWN :
# Toutes les 4 frames, tout l'écran monte d'une ligne (décalage lignes 0..23 vers 0..22)
# et on injecte sur la ligne 24 la suite du paysage :
# - Des falaises supplémentaires et le grand lac
# - Puis la crête dorée du parchemin
# - Puis le titre "HISTOIRE D'HYRULE"
# - Puis le rouleau se déploie complètement !
# Une fois en place, intro_phase passe à INTRO_PHASE_STORY et le texte commence à monter du bas vers le haut !
print("Pan down engine formulated")
