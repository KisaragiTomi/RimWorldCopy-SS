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

r1 = tcp_eval("""var has_zm = ZoneManager != null
var stockpile_cells = []
if has_zm:
\tstockpile_cells = ZoneManager.get_zone_cells("Stockpile") if ZoneManager.has_method("get_zone_cells") else []
var map = GameState.get_map()
var zone_types_found = {}
if map:
\tfor x in range(map.width):
\t\tfor y in range(map.height):
\t\t\tvar c = map.get_cell(x, y)
\t\t\tif c and c.zone:
\t\t\t\tvar zt = typeof(c.zone)
\t\t\t\tvar zstr = str(c.zone)
\t\t\t\tif not zstr in zone_types_found:
\t\t\t\t\tzone_types_found[zstr] = {"type_id": zt, "count": 0}
\t\t\t\tzone_types_found[zstr].count += 1
\t\t\t\tif zone_types_found.size() > 20:
\t\t\t\t\tbreak
return {"has_zone_manager": has_zm, "stockpile_cell_count": stockpile_cells.size() if stockpile_cells is Array else -1, "zone_types": zone_types_found}
""")
print(json.dumps(r1, indent=2))
