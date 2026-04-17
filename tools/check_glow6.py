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

code = 'var hud = get_tree().root.get_node("Main/GameHUD")\nfor c in hud.get_children():\n\tif c is SubViewportContainer:\n\t\tfor sv in c.get_children():\n\t\t\tif sv is SubViewport:\n\t\t\t\tfor mvp in sv.get_children():\n\t\t\t\t\tif mvp.name == "MapViewport":\n\t\t\t\t\t\treturn mvp._glow_sprites.size()\nreturn -1'
r = send_cmd({"command": "eval", "params": {"code": code}})
print("glow size:", json.dumps(r))

code2 = 'var hud = get_tree().root.get_node("Main/GameHUD")\nfor c in hud.get_children():\n\tif c is SubViewportContainer:\n\t\tfor sv in c.get_children():\n\t\t\tif sv is SubViewport:\n\t\t\t\tfor mvp in sv.get_children():\n\t\t\t\t\tif mvp.name == "MapViewport":\n\t\t\t\t\t\tvar cnt = 0\n\t\t\t\t\t\tfor ch in mvp.get_children():\n\t\t\t\t\t\t\tif ch is Sprite2D and ch.blend_mode == 1:\n\t\t\t\t\t\t\t\tcnt += 1\n\t\t\t\t\t\treturn cnt\nreturn -1'
r2 = send_cmd({"command": "eval", "params": {"code": code2}})
print("additive sprites:", json.dumps(r2))
