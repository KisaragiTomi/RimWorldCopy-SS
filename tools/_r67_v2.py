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
                if isinstance(r, dict) and "result" in r:
                    return r["result"]
                return r
            except:
                continue
        if buf:
            r = json.loads(buf.decode())
            if isinstance(r, dict) and "result" in r:
                return r["result"]
        return None
    except:
        return None
    finally:
        s.close()

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
    
    if isinstance(s, int):
        sname = smap.get(s, str(s))
    elif isinstance(s, str):
        sname = s
    else:
        sname = "?"
    
    tick_v = int(t) if isinstance(t, (int, float)) else 0
    fps_v = int(fps) if isinstance(fps, (int, float)) else 0
    
    if idx < len(targets) and sname == targets[idx]:
        print(f"  >>> {sname} | Tick={tick_v} | FPS={fps_v}")
        idx += 1
        if idx >= len(targets):
            print("\n  === 6TH CYCLE COMPLETE! ===")
            break
    elif chunk % 5 == 0:
        total = tick_v + 491000
        print(f"  [{chunk+1}] {sname} | Total~{total // 1000}K | FPS={fps_v}")

# Final
tick_v = ev("return TickManager.current_tick")
tick_v = int(tick_v) if isinstance(tick_v, (int, float)) else 0
total = tick_v + 491000
rt = ev("return RaidManager.total_raids")
rt = int(rt) if isinstance(rt, (int, float)) else 0

print(f"\n  Tick: {tick_v} | Total: ~{total // 1000}K | Raids: {rt}")

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

print("\n=== DONE ===")
