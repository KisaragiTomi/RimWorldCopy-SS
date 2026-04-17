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

print("=== R78 Queue Check ===\n")

qs = ev("return CraftingManager.craft_queue.size()")
print(f"Queue size: {qs}")

for i in range(int(qs or 0)):
    item = ev(f"return CraftingManager.craft_queue[{i}]")
    recipe = item.get("recipe", "") if isinstance(item, dict) else ""
    assigned = item.get("assigned", False) if isinstance(item, dict) else False
    has = ev(f"return CraftingManager.has_ingredients(\"{recipe}\")")
    missing = ev(f"return CraftingManager.get_missing_ingredients(\"{recipe}\")")
    print(f"  [{i}] recipe={recipe} assigned={assigned} has_ing={has} missing={missing}")

# Check Crafter's position and craft skill
crafter = ev("var c = null\nfor p in PawnManager.pawns:\n\tif p.pawn_name == \"Crafter\":\n\t\tc = p\n\t\tbreak\nif c:\n\treturn {\"name\": c.pawn_name, \"job\": c.current_job_name, \"pos\": [c.grid_pos.x, c.grid_pos.y], \"craft_skill\": c.get_skill_level(\"Crafting\"), \"capable\": c.is_capable_of(\"Crafting\")}\nreturn null")
print(f"\nCrafter: {crafter}")

# Check all pawns craft capability
for i in range(6):
    name = ev(f"return PawnManager.pawns[{i}].pawn_name")
    cap = ev(f"return PawnManager.pawns[{i}].is_capable_of(\"Crafting\")")
    skill = ev(f"return PawnManager.pawns[{i}].get_skill_level(\"Crafting\")")
    print(f"  {name}: capable={cap} skill={skill}")

# Reset stuck assigned entries and push again
ev("for entry in CraftingManager.craft_queue:\n\tentry[\"assigned\"] = false")
print("\nReset all entries to unassigned")

# Add more orders
ev("CraftingManager.add_to_queue(\"SimpleClothes\", 2)")
ev("CraftingManager.add_to_queue(\"ComponentIndustrial\", 3)")
qs2 = ev("return CraftingManager.craft_queue.size()")
print(f"Queue after adding: {qs2}")

# Run at 3x for 90s
ev("TickManager.set_speed(3)")
print("\n--- Running at 3x (90s) ---")

for i in range(6):
    time.sleep(15)
    c = ev("return CraftingManager.total_crafted")
    qs = ev("return CraftingManager.craft_queue.size()")
    fps = ev("return Engine.get_frames_per_second()")
    jobs = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append(p.pawn_name + \":\" + p.current_job_name)\nreturn r")
    print(f"  [{(i+1)*15:3d}s] fps={fps} crafted={c} q={qs} jobs={jobs}")

ev("TickManager.set_speed(1)")

c_final = ev("return CraftingManager.total_crafted")
q_final = ev("return CraftingManager.craft_queue.size()")
quality = ev("return CraftingManager._quality_counts")
print(f"\nFinal: crafted={c_final} queue={q_final} quality={quality}")
print("\n=== DONE ===")
