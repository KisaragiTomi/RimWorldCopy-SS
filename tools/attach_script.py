import socket, json, time

def send_cmd(cmd_dict, host="127.0.0.1", port=9090, timeout=30):
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

# Attach the script to MapViewport
code = 'var hud = get_tree().root.get_node("Main/GameHUD")\nvar svc = hud.get_child(0)\nvar sv = svc.get_child(0)\nvar mvp = sv.get_child(0)\nvar scr = load("res://scenes/game_map/map_viewport.gd")\nmvp.set_script(scr)\nreturn {"has_script": mvp.get_script() != null, "has_method": mvp.has_method("generate_new_map")}'
r = send_cmd({"command": "eval", "params": {"code": code}})
print("Attach:", r)

# Now try generate_new_map
time.sleep(1)
code2 = 'var hud = get_tree().root.get_node("Main/GameHUD")\nvar svc = hud.get_child(0)\nvar sv = svc.get_child(0)\nvar mvp = sv.get_child(0)\nmvp.generate_new_map(120, 120, 42)\nreturn "generated"'
r2 = send_cmd({"command": "eval", "params": {"code": code2}}, timeout=30)
print("Generate:", r2)

time.sleep(2)

# Check results
r3 = send_cmd({"command": "eval", "params": {"code": 'return GameState.active_map != null'}})
print("has_map:", r3)

r4 = send_cmd({"command": "eval", "params": {"code": 'return ThingManager.get_buildings().size()'}})
print("buildings:", r4)

r5 = send_cmd({"command": "eval", "params": {"code": 'var hud = get_tree().root.get_node("Main/GameHUD")\nvar svc = hud.get_child(0)\nvar sv = svc.get_child(0)\nvar mvp = sv.get_child(0)\nreturn mvp.get_child_count()'}})
print("MVP children:", r5)
