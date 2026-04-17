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

print("=== R78 Push ===\n")

# Setup research
ev("for p in ResearchManager.projects:\n\tResearchManager._complete_project(p)")

# Spawn materials
ev("ThingManager.spawn_item_stacks([{\"def_name\":\"Cloth\",\"count\":200},{\"def_name\":\"Stone\",\"count\":200},{\"def_name\":\"Steel\",\"count\":300},{\"def_name\":\"MealSimple\",\"count\":80},{\"def_name\":\"Leather\",\"count\":100},{\"def_name\":\"Components\",\"count\":50},{\"def_name\":\"Wood\",\"count\":200}])")

# Add crafting orders
ev("CraftingManager.add_to_queue(\"SimpleClothes\", 3)")
ev("CraftingManager.add_to_queue(\"SteelSword\", 2)")
ev("CraftingManager.add_to_queue(\"StoneBlock\", 3)")
ev("CraftingManager.add_to_queue(\"Flak_Vest\", 2)")
ev("CraftingManager.add_to_queue(\"ComponentIndustrial\", 2)")

queue = ev("return CraftingManager.craft_queue.size()")
crafted = ev("return CraftingManager.total_crafted")
tick0 = ev("return TickManager.current_tick")
print(f"Setup: tick={tick0} queue={queue} crafted={crafted}")

# Check materials
mats = ev("var r = {}\nfor t in ThingManager.things:\n\tif t is Item:\n\t\tvar d = t.def_name\n\t\tvar c = t.stack_count if t.get(\"stack_count\") else 1\n\t\tif d in r:\n\t\t\tr[d] += c\n\t\telse:\n\t\t\tr[d] = c\nreturn r")
print(f"Materials: {mats}")

# Long run at 3x
ev("TickManager.set_speed(3)")
print("\n--- Running at 3x (3 minutes) ---")

for i in range(12):
    time.sleep(15)
    tick = ev("return TickManager.current_tick")
    c = ev("return CraftingManager.total_crafted")
    qs = ev("return CraftingManager.craft_queue.size()")
    fps = ev("return Engine.get_frames_per_second()")
    season = ev("return SeasonManager.current_season")
    season_name = {0:"Spring",1:"Summer",2:"Fall",3:"Winter"}.get(season, str(season))
    
    jobs = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append(p.pawn_name + \":\" + p.current_job_name)\nreturn r")
    
    has_craft = any("Craft" in j for j in (jobs or []))
    craft_marker = " [CRAFTING]" if has_craft else ""
    
    print(f"  [{(i+1)*15:3d}s] tick={tick} {season_name} fps={fps} crafted={c} q={qs}{craft_marker}")
    if jobs:
        print(f"         jobs={jobs}")

ev("TickManager.set_speed(1)")

# Final stats
tick_end = ev("return TickManager.current_tick")
crafted_end = ev("return CraftingManager.total_crafted")
queue_end = ev("return CraftingManager.craft_queue.size()")
things = ev("return ThingManager.things.size()")
plants = ev("return ThingManager.get_plants().size()")

pawns = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append({\"name\": p.pawn_name, \"job\": p.current_job_name, \"food\": p.get_need(\"Food\"), \"mood\": p.get_need(\"Mood\"), \"craft_skill\": p.get_skill_level(\"Crafting\")})\nreturn r")

print(f"\n=== Summary ===")
print(f"Ticks: {tick0} -> {tick_end}")
print(f"Crafted: {crafted} -> {crafted_end} (+{int(crafted_end or 0)-int(crafted or 0)})")
print(f"Queue: {queue} -> {queue_end}")
print(f"Things: {things}, Plants: {plants}")
if pawns:
    print(f"Colonists ({len(pawns)}):")
    for p in pawns:
        print(f"  {p['name']}: job={p['job']} craft={p.get('craft_skill',0)} food={p.get('food',0):.2f} mood={p.get('mood',0):.2f}")

print("\n=== DONE ===")
