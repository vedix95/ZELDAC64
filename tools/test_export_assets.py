#!/usr/bin/env python3
"""
tools/test_export_assets.py : Test de validation automatisé du système
d'extraction et de génération d'atlas graphique (PNG avec légendes).
"""

import os
import subprocess
import sys

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
BUILD_DIR = os.path.join(BASE_DIR, "build")
SCRIPT_PATH = os.path.join(BASE_DIR, "tools", "export_assets_sheet.py")

PNG_MAGIC = b"\x89PNG\r\n\x1a\n"

def check_png(path, min_w=100, min_h=100):
    assert os.path.exists(path), f"Fichier introuvable: {path}"
    size = os.path.getsize(path)
    assert size > 1024, f"Fichier trop petit ({size} octets): {path}"
    with open(path, "rb") as f:
        header = f.read(8)
        assert header == PNG_MAGIC, f"En-tête PNG invalide dans {path}"
        # Lire IHDR (offset 16: largeur (4o), hauteur (4o))
        ihdr_chunk = f.read(16)
        w = int.from_bytes(ihdr_chunk[8:12], "big")
        h = int.from_bytes(ihdr_chunk[12:16], "big")
        assert w >= min_w, f"Largeur trop petite ({w} < {min_w}) dans {path}"
        assert h >= min_h, f"Hauteur trop petite ({h} < {min_h}) dans {path}"
    return w, h, size

def main():
    print("=" * 65)
    print("  TESTS AUTOMATISÉS : SYSTÈME D'EXTRACTION D'ATLAS GRAPHIQUE")
    print("=" * 65)

    # 1. Test génération complète (--all)
    print("\n[TEST 1] Exécution de export_assets_sheet.py --all...")
    cmd = [sys.executable, SCRIPT_PATH, "--all", "--out-dir", BUILD_DIR]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    assert res.returncode == 0, f"Échec d'exécution :\n{res.stderr}\n{res.stdout}"
    print("  [PASS] Script exécuté avec code de retour 0.")

    # 2. Vérification de la planche maîtresse
    print("\n[TEST 2] Validation de la planche maîtresse (atlas_all_assets.png)...")
    master_path = os.path.join(BUILD_DIR, "atlas_all_assets.png")
    w, h, sz = check_png(master_path, min_w=1920, min_h=3000)
    print(f"  [PASS] Planche maîtresse valide : {w}x{h} px, {sz:,} octets.")

    # 3. Vérification des planches spécialisées
    print("\n[TEST 3] Validation des planches spécialisées...")
    sheets = [
        ("sheet_tiles.png", 1920, 600),
        ("sheet_sprites_link.png", 1920, 300),
        ("sheet_sprites_enemies.png", 1920, 800),
        ("sheet_sprites_items.png", 1920, 300),
        ("sheet_animations.png", 1920, 800),
    ]
    for s_name, exp_w, exp_h in sheets:
        s_path = os.path.join(BUILD_DIR, s_name)
        w, h, sz = check_png(s_path, min_w=exp_w, min_h=exp_h)
        print(f"  [PASS] {s_name:<26} : {w}x{h} px, {sz:,} octets.")

    # 4. Test d'exportation unitaire avec argument CLI spécifique (--animations)
    print("\n[TEST 4] Test de l'argument CLI unitaire (--animations)...")
    anim_only_dir = os.path.join(BUILD_DIR, "test_anim_only")
    os.makedirs(anim_only_dir, exist_ok=True)
    cmd_anim = [sys.executable, SCRIPT_PATH, "--animations", "--out-dir", anim_only_dir]
    res_anim = subprocess.run(cmd_anim, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    assert res_anim.returncode == 0, f"Erreur unitaire CLI: {res_anim.stderr}"
    anim_file = os.path.join(anim_only_dir, "sheet_animations.png")
    w, h, sz = check_png(anim_file, min_w=1920, min_h=800)
    # Vérifier que les autres fichiers ne sont pas créés
    assert not os.path.exists(os.path.join(anim_only_dir, "atlas_all_assets.png"))
    print(f"  [PASS] Export ciblé --animations validé ({w}x{h} px).")

    # Nettoyage dossier test temporaire
    if os.path.exists(anim_file):
        os.remove(anim_file)
    if os.path.exists(anim_only_dir):
        os.rmdir(anim_only_dir)

    print("\n" + "=" * 65)
    print("   ✓✓✓ TOUS LES TESTS D'EXTRACTION D'ATLAS SONT VALIDÉS !")
    print("=" * 65)

if __name__ == "__main__":
    main()
