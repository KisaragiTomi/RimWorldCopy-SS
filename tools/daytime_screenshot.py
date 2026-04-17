"""快进到白天并截图"""
import socket, json, time, sys, base64, pathlib

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

def screenshot(path):
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
    print(f"Saved: {path}")

r = send_eval('return {"hour": TickManager.hour, "tick": TickManager.current_tick}')
print(f"Current: {r}")

hour = r.get('result', {}).get('hour', 0)
if isinstance(r.get('result'), dict):
    hour = r['result'].get('hour', 0)
else:
    hour = 12

if hour < 8 or hour >= 17:
    ticks_to_noon = 0
    if hour >= 17:
        ticks_to_noon = (24 - hour + 12) * 60 * 60
    else:
        ticks_to_noon = (12 - hour) * 60 * 60
    print(f"Fast-forwarding {ticks_to_noon} ticks to noon...")
    send_eval(f'TickManager._ticks_per_frame[3] = 60\nTickManager.set_speed(3)\nreturn "ok"')
    time.sleep(max(5, ticks_to_noon // 1800))
    send_eval('TickManager.set_speed(1)\nreturn "ok"')
    time.sleep(1)

r2 = send_eval('return {"hour": TickManager.hour, "tick": TickManager.current_tick, "buildings": ThingManager.get_buildings().size()}')
print(f"After ffwd: {r2}")

out = sys.argv[1] if len(sys.argv) > 1 else "screenshots/art_daytime.png"
screenshot(out)
