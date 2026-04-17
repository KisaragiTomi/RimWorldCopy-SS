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

send_cmd({"command": "eval", "params": {"code": 'TickManager._ticks_per_frame[3] = 30\nTickManager.set_speed(3)\nreturn "fast"'}})
print("Fast-forwarding to night...")

for _ in range(30):
    time.sleep(1)
    result = send_cmd({"command": "eval", "params": {"code": 'return {"hour": TickManager.hour}'}})
    hour = result.get("result", {}).get("hour", 0)
    if hour >= 21 or hour < 4:
        print(f"Night reached at hour {hour}")
        break

code_zoom = """var mvp = get_tree().root.get_node("Main/GameHUD/@SubViewportContainer@313/@SubViewport@314/MapViewport")
var cam = null
for c in mvp.get_children():
\tif c is Camera2D:
\t\tcam = c
\t\tbreak
if cam == null:
\treturn "no camera"
cam.position = Vector2(60 * 16 + 8, 60 * 16 + 8)
cam.zoom = Vector2(2.5, 2.5)
return "zoomed"
"""
send_cmd({"command": "eval", "params": {"code": code_zoom}})
time.sleep(0.5)

result2 = send_cmd({"command": "screenshot"}, timeout=15)
img_b64 = result2.get("data") or result2.get("result", {}).get("image", "")
pathlib.Path("screenshots/art_r203_night.png").write_bytes(base64.b64decode(img_b64))
print("Saved night screenshot")
