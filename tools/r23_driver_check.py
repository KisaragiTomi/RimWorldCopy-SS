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

code = """var results = []
for p in PawnManager.pawns:
\tif p.dead: continue
\tvar driver = PawnManager._drivers.get(p.id)
\tvar driver_class = ""
\tvar driver_ended = true
\tvar is_wander = false
\tif driver:
\t\tdriver_class = driver.get_class()
\t\tdriver_ended = driver.ended
\t\tis_wander = driver is JobDriverWander
\tresults.append({"name": p.pawn_name, "job": p.current_job_name, "food": snapped(p.get_need("Food"), 0.001), "rest": snapped(p.get_need("Rest"), 0.001), "driver": driver_class, "ended": driver_ended, "is_wander": is_wander, "has_driver": driver != null})
return results
"""

r = tcp_eval(code)
print(json.dumps(r, indent=2))
