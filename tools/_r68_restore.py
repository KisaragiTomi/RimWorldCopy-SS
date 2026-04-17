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
        if buf:
            r = json.loads(buf.decode())
            return r.get("result") if isinstance(r, dict) else r
        return None
    except Exception as e:
        return {"error": str(e)}
    finally:
        s.close()

print("=== R68 RESTORE ===\n")

# Test connection
tick = ev("return TickManager.current_tick")
fps = ev("return Engine.get_frames_per_second()")
print(f"Connection: Tick={tick}, FPS={fps}")

if not isinstance(tick, (int, float)):
    print("ERROR: Cannot connect to game!")
    exit(1)

# Unlock all research
print("\n--- Unlocking Research ---")
projects = [
    "Electricity", "Batteries", "SolarPanels", "WindTurbine",
    "Geothermal", "WoodFiredGenerator", "Stonecutting", "Smithing",
    "Smelting", "Machining", "Fabrication", "AdvancedFabrication",
    "MicroelectronicsBasics", "MultiAnalyzer", "Hospital",
    "Medicine", "MedicineProduction", "VitalsMonitor",
    "AirConditioning", "Firefoam", "IEDs", "GunTurrets",
    "HeavyTurrets", "MortarShell", "TransportPod",
    "PodLauncher", "CryptosleepCasket", "ShipBasics",
    "ShipCryptosleep", "ShipReactor"
]

completed = 0
for p in projects:
    r = ev(f'ResearchManager._complete_project("{p}")\nreturn 1')
    if r == 1:
        completed += 1

rc = ev("return ResearchManager.total_completed")
print(f"Completed: {completed} projects, total={rc}")

# Spawn resources
print("\n--- Spawning Resources ---")
resources = {
    "MealSimple": 100, "RawFood": 80, "Steel": 200,
    "Wood": 100, "Component": 30, "Cloth": 100,
    "Stone": 50, "Healroot_Leaf": 20
}
for name, qty in resources.items():
    ev(f'ThingManager.spawn_item_stacks("{name}", {qty}, Vector2i(55, 65))\nreturn 1')
    print(f"  {name}: {qty}")

# Check colonists
pcount = ev("return PawnManager.pawns.size()")
print(f"\n--- Colonists ({pcount}) ---")
for i in range(int(pcount) if isinstance(pcount, (int, float)) else 0):
    name = ev(f"return PawnManager.pawns[{i}].pawn_name")
    job = ev(f"return PawnManager.pawns[{i}].current_job_name")
    food = ev(f'return PawnManager.pawns[{i}].get_need("Food")')
    f = food if isinstance(food, (int, float)) else 0
    print(f"  {name}: {job} (F={f:.2f})")

tick = ev("return TickManager.current_tick")
fps = ev("return Engine.get_frames_per_second()")
season = ev("return SeasonManager.current_season")
print(f"\nTick: {tick} | FPS: {fps} | Season: {season}")

print("\n=== RESTORE DONE ===")
