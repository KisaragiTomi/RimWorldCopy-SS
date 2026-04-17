import socket, json, time, base64, pathlib

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

# Try to change scene to a temporary scene then back
code = 'get_tree().change_scene_to_file("res://scenes/main/main.tscn")\nreturn "changing"'
r = send_cmd({"command": "eval", "params": {"code": code}})
print("Change scene:", r)
time.sleep(3)

# Check current scene
r2 = send_cmd({"command": "eval", "params": {"code": 'return str(get_tree().current_scene.name)'}})
print("Scene:", r2)

# Switch to game
r3 = send_cmd({"command": "eval", "params": {"code": 'var main = get_tree().root.get_node("Main")\nmain.switch_to_game()\nreturn "switching"'}})
print("Switch:", r3)
time.sleep(8)

# Verify
r4 = send_cmd({"command": "eval", "params": {"code": 'var hud = get_tree().root.get_node("Main/GameHUD")\nvar svc = hud.get_child(0)\nvar sv = svc.get_child(0)\nvar mvp = sv.get_child(0)\nreturn {"name": mvp.name, "has_script": mvp.get_script() != null, "children": mvp.get_child_count()}'}})
print("MVP:", json.dumps(r4, indent=2))

r5 = send_cmd({"command": "eval", "params": {"code": 'return GameState.active_map != null'}})
print("has_map:", r5)
