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

print("=== R79 Spawn Tech Buildings ===\n")

# Test simple spawn first
r = ev("var b = Building.new(\"WoodFiredGenerator\")\nThingManager.spawn_thing(b, Vector2i(30, 30))\nreturn \"ok\"")
print(f"Test spawn WoodFiredGenerator: {r}")

# If that works, spawn all missing buildings
tech_buildings = [
    ("SolarGenerator", 31, 30),
    ("GeothermalGenerator", 32, 30),
    ("Battery", 33, 30),
    ("PowerConduit", 34, 30),
    ("MiniTurret", 35, 30),
    ("Smithy", 30, 32),
    ("StonecuttersTable", 31, 32),
    ("MachiningTable", 32, 32),
    ("FabricationBench", 33, 32),
    ("AdvancedComponentAssembly", 34, 32),
    ("DrugLab", 35, 32),
    ("BreweryVat", 30, 34),
    ("HiTechResearchBench", 31, 34),
    ("CommsConsole", 32, 34),
    ("HospitalBed", 33, 34),
    ("VitalsMonitor", 34, 34),
    ("MultiAnalyzer", 35, 34),
    ("LongRangeMineralScanner", 30, 36),
    ("TransportPodLauncher", 31, 36),
    ("PassiveCooler", 32, 36),
    ("Cooler", 33, 36),
    ("Heater", 34, 36),
    ("ShipStructuralBeam", 30, 38),
    ("ShipEngine", 31, 38),
    ("ShipSensorCluster", 32, 38),
    ("ShipCryptosleepCasket", 33, 38),
    ("ShipReactor", 34, 38),
]

results = {}
for name, x, y in tech_buildings:
    r = ev(f"var b = Building.new(\"{name}\")\nThingManager.spawn_thing(b, Vector2i({x}, {y}))\nreturn \"ok\"")
    results[name] = r

ok = sum(1 for v in results.values() if v == "ok")
fail = sum(1 for v in results.values() if v != "ok")
print(f"\nSpawned: {ok} OK, {fail} FAIL")

for name, result in results.items():
    if result != "ok":
        print(f"  FAIL: {name} -> {result}")

# Verify
time.sleep(1)
final = ev("var r = {}\nfor b in ThingManager._buildings:\n\tr[b.def_name] = r.get(b.def_name, 0) + 1\nreturn r")
print(f"\nAll buildings on map ({len(final) if isinstance(final, dict) else '?'}):")
if isinstance(final, dict):
    for name in sorted(final.keys()):
        print(f"  {name}: {final[name]}")

# Check power
gen = ev("return ElectricityGrid.get_total_generation()")
cons = ev("return ElectricityGrid.get_total_consumption()")
print(f"\nPower: gen={gen}W cons={cons}W")

print(f"\n=== DONE ===")
