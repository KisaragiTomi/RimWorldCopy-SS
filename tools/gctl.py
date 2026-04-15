import socket, json, sys, base64

def send_cmd(cmd_dict):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(15)
    sock.connect(("127.0.0.1", 9090))
    payload = json.dumps(cmd_dict) + chr(10)
    sock.sendall(payload.encode("utf-8"))
    buf = b""
    while True:
        chunk = sock.recv(65536)
        if not chunk:
            break
        buf += chunk
        if b"\n" in buf:
            break
    sock.close()
    return json.loads(buf.decode("utf-8").strip())

if __name__ == "__main__":
    action = sys.argv[1] if len(sys.argv) > 1 else "screenshot"
    if action == "screenshot":
        resp = send_cmd({"command": "screenshot"})
        if resp.get("success"):
            png = base64.b64decode(resp["data"])
            path = r"D:\MyProject\RimWorldCopy\screenshot.png"
            with open(path, "wb") as f:
                f.write(png)
            print("OK: %dx%d, %d bytes" % (resp["width"], resp["height"], len(png)))
        else:
            print("Error: %s" % resp)
    elif action == "eval":
        code = sys.argv[2]
        resp = send_cmd({"command": "eval", "params": {"code": code}})
        print(json.dumps(resp, indent=2, ensure_ascii=False)[:3000])
    elif action == "click":
        x, y = float(sys.argv[2]), float(sys.argv[3])
        resp = send_cmd({"command": "click", "params": {"x": x, "y": y}})
        print(json.dumps(resp))
    elif action == "ui":
        resp = send_cmd({"command": "get_ui_elements"})
        for e in resp.get("elements", []):
            txt = e.get("text", "")
            if txt:
                pos = e.get("position", {})
                sz = e.get("size", {})
                cx = pos.get("x", 0) + sz.get("width", 0) / 2
                cy = pos.get("y", 0) + sz.get("height", 0) / 2
                print("%-35s center=(%d,%d)" % (txt[:35], cx, cy))
