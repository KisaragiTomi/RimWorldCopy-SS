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

print("=== Plant Debug ===\n")

# Count plants by type and growth stage
plant_info = ev("var r = {\"total\": 0, \"harvestable\": 0, \"growing\": 0, \"types\": {}}\nfor t in ThingManager.get_plants():\n\tvar p = t as Plant\n\tr.total += 1\n\tif p.growth_stage == Plant.GrowthStage.HARVESTABLE:\n\t\tr.harvestable += 1\n\telse:\n\t\tr.growing += 1\n\tvar n = p.def_name\n\tif not r.types.has(n):\n\t\tr.types[n] = {\"total\": 0, \"harvestable\": 0}\n\tr.types[n].total += 1\n\tif p.growth_stage == Plant.GrowthStage.HARVESTABLE:\n\t\tr.types[n].harvestable += 1\nreturn r")
print(f"Plants: {json.dumps(plant_info, indent=2) if plant_info else plant_info}")

# Check if there's a season check that should prevent winter harvest
# The code in job_giver_sow checks harvest BEFORE season check
# This is RimWorld-correct: harvest mature plants regardless of season

# Let me wait for all plants to be harvested and see if jobs change
print("\n--- Waiting for plants to be cleared ---")
ev("TickManager.set_speed(3)")
for i in range(6):
    time.sleep(15)
    plants = ev("return ThingManager.get_plants().size()")
    harvestable = ev("var c = 0\nfor t in ThingManager.get_plants():\n\tvar p = t as Plant\n\tif p.growth_stage == Plant.GrowthStage.HARVESTABLE:\n\t\tc += 1\nreturn c")
    tick = ev("return TickManager.current_tick")
    season = ev("return SeasonManager.current_season")
    
    pawns = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append(p.current_job_name)\nreturn r")
    
    season_name = {0: "Spring", 1: "Summer", 2: "Fall", 3: "Winter"}.get(season, str(season))
    print(f"  [{(i+1)*15}s] tick={tick} season={season_name} plants={plants} harvestable={harvestable} jobs={pawns}")
    
    if harvestable == 0:
        print("  -> All plants harvested! Checking job switch...")
        time.sleep(10)
        pawns2 = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append(p.current_job_name)\nreturn r")
        print(f"  -> Jobs after clear: {pawns2}")
        break

ev("TickManager.set_speed(1)")
print(f"\n=== DONE ===")
