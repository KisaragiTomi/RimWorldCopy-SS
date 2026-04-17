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

print("=== R77 Full Season Cycle Test ===\n")

# Setup
ev("for p in ResearchManager.projects:\n\tResearchManager._complete_project(p)")
ev("ThingManager.spawn_item_stacks([{\"def_name\":\"MealSimple\",\"count\":50},{\"def_name\":\"Steel\",\"count\":100},{\"def_name\":\"Cloth\",\"count\":50},{\"def_name\":\"Components\",\"count\":20},{\"def_name\":\"Wood\",\"count\":100},{\"def_name\":\"Leather\",\"count\":50}])")

# Queue crafting
for r in ["SimpleClothes", "Flak_Vest", "SteelSword", "StoneBlock", "ComponentIndustrial"]:
    ev(f"CraftingManager.add_to_queue(\"{r}\", 2)")

tick0 = ev("return TickManager.current_tick")
season0 = ev("return SeasonManager.current_season")
crafted0 = ev("return CraftingManager.total_crafted")
season_name = {0: "Spring", 1: "Summer", 2: "Fall", 3: "Winter"}.get(season0, str(season0))
print(f"Start: tick={tick0} season={season_name} crafted={crafted0}")

# Run at 3x for extended period, tracking each season change
ev("TickManager.set_speed(3)")
last_season = season0
transitions = []

for i in range(16):
    time.sleep(15)
    tick = ev("return TickManager.current_tick")
    season = ev("return SeasonManager.current_season")
    fps = ev("return Engine.get_frames_per_second()")
    things = ev("return ThingManager.things.size()")
    plants = ev("return ThingManager.get_plants().size()")
    crafted = ev("return CraftingManager.total_crafted")
    raids = ev("return RaidManager.total_raids")
    
    pawns = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append(p.current_job_name)\nreturn r")
    
    season_name = {0: "Spring", 1: "Summer", 2: "Fall", 3: "Winter"}.get(season, str(season))
    
    if season != last_season:
        transitions.append(f"{last_season}->{season}")
        last_season = season
    
    print(f"  [{(i+1)*15:3d}s] tick={tick} season={season_name} fps={fps} things={things} plants={plants} crafted={crafted} raids={raids} jobs={pawns}")

# Final check
tick_end = ev("return TickManager.current_tick")
crafted_end = ev("return CraftingManager.total_crafted")
queue_end = ev("return CraftingManager.craft_queue.size()")
things_end = ev("return ThingManager.things.size()")
animals = ev("return AnimalManager.animals.size()")

pawns = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append({\"name\": p.pawn_name, \"job\": p.current_job_name, \"food\": p.get_need(\"Food\"), \"mood\": p.get_need(\"Mood\")})\nreturn r")

print(f"\n--- Summary ---")
if isinstance(tick0, (int,float)) and isinstance(tick_end, (int,float)):
    total_ticks = int(tick_end) - int(tick0)
    print(f"  Ticks: {tick0} -> {tick_end} (gained {total_ticks}, {total_ticks/240:.0f} tps)")
print(f"  Transitions: {transitions}")
print(f"  Crafted: {crafted0} -> {crafted_end}")
print(f"  Queue remaining: {queue_end}")
print(f"  Things: {things_end}")
print(f"  Animals: {animals}")
if pawns:
    print(f"  Colonists ({len(pawns)}):")
    for p in pawns:
        print(f"    {p['name']}: job={p['job']} food={p.get('food',0):.2f} mood={p.get('mood',0):.2f}")

ev("TickManager.set_speed(1)")
print(f"\n=== DONE ===")
