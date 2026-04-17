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

code1 = """var h = 0
var g = 0
var tm = 0
var ty = 0
for t in ThingManager.things:
\tif t is Plant:
\t\tvar p = t as Plant
\t\tif p.harvestable:
\t\t\th += 1
\t\telif p.growth < 1.0:
\t\t\tg += 1
\t\tif p.def_name == "Tree" and p.growth >= 0.8:
\t\t\ttm += 1
\t\telif p.def_name == "Tree":
\t\t\tty += 1
return {"harvestable": h, "growing": g, "trees_mature": tm, "trees_young": ty}
"""

code2 = """var ig = 0
var ist = 0
var hc = 0
var map = GameState.get_map()
for t in ThingManager.things:
\tif not (t is Item): continue
\tvar cell = map.get_cell(t.grid_pos.x, t.grid_pos.y) if map else null
\tif cell and cell.zone and cell.zone.zone_type == "Stockpile":
\t\tist += 1
\telse:
\t\tig += 1
\t\tif not t.forbidden and t.hauled_by < 0:
\t\t\thc += 1
return {"items_ground": ig, "items_stockpile": ist, "haul_candidates": hc}
"""

r1 = tcp_eval(code1)
print("Plants:", json.dumps(r1, indent=2))
r2 = tcp_eval(code2)
print("Items:", json.dumps(r2, indent=2))
