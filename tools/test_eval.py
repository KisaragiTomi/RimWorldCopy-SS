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

# Super simple step-by-step
r1 = send_cmd({"command": "eval", "params": {"code": 'var hud = get_tree().root.get_node("Main/GameHUD")\nreturn hud.get_child_count()'}})
print("HUD children:", r1)

r2 = send_cmd({"command": "eval", "params": {"code": 'var hud = get_tree().root.get_node("Main/GameHUD")\nvar svc = hud.get_child(0)\nreturn svc.get_class()'}})
print("SVC class:", r2)

r3 = send_cmd({"command": "eval", "params": {"code": 'var hud = get_tree().root.get_node("Main/GameHUD")\nvar svc = hud.get_child(0)\nvar sv = svc.get_child(0)\nreturn sv.get_class()'}})
print("SV class:", r3)

r4 = send_cmd({"command": "eval", "params": {"code": 'var hud = get_tree().root.get_node("Main/GameHUD")\nvar svc = hud.get_child(0)\nvar sv = svc.get_child(0)\nvar mvp = sv.get_child(0)\nreturn mvp.get_class()'}})
print("MVP class:", r4)

r5 = send_cmd({"command": "eval", "params": {"code": 'var hud = get_tree().root.get_node("Main/GameHUD")\nvar svc = hud.get_child(0)\nvar sv = svc.get_child(0)\nvar mvp = sv.get_child(0)\nreturn mvp.name'}})
print("MVP name:", r5)

r6 = send_cmd({"command": "eval", "params": {"code": 'var hud = get_tree().root.get_node("Main/GameHUD")\nvar svc = hud.get_child(0)\nvar sv = svc.get_child(0)\nvar mvp = sv.get_child(0)\nreturn mvp.get_child_count()'}})
print("MVP child count:", r6)
