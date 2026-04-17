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

code = """var sage = null
for p in PawnManager.pawns:
\tif p.pawn_name == "Sage":
\t\tsage = p
\t\tbreak
if sage == null:
\treturn "NOT_FOUND"
var map = GameState.get_map()
var gp = sage.grid_pos
var passable = 0
var impassable = 0
for dx in range(-4, 5):
\tfor dy in range(-4, 5):
\t\tvar tx = gp.x + dx
\t\tvar ty = gp.y + dy
\t\tif map.in_bounds(tx, ty):
\t\t\tvar cell = map.get_cell(tx, ty)
\t\t\tif cell and cell.is_passable():
\t\t\t\tpassable += 1
\t\t\telse:
\t\t\t\timpassable += 1
return {"pos": [gp.x, gp.y], "passable": passable, "impassable": impassable, "job": sage.current_job_name, "id": sage.id}"""

result = tcp_eval(code)
print(json.dumps(result, indent=2))
