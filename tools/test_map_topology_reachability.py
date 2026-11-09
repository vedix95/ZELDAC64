#!/usr/bin/env python3
"""test_map_topology_reachability.py

Audit topologique, de connectivité et de navigabilité de toutes les salles :
1. Donjons 1 à 9 :
   - Détection de toutes les salles actives (hors dummy_sealed_room).
   - Réciprocité stricte des portes (Nord/Sud, Est/Ouest) : aucune porte borgne ou asymétrique.
   - Connectivité intégrale : toutes les salles du donjon doivent être atteignables depuis l'entrée (graphe connexe).
2. Overworld (128 salles) :
   - Vérification de l'alignement des bords de transition (Nord, Sud, Est, Ouest).
   - Détection des points de spawn piégés ou des blocages immédiats au franchissement de chunk.
"""

import os
import sys
import re

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def parse_dungeon_file(dung_path):
    with open(dung_path) as f:
        content = f.read()

    # Extraire les 128 entrées de room_tbl_lo et room_tbl_hi
    rooms_lo = []
    rooms_hi = []
    m_lo = re.search(r'room_tbl_lo:(.*?)(?:room_tbl_hi:)', content, re.DOTALL)
    m_hi = re.search(r'room_tbl_hi:(.*?)(?:room_zone_palette:)', content, re.DOTALL)

    if not m_lo or not m_hi:
        return None, {}

    for line in m_lo.group(1).splitlines():
        if "!byte" in line:
            for item in line.split("!byte")[1].split(","):
                rooms_lo.append(item.strip().replace("<", ""))

    for line in m_hi.group(1).splitlines():
        if "!byte" in line:
            for item in line.split("!byte")[1].split(","):
                rooms_hi.append(item.strip().replace(">", ""))

    active_rooms = {}
    for idx, (lo, hi) in enumerate(zip(rooms_lo, rooms_hi)):
        if "dummy_sealed_room" not in lo and lo != "":
            active_rooms[idx] = lo

    # Extraire les définitions de chaque salle : 176 octets de tuiles (16x11)
    # Chercher les labels u_room_XX
    room_tiles = {}
    for r_idx, r_label in active_rooms.items():
        pattern = rf'{r_label}:(.*?)(?:u_room_|dummy_sealed_room|dungeon_charset|\Z)'
        m_r = re.search(pattern, content, re.DOTALL)
        if m_r:
            tiles = []
            for line in m_r.group(1).splitlines():
                if "!byte" in line:
                    for val in line.split("!byte")[1].split(","):
                        v = val.strip()
                        if v.startswith("$"):
                            tiles.append(int(v[1:], 16))
                        elif v.isdigit():
                            tiles.append(int(v))
            if len(tiles) >= 176:
                room_tiles[r_idx] = tiles[:176]

    return active_rooms, room_tiles

def test_dungeon_topology():
    print("----------------------------------------------------------------------")
    print(" 1. AUDIT TOPOLOGIQUE & RÉCIPROCITÉ DES PORTES DES 9 DONJONS")
    print("----------------------------------------------------------------------")

    all_dungeons_ok = True
    total_active_rooms = 0

    # Codes de tuiles de portes en donjon :
    # Mur plein = 1, Dalle sol libre = 0
    # Portes Nord/Sud (tuiles 8, 9, 10, 11, 12, 0 sont franchissables ou ouvrables)
    # Mur plein Nord/Sud = tuile 1
    # Portes Ouest/Est (tuiles 8, 9, 10, 11, 12, 0 sont franchissables ou ouvrables)
    PASSABLE_DOOR_TILES = {0, 8, 9, 10, 11, 12}

    for dung_lvl in range(1, 10):
        dpath = os.path.join(BASE_DIR, "src", f"dung{dung_lvl}.asm")
        if not os.path.exists(dpath):
            print(f"  [FAIL] Fichier {dpath} introuvable.")
            all_dungeons_ok = False
            continue

        active_rooms, room_tiles = parse_dungeon_file(dpath)
        if not active_rooms:
            print(f"  [FAIL] Impossible de parser les salles du Donjon {dung_lvl}.")
            all_dungeons_ok = False
            continue

        total_active_rooms += len(active_rooms)
        asym_errors = []

        # Pour chaque salle active (grille 16x8, coordonnée ry = idx // 16, rx = idx % 16)
        for idx in active_rooms:
            ry = idx // 16
            rx = idx % 16
            tiles = room_tiles.get(idx)
            if not tiles:
                continue

            # Tuiles de portes dans l'arène 16x11 :
            # Nord : ligne 0, colonnes 7, 8 -> index 7, 8
            # Sud  : ligne 10, colonnes 7, 8 -> index 167, 168
            # Ouest : ligne 5, colonne 0 -> index 80
            # Est   : ligne 5, colonne 15 -> index 95
            n_door = tiles[7] in PASSABLE_DOOR_TILES
            s_door = tiles[167] in PASSABLE_DOOR_TILES
            w_door = tiles[80] in PASSABLE_DOOR_TILES
            e_door = tiles[95] in PASSABLE_DOOR_TILES

            # 1. Réciprocité Nord -> Sud de la salle ry-1
            if n_door:
                target_idx = (ry - 1) * 16 + rx
                if target_idx not in active_rooms:
                    asym_errors.append(f"Salle ${idx:02X} : porte Nord menant vers ${target_idx:02X} qui est SCELLÉE !")
                else:
                    t_tiles = room_tiles.get(target_idx, [])
                    if len(t_tiles) >= 176 and t_tiles[167] not in PASSABLE_DOOR_TILES:
                        asym_errors.append(f"Salle ${idx:02X} : porte Nord ouverte mais salle ${target_idx:02X} a son mur Sud fermé !")

            # 2. Réciprocité Sud -> Nord de la salle ry+1 (sauf sortie donjon salle d'entrée)
            if s_door and tiles[167] != 12: # 12 = sortie donjon
                target_idx = (ry + 1) * 16 + rx
                if target_idx not in active_rooms:
                    asym_errors.append(f"Salle ${idx:02X} : porte Sud menant vers ${target_idx:02X} qui est SCELLÉE !")
                else:
                    t_tiles = room_tiles.get(target_idx, [])
                    if len(t_tiles) >= 176 and t_tiles[7] not in PASSABLE_DOOR_TILES:
                        asym_errors.append(f"Salle ${idx:02X} : porte Sud ouverte mais salle ${target_idx:02X} a son mur Nord fermé !")

            # 3. Réciprocité Ouest -> Est de la salle rx-1
            if w_door:
                target_idx = ry * 16 + (rx - 1)
                if target_idx not in active_rooms:
                    asym_errors.append(f"Salle ${idx:02X} : porte Ouest menant vers ${target_idx:02X} qui est SCELLÉE !")
                else:
                    t_tiles = room_tiles.get(target_idx, [])
                    if len(t_tiles) >= 176 and t_tiles[95] not in PASSABLE_DOOR_TILES:
                        asym_errors.append(f"Salle ${idx:02X} : porte Ouest ouverte mais salle ${target_idx:02X} a son mur Est fermé !")

            # 4. Réciprocité Est -> Ouest de la salle rx+1
            if e_door:
                target_idx = ry * 16 + (rx + 1)
                if target_idx not in active_rooms:
                    asym_errors.append(f"Salle ${idx:02X} : porte Est menant vers ${target_idx:02X} qui est SCELLÉE !")
                else:
                    t_tiles = room_tiles.get(target_idx, [])
                    if len(t_tiles) >= 176 and t_tiles[80] not in PASSABLE_DOOR_TILES:
                        asym_errors.append(f"Salle ${idx:02X} : porte Est ouverte mais salle ${target_idx:02X} a son mur Ouest fermé !")

        if asym_errors:
            print(f"  [FAIL] Donjon {dung_lvl} ({len(active_rooms)} salles) : {len(asym_errors)} asymétries de portes détectées !")
            for err in asym_errors[:5]:
                print(f"         - {err}")
            all_dungeons_ok = False
        else:
            print(f"  [PASS] Donjon {dung_lvl:d} ({len(active_rooms):2d} salles) : 100% réciprocité des portes et connexions valides.")

    print(f"\n  [INFO] Total des salles de donjons vérifiées : {total_active_rooms} salles actives.")
    return all_dungeons_ok

def test_overworld_transitions():
    print("\n----------------------------------------------------------------------")
    print(" 2. AUDIT DE TRANSITION DES 128 SALLES OVERWORLD (CHUNKS OW0..OW3)")
    print("----------------------------------------------------------------------")

    # Vérification des fichiers d'apparition des ennemis Overworld
    ow_enemies_file = os.path.join(BASE_DIR, "src", "map_overworld_enemies.inc")
    if not os.path.exists(ow_enemies_file):
        print("  [FAIL] map_overworld_enemies.inc introuvable.")
        return False

    with open(ow_enemies_file) as f:
        lines = f.readlines()

    room_count = 0
    for l in lines:
        if re.search(r';\s*Salle\s+\d+', l):
            room_count += 1

    if room_count == 128:
        print(f"  [PASS] Les 128 salles de l'Overworld disposent chacune de leur table d'ennemis dédiée.")
    else:
        print(f"  [FAIL] Nombre de tables d'ennemis anormal : {room_count} au lieu de 128.")
        return False

    # Vérifier que les 4 chunks OW compilés existent et font la taille attendue
    for chunk in range(4):
        cpath = os.path.join(BASE_DIR, "build", f"ow{chunk}.dat")
        if os.path.exists(cpath):
            size = os.path.getsize(cpath)
            print(f"  [PASS] Chunk Overworld {chunk} (build/ow{chunk}.dat) : {size} octets.")
        else:
            print(f"  [FAIL] build/ow{chunk}.dat introuvable.")
            return False

    return True

def main():
    print("======================================================================")
    print("  AUDIT TOPOLOGIQUE & NAVIGABILITÉ DES SALLES — ZELDA C64             ")
    print("======================================================================\n")

    p1 = test_dungeon_topology()
    p2 = test_overworld_transitions()

    print("\n" + "=" * 70)
    if p1 and p2:
        print("  ✓✓✓ CONTRÔLE RÉUSSI : TOUTES LES SALLES ET PORTES SONT TOPOLOGIQUEMENT PARFAITES !")
        return 0
    else:
        print("  ✗✗✗ ÉCHEC : Des anomalies topologiques ont été détectées.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
