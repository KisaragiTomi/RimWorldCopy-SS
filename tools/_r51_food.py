import socket, json, time
from collections import Counter

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

print("=== R51 FOOD CHECK ===\n")

# Current food resources
print("--- Food Resources ---")
for res in ["MealSimple", "Potato", "Meat", "RawFood", "NutrientPaste"]:
    r = ev(f'var c = 0\nfor t in ThingManager.things:\n\tif t.def_name == "{res}":\n\t\tc += 1\nreturn c')
    if isinstance(r, (int, float)):
        print(f"  {res}: {int(r)}")

# Colonist food needs
print("\n--- Colonist Food ---")
pcount = ev("return PawnManager.pawns.size()")
for i in range(int(pcount)):
    name = ev(f"return PawnManager.pawns[{i}].pawn_name")
    food = ev(f'return PawnManager.pawns[{i}].get_need("Food")')
    f = food if isinstance(food, (int, float)) else 0
    status = "OK" if f > 0.3 else "LOW!" if f > 0.15 else "CRITICAL!"
    print(f"  {name:8s}: {f:.2f} [{status}]")

# Spawn food to prevent starvation
print("\n--- Spawning Emergency Food ---")
ev('ThingManager.spawn_item_stacks("MealSimple", 50, Vector2i(55, 65))\nreturn 1')
ev('ThingManager.spawn_item_stacks("RawFood", 100, Vector2i(56, 65))\nreturn 1')
print("Spawned: MealSimple 50, RawFood 100")

# Fast-forward briefly
print("\n--- FF 1 min ---")
ev("TickManager.set_speed(3)\nreturn 1")
time.sleep(15)

tick = ev("return TickManager.current_tick")
fps = ev("return Engine.get_frames_per_second()")
print(f"Tick: {tick}, FPS: {fps}")

# Check colonists after food supply
print("\n--- Colonists After Food ---")
for i in range(int(pcount)):
    name = ev(f"return PawnManager.pawns[{i}].pawn_name")
    job = ev(f"return PawnManager.pawns[{i}].current_job_name")
    food = ev(f'return PawnManager.pawns[{i}].get_need("Food")')
    f = food if isinstance(food, (int, float)) else 0
    print(f"  {name:8s} | {job:15s} | F={f:.2f}")

ev("TickManager.set_speed(1)\nreturn 1")
ev("var logger = get_node_or_null('/root/_DataLogger')\nif logger:\n\tvar log = logger.get_meta('log', [])\n\tlogger._save_to_disk(log)\nreturn 1")

print("\n=== R51 COMPLETE ===")
