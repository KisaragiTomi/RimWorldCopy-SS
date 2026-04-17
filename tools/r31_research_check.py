import socket, json

def tcp_eval(code):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(5)
    s.connect(("127.0.0.1", 9090))
    msg = json.dumps({"command": "eval", "params": {"code": code}}) + "\n"
    s.sendall(msg.encode())
    data = b""
    while b"\n" not in data:
        data += s.recv(4096)
    s.close()
    return json.loads(data.decode().strip())

code = 'return {"current": ResearchManager.current_project, "completed": ResearchManager._completed.keys(), "queue": ResearchManager.research_queue, "available": ResearchManager.get_available_projects()}'
result = tcp_eval(code)
print(json.dumps(result, indent=2))
