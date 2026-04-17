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

print("=== R79 Full System Status ===\n")

# DefDB - all types
types = ev("return DefDB.all_types()")
print(f"DefDB types: {types}")

# Building defs
bld_names = ev("return DefDB.get_names(\"building\")")
print(f"Building defs: {bld_names}")

# If no "building" type, try others
if not bld_names or (isinstance(bld_names, dict) and "error" in bld_names):
    for t in (types or []):
        count = ev(f"return DefDB.get_type_count(\"{t}\")")
        print(f"  type '{t}': {count} defs")

# Research projects
all_proj = ev("return ResearchManager.get_all_projects()")
print(f"\nResearch projects: {all_proj}")

completion = ev("return ResearchManager.get_completion_percentage()")
print(f"Research completion: {completion}%")

# Check if already completed
for proj_name in (all_proj or [])[:5]:
    done = ev(f"return ResearchManager.is_completed(\"{proj_name}\")")
    print(f"  {proj_name}: completed={done}")

# Electricity
grid_summary = ev("return ElectricityGrid.get_summary()")
print(f"\nElectricity: {grid_summary}")

gen = ev("return ElectricityGrid.get_total_generation()")
cons = ev("return ElectricityGrid.get_total_consumption()")
stored = ev("return ElectricityGrid.get_total_stored()")
print(f"  Generation={gen} Consumption={cons} Stored={stored}")

# Crafting summary
craft_summary = ev("return CraftingManager.get_summary()")
print(f"\nCrafting: {craft_summary}")

# Current game state
tick = ev("return TickManager.current_tick")
season = ev("return SeasonManager.current_season")
temp = ev("return GameState.temperature")
fps = ev("return Engine.get_frames_per_second()")
things = ev("return ThingManager.things.size()")
plants = ev("return ThingManager.get_plants().size()")

print(f"\n--- Game State ---")
print(f"Tick: {tick} ({int(tick or 0)/60000:.1f} days)")
season_name = {0:"Spring",1:"Summer",2:"Fall",3:"Winter"}.get(season, str(season))
print(f"Season: {season_name}")
print(f"Temp: {temp:.1f}C")
print(f"FPS: {fps}")
print(f"Things: {things}, Plants: {plants}")

# Pawns
pawns = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append({\"name\": p.pawn_name, \"job\": p.current_job_name, \"food\": p.get_need(\"Food\"), \"mood\": p.get_need(\"Mood\"), \"rest\": p.get_need(\"Rest\")})\nreturn r")
if pawns:
    print(f"\nColonists ({len(pawns)}):")
    for p in pawns:
        print(f"  {p['name']:8s}: {p.get('job',''):15s} food={p.get('food',0):.2f} mood={p.get('mood',0):.2f} rest={p.get('rest',0):.2f}")

print(f"\n=== DONE ===")
