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

def find_and_zoom_cam(cx, cy, zoom_level):
    code = 'var hud = get_tree().root.get_node("Main/GameHUD")\nfor c in hud.get_children():\n\tif c is SubViewportContainer:\n\t\tfor sv in c.get_children():\n\t\t\tif sv is SubViewport:\n\t\t\t\tfor mvp in sv.get_children():\n\t\t\t\t\tfor cam in mvp.get_children():\n\t\t\t\t\t\tif cam is Camera2D:\n\t\t\t\t\t\t\tcam.position = Vector2(%d * 16 + 8, %d * 16 + 8)\n\t\t\t\t\t\t\tcam.zoom = Vector2(%s, %s)\n\t\t\t\t\t\t\treturn "zoomed"\nreturn "no_cam"' % (cx, cy, zoom_level, zoom_level)
    return send_cmd({"command": "eval", "params": {"code": code}})

# Reload
send_cmd({"command": "eval", "params": {"code": 'get_tree().reload_current_scene()\nreturn "ok"'}})
time.sleep(3)
send_cmd({"command": "eval", "params": {"code": 'var main = get_tree().root.get_node("Main")\nmain.switch_to_game()\nreturn "ok"'}})
time.sleep(5)

# Fast forward to night
send_cmd({"command": "eval", "params": {"code": 'TickManager._ticks_per_frame[3] = 30\nTickManager.set_speed(3)\nreturn "fast"'}})
for i in range(60):
    time.sleep(1)
    result = send_cmd({"command": "eval", "params": {"code": 'return {"hour": TickManager.hour}'}})
    hour = result.get("result", {}).get("hour", 0)
    if hour >= 22 or hour < 4:
        print(f"Night at hour {hour}")
        break

send_cmd({"command": "eval", "params": {"code": 'TickManager.set_speed(0)\nreturn "paused"'}})

# Zoom to building
find_and_zoom_cam(60, 60, 3.0)
time.sleep(1)

result = send_cmd({"command": "screenshot"}, timeout=15)
img_b64 = result.get("data") or result.get("result", {}).get("image", "")
pathlib.Path("screenshots/art_r203_night_glow.png").write_bytes(base64.b64decode(img_b64))
print("Saved night glow screenshot")
