import socket, json

def tcp_eval(code, timeout=10):
    s = socket.socket()
    s.settimeout(timeout)
    s.connect(('127.0.0.1', 9090))
    msg = json.dumps({'command': 'eval', 'params': {'code': code}}) + '\n'
    s.sendall(msg.encode())
    result = s.recv(65536).decode()
    s.close()
    return result

code = (
    'var beds = 0\n'
    'var bld = {}\n'
    'for t in ThingManager._buildings:\n'
    '\tif t.def_name == "Bed":\n'
    '\t\tbeds += 1\n'
    '\tvar d = t.def_name\n'
    '\tif not bld.has(d):\n'
    '\t\tbld[d] = 0\n'
    '\tbld[d] += 1\n'
    'var alive = PawnManager.pawns.filter(func(p): return not p.dead).size()\n'
    'var meals = 0\n'
    'for t in ThingManager._items:\n'
    '\tif "Meal" in t.def_name:\n'
    '\t\tmeals += 1\n'
    'return {"beds": beds, "pawns": alive, "meals": meals, "buildings": bld}'
)
print(tcp_eval(code))
