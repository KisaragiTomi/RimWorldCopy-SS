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

code = """var pm = PawnManager
var pawns = pm.pawns
var alive = pawns.filter(func(p): return not p.dead)
var dead = pawns.filter(func(p): return p.dead)
var downed = alive.filter(func(p): return p.downed)
var tm = ThingManager
var things = tm.things
var plants = things.filter(func(t): return t is Plant)
var items = things.filter(func(t): return not (t is Plant) and not (t is Building))
var blds = tm.get_buildings()
var tick = TickManager.current_tick
var fps = Engine.get_frames_per_second()
var speed = TickManager.current_speed if "current_speed" in TickManager else -1
var pawn_details = []
for p in alive:
\tpawn_details.append({"name": p.pawn_name, "job": p.current_job_name, "food": p.get_need("Food"), "rest": p.get_need("Rest"), "mood": p.get_need("Mood"), "pos": [p.grid_pos.x, p.grid_pos.y]})
return {"tick": tick, "fps": fps, "speed": speed, "pawns_total": pawns.size(), "alive": alive.size(), "dead": dead.size(), "downed": downed.size(), "things": things.size(), "plants": plants.size(), "items": items.size(), "buildings": blds.size(), "pawns": pawn_details}
"""

r = tcp_eval(code)
print(json.dumps(r, indent=2))
