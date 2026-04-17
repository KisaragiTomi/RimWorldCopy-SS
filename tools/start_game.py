"""切换到游戏场景并快进"""
import socket, json, time, sys

def send_eval(code, timeout=10):
    s = socket.create_connection(('127.0.0.1', 9090), timeout=timeout)
    msg = {'command': 'eval', 'params': {'code': code}}
    s.sendall(json.dumps(msg).encode() + b'\n')
    buf = b''
    while b'\n' not in buf:
        chunk = s.recv(65536)
        if not chunk: break
        buf += chunk
    s.close()
    return json.loads(buf.split(b'\n')[0])

def send_screenshot(path):
    s = socket.create_connection(('127.0.0.1', 9090), timeout=10)
    s.sendall(json.dumps({'command': 'screenshot'}).encode() + b'\n')
    buf = b''
    while b'\n' not in buf:
        chunk = s.recv(65536)
        if not chunk: break
        buf += chunk
    s.close()
    result = json.loads(buf.split(b'\n')[0])
    img_b64 = result.get("data") or result.get("result", {}).get("image", "")
    import base64, pathlib
    pathlib.Path(path).parent.mkdir(parents=True, exist_ok=True)
    pathlib.Path(path).write_bytes(base64.b64decode(img_b64))
    print(f"Screenshot saved: {path}")

print("Switching to game...")
r = send_eval('get_tree().root.get_node("Main").switch_to_game()\nreturn "ok"')
print(f"Switch: {r}")
time.sleep(3)

print("Checking status...")
r2 = send_eval('var gs = {"tick": TickManager.current_tick, "speed": TickManager.speed, "map": GameState.active_map != null, "pawns": PawnManager.pawns.size()}\nreturn str(gs)')
print(f"Status: {r2}")

print("Setting speed 3x (TPF=30)...")
r3 = send_eval('TickManager._ticks_per_frame[3] = 30\nTickManager.set_speed(3)\nreturn "ok"')
print(f"Speed: {r3}")

wait_secs = 60
if "--wait" in sys.argv:
    wait_secs = int(sys.argv[sys.argv.index("--wait") + 1])
print(f"Waiting {wait_secs}s for colony to build...")
time.sleep(wait_secs)

r4 = send_eval('var gs = {"tick": TickManager.current_tick, "pawns": PawnManager.pawns.size(), "buildings": ThingManager.get_buildings().size()}\nreturn str(gs)')
print(f"After wait: {r4}")

if "--screenshot" in sys.argv:
    ss_path = sys.argv[sys.argv.index("--screenshot") + 1]
    send_screenshot(ss_path)
