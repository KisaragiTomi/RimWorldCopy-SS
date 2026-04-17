import socket, json

def tcp_eval(code):
    s = socket.socket()
    s.settimeout(5)
    s.connect(('127.0.0.1', 9090))
    s.sendall(json.dumps({'command': 'eval', 'params': {'code': code}}).encode() + b'\n')
    data = s.recv(8192).decode()
    s.close()
    return data

code = (
    'var d = TickManager.get_date()\n'
    'var dc = PawnManager.pawns.filter(func(p): return p.dead).size()\n'
    'var ac = PawnManager.pawns.filter(func(p): return not p.dead).size()\n'
    'var jobs = {}\n'
    'for p in PawnManager.pawns:\n'
    '\tif p.dead:\n'
    '\t\tcontinue\n'
    '\tvar j = p.current_job_name\n'
    '\tjobs[j] = jobs.get(j, 0) + 1\n'
    'return {"tick": TickManager.current_tick, "year": d.year, "quadrum": d.quadrum, '
    '"day": d.day, "hour": d.hour, "pawns": PawnManager.pawns.size(), '
    '"alive": ac, "dead": dc, "fps": Engine.get_frames_per_second(), '
    '"speed": TickManager.speed, "jobs": jobs}'
)

result = tcp_eval(code)
parsed = json.loads(result)
if "result" in parsed:
    try:
        data = json.loads(parsed["result"].replace("'", '"'))
    except:
        data = parsed["result"]
    print(json.dumps(data, indent=2))
else:
    print(result)
