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

# Check if the script is loaded
r1 = send_cmd({"command": "eval", "params": {"code": 'var hud = get_tree().root.get_node("Main/GameHUD")\nvar svc = hud.get_child(0)\nvar sv = svc.get_child(0)\nvar mvp = sv.get_child(0)\nvar scr = mvp.get_script()\nif scr:\n\treturn {"path": scr.get_path(), "has_method": mvp.has_method("generate_new_map")}\nreturn "no_script"'}})
print("Script:", json.dumps(r1, indent=2))

# Try manually calling generate_new_map
r2 = send_cmd({"command": "eval", "params": {"code": 'var hud = get_tree().root.get_node("Main/GameHUD")\nvar svc = hud.get_child(0)\nvar sv = svc.get_child(0)\nvar mvp = sv.get_child(0)\nif mvp.has_method("generate_new_map"):\n\tmvp.generate_new_map(120, 120, 42)\n\treturn {"children": mvp.get_child_count(), "has_map": mvp.map_data != null}\nreturn "no_method"'}}, timeout=30)
print("Generate:", json.dumps(r2, indent=2))
