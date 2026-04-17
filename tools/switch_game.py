"""Switch to game scene and wait for it to load"""
import socket, json, time, sys

def eval_code(code, timeout=15):
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

def screenshot(path):
    import base64, pathlib
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
    pathlib.Path(path).parent.mkdir(parents=True, exist_ok=True)
    pathlib.Path(path).write_bytes(base64.b64decode(img_b64))
    print(f"Screenshot saved: {path}")

print("Switching to game...")
r = eval_code('get_tree().root.get_node("Main").switch_to_game()\nreturn "ok"', timeout=30)
print(f"Switch: {r}")
time.sleep(5)

print("Checking if game is alive...")
try:
    r2 = eval_code('return 42')
    print(f"Alive: {r2}")
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)

code = 'var gs = {"tick": TickManager.current_tick, "hour": TickManager.hour, "speed": TickManager.speed, "pawns": PawnManager.pawns.size()}\nreturn str(gs)'
r3 = eval_code(code)
print(f"Status: {r3}")

eval_code('TickManager._ticks_per_frame[3] = 20\nTickManager.set_speed(3)\nreturn "ok"')
print("Speed set to 3x (TPF=20)")

if "--screenshot" in sys.argv:
    ss_path = sys.argv[sys.argv.index("--screenshot") + 1]
    screenshot(ss_path)
