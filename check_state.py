import socket, json, time

def send_cmd(s, cmd, params=None):
    payload = {"command": cmd}
    if params:
        payload["params"] = params
    msg = json.dumps(payload) + '\n'
    s.sendall(msg.encode('utf-8'))
    buf = b''
    while True:
        chunk = s.recv(65536)
        buf += chunk
        if b'\n' in buf:
            break
    return json.loads(buf.decode('utf-8'))

s = socket.socket()
s.settimeout(15)
s.connect(('127.0.0.1', 9090))
print('Connected')

# Check current screen
resp = send_cmd(s, 'get_property', {'node_path': '/root/GameState', 'property': 'current_screen'})
print('Current screen:', resp)

# Get scene tree
resp = send_cmd(s, 'get_scene_tree')
tree = resp
# Print just the top-level children
if 'tree' in resp:
    t = resp['tree']
    print('Root children:', [c.get('name','?') for c in t.get('children',[])])
    for child in t.get('children', []):
        print(f"  {child.get('name','?')}: {child.get('class','?')}")
        for sub in child.get('children', []):
            print(f"    {sub.get('name','?')}: {sub.get('class','?')}")
else:
    print('Tree response:', str(resp)[:500])

s.close()