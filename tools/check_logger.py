"""检查 DataLogger 是否自动注入"""
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

code = """var logger = get_tree().root.get_node_or_null("_DataLogger")
if not logger:
	return {"exists": false}
var log = logger.get_meta("log")
return {"exists": true, "entries": log.size(), "max": logger.get_meta("max_entries"), "save_name": logger.get_meta("save_name")}
"""

r = eval_code(code)
print(json.dumps(r, indent=2, ensure_ascii=False))
