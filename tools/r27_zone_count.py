import socket, json

def tcp_eval(code):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(5)
    s.connect(("127.0.0.1", 9090))
    msg = json.dumps({"command": "eval", "params": {"code": code}}) + "\n"
    s.sendall(msg.encode())
    data = b""
    while b"\n" not in data:
        data += s.recv(4096)
    s.close()
    return json.loads(data.decode().strip())

code = """var grow = 0
var stock = 0
for pos in ZoneManager.zones:
\tvar z = ZoneManager.zones[pos]
\tif z == "GrowingZone":
\t\tgrow += 1
\telif z == "Stockpile":
\t\tstock += 1
return {"grow": grow, "stock": stock, "total_zones": ZoneManager.zones.size()}"""

result = tcp_eval(code)
print(json.dumps(result, indent=2))
