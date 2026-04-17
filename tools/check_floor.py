"""检查 FloorManager 状态"""
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

code = """if not FloorManager:
	return "no FloorManager"
return {"count": FloorManager.get_floor_count(), "placed": FloorManager.total_placed, "common": FloorManager.get_most_common_floor()}
"""

r = eval_code(code)
print(json.dumps(r, indent=2, ensure_ascii=False))
