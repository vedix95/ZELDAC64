import subprocess, os, time

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

OUT_DIR = "/home/vedix/.gemini/antigravity-cli/brain/80df6d3b-ab21-48b6-8efe-b0005a652eca"

SCENARIOS = [
    # (filename, cmd, arg1, arg2, description)
    # 1. Warp Overworld Screen 116 (Dungeon 3 Entrance)
    ("verify_ow_room116.png", 1, 116, 0, "Overworld Room 116 (Dungeon 3 entrance cave)"),
    # 2. Warp inside Dungeon 3 entrance room
    ("verify_dungeon3_in.png", 2, 3, 0, "Dungeon 3 Entrance Room inside"),
    # 3. Warp Overworld Screen 66 (Lake before whistle)
    ("verify_ow_room66_before.png", 1, 66, 0, "Overworld Room 66 (Lake before whistle)"),
    # 4. Use Whistle in Screen 66 (whistle item = 6) -> Lake Drains & Dungeon 7 Entrance appears
    ("verify_ow_room66_whistle.png", 5, 6, 0, "Overworld Room 66 (After Whistle: Lake drained, Dungeon 7 entrance open)"),
    # 5. Warp inside Dungeon 7 entrance room
    ("verify_dungeon7_in.png", 2, 7, 0, "Dungeon 7 Entrance Room inside"),
]

mon_file = "/tmp/verify_features.mon"
with open(mon_file, "w") as f:
    f.write(f"bk {main_addr:04x}\n")
    f.write("g\n")
    for fname, cmd, arg1, arg2, desc in SCENARIOS:
        out_png = os.path.join(OUT_DIR, fname)
        f.write(f"> {arg2_addr:04x} {arg2:02x}\n")
        f.write(f"> {arg_addr:04x} {arg1:02x}\n")
        f.write(f"> {cmd_addr:04x} {cmd:02x}\n")
        f.write("g\n")
        f.write("g\n")
        f.write("g\n")
        f.write(f'screenshot "{out_png}" 2\n')
    f.write("q\n")

print(f"Generated {mon_file}")
cmdline = [
    "x64sc",
    "-autostart", "build/zelda.d64:zelda",
    "-moncommands", mon_file,
    "+sound",
    "-warp"
]
print("Running VICE...")
t0 = time.time()
res = subprocess.run(cmdline, capture_output=True, text=True, timeout=120)
elapsed = time.time() - t0
print(f"Finished in {elapsed:.1f}s")
for fname, _, _, _, desc in SCENARIOS:
    path = os.path.join(OUT_DIR, fname)
    if os.path.exists(path):
        print(f"OK: {fname} ({os.path.getsize(path)} bytes) - {desc}")
    else:
        print(f"MISSING: {fname}")
