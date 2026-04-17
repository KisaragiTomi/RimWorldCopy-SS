import socket, json

def tcp_eval(code):
    s = socket.socket()
    s.settimeout(15)
    s.connect(('127.0.0.1', 9090))
    s.sendall((json.dumps({'command':'eval','params':{'code':code}}) + '\n').encode())
    data = b''
    while b'\n' not in data:
        chunk = s.recv(4096)
        if not chunk: break
        data += chunk
    s.close()
    return json.loads(data.strip())

code = """var src = PawnManager.get_script().source_code
var idx = src.find("JobDriverWander")
var snippet = ""
if idx >= 0:
\tsnippet = src.substr(max(idx - 50, 0), 200)
else:
\tsnippet = "NOT_FOUND"
var crit_food_idx = src.find("CRITICAL_FOOD")
var crit_food_snippet = ""
if crit_food_idx >= 0:
\tcrit_food_snippet = src.substr(crit_food_idx, 50)
return {"has_wander_interrupt": idx >= 0, "snippet": snippet, "critical_food": crit_food_snippet}
"""

r = tcp_eval(code)
print(json.dumps(r, indent=2))
