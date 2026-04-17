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

code = """var logger = get_tree().root.get_node_or_null("_DataLogger")
if not logger:
\treturn {"error": "no_logger"}
return logger.get_meta("log")"""

result = send_cmd({"command": "eval", "params": {"code": code}})
if "result" in result and isinstance(result["result"], list):
    logs = result["result"]
    print(f"Total entries: {len(logs)}")
    if logs:
        print(f"First tick: {logs[0].get('tick')}, Last tick: {logs[-1].get('tick')}")
        last = logs[-1]
        print(f"\nLast entry (sec={last.get('sec')}):")
        for p in last.get("pawns", []):
            cell_info = p.get("cell", {})
            print(f"  {p['name']}: pos={p['pos']}, job={p['job']}, food={p.get('food','?'):.2f}, terrain={cell_info.get('terrain','?')}, building={cell_info.get('building')}, things={len(cell_info.get('things',[]))}")
else:
    print(json.dumps(result, indent=2, ensure_ascii=False))
