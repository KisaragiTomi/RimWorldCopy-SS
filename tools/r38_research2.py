import socket, json

def tcp_eval(code, timeout=10):
    s = socket.socket()
    s.settimeout(timeout)
    s.connect(('127.0.0.1', 9090))
    msg = json.dumps({'command': 'eval', 'params': {'code': code}}) + '\n'
    s.sendall(msg.encode())
    result = s.recv(65536).decode()
    s.close()
    return result

print("Current project:")
print(tcp_eval('return ResearchManager.current_project'))

print("\nCompleted count:")
print(tcp_eval('return str(ResearchManager.completed_projects.size())'))

print("\nCompleted list:")
print(tcp_eval('return str(ResearchManager.completed_projects)'))

print("\nAvailable:")
print(tcp_eval('return str(ResearchManager.get_available_projects())'))

print("\nQueue:")
print(tcp_eval('return str(ResearchManager.research_queue)'))
