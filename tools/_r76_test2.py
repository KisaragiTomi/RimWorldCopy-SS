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

print("=== Harvest Test v2 ===\n")

before = ev("return ThingManager.get_plants().size()")
print(f"Plants before: {before}")

# Simple manual harvest
r1 = ev("var p = ThingManager.get_plants()[0] as Plant\nreturn {\"name\": p.def_name, \"stage\": p.growth_stage, \"id\": p.id}")
print(f"First plant: {r1}")

r2 = ev("var p = ThingManager.get_plants()[0] as Plant\nreturn p.harvest()")
print(f"Harvest result: {r2}")

r3 = ev("var p = ThingManager.get_plants()[0]\nThingManager.remove_thing(p)\nreturn \"removed\"")
print(f"Remove: {r3}")

after = ev("return ThingManager.get_plants().size()")
print(f"Plants after: {after}")

# Check what the first pawn harvesting is doing
for i in range(6):
    info = ev(f"var p = PawnManager.pawns[{i}]\nreturn {{\"name\": p.pawn_name, \"job\": p.current_job_name, \"pos\": [p.grid_pos.x, p.grid_pos.y]}}")
    print(f"Pawn {i}: {info}")

# Check driver state for first harvesting pawn
driver = ev("var pid = -1\nfor p in PawnManager.pawns:\n\tif p.current_job_name == \"Harvest\":\n\t\tpid = p.id\n\t\tbreak\nif pid >= 0 and PawnManager._drivers.has(pid):\n\tvar d = PawnManager._drivers[pid]\n\treturn {\"toil_idx\": d._toil_index, \"ticks\": d._toil_ticks, \"count\": d._toils.size(), \"ended\": d.ended}\nreturn \"no_driver\"")
print(f"\nHarvest driver: {driver}")

# Wait and check progress
time.sleep(3)
driver2 = ev("var pid = -1\nfor p in PawnManager.pawns:\n\tif p.current_job_name == \"Harvest\":\n\t\tpid = p.id\n\t\tbreak\nif pid >= 0 and PawnManager._drivers.has(pid):\n\tvar d = PawnManager._drivers[pid]\n\treturn {\"toil_idx\": d._toil_index, \"ticks\": d._toil_ticks, \"count\": d._toils.size(), \"ended\": d.ended}\nreturn \"no_driver\"")
print(f"Driver after 3s: {driver2}")

print(f"\n=== DONE ===")
