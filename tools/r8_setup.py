"""R8: 注入logger, 快进, 放大截图"""
import socket, json, time, base64, pathlib

def send(msg, timeout=10):
    s = socket.create_connection(('127.0.0.1', 9090), timeout=timeout)
    s.sendall(json.dumps(msg).encode() + b'\n')
    buf = b''
    while b'\n' not in buf:
        chunk = s.recv(65536)
        if not chunk: break
        buf += chunk
    s.close()
    return json.loads(buf.split(b'\n')[0])

def eval_code(code, timeout=10):
    return send({'command': 'eval', 'params': {'code': code}}, timeout)

def screenshot(path):
    r = send({'command': 'screenshot'})
    img_b64 = r.get("data") or r.get("result", {}).get("image", "")
    pathlib.Path(path).parent.mkdir(parents=True, exist_ok=True)
    pathlib.Path(path).write_bytes(base64.b64decode(img_b64))
    print(f"Saved: {path}")

# Check if game is running
r = eval_code('return {"tick": TickManager.current_tick, "hour": TickManager.hour, "pawns": PawnManager.pawns.size(), "buildings": ThingManager.get_buildings().size()}')
print(f"Status: {r}")

# Inject logger
logger_code = pathlib.Path(r"d:\MyProject\RimWorldCopy\.cursor\skills\rimworld-autotest\templates\logger_default.gd").read_text()
r2 = eval_code(logger_code)
print(f"Logger: {r2}")

# Fast forward to build colony
print("Fast forwarding 60s...")
eval_code('TickManager._ticks_per_frame[3] = 30\nTickManager.set_speed(3)\nreturn "ok"')
time.sleep(60)

# Slow down and skip to noon for better visibility
eval_code('TickManager._ticks_per_frame[3] = 60\nTickManager.set_speed(3)\nreturn "ok"')
for _ in range(20):
    time.sleep(2)
    r = eval_code('return TickManager.hour')
    hour = r.get('result', 0)
    if isinstance(hour, (int, float)) and 10 <= hour <= 14:
        break

eval_code('TickManager.set_speed(1)\nreturn "ok"')
time.sleep(0.5)

# Status
r3 = eval_code('return {"tick": TickManager.current_tick, "hour": TickManager.hour, "pawns": PawnManager.pawns.size(), "buildings": ThingManager.get_buildings().size()}')
print(f"After ffwd: {r3}")

# Zoom in on colony
eval_code("""
var mv = get_tree().root.get_node("Main/GameScene/MapViewport")
if mv and mv._camera:
\tmv._camera.zoom = Vector2(3.0, 3.0)
return "zoomed"
""")
time.sleep(0.5)
screenshot("screenshots/art_r205_zoomed.png")

# Zoom out overview
eval_code("""
var mv = get_tree().root.get_node("Main/GameScene/MapViewport")
if mv and mv._camera:
\tmv._camera.zoom = Vector2(1.0, 1.0)
return "unzoomed"
""")
time.sleep(0.5)
screenshot("screenshots/art_r205_overview.png")
