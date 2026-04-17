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
\t\t\t\t\t\tvar gs = mvp._glow_sprites
\t\t\t\t\t\tvar info = []
\t\t\t\t\t\tfor g in gs:
\t\t\t\t\t\t\tif g and is_instance_valid(g):
\t\t\t\t\t\t\t\tinfo.append({"pos": [g.position.x, g.position.y], "visible": g.visible, "alpha": g.modulate.a, "blend": g.blend_mode, "z": g.z_index, "self_mod": [g.self_modulate.r, g.self_modulate.g, g.self_modulate.b], "scale": [g.scale.x, g.scale.y]})
\t\t\t\t\t\treturn {"glow_count": gs.size(), "glows": info}
return "not found"'''
r = send_cmd({"command": "eval", "params": {"code": code}})
print(json.dumps(r, indent=2))
