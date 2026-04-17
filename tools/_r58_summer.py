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

print("=== R58 FF TO SUMMER ===\n")

# Check remaining crafting
tc = ev("return CraftingManager.total_crafted")
qs = ev("return CraftingManager.craft_queue.size()")
print(f"Crafting: total={tc}, queue={qs}")

# Spawn extra materials for remaining queue
ev('ThingManager.spawn_item_stacks("Steel", 100, Vector2i(55, 65))\nreturn 1')
ev('ThingManager.spawn_item_stacks("Stone", 50, Vector2i(56, 65))\nreturn 1')
ev('ThingManager.spawn_item_stacks("Cloth", 50, Vector2i(57, 65))\nreturn 1')
ev('ThingManager.spawn_item_stacks("MealSimple", 50, Vector2i(58, 65))\nreturn 1')

# FF to Summer
ev("TickManager.set_speed(3)\nreturn 1")

for chunk in range(12):
    time.sleep(20)
    s = ev("return SeasonManager.current_season")
    t = ev("return TickManager.current_tick")
    fps = ev("return Engine.get_frames_per_second()")
    sname = {0: "Spring", 1: "Summer", 2: "Fall", 3: "Winter"}.get(s, str(s))
    print(f"  [{chunk+1}] {sname} | Tick={t} | FPS={fps}")
    if str(s) in ["Summer", "1"]:
        print("  >>> SUMMER!")
        break

# Summer data
print("\n--- Summer Status ---")
summary = ev("return SeasonManager.get_summary()")
if isinstance(summary, dict):
    for k in ["current_season", "growth_factor", "year_count", "total_changes"]:
        print(f"  {k}: {summary.get(k)}")

# Colonists
pcount = ev("return PawnManager.pawns.size()")
for i in range(int(pcount)):
    name = ev(f"return PawnManager.pawns[{i}].pawn_name")
    job = ev(f"return PawnManager.pawns[{i}].current_job_name")
    food = ev(f'return PawnManager.pawns[{i}].get_need("Food")')
    mood = ev(f'return PawnManager.pawns[{i}].get_need("Mood")')
    f = food if isinstance(food, (int, float)) else 0
    m = mood if isinstance(mood, (int, float)) else 0
    print(f"  {name:8s} | {str(job):18s} | F={f:.2f} M={m:.2f}")

# Crafting after FF
tc2 = ev("return CraftingManager.total_crafted")
qs2 = ev("return CraftingManager.craft_queue.size()")
print(f"\nCrafting after FF: total={tc2}, queue={qs2}")

# Resources
print("\n--- Resources ---")
for res in ["MealSimple", "Potato", "Meat", "Steel", "Component"]:
    r = ev(f'var c = 0\nfor t in ThingManager.things:\n\tif t.def_name == "{res}":\n\t\tc += 1\nreturn c')
    if isinstance(r, (int, float)):
        print(f"  {res}: {int(r)}")

tick = ev("return TickManager.current_tick")
fps = ev("return Engine.get_frames_per_second()")
print(f"\nTick: {tick} | FPS: {fps}")

ev("TickManager.set_speed(1)\nreturn 1")
ev("var logger = get_node_or_null('/root/_DataLogger')\nif logger:\n\tvar log = logger.get_meta('log', [])\n\tlogger._save_to_disk(log)\nreturn 1")

print("\n=== R58 DONE ===")
