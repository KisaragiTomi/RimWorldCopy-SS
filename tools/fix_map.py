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

# Try to set active_map from MapViewport's map_data
code = '''var hud = get_tree().root.get_node("Main/GameHUD")
for c in hud.get_children():
\tif c is SubViewportContainer:
\t\tfor sv in c.get_children():
\t\t\tif sv is SubViewport:
\t\t\t\tfor mvp in sv.get_children():
\t\t\t\t\tif mvp.name == "MapViewport":
\t\t\t\t\t\tif mvp.map_data != null:
\t\t\t\t\t\t\tGameState.active_map = mvp.map_data
\t\t\t\t\t\t\treturn {"fixed": true, "map_size": [mvp.map_data.width, mvp.map_data.height]}
\t\t\t\t\t\treturn {"fixed": false, "reason": "map_data is null"}
return "mvp_not_found"'''
r = send_cmd({"command": "eval", "params": {"code": code}})
print("Fix map:", json.dumps(r, indent=2))

# Verify
r2 = send_cmd({"command": "eval", "params": {"code": 'return GameState.active_map != null'}})
print("has_map:", r2)

# Check buildings now
r3 = send_cmd({"command": "eval", "params": {"code": 'return ThingManager.get_buildings().size()'}})
print("buildings:", r3)
