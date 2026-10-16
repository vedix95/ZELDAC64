import sys
sys.path.insert(0, 'tools')
from midi_event_scanner import parse_midi

div, tracks = parse_midi('assets/zelda1.mid')
# Regardons l'enchaînement temporel dans zelda1.mid :
# De t=0 à 1600 :
# Tr 6: Fanfare Lead [70, 65, 65, 70, 68, 66, 68]
# Tr 4: Arpèges montants [46(Bb), 53(F), 58(Bb), 44(Ab), 51(Eb), 56(Ab), 42(Gb), 49(Db), 54(Gb), 41(F), 48(C), 53(F)]
# Puis à t=1617 (après la fanfare intro) :
# Tr 2 et Tr 5 : Rythme de marche militaire (Bb, F)
# Tr 3: Le grand thème héroïque qui démarre à 2425 (Bb4=70, F4=65, Bb4=70, Bb4=70, C5=72, D5=74, Eb5=75, F5=77...)
# C'EST EXACTEMENT LA MUSIQUE ORIGINALE COMPLÈTE DE KOJI KONDO !
print("Tr 6 events (Fanfare):")
for e in tracks[5]:
    if e[1]: print(f"  t={e[0]:5d}, note={e[2]}")

print("Tr 3 events (Theme principal):")
for e in tracks[2][:30]:
    if e[1]: print(f"  t={e[0]:5d}, note={e[2]}")

