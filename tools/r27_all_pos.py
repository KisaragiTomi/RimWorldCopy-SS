import socket, json

def tcp_eval(code):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(5)
    s.connect(("127.0.0.1", 9090))
    msg = json.dumps({"command": "eval", "params": {"code": code}}) + "\n"
    s.sendall(msg.encode())
    data = b""
    while b"\n" not in data:
        data += s.recv(4096)
    s.close()
    return json.loads(data.decode().strip())

for i in range(11):
    code = f'var p = PawnManager.pawns[{i}]\nreturn p.pawn_name + "|" + str(p.grid_pos.x) + "," + str(p.grid_pos.y) + "|" + p.current_job_name'
    r = tcp_eval(code)
    print(f"  {r.get('result', 'ERR')}")
