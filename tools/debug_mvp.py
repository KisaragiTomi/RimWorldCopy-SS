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

# Simple test
r0 = send_cmd({"command": "eval", "params": {"code": 'return "hello"'}})
print("test:", r0)

# Check Main children
r1 = send_cmd({"command": "eval", "params": {"code": 'var main = get_tree().root.get_node("Main")\nvar ch = []\nfor c in main.get_children():\n\tch.append(c.name)\nreturn ch'}})
print("Main children:", r1)

# Check if GameHUD exists
r2 = send_cmd({"command": "eval", "params": {"code": 'var hud = get_tree().root.get_node_or_null("Main/GameHUD")\nreturn hud != null'}})
print("GameHUD exists:", r2)

# If HUD exists, check first child
r3 = send_cmd({"command": "eval", "params": {"code": 'var hud = get_tree().root.get_node("Main/GameHUD")\nvar first_svc = null\nfor c in hud.get_children():\n\tif c is SubViewportContainer:\n\t\tfirst_svc = c\n\t\tbreak\nif first_svc:\n\treturn {"name": first_svc.name, "child_count": first_svc.get_child_count()}\nreturn "no_svc"'}})
print("SVC:", r3)
