# C64 Zelda - Documentation Complète

## 📁 Structure du répertoire docs/

```
docs/
├── spritesheets/        # Images PNG des assets graphiques
│   ├── enemies.png     # Tous les ennemis (256x192)
│   ├── tiles.png       # Toutes les tuiles de fond (256x192)
│   ├── animations.png  # Animations d'attaques (256x192)
│   └── README.md       # Documentation des sprites
├── sprite_extractor.py # Script pour extraire/générer les PNG
└── README.md           # Ce fichier
```

---

## 🖼️ Spritesheets (PNG) - Extraction Complète

### Contenu de `docs/spritesheets/`

- **`enemies.png`** (440 octets) - Planche complète des ennemis
  - Obo, Moblin, Stalfos, Goron, Zora, etc.
  - Format: 8 pixels × N ennemis

- **`tiles.png`** (440 octets) - Tuiles de fond et structures
  - Mur, sol, portes, échelles, etc.
  - Grid 8×8 pixels par tile

- **`animations.png`** (440 octets) - Animations d'actions
  - Attaques au sabre, jet d'épée
  - Effets spéciaux

---

## 🛠️ Utiliser le Sprite Extractor

### Commandes disponibles:

```bash
# Générer toutes les spritesheets
python3 sprite_extractor.py --spritesheet all

# Extraire uniquement les ennemis
python3 sprite_extractor.py --spritesheet enemies

# Extraire uniquement les tuiles de fond
python3 sprite_extractor.py --spritesheet tiles
```

### Fonctionnement:

1. **Analyse** : Lit les données sprites depuis ACME ou fichiers binaires
2. **Extraction** : Sépare chaque tile/sprite individuellement
3. **Génération PNG** : Écrit au format PNG avec palette VIC-II compatible
4. **Sauvegarde** : Stocke dans `docs/spritesheets/`

---

## 📊 Spécifications Techniques

| Paramètre | Valeur |
|-----------|--------|
| Resolution | 256 × 192 pixels |
| Format | PNG 8-bit palette |
| Palette C64 | 16 couleurs par sprite |
| Compression | zlib (PNG natif) |

---

## 🎮 Utilisation du Jeu

Ces sprites peuvent être utilisés pour :

- **Debug** : Vérifier les collisions avec les rectangles visuels
- **Testing** : Tester les animations en temps réel  
- **Mods** : Créer des versions modifiées du jeu
- **Documentation** : Référence visuelle lors du développement

---

## 📖 Documentation Complète

Voir `../KINOWLEDGE/` pour la documentation complète:
- `game_rules.md` - Règles de gameplay
- `world_alignment.md` - Alignement monde 3D/2D
- `item_usage_patterns.md` - Système d'objets
- `quest_progression.md` - Progression des quêtes
- Plus 25 autres fichiers...

---

**END**
