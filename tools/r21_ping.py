import socket, json, sys

s = socket.socket()
s.settimeout(5)
try:
    s.connect(('127.0.0.1', 9090))
    print("Connected OK")
    s.sendall(b'{"command":"eval","params":{"code":"return 42"}}\n')
    print("Sent OK")
    s.settimeout(5)
    data = s.recv(4096)
    print("Received:", data)
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
finally:
    s.close()
