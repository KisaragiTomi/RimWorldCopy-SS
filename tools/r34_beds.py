import socket, json

def tcp_eval(code, timeout=10):
    s = socket.socket()
    s.settimeout(timeout)
    s.connect(('127.0.0.1', 9090))
    msg = json.dumps({'command': 'eval', 'params': {'code': code}}) + '\n'
    s.sendall(msg.encode())
    result = s.recv(65536).decode()
    s.close()
    return result

print("=== Bed Locations ===")
code_beds = (
    'var beds = []\n'
    'for t in ThingManager._buildings:\n'
    '\tif t.def_name == "Bed":\n'
    '\t\tbeds.append([t.grid_pos.x, t.grid_pos.y])\n'
    'return beds'
)
print(tcp_eval(code_beds))

print("\n=== All Building Types ===")
code_bld = (
    'var types = {}\n'
    'for t in ThingManager._buildings:\n'
    '\tvar d = t.def_name\n'
    '\tif not types.has(d):\n'
    '\t\ttypes[d] = 0\n'
    '\ttypes[d] += 1\n'
    'return types'
)
print(tcp_eval(code_bld))

print("\n=== Map Center Area Passability ===")
code_map = (
    'var map = GameState.active_map\n'
    'var cx = map.width / 2\n'
    'var cy = map.height / 2\n'
    'return {"center": [cx, cy], "width": map.width, "height": map.height}'
)
print(tcp_eval(code_map))
