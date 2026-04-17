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

print("=== R59 FULL CYCLE ===\n")

# Food supply
ev('ThingManager.spawn_item_stacks("MealSimple", 80, Vector2i(55, 65))\nreturn 1')
ev('ThingManager.spawn_item_stacks("RawFood", 60, Vector2i(56, 65))\nreturn 1')

# Start FF
ev("TickManager.set_speed(3)\nreturn 1")

target_seasons = ["Fall", "Winter", "Spring"]
smap = {0: "Spring", 1: "Summer", 2: "Fall", 3: "Winter"}
current_target = 0
transitions = []

for chunk in range(36):
    time.sleep(20)
    s = ev("return SeasonManager.current_season")
    t = ev("return TickManager.current_tick")
    fps = ev("return Engine.get_frames_per_second()")
    sname = smap.get(s, str(s))
    
    if current_target < len(target_seasons) and sname == target_seasons[current_target]:
        transitions.append({"season": sname, "tick": t})
        print(f"  >>> {sname} at Tick {t} (FPS={fps})")
        
        # Check colonist jobs at transition
        pcount = ev("return PawnManager.pawns.size()")
        jobs = {}
        for i in range(int(pcount)):
            name = ev(f"return PawnManager.pawns[{i}].pawn_name")
            job = ev(f"return PawnManager.pawns[{i}].current_job_name")
            jobs[name] = job
        farm = sum(1 for j in jobs.values() if j in ["Sow", "Harvest"])
        res = sum(1 for j in jobs.values() if j == "Research")
        print(f"      Jobs: farming={farm}/6 research={res}/6")
        
        current_target += 1
        if current_target >= len(target_seasons):
            print("\n  === CYCLE COMPLETE! ===")
            break
    elif chunk % 3 == 0:
        print(f"  [{chunk+1}] {sname} | Tick={t} | FPS={fps}")

# Final status
print("\n--- Final Status ---")
summary = ev("return SeasonManager.get_summary()")
if isinstance(summary, dict):
    print(f"  Season: {summary.get('current_season')}")
    print(f"  Year: {summary.get('year_count')}")
    print(f"  Changes: {summary.get('total_changes')}")
    print(f"  Growth: {summary.get('growth_factor')}")

pcount = ev("return PawnManager.pawns.size()")
print(f"\n  Colonists: {pcount}/6")
for i in range(int(pcount)):
    name = ev(f"return PawnManager.pawns[{i}].pawn_name")
    job = ev(f"return PawnManager.pawns[{i}].current_job_name")
    food = ev(f'return PawnManager.pawns[{i}].get_need("Food")')
    mood = ev(f'return PawnManager.pawns[{i}].get_need("Mood")')
    f = food if isinstance(food, (int, float)) else 0
    m = mood if isinstance(mood, (int, float)) else 0
    print(f"    {name:8s} | {str(job):18s} | F={f:.2f} M={m:.2f}")

# Stats
tc = ev("return CraftingManager.total_crafted")
ac = ev("return AnimalManager.animals.size()")
rt = ev("return RaidManager.total_raids")
ff = ev("return FireManager.total_fires_started")

tick = ev("return TickManager.current_tick")
fps = ev("return Engine.get_frames_per_second()")
print(f"\n  Tick: {tick} | FPS: {fps}")
print(f"  Crafted: {tc} | Animals: {ac} | Raids: {rt} | Fires: {ff}")

ev("TickManager.set_speed(1)\nreturn 1")
ev("var logger = get_node_or_null('/root/_DataLogger')\nif logger:\n\tvar log = logger.get_meta('log', [])\n\tlogger._save_to_disk(log)\nreturn 1")

print("\n=== R59 DONE ===")
