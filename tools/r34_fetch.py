import socket, json

code = (
    'var logger = get_tree().root.get_node_or_null("_DataLogger")\n'
    'if not logger:\n'
    '\treturn {"error": "no_logger"}\n'
    'var log = logger.get_meta("log")\n'
    'var save_name = logger.get_meta("save_name", "game_raw_data")\n'
    'var dir = ProjectSettings.globalize_path("res://logs")\n'
    'DirAccess.make_dir_absolute(dir)\n'
    'var path = dir + "/" + save_name + ".json"\n'
    'var file = FileAccess.open(path, FileAccess.WRITE)\n'
    'if file:\n'
    '\tfile.store_string(JSON.stringify(log))\n'
    '\tfile.close()\n'
    '\treturn {"entries": log.size(), "saved_to": path}\n'
    'return log'
)

s = socket.socket()
s.settimeout(10)
s.connect(('127.0.0.1', 9090))
msg = json.dumps({'command': 'eval', 'params': {'code': code}}) + '\n'
s.sendall(msg.encode())
print(s.recv(4096).decode())
s.close()
