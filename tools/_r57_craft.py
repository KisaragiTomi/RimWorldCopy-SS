import socket, json, time

PORT = 9090

def send_cmd(cmd, timeout=10):
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(timeout)
        s.connect(("127.0.0.1", PORT))
        s.sendall(json.dumps(cmd).encode() + b"\n")
        buf = b""
        while True:
            chunk = s.recv(4096)
            if not chunk:
                break
            buf += chunk
            try:
                return json.loads(buf.decode())
            except:
                continue
        return json.loads(buf.decode()) if buf else None
    except Exception as e:
        return {"error": str(e)}
    finally:
        s.close()

def ev(code):
    r = send_cmd({"command": "eval", "params": {"code": code}})
    if isinstance(r, dict) and "result" in r:
        return r["result"]
    return r

print("=== R57 CRAFTING INVESTIGATION ===\n")

# Check current state
tc = ev("return CraftingManager.total_crafted")
qs = ev("return CraftingManager.craft_queue.size()")
print(f"Before: total_crafted={tc}, queue={qs}")

# Check available recipes
recipes = ev("return CraftingManager.RECIPES.keys()")
print(f"Available recipes: {recipes}")

# Queue 3 items and verify queue
r1 = ev('return CraftingManager.add_to_queue("MealSimple", 3)')
print(f"add_to_queue('MealSimple', 3) = {r1}")

qs2 = ev("return CraftingManager.craft_queue.size()")
print(f"Queue after add: {qs2}")

# Check queue contents
qb = ev("return CraftingManager.get_queue_by_recipe()")
print(f"Queue breakdown: {qb}")

# Spawn materials
ev('ThingManager.spawn_item_stacks("RawFood", 30, Vector2i(55, 66))\nreturn 1')
print("Spawned RawFood 30")

# Check ingredients
hi = ev('return CraftingManager.has_ingredients("MealSimple")')
print(f"has_ingredients('MealSimple') = {hi}")

# FF at 3x speed for 20 seconds
ev("TickManager.set_speed(3)\nreturn 1")
print("\nFF 20s...")
time.sleep(20)

# Check results
tc2 = ev("return CraftingManager.total_crafted")
qs3 = ev("return CraftingManager.craft_queue.size()")
print(f"After FF: total_crafted={tc2}, queue={qs3}")

# Check what jobs are active
pcount = ev("return PawnManager.pawns.size()")
for i in range(int(pcount)):
    name = ev(f"return PawnManager.pawns[{i}].pawn_name")
    job = ev(f"return PawnManager.pawns[{i}].current_job_name")
    print(f"  {name:8s}: {job}")

# Check crafting summary
sm = ev("return CraftingManager.get_summary()")
print(f"\nSummary: {sm}")

ev("TickManager.set_speed(1)\nreturn 1")
print("\n=== R57 DONE ===")
