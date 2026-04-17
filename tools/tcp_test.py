"""Simple TCP test for eval"""
import socket, json

s = socket.create_connection(('127.0.0.1', 9090), 5)
msg = {'command': 'eval', 'params': {'code': 'return 42'}}
payload = json.dumps(msg).encode() + b'\n'
print(f"Sending: {payload}")
s.sendall(payload)
buf = b''
while b'\n' not in buf:
    c = s.recv(65536)
    if not c:
        break
    buf += c
s.close()
print(f"Response: {buf.decode().strip()}")
