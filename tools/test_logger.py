import socket, json, time

def send_cmd(cmd_dict, host="127.0.0.1", port=9090, timeout=15):
    s = socket.create_connection((host, port), timeout=timeout)
    s.sendall(json.dumps(cmd_dict).encode() + b"\n")
    buf = b""
    while True:
        chunk = s.recv(65536)
        if not chunk: break
        buf += chunk
        if b"\n" in buf: break
    s.close()
    return json.loads(buf.split(b"\n")[0].decode())

# Install simplified DataLogger (no active_map access)
inject_code = """var existing = get_tree().root.get_node_or_null("_DataLogger")
if existing:
\texisting.queue_free()
var logger = Node.new()
logger.name = "_DataLogger"
logger.set_meta("log", [])
logger.set_meta("max_entries", 300)
logger.set_meta("interval", 60)
logger.set_meta("counter", 0)
get_tree().root.add_child(logger)
TickManager.tick.connect(func(_t):
\tvar c = logger.get_meta("counter") + 1
\tlogger.set_meta("counter", c)
\tif c % logger.get_meta("interval") != 0:
\t\treturn
\tvar pawns_data = []
\tfor p in PawnManager.pawns:
\t\tif p.dead:
\t\t\tcontinue
\t\tpawns_data.append({"name": p.pawn_name, "pos": [p.grid_pos.x, p.grid_pos.y], "job": p.current_job_name})
\tvar entry = {"tick": TickManager.current_tick, "sec": c / 60, "pawn_count": pawns_data.size(), "pawns": pawns_data}
\tvar log = logger.get_meta("log")
\tif log.size() >= logger.get_meta("max_entries"):
\t\tlog.pop_front()
\tlog.append(entry)
)
return "logger_installed_300"
"""
r = send_cmd({"command": "eval", "params": {"code": inject_code}})
print("Install:", r)

# Fast forward
send_cmd({"command": "eval", "params": {"code": 'TickManager._ticks_per_frame[3] = 60\nTickManager.set_speed(3)\nreturn "fast"'}})
print("Fast forwarding 5+ game minutes...")

# Wait ~50 seconds real time for ~300+ game seconds
for i in range(50):
    time.sleep(1)
    if i % 10 == 0:
        check = send_cmd({"command": "eval", "params": {"code": 'var logger = get_tree().root.get_node_or_null("_DataLogger")\nif not logger:\n\treturn {"error": "no_logger"}\nreturn {"entries": logger.get_meta("log").size(), "counter": logger.get_meta("counter")}'}})
        data = check.get("result", {})
        print(f"  t={i}s entries={data.get('entries', '?')} counter={data.get('counter', '?')}")

# Pause
send_cmd({"command": "eval", "params": {"code": 'TickManager._ticks_per_frame[3] = 6\nTickManager.set_speed(0)\nreturn "paused"'}})

# Final check
final = send_cmd({"command": "eval", "params": {"code": 'var logger = get_tree().root.get_node_or_null("_DataLogger")\nif not logger:\n\treturn {"error": "no_logger"}\nvar log = logger.get_meta("log")\nvar first_tick = log[0]["tick"] if log.size() > 0 else -1\nvar last_tick = log[log.size()-1]["tick"] if log.size() > 0 else -1\nreturn {"entries": log.size(), "max": logger.get_meta("max_entries"), "counter": logger.get_meta("counter"), "first_tick": first_tick, "last_tick": last_tick}'}})
print("\nFinal result:", json.dumps(final, indent=2))

# Check if ring buffer is working (entries should cap at 300)
log_size = final.get("result", {}).get("entries", 0)
counter = final.get("result", {}).get("counter", 0)
max_e = final.get("result", {}).get("max", 0)
game_seconds = counter // 60
print(f"\nGame seconds elapsed: {game_seconds}")
print(f"Log entries: {log_size} (max: {max_e})")
if log_size == max_e and game_seconds > max_e:
    print("PASS: Ring buffer capped at max_entries correctly")
elif log_size <= max_e:
    print(f"OK: Log size {log_size} <= max {max_e} (need more time to fill)")
else:
    print("FAIL: Log exceeded max_entries!")
