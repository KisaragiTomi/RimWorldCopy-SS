import socket, json, time

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

# Wait a moment for scene to fully initialize
time.sleep(2)

# Check map_data on MapViewport
code1 = 'var hud = get_tree().root.get_node("Main/GameHUD")\nfor c in hud.get_children():\n\tif c is SubViewportContainer:\n\t\tfor sv in c.get_children():\n\t\t\tif sv is SubViewport:\n\t\t\t\tfor mvp in sv.get_children():\n\t\t\t\t\tif mvp.name == "MapViewport":\n\t\t\t\t\t\treturn {"has_map": mvp.map_data != null}\nreturn "no_mvp"'
r1 = send_cmd({"command": "eval", "params": {"code": code1}})
print("MVP map_data:", r1)

# Check active_map
code2 = 'return {"active_map": GameState.active_map != null, "map_type": str(typeof(GameState.active_map))}'
r2 = send_cmd({"command": "eval", "params": {"code": code2}})
print("GameState:", r2)

# Force set from MapViewport
code3 = 'var hud = get_tree().root.get_node("Main/GameHUD")\nfor c in hud.get_children():\n\tif c is SubViewportContainer:\n\t\tfor sv in c.get_children():\n\t\t\tif sv is SubViewport:\n\t\t\t\tfor mvp in sv.get_children():\n\t\t\t\t\tif mvp.name == "MapViewport" and mvp.map_data != null:\n\t\t\t\t\t\tGameState.active_map = mvp.map_data\n\t\t\t\t\t\treturn "set"\nreturn "fail"'
r3 = send_cmd({"command": "eval", "params": {"code": code3}})
print("Set active_map:", r3)

# Verify
r4 = send_cmd({"command": "eval", "params": {"code": 'return GameState.active_map != null'}})
print("has_map:", r4)
