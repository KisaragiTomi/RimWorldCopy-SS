import socket, json

def tcp_eval(code):
    s = socket.socket()
    s.settimeout(15)
    s.connect(('127.0.0.1', 9090))
    s.sendall((json.dumps({'command':'eval','params':{'code':code}}) + '\n').encode())
    data = b''
    while b'\n' not in data:
        chunk = s.recv(4096)
        if not chunk: break
        data += chunk
    s.close()
    return json.loads(data.strip())

code = """var map = GameState.get_map()
var grow_cells = ZoneManager.get_zone_cells("GrowingZone") if ZoneManager else []
var empty = 0
var planted = 0
var details = []
for pos in grow_cells:
\tvar has_plant = false
\tfor t in ThingManager.get_things_at(pos):
\t\tif t is Plant:
\t\t\thas_plant = true
\t\t\tbreak
\tif has_plant:
\t\tplanted += 1
\telse:
\t\tempty += 1
\t\tif details.size() < 5:
\t\t\tvar cell = map.get_cell(pos.x, pos.y) if map else null
\t\t\tdetails.append({"pos": [pos.x, pos.y], "terrain": cell.terrain_def if cell else "?", "fertility": cell.fertility if cell else 0})
return {"total_grow": grow_cells.size(), "planted": planted, "empty_spots": empty, "empty_details": details}
"""

r = tcp_eval(code)
print(json.dumps(r, indent=2))
