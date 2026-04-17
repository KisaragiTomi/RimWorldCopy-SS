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

# Super fast forward
send_cmd({"command": "eval", "params": {"code": 'TickManager._ticks_per_frame[3] = 120\nTickManager.set_speed(3)\nreturn "ultra_fast"'}})
print("Ultra fast forwarding to build up colony...")

for i in range(180):
    time.sleep(1)
    result = send_cmd({"command": "eval", "params": {"code": 'return {"hour": TickManager.hour, "bld": ThingManager.get_buildings().size(), "day": TickManager.current_tick / 60000}'}})
    data = result.get("result", {})
    bld_count = data.get("bld", 0)
    hour = data.get("hour", 12)
    day = data.get("day", 0)
    if i % 15 == 0:
        print(f"  day={day:.1f} hour={hour} buildings={bld_count}")
    if bld_count >= 20 and (hour >= 22 or hour < 4):
        print(f"Ready: day={day:.1f} hour={hour} buildings={bld_count}")
        break

send_cmd({"command": "eval", "params": {"code": 'TickManager._ticks_per_frame[3] = 6\nTickManager.set_speed(0)\nreturn "paused"'}})

# Zoom to building center
bld_info = send_cmd({"command": "eval", "params": {"code": 'var lights = []\nfor b in ThingManager.get_buildings():\n\tif b.def_name == "Campfire" or b.def_name == "TorchLamp":\n\t\tlights.append({"def": b.def_name, "pos": [b.grid_pos.x, b.grid_pos.y]})\nreturn lights'}})
print("Lights:", bld_info)

lights = bld_info.get("result", [])
if lights:
    cx = lights[0]["pos"][0]
    cy = lights[0]["pos"][1]
else:
    cx, cy = 60, 60

find_and_zoom_cam(cx, cy, 3.0)
time.sleep(1)

# Screenshots
result = send_cmd({"command": "screenshot"}, timeout=15)
img_b64 = result.get("data") or result.get("result", {}).get("image", "")
pathlib.Path("screenshots/art_r203_final_night.png").write_bytes(base64.b64decode(img_b64))
print("Saved final night screenshot")

# Now daytime
send_cmd({"command": "eval", "params": {"code": 'TickManager._ticks_per_frame[3] = 60\nTickManager.set_speed(3)\nreturn "fast"'}})
for i in range(60):
    time.sleep(1)
    result = send_cmd({"command": "eval", "params": {"code": 'return {"hour": TickManager.hour}'}})
    hour = result.get("result", {}).get("hour", 0)
    if 10 <= hour <= 14:
        print(f"Daytime at hour {hour}")
        break
send_cmd({"command": "eval", "params": {"code": 'TickManager._ticks_per_frame[3] = 6\nTickManager.set_speed(0)\nreturn "paused"'}})

find_and_zoom_cam(cx, cy, 3.0)
time.sleep(1)
result2 = send_cmd({"command": "screenshot"}, timeout=15)
img_b64_2 = result2.get("data") or result2.get("result", {}).get("image", "")
pathlib.Path("screenshots/art_r203_final_day.png").write_bytes(base64.b64decode(img_b64_2))
print("Saved final day screenshot")
