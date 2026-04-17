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

print("=== R51 SPRING STATUS ===\n")

# Season
season = ev("return SeasonManager.get_summary()")
print(f"Season: {season}\n")

# Research status
rc = ev("return ResearchManager.total_completed")
rp = ev("return ResearchManager.current_project")
print(f"Research: {rc} completed, current={rp}")

# Building count
bc = ev("var s = {}\nfor b in get_tree().get_nodes_in_group('buildings'):\n\ts[b.def_name] = s.get(b.def_name, 0) + 1\nreturn s")
print(f"\nBuildings: {len(bc) if isinstance(bc, dict) else bc} types")
if isinstance(bc, dict):
    for k, v in sorted(bc.items()):
        print(f"  {k}: {v}")

# Crafting
cq = ev("return CraftingManager.craft_queue.size()")
ct = ev("return CraftingManager.total_crafted")
print(f"\nCrafting: queue={cq}, total_crafted={ct}")

# Animals
ac = ev("return AnimalManager.animals.size()")
print(f"Animals: {ac}")

# Fire / Raid
ff = ev("return FireManager.total_fires_started")
fe = ev("return FireManager.total_fires_extinguished")
af = ev("return FireManager.active_fires")
print(f"Fire: started={ff} extinguished={fe} active={af}")

rt = ev("return RaidManager.total_raids")
ar = ev("return RaidManager.active_raid")
print(f"Raids: total={rt} active={ar}")

# Fast-forward 2 min to collect more data
print("\n--- FF 2 min for Spring data ---")
ev("TickManager.set_speed(3)\nreturn 1")
time.sleep(30)

# Check jobs during Spring
print("\n--- Jobs During Spring ---")
pcount = ev("return PawnManager.pawns.size()")
for i in range(int(pcount)):
    name = ev(f"return PawnManager.pawns[{i}].pawn_name")
    job = ev(f"return PawnManager.pawns[{i}].current_job_name")
    food = ev(f'return PawnManager.pawns[{i}].get_need("Food")')
    mood = ev(f'return PawnManager.pawns[{i}].get_need("Mood")')
    rest = ev(f'return PawnManager.pawns[{i}].get_need("Rest")')
    f = food if isinstance(food, (int, float)) else 0
    m = mood if isinstance(mood, (int, float)) else 0
    r = rest if isinstance(rest, (int, float)) else 0
    print(f"  {name:8s} | {str(job):18s} | F={f:.2f} M={m:.2f} R={r:.2f}")

tick = ev("return TickManager.current_tick")
fps = ev("return Engine.get_frames_per_second()")
print(f"\nTick: {tick}, FPS: {fps}")

# Save data and reset speed
ev("TickManager.set_speed(1)\nreturn 1")
ev("var logger = get_node_or_null('/root/_DataLogger')\nif logger:\n\tvar log = logger.get_meta('log', [])\n\tlogger._save_to_disk(log)\nreturn 1")

# Count food after FF
print("\n--- Food After FF ---")
for res in ["MealSimple", "Potato", "Meat", "RawFood"]:
    r = ev(f'var c = 0\nfor t in ThingManager.things:\n\tif t.def_name == "{res}":\n\t\tc += 1\nreturn c')
    if isinstance(r, (int, float)):
        print(f"  {res}: {int(r)}")

print("\n=== R51 SPRING COMPLETE ===")
