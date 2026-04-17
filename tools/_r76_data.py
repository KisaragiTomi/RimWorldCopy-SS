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

print("=== R76 Fresh Data Collection ===\n")

# Current state
tick = ev("return TickManager.current_tick")
season = ev("return SeasonManager.current_season")
season_sum = ev("return SeasonManager.get_summary()")
fps = ev("return Engine.get_frames_per_second()")
things = ev("return ThingManager.things.size()")

season_name = {0: "Spring", 1: "Summer", 2: "Fall", 3: "Winter"}.get(season, str(season))
print(f"Current: tick={tick} season={season_name} fps={fps} things={things}")
if isinstance(season_sum, dict):
    print(f"  Growth factor: {season_sum.get('growth_factor')}")
    print(f"  Is growing: {season_sum.get('is_growing')}")
    print(f"  Days in season: {season_sum.get('days_in_season')}")

# Inject fresh data logger
logger_code = """
var logger = _DataLogger
if logger:
    logger.clear_data()
    return "cleared"
return "no_logger"
"""
cleared = ev(logger_code)
print(f"\nLogger clear: {cleared}")

# Fast-forward 60s at 3x for fresh data
print("\n--- Collecting fresh data (3x, 60s) ---")
ev("TickManager.set_speed(3)")

for i in range(4):
    time.sleep(15)
    tick = ev("return TickManager.current_tick")
    season = ev("return SeasonManager.current_season")
    fps = ev("return Engine.get_frames_per_second()")
    crafted = ev("return CraftingManager.total_crafted")
    
    pawns = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append({\"name\": p.pawn_name, \"job\": p.current_job_name})\nreturn r")
    
    season_name = {0: "Spring", 1: "Summer", 2: "Fall", 3: "Winter"}.get(season, str(season))
    jobs = [p["job"] for p in pawns] if pawns else []
    print(f"  [{(i+1)*15}s] tick={tick} season={season_name} fps={fps} crafted={crafted} jobs={jobs}")

ev("TickManager.set_speed(1)")

# Check if growth factor matters
growth = ev("return SeasonManager.growth_factor")
print(f"\nGrowth factor: {growth}")

# Check what plants exist
plants = ev("var r = []\nfor t in ThingManager.things:\n\tif t is Plant:\n\t\tvar p = t as Plant\n\t\tr.append({\"name\": p.def_name, \"growth\": p.growth_pct, \"harvestable\": p.is_harvestable()})\nreturn r")
if plants:
    print(f"Plants ({len(plants)}):")
    for p in plants[:10]:
        print(f"  {p.get('name','?')}: growth={p.get('growth',0):.0%} harvestable={p.get('harvestable',False)}")
else:
    print(f"Plants: {plants}")

# Check growing zones
zones = ev("var r = []\nvar map = GameState.get_map()\nif map:\n\tfor y in range(map.height):\n\t\tfor x in range(map.width):\n\t\t\tvar c = map.get_cell(x, y)\n\t\t\tif c and c.zone == \"GrowingZone\":\n\t\t\t\tvar has_plant = false\n\t\t\t\tfor t in ThingManager.things:\n\t\t\t\t\tif t is Plant and t.grid_pos == Vector2i(x,y):\n\t\t\t\t\t\thas_plant = true\n\t\t\t\t\t\tbreak\n\t\t\t\tr.append({\"pos\": [x,y], \"has_plant\": has_plant})\nreturn r.size()")
print(f"\nGrowing zone cells: {zones}")

# Analyze game_raw_data
print(f"\n--- Analyzing game_raw_data.json ---")
with open("logs/game_raw_data.json", "r") as f:
    data = json.load(f)

from collections import Counter
jobs_all = Counter()
for e in data:
    p = e.get("pawn", {})
    jobs_all[p.get("job", "?")] += 1

print(f"Entries: {len(data)}")
print(f"Jobs: {dict(jobs_all.most_common())}")
productive = sum(c for j, c in jobs_all.items() if j not in {"Wander", "JoyActivity", ""})
total = sum(jobs_all.values())
print(f"Productivity: {productive}/{total} = {productive/total*100:.1f}%")

# Final colonist status
pawns = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append({\"name\": p.pawn_name, \"job\": p.current_job_name, \"food\": p.get_need(\"Food\"), \"mood\": p.get_need(\"Mood\"), \"rest\": p.get_need(\"Rest\")})\nreturn r")
if pawns:
    print(f"\nColonists ({len(pawns)}):")
    for p in pawns:
        print(f"  {p['name']}: job={p['job']} food={p.get('food',0):.2f} mood={p.get('mood',0):.2f} rest={p.get('rest',0):.2f}")

print(f"\n=== DONE ===")
