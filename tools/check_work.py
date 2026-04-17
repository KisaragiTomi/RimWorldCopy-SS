import socket, json

def tcp_eval(code):
    s = socket.socket()
    s.settimeout(10)
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

code = """var result := {}
var bld_types := {}
for t in ThingManager.things:
\tif t is Building:
\t\tvar b = t as Building
\t\tbld_types[b.def_name] = bld_types.get(b.def_name, 0) + 1
result["buildings"] = bld_types
var harvestable := 0
var growing := 0
for t in ThingManager.things:
\tif t is Plant:
\t\tvar p = t as Plant
\t\tif p.growth_stage == Plant.GrowthStage.HARVESTABLE:
\t\t\tharvestable += 1
\t\telse:
\t\t\tgrowing += 1
result["harvestable_plants"] = harvestable
result["growing_plants"] = growing
return result"""

print(tcp_eval(code))
