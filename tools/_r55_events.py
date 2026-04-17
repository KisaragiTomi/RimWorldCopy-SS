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

print("=== R55 WINTER EVENTS ===\n")

# Pre-event check
tick = ev("return TickManager.current_tick")
season = ev("return SeasonManager.current_season")
print(f"Start: Tick={tick}, Season={season}")

# Trigger a fire
print("\n--- Fire Test ---")
ev('FireManager.start_fire(Vector2i(60, 70))\nreturn 1')
time.sleep(2)
af = ev("return FireManager.active_fires")
print(f"Active fires: {af}")

# Short FF to let fire play out
ev("TickManager.set_speed(3)\nreturn 1")
time.sleep(10)

af2 = ev("return FireManager.active_fires")
fe = ev("return FireManager.total_fires_extinguished")
print(f"After 10s: active={af2}, extinguished={fe}")

# Trigger a raid
print("\n--- Raid Test ---")
ev("RaidManager.spawn_raid()\nreturn 1")
time.sleep(5)
ar = ev("return RaidManager.active_raid")
rt = ev("return RaidManager.total_raids")
print(f"Raid: active={ar}, total={rt}")

# Let combat play out
time.sleep(15)
ar2 = ev("return RaidManager.active_raid")
print(f"After combat: active={ar2}")

# Check colonist status during combat
pcount = ev("return PawnManager.pawns.size()")
print(f"\n--- Colonists During Combat ({pcount}) ---")
for i in range(int(pcount)):
    name = ev(f"return PawnManager.pawns[{i}].pawn_name")
    job = ev(f"return PawnManager.pawns[{i}].current_job_name")
    food = ev(f'return PawnManager.pawns[{i}].get_need("Food")')
    downed = ev(f"return PawnManager.pawns[{i}].downed")
    f = food if isinstance(food, (int, float)) else 0
    print(f"  {name:8s} | {str(job):18s} | F={f:.2f} | down={downed}")

# Continue FF to Spring
print("\n--- FF to Spring ---")
for chunk in range(12):
    time.sleep(20)
    s = ev("return SeasonManager.current_season")
    t = ev("return TickManager.current_tick")
    fps = ev("return Engine.get_frames_per_second()")
    sname = {0: "Spring", 1: "Summer", 2: "Fall", 3: "Winter"}.get(s, str(s))
    print(f"  [{chunk+1}] {sname} | Tick={t} | FPS={fps}")
    if str(s) in ["Spring", "0"]:
        print("  >>> SPRING! Year cycle complete!")
        break

# Spring arrival
summary = ev("return SeasonManager.get_summary()")
if isinstance(summary, dict):
    print(f"\n  Season: {summary.get('current_season')}")
    print(f"  Year: {summary.get('year_count')}")
    print(f"  Changes: {summary.get('total_changes')}")
    print(f"  Growth: {summary.get('growth_factor')}")

# Final colonist check
print(f"\n--- Final Status ---")
for i in range(int(pcount)):
    name = ev(f"return PawnManager.pawns[{i}].pawn_name")
    job = ev(f"return PawnManager.pawns[{i}].current_job_name")
    food = ev(f'return PawnManager.pawns[{i}].get_need("Food")')
    mood = ev(f'return PawnManager.pawns[{i}].get_need("Mood")')
    f = food if isinstance(food, (int, float)) else 0
    m = mood if isinstance(mood, (int, float)) else 0
    print(f"  {name:8s} | {str(job):18s} | F={f:.2f} M={m:.2f}")

tick = ev("return TickManager.current_tick")
fps = ev("return Engine.get_frames_per_second()")
print(f"\nTick: {tick} | FPS: {fps}")

ev("TickManager.set_speed(1)\nreturn 1")
ev("var logger = get_node_or_null('/root/_DataLogger')\nif logger:\n\tvar log = logger.get_meta('log', [])\n\tlogger._save_to_disk(log)\nreturn 1")

print("\n=== R55 COMPLETE ===")
