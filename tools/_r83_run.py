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

print("=== R83 Fall→Winter→Spring ===\n")

# Setup
ev("for p in ResearchManager.get_all_projects():\n\tResearchManager._complete_project(p.get(\"defName\",\"\"))")
ev("ThingManager.spawn_item_stacks(\"MealSimple\", 80, Vector2i(25, 25))\nreturn \"ok\"")
ev("ThingManager.spawn_item_stacks(\"Steel\", 200, Vector2i(25, 25))\nreturn \"ok\"")
ev("ThingManager.spawn_item_stacks(\"Cloth\", 150, Vector2i(25, 25))\nreturn \"ok\"")
ev("CraftingManager.add_to_queue(\"SimpleClothes\", 2)")
ev("CraftingManager.add_to_queue(\"SteelSword\", 2)")
ev("CraftingManager.add_to_queue(\"Flak_Vest\", 2)")
ev("for entry in CraftingManager.craft_queue:\n\tentry[\"assigned\"] = false")

tick0 = ev("return TickManager.current_tick")
season0 = ev("return SeasonManager.current_season")
c0 = ev("return CraftingManager.total_crafted")
s0 = {0:"Sp",1:"Su",2:"Fa",3:"Wi"}.get(season0, "?")
print(f"Start: tick={tick0} {s0} crafted={c0}")

# 7 min at 3x
ev("TickManager.set_speed(3)")
transitions = []
last_season = season0
job_data = {}

for i in range(28):
    time.sleep(15)
    tick = ev("return TickManager.current_tick")
    season = ev("return SeasonManager.current_season")
    fps = ev("return Engine.get_frames_per_second()")
    c = ev("return CraftingManager.total_crafted")
    things = ev("return ThingManager.things.size()")
    
    marker = ""
    if season != last_season:
        s_old = {0:"Sp",1:"Su",2:"Fa",3:"Wi"}.get(last_season, "?")
        s_new = {0:"Sp",1:"Su",2:"Fa",3:"Wi"}.get(season, "?")
        transitions.append(f"{s_old}->{s_new}@t{tick}")
        last_season = season
        marker = f" *** {s_old}->{s_new} ***"
    
    s_name = {0:"Sp",1:"Su",2:"Fa",3:"Wi"}.get(season, "?")
    
    jobs = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append(p.current_job_name)\nreturn r")
    
    for j in (jobs or []):
        j = j or "Idle"
        job_data[j] = job_data.get(j, 0) + 1
    
    # Periodic cleanup
    if (i + 1) % 7 == 0:
        for item_type in ["Wood", "MealSimple", "Leather", "Meat", "RawFood", "NutrientPaste"]:
            for _ in range(30):
                cnt = ev(f"var c = 0\nfor t in ThingManager.get_items():\n\tif t.def_name == \"{item_type}\":\n\t\tc += 1\nreturn c")
                if not isinstance(cnt, (int, float)) or int(cnt) <= 5:
                    break
                ev(f"for t in ThingManager.get_items():\n\tif t.def_name == \"{item_type}\":\n\t\tThingManager.remove_thing(t)\n\t\treturn 1\nreturn 0")
        things = ev("return ThingManager.things.size()")
        marker += " [CLN]"
    
    top = {}
    for j in (jobs or []):
        j = j or "Idle"
        top[j] = top.get(j, 0) + 1
    top_str = " ".join(f"{j}={c}" for j,c in sorted(top.items(), key=lambda x: -x[1])[:3])
    
    print(f"  [{(i+1)*15:3d}s] t={tick} {s_name} fps={fps} c={c} th={things} {top_str}{marker}")

ev("TickManager.set_speed(1)")

# Final
tick_end = ev("return TickManager.current_tick")
c_end = ev("return CraftingManager.total_crafted")
quality = ev("return CraftingManager._quality_counts")
raids = ev("return RaidManager.total_raids")

pawns = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append({\"name\": p.pawn_name, \"job\": p.current_job_name, \"food\": p.get_need(\"Food\"), \"mood\": p.get_need(\"Mood\")})\nreturn r")

print(f"\n=== Summary ===")
print(f"Ticks: {tick0} -> {tick_end} (+{int(tick_end or 0)-int(tick0 or 0)})")
print(f"Transitions: {transitions}")
print(f"Crafted: {c0} -> {c_end} (+{int(c_end or 0)-int(c0 or 0)})")
print(f"Quality: {quality}")
print(f"Raids: {raids}")

total = sum(job_data.values())
prod = sum(c for j, c in job_data.items() if j in ["Sow","Harvest","Cook","Craft","Hunt","Haul","Mine","Chop","Research","Construct","DeliverResources","Clean","Repair","TendPatient"])
print(f"Productivity: {prod}/{total} ({prod/total*100:.1f}%)")

if pawns:
    print(f"Colonists ({len(pawns)}):")
    for p in pawns:
        print(f"  {p['name']}: {p.get('job','')} food={p.get('food',0):.2f} mood={p.get('mood',0):.2f}")

ev("GameState.save_game()")
print("\nSaved.")
print("\n=== DONE ===")
