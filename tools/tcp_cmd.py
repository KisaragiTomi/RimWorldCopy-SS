import socket, json, sys, base64, os

def send_cmd(cmd_dict, host="127.0.0.1", port=9090, timeout=30):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(timeout)
    sock.connect((host, port))
    payload = json.dumps(cmd_dict) + "\n"
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
    line = buf.split(b"\n")[0].decode("utf-8", errors="replace")
    return json.loads(line) if line else {}

if __name__ == "__main__":
    action = sys.argv[1] if len(sys.argv) > 1 else "screenshot"
    if action == "eval":
        code = sys.argv[2] if len(sys.argv) > 2 else "return OS.get_static_memory_usage()"
        r = send_cmd({"command": "eval", "params": {"code": code}})
        print(json.dumps(r, ensure_ascii=False, indent=2))
    elif action == "screenshot":
        out = sys.argv[2] if len(sys.argv) > 2 else "screen.png"
        r = send_cmd({"command": "screenshot"})
        if r.get("status") == "ok":
            img_b64 = r.get("data", r.get("image", ""))
            if img_b64:
                with open(out, "wb") as f:
                    f.write(base64.b64decode(img_b64))
                print("Saved %s (%d bytes)" % (out, os.path.getsize(out)))
            else:
                print("No image data in response")
        else:
            print(json.dumps(r, ensure_ascii=False, indent=2))
    elif action == "perf":
        r = send_cmd({"command": "get_performance"})
        print(json.dumps(r, ensure_ascii=False, indent=2))
    else:
        r = send_cmd(json.loads(action))
        print(json.dumps(r, ensure_ascii=False, indent=2))
