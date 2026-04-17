import socket, json, time

PORT = 9090

def ev(code):
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(10)
        s.connect(("127.0.0.1", PORT))
        cmd = {"command": "eval", "params": {"code": code}}
        s.sendall(json.dumps(cmd).encode() + b"\n")
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
        return None
    except:
        return None
    finally:
        s.close()

print("=== R69 SESSION 3 TEST ===\n")

# Quick stability check
tick = ev("return TickManager.current_tick")
fps = ev("return Engine.get_frames_per_second()")
print(f"Start: Tick={tick}, FPS={fps}")

# FF through first few seasons
ev("TickManager.set_speed(3)\nreturn 1")

smap = {0: "Spring", 1: "Summer", 2: "Fall", 3: "Winter"}
last_season = None

for chunk in range(20):
    time.sleep(20)
    s = ev("return SeasonManager.current_season")
    t = ev("return TickManager.current_tick")
    f = ev("return Engine.get_frames_per_second()")
    
    if s is None or t is None:
        print(f"  [{chunk+1}] CONNECTION LOST!")
        break
    
    sname = smap.get(s, str(s)) if isinstance(s, (int, float)) else str(s)
    tick_v = int(t) if isinstance(t, (int, float)) else 0
    fps_v = int(f) if isinstance(f, (int, float)) else 0
    
    if sname != last_season and last_season is not None:
        print(f"  >>> {last_season} -> {sname} | Tick={tick_v} | FPS={fps_v}")
    elif chunk % 3 == 0:
        print(f"  [{chunk+1}] {sname} | Tick={tick_v} | FPS={fps_v}")
    
    last_season = sname

# Final check
tick_v = ev("return TickManager.current_tick")
tick_v = int(tick_v) if isinstance(tick_v, (int, float)) else 0
fps_v = ev("return Engine.get_frames_per_second()")
fps_v = int(fps_v) if isinstance(fps_v, (int, float)) else 0
pcount = ev("return PawnManager.pawns.size()")
pcount = int(pcount) if isinstance(pcount, (int, float)) else 0
rt = ev("return RaidManager.total_raids")
rt = int(rt) if isinstance(rt, (int, float)) else 0

print(f"\n--- Final ---")
print(f"  Tick: {tick_v} | FPS: {fps_v} | Colonists: {pcount}/6 | Raids: {rt}")

for i in range(pcount):
    name = ev(f"return PawnManager.pawns[{i}].pawn_name")
    job = ev(f"return PawnManager.pawns[{i}].current_job_name")
    food = ev(f'return PawnManager.pawns[{i}].get_need("Food")')
    mood = ev(f'return PawnManager.pawns[{i}].get_need("Mood")')
    f = float(food) if isinstance(food, (int, float)) else 0
    m = float(mood) if isinstance(mood, (int, float)) else 0
    n = str(name) if name else "?"
    j = str(job) if job else "?"
    print(f"  {n:8s} | {j:18s} | F={f:.2f} M={m:.2f}")

ev("TickManager.set_speed(1)\nreturn 1")
ev("var logger = get_node_or_null('/root/_DataLogger')\nif logger:\n\tvar log = logger.get_meta('log', [])\n\tlogger._save_to_disk(log)\nreturn 1")

print("\n=== R69 DONE ===")
