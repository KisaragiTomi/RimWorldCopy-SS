import socket, json, base64, time

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect(('127.0.0.1', 9090))
s.sendall(b'{"command":"screenshot"}\n')
time.sleep(2)

data = b''
s.settimeout(3)
while True:
    try:
        chunk = s.recv(1048576)
        if not chunk:
            break
        data += chunk
    except socket.timeout:
        break
    except Exception as e:
        print(f"Error receiving: {e}")
        break

s.close()

lines = data.decode('utf-8').strip().split('\n')
for line in lines:
    line = line.strip()
    if not line:
        continue
    resp = json.loads(line)
    if 'data' in resp:
        img = base64.b64decode(resp['data'])
        path = 'd:/MyProject/RimWorldCopy/screenshot.png'
        with open(path, 'wb') as f:
            f.write(img)
        print(f"Screenshot saved: {resp.get('width','?')}x{resp.get('height','?')}")
    elif 'error' in resp:
        print(f"Error: {resp['error']}")
    else:
        print(f"Unknown: {list(resp.keys())}")
