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

print("=== R81 Spring→Summer Push ===\n")

# Setup
ev("for p in ResearchManager.get_all_projects():\n\tResearchManager._complete_project(p.get(\"defName\",\"\"))")
for mat, count in [("MealSimple", 80), ("Steel", 200), ("Cloth", 150), ("Wood", 200)]:
    ev(f"ThingManager.spawn_item_stacks(\"{mat}\", {count}, Vector2i(25, 25))\nreturn \"ok\"")

# Add craft orders
ev("CraftingManager.add_to_queue(\"SimpleClothes\", 2)")
ev("CraftingManager.add_to_queue(\"SteelSword\", 2)")
ev("CraftingManager.add_to_queue(\"ComponentIndustrial\", 3)")
ev("for entry in CraftingManager.craft_queue:\n\tentry[\"assigned\"] = false")

tick0 = ev("return TickManager.current_tick")
season0 = ev("return SeasonManager.current_season")
c0 = ev("return CraftingManager.total_crafted")
print(f"Start: tick={tick0} season={season0} crafted={c0}")

# 5 min at 3x
ev("TickManager.set_speed(3)")
transitions = []
last_season = season0
fps_samples = []
job_counts = {}

for i in range(20):
    time.sleep(15)
    tick = ev("return TickManager.current_tick")
    season = ev("return SeasonManager.current_season")
    fps = ev("return Engine.get_frames_per_second()")
    c = ev("return CraftingManager.total_crafted")
    things = ev("return ThingManager.things.size()")
    plants = ev("return ThingManager.get_plants().size()")
    raids = ev("return RaidManager.total_raids")
    
    fps_samples.append(float(fps or 0))
    
    if season != last_season:
        s_old = {0:"Sp",1:"Su",2:"Fa",3:"Wi"}.get(last_season, "?")
        s_new = {0:"Sp",1:"Su",2:"Fa",3:"Wi"}.get(season, "?")
        transitions.append(f"{s_old}->{s_new}@t{tick}")
        last_season = season
    
    s_name = {0:"Sp",1:"Su",2:"Fa",3:"Wi"}.get(season, "?")
    
    jobs = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append(p.current_job_name)\nreturn r")
    
    for j in (jobs or []):
        j = j or "Idle"
        job_counts[j] = job_counts.get(j, 0) + 1
    
    top = {}
    for j in (jobs or []):
        j = j or "Idle"
        top[j] = top.get(j, 0) + 1
    top_str = " ".join(f"{j}={c}" for j,c in sorted(top.items(), key=lambda x: -x[1])[:3])
    
    print(f"  [{(i+1)*15:3d}s] t={tick} {s_name} fps={fps} c={c} things={things} plants={plants} {top_str}")

ev("TickManager.set_speed(1)")

# Summary
tick_end = ev("return TickManager.current_tick")
c_end = ev("return CraftingManager.total_crafted")
q_end = ev("return CraftingManager.craft_queue.size()")
quality = ev("return CraftingManager._quality_counts")

pawns = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append({\"name\": p.pawn_name, \"job\": p.current_job_name, \"food\": p.get_need(\"Food\"), \"mood\": p.get_need(\"Mood\")})\nreturn r")

print(f"\n=== Summary ===")
print(f"Ticks: {tick0} -> {tick_end} (+{int(tick_end or 0)-int(tick0 or 0)})")
print(f"Transitions: {transitions}")
print(f"Crafted: {c0} -> {c_end} (+{int(c_end or 0)-int(c0 or 0)})")
print(f"Quality: {quality}")
print(f"FPS: min={min(fps_samples):.0f} avg={sum(fps_samples)/len(fps_samples):.0f} max={max(fps_samples):.0f}")

# Job distribution
total_jobs = sum(job_counts.values())
print(f"\nJob Distribution ({total_jobs} samples):")
productive = 0
for j, c in sorted(job_counts.items(), key=lambda x: -x[1]):
    pct = c / total_jobs * 100
    if j in ["Sow", "Harvest", "Cook", "Craft", "Hunt", "Haul", "Mine", "Chop", 
             "Research", "Construct", "DeliverResources", "Clean", "Repair"]:
        productive += c
    print(f"  {j:20s}: {c:4d} ({pct:5.1f}%)")
print(f"\nProductive: {productive}/{total_jobs} ({productive/total_jobs*100:.1f}%)")

if pawns:
    print(f"\nColonists ({len(pawns)}):")
    for p in pawns:
        print(f"  {p['name']}: {p.get('job','')} food={p.get('food',0):.2f} mood={p.get('mood',0):.2f}")

ev("GameState.save_game()")
print("\nGame saved.")
print("\n=== DONE ===")
