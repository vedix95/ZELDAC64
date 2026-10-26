#!/usr/bin/env python3
"""
tools/test_verify_cart_items.py - Test des items authentiques sur Zelda CRT C64
"""
import subprocess, os, sys

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

labels = load_labels("build/zelda.vs")
cmd_addr = labels['debug_hook_cmd']
arg_addr = labels['debug_hook_arg']
arg2_addr = labels['debug_hook_arg2']
main_addr = labels['main_loop']
ladder_addr = labels['player_has_stepladder']
raft_addr = labels['player_has_raft']
whistle_addr = labels['player_has_whistle']
bracelet_addr = labels['player_has_bracelet']
px_addr = labels['player_x']
py_addr = labels['player_y']
pdir_addr = labels['player_dir']
joy_addr = labels['joy']

OUT_DIR = "/home/vedix/.gemini/antigravity-cli/brain/07be3fc7-1193-4966-9496-feffbd9d596f"

# 1. Test Stepladder in Room 95 (P-6)
# Link positions on dock next to water, deploys ladder
mon_ladder = f"""break 080d
g
g 55c2
break {main_addr:04x}
> {arg2_addr:04x} 00
> {arg_addr:04x} 5f
> {cmd_addr:04x} 01
> {ladder_addr:04x} 01
> {px_addr:04x} ec 00
> {py_addr:04x} 92
> {pdir_addr:04x} 02
> {joy_addr:04x} 08
g
g
g
g
g
screenshot "{os.path.join(OUT_DIR, 'crt_test_ladder.png')}" 1
quit
"""

with open("build/test_ladder.mon", "w") as f:
    f.write(mon_ladder)

print("[*] Testing Stepladder in VICE...")
cmd = [
    "x64sc",
    "-default",
    "-cartcrt", "build/zelda.crt",
    "-warp",
    "-limitcycles", "8000000",
    "-moncommands", "build/test_ladder.mon"
]
subprocess.run(cmd, capture_output=True, text=True)
print("  -> Stepladder screenshot exists:", os.path.exists(os.path.join(OUT_DIR, "crt_test_ladder.png")))

# 2. Test Raft in Room 85 (F-6)
# Link stands on dock looking UP with Raft in inventory -> STATE_RAFT
mon_raft = f"""break 080d
g
g 55c2
break {main_addr:04x}
> {arg2_addr:04x} 00
> {arg_addr:04x} 55
> {cmd_addr:04x} 01
> {raft_addr:04x} 01
> {px_addr:04x} 88 00
> {py_addr:04x} b0
> {pdir_addr:04x} 01
> {joy_addr:04x} 01
g
g
g
g
g
screenshot "{os.path.join(OUT_DIR, 'crt_test_raft.png')}" 1
quit
"""

with open("build/test_raft.mon", "w") as f:
    f.write(mon_raft)

print("[*] Testing Raft in VICE...")
cmd = [
    "x64sc",
    "-default",
    "-cartcrt", "build/zelda.crt",
    "-warp",
    "-limitcycles", "8000000",
    "-moncommands", "build/test_raft.mon"
]
subprocess.run(cmd, capture_output=True, text=True)
print("  -> Raft screenshot exists:", os.path.exists(os.path.join(OUT_DIR, "crt_test_raft.png")))
