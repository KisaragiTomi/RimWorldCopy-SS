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

print("=== R75 Extended Stability & Crafting Test ===\n")

# Spawn crafting materials including Healroot_Leaf
ev("ThingManager.spawn_item_stacks([{\"def_name\":\"Steel\",\"count\":200},{\"def_name\":\"Cloth\",\"count\":100},{\"def_name\":\"Wood\",\"count\":200},{\"def_name\":\"Components\",\"count\":50},{\"def_name\":\"Leather\",\"count\":100},{\"def_name\":\"Healroot_Leaf\",\"count\":30},{\"def_name\":\"HerbalMedicine\",\"count\":20},{\"def_name\":\"MealSimple\",\"count\":30}])")
time.sleep(0.5)

# Unlock research
ev("for p in ResearchManager.projects:\n\tResearchManager._complete_project(p)")

# Check initial state
tick0 = ev("return TickManager.current_tick")
print(f"Start tick: {tick0}")

# Long 3x fast-forward (2 minutes)
print("--- Long 3x fast-forward (120s) ---")
ev("TickManager.set_speed(3)")

for i in range(4):
    time.sleep(30)
    tick = ev("return TickManager.current_tick")
    fps = ev("return Engine.get_frames_per_second()")
    things = ev("return ThingManager.things.size()")
    crafted = ev("return CraftingManager.total_crafted")
    queue = ev("return CraftingManager.craft_queue.size()")
    season_data = ev("return SeasonManager.current_season")
    
    pawns = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append(p.current_job_name)\nreturn r")
    
    print(f"  [{(i+1)*30}s] tick={tick} fps={fps} things={things} crafted={crafted} queue={queue} season={season_data} jobs={pawns}")

# Final status
tick_end = ev("return TickManager.current_tick")
fps_final = ev("return Engine.get_frames_per_second()")
things_final = ev("return ThingManager.things.size()")
crafted_final = ev("return CraftingManager.total_crafted")
raids = ev("return RaidManager.total_raids")
animals = ev("return AnimalManager.animals.size()")

print(f"\n--- Final Status ---")
print(f"  Tick: {tick0} -> {tick_end}")
if isinstance(tick0, (int,float)) and isinstance(tick_end, (int,float)):
    total_gained = int(tick_end) - int(tick0)
    print(f"  Total gained: {total_gained} ticks in 120s = {total_gained/120:.0f} tps")
print(f"  FPS: {fps_final}")
print(f"  Things: {things_final}")
print(f"  Crafted: {crafted_final}")
print(f"  Raids: {raids}")
print(f"  Animals: {animals}")

# Check all colonists
pawns = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append({\"name\": p.pawn_name, \"job\": p.current_job_name, \"food\": p.get_need(\"Food\"), \"mood\": p.get_need(\"Mood\"), \"rest\": p.get_need(\"Rest\")})\nreturn r")
if pawns:
    print(f"\n  Colonists ({len(pawns)}):")
    for p in pawns:
        print(f"    {p['name']}: job={p['job']} food={p.get('food',0):.2f} mood={p.get('mood',0):.2f} rest={p.get('rest',0):.2f}")

ev("TickManager.set_speed(1)")
print(f"\n=== DONE ===")
