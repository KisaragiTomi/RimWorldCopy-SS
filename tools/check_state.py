import socket, json

def send_cmd(cmd_dict, host="127.0.0.1", port=9090, timeout=15):
    s = socket.create_connection((host, port), timeout=timeout)
    s.sendall(json.dumps(cmd_dict).encode() + b"\n")
    buf = b""
    while True:
        chunk = s.recv(65536)
        if not chunk: break
        buf += chunk
        if b"\n" in buf: break
    s.close()
    return json.loads(buf.split(b"\n")[0].decode())

r1 = send_cmd({"command": "eval", "params": {"code": 'return ThingManager.get_buildings().size()'}})
print("buildings:", r1)

r2 = send_cmd({"command": "eval", "params": {"code": 'return {"hour": TickManager.hour, "tick": TickManager.current_tick}'}})
print("time:", r2)

r3 = send_cmd({"command": "eval", "params": {"code": 'return PawnManager.pawns.size()'}})
print("pawns:", r3)

r4 = send_cmd({"command": "eval", "params": {"code": 'return GameState.active_map != null'}})
print("has_map:", r4)
