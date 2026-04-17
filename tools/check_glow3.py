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
\t\t\t\t\t\tvar glow_keys = []
\t\t\t\t\t\tfor k in bs:
\t\t\t\t\t\t\tif k >= 100000 and k < 200000:
\t\t\t\t\t\t\t\tglow_keys.append(k)
\t\t\t\t\t\treturn {"total_bld_sprites": bs.size(), "glow_keys": glow_keys}
return "not found"'''
r = send_cmd({"command": "eval", "params": {"code": code}})
print(json.dumps(r, indent=2))
