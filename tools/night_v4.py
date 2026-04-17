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

r = send_cmd({"command": "eval", "params": {"code": 'get_tree().reload_current_scene()\nreturn "reloading"'}})
print("Reload:", r)
time.sleep(3)

r2 = send_cmd({"command": "eval", "params": {"code": 'var main = get_tree().root.get_node("Main")\nmain.switch_to_game()\nreturn "switching"'}})
print("Switch:", r2)
time.sleep(5)

send_cmd({"command": "eval", "params": {"code": 'TickManager._ticks_per_frame[3] = 30\nTickManager.set_speed(3)\nreturn "fast"'}})
print("Fast forwarding to night...")

for i in range(60):
    time.sleep(1)
    result = send_cmd({"command": "eval", "params": {"code": 'return {"hour": TickManager.hour}'}})
    hour = result.get("result", {}).get("hour", 0)
    if i % 5 == 0:
        print(f"  hour={hour}")
    if hour >= 22 or hour < 4:
        print(f"Night reached at hour {hour}")
        break

send_cmd({"command": "eval", "params": {"code": 'TickManager.set_speed(0)\nreturn "paused"'}})
time.sleep(0.5)

zoom_code = """var found = false
for child in get_tree().root.get_children():
\tif child.name == "Main":
\t\tvar search_cam = func(node, depth):
\t\t\tif node is Camera2D:
\t\t\t\tnode.position = Vector2(60 * 16 + 8, 60 * 16 + 8)
\t\t\t\tnode.zoom = Vector2(2.5, 2.5)
\t\t\t\treturn true
\t\t\tfor c in node.get_children():
\t\t\t\tif depth < 8:
\t\t\t\t\tvar r = search_cam.call(c, depth + 1)
\t\t\t\t\tif r:
\t\t\t\t\t\treturn true
\t\t\treturn false
\t\tfound = search_cam.call(child, 0)
\t\tbreak
return "found" if found else "not_found"
"""
r3 = send_cmd({"command": "eval", "params": {"code": zoom_code}})
print("Camera zoom:", r3)
time.sleep(1)

result2 = send_cmd({"command": "screenshot"}, timeout=15)
img_b64 = result2.get("data") or result2.get("result", {}).get("image", "")
pathlib.Path("screenshots/art_r203_night_v4.png").write_bytes(base64.b64decode(img_b64))
print("Saved night screenshot v4")
