#!/usr/bin/env python3
"""
tools/capture_intro_full.py - Capture d'écran automatisée de toutes les phases de l'Intro NES :
1. Écran Titre (Waterfall + Grand Blason NES + Falaises brunes + Copyright blanc)
2. Story Scroll (Cadre de pierre officiel NES centré en défilement vertical)
3. Link brandissant la Triforce d'Or
4. Treasures Showcase (Défilé vertical des 35 trésors sur 2 colonnes)
5. Pancarte du Manuel ("PLEASE LOOK UP THE MANUAL FOR DETAILS.")
6. Monsters Showcase (Défilé vertical des 15 monstres d'Hyrule avec sprites et noms)
"""
import os
import subprocess
import glob

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
BUILD_DIR = os.path.join(BASE_DIR, "build")
DOCS_DIR = os.path.join(BASE_DIR, "docs")
os.makedirs(DOCS_DIR, exist_ok=True)

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

def convert_image(base_name):
    for ext in [".pcx", ".bmp", ".png.bmp", ".png.pcx"]:
        candidate = base_name + ext if not base_name.endswith(ext) else base_name
        if os.path.exists(candidate):
            subprocess.run(["magick", candidate, base_name], check=True)
            if candidate != base_name:
                os.remove(candidate)
            print(f"  [+] Converti : {base_name}")
            return

def main():
    intro_vs = os.path.join(BUILD_DIR, "intro.vs")
    labels = load_labels(intro_vs)

    sid_menu_addr = labels.get('sid_setup_menu_loop', 0x573a)
    cursor_addr = labels.get('menu_cursor_idx', 0x09D5)
    intro_update_addr = labels.get('intro_update', 0x299b)
    inject_story = labels['intro_inject_story_line']
    setup_sign = labels['intro_setup_link_sign']
    inject_treasures = labels['intro_inject_treasure_step']
    inject_monsters = labels['intro_inject_monster_step']

    mon_file = "/tmp/capture_intro.mon"

    cap_title = os.path.join(DOCS_DIR, "intro_01_title_waterfall.png")
    cap_story = os.path.join(DOCS_DIR, "intro_02_story_scroll.png")
    cap_story2 = os.path.join(DOCS_DIR, "intro_03_story_scroll2.png")
    cap_treasures = os.path.join(DOCS_DIR, "intro_04_treasures_scroll.png")
    cap_sign = os.path.join(DOCS_DIR, "intro_05_manual_sign.png")
    cap_monsters = os.path.join(DOCS_DIR, "intro_06_monsters_scroll.png")

    with open(mon_file, "w") as f:
        # Boot et sélection Mono SID (Option 1)
        f.write(f"bk {sid_menu_addr:04x}\n")
        f.write("g\n")
        f.write("del\n")
        f.write(f"> {cursor_addr:04x} 00\n")
        f.write("> 0816 01\n")

        # 1. Capture Title Screen Waterfall (après ~80 frames pour voir la cascade animée)
        f.write(f"bk {intro_update_addr:04x}\n")
        f.write("g\n")
        for _ in range(80):
            f.write("g\n")
        f.write(f'screenshot "{cap_title}"\n')
        f.write("del\n")

        # 2. Capture Story Scroll (après 10 pas d'histoire en train de monter)
        f.write(f"bk {inject_story:04x}\n")
        for _ in range(10):
            f.write("g\n")
        f.write("del\n")
        f.write(f"bk {intro_update_addr:04x}\n")
        for _ in range(5):
            f.write("g\n")
        f.write(f'screenshot "{cap_story}"\n')
        f.write("del\n")

        # 3. Capture Story Scroll Suite (après 8 pas supplémentaires, histoire continue sans Link)
        f.write(f"bk {inject_story:04x}\n")
        for _ in range(8):
            f.write("g\n")
        f.write("del\n")
        f.write(f"bk {intro_update_addr:04x}\n")
        for _ in range(5):
            f.write("g\n")
        f.write(f'screenshot "{cap_story2}"\n')
        f.write("del\n")

        # 4. Capture Défilé des Trésors
        f.write(f"bk {inject_treasures:04x}\n")
        for _ in range(14):
            f.write("g\n")
        f.write("del\n")
        f.write(f"bk {intro_update_addr:04x}\n")
        for _ in range(5):
            f.write("g\n")
        f.write(f'screenshot "{cap_treasures}"\n')
        f.write("del\n")

        # 5. Capture Pancarte Manuel
        f.write(f"bk {setup_sign:04x}\n")
        f.write("g\n")
        f.write("del\n")
        f.write(f"bk {intro_update_addr:04x}\n")
        for _ in range(15):
            f.write("g\n")
        f.write(f'screenshot "{cap_sign}"\n')
        f.write("del\n")

        # 6. Capture Défilé des Monstres (après ~24 pas pour voir 5-6 monstres simultanés)
        f.write(f"bk {inject_monsters:04x}\n")
        for _ in range(24):
            f.write("g\n")
        f.write("del\n")
        f.write(f"bk {intro_update_addr:04x}\n")
        for _ in range(5):
            f.write("g\n")
        f.write(f'screenshot "{cap_monsters}"\n')
        f.write("del\n")

        f.write("q\n")

    cmd = [
        "x64sc", "-default", "-warp",
        "-moncommands", mon_file,
        "-cartcrt", os.path.join(BUILD_DIR, "zelda.crt")
    ]
    print("[*] Lancement de VICE pour captures d'écran de l'Introduction...")
    res = subprocess.run(cmd, capture_output=True, text=True, timeout=75)

    # Conversion magick pcx/bmp -> png
    for base in [cap_title, cap_story, cap_story2, cap_treasures, cap_sign, cap_monsters]:
        convert_image(base)

    print("[✓] Captures terminées avec succès dans docs/ !")

if __name__ == "__main__":
    main()
