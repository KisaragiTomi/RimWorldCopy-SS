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

print("=== R63 MEDICINE CRAFTING ===\n")

# Spawn Healroot_Leaf directly
ev('ThingManager.spawn_item_stacks("Healroot_Leaf", 20, Vector2i(55, 66))\nreturn 1')
ev('ThingManager.spawn_item_stacks("HerbalMedicine", 10, Vector2i(56, 66))\nreturn 1')
ev('ThingManager.spawn_item_stacks("Cloth", 50, Vector2i(57, 66))\nreturn 1')
print("Spawned: Healroot_Leaf 20, HerbalMedicine 10, Cloth 50")

# Check ingredients now
hi1 = ev('return CraftingManager.has_ingredients("HerbalMedicine_Craft")')
hi2 = ev('return CraftingManager.has_ingredients("Medicine_Craft")')
print(f"HerbalMedicine_Craft has_ingredients: {hi1}")
print(f"Medicine_Craft has_ingredients: {hi2}")

# Queue medicine recipes
r1 = ev('return CraftingManager.add_to_queue("HerbalMedicine_Craft", 5)')
r2 = ev('return CraftingManager.add_to_queue("Medicine_Craft", 3)')
print(f"\nQueued: HerbalMedicine_Craft x5 = {r1}")
print(f"Queued: Medicine_Craft x3 = {r2}")

tc_before = ev("return CraftingManager.total_crafted")
qs = ev("return CraftingManager.craft_queue.size()")
print(f"Before: total_crafted={tc_before}, queue={qs}")

# FF to let crafting happen
ev("TickManager.set_speed(3)\nreturn 1")
print("\n--- FF 45s ---")
time.sleep(45)

tc_after = ev("return CraftingManager.total_crafted")
qs_after = ev("return CraftingManager.craft_queue.size()")
quality = ev("return CraftingManager.get_summary().get('quality_stats', {})")
print(f"After: total_crafted={tc_after} (+{tc_after-tc_before}), queue={qs_after}")
print(f"Quality: {quality}")

# Check season
season = ev("return SeasonManager.current_season")
sname = {0: "Spring", 1: "Summer", 2: "Fall", 3: "Winter"}.get(season, str(season))
tick = ev("return TickManager.current_tick")
fps = ev("return Engine.get_frames_per_second()")
print(f"\nSeason: {sname} | Tick: {tick} | FPS: {fps}")

# Continue FF to Summer
if sname != "Summer":
    print("\n--- Continuing FF to Summer ---")
    for chunk in range(10):
        time.sleep(20)
        s = ev("return SeasonManager.current_season")
        t = ev("return TickManager.current_tick")
        f = ev("return Engine.get_frames_per_second()")
        sn = {0: "Spring", 1: "Summer", 2: "Fall", 3: "Winter"}.get(s, str(s))
        print(f"  [{chunk+1}] {sn} | Tick={t} | FPS={f}")
        if sn == "Summer":
            print("  >>> SUMMER!")
            break

# Final status
pcount = ev("return PawnManager.pawns.size()")
print(f"\n--- Colonists ({pcount}) ---")
for i in range(int(pcount)):
    name = ev(f"return PawnManager.pawns[{i}].pawn_name")
    job = ev(f"return PawnManager.pawns[{i}].current_job_name")
    food = ev(f'return PawnManager.pawns[{i}].get_need("Food")')
    f = food if isinstance(food, (int, float)) else 0
    print(f"  {name:8s} | {str(job):18s} | F={f:.2f}")

tick = ev("return TickManager.current_tick")
print(f"\nFinal Tick: {tick}")

ev("TickManager.set_speed(1)\nreturn 1")
ev("var logger = get_node_or_null('/root/_DataLogger')\nif logger:\n\tvar log = logger.get_meta('log', [])\n\tlogger._save_to_disk(log)\nreturn 1")

print("\n=== R63 DONE ===")
