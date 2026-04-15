import socket, json, base64, os, sys

s = socket.socket()
s.settimeout(15)
s.connect(('127.0.0.1', 9090))
msg = json.dumps({'command': 'screenshot'}) + '\n'
s.sendall(msg.encode('utf-8'))
buf = b''
while True:
    chunk = s.recv(65536)
    buf += chunk
    if b'\n' in buf:
        break
resp = json.loads(buf.decode('utf-8'))
if resp.get('success'):
    os.makedirs('d:/MyProject/RimWorldCopy/screenshots', exist_ok=True)
    label = sys.argv[1] if len(sys.argv) > 1 else 'shot'
    path = 'd:/MyProject/RimWorldCopy/screenshots/' + label + '.png'
    with open(path, 'wb') as f:
        f.write(base64.b64decode(resp['data']))
    w, h = resp['width'], resp['height']
    print('Saved ' + path + ' (' + str(w) + 'x' + str(h) + ')')
else:
    print('Failed:', resp)
s.close()
