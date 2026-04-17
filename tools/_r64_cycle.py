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

print("=== R64 5TH ANNUAL CYCLE ===\n")

# Food supply
ev('ThingManager.spawn_item_stacks("MealSimple", 100, Vector2i(55, 65))\nreturn 1')

smap = {0: "Spring", 1: "Summer", 2: "Fall", 3: "Winter"}
target_seasons = ["Fall", "Winter", "Spring"]
current_target = 0
transitions = []

ev("TickManager.set_speed(3)\nreturn 1")

for chunk in range(40):
    time.sleep(20)
    s = ev("return SeasonManager.current_season")
    t = ev("return TickManager.current_tick")
    fps = ev("return Engine.get_frames_per_second()")
    sname = smap.get(s, str(s))
    
    if current_target < len(target_seasons) and sname == target_seasons[current_target]:
        # Record transition
        pcount = ev("return PawnManager.pawns.size()")
        jobs = {}
        for i in range(int(pcount)):
            name = ev(f"return PawnManager.pawns[{i}].pawn_name")
            job = ev(f"return PawnManager.pawns[{i}].current_job_name")
            jobs[name] = job
        
        farm = sum(1 for j in jobs.values() if j in ["Sow", "Harvest"])
        res = sum(1 for j in jobs.values() if j == "Research")
        transitions.append({"season": sname, "tick": t, "farm": farm, "res": res, "fps": fps})
        print(f"  >>> {sname} | Tick={t} | Farm={farm}/6 Res={res}/6 | FPS={fps}")
        
        current_target += 1
        if current_target >= len(target_seasons):
            print("\n  === 5TH CYCLE COMPLETE! ===")
            break
    elif chunk % 5 == 0:
        print(f"  [{chunk+1}] {sname} | Tick={t} | FPS={fps}")

# Final status
summary = ev("return SeasonManager.get_summary()")
if isinstance(summary, dict):
    print(f"\n  Season: {summary.get('current_season')}")
    print(f"  Year: {summary.get('year_count')}")
    print(f"  Changes: {summary.get('total_changes')}")

pcount = ev("return PawnManager.pawns.size()")
for i in range(int(pcount)):
    name = ev(f"return PawnManager.pawns[{i}].pawn_name")
    job = ev(f"return PawnManager.pawns[{i}].current_job_name")
    food = ev(f'return PawnManager.pawns[{i}].get_need("Food")')
    mood = ev(f'return PawnManager.pawns[{i}].get_need("Mood")')
    f = food if isinstance(food, (int, float)) else 0
    m = mood if isinstance(mood, (int, float)) else 0
    print(f"  {name:8s} | {str(job):18s} | F={f:.2f} M={m:.2f}")

tc = ev("return CraftingManager.total_crafted")
ac = ev("return AnimalManager.animals.size()")
rt = ev("return RaidManager.total_raids")
tick = ev("return TickManager.current_tick")
fps = ev("return Engine.get_frames_per_second()")
print(f"\n  Tick: {tick} | FPS: {fps}")
print(f"  Crafted: {tc} | Animals: {ac} | Raids: {rt}")

ev("TickManager.set_speed(1)\nreturn 1")
ev("var logger = get_node_or_null('/root/_DataLogger')\nif logger:\n\tvar log = logger.get_meta('log', [])\n\tlogger._save_to_disk(log)\nreturn 1")

print("\n=== R64 DONE ===")
