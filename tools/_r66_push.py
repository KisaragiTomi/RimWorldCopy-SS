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

print("=== R66 PUSH FORWARD ===\n")

ev('ThingManager.spawn_item_stacks("MealSimple", 80, Vector2i(55, 65))\nreturn 1')
ev("TickManager.set_speed(3)\nreturn 1")

smap = {0: "Spring", 1: "Summer", 2: "Fall", 3: "Winter"}
last_season = None
transitions = 0

for chunk in range(15):
    time.sleep(20)
    s = ev("return SeasonManager.current_season")
    t = ev("return TickManager.current_tick")
    fps = ev("return Engine.get_frames_per_second()")
    sname = smap.get(s, str(s))
    
    if sname != last_season and last_season is not None:
        transitions += 1
        print(f"  >>> TRANSITION: {last_season} -> {sname} | Tick={t} | FPS={fps}")
    elif chunk % 3 == 0:
        total = t + 491000
        print(f"  [{chunk+1}] {sname} | Tick={t} | Total~{total/1000:.0f}K | FPS={fps}")
    
    last_season = sname

# Final status
pcount = ev("return PawnManager.pawns.size()")
print(f"\n--- Colonists ({pcount}/6) ---")
for i in range(int(pcount)):
    name = ev(f"return PawnManager.pawns[{i}].pawn_name")
    job = ev(f"return PawnManager.pawns[{i}].current_job_name")
    food = ev(f'return PawnManager.pawns[{i}].get_need("Food")')
    mood = ev(f'return PawnManager.pawns[{i}].get_need("Mood")')
    f = food if isinstance(food, (int, float)) else 0
    m = mood if isinstance(mood, (int, float)) else 0
    print(f"  {name:8s} | {str(job):18s} | F={f:.2f} M={m:.2f}")

summary = ev("return SeasonManager.get_summary()")
rt = ev("return RaidManager.total_raids")
tick = ev("return TickManager.current_tick")
total = tick + 491000
print(f"\nSeason: {summary.get('current_season') if isinstance(summary, dict) else '?'}")
print(f"Year: {summary.get('year_count') if isinstance(summary, dict) else '?'}")
print(f"Raids: {rt} | Transitions: {transitions} new")
print(f"Tick: {tick} | Total: ~{total/1000:.0f}K | FPS: {ev('return Engine.get_frames_per_second()')}")

ev("TickManager.set_speed(1)\nreturn 1")
ev("var logger = get_node_or_null('/root/_DataLogger')\nif logger:\n\tvar log = logger.get_meta('log', [])\n\tlogger._save_to_disk(log)\nreturn 1")

print("\n=== R66 DONE ===")
