# Implémentons l'enchaînement cinématique complet dans src/intro.asm :
# 1. Écran Titre & Cascade :
#    Grand logo d'or ZELDA 16x16, Triforces, falaises rocheuses de Death Mountain, double cascade vivante et animée.
# 2. Descente de la cascade (Pan Down) vers le parchemin :
#    Après 6 secondes, la cascade descend ! L'écran défile vers le haut en douceur.
#    Le grand lac apparaît, puis le haut du parchemin royal d'Hyrule émerge par le bas et se déroule.
# 3. Déroulement du parchemin royal :
#    Le parchemin prend toute sa place.
# 4. Défilement vertical du texte officiel de bas en haut (Bottom to Top Scroll) :
#    Le texte de l'histoire entre par le bas du parchemin et monte ligne par ligne avec régularité (une ligne toutes les 40 frames / 0.8s) !
#    Le texte défile sans discontinuer à l'intérieur du rouleau en blanc éclatant.
# 5. Défilé des trésors de la quête :
#    Dans la continuité du parchemin, tous les objets légendaires avec leurs icônes et noms montent du bas vers le haut.
# 6. Musique SID 3 voix continue et synchronisée tout au long de la séquence.

