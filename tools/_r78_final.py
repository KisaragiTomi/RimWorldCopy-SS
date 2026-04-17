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

print("=== R78 Final Craft Test ===\n")

# Spawn abundant materials
for mat, count in [("Cloth", 500), ("Stone", 500), ("Steel", 500), ("MealSimple", 100)]:
    ev(f"ThingManager.spawn_item_stacks(\"{mat}\", {count}, Vector2i(25, 25))\nreturn \"ok\"")

# Unassign all entries
ev("for entry in CraftingManager.craft_queue:\n\tentry[\"assigned\"] = false")

# Check
qs = ev("return CraftingManager.craft_queue.size()")
c0 = ev("return CraftingManager.total_crafted")
tick0 = ev("return TickManager.current_tick")

for recipe in ["SimpleClothes", "SteelSword", "StoneBlock", "Flak_Vest", "ComponentIndustrial"]:
    has = ev(f"return CraftingManager.has_ingredients(\"{recipe}\")")
    print(f"  {recipe}: has_ingredients={has}")

print(f"\nStart: tick={tick0} queue={qs} crafted={c0}")

# Run at 3x for 3 minutes
ev("TickManager.set_speed(3)")
print("\n--- Running at 3x (3 min) ---")

for i in range(12):
    time.sleep(15)
    tick = ev("return TickManager.current_tick")
    c = ev("return CraftingManager.total_crafted")
    qs = ev("return CraftingManager.craft_queue.size()")
    fps = ev("return Engine.get_frames_per_second()")
    season = ev("return SeasonManager.current_season")
    season_name = {0:"Sp",1:"Su",2:"Fa",3:"Wi"}.get(season, "?")
    
    jobs = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append(p.pawn_name + \":\" + p.current_job_name)\nreturn r")
    craft_active = sum(1 for j in (jobs or []) if j.endswith(":Craft"))
    
    print(f"  [{(i+1)*15:3d}s] t={tick} {season_name} fps={fps} crafted={c} q={qs} craft={craft_active}")

ev("TickManager.set_speed(1)")

# Final summary
tick_end = ev("return TickManager.current_tick")
c_end = ev("return CraftingManager.total_crafted")
q_end = ev("return CraftingManager.craft_queue.size()")
quality = ev("return CraftingManager._quality_counts")
things = ev("return ThingManager.things.size()")
plants = ev("return ThingManager.get_plants().size()")
raids = ev("return RaidManager.total_raids")

pawns = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append({\"name\": p.pawn_name, \"job\": p.current_job_name, \"food\": p.get_need(\"Food\"), \"mood\": p.get_need(\"Mood\")})\nreturn r")

print(f"\n=== Final Summary ===")
print(f"Ticks: {tick0} -> {tick_end}")
print(f"Crafted: {c0} -> {c_end} (+{int(c_end or 0)-int(c0 or 0)})")
print(f"Queue: {qs} -> {q_end}")
print(f"Quality: {quality}")
print(f"Things: {things}, Plants: {plants}, Raids: {raids}")
if pawns:
    print(f"Colonists ({len(pawns)}):")
    for p in pawns:
        print(f"  {p['name']}: {p['job']} food={p.get('food',0):.2f} mood={p.get('mood',0):.2f}")

# Save
ev("GameState.save_game()")
print("\nGame saved.")
print("\n=== DONE ===")
