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

# Step 1: Check MapViewport map_data
code1 = 'var hud = get_tree().root.get_node("Main/GameHUD")\nfor c in hud.get_children():\n\tif c is SubViewportContainer:\n\t\tfor sv in c.get_children():\n\t\t\tif sv is SubViewport:\n\t\t\t\tfor mvp in sv.get_children():\n\t\t\t\t\tif mvp.name == "MapViewport":\n\t\t\t\t\t\treturn mvp.map_data != null\nreturn "not_found"'
r1 = send_cmd({"command": "eval", "params": {"code": code1}})
print("mvp.map_data exists:", r1)

# Step 2: If map_data exists, set active_map
code2 = 'var hud = get_tree().root.get_node("Main/GameHUD")\nfor c in hud.get_children():\n\tif c is SubViewportContainer:\n\t\tfor sv in c.get_children():\n\t\t\tif sv is SubViewport:\n\t\t\t\tfor mvp in sv.get_children():\n\t\t\t\t\tif mvp.name == "MapViewport" and mvp.map_data:\n\t\t\t\t\t\tGameState.active_map = mvp.map_data\n\t\t\t\t\t\treturn "fixed"\nreturn "no_map"'
r2 = send_cmd({"command": "eval", "params": {"code": code2}})
print("Fix:", r2)

# Verify
r3 = send_cmd({"command": "eval", "params": {"code": 'return GameState.active_map != null'}})
print("has_map:", r3)
