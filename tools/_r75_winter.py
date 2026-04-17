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

print("=== R75 Winter Push ===\n")

# Spawn food for winter survival
ev("ThingManager.spawn_item_stacks([{\"def_name\":\"MealSimple\",\"count\":50}])")

tick0 = ev("return TickManager.current_tick")
crafted0 = ev("return CraftingManager.total_crafted")
print(f"Start: tick={tick0}, crafted={crafted0}")

ev("TickManager.set_speed(3)")

for i in range(8):
    time.sleep(15)
    tick = ev("return TickManager.current_tick")
    season = ev("return SeasonManager.current_season")
    crafted = ev("return CraftingManager.total_crafted")
    queue = ev("return CraftingManager.craft_queue.size()")
    fps = ev("return Engine.get_frames_per_second()")
    things = ev("return ThingManager.things.size()")
    
    pawns = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append(p.current_job_name)\nreturn r")
    
    season_name = {0: "Spring", 1: "Summer", 2: "Fall", 3: "Winter"}.get(season, str(season))
    print(f"  [{(i+1)*15}s] tick={tick} season={season_name} fps={fps} things={things} crafted={crafted} queue={queue} jobs={pawns}")

# Final status
tick_end = ev("return TickManager.current_tick")
crafted_end = ev("return CraftingManager.total_crafted")
raids = ev("return RaidManager.total_raids")
animals = ev("return AnimalManager.animals.size()")

pawns = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append({\"name\": p.pawn_name, \"job\": p.current_job_name, \"food\": p.get_need(\"Food\"), \"mood\": p.get_need(\"Mood\")})\nreturn r")

print(f"\n--- Final ---")
if isinstance(tick0, (int,float)) and isinstance(tick_end, (int,float)):
    print(f"  Total ticks: {int(tick_end) - int(tick0)} in 120s")
print(f"  Crafted: {crafted0} -> {crafted_end}")
print(f"  Raids: {raids}")
print(f"  Animals: {animals}")
if pawns:
    for p in pawns:
        print(f"  {p['name']}: job={p['job']} food={p.get('food',0):.2f} mood={p.get('mood',0):.2f}")

ev("TickManager.set_speed(1)")
print(f"\n=== DONE ===")
