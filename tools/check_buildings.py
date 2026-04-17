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

code = 'var types = {}\nfor bld in ThingManager.buildings:\n\tvar d = bld.def_name\n\tif d not in types:\n\t\ttypes[d] = 0\n\ttypes[d] += 1\nreturn types'
r = send_cmd({"command": "eval", "params": {"code": code}})
print(json.dumps(r, indent=2))
