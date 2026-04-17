"""快速检查游戏状态"""
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

code = """var gs = {
	"screen": str(GameState.current_screen),
	"map": GameState.active_map != null,
	"tick": TickManager.current_tick,
	"hour": TickManager.hour,
	"pawns": PawnManager.pawns.size(),
}
var logger = get_tree().root.get_node_or_null("_DataLogger")
if logger:
	gs["logger_entries"] = logger.get_meta("log").size()
else:
	gs["logger"] = "not_found"
return str(gs)
"""
r = eval_code(code)
print(r)
