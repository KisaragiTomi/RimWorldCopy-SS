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

code = '''var hud = get_tree().root.get_node("Main/GameHUD")
for c in hud.get_children():
\tif c is SubViewportContainer:
\t\tfor sv in c.get_children():
\t\t\tif sv is SubViewport:
\t\t\t\tfor mvp in sv.get_children():
\t\t\t\t\tif mvp.name == "MapViewport":
\t\t\t\t\t\tvar bs = mvp._building_sprites
\t\t\t\t\t\tvar keys = []
\t\t\t\t\t\tvar count = 0
\t\t\t\t\t\tfor k in bs:
\t\t\t\t\t\t\tcount += 1
\t\t\t\t\t\t\tif count <= 10:
\t\t\t\t\t\t\t\tkeys.append(k)
\t\t\t\t\t\tvar max_key = 0
\t\t\t\t\t\tfor k in bs:
\t\t\t\t\t\t\tif k > max_key:
\t\t\t\t\t\t\t\tmax_key = k
\t\t\t\t\t\treturn {"count": count, "sample_keys": keys, "max_key": max_key}
return "not found"'''
r = send_cmd({"command": "eval", "params": {"code": code}})
print(json.dumps(r, indent=2))
