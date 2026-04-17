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

code = """var things = ThingManager.things
var plants = 0
var items = 0
var buildings = 0
var other = 0
for t in things:
\tif t is Plant: plants += 1
\telif t is Building: buildings += 1
\telif t is Item: items += 1
\telse: other += 1
var fps = Engine.get_frames_per_second()
var tick = TickManager.current_tick
var speed = TickManager.current_speed if "current_speed" in TickManager else -1
var tpf = TickManager._ticks_per_frame[3] if "_ticks_per_frame" in TickManager else -1
var rare_interval = TickManager.RARE_INTERVAL if "RARE_INTERVAL" in TickManager else -1
return {"fps": fps, "tick": tick, "things": things.size(), "plants": plants, "items": items, "buildings": buildings, "other": other, "tpf_3x": tpf, "rare_interval": rare_interval, "pawns": PawnManager.pawns.size()}
"""

r = tcp_eval(code)
print(json.dumps(r, indent=2))
