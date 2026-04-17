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

print("=== R75 Tech & Building Verification ===\n")

# Check research status
research = ev("var r = {}\nfor p in ResearchManager.projects:\n\tr[p] = ResearchManager.is_completed(p)\nreturn r")
if research:
    completed = sum(1 for v in research.values() if v)
    total = len(research)
    print(f"Research: {completed}/{total}")
    unlocked = [k for k, v in research.items() if v]
    locked = [k for k, v in research.items() if not v]
    if locked:
        print(f"  LOCKED: {locked}")
    else:
        print(f"  ALL UNLOCKED!")
else:
    print("Research: Failed to query")
    # Try to unlock all
    ev("for p in ResearchManager.projects:\n\tResearchManager._complete_project(p)")
    print("  -> Attempted to unlock all")

# Check buildings
buildings = ev("var r = []\nvar map = GameState.get_map()\nif map:\n\tfor y in range(map.height):\n\t\tfor x in range(map.width):\n\t\t\tvar c = map.get_cell(x, y)\n\t\t\tif c and c.building:\n\t\t\t\tvar n = c.building.def_name if c.building.has_method('get') else str(c.building)\n\t\t\t\tif n not in r: r.append(n)\nreturn r")
print(f"\nBuilding types on map: {buildings}")

# Check building manager
bld_info = ev("return {\"total\": BuildingManager.buildings.size() if BuildingManager else 0}")
print(f"BuildingManager: {bld_info}")

# All building types check
all_bld = ev("var types = {}\nif BuildingManager:\n\tfor b in BuildingManager.buildings:\n\t\tvar n = b.def_name\n\t\tif not types.has(n): types[n] = 0\n\t\ttypes[n] += 1\nreturn types")
print(f"Building distribution: {all_bld}")

# Check key systems
tick = ev("return TickManager.current_tick")
season = ev("return SeasonManager.current_season")
fps = ev("return Engine.get_frames_per_second()")
things = ev("return ThingManager.things.size()")
animals = ev("return AnimalManager.animals.size()")
crafted = ev("return CraftingManager.total_crafted")
raids = ev("return RaidManager.total_raids")

print(f"\n--- System Status ---")
print(f"  Tick: {tick}")
print(f"  Season: {season}")
print(f"  FPS: {fps}")
print(f"  Things: {things}")
print(f"  Animals: {animals}")
print(f"  Total crafted: {crafted}")
print(f"  Total raids: {raids}")

# Crafting recipes
recipes = ev("return CraftingManager.get_available_recipes()")
print(f"\nAvailable recipes: {recipes}")

# Test quick fast-forward at 3x to verify stability
print(f"\n--- Stability Test (3x, 20s) ---")
ev("TickManager.set_speed(3)")
tick_before = ev("return TickManager.current_tick")
time.sleep(20)
tick_after = ev("return TickManager.current_tick")
fps_ff = ev("return Engine.get_frames_per_second()")
things_ff = ev("return ThingManager.things.size()")

if isinstance(tick_before, (int,float)) and isinstance(tick_after, (int,float)):
    gained = int(tick_after) - int(tick_before)
    tps = gained / 20
else:
    gained = "?"
    tps = "?"

print(f"  Ticks: {tick_before} -> {tick_after} (gained {gained})")
print(f"  TPS: {tps}")
print(f"  FPS: {fps_ff}")
print(f"  Things: {things_ff}")

# Check colonists after fast-forward
pawns = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append({\"name\": p.pawn_name, \"job\": p.current_job_name, \"food\": p.get_need(\"Food\"), \"mood\": p.get_need(\"Mood\")})\nreturn r")
print(f"\nColonists after FF:")
if pawns:
    for p in pawns:
        print(f"  {p['name']}: job={p['job']} food={p.get('food',0):.2f} mood={p.get('mood',0):.2f}")

ev("TickManager.set_speed(1)")
print(f"\n=== DONE ===")
