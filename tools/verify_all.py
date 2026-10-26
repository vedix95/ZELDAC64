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

labels = load_labels('build/zelda.vs')
cmd_addr = labels['debug_hook_cmd']
arg_addr = labels['debug_hook_arg']
arg2_addr = labels['debug_hook_arg2']
main_addr = labels['main_loop']
joy_addr = labels['joy']
px_addr = labels['player_x']
py_addr = labels['player_y']
room_addr = labels['current_room_idx']
world_addr = labels['current_world_type']
dung_addr = labels['current_dungeon_level']

print(f"main_loop: {main_addr:04x}, hook_cmd: {cmd_addr:04x}")

# Let's test Dungeon 3 Exit & Re-entry:
# 1. Break at main_loop
# 2. Warp to Dungeon 3: hook_cmd=2, hook_arg=3, hook_arg2=0
# 3. Step a few frames, take screenshot test_d3_in.png
# 4. Hold JOY_DOWN (joy = 0x02) for 40 frames until exit_dungeon triggers
# 5. Check world_type, current_room_idx, player_x, player_y, take screenshot test_d3_exit_ow.png
# 6. Hold JOY_UP (joy = 0x01) for 40 frames to walk back into cave
# 7. Check if back in Dungeon 3, take screenshot test_d3_reenter.png

script1 = f"""
bk {main_addr:04x}
g
> {arg2_addr:04x} 00
> {arg_addr:04x} 03
> {cmd_addr:04x} 02
g
g
g
screenshot "/tmp/d3_1_start.png" 2
m {px_addr:04x} {px_addr+2:04x}
m {py_addr:04x} {py_addr:04x}
m {world_addr:04x} {world_addr:04x}
"""

# Let's add joy down loops:
for i in range(35):
    script1 += f"""
> {joy_addr:04x} 02
g
"""

script1 += f"""
screenshot "/tmp/d3_2_exited.png" 2
m {px_addr:04x} {px_addr+2:04x}
m {py_addr:04x} {py_addr:04x}
m {world_addr:04x} {world_addr:04x}
m {room_addr:04x} {room_addr:04x}
"""

# Now walk up to re-enter
for i in range(35):
    script1 += f"""
> {joy_addr:04x} 01
g
"""

script1 += f"""
screenshot "/tmp/d3_3_reentered.png" 2
m {world_addr:04x} {world_addr:04x}
m {dung_addr:04x} {dung_addr:04x}
q
"""

with open('/tmp/test_d3.mon', 'w') as f:
    f.write(script1)

print("Running D3 test in VICE...")
cmd = ['x64sc', '-autostart', 'build/zelda.d64:zelda', '-moncommands', '/tmp/test_d3.mon', '+sound', '-warp']
res = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
print("VICE stdout tail:")
for line in res.stdout.splitlines()[-25:]:
    print(line)

for fn in ['/tmp/d3_1_start.png', '/tmp/d3_2_exited.png', '/tmp/d3_3_reentered.png']:
    if os.path.exists(fn):
        print(f"Generated {fn}: {os.path.getsize(fn)} bytes")
