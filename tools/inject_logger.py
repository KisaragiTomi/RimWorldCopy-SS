import socket, json

def send_cmd(cmd_dict, host="127.0.0.1", port=9090, timeout=15):
    s = socket.create_connection((host, port), timeout=timeout)
    s.sendall(json.dumps(cmd_dict).encode() + b"\n")
    buf = b""
    while True:
        chunk = s.recv(65536)
        if not chunk:
            break
        buf += chunk
        if b"\n" in buf:
            break
    s.close()
    line = buf.split(b"\n")[0]
    return json.loads(line.decode())

code = """var existing = get_tree().root.get_node_or_null("_DataLogger")
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
\t\tvar pi = {"name": p.pawn_name, "pos": [p.grid_pos.x, p.grid_pos.y], "job": p.current_job_name, "food": p.get_need("Food"), "rest": p.get_need("Rest"), "mood": p.get_need("Mood"), "drafted": p.drafted, "downed": p.downed, "gear": p.equipment.slots if p.equipment else {}}
\t\tvar cell = GameState.active_map.get_cell_v(p.grid_pos)
\t\tif cell:
\t\t\tvar ct = []
\t\t\tfor t in cell.things:
\t\t\t\tct.append({"def": t.def_name, "type": t.get_class()})
\t\t\tpi["cell"] = {"terrain": cell.terrain_def, "roof": cell.roof, "building": cell.building.def_name if cell.building else null, "zone": str(cell.zone) if cell.zone else null, "things": ct}
\t\tpawns_data.append(pi)
\tvar entry = {"tick": TickManager.current_tick, "sec": c / 60, "pawns": pawns_data}
\tvar log = logger.get_meta("log")
\tif log.size() >= logger.get_meta("max_entries"):
\t\tlog.pop_front()
\tlog.append(entry)
)
return "logger_installed_300"
"""

result = send_cmd({"command": "eval", "params": {"code": code}})
print(json.dumps(result, indent=2))
