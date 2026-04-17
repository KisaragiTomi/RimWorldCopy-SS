"""简单截图工具"""
import socket, json, base64, pathlib, sys

def screenshot(path):
    s = socket.create_connection(('127.0.0.1', 9090), timeout=10)
    s.sendall(json.dumps({'command': 'screenshot'}).encode() + b'\n')
    buf = b''
    while b'\n' not in buf:
        chunk = s.recv(65536)
        if not chunk: break
        buf += chunk
    s.close()
    result = json.loads(buf.split(b'\n')[0])
    img_b64 = result.get("data") or result.get("result", {}).get("image", "")
    pathlib.Path(path).parent.mkdir(parents=True, exist_ok=True)
    pathlib.Path(path).write_bytes(base64.b64decode(img_b64))
    print(f"Saved: {path}")

screenshot(sys.argv[1] if len(sys.argv) > 1 else "screenshots/screenshot.png")
