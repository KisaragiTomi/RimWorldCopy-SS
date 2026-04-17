import socket, json

s = socket.socket()
s.settimeout(3)
s.connect(('127.0.0.1', 9090))
code = 'TickManager.set_speed(3)\nreturn "speed=3"'
s.sendall(json.dumps({'command': 'eval', 'params': {'code': code}}).encode() + b'\n')
print(s.recv(4096).decode()[:200])
s.close()
