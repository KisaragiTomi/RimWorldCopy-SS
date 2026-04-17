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

print("=== R79 Final Verification ===\n")

# Add CraftingSpot and TailoringBench
ev("var b = Building.new(\"CraftingSpot\")\nThingManager.spawn_thing(b, Vector2i(36, 32))\nreturn \"ok\"")
ev("var b = Building.new(\"TailoringBench\")\nThingManager.spawn_thing(b, Vector2i(37, 32))\nreturn \"ok\"")

# Spawn materials
for mat, count in [("Cloth", 300), ("Stone", 300), ("Steel", 500), ("MealSimple", 100), ("Leather", 200), ("Components", 100), ("Wood", 300)]:
    ev(f"ThingManager.spawn_item_stacks(\"{mat}\", {count}, Vector2i(25, 25))\nreturn \"ok\"")

# Add craft orders
ev("CraftingManager.add_to_queue(\"SimpleClothes\", 3)")
ev("CraftingManager.add_to_queue(\"SteelSword\", 2)")
ev("CraftingManager.add_to_queue(\"StoneBlock\", 3)")
ev("CraftingManager.add_to_queue(\"Flak_Vest\", 2)")
ev("CraftingManager.add_to_queue(\"ComponentIndustrial\", 3)")

# Verify everything
buildings = ev("var r = {}\nfor b in ThingManager._buildings:\n\tr[b.def_name] = r.get(b.def_name, 0) + 1\nreturn r")
print(f"Buildings ({len(buildings) if isinstance(buildings, dict) else '?'} types):")

# Research completion
comp = ev("return ResearchManager.get_completion_percentage()")
print(f"Research: {comp}% complete")

# Power
gen = ev("return ElectricityGrid.get_total_generation()")
cons = ev("return ElectricityGrid.get_total_consumption()")
print(f"Power: gen={gen}W cons={cons}W surplus={float(gen or 0)-float(cons or 0):.0f}W")

# Queue
qs = ev("return CraftingManager.craft_queue.size()")
print(f"Craft queue: {qs}")

# Run at 3x for 3 minutes
ev("TickManager.set_speed(3)")
print("\n--- Stability + Crafting test (3 min at 3x) ---")

tick0 = ev("return TickManager.current_tick")
c0 = ev("return CraftingManager.total_crafted")

for i in range(12):
    time.sleep(15)
    tick = ev("return TickManager.current_tick")
    c = ev("return CraftingManager.total_crafted")
    qs = ev("return CraftingManager.craft_queue.size()")
    fps = ev("return Engine.get_frames_per_second()")
    season = ev("return SeasonManager.current_season")
    gen = ev("return ElectricityGrid.get_total_generation()")
    things = ev("return ThingManager.things.size()")
    
    s_name = {0:"Sp",1:"Su",2:"Fa",3:"Wi"}.get(season, "?")
    
    jobs = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append(p.pawn_name + \":\" + p.current_job_name)\nreturn r")
    
    craft_active = sum(1 for j in (jobs or []) if j.endswith(":Craft"))
    
    print(f"  [{(i+1)*15:3d}s] t={tick} {s_name} fps={fps} c={c} q={qs} gen={gen}W things={things} craft_pawn={craft_active}")

ev("TickManager.set_speed(1)")

# Final summary
tick_end = ev("return TickManager.current_tick")
c_end = ev("return CraftingManager.total_crafted")
q_end = ev("return CraftingManager.craft_queue.size()")
quality = ev("return CraftingManager._quality_counts")
raids = ev("return RaidManager.total_raids")

pawns = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append({\"name\": p.pawn_name, \"job\": p.current_job_name, \"food\": p.get_need(\"Food\"), \"mood\": p.get_need(\"Mood\")})\nreturn r")

print(f"\n=== Summary ===")
print(f"Ticks: {tick0} -> {tick_end} (+{int(tick_end or 0)-int(tick0 or 0)})")
print(f"Crafted: {c0} -> {c_end} (+{int(c_end or 0)-int(c0 or 0)})")
print(f"Queue: {q_end}")
print(f"Quality: {quality}")
print(f"Raids: {raids}")
print(f"Buildings: {len(buildings) if isinstance(buildings, dict) else '?'} types")

if pawns:
    print(f"Colonists ({len(pawns)}):")
    for p in pawns:
        print(f"  {p['name']}: {p.get('job','')} food={p.get('food',0):.2f} mood={p.get('mood',0):.2f}")

ev("GameState.save_game()")
print("\nGame saved.")
print("\n=== DONE ===")
