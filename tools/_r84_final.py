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

print("=== R84 Final Comprehensive Check ===\n")

# === GAME STATE ===
tick = ev("return TickManager.current_tick")
season = ev("return SeasonManager.current_season")
temp = ev("return GameState.temperature")
fps = ev("return Engine.get_frames_per_second()")
s_name = {0:"Spring",1:"Summer",2:"Fall",3:"Winter"}.get(season, "?")
print(f"--- Game State ---")
print(f"  Tick: {tick} ({int(tick or 0)/60000:.1f} game days)")
print(f"  Season: {s_name}")
print(f"  Temperature: {float(temp or 0):.1f}C")
print(f"  FPS: {fps}")

# === THINGS ===
things = ev("return ThingManager.things.size()")
plants = ev("return ThingManager.get_plants().size()")
items = ev("return ThingManager.get_items().size()")
buildings = ev("var c = 0\nfor b in ThingManager._buildings:\n\tc += 1\nreturn c")
print(f"\n--- Things ---")
print(f"  Total: {things} (plants={plants} items={items} buildings={buildings})")

# === BUILDINGS ===
bld_types = ev("var r = {}\nfor b in ThingManager._buildings:\n\tr[b.def_name] = r.get(b.def_name, 0) + 1\nreturn r")
print(f"\n--- Buildings ({len(bld_types) if isinstance(bld_types, dict) else '?'} types) ---")

# === RESEARCH ===
comp = ev("return ResearchManager.get_completion_percentage()")
print(f"\n--- Research ---")
print(f"  Completion: {comp}%")

# === POWER ===
gen = ev("return ElectricityGrid.get_total_generation()")
cons = ev("return ElectricityGrid.get_total_consumption()")
stored = ev("return ElectricityGrid.get_total_stored()")
print(f"\n--- Power ---")
print(f"  Generation: {gen}W")
print(f"  Consumption: {cons}W")
print(f"  Stored: {stored}Wd")
print(f"  Status: {'OK' if float(gen or 0) >= float(cons or 0) else 'BROWNOUT'}")

# === CRAFTING ===
crafted = ev("return CraftingManager.total_crafted")
queue = ev("return CraftingManager.craft_queue.size()")
quality = ev("return CraftingManager._quality_counts")
print(f"\n--- Crafting ---")
print(f"  Total crafted: {crafted}")
print(f"  Queue: {queue}")
print(f"  Quality: {quality}")

# === COMBAT ===
raids = ev("return RaidManager.total_raids")
print(f"\n--- Combat ---")
print(f"  Total raids: {raids}")

# === ANIMALS ===
animals = ev("return AnimalManager.animals.size()")
print(f"\n--- Animals ---")
print(f"  Count: {animals}")

# === COLONISTS ===
pawns = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append({\"name\": p.pawn_name, \"job\": p.current_job_name, \"food\": p.get_need(\"Food\"), \"mood\": p.get_need(\"Mood\"), \"rest\": p.get_need(\"Rest\"), \"joy\": p.get_need(\"Joy\"), \"craft\": p.get_skill_level(\"Crafting\")})\nreturn r")
print(f"\n--- Colonists ---")
if pawns:
    for p in pawns:
        print(f"  {p['name']:8s}: job={p.get('job',''):15s} food={p.get('food',0):.2f} mood={p.get('mood',0):.2f} rest={p.get('rest',0):.2f} joy={p.get('joy',0):.2f} craft={p.get('craft',0)}")

# === SYSTEMS VERIFIED ===
print(f"\n--- Systems Summary ---")
systems = {
    "TickManager": ev("return TickManager != null"),
    "GameState": ev("return GameState != null"),
    "ThingManager": ev("return ThingManager != null"),
    "PawnManager": ev("return PawnManager != null"),
    "ResearchManager": ev("return ResearchManager != null"),
    "CraftingManager": ev("return CraftingManager != null"),
    "RaidManager": ev("return RaidManager != null"),
    "SeasonManager": ev("return SeasonManager != null"),
    "WeatherManager": ev("return WeatherManager != null"),
    "FireManager": ev("return FireManager != null"),
    "ElectricityGrid": ev("return ElectricityGrid != null"),
    "AnimalManager": ev("return AnimalManager != null"),
    "TradeManager": ev("return TradeManager != null"),
    "JoyManager": ev("return JoyManager != null"),
    "TemperatureManager": ev("return TemperatureManager != null"),
    "ZoneManager": ev("return ZoneManager != null"),
    "ColonyLog": ev("return ColonyLog != null"),
    "AlertManager": ev("return AlertManager != null"),
    "ScheduleManager": ev("return ScheduleManager != null"),
    "SurgeryManager": ev("return SurgeryManager != null"),
    "DoorManager": ev("return DoorManager != null"),
    "CombatLog": ev("return CombatLog != null"),
}

active = sum(1 for v in systems.values() if v)
print(f"  Active systems: {active}/{len(systems)}")
for name, status in systems.items():
    if not status:
        print(f"  MISSING: {name}")

# Run quick 2min stability test
print(f"\n--- Final Stability Test (2 min at 3x) ---")
ev("TickManager.set_speed(3)")
fps_samples = []
for i in range(8):
    time.sleep(15)
    fps = ev("return Engine.get_frames_per_second()")
    fps_samples.append(float(fps or 0))
    tick = ev("return TickManager.current_tick")
    things = ev("return ThingManager.things.size()")
    print(f"  [{(i+1)*15}s] tick={tick} fps={fps} things={things}")

ev("TickManager.set_speed(1)")
print(f"  FPS: min={min(fps_samples):.0f} avg={sum(fps_samples)/len(fps_samples):.0f} max={max(fps_samples):.0f}")

ev("GameState.save_game()")
print(f"\n=== FINAL: Game saved at tick {ev('return TickManager.current_tick')} ===")
