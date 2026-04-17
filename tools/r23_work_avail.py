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
var grow_cells = 0
var empty_grow = 0
var stockpile_cells = 0
var items_ground = 0
var items_stock = 0
var trees = 0
var mature_trees = 0
var dirty_cells = 0

if map:
\tfor x in range(map.width):
\t\tfor y in range(map.height):
\t\t\tvar c = map.get_cell(x, y)
\t\t\tif not c: continue
\t\t\tif c.zone == "Growing":
\t\t\t\tgrow_cells += 1
\t\t\t\tvar has_plant = false
\t\t\t\tfor t in ThingManager.get_things_at(Vector2i(x, y)):
\t\t\t\t\tif t is Plant:
\t\t\t\t\t\thas_plant = true
\t\t\t\t\t\tbreak
\t\t\t\tif not has_plant:
\t\t\t\t\tempty_grow += 1
\t\t\telif c.zone == "Stockpile":
\t\t\t\tstockpile_cells += 1
\t\t\tif c.filth_level > 0 if "filth_level" in c else false:
\t\t\t\tdirty_cells += 1

for t in ThingManager.things:
\tif t is Plant:
\t\tif t.def_name == "Tree":
\t\t\ttrees += 1
\t\t\tif t.growth >= 0.8:
\t\t\t\tmature_trees += 1
\telif t is Item:
\t\tvar cell = map.get_cell(t.grid_pos.x, t.grid_pos.y) if map else null
\t\tif cell and cell.zone == "Stockpile":
\t\t\titems_stock += 1
\t\telse:
\t\t\titems_ground += 1

var blueprints = 0
for t in ThingManager.things:
\tif t is Building:
\t\tvar b = t as Building
\t\tif b.build_state != Building.BuildState.COMPLETE:
\t\t\tblueprints += 1

return {"grow_cells": grow_cells, "empty_grow": empty_grow, "stockpile_cells": stockpile_cells, "items_ground": items_ground, "items_stockpile": items_stock, "trees": trees, "mature_trees": mature_trees, "dirty_cells": dirty_cells, "blueprints": blueprints}
"""

r = tcp_eval(code)
print(json.dumps(r, indent=2))
