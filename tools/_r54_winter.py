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

print("=== R54 FF TO WINTER ===\n")

# Ensure food for Winter
ev('ThingManager.spawn_item_stacks("MealSimple", 80, Vector2i(55, 65))\nreturn 1')
ev('ThingManager.spawn_item_stacks("RawFood", 60, Vector2i(56, 65))\nreturn 1')
print("Spawned food for Winter prep")

ev("TickManager.set_speed(3)\nreturn 1")

for chunk in range(12):
    time.sleep(20)
    s = ev("return SeasonManager.current_season")
    t = ev("return TickManager.current_tick")
    ch = ev("return SeasonManager.total_changes")
    fps = ev("return Engine.get_frames_per_second()")
    sname = {0: "Spring", 1: "Summer", 2: "Fall", 3: "Winter"}.get(s, str(s))
    print(f"  [{chunk+1}] {sname} | Tick={t} | Changes={ch} | FPS={fps}")
    if str(s) in ["Winter", "3"]:
        print("  >>> WINTER!")
        break

# Winter data
print("\n--- Winter Status ---")
summary = ev("return SeasonManager.get_summary()")
if isinstance(summary, dict):
    for k in ["current_season", "growth_factor", "is_growing", "is_harsh", "temp_offset", "total_changes"]:
        print(f"  {k}: {summary.get(k)}")

pcount = ev("return PawnManager.pawns.size()")
print(f"\n--- Colonists ({pcount}) ---")
for i in range(int(pcount)):
    name = ev(f"return PawnManager.pawns[{i}].pawn_name")
    job = ev(f"return PawnManager.pawns[{i}].current_job_name")
    food = ev(f'return PawnManager.pawns[{i}].get_need("Food")')
    mood = ev(f'return PawnManager.pawns[{i}].get_need("Mood")')
    rest = ev(f'return PawnManager.pawns[{i}].get_need("Rest")')
    f = food if isinstance(food, (int, float)) else 0
    m = mood if isinstance(mood, (int, float)) else 0
    r = rest if isinstance(rest, (int, float)) else 0
    print(f"  {name:8s} | {str(job):18s} | F={f:.2f} M={m:.2f} R={r:.2f}")

print("\n--- Resources ---")
for res in ["MealSimple", "Potato", "Meat", "RawFood"]:
    r = ev(f'var c = 0\nfor t in ThingManager.things:\n\tif t.def_name == "{res}":\n\t\tc += 1\nreturn c')
    if isinstance(r, (int, float)):
        print(f"  {res}: {int(r)}")

# Animals and events
ac = ev("return AnimalManager.animals.size()")
rt = ev("return RaidManager.total_raids")
ff = ev("return FireManager.total_fires_started")
print(f"\nAnimals: {ac} | Raids: {rt} | Fires: {ff}")

tick = ev("return TickManager.current_tick")
fps = ev("return Engine.get_frames_per_second()")
print(f"\nTick: {tick} | FPS: {fps}")

ev("TickManager.set_speed(1)\nreturn 1")
ev("var logger = get_node_or_null('/root/_DataLogger')\nif logger:\n\tvar log = logger.get_meta('log', [])\n\tlogger._save_to_disk(log)\nreturn 1")

print("\n=== R54 WINTER DONE ===")
