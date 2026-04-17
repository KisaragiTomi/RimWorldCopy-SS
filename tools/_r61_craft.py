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

print("=== R61 FULL CRAFTING TEST ===\n")

# Check recipes and their ingredients
recipes = ev("return CraftingManager.RECIPES")
print("All recipes:")
if isinstance(recipes, dict):
    for name, info in recipes.items():
        ing = info.get("ingredients", {})
        out = info.get("output", "?")
        cnt = info.get("output_count", 1)
        print(f"  {name}: {ing} -> {out} x{cnt}")

# Spawn all needed materials
print("\n--- Spawning materials ---")
mats = {"Steel": 300, "Cloth": 200, "Component": 50, "Stone": 100,
        "HerbalMedicine": 30, "Neutroamine": 20}
for mat, qty in mats.items():
    ev(f'ThingManager.spawn_item_stacks("{mat}", {qty}, Vector2i(55, 65))\nreturn 1')
    print(f"  {mat}: {qty}")

# Queue all 7 recipes
print("\n--- Queueing all recipes ---")
tc_before = ev("return CraftingManager.total_crafted")
for recipe in ["ComponentIndustrial", "HerbalMedicine_Craft", "Medicine_Craft",
               "StoneBlock", "SteelSword", "SimpleClothes", "Flak_Vest"]:
    r = ev(f'return CraftingManager.add_to_queue("{recipe}", 2)')
    hi = ev(f'return CraftingManager.has_ingredients("{recipe}")')
    print(f"  {recipe}: added={r}, has_ingredients={hi}")

qs = ev("return CraftingManager.craft_queue.size()")
print(f"\nTotal queue: {qs}")

# FF long enough for crafting
print("\n--- FF 60s at 3x ---")
ev("TickManager.set_speed(3)\nreturn 1")
time.sleep(60)

tc_after = ev("return CraftingManager.total_crafted")
qs_after = ev("return CraftingManager.craft_queue.size()")
print(f"Result: total_crafted {tc_before}->{tc_after} (+{tc_after-tc_before})")
print(f"Queue: {qs}->{qs_after}")

# Check quality stats
qs_data = ev("return CraftingManager.get_summary()")
if isinstance(qs_data, dict):
    print(f"Quality: {qs_data.get('quality_stats', {})}")

# Pawn jobs
pcount = ev("return PawnManager.pawns.size()")
print("\n--- Colonists ---")
for i in range(int(pcount)):
    name = ev(f"return PawnManager.pawns[{i}].pawn_name")
    job = ev(f"return PawnManager.pawns[{i}].current_job_name")
    food = ev(f'return PawnManager.pawns[{i}].get_need("Food")')
    f = food if isinstance(food, (int, float)) else 0
    print(f"  {name:8s} | {str(job):18s} | F={f:.2f}")

tick = ev("return TickManager.current_tick")
fps = ev("return Engine.get_frames_per_second()")
print(f"\nTick: {tick} | FPS: {fps}")

ev("TickManager.set_speed(1)\nreturn 1")
ev("var logger = get_node_or_null('/root/_DataLogger')\nif logger:\n\tvar log = logger.get_meta('log', [])\n\tlogger._save_to_disk(log)\nreturn 1")

print("\n=== R61 DONE ===")
