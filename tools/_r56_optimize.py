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

print("=== R56 OPTIMIZATION CHECK ===\n")

# Crafting test - queue items
print("--- Crafting Queue ---")
ev('CraftingManager.add_to_queue("FlakVest", 2)\nreturn 1')
ev('CraftingManager.add_to_queue("Revolver", 2)\nreturn 1')
ev('CraftingManager.add_to_queue("MealSimple", 10)\nreturn 1')
print("Queued: FlakVest x2, Revolver x2, MealSimple x10")

# Spawn crafting materials
ev('ThingManager.spawn_item_stacks("Steel", 100, Vector2i(55, 65))\nreturn 1')
ev('ThingManager.spawn_item_stacks("Component", 20, Vector2i(56, 65))\nreturn 1')
ev('ThingManager.spawn_item_stacks("RawFood", 80, Vector2i(57, 65))\nreturn 1')
print("Spawned materials: Steel 100, Component 20, RawFood 80")

# FF to let crafting happen
ev("TickManager.set_speed(3)\nreturn 1")
time.sleep(30)

# Check crafting results
cq = ev("return CraftingManager.craft_queue.size()")
ct = ev("return CraftingManager.total_crafted")
print(f"\nAfter FF: queue={cq}, crafted={ct}")

# Check colonist jobs
pcount = ev("return PawnManager.pawns.size()")
print(f"\n--- Colonists ---")
for i in range(int(pcount)):
    name = ev(f"return PawnManager.pawns[{i}].pawn_name")
    job = ev(f"return PawnManager.pawns[{i}].current_job_name")
    food = ev(f'return PawnManager.pawns[{i}].get_need("Food")')
    mood = ev(f'return PawnManager.pawns[{i}].get_need("Mood")')
    f = food if isinstance(food, (int, float)) else 0
    m = mood if isinstance(mood, (int, float)) else 0
    print(f"  {name:8s} | {str(job):18s} | F={f:.2f} M={m:.2f}")

# Check food after crafting MealSimple
print("\n--- Food After Crafting ---")
for res in ["MealSimple", "Potato", "Meat", "RawFood", "Steel", "Component"]:
    r = ev(f'var c = 0\nfor t in ThingManager.things:\n\tif t.def_name == "{res}":\n\t\tc += 1\nreturn c')
    if isinstance(r, (int, float)):
        print(f"  {res}: {int(r)}")

tick = ev("return TickManager.current_tick")
fps = ev("return Engine.get_frames_per_second()")
print(f"\nTick: {tick} | FPS: {fps}")

ev("TickManager.set_speed(1)\nreturn 1")
ev("var logger = get_node_or_null('/root/_DataLogger')\nif logger:\n\tvar log = logger.get_meta('log', [])\n\tlogger._save_to_disk(log)\nreturn 1")

print("\n=== R56 DONE ===")
