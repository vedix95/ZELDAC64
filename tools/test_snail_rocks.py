import subprocess
import os
import re
import time

def load_labels():
    labels = {}
    with open('build/zelda.vs') as f:
        for line in f:
            m = re.match(r'al C:([0-9a-fA-F]+) \.([a-zA-Z0-9_]+)', line)
            if m:
                labels[m.group(2)] = int(m.group(1), 16)
    return labels

labels = load_labels()
main_loop = labels['main_loop']
current_room_idx = labels['current_room_idx']
player_x = labels['player_x']
player_y = labels['player_y']
player_dir = labels['player_dir']
player_has_bracelet = labels['player_has_bracelet']
room_buf = labels['room_buf']

print(f"main_loop: 0x{main_loop:04x}")
print(f"room_buf: 0x{room_buf:04x}")

# Step 1: Boot into room 51 (D-4) and check snail rocks in room_buf and charset at $2640
# We can create a monitor commands script
mon_cmd = f"""break {main_loop:04x}
commands 1
m {current_room_idx:04x} {current_room_idx:04x}
m 2640 265f
m {room_buf:04x} {room_buf+199:04x}
quit
end
"""
# Wait, commands in VICE monitor files don't support multi-line commands block without interactive stdin,
# so we use a sequential script or python interactive socket / pty.
