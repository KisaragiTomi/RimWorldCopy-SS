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

print("=== Craft Debug ===\n")

# Check craft queue details
queue = ev("var r = []\nfor item in CraftingManager.craft_queue:\n\tr.append(item)\nreturn r")
print(f"Queue items: {json.dumps(queue, indent=2) if queue else queue}")

# Check if Crafter pawn has Crafting skill
crafter_skill = ev("var r = {}\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr[p.pawn_name] = p.get_skill_level(\"Crafting\")\nreturn r")
print(f"\nCrafting skills: {crafter_skill}")

# Check what materials are available
materials = ev("var r = {}\nfor t in ThingManager.things:\n\tvar n = t.def_name\n\tif t is Item:\n\t\tif not r.has(n): r[n] = 0\n\t\tr[n] += t.stack_count if t.has_method(\"get\") else 1\nreturn r")
print(f"\nMaterials: {materials}")

# Check if there's a workbench
workbench = ev("var r = []\nfor t in ThingManager.things:\n\tvar n = t.def_name\n\tif n in [\"CraftingSpot\",\"Workbench\",\"ElectricSmithy\",\"FueledSmithy\",\"CookingStove\",\"TailoringBench\",\"DrugLab\"]:\n\t\tr.append(n)\nreturn r")
print(f"\nWorkbenches: {workbench}")

# Check the craft job giver
craft_giver = ev("var r = {}\nif CraftingManager:\n\tr[\"queue_size\"] = CraftingManager.craft_queue.size()\n\tr[\"total_crafted\"] = CraftingManager.total_crafted\n\tr[\"has_recipes\"] = CraftingManager.RECIPES.size()\nreturn r")
print(f"\nCraftingManager state: {craft_giver}")

# Force fast-forward in Winter (no farming) to see if crafting happens
ev("TickManager.set_speed(3)")
print("\n--- Fast-forward to Winter for crafting test ---")
for i in range(6):
    time.sleep(15)
    tick = ev("return TickManager.current_tick")
    season = ev("return SeasonManager.current_season")
    crafted = ev("return CraftingManager.total_crafted")
    queue_sz = ev("return CraftingManager.craft_queue.size()")
    
    pawns = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append(p.current_job_name)\nreturn r")
    
    season_name = {0: "Spring", 1: "Summer", 2: "Fall", 3: "Winter"}.get(season, str(season))
    print(f"  [{(i+1)*15}s] tick={tick} season={season_name} crafted={crafted} queue={queue_sz} jobs={pawns}")
    
    if season == 3:  # Winter
        break

ev("TickManager.set_speed(1)")
print(f"\n=== DONE ===")
