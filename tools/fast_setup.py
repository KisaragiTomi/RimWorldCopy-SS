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

# Switch to game if needed
r = send_cmd({"command": "eval", "params": {"code": 'return str(get_tree().current_scene.name)'}})
print("Scene:", r)

if r.get("result") == "Main":
    r2 = send_cmd({"command": "eval", "params": {"code": 'var main = get_tree().root.get_node("Main")\nmain.switch_to_game()\nreturn "switching"'}})
    print("Switch:", r2)
    time.sleep(5)

# Fast forward game for 2 minutes of game time to build up base
send_cmd({"command": "eval", "params": {"code": 'TickManager._ticks_per_frame[3] = 60\nTickManager.set_speed(3)\nreturn "ultra_fast"'}})
print("Ultra fast forwarding...")

for i in range(120):
    time.sleep(1)
    result = send_cmd({"command": "eval", "params": {"code": 'return {"hour": TickManager.hour, "day": TickManager.current_tick / 60000}'}})
    data = result.get("result", {})
    if i % 10 == 0:
        print(f"  tick progress: {data}")
    blds = send_cmd({"command": "eval", "params": {"code": 'return ThingManager.get_buildings().size()'}})
    bld_count = blds.get("result", 0)
    hour = data.get("hour", 12)
    if bld_count > 20 and (hour >= 22 or hour < 4):
        print(f"Buildings={bld_count}, hour={hour} - ready!")
        break

send_cmd({"command": "eval", "params": {"code": 'TickManager.set_speed(0)\nreturn "paused"'}})

# Check glow sprites
r_glow = send_cmd({"command": "eval", "params": {"code": 'var hud = get_tree().root.get_node("Main/GameHUD")\nfor c in hud.get_children():\n\tif c is SubViewportContainer:\n\t\tfor sv in c.get_children():\n\t\t\tif sv is SubViewport:\n\t\t\t\tfor mvp in sv.get_children():\n\t\t\t\t\tif mvp.name == "MapViewport":\n\t\t\t\t\t\treturn {"glow": mvp._glow_sprites.size(), "bld_spr": mvp._building_sprites.size()}\nreturn "not found"'}})
print("Glow info:", r_glow)

# Zoom and screenshot
find_and_zoom_cam(60, 60, 3.0)
time.sleep(1)

result = send_cmd({"command": "screenshot"}, timeout=15)
img_b64 = result.get("data") or result.get("result", {}).get("image", "")
pathlib.Path("screenshots/art_r203_night_glow2.png").write_bytes(base64.b64decode(img_b64))
print("Saved screenshot")
