"""放大到基地中心并截图"""
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

find_code = """var result = []
var queue = [get_tree().root]
while queue.size() > 0:
	var n = queue.pop_front()
	if n is Camera2D:
		result.append(n.get_path())
	for c in n.get_children():
		queue.append(c)
return str(result)
"""

r = eval_code(find_code)
print(f"Cameras: {r}")

zoom_code = """var cams = []
var queue = [get_tree().root]
while queue.size() > 0:
	var n = queue.pop_front()
	if n is Camera2D:
		cams.append(n)
	for c in n.get_children():
		queue.append(c)
if cams.is_empty():
	return "no camera"
var cam = cams[0]
cam.zoom = Vector2(2.5, 2.5)
return "zoomed: " + str(cam.get_path())
"""

r2 = eval_code(zoom_code)
print(f"Zoom: {r2}")
time.sleep(0.5)

ss_path = sys.argv[1] if len(sys.argv) > 1 else "screenshots/art_r207_zoom.png"
screenshot(ss_path)
print("Done")
