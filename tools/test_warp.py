import subprocess, os

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

print(f"main_loop: {main_addr:04x}, hook_cmd: {cmd_addr:04x}")

mon = f"""
bk {main_addr:04x}
g
> {arg2_addr:04x} 00
> {arg_addr:04x} 77
> {cmd_addr:04x} 01
g
g
g
screenshot "/tmp/test_room119.png" 2
> {arg2_addr:04x} 00
> {arg_addr:04x} 7f
> {cmd_addr:04x} 01
g
g
g
screenshot "/tmp/test_room127.png" 2
q
"""

with open('/tmp/test_warp.mon', 'w') as f:
    f.write(mon)

cmd = ['x64sc', '-autostart', 'build/zelda.d64:zelda', '-moncommands', '/tmp/test_warp.mon', '+sound', '-warp']
res = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
print("Finished!")
for fn in ['/tmp/test_room119.png', '/tmp/test_room127.png']:
    if os.path.exists(fn):
        print(f"{fn}: {os.path.getsize(fn)} bytes")
