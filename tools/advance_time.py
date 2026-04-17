import socket, json, base64, pathlib, time

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

send_cmd({"command": "eval", "params": {"code": 'TickManager._ticks_per_frame[3] = 30\nTickManager.set_speed(3)\nreturn "fast"'}})
print("Speed set to fast, waiting 20 seconds for daytime...")
time.sleep(20)

result = send_cmd({"command": "eval", "params": {"code": 'return {"hour": TickManager.hour, "tick": TickManager.current_tick}'}})
print(json.dumps(result, indent=2))

result2 = send_cmd({"command": "screenshot"}, timeout=15)
img_b64 = result2.get("data") or result2.get("result", {}).get("image", "")
pathlib.Path("screenshots/art_r200_day.png").write_bytes(base64.b64decode(img_b64))
print("Saved daytime screenshot")
