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

r1 = tcp_eval("""var plants = []
var defs = {}
for t in ThingManager.things:
\tif t is Plant:
\t\tvar d = t.def_name
\t\tif d in defs:
\t\t\tdefs[d] += 1
\t\telse:
\t\t\tdefs[d] = 1
\t\tif plants.size() < 3:
\t\t\tplants.append({"def": d, "growth": t.growth, "props": t.get_property_list().map(func(p): return p.name).slice(0, 20)})
return {"plant_defs": defs, "sample_props": plants}""")
print("Plants:", json.dumps(r1, indent=2))

r2 = tcp_eval("""var items = {}
for t in ThingManager.things:
\tif t is Item:
\t\tvar d = t.def_name
\t\tif d in items:
\t\t\titems[d] += 1
\t\telse:
\t\t\titems[d] = 1
return items""")
print("\nItems:", json.dumps(r2, indent=2))
