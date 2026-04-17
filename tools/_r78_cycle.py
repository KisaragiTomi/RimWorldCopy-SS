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

print("=== R78 Full Annual Cycle ===\n")

# Setup
ev("for p in ResearchManager.projects:\n\tResearchManager._complete_project(p)")
ev("ThingManager.spawn_item_stacks([{\"def_name\":\"MealSimple\",\"count\":80},{\"def_name\":\"Steel\",\"count\":200},{\"def_name\":\"Cloth\",\"count\":100},{\"def_name\":\"Wood\",\"count\":200},{\"def_name\":\"Components\",\"count\":50},{\"def_name\":\"Leather\",\"count\":100}])")

tick0 = ev("return TickManager.current_tick")
season0 = ev("return SeasonManager.current_season")
crafted0 = ev("return CraftingManager.total_crafted")
print(f"Start: tick={tick0} season={season0} crafted={crafted0}")

# Long 3x run (5 minutes = 300s)
ev("TickManager.set_speed(3)")
last_season = season0
transitions = 0

for i in range(20):
    time.sleep(15)
    tick = ev("return TickManager.current_tick")
    season = ev("return SeasonManager.current_season")
    fps = ev("return Engine.get_frames_per_second()")
    crafted = ev("return CraftingManager.total_crafted")
    things = ev("return ThingManager.things.size()")
    raids = ev("return RaidManager.total_raids")
    
    pawns = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append(p.current_job_name)\nreturn r")
    
    if season != last_season:
        transitions += 1
        s_old = {0:"Sp",1:"Su",2:"Fa",3:"Wi"}.get(last_season, "?")
        s_new = {0:"Sp",1:"Su",2:"Fa",3:"Wi"}.get(season, "?")
        last_season = season
        marker = f" *** {s_old}->{s_new} ***"
    else:
        marker = ""
    
    season_name = {0:"Spring",1:"Summer",2:"Fall",3:"Winter"}.get(season, str(season))
    print(f"  [{(i+1)*15:3d}s] tick={tick} {season_name} fps={fps} things={things} crafted={crafted} raids={raids} jobs={pawns}{marker}")

# Final
tick_end = ev("return TickManager.current_tick")
crafted_end = ev("return CraftingManager.total_crafted")
queue_end = ev("return CraftingManager.craft_queue.size()")
things_end = ev("return ThingManager.things.size()")
plants_end = ev("return ThingManager.get_plants().size()")
animals = ev("return AnimalManager.animals.size()")

pawns = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append({\"name\": p.pawn_name, \"job\": p.current_job_name, \"food\": p.get_need(\"Food\"), \"mood\": p.get_need(\"Mood\")})\nreturn r")

print(f"\n=== Summary ===")
if isinstance(tick0, (int,float)) and isinstance(tick_end, (int,float)):
    total = int(tick_end) - int(tick0)
    print(f"Ticks: {tick0} -> {tick_end} (gained {total}, avg {total/300:.0f} tps)")
print(f"Transitions: {transitions}")
print(f"Crafted: {crafted0} -> {crafted_end} (+{int(crafted_end or 0)-int(crafted0 or 0)})")
print(f"Queue: {queue_end}")
print(f"Things: {things_end}, Plants: {plants_end}")
print(f"Raids: {raids}, Animals: {animals}")
if pawns:
    print(f"Colonists ({len(pawns)}):")
    for p in pawns:
        print(f"  {p['name']}: job={p['job']} food={p.get('food',0):.2f} mood={p.get('mood',0):.2f}")

ev("TickManager.set_speed(1)")
print(f"\n=== DONE ===")
