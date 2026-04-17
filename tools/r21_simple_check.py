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

r = tcp_eval('var things = ThingManager.things\nvar plants = []\nfor t in things:\n\tif t is Plant:\n\t\tplants.append({"def": t.def_name, "growth": t.growth})\nreturn {"total_plants": plants.size(), "sample": plants.slice(0, 5)}')
print(json.dumps(r, indent=2))
