import socket, json

def send_cmd(cmd_dict, host="127.0.0.1", port=9090, timeout=15):
    s = socket.create_connection((host, port), timeout=timeout)
    s.sendall(json.dumps(cmd_dict).encode() + b"\n")
    buf = b""
    while True:
        chunk = s.recv(65536)
        if not chunk: break
        buf += chunk
        if b"\n" in buf: break
    s.close()
    return json.loads(buf.split(b"\n")[0].decode())

code = 'var blds = ThingManager.get_buildings()\nvar names = []\nfor b in blds:\n\tif b.def_name not in names:\n\t\tnames.append(b.def_name)\nreturn {"count": blds.size(), "types": names}'
r = send_cmd({"command": "eval", "params": {"code": code}})
print(json.dumps(r, indent=2))

code2 = 'var lights = []\nfor b in ThingManager.get_buildings():\n\tif b.def_name == "Campfire" or b.def_name == "TorchLamp" or b.def_name == "StandingLamp":\n\t\tlights.append({"def": b.def_name, "pos": [b.grid_pos.x, b.grid_pos.y]})\nreturn lights'
r2 = send_cmd({"command": "eval", "params": {"code": code2}})
print("Lights:", json.dumps(r2, indent=2))
