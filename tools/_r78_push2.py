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

print("=== R78 Push2 ===\n")

# Check spawn_item_stacks signature
sig = ev("var methods = []\nfor m in ThingManager.get_method_list():\n\tif \"spawn\" in m.name.to_lower():\n\t\tmethods.append(m.name)\nreturn methods")
print(f"Spawn methods: {sig}")

# Try spawning individual items
for mat, count in [("Cloth", 200), ("Stone", 200), ("Steel", 200)]:
    r = ev(f"ThingManager.spawn_item_stacks([{{\"def_name\":\"{mat}\",\"count\":{count}}}])")
    print(f"Spawn {mat}x{count}: {r}")

time.sleep(1)

# Check material counts
mats = ev("var r = {}\nfor t in ThingManager.things:\n\tif t is Item:\n\t\tvar d = t.def_name\n\t\tvar c = t.stack_count if t.get(\"stack_count\") else 1\n\t\tif d in r:\n\t\t\tr[d] += c\n\t\telse:\n\t\t\tr[d] = c\nreturn r")
print(f"\nMaterials after spawn: {mats}")

# Check has_ingredients for each recipe type
for recipe in ["SimpleClothes", "SteelSword", "StoneBlock", "Flak_Vest", "ComponentIndustrial"]:
    has = ev(f"return CraftingManager.has_ingredients(\"{recipe}\")")
    missing = ev(f"return CraftingManager.get_missing_ingredients(\"{recipe}\")")
    print(f"  {recipe}: has_ingredients={has}, missing={missing}")

# Check can_craft for Crafter
for recipe in ["SimpleClothes", "SteelSword", "StoneBlock", "Flak_Vest", "ComponentIndustrial"]:
    can = ev(f"return CraftingManager.can_craft(\"{recipe}\", PawnManager.pawns[5])")
    print(f"  Crafter can_craft({recipe}): {can}")

# Unassign any stuck entries
ev("for entry in CraftingManager.craft_queue:\n\tentry[\"assigned\"] = false")

# Run 2 minutes at 3x
ev("TickManager.set_speed(3)")
print("\n--- Running at 3x (2 min) ---")

for i in range(8):
    time.sleep(15)
    tick = ev("return TickManager.current_tick")
    c = ev("return CraftingManager.total_crafted")
    qs = ev("return CraftingManager.craft_queue.size()")
    fps = ev("return Engine.get_frames_per_second()")
    
    jobs = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append(p.pawn_name + \":\" + p.current_job_name)\nreturn r")
    
    print(f"  [{(i+1)*15:3d}s] tick={tick} fps={fps} crafted={c} q={qs} jobs={jobs}")

ev("TickManager.set_speed(1)")

# Final
crafted_end = ev("return CraftingManager.total_crafted")
queue_end = ev("return CraftingManager.craft_queue.size()")
print(f"\nFinal: crafted={crafted_end} queue={queue_end}")
print("\n=== DONE ===")
