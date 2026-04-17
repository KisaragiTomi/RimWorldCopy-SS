import socket, json, base64, pathlib, time

def send_cmd(cmd_dict, host="127.0.0.1", port=9090, timeout=15):
    s = socket.create_connection((host, port), timeout=timeout)
    s.sendall(json.dumps(cmd_dict).encode() + b"\n")
    buf = b""
    while True:
        chunk = s.recv(65536)
        if not chunk:
            break
        buf += chunk
        if b"\n" in buf:
            break
    s.close()
    line = buf.split(b"\n")[0]
    return json.loads(line.decode())

code = """var mvp = get_tree().root.get_node("Main/GameHUD/@SubViewportContainer@313/@SubViewport@314/MapViewport")
var cam = null
for c in mvp.get_children():
\tif c is Camera2D:
\t\tcam = c
\t\tbreak
if cam == null:
\treturn "no camera"
cam.position = Vector2(60 * 16 + 8, 60 * 16 + 8)
cam.zoom = Vector2(1.0, 1.0)
return "zoomed out"
"""
result = send_cmd({"command": "eval", "params": {"code": code}})
print(json.dumps(result, indent=2))

time.sleep(0.5)

result2 = send_cmd({"command": "screenshot"}, timeout=15)
img_b64 = result2.get("data") or result2.get("result", {}).get("image", "")
pathlib.Path("screenshots/art_r200_final.png").write_bytes(base64.b64decode(img_b64))
print("Saved final screenshot")
