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

code = """var map = GameState.get_map()
var center = Vector2i(map.width / 2, map.height / 2)
var zone1_pass = 0
var zone1_fert_low = 0
var zone1_impass = 0
var zone2_pass = 0
var zone2_fert_low = 0
var zone2_impass = 0
for dx in range(-8, -1):
\tfor dy in range(-8, -1):
\t\tvar pos = center + Vector2i(dx, dy)
\t\tif map.in_bounds(pos.x, pos.y):
\t\t\tvar cell = map.get_cell_v(pos)
\t\t\tif cell and cell.is_passable():
\t\t\t\tif cell.fertility > 0.4:
\t\t\t\t\tzone1_pass += 1
\t\t\t\telse:
\t\t\t\t\tzone1_fert_low += 1
\t\t\telse:
\t\t\t\tzone1_impass += 1
for dx in range(-3, 7):
\tfor dy in range(5, 12):
\t\tvar pos = center + Vector2i(dx, dy)
\t\tif map.in_bounds(pos.x, pos.y):
\t\t\tvar cell = map.get_cell_v(pos)
\t\t\tif cell and cell.is_passable():
\t\t\t\tif cell.fertility > 0.3:
\t\t\t\t\tzone2_pass += 1
\t\t\t\telse:
\t\t\t\t\tzone2_fert_low += 1
\t\t\telse:
\t\t\t\tzone2_impass += 1
return {"zone1": {"pass": zone1_pass, "fert_low": zone1_fert_low, "impass": zone1_impass}, "zone2": {"pass": zone2_pass, "fert_low": zone2_fert_low, "impass": zone2_impass}, "center": [center.x, center.y]}"""

result = tcp_eval(code)
print(json.dumps(result, indent=2))
