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

r1 = send_cmd({"command": "eval", "params": {"code": 'return str(get_tree().current_scene.name)'}})
print("current scene:", json.dumps(r1, indent=2))

r2 = send_cmd({"command": "eval", "params": {"code": 'var children = []\nfor c in get_tree().root.get_children():\n\tchildren.append(c.name)\nreturn children'}})
print("root children:", json.dumps(r2, indent=2))
