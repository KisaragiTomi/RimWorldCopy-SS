import socket, json, time

def tcp_eval(code, timeout=10):
    s = socket.socket()
    s.settimeout(timeout)
    s.connect(('127.0.0.1', 9090))
    msg = json.dumps({'command': 'eval', 'params': {'code': code}}) + '\n'
    s.sendall(msg.encode())
    result = s.recv(65536).decode()
    s.close()
    return result

inject_code = (
    'var root = get_tree().root\n'
    'var existing = root.get_node_or_null("_DataLogger")\n'
    'if existing:\n'
    '\treturn "already_exists"\n'
    'var script = load("res://scripts/utils/auto_logger.gd")\n'
    'var node = Node.new()\n'
    'node.name = "_DataLogger"\n'
    'node.set_script(script)\n'
    'node.set_meta("log", [])\n'
    'node.set_meta("max_entries", 300)\n'
    'node.set_meta("save_name", "game_raw_data")\n'
    'root.add_child(node)\n'
    'return "injected"'
)

print("Injecting DataLogger...")
print(tcp_eval(inject_code))

print("Setting speed 3 (fast)...")
print(tcp_eval('TickManager._ticks_per_frame[3] = 30\nTickManager.set_speed(3)\nreturn "ok"'))

print("Waiting 90 seconds for data collection...")
time.sleep(90)

fetch_code = (
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

print("Fetching log...")
print(tcp_eval(fetch_code))
