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

code = (
    'var rm = ResearchManager\n'
    'var completed = rm.completed_projects.duplicate()\n'
    'var current = rm.current_project\n'
    'var queue = rm.research_queue.duplicate()\n'
    'var avail = rm.get_available_projects()\n'
    'return {"current": current, "completed_count": completed.size(), '
    '"completed": completed, "queue": queue, "available": avail}'
)
print(tcp_eval(code))
