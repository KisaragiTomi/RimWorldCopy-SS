import socket, json, time

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

r = tcp_eval('TickManager._ticks_per_frame[3] = 30\nTickManager.set_speed(3)\nreturn "3x speed"')
print("Speed set:", r)

status_code = """var pm = PawnManager
var pawns = pm.pawns
var alive = pawns.filter(func(p): return not p.dead)
var tm = ThingManager
var things = tm.things
var items_count = 0
var plants_count = 0
for t in things:
\tif t is Plant: plants_count += 1
\telif t is Item: items_count += 1
var blds = tm.get_buildings()
var tick = TickManager.current_tick
var fps = Engine.get_frames_per_second()
var pawn_details = []
for p in alive:
\tpawn_details.append({"name": p.pawn_name, "job": p.current_job_name, "food": snapped(p.get_need("Food"), 0.001), "rest": snapped(p.get_need("Rest"), 0.001), "mood": snapped(p.get_need("Mood"), 0.001)})
return {"tick": tick, "fps": fps, "alive": alive.size(), "dead": pawns.filter(func(p): return p.dead).size(), "things": things.size(), "plants": plants_count, "items": items_count, "buildings": blds.size(), "pawns": pawn_details}
"""

r2 = tcp_eval(status_code)
print(json.dumps(r2, indent=2))
