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
        return None
    except:
        return None
    finally:
        s.close()

print("=== R76 Harvest Fix Verification ===\n")

# Unlock research + spawn resources
ev("for p in ResearchManager.projects:\n\tResearchManager._complete_project(p)")
ev("ThingManager.spawn_item_stacks([{\"def_name\":\"MealSimple\",\"count\":30}])")
time.sleep(1)

# Check array sync
in_things = ev("var count = 0\nfor t in ThingManager.things:\n\tif t is Plant: count += 1\nreturn count")
in_plants = ev("return ThingManager.get_plants().size()")
print(f"Plants in things: {in_things}")
print(f"Plants in _plants: {in_plants}")
print(f"Arrays in sync: {in_things == in_plants}")

# Initial count
p0 = ev("return ThingManager.get_plants().size()")
tick0 = ev("return TickManager.current_tick")
print(f"\nInitial: plants={p0} tick={tick0}")

# Fast-forward 3x for 30s - verify plants decrease
print("\n--- 3x fast-forward 30s ---")
ev("TickManager.set_speed(3)")
for i in range(3):
    time.sleep(10)
    plants = ev("return ThingManager.get_plants().size()")
    tick = ev("return TickManager.current_tick")
    fps = ev("return Engine.get_frames_per_second()")
    
    pawns = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append(p.current_job_name)\nreturn r")
    
    print(f"  [{(i+1)*10}s] tick={tick} plants={plants} fps={fps} jobs={pawns}")

# Final check
p_final = ev("return ThingManager.get_plants().size()")
tick_final = ev("return TickManager.current_tick")
things_final = ev("return ThingManager.things.size()")
season = ev("return SeasonManager.current_season")
ev("TickManager.set_speed(1)")

print(f"\n--- Result ---")
print(f"  Plants: {p0} -> {p_final} (harvested {int(p0 or 0) - int(p_final or 0)})")
print(f"  Ticks: {tick0} -> {tick_final}")
print(f"  Things: {things_final}")
season_name = {0: "Spring", 1: "Summer", 2: "Fall", 3: "Winter"}.get(season, str(season))
print(f"  Season: {season_name}")

if int(p0 or 0) > int(p_final or 0):
    print(f"\n  *** HARVEST FIX CONFIRMED! Plants decreased by {int(p0 or 0) - int(p_final or 0)} ***")
else:
    print(f"\n  *** HARVEST STILL BROKEN ***")

print(f"\n=== DONE ===")
