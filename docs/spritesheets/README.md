# Sprites C64 Zelda - Documentation

Ce dossier contient tous les sprites extraits du jeu C64 Zelda.

## Fichiers disponibles

- `enemies.png` - Planche de tous les ennemis (sprites)
- `tiles.png` - Planche de toutes les tuiles de fond
- `animations.png` - Animations des attaques et effets spéciaux
- `items.png` - Sprites d'objets, armes, potions
- `characters.png` - Link, Sheikah, NPCs

## Utilisation

Ces sprites peuvent être utilisés pour :
- Debugger les collisions
- Tester les animations
- Créer des mods du jeu
- Référence visuelle pendant le développement

## Générer de nouveaux sprites

```bash
# Extraire depuis la mémoire C64 dump
python3 sprite_extractor.py --extract-memory memory.dump

# Regénérer la planche complète  
python3 sprite_extractor.py --spritesheet all
```

---
**END**
