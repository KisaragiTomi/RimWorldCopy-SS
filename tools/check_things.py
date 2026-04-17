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

r1 = send_cmd({"command": "eval", "params": {"code": 'return typeof(ThingManager.buildings)'}})
print("type:", json.dumps(r1))

r2 = send_cmd({"command": "eval", "params": {"code": 'var props = []\nfor p in ThingManager.get_property_list():\n\tif p.name.begins_with("_") == false:\n\t\tprops.append(p.name)\nreturn props.slice(0, 20)'}})
print("props:", json.dumps(r2))

r3 = send_cmd({"command": "eval", "params": {"code": 'return {"has_map": GameState.active_map != null, "hour": TickManager.hour}'}})
print("state:", json.dumps(r3))
