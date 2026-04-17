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

find_code = 'var main = get_tree().root.get_node("Main")\nvar children = []\nfor c in main.get_children():\n\tchildren.append(c.name)\nreturn children'
r = send_cmd({"command": "eval", "params": {"code": find_code}})
print("Main children:", r)

find2 = 'var main = get_tree().root.get_node("Main")\nfor c in main.get_children():\n\tif "HUD" in c.name or "Game" in c.name:\n\t\tvar sub = []\n\t\tfor cc in c.get_children():\n\t\t\tsub.append(cc.name + ":" + cc.get_class())\n\t\treturn {"node": c.name, "children": sub}\nreturn "not found"'
r2 = send_cmd({"command": "eval", "params": {"code": find2}})
print("HUD node:", r2)
