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

find_svp = 'var hud = get_tree().root.get_node("Main/GameHUD")\nfor c in hud.get_children():\n\tif c is SubViewportContainer:\n\t\tfor sv in c.get_children():\n\t\t\tif sv is SubViewport:\n\t\t\t\tfor mvp in sv.get_children():\n\t\t\t\t\tfor cam in mvp.get_children():\n\t\t\t\t\t\tif cam is Camera2D:\n\t\t\t\t\t\t\tcam.position = Vector2(60 * 16 + 8, 60 * 16 + 8)\n\t\t\t\t\t\t\tcam.zoom = Vector2(2.5, 2.5)\n\t\t\t\t\t\t\treturn "zoomed"\nreturn "no_cam"'
r = send_cmd({"command": "eval", "params": {"code": find_svp}})
print("Zoom:", r)
time.sleep(1)

result = send_cmd({"command": "screenshot"}, timeout=15)
img_b64 = result.get("data") or result.get("result", {}).get("image", "")
pathlib.Path("screenshots/art_r203_night_v4.png").write_bytes(base64.b64decode(img_b64))
print("Saved screenshot")
