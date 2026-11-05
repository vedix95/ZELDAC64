#!/usr/bin/env python3
import subprocess
import os
import time

BASE_DIR = "/home/vedix/Documents/C64/zelda"
OUT_DIR = "/home/vedix/.gemini/antigravity-cli/brain/948c3f56-813e-4558-8dcf-700117d0de02"
os.makedirs(OUT_DIR, exist_ok=True)

def load_labels(vs_path):
    labels = {}
    with open(vs_path) as f:
        for line in f:
            parts = line.strip().split()
            if len(parts) >= 3 and parts[0] == 'al':
                addr = int(parts[1].split(':')[-1], 16)
                name = parts[2].lstrip('.')
                labels[name] = addr
    return labels

labels = load_labels(os.path.join(BASE_DIR, "build", "zelda.vs"))
intro_labels = load_labels(os.path.join(BASE_DIR, "build", "intro.vs"))
cmd_addr = labels['debug_hook_cmd']
arg_addr = labels['debug_hook_arg']
arg2_addr = labels['debug_hook_arg2']
main_addr = labels['main_loop']
px_addr = labels['player_x']
py_addr = labels['player_y']
launch_addr = intro_labels['launch_zelda_game']

mon_file = "/tmp/test_zelda_fixes.mon"
with open(mon_file, "w") as f:
    # 0. Démarrage cartouche & passage intro via résolution dynamique
    f.write("break 080d\n")
    f.write("g\n")
    f.write(f"g {launch_addr:04x}\n")

    # 1. Arrivée dans main_loop
    f.write(f"break {main_addr:04x}\n")
    f.write("g\n")

    # 2. Donner tout l'équipement (bombes, etc.)
    f.write(f"> {cmd_addr:04x} 07\n")
    f.write("g\n")

    # Capture 1 : Écran de départ avec Link et monstres
    f.write(f'screenshot "{os.path.join(OUT_DIR, "01_overworld_start.png")}" 2\n')

    # 4. Poser une bombe (hook_use_item = 5, arg = 1 (ITEM_BOMB))
    f.write(f"> {arg_addr:04x} 01\n")
    f.write(f"> {cmd_addr:04x} 05\n")
    f.write("g\n")

    # Attendre 25 frames pour voir la mèche de la bombe
    for _ in range(25):
        f.write("g\n")
    f.write(f'screenshot "{os.path.join(OUT_DIR, "02_bomb_ticking.png")}" 2\n')

    # Attendre l'explosion (25 frames de plus)
    for _ in range(25):
        f.write("g\n")
    f.write(f'screenshot "{os.path.join(OUT_DIR, "03_bomb_exploding.png")}" 2\n')

    # Attendre fin de l'explosion
    for _ in range(25):
        f.write("g\n")
    f.write(f'screenshot "{os.path.join(OUT_DIR, "04_bomb_ended.png")}" 2\n')

    # 5. Tester Transition d'écran vers la droite
    # Placer Link près du bord droit (X=284, Y=160)
    f.write(f"> {px_addr:04x} 1c 01\n")  # X = 284 ($011C)
    f.write(f"> {py_addr:04x} a0\n")     # Y = 160 ($A0)
    # Simuler joystick droite pendant 10 frames
    f.write(f"> {arg_addr:04x} 08\n")    # JOY_RIGHT = $08
    f.write(f"> {arg2_addr:04x} 0a\n")   # 10 frames
    f.write(f"> {cmd_addr:04x} 06\n")    # hook_force_joy
    for _ in range(15):
        f.write("g\n")
    f.write(f'screenshot "{os.path.join(OUT_DIR, "05_transition_start.png")}" 2\n')

    # Milieu de transition
    for _ in range(20):
        f.write("g\n")
    f.write(f'screenshot "{os.path.join(OUT_DIR, "06_transition_mid.png")}" 2\n')

    # Fin de transition
    for _ in range(30):
        f.write("g\n")
    f.write(f'screenshot "{os.path.join(OUT_DIR, "07_transition_finished.png")}" 2\n')

    # 6. Tester Transition vers le haut (changement de chunk vertical 2 -> 1)
    # Placer Link près du bord haut (X=160, Y=86)
    f.write(f"> {px_addr:04x} a0 00\n")  # X = 160 ($00A0)
    f.write(f"> {py_addr:04x} 56\n")     # Y = 86 ($56)
    f.write(f"> {arg_addr:04x} 01\n")    # JOY_UP = $01
    f.write(f"> {arg2_addr:04x} 0a\n")   # 10 frames
    f.write(f"> {cmd_addr:04x} 06\n")    # hook_force_joy
    for _ in range(15):
        f.write("g\n")
    f.write(f'screenshot "{os.path.join(OUT_DIR, "08_transition_up_chunk.png")}" 2\n')

    for _ in range(35):
        f.write("g\n")
    f.write(f'screenshot "{os.path.join(OUT_DIR, "09_transition_up_done.png")}" 2\n')

    # 7. Tester les collisions dans la nouvelle salle (bloqué contre l'arbre à X=133..134)
    # Placer Link devant un arbre solide de la salle active et pousser vers l'arbre
    f.write(f"> {px_addr:04x} 7d 00\n")  # X = 125
    f.write(f"> {py_addr:04x} a2\n")     # Y = 162 (Row 5)
    f.write(f"> {arg_addr:04x} 08\n")    # JOY_RIGHT = $08
    f.write(f"> {arg2_addr:04x} 1e\n")   # 30 frames
    f.write(f"> {cmd_addr:04x} 06\n")    # hook_force_joy
    for _ in range(35):
        f.write("g\n")
    f.write(f'screenshot "{os.path.join(OUT_DIR, "10_collision_blocked_by_tree.png")}" 2\n')

    f.write("q\n")

print(f"Generated {mon_file}")
cmdline = [
    "x64sc",
    "-default",
    "-cartcrt", os.path.join(BASE_DIR, "build", "zelda.crt"),
    "-moncommands", mon_file,
    "+sound",
    "-warp"
]
print("Running VICE test...")
t0 = time.time()
res = subprocess.run(cmdline, capture_output=True, text=True, timeout=20)
elapsed = time.time() - t0
print(f"VICE finished in {elapsed:.1f}s with return code {res.returncode}")

screenshots = [
    "01_overworld_start.png",
    "02_bomb_ticking.png",
    "03_bomb_exploding.png",
    "04_bomb_ended.png",
    "05_transition_start.png",
    "06_transition_mid.png",
    "07_transition_finished.png",
    "08_transition_up_chunk.png",
    "09_transition_up_done.png",
    "10_collision_blocked_by_tree.png"
]

all_ok = True
for s in screenshots:
    p = os.path.join(OUT_DIR, s)
    if os.path.exists(p) and os.path.getsize(p) > 0:
        print(f"✓ OK: {s} ({os.path.getsize(p)} bytes)")
    else:
        print(f"✗ MANQUANT: {s}")
        all_ok = False

if all_ok:
    print("\n[SUCCESS] Tous les scénarios de test ont été exécutés et capturés avec succès !")
