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
var harvestable = 0
var growing = 0
var sow_spots = 0
var trees_mature = 0
var trees_young = 0
var items_ground = 0
var items_stockpile = 0
var haul_candidates = 0

for t in ThingManager.things:
\tif t is Plant:
\t\tvar p = t as Plant
\t\tif p.harvestable:
\t\t\tharvestable += 1
\t\tif p.def_name == "Tree" and p.growth >= 0.8:
\t\t\ttrees_mature += 1
\t\telif p.def_name == "Tree":
\t\t\ttrees_young += 1
\t\tif not p.harvestable and p.growth < 1.0:
\t\t\tgrowing += 1
\telif t is Item:
\t\tvar cell = map.get_cell(t.grid_pos.x, t.grid_pos.y) if map else null
\t\tif cell and cell.zone and cell.zone.zone_type == "Stockpile":
\t\t\titems_stockpile += 1
\t\telse:
\t\t\titems_ground += 1
\t\t\tif not t.forbidden and t.hauled_by < 0:
\t\t\t\thaul_candidates += 1

var zones_count = 0
var grow_zones = 0
if map:
\tfor x in range(map.width):
\t\tfor y in range(map.height):
\t\t\tvar c = map.get_cell(x, y)
\t\t\tif c and c.zone:
\t\t\t\tzones_count += 1
\t\t\t\tif c.zone.zone_type == "Growing":
\t\t\t\t\tgrow_zones += 1

var designated_cut = 0
for t in ThingManager.things:
\tif t is Plant and t.get_meta("designated_cut", false):
\t\tdesignated_cut += 1

return {"harvestable": harvestable, "growing": growing, "trees_mature": trees_mature, "trees_young": trees_young, "items_ground": items_ground, "items_stockpile": items_stockpile, "haul_candidates": haul_candidates, "zone_cells": zones_count, "grow_zone_cells": grow_zones, "designated_cut": designated_cut}
"""

r = tcp_eval(code)
print(json.dumps(r, indent=2))
