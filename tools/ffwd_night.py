"""快进到深夜并截图"""
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

eval_code('TickManager._ticks_per_frame[3] = 60\nTickManager.set_speed(3)\nreturn "ok"')

for _ in range(30):
    time.sleep(2)
    r = eval_code('return TickManager.hour')
    hour = r.get('result', 0)
    print(f"Hour: {hour}")
    if isinstance(hour, (int, float)) and (hour >= 22 or hour <= 2):
        print("Night reached!")
        break

eval_code('TickManager.set_speed(1)\nreturn "ok"')
time.sleep(0.5)
import sys
ss_path = "screenshots/art_r207_night.png"
if "--screenshot" in sys.argv:
    ss_path = sys.argv[sys.argv.index("--screenshot") + 1]
screenshot(ss_path)
