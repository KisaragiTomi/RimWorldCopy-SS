"""注入logger, 等待采集, 保存为 game_raw_data.json"""
import socket, json, time, pathlib

def eval_code(code, timeout=10):
    s = socket.create_connection(('127.0.0.1', 9090), timeout=timeout)
    msg = {'command': 'eval', 'params': {'code': code}}
    s.sendall(json.dumps(msg).encode() + b'\n')
    buf = b''
    while b'\n' not in buf:
        chunk = s.recv(65536)
        if not chunk: break
        buf += chunk
    s.close()
    return json.loads(buf.split(b'\n')[0])

logger_code = pathlib.Path(r"d:\MyProject\RimWorldCopy\.cursor\skills\rimworld-autotest\templates\logger_default.gd").read_text()
r = eval_code(logger_code)
print(f"Logger injected: {r}")

eval_code('TickManager._ticks_per_frame[3] = 30\nTickManager.set_speed(3)\nreturn "ok"')
print("Collecting data for 60s...")
time.sleep(60)

eval_code('TickManager.set_speed(1)\nreturn "ok"')

fetch_code = pathlib.Path(r"d:\MyProject\RimWorldCopy\.cursor\skills\rimworld-autotest\templates\fetch_log.gd").read_text()
r2 = eval_code(fetch_code)
print(f"Log saved: {r2}")
