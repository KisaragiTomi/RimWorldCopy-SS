import socket, json

def tcp_eval(code):
    s = socket.socket()
    s.settimeout(10)
    s.connect(('127.0.0.1', 9090))
    cmd = json.dumps({'command': 'eval', 'params': {'code': code}})
    s.sendall((cmd + '\n').encode())
    r = b''
    while True:
        try:
            d = s.recv(4096)
            if not d: break
            r += d
        except socket.timeout:
            break
    s.close()
    return r.decode()

with open('d:/MyProject/RimWorldCopy/.cursor/skills/rimworld-autotest/templates/fetch_log.gd', 'r') as f:
    code = f.read()

result = tcp_eval(code)
print(result[:300])
