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

code = """var by_type = {}
for t in ThingManager.things:
\tif t is Building and t.state == Thing.ThingState.SPAWNED:
\t\tvar key = t.def_name + "_s" + str(t.build_state)
\t\tif not by_type.has(key):
\t\t\tby_type[key] = 0
\t\tby_type[key] += 1
return by_type
"""
result = send_cmd({"command": "eval", "params": {"code": code}})
print(json.dumps(result.get("result", {}), indent=2))
