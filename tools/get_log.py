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

# Try to load the script manually
r = send_cmd({"command": "eval", "params": {"code": 'var scr = load("res://scenes/game_map/map_viewport.gd")\nif scr:\n\treturn "loaded"\nreturn "failed_to_load"'}})
print("Load script:", r)
