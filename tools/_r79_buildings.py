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

print("=== R79 Building & System Verification ===\n")

# All current buildings on map
buildings = ev("var r = {}\nfor b in ThingManager._buildings:\n\tvar d = b.def_name\n\tif d in r:\n\t\tr[d] += 1\n\telse:\n\t\tr[d] = 1\nreturn r")
print(f"Buildings on map: {buildings}")

# Check power system
power = ev("var r = {}\nif PowerManager:\n\tr[\"total_power\"] = PowerManager.total_power_generated\n\tr[\"total_consumption\"] = PowerManager.total_power_consumed\n\tr[\"battery_stored\"] = PowerManager.total_battery_stored if \"total_battery_stored\" in PowerManager else 0\n\tr[\"generators\"] = PowerManager.generators.size() if \"generators\" in PowerManager else 0\nreturn r")
print(f"\nPower: {power}")

# Check research
research = ev("var r = {}\nif ResearchManager:\n\tr[\"total\"] = ResearchManager.projects.size()\n\tr[\"completed\"] = 0\n\tfor p in ResearchManager.projects:\n\t\tif ResearchManager.projects[p].get(\"completed\", false):\n\t\t\tr[\"completed\"] += 1\n\tr[\"current\"] = ResearchManager.current_project\nreturn r")
print(f"Research: {research}")

# Check temperature control
temp = ev("var r = {}\nif GameState:\n\tr[\"temperature\"] = GameState.temperature\n\tr[\"target_temp\"] = GameState.target_temperature if \"target_temperature\" in GameState else null\nif WeatherManager:\n\tr[\"weather\"] = WeatherManager.current_weather\n\tr[\"temp_offset\"] = WeatherManager.get_temp_offset()\nreturn r")
print(f"Temperature: {temp}")

# Check season
season = ev("var r = {}\nif SeasonManager:\n\tr[\"season\"] = SeasonManager.current_season\n\tr[\"day\"] = SeasonManager.current_day if \"current_day\" in SeasonManager else null\n\tr[\"year\"] = SeasonManager.current_year if \"current_year\" in SeasonManager else null\nreturn r")
print(f"Season: {season}")

# Check medical system
medical = ev("var r = {}\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tvar h = {\"name\": p.pawn_name}\n\tif p.health:\n\t\th[\"hp\"] = p.health.current_hp\n\t\th[\"max_hp\"] = p.health.max_hp\n\t\th[\"injuries\"] = p.health.injuries.size() if \"injuries\" in p.health else 0\n\tr.append(h) if r is Array else null\nreturn r")
print(f"Medical: {medical}")

# Check animals
animals = ev("var r = []\nif AnimalManager:\n\tfor a in AnimalManager.animals:\n\t\tr.append({\"name\": a.get(\"name\", \"?\"), \"species\": a.get(\"species\", \"?\"), \"tamed\": a.get(\"tamed\", false)})\nreturn r")
print(f"Animals ({len(animals) if isinstance(animals, list) else '?'}): {animals}")

# Check combat
combat = ev("var r = {}\nif RaidManager:\n\tr[\"total_raids\"] = RaidManager.total_raids\n\tr[\"active_raiders\"] = 0\n\tfor p in PawnManager.pawns:\n\t\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\" and not p.dead:\n\t\t\tr[\"active_raiders\"] += 1\nreturn r")
print(f"Combat: {combat}")

# Available building defs (what CAN be built)
build_defs = ev("var r = []\nif BuildingDefs:\n\tfor key in BuildingDefs.ALL:\n\t\tr.append(key)\nreturn r")
print(f"\nBuildable defs: {build_defs}")

# Missing buildings (in defs but not on map)
if isinstance(build_defs, list) and isinstance(buildings, dict):
    on_map = set(buildings.keys())
    all_defs = set(build_defs)
    missing = sorted(all_defs - on_map)
    print(f"\nNOT on map ({len(missing)}): {missing}")

print(f"\n=== DONE ===")
