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

r1 = tcp_eval("""var map = GameState.get_map()
var on_ground = 0
var in_stockpile = 0
var forbidden_count = 0
var hauled_count = 0
for t in ThingManager.things:
\tif not (t is Item): continue
\tif t.forbidden: forbidden_count += 1
\tif t.hauled_by >= 0: hauled_count += 1
\tvar cell = map.get_cell(t.grid_pos.x, t.grid_pos.y) if map else null
\tif cell and cell.zone == "Stockpile":
\t\tin_stockpile += 1
\telse:
\t\ton_ground += 1
return {"on_ground": on_ground, "in_stockpile": in_stockpile, "forbidden": forbidden_count, "hauled_by_someone": hauled_count}
""")
print("Haul status:", json.dumps(r1, indent=2))

r2 = tcp_eval("""var results = []
for p in PawnManager.pawns:
\tif p.dead: continue
\tvar capable = p.is_capable_of("Hauling") if p.has_method("is_capable_of") else "no_method"
\tresults.append({"name": p.pawn_name, "capable_hauling": capable, "job": p.current_job_name})
return results
""")
print("Pawn hauling capability:", json.dumps(r2, indent=2))
