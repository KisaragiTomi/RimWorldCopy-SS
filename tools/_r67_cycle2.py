import socket, json, time

PORT = 9090

def ev(code):
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(10)
        s.connect(("127.0.0.1", PORT))
        s.sendall(json.dumps({"command": "eval", "params": {"code": code}}).encode() + b"\n")
        buf = b""
        while True:
            chunk = s.recv(4096)
            if not chunk:
                break
            buf += chunk
            try:
                r = json.loads(buf.decode())
                return r.get("result") if isinstance(r, dict) else r
            except:
                continue
        return json.loads(buf.decode()).get("result") if buf else None
    except:
        return None
    finally:
        s.close()

def safe_int(v, default=0):
    return int(v) if isinstance(v, (int, float)) else default

def safe_str(v, default="?"):
    return str(v) if v is not None else default

print("=== R67 6TH CYCLE ===\n")

ev('ThingManager.spawn_item_stacks("MealSimple", 100, Vector2i(55, 65))\nreturn 1')
ev("TickManager.set_speed(3)\nreturn 1")

smap = {0: "Spring", 1: "Summer", 2: "Fall", 3: "Winter"}
targets = ["Fall", "Winter", "Spring"]
idx = 0

for chunk in range(40):
    time.sleep(20)
    
    s = ev("return SeasonManager.current_season")
    t = ev("return TickManager.current_tick")
    fps = ev("return Engine.get_frames_per_second()")
    
    sname = smap.get(s, str(s)) if isinstance(s, (int, float)) else str(s)
    tick_val = safe_int(t)
    fps_val = safe_int(fps)
    
    if idx < len(targets) and sname == targets[idx]:
        print(f"  >>> {sname} | Tick={tick_val} | FPS={fps_val}")
        idx += 1
        if idx >= len(targets):
            print("\n  === 6TH CYCLE COMPLETE! ===")
            break
    elif chunk % 5 == 0:
        total = tick_val + 491000
        print(f"  [{chunk+1}] {sname} | Total~{total//1000}K | FPS={fps_val}")

# Final
tick = safe_int(ev("return TickManager.current_tick"))
total = tick + 491000
pcount = safe_int(ev("return PawnManager.pawns.size()"), 6)
rt = safe_int(ev("return RaidManager.total_raids"))
year = safe_int(ev("return SeasonManager.get_summary().get('year_count', 0)"))
changes = safe_int(ev("return SeasonManager.get_summary().get('total_changes', 0)"))

print(f"\n  Year: {year} | Changes: {changes} | Raids: {rt}")
print(f"  Tick: {tick} | Total: ~{total//1000}K | Colonists: {pcount}/6")

for i in range(pcount):
    name = ev(f"return PawnManager.pawns[{i}].pawn_name")
    job = ev(f"return PawnManager.pawns[{i}].current_job_name")
    food = ev(f'return PawnManager.pawns[{i}].get_need("Food")')
    mood = ev(f'return PawnManager.pawns[{i}].get_need("Mood")')
    f = food if isinstance(food, (int, float)) else 0
    m = mood if isinstance(mood, (int, float)) else 0
    print(f"  {safe_str(name):8s} | {safe_str(job):18s} | F={f:.2f} M={m:.2f}")

ev("TickManager.set_speed(1)\nreturn 1")
ev("var logger = get_node_or_null('/root/_DataLogger')\nif logger:\n\tvar log = logger.get_meta('log', [])\n\tlogger._save_to_disk(log)\nreturn 1")

print("\n=== DONE ===")
