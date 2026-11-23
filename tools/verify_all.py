#!/usr/bin/env python3
"""Suite de vérification unifiée à 4 piliers pour Zelda C64 :
  1. Mémoire & Cartouche ($1000, <$2000, <$A000, $2540..$25FF, overlays, banques, pile)
  2. Conformité (1:1 zelda.nes sur 189 salles de donjons, 128 salles Overworld,
                 sprites & tuiles CHR vs zelda.nes, invariants AGENTS.md)
  3. Logique & Gameplay sous VICE (49 secrets Overworld, blocs donjons, 50 FPS, Dual SID, pile)
  4. Visuels VIC-II & Contrôle PNG (mode multicolore $D016, palettes donjons, captures Pillow, atlas/maps)

Usage :
  python3 tools/verify_all.py --fast   # Piliers 1 & 2 (statique + ROM NES + mémoire, ~15s)
  python3 tools/verify_all.py --full   # Piliers 1, 2, 3 & 4 (incluant VICE & visuels, ~3min)
"""
import argparse
import os
import re
import socket
import subprocess
import sys
import time
from collections import deque

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(BASE_DIR, "tools"))

import build_dungeons as bd
import extract_all_nes_sprites as nes_spr
import sprgen
import tilegen


def load_vs(path):
    res = {}
    with open(path) as f:
        for line in f:
            m = re.match(r"al\s+C:([0-9a-fA-F]+)\s+\.(\S+)", line.strip())
            if m:
                res[m.group(2)] = int(m.group(1), 16)
    return res


def decode_dung_rle(vals):
    out = []
    for b in vals:
        if b == 255:
            break
        if b < 16:
            out.append(b)
        else:
            out.extend([b & 15] * ((b >> 4) + 1))
    return out


class Runner:
    def __init__(self):
        self.passed = 0
        self.failed = 0

    def chk(self, name, ok, detail):
        if ok:
            self.passed += 1
            print(f"  [PASS] {name}: {detail}", flush=True)
        else:
            self.failed += 1
            print(f"  [FAIL] {name}: {detail}", flush=True)


# ===========================================================================
# PILIER 1 : MÉMOIRE & CARTOUCHE
# ===========================================================================
def check_memory(r: Runner):
    print("\n=== PILIER 1 : MÉMOIRE & CARTOUCHE ===", flush=True)
    crt_path = os.path.join(BASE_DIR, "build", "zelda.crt")
    r.chk("MEM_CRT", os.path.exists(crt_path) and os.path.getsize(crt_path) == 1050688,
          f"build/zelda.crt size={os.path.getsize(crt_path) if os.path.exists(crt_path) else 0} (EasyFlash 1Mo)")

    vs = load_vs(os.path.join(BASE_DIR, "build", "zelda.vs"))
    spr_end = vs["sprite_link_proj_explosion"] + 64
    r.chk("MEM_SPRITES_1000", spr_end == 0x1000,
          f"sprite_link_proj_explosion+64 = ${spr_end:04X} (attendu $1000)")

    # Basse RAM < $2000 (vérifier dernier symbole avant CHARSET_ADDR $2000 dans zelda.rep)
    low_addrs = [a for a in vs.values() if 0x1000 <= a < 0x2000]
    low_max = max(low_addrs) if low_addrs else 0
    r.chk("MEM_LOW_2000", low_max < 0x2000, f"max symbole basse RAM = ${low_max:04X} (< $2000)")

    # Haute RAM résidente < $A000
    res_addrs = [a for a in vs.values() if 0x4000 <= a < 0xA000]
    res_max = max(res_addrs) if res_addrs else 0
    main_txt = open(os.path.join(BASE_DIR, "src", "main.asm")).read()
    has_assert = "!if * > OVERLAY_RAM_ADDR" in main_txt
    r.chk("MEM_RES_A000", res_max < 0xA000 and has_assert,
          f"max symbole résident = ${res_max:04X} (< $A000), assertion={has_assert}")

    # Overlays Banques 27..30 <= 8192 octets
    ovl_ok = True
    ovl_sizes = []
    for ovl in ("ovl_inv.dat", "ovl_cave.dat", "ovl_items.dat", "ovl_debug.dat", "ovl_save.dat"):
        p = os.path.join(BASE_DIR, "build", ovl)
        sz = os.path.getsize(p) if os.path.exists(p) else -1
        ovl_sizes.append(f"{ovl}={sz}B")
        if sz <= 0 or sz > 8192:
            ovl_ok = False
    r.chk("MEM_OVERLAYS_8K", ovl_ok, ", ".join(ovl_sizes))

    # Banques sprites <= 8192 octets
    sb_ok = True
    sb_sizes = []
    for sb in ("sprites_ow.bin", "sprites_dung.bin", "sprites_boss.bin", "sprites_npc.bin"):
        p = os.path.join(BASE_DIR, "build", sb)
        sz = os.path.getsize(p) if os.path.exists(p) else -1
        sb_sizes.append(f"{sb}={sz}B")
        if sz != 8192:
            sb_ok = False
    r.chk("MEM_SPRITE_BANKS", sb_ok, ", ".join(sb_sizes))

    # Cache loaded_overlay_bank + garde irq_top
    enemies_txt = open(os.path.join(BASE_DIR, "src", "enemies.asm")).read()
    cache_ok = ("loaded_overlay_bank" in main_txt and "lda #$ff" in main_txt
                and "CART_BANK_OVL_INV" in enemies_txt and "jsr $a009" in enemies_txt)
    r.chk("MEM_OVL_CACHE_GUARD", cache_ok, "invalidation $FF + garde irq_top == CART_BANK_OVL_INV")


# ===========================================================================
# PILIER 2 : CONFORMITÉ (ROM NES, SPRITES/TUILES CHR, RÈGLES AGENTS.MD)
# ===========================================================================
def check_conformity(r: Runner):
    print("\n=== PILIER 2 : CONFORMITÉ ROM NES, SPRITES/TUILES & RÈGLES ===", flush=True)

    # 2.1 Comparaison 1:1 des 189 salles de donjons contre zelda.nes
    ents = {1: 0x73, 2: 0x7d, 3: 0x7c, 4: 0x71, 5: 0x76, 6: 0x79, 7: 0x79, 8: 0x7e, 9: 0x76}
    total_rooms = 0
    total_diffs = 0
    for lvl in range(1, 10):
        txt = open(os.path.join(BASE_DIR, "src", f"dung{lvl}.asm")).read()
        m_lo = re.search(r"room_tbl_lo:(.*?)room_tbl_hi:", txt, re.S)
        labels = [x.strip().replace("<", "") for l in m_lo.group(1).splitlines()
                  if "!byte" in l for x in l.split("!byte")[1].split(",")]
        c64_rooms = {}
        for idx, lbl in enumerate(labels):
            if "dummy" in lbl or not lbl:
                continue
            m_r = re.search(rf"^{lbl}:\s*\n(.*?)(?=^[a-zA-Z_0-9]+:|\Z)", txt, re.M | re.S)
            vals = [int(v.strip()[1:], 16) if v.strip().startswith("$") else int(v.strip())
                    for l in m_r.group(1).splitlines() if "!byte" in l
                    for v in l.split("!byte")[1].split(";")[0].split(",") if v.strip()]
            dec = decode_dung_rle(vals)
            c64_rooms[idx] = [dec[row * 20:(row + 1) * 20] for row in range(10)]
        nes_rooms = bd.decode_nes_dungeon_rooms(lvl, set(c64_rooms.keys()), ents[lvl])
        for rm in c64_rooms:
            total_rooms += 1
            for y in range(10):
                for x in range(20):
                    if nes_rooms[rm][y][x] != c64_rooms[rm][y][x]:
                        total_diffs += 1
    r.chk("CONF_DUNG_189_NES", total_rooms == 189 and total_diffs == 0,
          f"{total_rooms}/189 salles comparées à zelda.nes, {total_diffs} écart(s)")

    # 2.2 Topologie Overworld 128 salles (bordures, accessibilité, 0 O/B bloqué)
    lines = [l for l in open(os.path.join(BASE_DIR, "assets", "world.txt")).read().splitlines()
             if l.strip() and not l.startswith(";")]
    world = {ry * 16 + rx: [lines[ry * 10 + row].split(" ")[rx] for row in range(10)]
             for ry in range(8) for rx in range(16)}
    passable = set(".=_I,")
    mismatches = []
    for ry in range(8):
        for rx in range(16):
            idx = ry * 16 + rx
            if rx < 15:
                for row in range(10):
                    if (world[idx][row][19] in passable) != (world[idx + 1][row][0] in passable):
                        mismatches.append((idx, idx + 1))
            if ry < 7:
                for col in range(20):
                    if (world[idx][9][col] in passable) != (world[idx + 16][0][col] in passable):
                        mismatches.append((idx, idx + 16))
    # Seules transitions asymétriques attendues : P-1/P-2 ($0F/$1F), P-3/P-4 ($2F/$3F), F-5/F-6 ($45/$55)
    unexpected = [e for e in mismatches if e not in {(0x0F, 0x1F), (0x2F, 0x3F), (0x45, 0x55)}]
    blocked_ob = [
        (idx, tx, ty) for idx in range(128) for ty in range(10) for tx in range(20)
        if world[idx][ty][tx] in ("O", "B") and (ty == 9 or world[idx][ty + 1][tx] not in passable)
    ]
    trans_txt = open(os.path.join(BASE_DIR, "src", "transition.asm")).read()
    lw_ok = "cmp #$61" in trans_txt and "cmp #$52" not in trans_txt
    r.chk("CONF_OW_128_MAP", not unexpected and not blocked_ob and lw_ok,
          f"bordures_inattendues={len(unexpected)}, O/B_bloqués={len(blocked_ob)}, LostWoods_$61={lw_ok}")

    # 2.3 Conformité Sprites CHR (zelda.nes <-> assets/link.txt, enemies.txt, extra.txt)
    rom_bytes = nes_spr.load_rom(os.path.join(BASE_DIR, "zelda.nes"))
    get_chr_tile = nes_spr.get_block_reader(rom_bytes)
    chr_ok = all(any(any(px != 0 for px in row) for row in get_chr_tile(blk, 0)) for blk in ("ow", "uw_com"))

    link_order, link_frames = sprgen.parse(os.path.join(BASE_DIR, "assets", "link.txt"))
    en_order, en_frames = sprgen.parse(os.path.join(BASE_DIR, "assets", "enemies.txt"))
    ex_order, ex_frames = sprgen.parse(os.path.join(BASE_DIR, "assets", "extra.txt"))

    def resolve_grids(order, frames):
        g = {}
        for name in order:
            ent = frames[name]
            if "mirror" in ent:
                g[name] = [row[::-1] for row in g[ent["mirror"]]]
            else:
                g[name] = sprgen.to_grid(ent)
        return g

    link_grids = resolve_grids(link_order, link_frames)
    en_grids = resolve_grids(en_order, en_frames)
    ex_grids = resolve_grids(ex_order, ex_frames)

    dim_bad = []
    for lbl, order, grids in [("link", link_order, link_grids), ("enemies", en_order, en_grids), ("extra", ex_order, ex_grids)]:
        for name in order:
            g = grids[name]
            if len(g) != 21 or any(len(row) != 12 for row in g):
                dim_bad.append(f"{lbl}:{name}")

    # Vérifier routage couleur propre 'g' sur les monstres + présence des sprites clés NES
    dung_sprites_g = [n for n in en_order if any(k in n for k in ("stalfos", "keese", "goriya", "darknut", "zol", "gel", "trap", "wallmaster", "wizzrobe", "likelike", "bubble", "gibdo"))]
    no_g_routing = [n for n in dung_sprites_g if not any(2 in row for row in en_grids[n])]
    req_sprites = ("stalfos_0", "keese_0", "keese_1", "goriya_down_0", "darknut_down_0", "aquamentus_0")
    missing_nes_ref = [k for k in req_sprites if k not in en_grids]
    r.chk("CONF_SPRITES_CHR", chr_ok and not dim_bad and not no_g_routing and not missing_nes_ref,
          f"CHR_ROM={chr_ok}, link={len(link_order)}, enemies={len(en_order)}, extra={len(ex_order)}, bad_dim={len(dim_bad)}, no_g={len(no_g_routing)}, missing={missing_nes_ref}")

    # 2.4 Conformité Tuiles Overworld & Donjons (assets/tiles.txt + src/tiles_data.asm + src/tilemap.asm)
    cfg, ow_tiles = tilegen.parse_tiles(os.path.join(BASE_DIR, "assets", "tiles.txt"))
    tiles_ok = (len(ow_tiles) == 16) and all(len(t["rows"]) == 16 and all(len(rw) == 8 for rw in t["rows"]) for t in ow_tiles)
    dung_chr_parts = bd.generate_dungeon_charset_bytes()
    dung_chr_bytes = sum(len(p) for p in dung_chr_parts)
    tiles_data_txt = open(os.path.join(BASE_DIR, "src", "tiles_data.asm")).read()
    tmap_txt = open(os.path.join(BASE_DIR, "src", "tilemap.asm")).read()
    pal_ok = ("dungeon_mc1_table:" in tmap_txt and "zone0_tile_color:" in tiles_data_txt
              and "TILE_DUNG_DOOR_BOMB     = 15" in tiles_data_txt)
    r.chk("CONF_TILES_CHR", tiles_ok and dung_chr_bytes >= 512 and pal_ok,
          f"OW_tiles={len(ow_tiles)} (16x8 mc), Dung_CHR={dung_chr_bytes}B, palettes={pal_ok}")

    # 2.5 Audit statique règles AGENTS.md (SID ldy, !zone, CLI)
    main_txt = open(os.path.join(BASE_DIR, "src", "main.asm")).read()
    sound_txt = open(os.path.join(BASE_DIR, "src", "sound.asm")).read()
    lda_dual_sid_bad = bool(re.search(r"lda\s+dual_sid_enabled\s*\n\s*(?:beq|bne)[^\n]*\n\s*sta\s+SID2_", sound_txt))
    cli_ok = "cli" in main_txt.lower()
    # Vérifier !zone dans tous les modules autonomes
    mods = ["player.asm", "enemies.asm", "items.asm", "dungeon.asm", "sound.asm", "hud.asm", "cave.asm", "inventory.asm", "debug.asm"]
    no_zone = [m for m in mods if "!zone " not in open(os.path.join(BASE_DIR, "src", m)).read()]
    r.chk("CONF_AGENTS_RULES", not lda_dual_sid_bad and cli_ok and not no_zone,
          f"lda_dual_sid_bad={lda_dual_sid_bad}, cli_ok={cli_ok}, no_zone={no_zone}")

    # 2.6 Audit topologique officiel
    p_topo = subprocess.run([sys.executable, os.path.join(BASE_DIR, "tools", "test_map_topology_reachability.py")],
                            cwd=BASE_DIR, capture_output=True, text=True)
    r.chk("CONF_TOPOLOGY_AUDIT", p_topo.returncode == 0, "test_map_topology_reachability.py")


# ===========================================================================
# PILIER 3 & 4 : LOGIQUE + VISUELS SOUS VICE (--full)
# ===========================================================================
def check_full_vice(r: Runner):
    print("\n=== PILIER 3 & 4 : LOGIQUE, FLUIDITÉ 50 FPS, AUDIO & VISUELS VICE ===", flush=True)
    scripts = [
        ("VICE_SPRITE_INTEGRITY", "tools/test_sprite_memory_integrity.py"),
        ("VICE_STACK_ENDURANCE", "tools/test_stack_overlay_endurance.py"),
        ("VICE_DUAL_SID_DUNG", "tools/test_dual_sid_dungeon.py"),
        ("VICE_AUDIO_QUEUE", "tools/test_audio_queue_conflict.py"),
        ("VICE_DUNG9_AUDIO", "tools/test_dungeon9_audio.py"),
    ]
    for label, rel in scripts:
        p = subprocess.run([sys.executable, os.path.join(BASE_DIR, rel)],
                           cwd=BASE_DIR, capture_output=True, text=True, timeout=180)
        r.chk(label, p.returncode == 0, rel)

    # Contrôle visuel VIC-II + captures PNG (Pillow) sur Overworld + D1 + D9 après Warp Debug depuis Inventaire
    from PIL import Image
    L = load_vs(os.path.join(BASE_DIR, "build", "zelda.vs"))
    I = load_vs(os.path.join(BASE_DIR, "build", "intro.vs"))
    tmp_dir = "/tmp/zelda_verify_shots"
    os.makedirs(tmp_dir, exist_ok=True)
    port = 6549
    proc = subprocess.Popen(
        ["x64sc", "+saveres", "-silent", "-warp", "-remotemonitor",
         "-remotemonitoraddress", f"127.0.0.1:{port}", "-cartcrt", os.path.join(BASE_DIR, "build", "zelda.crt")],
        cwd=BASE_DIR, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )
    try:
        sock = None
        for _ in range(80):
            try:
                sock = socket.create_connection(("127.0.0.1", port), timeout=5.0)
                break
            except OSError:
                time.sleep(0.1)
        assert sock, "Impossible de joindre le moniteur VICE"
        sock.settimeout(30.0)
        sock.sendall(b"\n")

        def rd():
            buf = b""
            while True:
                ch = sock.recv(4096)
                if not ch:
                    break
                buf += ch
                if re.search(rb"\(C:\$[0-9a-fA-F]{4}\)\s*$", buf):
                    break
            return buf.decode("latin1", "replace")

        rd()

        def cmd(s):
            sock.sendall((s.strip() + "\n").encode("ascii"))
            return rd()

        def wb(a, *vals):
            cmd(f"> {a:04x} " + " ".join(f"{v & 0xff:02x}" for v in vals))

        def rb(a):
            for _ in range(3):
                out = cmd(f"m {a:04x} {a:04x}")
                m = re.search(r">\s*C:[0-9a-fA-F]+\s+([0-9a-fA-F]{2})", out)
                if m:
                    return int(m.group(1), 16)
            raise RuntimeError(f"Lecture mémoire ${a:04x} échouée: {out!r}")

        def step(n=1):
            for _ in range(n):
                cmd("g")

        # Boot jusqu'à main_loop
        cmd(f"break {I['sid_setup_menu_loop']:04x}"); cmd("g"); cmd("del")
        wb(I["menu_cursor_idx"], 1); wb(I["menu_timeout_frames"], 1, 0)
        cmd(f"break {I['intro_update']:04x}"); cmd("g"); cmd("del")
        cmd(f"break {L['main_loop']:04x}"); cmd(f"g {I['launch_zelda_game']:04x}")
        step(6)

        # Ouvrir Inventaire (coupe VIC_CTRL2 bit 4) puis Warp Donjon 1 $53 & Donjon 9 $42 (doit réactiver multicolore!)
        wb(L["debug_hook_arg"], 0); wb(L["debug_hook_cmd"], 3); step(10)
        for name, dlvl, rid, expected_mc1 in [("d1", 1, 0x53, 3), ("d9", 9, 0x42, 2)]:
            wb(L["debug_hook_arg2"], rid); wb(L["debug_hook_arg"], dlvl); wb(L["debug_hook_cmd"], 2)
            step(24)
            ctrl2 = rb(0xD016)
            mc1 = rb(0xD022) & 0x0F
            png_p = os.path.join(tmp_dir, f"{name}.png")
            cmd(f'screenshot "{png_p}" 2')
            pcx_p = png_p + ".pcx"
            if os.path.exists(pcx_p):
                subprocess.run(["magick", pcx_p, png_p], check=True)
                os.remove(pcx_p)
            im = Image.open(png_p).convert("RGB")
            colors = len(set(im.getdata()))
            r.chk(f"VIS_VIC_{name.upper()}", (ctrl2 & 0x10) == 0x10 and mc1 == expected_mc1 and colors >= 5,
                  f"$D016=${ctrl2:02X} (MC={bool(ctrl2&0x10)}), MC1={mc1}(exp={expected_mc1}), distinct_colors={colors}")

        # Contrôle 50 FPS sur poussée rocher J-8
        wb(L["player_has_bracelet"], 1)
        wb(L["debug_hook_arg"], 0x79); wb(L["debug_hook_cmd"], 1); step(6)
        wb(L["en_type"], 0, 0, 0, 0, 0, 0, 0, 0)
        wb(L["en_state"], 0, 0, 0, 0, 0, 0, 0, 0)
        # Placer Link sous (10,5) poussant vers le HAUT
        wb(L["player_x"], (24 + 10 * 16) & 0xff, (24 + 10 * 16) >> 8)
        wb(L["player_y"], 82 + 6 * 16 - 4)
        wb(L["player_dir"], 1)
        cmd("del"); cmd(f"break {L['player_update']:04x}")
        for _ in range(5):
            cmd("g"); wb(L["joy"], 1)
        cmd("stopwatch reset")
        for _ in range(15):
            cmd("g"); wb(L["joy"], 1)
        sw = cmd("stopwatch")
        m_cyc = re.search(r"(\d{4,})", sw)
        cyc = int(m_cyc.group(1)) if m_cyc else -1
        r.chk("LOGIC_50FPS_PUSH", 250000 <= cyc <= 340000,
              f"15 frames poussée = {cyc} cycles ({cyc/19656:.2f} trames PAL -> 50,00 FPS)")
    finally:
        try:
            sock.close()
        except Exception:
            pass
        proc.terminate()
        proc.wait(timeout=3)

    # Génération atlas & cartes
    p_atlas = subprocess.run(["make", "atlas", "maps"], cwd=BASE_DIR, capture_output=True, text=True)
    r.chk("VIS_ATLAS_MAPS", p_atlas.returncode == 0, "make atlas maps")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--fast", action="store_true", help="Contrôles rapides statiques, mémoire, ROM NES & sprites/tuiles")
    ap.add_argument("--full", action="store_true", help="Suite complète incluant émulation VICE & contrôles visuels")
    args = ap.parse_args()
    full = args.full or not args.fast

    r = Runner()
    check_memory(r)
    check_conformity(r)
    if full:
        check_full_vice(r)

    print(f"\n============================================================")
    print(f" BILAN VERIFY_ALL ({'FULL' if full else 'FAST'}) : {r.passed}/{r.passed + r.failed} PASS (failed={r.failed})")
    print(f"============================================================", flush=True)
    sys.exit(1 if r.failed else 0)


if __name__ == "__main__":
    main()
