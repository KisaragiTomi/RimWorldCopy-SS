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

print("=== R57 CORRECT CRAFTING TEST ===\n")

# Check recipes and ingredients
recipes = ev("return CraftingManager.RECIPES.keys()")
print(f"Recipes: {recipes}\n")

# Check each recipe's ingredients
for r in ["Flak_Vest", "SteelSword", "StoneBlock", "SimpleClothes"]:
    ing = ev(f'return CraftingManager.RECIPES.get("{r}", {{}}).get("ingredients", {{}})')
    hi = ev(f'return CraftingManager.has_ingredients("{r}")')
    print(f"  {r}: ingredients={ing}, has={hi}")

# Spawn materials for all recipes
ev('ThingManager.spawn_item_stacks("Steel", 200, Vector2i(55, 65))\nreturn 1')
ev('ThingManager.spawn_item_stacks("Cloth", 100, Vector2i(56, 65))\nreturn 1')
ev('ThingManager.spawn_item_stacks("Component", 30, Vector2i(57, 65))\nreturn 1')
ev('ThingManager.spawn_item_stacks("Stone", 50, Vector2i(58, 65))\nreturn 1')
print("\nSpawned: Steel 200, Cloth 100, Component 30, Stone 50")

# Queue crafts
for r in ["Flak_Vest", "SteelSword", "StoneBlock", "SimpleClothes"]:
    result = ev(f'return CraftingManager.add_to_queue("{r}", 2)')
    print(f"  Queue {r} x2 = {result}")

qs = ev("return CraftingManager.craft_queue.size()")
qb = ev("return CraftingManager.get_queue_by_recipe()")
print(f"\nQueue: {qs} items, breakdown: {qb}")

# FF to let crafting happen
print("\n--- FF 30s at 3x ---")
ev("TickManager.set_speed(3)\nreturn 1")
time.sleep(30)

# Check results
tc = ev("return CraftingManager.total_crafted")
qs2 = ev("return CraftingManager.craft_queue.size()")
print(f"After FF: total_crafted={tc}, queue={qs2}")

# Check pawn jobs
pcount = ev("return PawnManager.pawns.size()")
for i in range(int(pcount)):
    name = ev(f"return PawnManager.pawns[{i}].pawn_name")
    job = ev(f"return PawnManager.pawns[{i}].current_job_name")
    print(f"  {name:8s}: {job}")

tick = ev("return TickManager.current_tick")
fps = ev("return Engine.get_frames_per_second()")
print(f"\nTick: {tick} | FPS: {fps}")

ev("TickManager.set_speed(1)\nreturn 1")
print("\n=== DONE ===")
