import socket, json, time

s = socket.socket()
s.settimeout(15)
s.connect(('127.0.0.1', 9090))
print('Connected')

msg = json.dumps({
    'command': 'call_method',
    'params': {
        'node_path': '/root/Main',
        'method': 'switch_to_game',
        'args': []
    }
}) + '\n'
s.sendall(msg.encode('utf-8'))

buf = b''
while True:
    chunk = s.recv(65536)
    buf += chunk
    if b'\n' in buf:
        break

print('Response:', buf.decode('utf-8'))
s.close()