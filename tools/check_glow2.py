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
\t\t\t\t\tvar add_sprites = 0
\t\t\t\t\tvar z5_sprites = 0
\t\t\t\t\tvar sample_z = []
\t\t\t\t\tfor child in mvp.get_children():
\t\t\t\t\t\tif child is Sprite2D:
\t\t\t\t\t\t\tif child.blend_mode == 1:
\t\t\t\t\t\t\t\tadd_sprites += 1
\t\t\t\t\t\t\tif child.z_index >= 4:
\t\t\t\t\t\t\t\tz5_sprites += 1
\t\t\t\t\t\t\t\tif sample_z.size() < 5:
\t\t\t\t\t\t\t\t\tsample_z.append({"z": child.z_index, "blend": child.blend_mode, "pos": [child.position.x, child.position.y]})
\t\t\t\t\treturn {"add_count": add_sprites, "z4plus": z5_sprites, "samples": sample_z}
return "not found"'''
r = send_cmd({"command": "eval", "params": {"code": code}})
print(json.dumps(r, indent=2))

code2 = '''var hud = get_tree().root.get_node("Main/GameHUD")
for c in hud.get_children():
\tif c is SubViewportContainer:
\t\tfor sv in c.get_children():
\t\t\tif sv is SubViewport:
\t\t\t\tfor mvp in sv.get_children():
\t\t\t\t\tif mvp.has_method("get_building_sprite_count"):
\t\t\t\t\t\treturn "has_method"
\t\t\t\t\tvar script_name = mvp.get_script().get_path() if mvp.get_script() else "no_script"
\t\t\t\t\treturn {"script": script_name, "name": mvp.name}
return "not found"'''
r2 = send_cmd({"command": "eval", "params": {"code": code2}})
print("MVP info:", json.dumps(r2, indent=2))
