import socket, json, time, base64, pathlib

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

# Place a campfire at center
place_code = 'var bp = ThingManager.place_blueprint("Campfire", Vector2i(60, 60))\nif bp:\n\tbp.build_state = 2\n\treturn "placed"\nreturn "failed"'
r1 = send_cmd({"command": "eval", "params": {"code": place_code}})
print("Place campfire:", r1)

# Place torch lamp
place_code2 = 'var bp = ThingManager.place_blueprint("TorchLamp", Vector2i(59, 62))\nif bp:\n\tbp.build_state = 2\n\treturn "placed"\nreturn "failed"'
r2 = send_cmd({"command": "eval", "params": {"code": place_code2}})
print("Place torch:", r2)

# Check if active_map exists now
r3 = send_cmd({"command": "eval", "params": {"code": 'return GameState.active_map != null'}})
print("has_map:", r3)

# Check buildings
r4 = send_cmd({"command": "eval", "params": {"code": 'return ThingManager.get_buildings().size()'}})
print("buildings:", r4)
