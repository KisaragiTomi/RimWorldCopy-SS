import socket, json

def tcp_eval(code):
    s = socket.socket()
    s.settimeout(5)
    s.connect(('127.0.0.1', 9090))
    s.sendall(json.dumps({'command': 'eval', 'params': {'code': code}}).encode() + b'\n')
    data = s.recv(16384).decode()
    s.close()
    return data

code = (
    'var result = []\n'
    'for p in PawnManager.pawns:\n'
    '\tif p.dead:\n'
    '\t\tcontinue\n'
    '\tresult.append({"name": p.pawn_name, "pos": [p.grid_pos.x, p.grid_pos.y], '
    '"job": p.current_job_name, "food": snapped(p.get_need("Food"), 0.01), '
    '"rest": snapped(p.get_need("Rest"), 0.01), "mood": snapped(p.get_need("Mood"), 0.01), '
    '"drafted": p.drafted, "downed": p.downed})\n'
    'return result'
)

result = tcp_eval(code)
parsed = json.loads(result)
if "result" in parsed:
    r = parsed["result"]
    if isinstance(r, str):
        r = r.replace("'", '"').replace("True", "true").replace("False", "false")
        data = json.loads(r)
    else:
        data = r
    for p in data:
        print(f"  {p['name']:10s} pos={p['pos']}  job={p['job']:15s}  food={p['food']:.2f}  rest={p['rest']:.2f}  mood={p['mood']:.2f}")
else:
    print(result)
