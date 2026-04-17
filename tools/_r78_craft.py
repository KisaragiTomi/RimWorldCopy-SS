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

print("=== R78 Craft Debug ===\n")

# Check craft queue
queue = ev("var r = []\nfor item in CraftingManager.craft_queue:\n\tr.append({\"def\": item.def_name, \"count\": item.count, \"progress\": item.get(\"progress\", 0)})\nreturn r")
print(f"Queue: {queue}")

# Check workbenches on map
benches = ev("var r = []\nfor t in ThingManager.things:\n\tif t.def_name in [\"CraftingSpot\", \"Smithy\", \"TailoringBench\", \"CookingStove\", \"ElectricSmelter\", \"FueledSmelter\"]:\n\t\tr.append({\"def\": t.def_name, \"pos\": [t.cell.x, t.cell.y] if t.cell else null})\nreturn r")
print(f"Workbenches: {benches}")

# Check materials
mats = ev("var r = {}\nfor t in ThingManager.things:\n\tif t.def_name in [\"Steel\", \"Cloth\", \"Wood\", \"Components\", \"Leather\", \"Stone\", \"Gold\", \"Silver\", \"Plasteel\", \"Uranium\"]:\n\t\tif t.def_name in r:\n\t\t\tr[t.def_name] += t.stack_count if t.get(\"stack_count\") else 1\n\t\telse:\n\t\t\tr[t.def_name] = t.stack_count if t.get(\"stack_count\") else 1\nreturn r")
print(f"Materials: {mats}")

# Check JobGiverCraft conditions directly
can_craft = ev("return JobGiverCraft.can_craft(PawnManager.pawns[0])")
print(f"can_craft(pawn0): {can_craft}")

has_ing = ev("return CraftingManager.has_ingredients(CraftingManager.craft_queue[0]) if CraftingManager.craft_queue.size() > 0 else null")
print(f"has_ingredients(q0): {has_ing}")

# Check pawn work priorities
for i in range(6):
    name = ev(f"return PawnManager.pawns[{i}].pawn_name")
    craft_pri = ev(f"return PawnManager.pawns[{i}].work_priorities.get(\"Crafting\", -1)")
    job = ev(f"return PawnManager.pawns[{i}].current_job_name")
    print(f"  {name}: craft_priority={craft_pri} current_job={job}")

# Try to manually trigger craft
print("\n--- Manual craft test ---")
ev("TickManager.set_speed(3)")
time.sleep(30)

crafted = ev("return CraftingManager.total_crafted")
jobs = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append(p.pawn_name + \":\" + p.current_job_name)\nreturn r")
print(f"After 30s: crafted={crafted} jobs={jobs}")

ev("TickManager.set_speed(1)")
print("\n=== DONE ===")
