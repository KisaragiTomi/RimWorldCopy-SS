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

code = """var zm = ZoneManager
var has_method = zm.has_method("get_zone_cells") if zm else false
var stockpile = zm.get_zone_cells("Stockpile") if has_method else []
var growing = zm.get_zone_cells("GrowingZone") if has_method else []
var all_zones = zm.get_zone_cells("Growing") if has_method else []

var map = GameState.get_map()
var zone_cells_map = {}
if map:
\tfor x in range(map.width):
\t\tfor y in range(map.height):
\t\t\tvar c = map.get_cell(x, y)
\t\t\tif c and c.zone:
\t\t\t\tvar z = str(c.zone)
\t\t\t\tif z in zone_cells_map:
\t\t\t\t\tzone_cells_map[z] += 1
\t\t\t\telse:
\t\t\t\t\tzone_cells_map[z] = 1

return {"zm_exists": zm != null, "has_method": has_method, "stockpile_cells": stockpile.size() if stockpile is Array else -1, "growing_cells": growing.size() if growing is Array else -1, "growing2_cells": all_zones.size() if all_zones is Array else -1, "map_zones": zone_cells_map}
"""

r = tcp_eval(code)
print(json.dumps(r, indent=2))
