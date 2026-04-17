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

print("=== R79 Tech Tree & Building Test ===\n")

# 1. Complete all research
projects = ev("return ResearchManager.get_all_projects()")
if isinstance(projects, list):
    for p in projects:
        name = p.get("defName", "")
        if name:
            ev(f"ResearchManager._complete_project(\"{name}\")")
    print(f"Completed {len(projects)} research projects")

comp = ev("return ResearchManager.get_completion_percentage()")
print(f"Completion: {comp}%")

# 2. Check which buildings exist on map
existing = ev("var r = {}\nfor b in ThingManager._buildings:\n\tr[b.def_name] = r.get(b.def_name, 0) + 1\nreturn r")
print(f"\nExisting buildings: {existing}")

# 3. Get all unlockable buildings from research
all_unlocks = set()
if isinstance(projects, list):
    for p in projects:
        for u in p.get("unlocks", []):
            all_unlocks.add(u)
print(f"\nAll unlockable buildings ({len(all_unlocks)}): {sorted(all_unlocks)}")

# 4. Which are missing from map
existing_set = set(existing.keys()) if isinstance(existing, dict) else set()
missing = sorted(all_unlocks - existing_set)
print(f"Missing ({len(missing)}): {missing}")

# 5. Spawn missing tech buildings
spawn_results = {}
base_x, base_y = 30, 30
offset = 0

for bld_name in missing:
    x = base_x + (offset % 10) * 3
    y = base_y + (offset // 10) * 3
    r = ev(f"var b = Building.new()\nb.def_name = \"{bld_name}\"\nb.grid_pos = Vector2i({x}, {y})\nb.build_state = Building.BuildState.COMPLETE\nThingManager.spawn_thing(b)\nreturn \"ok\"")
    spawn_results[bld_name] = r
    offset += 1

print(f"\nSpawn results:")
for name, result in spawn_results.items():
    status = "OK" if result == "ok" else f"FAIL({result})"
    print(f"  {name:30s}: {status}")

# 6. Verify all buildings now on map
time.sleep(1)
final_buildings = ev("var r = {}\nfor b in ThingManager._buildings:\n\tr[b.def_name] = r.get(b.def_name, 0) + 1\nreturn r")
print(f"\nFinal buildings ({len(final_buildings) if isinstance(final_buildings, dict) else '?'}):")
if isinstance(final_buildings, dict):
    for name in sorted(final_buildings.keys()):
        print(f"  {name}: {final_buildings[name]}")

# 7. Check electricity after spawning generators
time.sleep(1)
gen = ev("return ElectricityGrid.get_total_generation()")
cons = ev("return ElectricityGrid.get_total_consumption()")
surplus = ev("return ElectricityGrid.get_total_surplus()")
print(f"\nPower: gen={gen} cons={cons} surplus={surplus}")

# 8. Run at 3x for 60s to verify stability
ev("TickManager.set_speed(3)")
print("\n--- Running at 3x (60s) ---")
for i in range(4):
    time.sleep(15)
    tick = ev("return TickManager.current_tick")
    fps = ev("return Engine.get_frames_per_second()")
    gen = ev("return ElectricityGrid.get_total_generation()")
    things = ev("return ThingManager.things.size()")
    print(f"  [{(i+1)*15}s] tick={tick} fps={fps} gen={gen}W things={things}")

ev("TickManager.set_speed(1)")
ev("GameState.save_game()")
print("\nGame saved.")
print("\n=== DONE ===")
