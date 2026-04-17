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
        return None
    except:
        return None
    finally:
        s.close()

print("=== R70 FPS CHECK ===\n")

# 1x speed FPS
ev("TickManager.set_speed(1)\nreturn 1")
time.sleep(5)
fps1 = ev("return Engine.get_frames_per_second()")
print(f"1x speed FPS: {fps1}")

# Check thing count
tc = ev("return ThingManager.things.size()")
print(f"Total things: {tc}")

# Check pawn count
pc = ev("return PawnManager.pawns.size()")
print(f"Pawns: {pc}")

# 2x speed
ev("TickManager.set_speed(2)\nreturn 1")
time.sleep(5)
fps2 = ev("return Engine.get_frames_per_second()")
print(f"2x speed FPS: {fps2}")

# 3x speed
ev("TickManager.set_speed(3)\nreturn 1")
time.sleep(5)
fps3 = ev("return Engine.get_frames_per_second()")
print(f"3x speed FPS: {fps3}")

# Quick FF
time.sleep(15)
tick = ev("return TickManager.current_tick")
fps = ev("return Engine.get_frames_per_second()")
tick2 = int(tick) if isinstance(tick, (int, float)) else 0
print(f"\nAfter 15s FF: Tick={tick2}, FPS={fps}")

# Season check
season = ev("return SeasonManager.current_season")
smap = {0: "Spring", 1: "Summer", 2: "Fall", 3: "Winter"}
sname = smap.get(season, str(season)) if isinstance(season, (int, float)) else str(season)
print(f"Season: {sname}")

# Colonists
pc = ev("return PawnManager.pawns.size()")
pc = int(pc) if isinstance(pc, (int, float)) else 6
for i in range(pc):
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

print("\n=== R70 DONE ===")
