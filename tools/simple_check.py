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

r1 = send_cmd({"command": "eval", "params": {"code": 'var main = get_tree().root.get_node("Main")\nvar ch = []\nfor c in main.get_children():\n\tch.append(c.name + ":" + c.get_class())\nreturn ch'}})
print("Main:", r1)

r2 = send_cmd({"command": "eval", "params": {"code": 'var hud = get_tree().root.get_node_or_null("Main/GameHUD")\nif hud:\n\treturn {"children": hud.get_child_count(), "first": hud.get_child(0).name if hud.get_child_count() > 0 else "none"}\nreturn "no_hud"'}})
print("HUD:", r2)
