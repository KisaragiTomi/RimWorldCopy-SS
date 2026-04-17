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

print("=== Harvest Debug ===\n")

# Check if plants are in things array
in_things = ev("var count = 0\nfor t in ThingManager.things:\n\tif t is Plant: count += 1\nreturn count")
in_plants = ev("return ThingManager.get_plants().size()")
print(f"Plants in things: {in_things}")
print(f"Plants in _plants: {in_plants}")

# Get a plant's ID from _plants and check if it's in things
first_plant_id = ev("return ThingManager.get_plants()[0].id")
found_in_things = ev(f"var found = false\nfor t in ThingManager.things:\n\tif t.id == {first_plant_id}:\n\t\tfound = true\n\t\tbreak\nreturn found")
print(f"\nFirst plant ID: {first_plant_id}")
print(f"Found in things: {found_in_things}")

# Check what a pawn's harvest target ID is
target = ev("for p in PawnManager.pawns:\n\tif p.current_job_name == \"Harvest\" and PawnManager._drivers.has(p.id):\n\t\tvar d = PawnManager._drivers[p.id]\n\t\treturn {\"pawn\": p.pawn_name, \"target_id\": d.job.target_thing_id}\nreturn \"no_harvest\"")
print(f"\nHarvest target: {target}")

# Check if that target ID exists in things
if isinstance(target, dict) and "target_id" in target:
    tid = target["target_id"]
    exists = ev(f"var found = false\nfor t in ThingManager.things:\n\tif t.id == {tid}:\n\t\tfound = true\n\t\tbreak\nreturn found")
    exists_plants = ev(f"var found = false\nfor t in ThingManager.get_plants():\n\tif t.id == {tid}:\n\t\tfound = true\n\t\tbreak\nreturn found")
    print(f"Target {tid} in things: {exists}")
    print(f"Target {tid} in _plants: {exists_plants}")

# Check Thing ID range
max_id = ev("var mx = 0\nfor t in ThingManager.things:\n\tif t.id > mx: mx = t.id\nreturn mx")
max_plant_id = ev("var mx = 0\nfor t in ThingManager.get_plants():\n\tif t.id > mx: mx = t.id\nreturn mx")
print(f"\nMax ID in things: {max_id}")
print(f"Max ID in _plants: {max_plant_id}")

print(f"\n=== DONE ===")
