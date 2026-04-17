import socket, json, sys

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

if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "status"

    if mode == "status":
        code = (
            "var d = TickManager.get_date()\n"
            "var dead_c = PawnManager.pawns.filter(func(p): return p.dead).size()\n"
            'return {"tick": TickManager.current_tick, "year": d.year, "quadrum": d.quadrum, '
            '"day": d.day, "pawns": PawnManager.pawns.size(), "dead": dead_c, '
            '"fps": Engine.get_frames_per_second()}'
        )
        result = send_cmd({"command": "eval", "params": {"code": code}})
        print(json.dumps(result, indent=2))

    elif mode == "screenshot":
        import base64, pathlib
        result = send_cmd({"command": "screenshot"}, timeout=15)
        img_b64 = result.get("data") or result.get("result", {}).get("image", "")
        out = sys.argv[2] if len(sys.argv) > 2 else "screenshots/art_check.png"
        pathlib.Path(out).parent.mkdir(parents=True, exist_ok=True)
        pathlib.Path(out).write_bytes(base64.b64decode(img_b64))
        print(f"Saved to {out}")

    elif mode == "eval":
        code = sys.argv[2]
        result = send_cmd({"command": "eval", "params": {"code": code}})
        print(json.dumps(result, indent=2, ensure_ascii=False))
