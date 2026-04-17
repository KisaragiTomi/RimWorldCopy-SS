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

print("=== R77 Crafting Test ===\n")

# Check current crafting state
crafted = ev("return CraftingManager.total_crafted")
queue = ev("return CraftingManager.craft_queue.size()")
recipes = ev("var r = []\nfor key in CraftingManager.RECIPES:\n\tr.append(key)\nreturn r")
print(f"Total crafted: {crafted}")
print(f"Queue size: {queue}")
print(f"Recipes: {recipes}")

# Queue items
queue_items = ev("var r = []\nfor item in CraftingManager.craft_queue:\n\tr.append(item.recipe)\nreturn r")
print(f"Queue contents: {queue_items}")

# Spawn all necessary materials
ev("ThingManager.spawn_item_stacks([{\"def_name\":\"Steel\",\"count\":200},{\"def_name\":\"Cloth\",\"count\":100},{\"def_name\":\"Wood\",\"count\":200},{\"def_name\":\"Components\",\"count\":50},{\"def_name\":\"Leather\",\"count\":100},{\"def_name\":\"Healroot_Leaf\",\"count\":30},{\"def_name\":\"HerbalMedicine\",\"count\":20}])")

# Queue ALL recipes if not already
for r in recipes or []:
    ev(f"CraftingManager.add_to_queue(\"{r}\", 1)")

queue_after = ev("return CraftingManager.craft_queue.size()")
print(f"\nQueue after adding all: {queue_after}")

# Fast-forward to let crafting happen
print("\n--- 3x fast-forward for crafting (120s) ---")
ev("TickManager.set_speed(3)")
for i in range(8):
    time.sleep(15)
    tick = ev("return TickManager.current_tick")
    crafted = ev("return CraftingManager.total_crafted")
    queue = ev("return CraftingManager.craft_queue.size()")
    fps = ev("return Engine.get_frames_per_second()")
    season = ev("return SeasonManager.current_season")
    
    pawns = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append(p.current_job_name)\nreturn r")
    
    season_name = {0: "Spring", 1: "Summer", 2: "Fall", 3: "Winter"}.get(season, str(season))
    print(f"  [{(i+1)*15:3d}s] tick={tick} season={season_name} fps={fps} crafted={crafted} queue={queue} jobs={pawns}")

# Quality stats
quality = ev("return CraftingManager.quality_stats")
print(f"\nQuality stats: {quality}")

ev("TickManager.set_speed(1)")
print(f"\n=== DONE ===")
