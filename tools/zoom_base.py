"""放大到基地中心 3x 并截图"""
import socket, json, time, base64, pathlib, sys

def eval_code(code, timeout=10):
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

code = """var queue = [get_tree().root]
while queue.size() > 0:
	var n = queue.pop_front()
	if n is Camera2D:
		n.zoom = Vector2(3.5, 3.5)
		var center = Vector2(GameState.active_map.width / 2 * 16 + 8, GameState.active_map.height / 2 * 16 + 8)
		n.position = center
		return "zoomed 3.5x at center"
	for c in n.get_children():
		queue.append(c)
return "no camera"
"""

r = eval_code(code)
print(f"Zoom: {r}")
time.sleep(0.3)

ss_path = sys.argv[1] if len(sys.argv) > 1 else "screenshots/art_r208_base_zoom.png"
screenshot(ss_path)
