#!/usr/bin/env python3
"""
tools/editor.py - Éditeur de niveau visuel en Python pour Zelda C64.

Édition à la souris des tuiles de la carte, des mondes Overworld et Underworld,
positionnement de jusqu'à 4 ennemis par salle, sauvegarde automatique dans
assets/world.txt, assets/underworld.txt et src/enemies.asm, recompilation
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

OVERWORLD_ROOM_NAMES = []
for _ry in range(8):
    _row = []
    for _rx in range(16):
        _col_letter = chr(ord('A') + _rx)
        _row_num = _ry + 1
        _name = f"({_rx}, {_ry}) {_col_letter}-{_row_num}"
        if _rx == 7 and _ry == 7:
            _name += " [Depart Link - H-8]"
        elif _rx == 7 and _ry == 6:
            _name += " [Grotte Epee - H-7]"
        _row.append(_name)
    OVERWORLD_ROOM_NAMES.append(_row)


UNDERWORLD_ROOM_NAMES = [
    ["(0, 0) Grotte de l'Épée", "(1, 0) Entrée Donjon N1",   "(2, 0) Armurerie Secrète"],
    ["(0, 1) Salle des Pièges", "(1, 1) Grand Carrefour",    "(2, 1) Lac Souterrain"],
    ["(0, 2) Crypte Nord",      "(1, 2) Antre du Boss",      "(2, 2) Sanctuaire Triforce"]
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
    ],
    "old_man": [
        "..rrrr..",
        ".rrrrrr.",
        "rrrrrrrr",
        "rrwwssrr",
        "rrssbssr",
        "rrwwssrr",
        ".rwwwwr.",
        "..wwww..",
        "rrwwwwrr",
        "rrrrrrrr",
        "rrrrrrrr",
        ".rrrrrr.",
        "..rrrr..",
        "..rrrr..",
        "..rr..rr",
        "..rr..rr"
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


def parse_map(filename):
    path = os.path.join(BASE_DIR, filename)
    if not os.path.exists(path):
        return []
    with open(path, "r", encoding="utf-8") as f:
        lines = [l.rstrip("\r\n") for l in f]

    map_lines = [l for l in lines if not l.startswith(";") and l.strip()]
    if not map_lines:
        return []

    first_parts = map_lines[0].split(" ")
    rooms_x = len(first_parts)
    rooms_y = len(map_lines) // 10

    rooms = [[["" for _ in range(10)] for _ in range(rooms_x)] for _ in range(rooms_y)]

    for idx, l in enumerate(map_lines):
        r = idx // 10
        y = idx % 10
        parts = l.split(" ")
        for rx in range(rooms_x):
            if rx < len(parts):
                rooms[r][rx][y] = parts[rx]
            else:
                rooms[r][rx][y] = "." * 20
    return rooms


def parse_enemies():
    path = os.path.join(BASE_DIR, "src/enemies.asm")
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()

    m_block = re.search(r'world_enemies:\s*\n(.*?)(?:\n\s*;\s*-{10,}|\n\s*get_rand:)', text, re.DOTALL)
    if not m_block:
        return []

    block = m_block.group(1)
    slot_re = re.compile(r'(TYPE_[A-Z0-9_]+)\s*,\s*(\d+)\s*,\s*(\d+)')
    enemies = []
    for line in block.splitlines():
        if "!byte" in line:
            slots = slot_re.findall(line)
            room_slots = []
            for t, x, y in slots:
                room_slots.append({"type": t, "x": int(x), "y": int(y)})
            while len(room_slots) < 8:
                room_slots.append({"type": "TYPE_NONE", "x": 0, "y": 0})
            enemies.append(room_slots[:8])
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


def save_map_data(filename, rooms):
    path = os.path.join(BASE_DIR, filename)
    with open(path, "r", encoding="utf-8") as f:
        orig = f.read()
    lines = orig.splitlines()

    map_indices = []
    for i, l in enumerate(lines):
        if not l.startswith(";") and l.strip():
            map_indices.append(i)

    new_lines = list(lines)
    rooms_y = len(rooms)
    rooms_x = len(rooms[0]) if rooms_y > 0 else 0

    for idx, line_num in enumerate(map_indices):
        r = idx // 10
        y = idx % 10
        if r < rooms_y:
            row_parts = [rooms[r][rx][y] for rx in range(rooms_x)]
            new_lines[line_num] = " ".join(row_parts)

    reconstructed = "\n".join(new_lines) + ("\n" if orig.endswith("\n") else "")
    with open(path, "w", encoding="utf-8") as f:
        f.write(reconstructed)


def save_enemies_data(enemies):
    path = os.path.join(BASE_DIR, "src/enemies.asm")
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()

    lines_out = []
    for i, en_slots in enumerate(enemies):
        rx, ry = i % 16, i // 16
        col_letter = chr(ord('A') + rx) if rx < 26 else str(rx)
        row_num = ry + 1
        lines_out.append(f"        ; Salle {i:3d} : ({rx}, {ry}) {col_letter}-{row_num}")
        parts = []
        for e in en_slots[:8]:
            t = e.get("type", "TYPE_NONE")
            x = int(e.get("x", 0))
            y = int(e.get("y", 0))
            parts.append(f"{t:<11}, {x:3d}, {y:2d}")
        while len(parts) < 8:
            parts.append(f"{'TYPE_NONE':<11},   0,  0")
        lines_out.append("        !byte " + ",   ".join(parts))

    new_block = "world_enemies:\n" + "\n".join(lines_out) + "\n"

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
    # 1. Regenerate charset, map_overworld, map_underworld & tiles_data
    cmd_tilegen = [
        sys.executable,
        "tools/tilegen.py",
        "assets/tiles.txt",
        "assets/world.txt",
        "--charset", "src/charset.asm",
        "--tiles-out", "src/tiles_data.asm",
        "--map-out", "src/map_overworld.asm",
        "--underworld", "assets/underworld.txt",
        "--underworld-out", "src/map_underworld.asm"
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
        pass

    def do_GET(self):
        url = urllib.parse.urlparse(self.path)
        if url.path == "/" or url.path == "/index.html":
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(HTML_PAGE.encode("utf-8"))
        elif url.path == "/api/data":
            try:
                cfg, tiles = parse_tiles()
                rooms = parse_map("assets/world.txt")
                underworld_rooms = parse_map("assets/underworld.txt")
                enemies = parse_enemies()
                start_cfg = parse_start_config()

                data = {
                    "palette": PALETTE,
                    "color_names": COLOR_NAMES,
                    "config": cfg,
                    "tiles": tiles,
                    "rooms": rooms,
                    "underworld_rooms": underworld_rooms,
                    "room_names": OVERWORLD_ROOM_NAMES,
                    "underworld_room_names": UNDERWORLD_ROOM_NAMES,
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
            except Exception as e:
                err_res = json.dumps({"error": str(e)}).encode("utf-8")
                self.send_response(500)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(err_res)))
                self.end_headers()
                self.wfile.write(err_res)
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
                    save_map_data("assets/world.txt", payload["rooms"])
                if "underworld_rooms" in payload:
                    save_map_data("assets/underworld.txt", payload["underworld_rooms"])
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
            try:
                if "rooms" in payload:
                    save_map_data("assets/world.txt", payload["rooms"])
                if "underworld_rooms" in payload:
                    save_map_data("assets/underworld.txt", payload["underworld_rooms"])
                if "enemies" in payload:
                    save_enemies_data(payload["enemies"])
                if "start_room" in payload:
                    save_start_config(payload.get("start_room"), payload.get("player"))
                ok, msg = build_and_recompile()
            except Exception as e:
                ok, msg = False, str(e)

            if ok:
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
    --purple: #8b5cf6;
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
  .btn.realm-btn.active {
    background: #d97706;
    color: #fff;
    font-weight: 700;
    border-color: #f59e0b;
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
    width: 320px;
    background: var(--bg-panel);
    border-left: 1px solid var(--border);
    display: flex;
    flex-direction: column;
    overflow-y: auto;
  }

  /* Minimap */
  .minimap-container {
    display: grid;
    grid-template-columns: repeat(16, 1fr);
    gap: 2px;
    background: var(--bg-card);
    padding: 6px;
    border-radius: 6px;
    border: 1px solid var(--border);
    margin-bottom: 10px;
    max-height: 280px;
    overflow-y: auto;
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
    padding: 8px 10px;
    margin-bottom: 6px;
  }
  .enemy-card-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 6px;
    font-size: 11px;
    font-weight: 600;
  }
  .enemy-select {
    width: 100%;
    background: var(--bg-main);
    border: 1px solid var(--border);
    color: var(--text-main);
    padding: 5px;
    border-radius: 4px;
    font-size: 11px;
    margin-bottom: 6px;
    outline: none;
  }
  .enemy-coord-row {
    display: flex;
    align-items: center;
    gap: 8px;
    font-size: 11px;
  }
  .enemy-coord-row input {
    width: 48px;
    background: var(--bg-main);
    border: 1px solid var(--border);
    color: var(--text-main);
    padding: 3px 5px;
    border-radius: 4px;
    text-align: center;
    font-family: monospace;
    font-size: 11px;
  }
  .btn-sm {
    padding: 3px 6px;
    font-size: 10px;
    border-radius: 4px;
  }

  .underworld-note {
    background: rgba(245, 158, 11, 0.1);
    border: 1px solid var(--gold);
    padding: 8px;
    border-radius: 6px;
    font-size: 11px;
    color: var(--gold);
    margin-bottom: 8px;
    line-height: 1.4;
  }

  /* Shortcuts box */
  .shortcut-table {
    width: 100%;
    border-collapse: collapse;
    font-size: 11px;
    color: var(--text-muted);
  }
  .shortcut-table td { padding: 3px 0; }
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
  #toast.show { opacity: 1; transform: translateY(0); }
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
    <!-- Realm Switcher -->
    <div class="btn-group">
      <button class="btn realm-btn active" id="realmOverworldBtn" onclick="setRealm('overworld')">🌍 Surface (Overworld)</button>
      <button class="btn realm-btn" id="realmUnderworldBtn" onclick="setRealm('underworld')">🏰 Donjons (Underworld)</button>
    </div>

    <!-- View Mode -->
    <div class="btn-group">
      <button class="btn active" id="viewRoomBtn" onclick="setViewMode('room')">Salle (20×10)</button>
      <button class="btn" id="viewWorldBtn" onclick="setViewMode('world')">Monde (60×30)</button>
    </div>

    <!-- Undo / Redo -->
    <div class="btn-group">
      <button class="btn" onclick="undo()" title="Annuler (Ctrl+Z)" id="undoBtn">↩</button>
      <button class="btn" onclick="redo()" title="Rétablir (Ctrl+Y)" id="redoBtn">↪</button>
    </div>

    <!-- Zoom -->
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
      <div class="panel-title" id="minimapTitle">Carte Hyrule (16×8)</div>
      <div class="minimap-container" id="minimapContainer">
        <!-- rooms generated dynamically -->
      </div>
      <button class="btn btn-sm" id="btnStartRoom" style="width:100%" onclick="setStartRoom()">
        ★ Définir salle active comme départ
      </button>
    </div>

    <div class="panel-section" id="enemySection">
      <div class="panel-title">
        <span>Ennemis de la Salle</span>
        <span style="font-size:10px; color:var(--gold)">8 Slots (VIC-II IRQ)</span>
      </div>

      <div id="underworldEnemyNotice" class="underworld-note" style="display:none;">
        ℹ️ Les ennemis sont gérés sur la surface (Overworld). En donjon, la salle (0,0) abrite le Vieil Homme et l'Épée !
      </div>
      
      <div style="max-height: 440px; overflow-y: auto; padding-right: 4px;">
      <!-- Enemy Slot 0 -->
      <div class="enemy-card">
        <div class="enemy-card-header">
          <span style="color:var(--gold)">Ennemi #1</span>
          <button class="btn btn-sm" onclick="pickEnemyTarget(0)">🎯 Poser</button>
        </div>
        <select class="enemy-select" id="en0_type" onchange="updateEnemyFromUI(0)">
          <option value="TYPE_NONE">Aucun (TYPE_NONE)</option>
          <option value="TYPE_OCTO_RED">Octorok Rouge (TYPE_OCTO_RED)</option>
          <option value="TYPE_OCTO_BLUE">Octorok Bleu (TYPE_OCTO_BLUE)</option>
          <option value="TYPE_MOBLIN_RED">Moblin Rouge (TYPE_MOBLIN_RED)</option>
          <option value="TYPE_MOBLIN_BLUE">Moblin Bleu (TYPE_MOBLIN_BLUE)</option>
          <option value="TYPE_TEKTITE_RED">Tektite Rouge (TYPE_TEKTITE_RED)</option>
          <option value="TYPE_TEKTITE_BLUE">Tektite Bleu (TYPE_TEKTITE_BLUE)</option>
          <option value="TYPE_LEEVER_RED">Leever Rouge (TYPE_LEEVER_RED)</option>
          <option value="TYPE_LEEVER_BLUE">Leever Bleu (TYPE_LEEVER_BLUE)</option>
          <option value="TYPE_PEAHAT">Peahat (TYPE_PEAHAT)</option>
          <option value="TYPE_ARMOS">Armos (TYPE_ARMOS)</option>
          <option value="TYPE_GHINI">Ghini (TYPE_GHINI)</option>
          <option value="TYPE_ZORA">Zora (TYPE_ZORA)</option>
          <option value="TYPE_LYNEL_RED">Lynel Rouge (TYPE_LYNEL_RED)</option>
          <option value="TYPE_LYNEL_BLUE">Lynel Bleu (TYPE_LYNEL_BLUE)</option>
          <option value="TYPE_OCTO">Octorok (TYPE_OCTO)</option>
          <option value="TYPE_MOBLIN">Moblin (TYPE_MOBLIN)</option>
        </select>
        <div class="enemy-coord-row">
          <span>X:</span> <input type="number" id="en0_x" min="0" max="19" onchange="updateEnemyFromUI(0)">
          <span>Y:</span> <input type="number" id="en0_y" min="0" max="9" onchange="updateEnemyFromUI(0)">
        </div>
      </div>

      <!-- Enemy Slot 1 -->
      <div class="enemy-card">
        <div class="enemy-card-header">
          <span style="color:var(--gold)">Ennemi #2</span>
          <button class="btn btn-sm" onclick="pickEnemyTarget(1)">🎯 Poser</button>
        </div>
        <select class="enemy-select" id="en1_type" onchange="updateEnemyFromUI(1)">
          <option value="TYPE_NONE">Aucun (TYPE_NONE)</option>
          <option value="TYPE_OCTO_RED">Octorok Rouge (TYPE_OCTO_RED)</option>
          <option value="TYPE_OCTO_BLUE">Octorok Bleu (TYPE_OCTO_BLUE)</option>
          <option value="TYPE_MOBLIN_RED">Moblin Rouge (TYPE_MOBLIN_RED)</option>
          <option value="TYPE_MOBLIN_BLUE">Moblin Bleu (TYPE_MOBLIN_BLUE)</option>
          <option value="TYPE_TEKTITE_RED">Tektite Rouge (TYPE_TEKTITE_RED)</option>
          <option value="TYPE_TEKTITE_BLUE">Tektite Bleu (TYPE_TEKTITE_BLUE)</option>
          <option value="TYPE_LEEVER_RED">Leever Rouge (TYPE_LEEVER_RED)</option>
          <option value="TYPE_LEEVER_BLUE">Leever Bleu (TYPE_LEEVER_BLUE)</option>
          <option value="TYPE_PEAHAT">Peahat (TYPE_PEAHAT)</option>
          <option value="TYPE_ARMOS">Armos (TYPE_ARMOS)</option>
          <option value="TYPE_GHINI">Ghini (TYPE_GHINI)</option>
          <option value="TYPE_ZORA">Zora (TYPE_ZORA)</option>
          <option value="TYPE_LYNEL_RED">Lynel Rouge (TYPE_LYNEL_RED)</option>
          <option value="TYPE_LYNEL_BLUE">Lynel Bleu (TYPE_LYNEL_BLUE)</option>
          <option value="TYPE_OCTO">Octorok (TYPE_OCTO)</option>
          <option value="TYPE_MOBLIN">Moblin (TYPE_MOBLIN)</option>
        </select>
        <div class="enemy-coord-row">
          <span>X:</span> <input type="number" id="en1_x" min="0" max="19" onchange="updateEnemyFromUI(1)">
          <span>Y:</span> <input type="number" id="en1_y" min="0" max="9" onchange="updateEnemyFromUI(1)">
        </div>
      </div>

      <!-- Enemy Slot 2 -->
      <div class="enemy-card">
        <div class="enemy-card-header">
          <span style="color:var(--gold)">Ennemi #3</span>
          <button class="btn btn-sm" onclick="pickEnemyTarget(2)">🎯 Poser</button>
        </div>
        <select class="enemy-select" id="en2_type" onchange="updateEnemyFromUI(2)">
          <option value="TYPE_NONE">Aucun (TYPE_NONE)</option>
          <option value="TYPE_OCTO_RED">Octorok Rouge (TYPE_OCTO_RED)</option>
          <option value="TYPE_OCTO_BLUE">Octorok Bleu (TYPE_OCTO_BLUE)</option>
          <option value="TYPE_MOBLIN_RED">Moblin Rouge (TYPE_MOBLIN_RED)</option>
          <option value="TYPE_MOBLIN_BLUE">Moblin Bleu (TYPE_MOBLIN_BLUE)</option>
          <option value="TYPE_TEKTITE_RED">Tektite Rouge (TYPE_TEKTITE_RED)</option>
          <option value="TYPE_TEKTITE_BLUE">Tektite Bleu (TYPE_TEKTITE_BLUE)</option>
          <option value="TYPE_LEEVER_RED">Leever Rouge (TYPE_LEEVER_RED)</option>
          <option value="TYPE_LEEVER_BLUE">Leever Bleu (TYPE_LEEVER_BLUE)</option>
          <option value="TYPE_PEAHAT">Peahat (TYPE_PEAHAT)</option>
          <option value="TYPE_ARMOS">Armos (TYPE_ARMOS)</option>
          <option value="TYPE_GHINI">Ghini (TYPE_GHINI)</option>
          <option value="TYPE_ZORA">Zora (TYPE_ZORA)</option>
          <option value="TYPE_LYNEL_RED">Lynel Rouge (TYPE_LYNEL_RED)</option>
          <option value="TYPE_LYNEL_BLUE">Lynel Bleu (TYPE_LYNEL_BLUE)</option>
          <option value="TYPE_OCTO">Octorok (TYPE_OCTO)</option>
          <option value="TYPE_MOBLIN">Moblin (TYPE_MOBLIN)</option>
        </select>
        <div class="enemy-coord-row">
          <span>X:</span> <input type="number" id="en2_x" min="0" max="19" onchange="updateEnemyFromUI(2)">
          <span>Y:</span> <input type="number" id="en2_y" min="0" max="9" onchange="updateEnemyFromUI(2)">
        </div>
      </div>

      <!-- Enemy Slot 3 -->
      <div class="enemy-card">
        <div class="enemy-card-header">
          <span style="color:var(--gold)">Ennemi #4</span>
          <button class="btn btn-sm" onclick="pickEnemyTarget(3)">🎯 Poser</button>
        </div>
        <select class="enemy-select" id="en3_type" onchange="updateEnemyFromUI(3)">
          <option value="TYPE_NONE">Aucun (TYPE_NONE)</option>
          <option value="TYPE_OCTO_RED">Octorok Rouge (TYPE_OCTO_RED)</option>
          <option value="TYPE_OCTO_BLUE">Octorok Bleu (TYPE_OCTO_BLUE)</option>
          <option value="TYPE_MOBLIN_RED">Moblin Rouge (TYPE_MOBLIN_RED)</option>
          <option value="TYPE_MOBLIN_BLUE">Moblin Bleu (TYPE_MOBLIN_BLUE)</option>
          <option value="TYPE_TEKTITE_RED">Tektite Rouge (TYPE_TEKTITE_RED)</option>
          <option value="TYPE_TEKTITE_BLUE">Tektite Bleu (TYPE_TEKTITE_BLUE)</option>
          <option value="TYPE_LEEVER_RED">Leever Rouge (TYPE_LEEVER_RED)</option>
          <option value="TYPE_LEEVER_BLUE">Leever Bleu (TYPE_LEEVER_BLUE)</option>
          <option value="TYPE_PEAHAT">Peahat (TYPE_PEAHAT)</option>
          <option value="TYPE_ARMOS">Armos (TYPE_ARMOS)</option>
          <option value="TYPE_GHINI">Ghini (TYPE_GHINI)</option>
          <option value="TYPE_ZORA">Zora (TYPE_ZORA)</option>
          <option value="TYPE_LYNEL_RED">Lynel Rouge (TYPE_LYNEL_RED)</option>
          <option value="TYPE_LYNEL_BLUE">Lynel Bleu (TYPE_LYNEL_BLUE)</option>
          <option value="TYPE_OCTO">Octorok (TYPE_OCTO)</option>
          <option value="TYPE_MOBLIN">Moblin (TYPE_MOBLIN)</option>
        </select>
        <div class="enemy-coord-row">
          <span>X:</span> <input type="number" id="en3_x" min="0" max="19" onchange="updateEnemyFromUI(3)">
          <span>Y:</span> <input type="number" id="en3_y" min="0" max="9" onchange="updateEnemyFromUI(3)">
        </div>
      </div>

      <!-- Enemy Slot 4 -->
      <div class="enemy-card">
        <div class="enemy-card-header">
          <span style="color:var(--gold)">Ennemi #5</span>
          <button class="btn btn-sm" onclick="pickEnemyTarget(4)">🎯 Poser</button>
        </div>
        <select class="enemy-select" id="en4_type" onchange="updateEnemyFromUI(4)">
          <option value="TYPE_NONE">Aucun (TYPE_NONE)</option>
          <option value="TYPE_OCTO_RED">Octorok Rouge (TYPE_OCTO_RED)</option>
          <option value="TYPE_OCTO_BLUE">Octorok Bleu (TYPE_OCTO_BLUE)</option>
          <option value="TYPE_MOBLIN_RED">Moblin Rouge (TYPE_MOBLIN_RED)</option>
          <option value="TYPE_MOBLIN_BLUE">Moblin Bleu (TYPE_MOBLIN_BLUE)</option>
          <option value="TYPE_TEKTITE_RED">Tektite Rouge (TYPE_TEKTITE_RED)</option>
          <option value="TYPE_TEKTITE_BLUE">Tektite Bleu (TYPE_TEKTITE_BLUE)</option>
          <option value="TYPE_LEEVER_RED">Leever Rouge (TYPE_LEEVER_RED)</option>
          <option value="TYPE_LEEVER_BLUE">Leever Bleu (TYPE_LEEVER_BLUE)</option>
          <option value="TYPE_PEAHAT">Peahat (TYPE_PEAHAT)</option>
          <option value="TYPE_ARMOS">Armos (TYPE_ARMOS)</option>
          <option value="TYPE_GHINI">Ghini (TYPE_GHINI)</option>
          <option value="TYPE_ZORA">Zora (TYPE_ZORA)</option>
          <option value="TYPE_LYNEL_RED">Lynel Rouge (TYPE_LYNEL_RED)</option>
          <option value="TYPE_LYNEL_BLUE">Lynel Bleu (TYPE_LYNEL_BLUE)</option>
          <option value="TYPE_OCTO">Octorok (TYPE_OCTO)</option>
          <option value="TYPE_MOBLIN">Moblin (TYPE_MOBLIN)</option>
        </select>
        <div class="enemy-coord-row">
          <span>X:</span> <input type="number" id="en4_x" min="0" max="19" onchange="updateEnemyFromUI(4)">
          <span>Y:</span> <input type="number" id="en4_y" min="0" max="9" onchange="updateEnemyFromUI(4)">
        </div>
      </div>

      <!-- Enemy Slot 5 -->
      <div class="enemy-card">
        <div class="enemy-card-header">
          <span style="color:var(--gold)">Ennemi #6</span>
          <button class="btn btn-sm" onclick="pickEnemyTarget(5)">🎯 Poser</button>
        </div>
        <select class="enemy-select" id="en5_type" onchange="updateEnemyFromUI(5)">
          <option value="TYPE_NONE">Aucun (TYPE_NONE)</option>
          <option value="TYPE_OCTO_RED">Octorok Rouge (TYPE_OCTO_RED)</option>
          <option value="TYPE_OCTO_BLUE">Octorok Bleu (TYPE_OCTO_BLUE)</option>
          <option value="TYPE_MOBLIN_RED">Moblin Rouge (TYPE_MOBLIN_RED)</option>
          <option value="TYPE_MOBLIN_BLUE">Moblin Bleu (TYPE_MOBLIN_BLUE)</option>
          <option value="TYPE_TEKTITE_RED">Tektite Rouge (TYPE_TEKTITE_RED)</option>
          <option value="TYPE_TEKTITE_BLUE">Tektite Bleu (TYPE_TEKTITE_BLUE)</option>
          <option value="TYPE_LEEVER_RED">Leever Rouge (TYPE_LEEVER_RED)</option>
          <option value="TYPE_LEEVER_BLUE">Leever Bleu (TYPE_LEEVER_BLUE)</option>
          <option value="TYPE_PEAHAT">Peahat (TYPE_PEAHAT)</option>
          <option value="TYPE_ARMOS">Armos (TYPE_ARMOS)</option>
          <option value="TYPE_GHINI">Ghini (TYPE_GHINI)</option>
          <option value="TYPE_ZORA">Zora (TYPE_ZORA)</option>
          <option value="TYPE_LYNEL_RED">Lynel Rouge (TYPE_LYNEL_RED)</option>
          <option value="TYPE_LYNEL_BLUE">Lynel Bleu (TYPE_LYNEL_BLUE)</option>
          <option value="TYPE_OCTO">Octorok (TYPE_OCTO)</option>
          <option value="TYPE_MOBLIN">Moblin (TYPE_MOBLIN)</option>
        </select>
        <div class="enemy-coord-row">
          <span>X:</span> <input type="number" id="en5_x" min="0" max="19" onchange="updateEnemyFromUI(5)">
          <span>Y:</span> <input type="number" id="en5_y" min="0" max="9" onchange="updateEnemyFromUI(5)">
        </div>
      </div>

      <!-- Enemy Slot 6 -->
      <div class="enemy-card">
        <div class="enemy-card-header">
          <span style="color:var(--gold)">Ennemi #7</span>
          <button class="btn btn-sm" onclick="pickEnemyTarget(6)">🎯 Poser</button>
        </div>
        <select class="enemy-select" id="en6_type" onchange="updateEnemyFromUI(6)">
          <option value="TYPE_NONE">Aucun (TYPE_NONE)</option>
          <option value="TYPE_OCTO_RED">Octorok Rouge (TYPE_OCTO_RED)</option>
          <option value="TYPE_OCTO_BLUE">Octorok Bleu (TYPE_OCTO_BLUE)</option>
          <option value="TYPE_MOBLIN_RED">Moblin Rouge (TYPE_MOBLIN_RED)</option>
          <option value="TYPE_MOBLIN_BLUE">Moblin Bleu (TYPE_MOBLIN_BLUE)</option>
          <option value="TYPE_TEKTITE_RED">Tektite Rouge (TYPE_TEKTITE_RED)</option>
          <option value="TYPE_TEKTITE_BLUE">Tektite Bleu (TYPE_TEKTITE_BLUE)</option>
          <option value="TYPE_LEEVER_RED">Leever Rouge (TYPE_LEEVER_RED)</option>
          <option value="TYPE_LEEVER_BLUE">Leever Bleu (TYPE_LEEVER_BLUE)</option>
          <option value="TYPE_PEAHAT">Peahat (TYPE_PEAHAT)</option>
          <option value="TYPE_ARMOS">Armos (TYPE_ARMOS)</option>
          <option value="TYPE_GHINI">Ghini (TYPE_GHINI)</option>
          <option value="TYPE_ZORA">Zora (TYPE_ZORA)</option>
          <option value="TYPE_LYNEL_RED">Lynel Rouge (TYPE_LYNEL_RED)</option>
          <option value="TYPE_LYNEL_BLUE">Lynel Bleu (TYPE_LYNEL_BLUE)</option>
          <option value="TYPE_OCTO">Octorok (TYPE_OCTO)</option>
          <option value="TYPE_MOBLIN">Moblin (TYPE_MOBLIN)</option>
        </select>
        <div class="enemy-coord-row">
          <span>X:</span> <input type="number" id="en6_x" min="0" max="19" onchange="updateEnemyFromUI(6)">
          <span>Y:</span> <input type="number" id="en6_y" min="0" max="9" onchange="updateEnemyFromUI(6)">
        </div>
      </div>

      <!-- Enemy Slot 7 -->
      <div class="enemy-card">
        <div class="enemy-card-header">
          <span style="color:var(--gold)">Ennemi #8</span>
          <button class="btn btn-sm" onclick="pickEnemyTarget(7)">🎯 Poser</button>
        </div>
        <select class="enemy-select" id="en7_type" onchange="updateEnemyFromUI(7)">
          <option value="TYPE_NONE">Aucun (TYPE_NONE)</option>
          <option value="TYPE_OCTO_RED">Octorok Rouge (TYPE_OCTO_RED)</option>
          <option value="TYPE_OCTO_BLUE">Octorok Bleu (TYPE_OCTO_BLUE)</option>
          <option value="TYPE_MOBLIN_RED">Moblin Rouge (TYPE_MOBLIN_RED)</option>
          <option value="TYPE_MOBLIN_BLUE">Moblin Bleu (TYPE_MOBLIN_BLUE)</option>
          <option value="TYPE_TEKTITE_RED">Tektite Rouge (TYPE_TEKTITE_RED)</option>
          <option value="TYPE_TEKTITE_BLUE">Tektite Bleu (TYPE_TEKTITE_BLUE)</option>
          <option value="TYPE_LEEVER_RED">Leever Rouge (TYPE_LEEVER_RED)</option>
          <option value="TYPE_LEEVER_BLUE">Leever Bleu (TYPE_LEEVER_BLUE)</option>
          <option value="TYPE_PEAHAT">Peahat (TYPE_PEAHAT)</option>
          <option value="TYPE_ARMOS">Armos (TYPE_ARMOS)</option>
          <option value="TYPE_GHINI">Ghini (TYPE_GHINI)</option>
          <option value="TYPE_ZORA">Zora (TYPE_ZORA)</option>
          <option value="TYPE_LYNEL_RED">Lynel Rouge (TYPE_LYNEL_RED)</option>
          <option value="TYPE_LYNEL_BLUE">Lynel Bleu (TYPE_LYNEL_BLUE)</option>
          <option value="TYPE_OCTO">Octorok (TYPE_OCTO)</option>
          <option value="TYPE_MOBLIN">Moblin (TYPE_MOBLIN)</option>
        </select>
        <div class="enemy-coord-row">
          <span>X:</span> <input type="number" id="en7_x" min="0" max="19" onchange="updateEnemyFromUI(7)">
          <span>Y:</span> <input type="number" id="en7_y" min="0" max="9" onchange="updateEnemyFromUI(7)">
        </div>
      </div>
      </div>

      <button class="btn btn-sm" style="width:100%; color:var(--red); margin-top:4px;" onclick="clearRoomEnemies()">
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
let currentRealm = 'overworld'; // 'overworld' | 'underworld'
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
  try {
    const res = await fetch('/api/data');
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      showToast("Erreur chargement : " + (err.error || res.statusText), "error");
      return;
    }
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
    showToast("Données Zelda C64 (Overworld 16×8 + Underworld) chargées !", "success");
  } catch (e) {
    showToast("Erreur de communication : " + e.message, "error");
    console.error(e);
  }
}

function getActiveRooms() {
  if (!appData) return [];
  return currentRealm === 'overworld' ? appData.rooms : appData.underworld_rooms;
}

function getActiveRoomNames() {
  if (!appData) return [];
  return currentRealm === 'overworld' ? appData.room_names : appData.underworld_room_names;
}

function getRoomDims() {
  const rooms = getActiveRooms();
  if (!rooms || !rooms.length || !rooms[0]) return { x: 3, y: 3 };
  return { x: rooms[0].length, y: rooms.length };
}

function getRoomIndex(rx, ry) {
  const dims = getRoomDims();
  return ry * dims.x + rx;
}

function getTileSize() {
  const dims = getRoomDims();
  if (viewMode === 'world') {
    if (dims.x > 4) {
      return 6 * zoomLevel;
    }
    return 16 * zoomLevel;
  }
  return 16 * zoomLevel;
}

function setRealm(realm) {
  if (currentRealm === realm) return;
  currentRealm = realm;
  document.getElementById('realmOverworldBtn').classList.toggle('active', realm === 'overworld');
  document.getElementById('realmUnderworldBtn').classList.toggle('active', realm === 'underworld');

  const dims = getRoomDims();
  if (currentRoom.x >= dims.x || currentRoom.y >= dims.y) {
    if (realm === 'overworld' && appData.start_room) {
      currentRoom = { ...appData.start_room };
    } else {
      currentRoom = { x: 0, y: 0 };
    }
  }

  document.getElementById('minimapTitle').textContent =
    realm === 'overworld' ? 'Carte Hyrule (16×8)' : 'Minimap Donjon (3×3)';
  document.getElementById('underworldEnemyNotice').style.display =
    realm === 'underworld' ? 'block' : 'none';
  document.getElementById('btnStartRoom').style.display =
    realm === 'overworld' ? 'block' : 'none';

  renderMinimap();
  updateUI();
  renderMainCanvas();
  showToast(`Basculé vers : ${realm === 'overworld' ? '🌍 Surface (Overworld 16×8)' : '🏰 Souterrain (Underworld)'}`, 'success');
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
  const white = appData.palette[1];  // white
  const black = appData.palette[0];  // black

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
        else if (ch === 'r') col = red;
        else if (ch === 'w') col = white;
        else if (ch === 'k') col = black;
        ctx.fillStyle = col;
        ctx.fillRect(x * 2, y, 2, 1);
      }
    });
    return cvs;
  }

  actorCanvases['link'] = renderActor(appData.actor_sprites.link, green);
  actorCanvases['octo'] = renderActor(appData.actor_sprites.octo, red);
  actorCanvases['moblin'] = renderActor(appData.actor_sprites.moblin, red);
  actorCanvases['old_man'] = renderActor(appData.actor_sprites.old_man, red);
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
    underworld_rooms: JSON.parse(JSON.stringify(appData.underworld_rooms)),
    enemies: JSON.parse(JSON.stringify(appData.enemies)),
    start_room: { ...appData.start_room },
    player: { ...appData.player }
  });
  if (undoStack.length > 50) undoStack.shift();
  redoStack.length = 0;
}

function undo() {
  if (undoStack.length === 0) return;
  redoStack.push({
    rooms: JSON.parse(JSON.stringify(appData.rooms)),
    underworld_rooms: JSON.parse(JSON.stringify(appData.underworld_rooms)),
    enemies: JSON.parse(JSON.stringify(appData.enemies)),
    start_room: { ...appData.start_room },
    player: { ...appData.player }
  });
  const state = undoStack.pop();
  appData.rooms = state.rooms;
  appData.underworld_rooms = state.underworld_rooms;
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
    underworld_rooms: JSON.parse(JSON.stringify(appData.underworld_rooms)),
    enemies: JSON.parse(JSON.stringify(appData.enemies)),
    start_room: { ...appData.start_room },
    player: { ...appData.player }
  });
  const state = redoStack.pop();
  appData.rooms = state.rooms;
  appData.underworld_rooms = state.underworld_rooms;
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
  const rooms = getActiveRooms();
  if (!rooms || !rooms.length || !rooms[0]) return;
  const dims = getRoomDims();

  container.style.gridTemplateColumns = `repeat(${dims.x}, 1fr)`;
  container.style.gap = dims.x > 4 ? '2px' : '4px';

  for (let ry = 0; ry < dims.y; ry++) {
    for (let rx = 0; rx < dims.x; rx++) {
      const cell = document.createElement('div');
      cell.className = 'minimap-cell' + (currentRoom.x === rx && currentRoom.y === ry ? ' active' : '');
      const colLetter = String.fromCharCode(65 + rx);
      const rowNum = ry + 1;
      cell.title = `Salle (${rx}, ${ry}) : ${colLetter}-${rowNum}`;
      cell.onclick = () => selectRoom(rx, ry);

      const cvs = document.createElement('canvas');
      cvs.width = 20 * 16;
      cvs.height = 10 * 16;
      const ctx = cvs.getContext('2d');
      ctx.imageSmoothingEnabled = false;

      const room = rooms[ry][rx];
      for (let y = 0; y < 10; y++) {
        for (let x = 0; x < 20; x++) {
          const sym = room[y][x];
          const tileCvs = tileCanvases[sym];
          if (tileCvs) ctx.drawImage(tileCvs, x * 16, y * 16);
        }
      }

      // Draw enemies on minimap in Overworld
      if (currentRealm === 'overworld') {
        const rIdx = getRoomIndex(rx, ry);
        const rEnemies = appData.enemies[rIdx] || [];
        rEnemies.forEach(e => {
          if (e.type && e.type !== 'TYPE_NONE') {
            ctx.fillStyle = e.type.includes('BLUE') ? '#3b82f6' : (e.type.includes('LYNEL') ? '#dc2626' : (e.type.includes('PEAHAT') ? '#eab308' : (e.type.includes('GHINI') ? '#a855f7' : (e.type.includes('ZORA') ? '#06b6d4' : '#ef4444'))));
            ctx.fillRect(e.x * 16 + 2, e.y * 16 + 2, 12, 12);
          }
        });

        // Draw start marker
        if (appData.start_room.x === rx && appData.start_room.y === ry) {
          const px = appData.player ? appData.player.tile_x : 9;
          const py = appData.player ? appData.player.tile_y : 7;
          ctx.fillStyle = '#10b981';
          ctx.fillRect(px * 16 + 1, py * 16 + 1, 14, 14);

          const star = document.createElement('div');
          star.className = 'start-star';
          star.textContent = '★';
          cell.appendChild(star);
        }
      } else {
        // Underworld markers
        if (rx === 0 && ry === 0) {
          ctx.fillStyle = '#f59e0b';
          ctx.fillRect(10 * 16 + 2, 3 * 16 + 2, 14, 14);
        }
      }

      if (dims.x <= 4) {
        const badge = document.createElement('div');
        badge.className = 'minimap-badge';
        badge.textContent = `${rx},${ry}`;
        cell.appendChild(badge);
      }

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
  if (currentRealm !== 'overworld') return;
  pushHistory();
  appData.start_room = { ...currentRoom };
  renderMinimap();
  renderMainCanvas();
  showToast(`Salle (${currentRoom.x}, ${currentRoom.y}) définie comme point de départ !`, "success");
}

function updateUI() {
  const rx = currentRoom.x;
  const ry = currentRoom.y;
  const rIdx = getRoomIndex(rx, ry);
  const names = getActiveRoomNames();
  const colLetter = String.fromCharCode(65 + rx);
  const rowNum = ry + 1;
  const rName = (names && names[ry] && names[ry][rx]) ? names[ry][rx] : `(${rx}, ${ry}) ${colLetter}-${rowNum}`;

  document.getElementById('stageRoomTitle').textContent = `Salle (${rx}, ${ry}) : ${rName}`;
  document.getElementById('roomCoordPill').textContent = `${colLetter}-${rowNum} (${rx}, ${ry})`;

  // Update enemy cards (8 slots)
  const rEnemies = appData.enemies[rIdx] || [];

  for (let slot = 0; slot < 8; slot++) {
    const e = rEnemies[slot] || { type: 'TYPE_NONE', x: 0, y: 0 };
    const typeEl = document.getElementById(`en${slot}_type`);
    const xEl = document.getElementById(`en${slot}_x`);
    const yEl = document.getElementById(`en${slot}_y`);
    if (typeEl) typeEl.value = e.type;
    if (xEl) xEl.value = e.x;
    if (yEl) yEl.value = e.y;
  }
}

function updateEnemyFromUI(slot) {
  pushHistory();
  const rIdx = getRoomIndex(currentRoom.x, currentRoom.y);
  const type = document.getElementById(`en${slot}_type`).value;
  const x = Math.max(0, Math.min(19, parseInt(document.getElementById(`en${slot}_x`).value) || 0));
  const y = Math.max(0, Math.min(9, parseInt(document.getElementById(`en${slot}_y`).value) || 0));

  if (!appData.enemies[rIdx]) appData.enemies[rIdx] = [];
  while (appData.enemies[rIdx].length <= slot) {
    appData.enemies[rIdx].push({ type: 'TYPE_NONE', x: 0, y: 0 });
  }

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
  const rIdx = getRoomIndex(currentRoom.x, currentRoom.y);
  appData.enemies[rIdx] = [];
  for (let s = 0; s < 8; s++) {
    appData.enemies[rIdx].push({ type: 'TYPE_NONE', x: 0, y: 0 });
  }
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

  const tileSize = getTileSize();
  const rooms = getActiveRooms();
  if (!rooms || !rooms.length || !rooms[0]) return;
  const dims = getRoomDims();

  if (viewMode === 'room') {
    canvas.width = 20 * tileSize;
    canvas.height = 10 * tileSize;

    const rx = currentRoom.x;
    const ry = currentRoom.y;
    const room = (rooms[ry] && rooms[ry][rx]) ? rooms[ry][rx] : null;
    if (!room) return;

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

    // 3. Actors overlay
    if (currentRealm === 'overworld') {
      // Draw Link (if starting room)
      if (appData.start_room.x === rx && appData.start_room.y === ry) {
        const px = appData.player ? appData.player.tile_x : 9;
        const py = appData.player ? appData.player.tile_y : 7;
        drawActorBadge(ctx, actorCanvases['link'], px, py, tileSize, "LINK", "#10b981");
      }

      // Draw enemies (all 8 slots)
      const rIdx = getRoomIndex(rx, ry);
      const rEnemies = appData.enemies[rIdx] || [];
      rEnemies.forEach((e, idx) => {
        if (!e.type || e.type === 'TYPE_NONE') return;
        let color = '#ef4444';
        let label = `EN #${idx+1}`;
        let icon = actorCanvases['octo'];
        if (e.type.includes('OCTO')) {
          color = e.type.includes('BLUE') ? '#3b82f6' : '#ef4444';
          label = `OCTO #${idx+1}`;
          icon = actorCanvases['octo'];
        } else if (e.type.includes('MOBLIN')) {
          color = e.type.includes('BLUE') ? '#3b82f6' : '#f97316';
          label = `MOBLIN #${idx+1}`;
          icon = actorCanvases['moblin'];
        } else if (e.type.includes('LYNEL')) {
          color = e.type.includes('BLUE') ? '#3b82f6' : '#dc2626';
          label = `LYNEL #${idx+1}`;
          icon = actorCanvases['moblin'];
        } else if (e.type.includes('TEKTITE')) {
          color = e.type.includes('BLUE') ? '#3b82f6' : '#f87171';
          label = `TEKTITE #${idx+1}`;
          icon = actorCanvases['octo'];
        } else if (e.type.includes('LEEVER')) {
          color = e.type.includes('BLUE') ? '#3b82f6' : '#fb923c';
          label = `LEEVER #${idx+1}`;
          icon = actorCanvases['octo'];
        } else if (e.type.includes('PEAHAT')) {
          color = '#eab308';
          label = `PEAHAT #${idx+1}`;
          icon = actorCanvases['octo'];
        } else if (e.type.includes('GHINI')) {
          color = '#a855f7';
          label = `GHINI #${idx+1}`;
          icon = actorCanvases['octo'];
        } else if (e.type.includes('ZORA')) {
          color = '#06b6d4';
          label = `ZORA #${idx+1}`;
          icon = actorCanvases['octo'];
        } else if (e.type.includes('ARMOS')) {
          color = '#78716c';
          label = `ARMOS #${idx+1}`;
          icon = actorCanvases['moblin'];
        }
        drawActorBadge(ctx, icon, e.x, e.y, tileSize, label, color);
      });
    } else {
      // Underworld actors
      if (rx === 0 && ry === 0) {
        // Old Man Cave room
        drawActorBadge(ctx, actorCanvases['old_man'], 10, 3, tileSize, "OLD MAN", "#ef4444");
      }
    }

  } else {
    // World View (dims.x * 20 by dims.y * 10)
    canvas.width = dims.x * 20 * tileSize;
    canvas.height = dims.y * 10 * tileSize;

    for (let ry = 0; ry < dims.y; ry++) {
      for (let rx = 0; rx < dims.x; rx++) {
        const room = rooms[ry][rx];
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
    for (let rx = 1; rx < dims.x; rx++) {
      ctx.beginPath();
      ctx.moveTo(rx * 20 * tileSize, 0);
      ctx.lineTo(rx * 20 * tileSize, dims.y * 10 * tileSize);
      ctx.stroke();
    }
    for (let ry = 1; ry < dims.y; ry++) {
      ctx.beginPath();
      ctx.moveTo(0, ry * 10 * tileSize);
      ctx.lineTo(dims.x * 20 * tileSize, ry * 10 * tileSize);
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
  ctx.fillStyle = "rgba(0, 0, 0, 0.6)";
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
    const tileSize = getTileSize();
    const clickX = e.clientX - rect.left;
    const clickY = e.clientY - rect.top;
    const dims = getRoomDims();

    let tx = Math.floor(clickX / tileSize);
    let ty = Math.floor(clickY / tileSize);

    if (viewMode === 'room') {
      tx = Math.max(0, Math.min(19, tx));
      ty = Math.max(0, Math.min(9, ty));
      return { tx, ty, rx: currentRoom.x, ry: currentRoom.y };
    } else {
      const maxX = dims.x * 20 - 1;
      const maxY = dims.y * 10 - 1;
      tx = Math.max(0, Math.min(maxX, tx));
      ty = Math.max(0, Math.min(maxY, ty));
      const rx = Math.floor(tx / 20);
      const ry = Math.floor(ty / 10);
      return { tx: tx % 20, ty: ty % 10, rx, ry, globalX: tx, globalY: ty };
    }
  }

  canvas.addEventListener('contextmenu', e => {
    e.preventDefault();
    const { tx, ty, rx, ry } = getTileCoords(e);
    const rooms = getActiveRooms();
    const sym = rooms[ry][rx][ty][tx];
    selectTile(sym);
    showToast(`Tuile copiée : ${sym}`, "success");
  });

  canvas.addEventListener('mousedown', e => {
    if (e.button === 2) return;
    const { tx, ty, rx, ry } = getTileCoords(e);
    const rooms = getActiveRooms();

    // If clicked in another room in World View, switch active room
    if (viewMode === 'world' && (rx !== currentRoom.x || ry !== currentRoom.y)) {
      currentRoom = { x: rx, y: ry };
      renderMinimap();
      updateUI();
    }

    if (currentRealm === 'overworld') {
      // Check if clicked on any of the 8 Enemies or Link to start dragging
      const rIdx = getRoomIndex(rx, ry);
      const rEnemies = appData.enemies[rIdx] || [];
      
      for (let slot = 0; slot < 8; slot++) {
        if (rEnemies[slot] && rEnemies[slot].type !== 'TYPE_NONE' && rEnemies[slot].x === tx && rEnemies[slot].y === ty) {
          isDragging = { type: 'enemy', index: slot, rx, ry };
          return;
        }
      }

      // Check Link
      if (appData.start_room.x === rx && appData.start_room.y === ry && appData.player.tile_x === tx && appData.player.tile_y === ty) {
        isDragging = { type: 'link', rx, ry };
        return;
      }
    }

    // Tool actions
    pushHistory();
    if (currentTool === 'picker') {
      const sym = rooms[ry][rx][ty][tx];
      selectTile(sym);
      setTool('brush');
      showToast(`Tuile copiée : ${sym}`, "success");
    } else if (currentTool === 'enemy') {
      if (currentRealm === 'overworld') {
        const slot = activeEnemySlotToPick !== null ? activeEnemySlotToPick : 0;
        const type = document.getElementById(`en${slot}_type`).value;
        const rIdx = getRoomIndex(rx, ry);
        if (!appData.enemies[rIdx]) appData.enemies[rIdx] = [];
        while (appData.enemies[rIdx].length <= slot) {
          appData.enemies[rIdx].push({ type: 'TYPE_NONE', x: 0, y: 0 });
        }
        appData.enemies[rIdx][slot] = { type: type === 'TYPE_NONE' ? 'TYPE_OCTO' : type, x: tx, y: ty };
        activeEnemySlotToPick = null;
        setTool('brush');
        updateUI();
        renderMinimap();
        renderMainCanvas();
      } else {
        showToast("Les ennemis sont configurés sur la Surface (Overworld)", "error");
      }
    } else if (currentTool === 'link') {
      if (currentRealm === 'overworld') {
        appData.start_room = { x: rx, y: ry };
        appData.player.tile_x = tx;
        appData.player.tile_y = ty;
        appData.player.modified = true;
        setTool('brush');
        updateUI();
        renderMinimap();
        renderMainCanvas();
      } else {
        showToast("Le point de départ du jeu se situe sur l'Overworld", "error");
      }
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
      const rIdx = getRoomIndex(rx, ry);
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
  const rooms = getActiveRooms();
  function setTile(x, y) {
    if (x >= 0 && x < 20 && y >= 0 && y < 10) {
      const row = rooms[ry][rx][y];
      rooms[ry][rx][y] = row.substring(0, x) + selectedTileSymbol + row.substring(x + 1);
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
  const rooms = getActiveRooms();
  const grid = rooms[ry][rx];
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
        underworld_rooms: appData.underworld_rooms,
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
        underworld_rooms: appData.underworld_rooms,
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
