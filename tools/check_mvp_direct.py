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

# Direct access via path
code = 'var hud = get_tree().root.get_node("Main/GameHUD")\nvar svc = hud.get_child(0)\nvar sv = svc.get_child(0)\nvar mvp = sv.get_child(0)\nreturn {"name": mvp.name, "map_data_null": mvp.map_data == null, "child_count": mvp.get_child_count()}'
r = send_cmd({"command": "eval", "params": {"code": code}})
print("MVP:", json.dumps(r, indent=2))

# Check child count of mvp - if 0, the map wasn't generated
code2 = 'var hud = get_tree().root.get_node("Main/GameHUD")\nvar svc = hud.get_child(0)\nvar sv = svc.get_child(0)\nvar mvp = sv.get_child(0)\nif mvp.map_data:\n\treturn {"w": mvp.map_data.width, "h": mvp.map_data.height}\nreturn "null_map"'
r2 = send_cmd({"command": "eval", "params": {"code": code2}})
print("Map info:", r2)
