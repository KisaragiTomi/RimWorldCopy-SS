"""重置相机缩放"""
import socket, json

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

code = """var queue = [get_tree().root]
while queue.size() > 0:
	var n = queue.pop_front()
	if n is Camera2D:
		n.zoom = Vector2(1.0, 1.0)
		return "reset to 1x"
	for c in n.get_children():
		queue.append(c)
return "no camera"
"""
r = eval_code(code)
print(r)
