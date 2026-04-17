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

code = """var results = []
for p in PawnManager.pawns:
\tif p.dead: continue
\tvar info = {"name": p.pawn_name, "job": p.current_job_name, "food": snapped(p.get_need("Food"), 0.001), "rest": snapped(p.get_need("Rest"), 0.001), "mood": snapped(p.get_need("Mood"), 0.001)}
\tif p.has_method("get_mood_modifiers"):
\t\tinfo["mood_mods"] = p.get_mood_modifiers()
\tif p.has_method("get_thoughts"):
\t\tinfo["thoughts"] = p.get_thoughts()
\tif "joy" in p:
\t\tinfo["joy"] = snapped(p.joy, 0.001)
\tif p.has_method("get_need"):
\t\tinfo["joy_need"] = snapped(p.get_need("Joy"), 0.001)
\tresults.append(info)
return results
"""

r = tcp_eval(code)
print(json.dumps(r, indent=2))
