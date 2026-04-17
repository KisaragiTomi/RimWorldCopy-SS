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

print("=== Harvest Test ===\n")

# Get plant count before
before = ev("return ThingManager.get_plants().size()")
print(f"Plants before: {before}")

# Manually harvest first plant
test = ev("""
var plants = ThingManager.get_plants()
if plants.size() > 0:
    var p = plants[0] as Plant
    var info = {"name": p.def_name, "stage": p.growth_stage, "id": p.id, "pos": [p.grid_pos.x, p.grid_pos.y]}
    var result = p.harvest()
    info["harvest_result"] = result
    if not result.is_empty():
        ThingManager.remove_thing(p)
        info["removed"] = true
    else:
        info["removed"] = false
    return info
return "no_plants"
""")
print(f"Manual harvest: {test}")

# Get plant count after
after = ev("return ThingManager.get_plants().size()")
print(f"Plants after: {after}")
print(f"Removed: {int(before or 0) - int(after or 0)}")

# Now check a pawn's harvest job driver
driver_info = ev("""
var r = []
for p in PawnManager.pawns:
    if p.dead: continue
    if p.has_meta("faction") and p.get_meta("faction") == "enemy": continue
    if p.current_job_name == "Harvest" and PawnManager._drivers.has(p.id):
        var d = PawnManager._drivers[p.id]
        r.append({
            "pawn": p.pawn_name,
            "toil_idx": d._toil_index,
            "toil_ticks": d._toil_ticks,
            "toils_count": d._toils.size(),
            "current_toil": d._toils[d._toil_index].name if d._toil_index >= 0 and d._toil_index < d._toils.size() else "none",
            "ended": d.ended,
            "target_id": d.job.target_thing_id if d.job else -1,
            "pawn_pos": [p.grid_pos.x, p.grid_pos.y],
        })
return r
""")
print(f"\nHarvest drivers: {json.dumps(driver_info, indent=2) if driver_info else driver_info}")

# Fast-forward 15s and check again
ev("TickManager.set_speed(3)")
time.sleep(15)
plants_after_ff = ev("return ThingManager.get_plants().size()")
fps = ev("return Engine.get_frames_per_second()")
ev("TickManager.set_speed(1)")
print(f"\nAfter 15s 3x: plants={plants_after_ff} fps={fps}")

print(f"\n=== DONE ===")
