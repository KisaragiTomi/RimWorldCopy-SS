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

code = 'TickManager._ticks_per_frame[3] = 30\nTickManager.set_speed(3)\nreturn "ok"'
result = send_cmd({"command": "eval", "params": {"code": code}})
print(json.dumps(result, indent=2))
