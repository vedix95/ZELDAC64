#!/usr/bin/env python3
"""
tools/editor.py - Éditeur de niveau visuel en Python pour Zelda C64.

Édition à la souris des tuiles de la carte, positionnement des ennemis et des salles,
sauvegarde automatique dans assets/world.txt et src/enemies.asm, recompilation
et lancement direct dans l'émulateur VICE.

100% autonome : aucune dépendance externe requise (utilise http.server de la lib standard).
Usage :
    python3 tools/editor.py [--port 8080] [--no-browser]
"""

import argparse
import http.server
import json
import os
import re
import socketserver
import subprocess
import sys
import threading
import time
import urllib.parse
import webbrowser

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

COLOR_NAMES = ("black white red cyan purple green blue yellow orange brown "
               "lred dgrey grey lgreen lblue lgrey").split()
COLORS = {n: i for i, n in enumerate(COLOR_NAMES)}
PALETTE = [
    "#000000", "#ffffff", "#68372b", "#70a4b2",
    "#6f3d86", "#588d43", "#352879", "#b8c76f",
    "#6f4f25", "#433900", "#9a6759", "#444444",
    "#6c6c6c", "#9ad284", "#6c5eb5", "#959595"
]

ROOM_NAMES = [
    ["(0, 0) Grotte Montagne",  "(1, 0) Sanctuaire Nord",     "(2, 0) Lac Bleu"],
    ["(0, 1) Forêt Ouest",      "(1, 1) Le Carrefour",        "(2, 1) Rivage Est"],
    ["(0, 2) Bosquet Perdu",    "(1, 2) Départ - Zelda 1",    "(2, 2) Labyrinthe"]
]

ACTOR_SPRITES = {
    "link": [
        "..gggg..",
        ".gggggg.",
        "gggggggg",
        "gggggggg",
        "bbssssbb",
        "bsbssbsb",
        ".ssssss.",
        "..ssss..",
        "sggggss.",
        "sggggbs.",
        "sggggss.",
        ".bbsbb..",
        ".gggggg.",
        ".gggggg.",
        ".bb.....",
        ".bb..bb."
    ],
    "octo": [
        ".gg..gg.",
        "gggggggg",
        "gggggggg",
        "gssggssg",
        "gsbggsbg",
        "gggggggg",
        "ggsbbggg",
        "ggsbbggg",
        ".gggggg.",
        "gggggggg",
        "gggggggg",
        ".gggggg.",
        ".g....g.",
        ".gg..gg.",
        "bgg..ggb",
        "..b..b.."
    ],
    "moblin": [
        "s.gggg..",
        "s.gssg.s",
        "..ssss.b",
        ".bsbsb.b",
        ".bssss.b",
        "..ssss.b",
        ".ggggg.b",
        "gggggggb",
        "gggggg.b",
        ".ggggg.b",
        ".bbbbb.b",
        ".gg.gg.b",
        ".gg.gg..",
        ".bb.bb..",
        ".bb.....",
        "........"
    ]
}


def parse_tiles():
    path = os.path.join(BASE_DIR, "assets/tiles.txt")
    cfg = {}
    tiles = []
    cur = None
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith(";"):
                continue
            if line.startswith("["):
                head, _, rest = line.partition("]")
                parts = rest.split()
                name = head[1:].strip()
                sym = parts[0]
                col_name = parts[1]
                col_idx = COLORS.get(col_name, 0)
                solid = "solid" in parts[2:]
                cur = {
                    "name": name,
                    "symbol": sym,
                    "color_name": col_name,
                    "color_idx": col_idx,
                    "solid": solid,
                    "rows": []
                }
                tiles.append(cur)
            elif ":" in line:
                k, _, v = line.partition(":")
                k, v = k.strip(), v.strip()
                if k in ("bg", "mc1", "mc2") and v in COLORS:
                    cfg[k] = COLORS[v]
            elif cur is not None and len(line) == 8:
                cur["rows"].append(line)
    return cfg, tiles


def parse_world():
    path = os.path.join(BASE_DIR, "assets/world.txt")
    with open(path, "r", encoding="utf-8") as f:
        lines = [l.rstrip("\r\n") for l in f]

    rooms = [[["" for _ in range(10)] for _ in range(3)] for _ in range(3)]
    map_lines = [l for l in lines if not l.startswith(";") and l.strip()]

    for idx, l in enumerate(map_lines):
        r = idx // 10
        y = idx % 10
        rooms[r][0][y] = l[0:20]
        rooms[r][1][y] = l[21:41]
        rooms[r][2][y] = l[42:62]
    return rooms


def parse_enemies():
    path = os.path.join(BASE_DIR, "src/enemies.asm")
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()

    enemy_line_re = re.compile(
        r'!\s*byte\s+(TYPE_[A-Z]+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(TYPE_[A-Z]+)\s*,\s*(\d+)\s*,\s*(\d+)'
    )
    matches = list(enemy_line_re.finditer(text))
    enemies = []
    for m in matches:
        t0, x0, y0, t1, x1, y1 = m.groups()
        enemies.append([
            {"type": t0, "x": int(x0), "y": int(y0)},
            {"type": t1, "x": int(x1), "y": int(y1)}
        ])
    return enemies


def parse_start_config():
    tilemap_path = os.path.join(BASE_DIR, "src/tilemap.asm")
    start_rx, start_ry = 1, 2
    if os.path.exists(tilemap_path):
        with open(tilemap_path, "r", encoding="utf-8") as f:
            tm_text = f.read()
        mx = re.search(r'START_ROOM_X\s*=\s*(\d+)', tm_text)
        my = re.search(r'START_ROOM_Y\s*=\s*(\d+)', tm_text)
        if mx:
            start_rx = int(mx.group(1))
        if my:
            start_ry = int(my.group(1))

    player_path = os.path.join(BASE_DIR, "src/player.asm")
    px, py = 180, 150
    if os.path.exists(player_path):
        with open(player_path, "r", encoding="utf-8") as f:
            p_text = f.read()
        mx = re.search(r'player_x:\s*!word\s*(\d+)', p_text)
        my = re.search(r'player_y:\s*!byte\s*(\d+)', p_text)
        if mx:
            px = int(mx.group(1))
        if my:
            py = int(my.group(1))

    tile_x = max(0, min(19, (px - 24) // 16))
    tile_y = max(0, min(9, (py - 82) // 16))

    return {
        "start_room": {"x": start_rx, "y": start_ry},
        "player": {"x": px, "y": py, "tile_x": tile_x, "tile_y": tile_y}
    }


def save_world_data(rooms):
    path = os.path.join(BASE_DIR, "assets/world.txt")
    with open(path, "r", encoding="utf-8") as f:
        orig = f.read()
    lines = orig.splitlines()

    map_indices = []
    for i, l in enumerate(lines):
        if not l.startswith(";") and l.strip():
            map_indices.append(i)

    new_lines = list(lines)
    for idx, line_num in enumerate(map_indices):
        r = idx // 10
        y = idx % 10
        new_lines[line_num] = f"{rooms[r][0][y]} {rooms[r][1][y]} {rooms[r][2][y]}"

    reconstructed = "\n".join(new_lines) + ("\n" if orig.endswith("\n") else "")
    with open(path, "w", encoding="utf-8") as f:
        f.write(reconstructed)


def save_enemies_data(enemies):
    path = os.path.join(BASE_DIR, "src/enemies.asm")
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()

    lines_out = []
    for i, en_pair in enumerate(enemies):
        rx, ry = i % 3, i // 3
        e0, e1 = en_pair[0], en_pair[1]
        rname = ROOM_NAMES[ry][rx]
        lines_out.append(f"        ; Salle {i} : {rname}")
        lines_out.append(
            f"        !byte {e0['type']:<10}, {int(e0['x']):3d}, {int(e0['y']):2d},   "
            f"{e1['type']:<10}, {int(e1['x']):4d}, {int(e1['y']):2d}"
        )

    new_block = "world_enemies:\n" + "\n".join(lines_out) + "\n"

    # Match from world_enemies: up to the separator comment before get_rand:
    pattern = r'(world_enemies:\s*\n)(.*?)(\n; -{10,}\n; get_rand)'
    if re.search(pattern, text, re.DOTALL):
        new_text = re.sub(
            pattern,
            lambda m: f"{new_block}{m.group(3)}",
            text,
            flags=re.DOTALL
        )
    else:
        pattern2 = r'(world_enemies:\s*\n)(.*?)(\n[ \t]*get_rand:)'
        new_text = re.sub(
            pattern2,
            lambda m: f"{new_block}\n; ---------------------------------------------------------------------------\n; get_rand : nombre pseudo-aléatoire 8 bits dans A\n; ---------------------------------------------------------------------------\n{m.group(3)}",
            text,
            flags=re.DOTALL
        )

    with open(path, "w", encoding="utf-8") as f:
        f.write(new_text)


def save_start_config(start_room, player):
    if not start_room:
        return
    tilemap_path = os.path.join(BASE_DIR, "src/tilemap.asm")
    if os.path.exists(tilemap_path):
        with open(tilemap_path, "r", encoding="utf-8") as f:
            tm_text = f.read()
        tm_text = re.sub(r'START_ROOM_X\s*=\s*\d+', f"START_ROOM_X    = {start_room['x']}", tm_text)
        tm_text = re.sub(r'START_ROOM_Y\s*=\s*\d+', f"START_ROOM_Y    = {start_room['y']}", tm_text)
        with open(tilemap_path, "w", encoding="utf-8") as f:
            f.write(tm_text)

    if player and player.get("modified", False) and "tile_x" in player and "tile_y" in player:
        player_path = os.path.join(BASE_DIR, "src/player.asm")
        if os.path.exists(player_path):
            with open(player_path, "r", encoding="utf-8") as f:
                p_text = f.read()
            px = 24 + int(player["tile_x"]) * 16 + 8
            py = 82 + int(player["tile_y"]) * 16 + 8
            p_text = re.sub(r'player_x:\s*!word\s*\d+', f"player_x:         !word {px}", p_text)
            p_text = re.sub(r'player_y:\s*!byte\s*\d+', f"player_y:         !byte {py}", p_text)
            with open(player_path, "w", encoding="utf-8") as f:
                f.write(p_text)


def build_and_recompile():
    # 1. Regenerate charset & tilemap
    cmd_tilegen = [
        sys.executable,
        "tools/tilegen.py",
        "assets/tiles.txt",
        "assets/world.txt",
        "--charset", "src/charset.asm",
        "--map-out", "src/map_data.asm"
    ]
    p1 = subprocess.run(cmd_tilegen, cwd=BASE_DIR, capture_output=True, text=True)
    if p1.returncode != 0:
        return False, f"Erreur tilegen : {p1.stderr or p1.stdout}"

    # 2. Make
    cmd_make = ["make"]
    p2 = subprocess.run(cmd_make, cwd=BASE_DIR, capture_output=True, text=True)
    if p2.returncode != 0:
        return False, f"Erreur compilation ACME : {p2.stderr or p2.stdout}"

    prg_path = os.path.join(BASE_DIR, "build/zelda.prg")
    prg_size = os.path.getsize(prg_path) if os.path.exists(prg_path) else 0

    return True, f"Compilation réussie ! PRG : {prg_size} octets.\n{p2.stdout.strip()}"


class EditorHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        # Silence routine request logging
        pass

    def do_GET(self):
        url = urllib.parse.urlparse(self.path)
        if url.path == "/" or url.path == "/index.html":
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(HTML_PAGE.encode("utf-8"))
        elif url.path == "/api/data":
            cfg, tiles = parse_tiles()
            rooms = parse_world()
            enemies = parse_enemies()
            start_cfg = parse_start_config()

            data = {
                "palette": PALETTE,
                "color_names": COLOR_NAMES,
                "config": cfg,
                "tiles": tiles,
                "rooms": rooms,
                "room_names": ROOM_NAMES,
                "enemies": enemies,
                "start_room": start_cfg["start_room"],
                "player": start_cfg["player"],
                "actor_sprites": ACTOR_SPRITES
            }
            res = json.dumps(data).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(res)))
            self.end_headers()
            self.wfile.write(res)
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        url = urllib.parse.urlparse(self.path)
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length).decode("utf-8") if length > 0 else "{}"
        try:
            payload = json.loads(body)
        except Exception:
            payload = {}

        if url.path == "/api/save":
            try:
                if "rooms" in payload:
                    save_world_data(payload["rooms"])
                if "enemies" in payload:
                    save_enemies_data(payload["enemies"])
                if "start_room" in payload:
                    save_start_config(payload.get("start_room"), payload.get("player"))

                ok, msg = build_and_recompile()
                resp = {"success": ok, "message": msg}
            except Exception as e:
                resp = {"success": False, "message": f"Exception lors de la sauvegarde : {str(e)}"}

            res_bytes = json.dumps(resp).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(res_bytes)))
            self.end_headers()
            self.wfile.write(res_bytes)

        elif url.path == "/api/run":
            # Save first if payload contains data
            try:
                if "rooms" in payload:
                    save_world_data(payload["rooms"])
                if "enemies" in payload:
                    save_enemies_data(payload["enemies"])
                if "start_room" in payload:
                    save_start_config(payload.get("start_room"), payload.get("player"))
                ok, msg = build_and_recompile()
            except Exception as e:
                ok, msg = False, str(e)

            if ok:
                # Spawn VICE asynchronously
                subprocess.Popen(["make", "run"], cwd=BASE_DIR, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                resp = {"success": True, "message": "Jeu recompilé et lancé dans VICE !"}
            else:
                resp = {"success": False, "message": f"Échec recompilation avant lancement : {msg}"}

            res_bytes = json.dumps(resp).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(res_bytes)))
            self.end_headers()
            self.wfile.write(res_bytes)
        else:
            self.send_response(404)
            self.end_headers()


HTML_PAGE = """<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Zelda C64 — Éditeur de Niveau</title>
<style>
  :root {
    --bg-main: #12151a;
    --bg-panel: #1b2028;
    --bg-card: #242b35;
    --bg-hover: #2f3846;
    --border: #364152;
    --text-main: #e2e8f0;
    --text-muted: #94a3b8;
    --gold: #f59e0b;
    --gold-glow: rgba(245, 158, 11, 0.35);
    --green: #10b981;
    --red: #ef4444;
    --blue: #3b82f6;
    --accent: #8b5cf6;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; user-select: none; }
  body {
    background: var(--bg-main);
    color: var(--text-main);
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", sans-serif;
    height: 100vh;
    display: flex;
    flex-direction: column;
    overflow: hidden;
  }

  /* Header */
  header {
    background: var(--bg-panel);
    border-bottom: 1px solid var(--border);
    padding: 8px 16px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    z-index: 10;
  }
  .title-group {
    display: flex;
    align-items: center;
    gap: 10px;
  }
  .app-icon {
    font-size: 24px;
    filter: drop-shadow(0 0 6px var(--gold));
  }
  .app-title {
    font-size: 16px;
    font-weight: 700;
    letter-spacing: 0.5px;
    color: var(--gold);
    display: flex;
    align-items: center;
    gap: 8px;
  }
  .app-tag {
    font-size: 11px;
    background: var(--bg-card);
    border: 1px solid var(--border);
    padding: 2px 6px;
    border-radius: 4px;
    color: var(--text-muted);
  }

  .header-actions {
    display: flex;
    align-items: center;
    gap: 8px;
  }
  .btn {
    background: var(--bg-card);
    border: 1px solid var(--border);
    color: var(--text-main);
    padding: 6px 12px;
    border-radius: 6px;
    font-size: 13px;
    font-weight: 500;
    cursor: pointer;
    display: inline-flex;
    align-items: center;
    gap: 6px;
    transition: all 0.15s ease;
  }
  .btn:hover { background: var(--bg-hover); border-color: var(--gold); }
  .btn:active { transform: translateY(1px); }
  .btn-primary {
    background: #047857;
    border-color: #10b981;
    color: #fff;
    font-weight: 600;
  }
  .btn-primary:hover { background: #059669; border-color: #34d399; }
  .btn-run {
    background: #7c2d12;
    border-color: #f97316;
    color: #fff;
    font-weight: 600;
  }
  .btn-run:hover { background: #9a3412; border-color: #fb923c; }
  .btn-group {
    display: inline-flex;
    background: var(--bg-card);
    border-radius: 6px;
    border: 1px solid var(--border);
    overflow: hidden;
  }
  .btn-group .btn {
    border: none;
    border-radius: 0;
    border-right: 1px solid var(--border);
    padding: 6px 10px;
  }
  .btn-group .btn:last-child { border-right: none; }
  .btn.active {
    background: var(--gold);
    color: #000;
    font-weight: 700;
  }

  /* Main Workspace Layout */
  .workspace {
    flex: 1;
    display: flex;
    overflow: hidden;
  }

  /* Sidebar Left */
  .sidebar-left {
    width: 260px;
    background: var(--bg-panel);
    border-right: 1px solid var(--border);
    display: flex;
    flex-direction: column;
    overflow-y: auto;
  }
  .panel-section {
    padding: 14px;
    border-bottom: 1px solid var(--border);
  }
  .panel-title {
    font-size: 11px;
    text-transform: uppercase;
    letter-spacing: 1px;
    color: var(--text-muted);
    margin-bottom: 10px;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .tool-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 6px;
    margin-bottom: 10px;
  }
  .tool-btn {
    background: var(--bg-card);
    border: 1px solid var(--border);
    color: var(--text-main);
    border-radius: 6px;
    padding: 8px 4px;
    font-size: 11px;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 4px;
    cursor: pointer;
    transition: all 0.15s ease;
  }
  .tool-btn:hover { background: var(--bg-hover); }
  .tool-btn.active {
    background: var(--bg-hover);
    border-color: var(--gold);
    box-shadow: 0 0 8px var(--gold-glow);
    color: var(--gold);
    font-weight: 700;
  }
  .tool-btn .icon { font-size: 16px; }

  /* Tiles List */
  .tile-list {
    display: flex;
    flex-direction: column;
    gap: 4px;
  }
  .tile-item {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 6px 8px;
    background: var(--bg-card);
    border: 1px solid transparent;
    border-radius: 6px;
    cursor: pointer;
    transition: all 0.1s ease;
  }
  .tile-item:hover { background: var(--bg-hover); }
  .tile-item.active {
    border-color: var(--gold);
    background: var(--bg-hover);
    box-shadow: 0 0 6px var(--gold-glow);
  }
  .tile-preview-box {
    width: 32px;
    height: 32px;
    border-radius: 4px;
    background: #000;
    image-rendering: pixelated;
    display: flex;
    align-items: center;
    justify-content: center;
    border: 1px solid var(--border);
  }
  .tile-preview-canvas {
    width: 32px;
    height: 32px;
    image-rendering: pixelated;
  }
  .tile-info {
    flex: 1;
    display: flex;
    flex-direction: column;
  }
  .tile-name {
    font-size: 13px;
    font-weight: 600;
    color: var(--text-main);
  }
  .tile-sub {
    font-size: 11px;
    color: var(--text-muted);
    display: flex;
    align-items: center;
    gap: 6px;
  }
  .badge-solid {
    color: var(--red);
    font-weight: 700;
    font-size: 10px;
  }
  .badge-passable {
    color: var(--green);
    font-size: 10px;
  }
  .tile-key {
    font-size: 11px;
    color: var(--text-muted);
    background: var(--bg-main);
    border: 1px solid var(--border);
    padding: 2px 5px;
    border-radius: 4px;
    font-family: monospace;
  }

  /* Center Stage */
  .center-stage {
    flex: 1;
    display: flex;
    flex-direction: column;
    background: var(--bg-main);
    overflow: hidden;
    position: relative;
  }
  .stage-bar {
    padding: 8px 16px;
    background: var(--bg-panel);
    border-bottom: 1px solid var(--border);
    display: flex;
    align-items: center;
    justify-content: space-between;
    font-size: 13px;
  }
  .stage-room-title {
    font-weight: 600;
    color: var(--gold);
    display: flex;
    align-items: center;
    gap: 8px;
  }
  .stage-status {
    color: var(--text-muted);
    font-size: 12px;
  }

  .canvas-viewport {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    overflow: auto;
    padding: 20px;
    background: radial-gradient(circle at center, #1b2029 0%, #12151a 100%);
    cursor: crosshair;
  }
  .canvas-wrapper {
    position: relative;
    box-shadow: 0 10px 30px rgba(0,0,0,0.6);
    border: 2px solid var(--border);
    border-radius: 4px;
    line-height: 0;
    background: #000;
  }
  #mainCanvas {
    image-rendering: pixelated;
    image-rendering: crisp-edges;
    display: block;
  }

  /* Bottom status bar */
  .bottom-bar {
    padding: 6px 16px;
    background: var(--bg-panel);
    border-top: 1px solid var(--border);
    display: flex;
    align-items: center;
    justify-content: space-between;
    font-size: 12px;
    color: var(--text-muted);
  }
  .coord-pill {
    background: var(--bg-card);
    padding: 2px 8px;
    border-radius: 4px;
    border: 1px solid var(--border);
    color: var(--text-main);
    font-family: monospace;
  }

  /* Sidebar Right */
  .sidebar-right {
    width: 310px;
    background: var(--bg-panel);
    border-left: 1px solid var(--border);
    display: flex;
    flex-direction: column;
    overflow-y: auto;
  }

  /* Minimap 3x3 */
  .minimap-container {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 4px;
    background: var(--bg-card);
    padding: 6px;
    border-radius: 6px;
    border: 1px solid var(--border);
    margin-bottom: 10px;
  }
  .minimap-cell {
    aspect-ratio: 2 / 1;
    background: #000;
    border: 2px solid transparent;
    border-radius: 3px;
    cursor: pointer;
    position: relative;
    overflow: hidden;
    transition: all 0.1s ease;
  }
  .minimap-cell:hover { border-color: var(--text-muted); }
  .minimap-cell.active {
    border-color: var(--gold);
    box-shadow: 0 0 8px var(--gold-glow);
  }
  .minimap-cell canvas {
    width: 100%;
    height: 100%;
    image-rendering: pixelated;
    display: block;
  }
  .minimap-badge {
    position: absolute;
    bottom: 2px;
    right: 2px;
    font-size: 9px;
    background: rgba(0,0,0,0.7);
    color: #fff;
    padding: 1px 3px;
    border-radius: 2px;
  }
  .start-star {
    position: absolute;
    top: 2px;
    left: 2px;
    font-size: 10px;
    color: var(--gold);
    text-shadow: 0 0 3px #000;
  }

  /* Enemy slots */
  .enemy-card {
    background: var(--bg-card);
    border: 1px solid var(--border);
    border-radius: 6px;
    padding: 10px;
    margin-bottom: 8px;
  }
  .enemy-card-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 8px;
    font-size: 12px;
    font-weight: 600;
  }
  .enemy-select {
    width: 100%;
    background: var(--bg-main);
    border: 1px solid var(--border);
    color: var(--text-main);
    padding: 6px;
    border-radius: 4px;
    font-size: 12px;
    margin-bottom: 8px;
    outline: none;
  }
  .enemy-coord-row {
    display: flex;
    align-items: center;
    gap: 8px;
    font-size: 12px;
  }
  .enemy-coord-row input {
    width: 50px;
    background: var(--bg-main);
    border: 1px solid var(--border);
    color: var(--text-main);
    padding: 4px 6px;
    border-radius: 4px;
    text-align: center;
    font-family: monospace;
    font-size: 12px;
  }
  .btn-sm {
    padding: 4px 8px;
    font-size: 11px;
    border-radius: 4px;
  }

  /* Shortcuts box */
  .shortcut-table {
    width: 100%;
    border-collapse: collapse;
    font-size: 11px;
    color: var(--text-muted);
  }
  .shortcut-table td {
    padding: 3px 0;
  }
  .shortcut-table kbd {
    background: var(--bg-card);
    border: 1px solid var(--border);
    border-radius: 3px;
    padding: 1px 4px;
    color: var(--text-main);
    font-family: monospace;
  }

  /* Notifications */
  #toast {
    position: fixed;
    bottom: 24px;
    right: 24px;
    background: #1f2937;
    border: 1px solid var(--border);
    color: #fff;
    padding: 10px 16px;
    border-radius: 8px;
    font-size: 13px;
    box-shadow: 0 10px 25px rgba(0,0,0,0.5);
    display: flex;
    align-items: center;
    gap: 8px;
    opacity: 0;
    pointer-events: none;
    transform: translateY(10px);
    transition: all 0.25s ease;
    z-index: 1000;
  }
  #toast.show {
    opacity: 1;
    transform: translateY(0);
  }
  #toast.success { border-color: var(--green); background: #064e3b; }
  #toast.error { border-color: var(--red); background: #7f1d1d; }
</style>
</head>
<body>

<header>
  <div class="title-group">
    <div class="app-icon">🛡️</div>
    <div>
      <div class="app-title">ZELDA C64 <span class="app-tag">Level Editor</span></div>
    </div>
  </div>

  <div class="header-actions">
    <div class="btn-group">
      <button class="btn active" id="viewRoomBtn" onclick="setViewMode('room')">Salle (20×10)</button>
      <button class="btn" id="viewWorldBtn" onclick="setViewMode('world')">Monde (60×30)</button>
    </div>

    <div class="btn-group">
      <button class="btn" onclick="undo()" title="Annuler (Ctrl+Z)" id="undoBtn">↩</button>
      <button class="btn" onclick="redo()" title="Rétablir (Ctrl+Y)" id="redoBtn">↪</button>
    </div>

    <div class="btn-group">
      <button class="btn active" id="zoom1Btn" onclick="setZoom(1)">1x</button>
      <button class="btn" id="zoom2Btn" onclick="setZoom(2)">2x</button>
      <button class="btn" id="zoom3Btn" onclick="setZoom(3)">3x</button>
    </div>

    <button class="btn" id="gridToggleBtn" onclick="toggleGrid()">⊞ Grille</button>

    <button class="btn btn-primary" onclick="saveData()" id="saveBtn">💾 Sauvegarder</button>
    <button class="btn btn-run" onclick="runVICE()" id="runBtn">▶ Tester (VICE)</button>
  </div>
</header>

<div class="workspace">
  <!-- Left Panel: Tools & Palette -->
  <aside class="sidebar-left">
    <div class="panel-section">
      <div class="panel-title">Outils de Peinture</div>
      <div class="tool-grid">
        <button class="tool-btn active" id="tool_brush" onclick="setTool('brush')">
          <span class="icon">🖌️</span>
          <span>Pinceau</span>
        </button>
        <button class="tool-btn" id="tool_brush2" onclick="setTool('brush2')">
          <span class="icon">⬛</span>
          <span>Gros 2x2</span>
        </button>
        <button class="tool-btn" id="tool_fill" onclick="setTool('fill')">
          <span class="icon">🪣</span>
          <span>Seau</span>
        </button>
        <button class="tool-btn" id="tool_picker" onclick="setTool('picker')">
          <span class="icon">🧪</span>
          <span>Pipette</span>
        </button>
        <button class="tool-btn" id="tool_enemy" onclick="setTool('enemy')">
          <span class="icon">👾</span>
          <span>Ennemi</span>
        </button>
        <button class="tool-btn" id="tool_link" onclick="setTool('link')">
          <span class="icon">🗡️</span>
          <span>Link</span>
        </button>
      </div>
    </div>

    <div class="panel-section" style="flex: 1; overflow-y: auto;">
      <div class="panel-title">
        <span>Palette de Tuiles</span>
        <span id="tileCountBadge" style="font-size:10px; color:var(--text-muted)">8 tuiles</span>
      </div>
      <div class="tile-list" id="tileList">
        <!-- Rendered dynamically -->
      </div>
    </div>
  </aside>

  <!-- Center Stage: Canvas -->
  <main class="center-stage">
    <div class="stage-bar">
      <div class="stage-room-title" id="stageRoomTitle">
        Salle (1, 2) : Départ - Zelda 1
      </div>
      <div class="stage-status" id="stageStatus">
        Prêt • Clic gauche pour peindre / déplacer
      </div>
    </div>

    <div class="canvas-viewport" id="viewport">
      <div class="canvas-wrapper">
        <canvas id="mainCanvas"></canvas>
      </div>
    </div>

    <div class="bottom-bar">
      <div id="tileHoverInfo">Survolez la carte</div>
      <div style="display:flex; gap:10px; align-items:center;">
        <span>Curseur : <span class="coord-pill" id="coordPill">X: --, Y: --</span></span>
        <span>Salle : <span class="coord-pill" id="roomCoordPill">1, 2</span></span>
      </div>
    </div>
  </main>

  <!-- Right Panel: Minimap & Enemies -->
  <aside class="sidebar-right">
    <div class="panel-section">
      <div class="panel-title">Minimap Hyrule (3×3)</div>
      <div class="minimap-container" id="minimapContainer">
        <!-- 9 rooms generated dynamically -->
      </div>
      <button class="btn btn-sm" style="width:100%" onclick="setStartRoom()">
        ★ Définir salle active comme départ
      </button>
    </div>

    <div class="panel-section">
      <div class="panel-title">Ennemis de la Salle</div>
      
      <!-- Enemy Slot 1 -->
      <div class="enemy-card">
        <div class="enemy-card-header">
          <span style="color:var(--gold)">Ennemi #1</span>
          <button class="btn btn-sm" onclick="pickEnemyTarget(0)">🎯 Cliquer pour poser</button>
        </div>
        <select class="enemy-select" id="en0_type" onchange="updateEnemyFromUI(0)">
          <option value="TYPE_NONE">Aucun (TYPE_NONE)</option>
          <option value="TYPE_OCTO">Octorok Rouge (TYPE_OCTO)</option>
          <option value="TYPE_MOBLIN">Moblin Rouge (TYPE_MOBLIN)</option>
        </select>
        <div class="enemy-coord-row">
          <span>X:</span> <input type="number" id="en0_x" min="0" max="19" onchange="updateEnemyFromUI(0)">
          <span>Y:</span> <input type="number" id="en0_y" min="0" max="9" onchange="updateEnemyFromUI(0)">
        </div>
      </div>

      <!-- Enemy Slot 2 -->
      <div class="enemy-card">
        <div class="enemy-card-header">
          <span style="color:var(--gold)">Ennemi #2</span>
          <button class="btn btn-sm" onclick="pickEnemyTarget(1)">🎯 Cliquer pour poser</button>
        </div>
        <select class="enemy-select" id="en1_type" onchange="updateEnemyFromUI(1)">
          <option value="TYPE_NONE">Aucun (TYPE_NONE)</option>
          <option value="TYPE_OCTO">Octorok Rouge (TYPE_OCTO)</option>
          <option value="TYPE_MOBLIN">Moblin Rouge (TYPE_MOBLIN)</option>
        </select>
        <div class="enemy-coord-row">
          <span>X:</span> <input type="number" id="en1_x" min="0" max="19" onchange="updateEnemyFromUI(1)">
          <span>Y:</span> <input type="number" id="en1_y" min="0" max="9" onchange="updateEnemyFromUI(1)">
        </div>
      </div>

      <button class="btn btn-sm" style="width:100%; color:var(--red)" onclick="clearRoomEnemies()">
        🧹 Supprimer les ennemis de la salle
      </button>
    </div>

    <div class="panel-section">
      <div class="panel-title">Raccourcis Clavier</div>
      <table class="shortcut-table">
        <tr><td><kbd>Clic G</kbd></td><td>Peindre / Déplacer</td></tr>
        <tr><td><kbd>Clic D</kbd></td><td>Pipette tuile</td></tr>
        <tr><td><kbd>1</kbd> .. <kbd>8</kbd></td><td>Choix direct tuile</td></tr>
        <tr><td><kbd>B</kbd> / <kbd>F</kbd></td><td>Pinceau / Seau</td></tr>
        <tr><td><kbd>G</kbd></td><td>Afficher grille</td></tr>
        <tr><td><kbd>Ctrl+Z</kbd></td><td>Annuler</td></tr>
        <tr><td><kbd>Ctrl+Y</kbd></td><td>Rétablir</td></tr>
        <tr><td><kbd>Ctrl+S</kbd></td><td>Sauvegarder</td></tr>
      </table>
    </div>
  </aside>
</div>

<div id="toast"></div>

<script>
// State
let appData = null;
let currentRoom = { x: 1, y: 2 };
let viewMode = 'room'; // 'room' | 'world'
let currentTool = 'brush'; // 'brush' | 'brush2' | 'fill' | 'picker' | 'enemy' | 'link'
let selectedTileSymbol = '.';
let showGrid = true;
let zoomLevel = 2; // 1, 2, 3
let isPainting = false;
let isDragging = null; // { type: 'enemy'|'link', index: 0, rx: 1, ry: 2 }
let activeEnemySlotToPick = null;

// Offscreen tile & sprite cache
const tileCanvases = {};
const actorCanvases = {};

// History stacks for Undo / Redo
const undoStack = [];
const redoStack = [];

async function init() {
  const res = await fetch('/api/data');
  appData = await res.json();

  if (appData.start_room) {
    currentRoom = { ...appData.start_room };
  }

  buildTileCache();
  buildActorCache();
  renderTileList();
  renderMinimap();
  updateUI();
  renderMainCanvas();
  setupEvents();
  showToast("Données Zelda C64 chargées avec succès !", "success");
}

function buildTileCache() {
  const bg = appData.palette[appData.config.bg];
  const mc1 = appData.palette[appData.config.mc1];
  const mc2 = appData.palette[appData.config.mc2];

  appData.tiles.forEach(tile => {
    const cvs = document.createElement('canvas');
    cvs.width = 16;
    cvs.height = 16;
    const ctx = cvs.getContext('2d');
    const ownCol = appData.palette[tile.color_idx];

    tile.rows.forEach((row, y) => {
      for (let x = 0; x < 8; x++) {
        const ch = row[x];
        let col = bg;
        if (ch === '1') col = mc1;
        else if (ch === '2') col = mc2;
        else if (ch === 'c') col = ownCol;
        
        ctx.fillStyle = col;
        // Double horizontal pixel for C64 multicolor aspect
        ctx.fillRect(x * 2, y, 2, 1);
      }
    });
    tileCanvases[tile.symbol] = cvs;
  });
}

function buildActorCache() {
  const skin = appData.palette[10];  // lred / skin
  const brown = appData.palette[9];  // brown
  const green = appData.palette[5];  // green
  const red = appData.palette[2];    // red

  function renderActor(rows, colG) {
    const cvs = document.createElement('canvas');
    cvs.width = 16;
    cvs.height = 16;
    const ctx = cvs.getContext('2d');

    rows.forEach((row, y) => {
      for (let x = 0; x < 8; x++) {
        const ch = row[x];
        if (ch === '.') continue;
        let col = '#fff';
        if (ch === 'g') col = colG;
        else if (ch === 's') col = skin;
        else if (ch === 'b') col = brown;
        ctx.fillStyle = col;
        ctx.fillRect(x * 2, y, 2, 1);
      }
    });
    return cvs;
  }

  actorCanvases['link'] = renderActor(appData.actor_sprites.link, green);
  actorCanvases['octo'] = renderActor(appData.actor_sprites.octo, red);
  actorCanvases['moblin'] = renderActor(appData.actor_sprites.moblin, red);
}

function renderTileList() {
  const container = document.getElementById('tileList');
  container.innerHTML = '';
  appData.tiles.forEach((tile, idx) => {
    const item = document.createElement('div');
    item.className = 'tile-item' + (tile.symbol === selectedTileSymbol ? ' active' : '');
    item.onclick = () => selectTile(tile.symbol);

    const prevBox = document.createElement('div');
    prevBox.className = 'tile-preview-box';
    const cvs = document.createElement('canvas');
    cvs.className = 'tile-preview-canvas';
    cvs.width = 16;
    cvs.height = 16;
    const ctx = cvs.getContext('2d');
    ctx.drawImage(tileCanvases[tile.symbol], 0, 0);
    prevBox.appendChild(cvs);

    const info = document.createElement('div');
    info.className = 'tile-info';
    info.innerHTML = `
      <div class="tile-name">${tile.name}</div>
      <div class="tile-sub">
        <span style="font-family:monospace; color:var(--gold); font-weight:bold;">${tile.symbol}</span>
        ${tile.solid ? '<span class="badge-solid">SOLIDE</span>' : '<span class="badge-passable">PASSABLE</span>'}
      </div>
    `;

    const key = document.createElement('div');
    key.className = 'tile-key';
    key.textContent = `${idx + 1}`;

    item.appendChild(prevBox);
    item.appendChild(info);
    item.appendChild(key);
    container.appendChild(item);
  });
}

function selectTile(symbol) {
  selectedTileSymbol = symbol;
  renderTileList();
  if (currentTool === 'enemy' || currentTool === 'link') {
    setTool('brush');
  }
}

function setTool(tool) {
  currentTool = tool;
  document.querySelectorAll('.tool-btn').forEach(btn => {
    btn.classList.toggle('active', btn.id === `tool_${tool}`);
  });
  if (tool === 'picker') {
    document.getElementById('stageStatus').textContent = "Pipette : Cliquez sur une tuile pour la copier";
  } else if (tool === 'enemy') {
    document.getElementById('stageStatus').textContent = "Mode Ennemi : Cliquez sur la carte pour placer le monstre sélectionné";
  } else if (tool === 'link') {
    document.getElementById('stageStatus').textContent = "Mode Link : Cliquez sur la carte pour définir la position de départ";
  } else {
    document.getElementById('stageStatus').textContent = "Prêt • Clic gauche pour peindre / déplacer";
  }
}

function setViewMode(mode) {
  viewMode = mode;
  document.getElementById('viewRoomBtn').classList.toggle('active', mode === 'room');
  document.getElementById('viewWorldBtn').classList.toggle('active', mode === 'world');
  renderMainCanvas();
  updateUI();
}

function setZoom(z) {
  zoomLevel = z;
  document.getElementById('zoom1Btn').classList.toggle('active', z === 1);
  document.getElementById('zoom2Btn').classList.toggle('active', z === 2);
  document.getElementById('zoom3Btn').classList.toggle('active', z === 3);
  renderMainCanvas();
}

function toggleGrid() {
  showGrid = !showGrid;
  document.getElementById('gridToggleBtn').classList.toggle('active', showGrid);
  renderMainCanvas();
}

function pushHistory() {
  undoStack.push({
    rooms: JSON.parse(JSON.stringify(appData.rooms)),
    enemies: JSON.parse(JSON.stringify(appData.enemies)),
    start_room: { ...appData.start_room },
    player: { ...appData.player }
  });
  if (undoStack.length > 50) undoStack.shift();
  redoStack.length = 0; // Clear redo on new action
}

function undo() {
  if (undoStack.length === 0) return;
  redoStack.push({
    rooms: JSON.parse(JSON.stringify(appData.rooms)),
    enemies: JSON.parse(JSON.stringify(appData.enemies)),
    start_room: { ...appData.start_room },
    player: { ...appData.player }
  });
  const state = undoStack.pop();
  appData.rooms = state.rooms;
  appData.enemies = state.enemies;
  appData.start_room = state.start_room;
  appData.player = state.player;
  renderMainCanvas();
  renderMinimap();
  updateUI();
  showToast("Annulation effectuée", "success");
}

function redo() {
  if (redoStack.length === 0) return;
  undoStack.push({
    rooms: JSON.parse(JSON.stringify(appData.rooms)),
    enemies: JSON.parse(JSON.stringify(appData.enemies)),
    start_room: { ...appData.start_room },
    player: { ...appData.player }
  });
  const state = redoStack.pop();
  appData.rooms = state.rooms;
  appData.enemies = state.enemies;
  appData.start_room = state.start_room;
  appData.player = state.player;
  renderMainCanvas();
  renderMinimap();
  updateUI();
  showToast("Rétablissement effectué", "success");
}

function renderMinimap() {
  const container = document.getElementById('minimapContainer');
  container.innerHTML = '';

  for (let ry = 0; ry < 3; ry++) {
    for (let rx = 0; rx < 3; rx++) {
      const cell = document.createElement('div');
      cell.className = 'minimap-cell' + (currentRoom.x === rx && currentRoom.y === ry ? ' active' : '');
      cell.onclick = () => selectRoom(rx, ry);

      const cvs = document.createElement('canvas');
      cvs.width = 20 * 16;
      cvs.height = 10 * 16;
      const ctx = cvs.getContext('2d');
      ctx.imageSmoothingEnabled = false;

      const room = appData.rooms[ry][rx];
      for (let y = 0; y < 10; y++) {
        for (let x = 0; x < 20; x++) {
          const sym = room[y][x];
          const tileCvs = tileCanvases[sym];
          if (tileCvs) ctx.drawImage(tileCvs, x * 16, y * 16);
        }
      }

      // Draw enemies on minimap
      const rIdx = ry * 3 + rx;
      const rEnemies = appData.enemies[rIdx] || [];
      rEnemies.forEach(e => {
        if (e.type !== 'TYPE_NONE') {
          ctx.fillStyle = '#ef4444';
          ctx.fillRect(e.x * 16 + 2, e.y * 16 + 2, 12, 12);
        }
      });

      // Draw start marker
      if (appData.start_room.x === rx && appData.start_room.y === ry) {
        const px = appData.player ? appData.player.tile_x : 9;
        const py = appData.player ? appData.player.tile_y : 7;
        ctx.fillStyle = '#10b981';
        ctx.fillRect(px * 16 + 2, py * 16 + 2, 12, 12);

        const star = document.createElement('div');
        star.className = 'start-star';
        star.textContent = '★';
        cell.appendChild(star);
      }

      const badge = document.createElement('div');
      badge.className = 'minimap-badge';
      badge.textContent = `${rx},${ry}`;
      cell.appendChild(badge);

      cell.appendChild(cvs);
      container.appendChild(cell);
    }
  }
}

function selectRoom(rx, ry) {
  currentRoom = { x: rx, y: ry };
  renderMinimap();
  updateUI();
  renderMainCanvas();
}

function setStartRoom() {
  pushHistory();
  appData.start_room = { ...currentRoom };
  renderMinimap();
  renderMainCanvas();
  showToast(`Salle (${currentRoom.x}, ${currentRoom.y}) définie comme point de départ !`, "success");
}

function updateUI() {
  const rx = currentRoom.x;
  const ry = currentRoom.y;
  const rIdx = ry * 3 + rx;
  const rName = appData.room_names[ry][rx];

  document.getElementById('stageRoomTitle').textContent = `Salle (${rx}, ${ry}) : ${rName}`;
  document.getElementById('roomCoordPill').textContent = `${rx}, ${ry}`;

  // Update enemy cards
  const rEnemies = appData.enemies[rIdx] || [
    { type: 'TYPE_NONE', x: 0, y: 0 },
    { type: 'TYPE_NONE', x: 0, y: 0 }
  ];

  document.getElementById('en0_type').value = rEnemies[0].type;
  document.getElementById('en0_x').value = rEnemies[0].x;
  document.getElementById('en0_y').value = rEnemies[0].y;

  document.getElementById('en1_type').value = rEnemies[1].type;
  document.getElementById('en1_x').value = rEnemies[1].x;
  document.getElementById('en1_y').value = rEnemies[1].y;
}

function updateEnemyFromUI(slot) {
  pushHistory();
  const rIdx = currentRoom.y * 3 + currentRoom.x;
  const type = document.getElementById(`en${slot}_type`).value;
  const x = Math.max(0, Math.min(19, parseInt(document.getElementById(`en${slot}_x`).value) || 0));
  const y = Math.max(0, Math.min(9, parseInt(document.getElementById(`en${slot}_y`).value) || 0));

  appData.enemies[rIdx][slot] = { type, x, y };
  renderMainCanvas();
  renderMinimap();
}

function pickEnemyTarget(slot) {
  activeEnemySlotToPick = slot;
  setTool('enemy');
  showToast(`Cliquez sur la carte pour positionner l'Ennemi #${slot + 1}`, "success");
}

function clearRoomEnemies() {
  pushHistory();
  const rIdx = currentRoom.y * 3 + currentRoom.x;
  appData.enemies[rIdx] = [
    { type: 'TYPE_NONE', x: 0, y: 0 },
    { type: 'TYPE_NONE', x: 0, y: 0 }
  ];
  updateUI();
  renderMainCanvas();
  renderMinimap();
  showToast("Ennemis supprimés de cette salle", "success");
}

// Main Canvas Drawing
function renderMainCanvas() {
  const canvas = document.getElementById('mainCanvas');
  const ctx = canvas.getContext('2d');
  ctx.imageSmoothingEnabled = false;

  const tileSize = 16 * zoomLevel;

  if (viewMode === 'room') {
    canvas.width = 20 * tileSize;
    canvas.height = 10 * tileSize;

    const rx = currentRoom.x;
    const ry = currentRoom.y;
    const room = appData.rooms[ry][rx];

    // 1. Draw tiles
    for (let y = 0; y < 10; y++) {
      for (let x = 0; x < 20; x++) {
        const sym = room[y][x];
        const tileCvs = tileCanvases[sym];
        if (tileCvs) {
          ctx.drawImage(tileCvs, x * tileSize, y * tileSize, tileSize, tileSize);
        }
      }
    }

    // 2. Grid overlay
    if (showGrid) {
      ctx.strokeStyle = "rgba(255, 255, 255, 0.12)";
      ctx.lineWidth = 1;
      for (let x = 0; x <= 20; x++) {
        ctx.beginPath();
        ctx.moveTo(x * tileSize, 0);
        ctx.lineTo(x * tileSize, 10 * tileSize);
        ctx.stroke();
      }
      for (let y = 0; y <= 10; y++) {
        ctx.beginPath();
        ctx.moveTo(0, y * tileSize);
        ctx.lineTo(20 * tileSize, y * tileSize);
        ctx.stroke();
      }
    }

    // 3. Draw Link (if starting room)
    if (appData.start_room.x === rx && appData.start_room.y === ry) {
      const px = appData.player ? appData.player.tile_x : 9;
      const py = appData.player ? appData.player.tile_y : 7;
      drawActorBadge(ctx, actorCanvases['link'], px, py, tileSize, "LINK", "#10b981");
    }

    // 4. Draw enemies
    const rIdx = ry * 3 + rx;
    const rEnemies = appData.enemies[rIdx] || [];
    rEnemies.forEach((e, idx) => {
      if (e.type === 'TYPE_OCTO') {
        drawActorBadge(ctx, actorCanvases['octo'], e.x, e.y, tileSize, `OCTO #${idx+1}`, "#ef4444");
      } else if (e.type === 'TYPE_MOBLIN') {
        drawActorBadge(ctx, actorCanvases['moblin'], e.x, e.y, tileSize, `MOBLIN #${idx+1}`, "#f97316");
      }
    });

  } else {
    // World View (60x30)
    canvas.width = 60 * tileSize;
    canvas.height = 30 * tileSize;

    for (let ry = 0; ry < 3; ry++) {
      for (let rx = 0; rx < 3; rx++) {
        const room = appData.rooms[ry][rx];
        for (let y = 0; y < 10; y++) {
          for (let x = 0; x < 20; x++) {
            const sym = room[y][x];
            const tileCvs = tileCanvases[sym];
            const gx = rx * 20 + x;
            const gy = ry * 10 + y;
            if (tileCvs) {
              ctx.drawImage(tileCvs, gx * tileSize, gy * tileSize, tileSize, tileSize);
            }
          }
        }
      }
    }

    // Room boundaries in World View
    ctx.strokeStyle = "rgba(245, 158, 11, 0.7)";
    ctx.lineWidth = 2;
    for (let rx = 1; rx < 3; rx++) {
      ctx.beginPath();
      ctx.moveTo(rx * 20 * tileSize, 0);
      ctx.lineTo(rx * 20 * tileSize, 30 * tileSize);
      ctx.stroke();
    }
    for (let ry = 1; ry < 3; ry++) {
      ctx.beginPath();
      ctx.moveTo(0, ry * 10 * tileSize);
      ctx.lineTo(60 * tileSize, ry * 10 * tileSize);
      ctx.stroke();
    }

    // Active room highlight box
    ctx.strokeStyle = "#f59e0b";
    ctx.lineWidth = 3;
    ctx.strokeRect(
      currentRoom.x * 20 * tileSize,
      currentRoom.y * 10 * tileSize,
      20 * tileSize,
      10 * tileSize
    );
  }
}

function drawActorBadge(ctx, spriteCvs, tx, ty, size, label, col) {
  const x = tx * size;
  const y = ty * size;

  // Background halo
  ctx.fillStyle = "rgba(0, 0, 0, 0.5)";
  ctx.beginPath();
  ctx.arc(x + size / 2, y + size / 2, size * 0.55, 0, Math.PI * 2);
  ctx.fill();

  // Sprite
  if (spriteCvs) {
    ctx.drawImage(spriteCvs, x, y, size, size);
  }

  // Label tag
  ctx.fillStyle = col;
  ctx.font = `bold ${Math.max(9, size * 0.28)}px monospace`;
  ctx.textAlign = "center";
  ctx.shadowColor = "#000";
  ctx.shadowBlur = 4;
  ctx.fillText(label, x + size / 2, y + size + 9);
  ctx.shadowBlur = 0;
}

// Canvas Interaction (Mouse)
function setupEvents() {
  const canvas = document.getElementById('mainCanvas');

  function getTileCoords(e) {
    const rect = canvas.getBoundingClientRect();
    const tileSize = 16 * zoomLevel;
    const clickX = e.clientX - rect.left;
    const clickY = e.clientY - rect.top;

    let tx = Math.floor(clickX / tileSize);
    let ty = Math.floor(clickY / tileSize);

    if (viewMode === 'room') {
      tx = Math.max(0, Math.min(19, tx));
      ty = Math.max(0, Math.min(9, ty));
      return { tx, ty, rx: currentRoom.x, ry: currentRoom.y };
    } else {
      tx = Math.max(0, Math.min(59, tx));
      ty = Math.max(0, Math.min(29, ty));
      const rx = Math.floor(tx / 20);
      const ry = Math.floor(ty / 10);
      return { tx: tx % 20, ty: ty % 10, rx, ry, globalX: tx, globalY: ty };
    }
  }

  canvas.addEventListener('contextmenu', e => {
    e.preventDefault();
    const { tx, ty, rx, ry } = getTileCoords(e);
    const sym = appData.rooms[ry][rx][ty][tx];
    selectTile(sym);
    showToast(`Tuile copiée : ${sym}`, "success");
  });

  canvas.addEventListener('mousedown', e => {
    if (e.button === 2) return; // Right click handled by contextmenu
    const { tx, ty, rx, ry } = getTileCoords(e);

    // If clicked in another room in World View, switch active room
    if (viewMode === 'world' && (rx !== currentRoom.x || ry !== currentRoom.y)) {
      currentRoom = { x: rx, y: ry };
      renderMinimap();
      updateUI();
    }

    // Check if clicked on Enemy or Link to start dragging
    const rIdx = ry * 3 + rx;
    const rEnemies = appData.enemies[rIdx] || [];
    
    // Check enemy 0
    if (rEnemies[0] && rEnemies[0].type !== 'TYPE_NONE' && rEnemies[0].x === tx && rEnemies[0].y === ty) {
      isDragging = { type: 'enemy', index: 0, rx, ry };
      return;
    }
    // Check enemy 1
    if (rEnemies[1] && rEnemies[1].type !== 'TYPE_NONE' && rEnemies[1].x === tx && rEnemies[1].y === ty) {
      isDragging = { type: 'enemy', index: 1, rx, ry };
      return;
    }
    // Check Link
    if (appData.start_room.x === rx && appData.start_room.y === ry && appData.player.tile_x === tx && appData.player.tile_y === ty) {
      isDragging = { type: 'link', rx, ry };
      return;
    }

    // Tool actions
    pushHistory();
    if (currentTool === 'picker') {
      const sym = appData.rooms[ry][rx][ty][tx];
      selectTile(sym);
      setTool('brush');
      showToast(`Tuile copiée : ${sym}`, "success");
    } else if (currentTool === 'enemy') {
      const slot = activeEnemySlotToPick !== null ? activeEnemySlotToPick : 0;
      const type = document.getElementById(`en${slot}_type`).value;
      appData.enemies[rIdx][slot] = { type: type === 'TYPE_NONE' ? 'TYPE_OCTO' : type, x: tx, y: ty };
      activeEnemySlotToPick = null;
      setTool('brush');
      updateUI();
      renderMinimap();
      renderMainCanvas();
    } else if (currentTool === 'link') {
      appData.start_room = { x: rx, y: ry };
      appData.player.tile_x = tx;
      appData.player.tile_y = ty;
      appData.player.modified = true;
      setTool('brush');
      updateUI();
      renderMinimap();
      renderMainCanvas();
    } else if (currentTool === 'fill') {
      floodFill(rx, ry, tx, ty, selectedTileSymbol);
      renderMainCanvas();
      renderMinimap();
    } else {
      isPainting = true;
      paintAt(rx, ry, tx, ty);
      renderMainCanvas();
      renderMinimap();
    }
  });

  window.addEventListener('mousemove', e => {
    const { tx, ty, rx, ry } = getTileCoords(e);
    document.getElementById('coordPill').textContent = `X: ${tx}, Y: ${ty}`;
    
    if (isDragging) {
      const rIdx = ry * 3 + rx;
      if (isDragging.type === 'enemy') {
        appData.enemies[rIdx][isDragging.index].x = tx;
        appData.enemies[rIdx][isDragging.index].y = ty;
        updateUI();
      } else if (isDragging.type === 'link') {
        appData.player.tile_x = tx;
        appData.player.tile_y = ty;
        appData.player.modified = true;
      }
      renderMainCanvas();
      renderMinimap();
      return;
    }

    if (isPainting) {
      paintAt(rx, ry, tx, ty);
      renderMainCanvas();
      renderMinimap();
    }
  });

  window.addEventListener('mouseup', () => {
    isPainting = false;
    isDragging = null;
  });

  // Keyboard Shortcuts
  window.addEventListener('keydown', e => {
    if (e.target.tagName === 'INPUT' || e.target.tagName === 'SELECT') return;

    if (e.ctrlKey && e.key.toLowerCase() === 'z') {
      e.preventDefault();
      undo();
    } else if (e.ctrlKey && e.key.toLowerCase() === 'y') {
      e.preventDefault();
      redo();
    } else if (e.ctrlKey && e.key.toLowerCase() === 's') {
      e.preventDefault();
      saveData();
    } else if (e.key === 'b' || e.key === 'B') {
      setTool('brush');
    } else if (e.key === 'f' || e.key === 'F') {
      setTool('fill');
    } else if (e.key === 'p' || e.key === 'P') {
      setTool('picker');
    } else if (e.key === 'g' || e.key === 'G') {
      toggleGrid();
    } else if (e.key === 'e' || e.key === 'E') {
      setTool('enemy');
    } else if (e.key >= '1' && e.key <= '8') {
      const idx = parseInt(e.key) - 1;
      if (idx < appData.tiles.length) {
        selectTile(appData.tiles[idx].symbol);
      }
    }
  });
}

function paintAt(rx, ry, tx, ty) {
  function setTile(x, y) {
    if (x >= 0 && x < 20 && y >= 0 && y < 10) {
      const row = appData.rooms[ry][rx][y];
      appData.rooms[ry][rx][y] = row.substring(0, x) + selectedTileSymbol + row.substring(x + 1);
    }
  }

  setTile(tx, ty);
  if (currentTool === 'brush2') {
    setTile(tx + 1, ty);
    setTile(tx, ty + 1);
    setTile(tx + 1, ty + 1);
  }
}

function floodFill(rx, ry, startX, startY, newSym) {
  const grid = appData.rooms[ry][rx];
  const targetSym = grid[startY][startX];
  if (targetSym === newSym) return;

  const queue = [[startX, startY]];
  const seen = new Set();

  while (queue.length > 0) {
    const [cx, cy] = queue.pop();
    const key = `${cx},${cy}`;
    if (seen.has(key)) continue;
    seen.add(key);

    if (grid[cy][cx] !== targetSym) continue;

    grid[cy] = grid[cy].substring(0, cx) + newSym + grid[cy].substring(cx + 1);

    if (cx > 0) queue.push([cx - 1, cy]);
    if (cx < 19) queue.push([cx + 1, cy]);
    if (cy > 0) queue.push([cx, cy - 1]);
    if (cy < 9) queue.push([cx, cy + 1]);
  }
}

// Backend API Calls
async function saveData() {
  const saveBtn = document.getElementById('saveBtn');
  saveBtn.textContent = "⏳ Sauvegarde...";
  saveBtn.disabled = true;

  try {
    const res = await fetch('/api/save', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        rooms: appData.rooms,
        enemies: appData.enemies,
        start_room: appData.start_room,
        player: appData.player
      })
    });
    const result = await res.json();
    if (result.success) {
      showToast(result.message || "Sauvegardé et recompilé avec succès !", "success");
    } else {
      showToast(result.message || "Erreur de compilation !", "error");
    }
  } catch (err) {
    showToast("Erreur de communication avec le serveur", "error");
  } finally {
    saveBtn.textContent = "💾 Sauvegarder";
    saveBtn.disabled = false;
  }
}

async function runVICE() {
  const runBtn = document.getElementById('runBtn');
  runBtn.textContent = "⏳ Lancement...";
  runBtn.disabled = true;

  try {
    const res = await fetch('/api/run', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        rooms: appData.rooms,
        enemies: appData.enemies,
        start_room: appData.start_room,
        player: appData.player
      })
    });
    const result = await res.json();
    if (result.success) {
      showToast(result.message || "VICE lancé !", "success");
    } else {
      showToast(result.message || "Échec lancement VICE", "error");
    }
  } catch (err) {
    showToast("Erreur lors du lancement de VICE", "error");
  } finally {
    runBtn.textContent = "▶ Tester (VICE)";
    runBtn.disabled = false;
  }
}

function showToast(msg, type = "success") {
  const toast = document.getElementById('toast');
  toast.textContent = msg;
  toast.className = `show ${type}`;
  setTimeout(() => {
    toast.className = '';
  }, 3500);
}

window.onload = init;
</script>
</body>
</html>
"""


def main():
    parser = argparse.ArgumentParser(description="Éditeur de niveau Zelda C64")
    parser.add_argument("--port", type=int, default=8080, help="Port HTTP local (défaut : 8080)")
    parser.add_argument("--no-browser", action="store_true", help="Ne pas ouvrir automatiquement le navigateur")
    args = parser.parse_args()

    port = args.port
    max_attempts = 10
    httpd = None

    for attempt in range(max_attempts):
        try:
            httpd = socketserver.TCPServer(("127.0.0.1", port), EditorHandler)
            break
        except OSError:
            print(f"Port {port} déjà utilisé, tentative sur {port + 1}...")
            port += 1

    if httpd is None:
        sys.exit("Impossible de lier le serveur HTTP à un port libre.")

    url = f"http://127.0.0.1:{port}"
    print(f"\n=======================================================")
    print(f"  ⚔️  ÉDITEUR DE NIVEAU ZELDA C64 DÉMARRÉ AVEC SUCCÈS")
    print(f"=======================================================")
    print(f"  Interface web disponible sur : {url}")
    print(f"  Appuyez sur Ctrl+C dans ce terminal pour quitter.")
    print(f"=======================================================\n")

    if not args.no_browser:
        threading.Timer(0.6, lambda: webbrowser.open(url)).start()

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nArrêt de l'éditeur de niveau. À bientôt dans Hyrule !")
        httpd.server_close()


if __name__ == "__main__":
    main()
