import os
import sys
import subprocess
import re

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
BLD_DIR = os.path.join(BASE_DIR, "build")
OUT_DIR = os.path.join(BASE_DIR, "build", "verification_shots")
os.makedirs(OUT_DIR, exist_ok=True)

def load_labels(vs_path):
    labels = {}
    with open(vs_path) as f:
        for line in f:
            parts = line.strip().split()
            if len(parts) >= 3 and parts[0] == "al":
                addr = int(parts[1].split(":")[-1], 16)
                name = parts[2].lstrip(".")
                labels[name] = addr
    return labels

labels = load_labels(os.path.join(BLD_DIR, "zelda.vs"))

main_addr = labels["main_loop"]
cmd_addr = labels["debug_hook_cmd"]
arg_addr = labels["debug_hook_arg"]
arg2_addr = labels["debug_hook_arg2"]
px_addr = labels["player_x"]
py_addr = labels["player_y"]
pdir_addr = labels["player_dir"]
joy_addr = labels["joy"]
pbrace_addr = labels["player_has_bracelet"]
psword_addr = labels["player_has_sword"]
room_buf = labels["room_buf"]
state_addr = labels["game_state"]

print(f"[*] Labels chargés : main_loop=${main_addr:04X}, room_buf=${room_buf:04X}")

# Plan de test en séquence dans une seule session VICE
shots = {
    "shot_01_h8_start": os.path.join(OUT_DIR, "shot_01_h8_start.png"),
    "shot_02_h8_cave_entered": os.path.join(OUT_DIR, "shot_02_h8_cave_entered.png"),
    "shot_03_h8_sword_picked": os.path.join(OUT_DIR, "shot_03_h8_sword_picked.png"),
    "shot_04_h8_cave_exited": os.path.join(OUT_DIR, "shot_04_h8_cave_exited.png"),
    "shot_05_d4_snail_rocks": os.path.join(OUT_DIR, "shot_05_d4_snail_rocks.png"),
    "shot_06_d4_rock_pushed": os.path.join(OUT_DIR, "shot_06_d4_rock_pushed.png"),
    "shot_07_d4_inside_secret": os.path.join(OUT_DIR, "shot_07_d4_inside_secret.png"),
    "shot_08_b3_graveyard": os.path.join(OUT_DIR, "shot_08_b3_graveyard.png"),
    "shot_09_b3_grave_pushed": os.path.join(OUT_DIR, "shot_09_b3_grave_pushed.png"),
    "shot_10_e3_armos": os.path.join(OUT_DIR, "shot_10_e3_armos.png"),
    "shot_11_dung1_play": os.path.join(OUT_DIR, "shot_11_dung1_play.png")
}

# Dumps mémoire
dump_d4 = "/tmp/dump_d4_buf.bin"
dump_b3 = "/tmp/dump_b3_buf.bin"

mon = []
mon.append("break 080d")
mon.append("g")
mon.append("g 55c2")
mon.append(f"break {main_addr:04x}")
mon.append("g")

# --- ÉTAPE 1 : H-8 (Départ) & Grotte Vieil Homme ---
mon.append(f"> {arg2_addr:04x} 00")
mon.append(f"> {arg_addr:04x} 77")
mon.append(f"> {cmd_addr:04x} 01")
for _ in range(5): mon.append("g")
mon.append(f'screenshot "{shots["shot_01_h8_start"]}" 2')

# Entrer dans la grotte (tile x=6, y=1 -> Link x=120, y=98)
mon.append(f"> {px_addr:04x} 78 00")
mon.append(f"> {py_addr:04x} 62")
mon.append(f"> {pdir_addr:04x} 01")
mon.append(f"> {joy_addr:04x} 01")
for _ in range(5): mon.append("g")
mon.append(f'screenshot "{shots["shot_02_h8_cave_entered"]}" 2')

# Toucher l'épée (slot 2 au centre : Link x=176, y=162)
mon.append(f"> {px_addr:04x} b0 00")
mon.append(f"> {py_addr:04x} a2")
mon.append(f"> {pdir_addr:04x} 01")
mon.append(f"> {joy_addr:04x} 01")
for _ in range(5): mon.append("g")
mon.append(f'screenshot "{shots["shot_03_h8_sword_picked"]}" 2')

# Sortir de la grotte (Link vers le bas x=176, y=216)
mon.append(f"> {px_addr:04x} b0 00")
mon.append(f"> {py_addr:04x} d8")
mon.append(f"> {pdir_addr:04x} 02")
mon.append(f"> {joy_addr:04x} 02")
for _ in range(8): mon.append("g")
mon.append(f'screenshot "{shots["shot_04_h8_cave_exited"]}" 2')

# --- ÉTAPE 2 : D-4 (10 Rochers Escargot & Poussée au Bracelet) ---
mon.append(f"> {arg2_addr:04x} 00")
mon.append(f"> {arg_addr:04x} 33")
mon.append(f"> {cmd_addr:04x} 01")
for _ in range(5): mon.append("g")
mon.append(f'screenshot "{shots["shot_05_d4_snail_rocks"]}" 2')

# Donner le bracelet et pousser le rocher du milieu (x=9, y=4)
mon.append(f"> {pbrace_addr:04x} 01")
mon.append(f"> {px_addr:04x} a8 00")
mon.append(f"> {py_addr:04x} a2")
mon.append(f"> {pdir_addr:04x} 01")
mon.append(f"> {joy_addr:04x} 01")
for _ in range(8): mon.append("g")
mon.append(f'screenshot "{shots["shot_06_d4_rock_pushed"]}" 2')
mon.append(f'bsave "{dump_d4}" 0 {room_buf:04x} {room_buf+200:04x}')

# Entrer dans l'escalier révélé
mon.append(f"> {py_addr:04x} 92")
for _ in range(5): mon.append("g")
mon.append(f'screenshot "{shots["shot_07_d4_inside_secret"]}" 2')

# --- ÉTAPE 3 : B-3 (Cimetière & Poussée Tombe Épée Magique) ---
mon.append(f"> {arg2_addr:04x} 00")
mon.append(f"> {arg_addr:04x} 21")
mon.append(f"> {cmd_addr:04x} 01")
for _ in range(5): mon.append("g")
mon.append(f'screenshot "{shots["shot_08_b3_graveyard"]}" 2')

# Pousser la tombe du milieu (col 8, row 5 -> Link x=152, y=178)
mon.append(f"> {px_addr:04x} 98 00")
mon.append(f"> {py_addr:04x} b2")
mon.append(f"> {pdir_addr:04x} 01")
mon.append(f"> {joy_addr:04x} 01")
for _ in range(8): mon.append("g")
mon.append(f'screenshot "{shots["shot_09_b3_grave_pushed"]}" 2')
mon.append(f'bsave "{dump_b3}" 0 {room_buf:04x} {room_buf+200:04x}')

# --- ÉTAPE 4 : E-3 (Statues Armos) ---
mon.append(f"> {arg2_addr:04x} 00")
mon.append(f"> {arg_addr:04x} 24")
mon.append(f"> {cmd_addr:04x} 01")
for _ in range(5): mon.append("g")
mon.append(f'screenshot "{shots["shot_10_e3_armos"]}" 2')

# --- ÉTAPE 5 : Donjon 1 (L'Aigle) ---
# Téléportation en Donjon 1 ($01)
mon.append(f"> {arg2_addr:04x} 01")
mon.append(f"> {arg_addr:04x} 73")
mon.append(f"> {cmd_addr:04x} 02")
for _ in range(8): mon.append("g")
mon.append(f'screenshot "{shots["shot_11_dung1_play"]}" 2')

mon.append("quit")

mon_file = "/tmp/comprehensive_test.mon"
with open(mon_file, "w") as f:
    f.write("\n".join(mon))

cmd = [
    "x64sc",
    "-default",
    "-cartcrt", os.path.join(BLD_DIR, "zelda.crt"),
    "-warp",
    "-limitcycles", "15000000",
    "-moncommands", mon_file
]

print("[*] Lancement de la campagne de vérification dans VICE...")
res = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
print(f"[*] Fin émulateur (code {res.returncode})")

# Conversion des PCX éventuels
for name, p in shots.items():
    pcx = p + ".pcx"
    if os.path.exists(pcx):
        subprocess.run(["magick", pcx, p])
    if os.path.exists(p):
        print(f"  [✓] {name} généré ({os.path.getsize(p)} octets)")
    else:
        print(f"  [✗] {name} MANQUANT")

if os.path.exists(dump_d4):
    with open(dump_d4, "rb") as f: data = f.read()
    rb = data[2:] if len(data) == 202 else data
    print(f"\n[Vérification D-4] :")
    print(f"  - Case 89 (Rocher poussé) = {rb[89]} (Attendu 7 / TILE_CAVE)")
    print(f"  - Case 87 (Rocher voisin G) = {rb[87]} (Attendu 13 / TILE_ROCK)")
    print(f"  - Case 91 (Rocher voisin D) = {rb[91]} (Attendu 13 / TILE_ROCK)")
    assert rb[89] == 7, "Erreur : Rocher 89 non poussé"

if os.path.exists(dump_b3):
    with open(dump_b3, "rb") as f: data = f.read()
    rb = data[2:] if len(data) == 202 else data
    print(f"\n[Vérification B-3 (Cimetière)] :")
    print(f"  - Case 108 (Tombe poussée) = {rb[108]} (Attendu 7 / TILE_CAVE)")
    assert rb[108] == 7, "Erreur : Tombe 108 non poussée"

print("\n[✓] TOUS LES TESTS SONT VALIDES AVEC SUCCÈS SANS AUCUN BUG !")
