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

print("=== R80 Deep Building Verification ===\n")

# === POWER SYSTEM ===
print("--- Power System ---")
grid = ev("return ElectricityGrid.get_summary()")
if isinstance(grid, dict):
    print(f"  Grid count: {grid.get('grid_count', 0)}")
    print(f"  Total gen: {grid.get('total_generation', 0)}W")
    print(f"  Total cons: {grid.get('total_consumption', 0)}W")
    print(f"  Total stored: {grid.get('total_stored', 0)}Wd")
    print(f"  Surplus: {grid.get('total_surplus', 0)}W")
    print(f"  Stability: {grid.get('grid_stability', '?')}")
    print(f"  Brownout risk: {grid.get('brownout_risk_pct', 0)}%")
    nets = grid.get('nets', [])
    for i, net in enumerate(nets):
        print(f"  Net {i}: gen={net.get('gen',0)} draw={net.get('draw',0)} stored={net.get('stored',0)} status={net.get('status','?')}")

# Check individual power buildings
power_buildings = ev("var r = []\nfor b in ThingManager._buildings:\n\tif b.power_gen > 0 or b.power_draw > 0:\n\t\tr.append({\"name\": b.def_name, \"gen\": b.power_gen, \"draw\": b.power_draw})\nreturn r")
print(f"  Power buildings: {power_buildings}")

# === TEMPERATURE SYSTEM ===
print("\n--- Temperature System ---")
temp = ev("return GameState.temperature")
print(f"  Current temp: {temp}C")

temp_mgr = ev("var r = {}\nif TemperatureManager:\n\tfor m in TemperatureManager.get_method_list():\n\t\tif m.name in [\"get_summary\", \"get_room_temps\", \"get_indoor_temp\"]:\n\t\t\tr[\"has_\" + m.name] = true\nreturn r")
print(f"  TempManager: {temp_mgr}")

# Check cooler/heater function
cooler_check = ev("var r = []\nfor b in ThingManager._buildings:\n\tif b.def_name in [\"Cooler\", \"Heater\", \"PassiveCooler\"]:\n\t\tr.append({\"name\": b.def_name, \"powered\": ElectricityGrid.is_powered(b.id) if ElectricityGrid else false})\nreturn r")
print(f"  HVAC buildings: {cooler_check}")

# === MEDICAL SYSTEM ===
print("\n--- Medical System ---")
med_buildings = ev("var r = []\nfor b in ThingManager._buildings:\n\tif b.def_name in [\"HospitalBed\", \"VitalsMonitor\"]:\n\t\tr.append({\"name\": b.def_name, \"powered\": ElectricityGrid.is_powered(b.id) if ElectricityGrid else false})\nreturn r")
print(f"  Medical buildings: {med_buildings}")

# Check pawn health
health = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tvar h = {\"name\": p.pawn_name}\n\tif p.health:\n\t\th[\"hp\"] = p.health.current_hp\n\t\th[\"max\"] = p.health.max_hp\n\tr.append(h)\nreturn r")
print(f"  Pawn health: {health}")

# === DEFENSE SYSTEM ===
print("\n--- Defense System ---")
turret = ev("var r = []\nfor b in ThingManager._buildings:\n\tif b.def_name == \"MiniTurret\":\n\t\tr.append({\"name\": b.def_name, \"powered\": ElectricityGrid.is_powered(b.id) if ElectricityGrid else false, \"hp\": b.hit_points, \"max_hp\": b.max_hit_points})\nreturn r")
print(f"  Turrets: {turret}")

raids = ev("return RaidManager.total_raids")
print(f"  Total raids: {raids}")

# TurretAI check
turret_count = ev("return TurretAI.get_turret_count() if TurretAI.has_method(\"get_turret_count\") else -1")
print(f"  TurretAI registered: {turret_count}")

# === RESEARCH SYSTEM ===
print("\n--- Research System ---")
res_bench = ev("var r = []\nfor b in ThingManager._buildings:\n\tif b.def_name in [\"HiTechResearchBench\", \"MultiAnalyzer\"]:\n\t\tr.append({\"name\": b.def_name, \"powered\": ElectricityGrid.is_powered(b.id) if ElectricityGrid else false})\nreturn r")
print(f"  Research buildings: {res_bench}")

comp = ev("return ResearchManager.get_completion_percentage()")
print(f"  Completion: {comp}%")

# === SHIP SYSTEM ===
print("\n--- Ship System ---")
ship = ev("var r = []\nfor b in ThingManager._buildings:\n\tif b.def_name.begins_with(\"Ship\"):\n\t\tr.append({\"name\": b.def_name, \"hp\": b.hit_points, \"max_hp\": b.max_hit_points})\nreturn r")
print(f"  Ship parts: {ship}")

# === CRAFTING BENCHES ===
print("\n--- Crafting Benches ---")
benches = ev("var r = []\nvar defs = [\"CraftingSpot\", \"TailoringBench\", \"Smithy\", \"MachiningTable\", \"FabricationBench\", \"StonecuttersTable\", \"DrugLab\", \"BreweryVat\", \"AdvancedComponentAssembly\"]\nfor b in ThingManager._buildings:\n\tif b.def_name in defs:\n\t\tr.append(b.def_name)\nreturn r")
print(f"  Active benches: {benches}")

bench_count = ev("return JobGiverCraft.new().get_available_bench_count()")
print(f"  JobGiverCraft bench count: {bench_count}")

print(f"\n=== DONE ===")
