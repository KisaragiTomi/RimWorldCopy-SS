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

print("=== R65 2 MILLION TICK MILESTONE ===\n")

# Need ~65K more ticks (1,936K + 64K = 2M)
# Session needs ~556K more (1,444K + 556K = 2M session)
# Actually total = session tick + 491K, so need session to reach ~1,509K
# Currently at ~1,444K, need ~65K more

tick_start = ev("return TickManager.current_tick")
print(f"Start: Tick {tick_start}")
target = 1509000  # ~2M total when added to 491K

ev('ThingManager.spawn_item_stacks("MealSimple", 80, Vector2i(55, 65))\nreturn 1')
ev("TickManager.set_speed(3)\nreturn 1")

smap = {0: "Spring", 1: "Summer", 2: "Fall", 3: "Winter"}

for chunk in range(15):
    time.sleep(20)
    t = ev("return TickManager.current_tick")
    s = ev("return SeasonManager.current_season")
    fps = ev("return Engine.get_frames_per_second()")
    sname = smap.get(s, str(s))
    total_est = t + 491000
    print(f"  [{chunk+1}] {sname} | Tick={t} | Total~{total_est/1000:.0f}K | FPS={fps}")
    
    if t >= target:
        print(f"\n  >>> 2 MILLION TOTAL TICKS! <<<")
        break

# Comprehensive final check
print("\n=== MILESTONE STATUS ===")
summary = ev("return SeasonManager.get_summary()")
if isinstance(summary, dict):
    for k in ["current_season", "year_count", "total_changes", "growth_factor"]:
        print(f"  {k}: {summary.get(k)}")

pcount = ev("return PawnManager.pawns.size()")
print(f"\n--- Colonists ({pcount}/6) ---")
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

# Resources
print("\n--- Resources ---")
for res in ["MealSimple", "Potato", "Meat", "RawFood", "Steel", "Component"]:
    r = ev(f'var c = 0\nfor t in ThingManager.things:\n\tif t.def_name == "{res}":\n\t\tc += 1\nreturn c')
    if isinstance(r, (int, float)):
        print(f"  {res}: {int(r)}")

# Events
tc = ev("return CraftingManager.total_crafted")
ac = ev("return AnimalManager.animals.size()")
rt = ev("return RaidManager.total_raids")
ff = ev("return FireManager.total_fires_started")
fe = ev("return FireManager.total_fires_extinguished")
rc = ev("return ResearchManager.total_completed")

print(f"\n--- Events ---")
print(f"  Crafted: {tc} | Animals: {ac}")
print(f"  Raids: {rt} | Fires: {ff} (extinguished: {fe})")
print(f"  Research: {rc}/30")

tick = ev("return TickManager.current_tick")
fps = ev("return Engine.get_frames_per_second()")
total = tick + 491000
print(f"\n  Session Tick: {tick}")
print(f"  Total Tick: ~{total} ({total/1000:.0f}K)")
print(f"  FPS: {fps}")

ev("TickManager.set_speed(1)\nreturn 1")
ev("var logger = get_node_or_null('/root/_DataLogger')\nif logger:\n\tvar log = logger.get_meta('log', [])\n\tlogger._save_to_disk(log)\nreturn 1")

print("\n=== R65 MILESTONE COMPLETE ===")
