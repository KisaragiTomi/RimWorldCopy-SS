import socket, json, time

PORT = 9090

def send_cmd(cmd, timeout=10):
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(timeout)
        s.connect(("127.0.0.1", PORT))
        s.sendall(json.dumps(cmd).encode() + b"\n")
        buf = b""
        while True:
            chunk = s.recv(4096)
            if not chunk:
                break
            buf += chunk
            try:
                return json.loads(buf.decode())
            except:
                continue
        return json.loads(buf.decode()) if buf else None
    except Exception as e:
        return {"error": str(e)}
    finally:
        s.close()

def ev(code):
    r = send_cmd({"command": "eval", "params": {"code": code}})
    if isinstance(r, dict) and "result" in r:
        return r["result"]
    return r

print("=== R67 6TH CYCLE ===\n")

ev('ThingManager.spawn_item_stacks("MealSimple", 100, Vector2i(55, 65))\nreturn 1')

smap = {0: "Spring", 1: "Summer", 2: "Fall", 3: "Winter"}
targets = ["Fall", "Winter", "Spring"]
idx = 0
transitions = []

ev("TickManager.set_speed(3)\nreturn 1")

for chunk in range(40):
    time.sleep(20)
    s = ev("return SeasonManager.current_season")
    t = ev("return TickManager.current_tick")
    fps = ev("return Engine.get_frames_per_second()")
    if isinstance(s, dict):
        sname = s.get("current_season", str(s))
    else:
        sname = smap.get(s, str(s))
    
    if idx < len(targets) and sname == targets[idx]:
        pcount = ev("return PawnManager.pawns.size()")
        farm = 0
        res = 0
        for i in range(int(pcount)):
            job = ev(f"return PawnManager.pawns[{i}].current_job_name")
            if job in ["Sow", "Harvest"]:
                farm += 1
            elif job == "Research":
                res += 1
        
        transitions.append({"season": sname, "tick": t, "farm": farm, "res": res})
        print(f"  >>> {sname} | Tick={t} | Farm={farm}/6 Res={res}/6 | FPS={fps}")
        idx += 1
        if idx >= len(targets):
            print("\n  === 6TH CYCLE COMPLETE! ===")
            break
    elif chunk % 5 == 0:
        total = t + 491000
        print(f"  [{chunk+1}] {sname} | Total~{total/1000:.0f}K | FPS={fps}")

# Final
summary = ev("return SeasonManager.get_summary()")
year = summary.get("year_count") if isinstance(summary, dict) else "?"
changes = summary.get("total_changes") if isinstance(summary, dict) else "?"
rt = ev("return RaidManager.total_raids")
tick = ev("return TickManager.current_tick")
total = tick + 491000

pcount = ev("return PawnManager.pawns.size()")
print(f"\n  Year: {year} | Changes: {changes} | Raids: {rt}")
print(f"  Tick: {tick} | Total: ~{total/1000:.0f}K")
print(f"  Colonists: {pcount}/6")

ev("TickManager.set_speed(1)\nreturn 1")
ev("var logger = get_node_or_null('/root/_DataLogger')\nif logger:\n\tvar log = logger.get_meta('log', [])\n\tlogger._save_to_disk(log)\nreturn 1")

print("\n=== DONE ===")
