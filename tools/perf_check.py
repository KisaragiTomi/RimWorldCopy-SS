import socket, json

def tcp_eval(code):
    s = socket.socket()
    s.settimeout(5)
    s.connect(('127.0.0.1', 9090))
    cmd = json.dumps({'command': 'eval', 'params': {'code': code}})
    s.sendall((cmd + '\n').encode())
    r = b''
    while True:
        try:
            d = s.recv(4096)
            if not d: break
            r += d
        except: break
    s.close()
    return r.decode()

code = """var plants := 0
var items := 0
var buildings := 0
var other := 0
for t in ThingManager.things:
\tif t is Plant: plants += 1
\telif t is Item: items += 1
\telif t is Building: buildings += 1
\telse: other += 1
return {"total": ThingManager.things.size(), "plants": plants, "items": items, "buildings": buildings, "other": other, "fps": Engine.get_frames_per_second(), "tick": TickManager.current_tick, "pawns": PawnManager.pawns.size()}"""

print(tcp_eval(code))
