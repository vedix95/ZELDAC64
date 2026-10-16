import sys
sys.path.insert(0, 'tools')
from midi_event_scanner import parse_midi
import math

def sid(m):
    if not m or m == 0: return 0
    hz = 440.0 * (2.0 ** ((m - 69.0) / 12.0))
    return int(round(hz * 17.0284))

div, tracks = parse_midi('assets/zelda1.mid')

# Dans zelda1.mid :
# 1 tick = 25 ticks step
# Regardons l'activité des notes par step de 25 ticks pour construire les 3 voix
step_size = 25
max_time = 12000
num_steps = max_time // step_size

# Pistes de zelda1.mid :
# Tr 6 : Fanfare lead (t < 1617)
# Tr 3 : Main theme lead (t >= 1617)
# Tr 4 : Arpèges intro (t < 1617) et Basse
# Tr 5 / Tr 2 : Rythme de marche

v1_grid = [0] * num_steps
v2_grid = [0] * num_steps
v3_grid = [0] * num_steps # noise/percussion ou basse

# Remplir V1 (Lead) :
for e in tracks[5]: # Tr 6
    if e[1] and e[0] < 1617:
        step = round(e[0] / step_size)
        if step < num_steps: v1_grid[step] = e[2]

for e in tracks[2]: # Tr 3
    if e[1] and e[0] >= 1617:
        step = round(e[0] / step_size)
        if step < num_steps: v1_grid[step] = e[2]

# Remplir V2 (Harmonie / Arpèges / Contre-chant) :
for e in tracks[3]: # Tr 4
    if e[1]:
        step = round(e[0] / step_size)
        if step < num_steps: v2_grid[step] = e[2]

# Remplir V3 (Rythme / Percussion militaire) :
for e in tracks[1]: # Tr 2
    if e[1]:
        step = round(e[0] / step_size)
        if step < num_steps: v3_grid[step] = 1 # snare hit

# Propageons les notes tenues (legato / sustain)
# Pour V1 :
cur_v1 = 0
v1_held = [0] * num_steps
v1_trigger = [0] * num_steps
for s in range(num_steps):
    if v1_grid[s] != 0:
        cur_v1 = v1_grid[s]
        v1_trigger[s] = 1
    v1_held[s] = cur_v1

# Pour V2 :
cur_v2 = 0
v2_held = [0] * num_steps
v2_trigger = [0] * num_steps
for s in range(num_steps):
    if v2_grid[s] != 0:
        cur_v2 = v2_grid[s]
        v2_trigger[s] = 1
    v2_held[s] = cur_v2

print(f"Quantized {num_steps} steps.")
print("V1 triggers count:", sum(v1_trigger))
print("V2 triggers count:", sum(v2_trigger))
print("V3 triggers count:", sum(v3_grid))

