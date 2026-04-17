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

print("=== R78 Spawn Materials ===\n")

# Spawn materials with correct API: spawn_item_stacks(def_name, count, pos)
materials = [
    ("Cloth", 200),
    ("Stone", 200),
    ("Steel", 300),
]

for mat, count in materials:
    r = ev(f"ThingManager.spawn_item_stacks(\"{mat}\", {count}, Vector2i(25, 25))\nreturn \"ok\"")
    print(f"Spawn {mat}x{count}: {r}")

time.sleep(1)

# Verify
mats = ev("var r = {}\nfor t in ThingManager.things:\n\tif t is Item:\n\t\tvar d = t.def_name\n\t\tvar c = t.stack_count if t.get(\"stack_count\") else 1\n\t\tif d in r:\n\t\t\tr[d] += c\n\t\telse:\n\t\t\tr[d] = c\nreturn r")
print(f"\nMaterials: {mats}")

# Check has_ingredients again
for recipe in ["SimpleClothes", "SteelSword", "StoneBlock", "Flak_Vest", "ComponentIndustrial"]:
    has = ev(f"return CraftingManager.has_ingredients(\"{recipe}\")")
    print(f"  {recipe}: has_ingredients={has}")

# Unassign stuck entries
ev("for entry in CraftingManager.craft_queue:\n\tentry[\"assigned\"] = false")

# Run at 3x for 2 min
ev("TickManager.set_speed(3)")
print("\n--- Running at 3x (2 min) ---")

for i in range(8):
    time.sleep(15)
    tick = ev("return TickManager.current_tick")
    c = ev("return CraftingManager.total_crafted")
    qs = ev("return CraftingManager.craft_queue.size()")
    fps = ev("return Engine.get_frames_per_second()")
    
    jobs = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append(p.pawn_name + \":\" + p.current_job_name)\nreturn r")
    
    craft_jobs = [j for j in (jobs or []) if j.endswith(":Craft")]
    
    print(f"  [{(i+1)*15:3d}s] tick={tick} fps={fps} crafted={c} q={qs} craft_active={len(craft_jobs)}")
    if craft_jobs:
        print(f"         crafters: {craft_jobs}")

ev("TickManager.set_speed(1)")

crafted_end = ev("return CraftingManager.total_crafted")
queue_end = ev("return CraftingManager.craft_queue.size()")
quality = ev("return CraftingManager._quality_counts")
print(f"\nFinal: crafted={crafted_end} queue={queue_end} quality={quality}")
print("\n=== DONE ===")
