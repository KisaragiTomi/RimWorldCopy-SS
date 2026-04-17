import socket, json

def send_cmd(cmd_dict, host="127.0.0.1", port=9090, timeout=15):
    s = socket.create_connection((host, port), timeout=timeout)
    s.sendall(json.dumps(cmd_dict).encode() + b"\n")
    buf = b""
    while True:
        chunk = s.recv(65536)
        if not chunk:
            break
        buf += chunk
        if b"\n" in buf:
            break
    s.close()
    line = buf.split(b"\n")[0]
    return json.loads(line.decode())

code = """var d = TickManager.get_date()
var dead_c = PawnManager.pawns.filter(func(p): return p.dead).size()
return {"tick": TickManager.current_tick, "year": d.year, "quadrum": d.quadrum, "day": d.day, "pawns": PawnManager.pawns.size(), "dead": dead_c, "fps": Engine.get_frames_per_second()}"""

result = send_cmd({"command": "eval", "params": {"code": code}})
print(json.dumps(result, indent=2))
