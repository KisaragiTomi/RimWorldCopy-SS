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

code = """var zones := {}
if ZoneManager:
\tfor pos in ZoneManager.zones:
\t\tvar zt: String = ZoneManager.zones[pos]
\t\tzones[zt] = zones.get(zt, 0) + 1
return {"zones": zones, "has_stockpile": zones.has("Stockpile")}"""

print(tcp_eval(code))
