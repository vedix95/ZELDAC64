import subprocess
import os
import re
import time

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
main_addr = labels['main_loop']
px_addr = labels['player_x']
py_addr = labels['player_y']
pdir_addr = labels['player_dir']
pbrace_addr = labels['player_has_bracelet']
room_buf = labels['room_buf']

dump_file = "/tmp/d4_dump.bin"
if os.path.exists(dump_file): os.remove(dump_file)
scr1 = "/tmp/d4_screen_snail_rocks.png"
scr2 = "/tmp/d4_screen_pushed.png"
if os.path.exists(scr1): os.remove(scr1)
if os.path.exists(scr2): os.remove(scr2)

mon_file = "/tmp/test_d4_snail.mon"
with open(mon_file, "w") as f:
    f.write(f"bk {main_addr:04x}\n")
    f.write("g\n")

    # 1. Warp en Salle 51 (D-4 / $33)
    f.write(f"> {arg_addr:04x} 33\n")
    f.write(f"> {cmd_addr:04x} 01\n")
    for _ in range(5):
        f.write("g\n")

    # Capture initial room 51 with snail rocks
    f.write(f'screenshot "{scr1}" 2\n')
    # Dump $2640 (chars 200..203) and room_buf
    f.write(f'bsave "{dump_file}" 0 2640 2660\n')

    # Give bracelet and position Link to push rock at index 88 (col 8, row 4)
    # Link position: x=132 (col 8 = 128..143), y=156 (row 5 = 152..167)
    f.write(f"> {pbrace_addr:04x} 01\n")
    f.write(f"> {px_addr:04x} 84 00\n")  # X=132 (0x0084)
    f.write(f"> {py_addr:04x} 9c\n")     # Y=156 (0x9C)
    f.write(f"> {pdir_addr:04x} 01\n")   # DIR_UP (1)

    # Run 30 frames of pushing
    for _ in range(30):
        f.write("g\n")

    f.write(f'screenshot "{scr2}" 2\n')
    # Dump room_buf to verify tile 88 is now TILE_CAVE (7)
    f.write(f'bsave "/tmp/room_buf_d4.bin" 0 {room_buf:04x} {room_buf+200:04x}\n')
    f.write("q\n")

cmdline = [
    "x64sc",
    "-autostart", "build/zelda.prg",
    "-8", "build/zelda.d64",
    "-moncommands", mon_file,
    "+sound",
    "-warp"
]
print("Running VICE test...")
proc = subprocess.run(cmdline, capture_output=True, text=True, timeout=60)
print(f"VICE finished with exit code {proc.returncode}")

# Check charset dump
if os.path.exists(dump_file):
    with open(dump_file, "rb") as f:
        data = f.read()
    # Skip 2 load address bytes if cbm format
    chars_data = data[2:] if len(data) == 34 else data
    print(f"Chars 200..203 length: {len(chars_data)} bytes")
    # Verify non-zero bytes for snail rock
    non_zero = sum(1 for b in chars_data if b != 0)
    print(f"Non-zero bytes in snail rock charset: {non_zero}/{len(chars_data)}")
    print(f"First 8 bytes of char 200: {[hex(b) for b in chars_data[:8]]}")
else:
    print("Dump file not found!")

if os.path.exists("/tmp/room_buf_d4.bin"):
    with open("/tmp/room_buf_d4.bin", "rb") as f:
        rb = f.read()
    rb_data = rb[2:] if len(rb) == 202 else rb
    print(f"room_buf[88] (pushed rock): {rb_data[88]} (expect 7 for TILE_CAVE)")
    print(f"room_buf[84] (neighbor rock): {rb_data[84]} (expect 13 for TILE_ROCK)")
    print(f"room_buf[86] (neighbor rock): {rb_data[86]} (expect 13 for TILE_ROCK)")
