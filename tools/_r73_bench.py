import socket, json, time

PORT = 9090

def ev(code):
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(10)
        s.connect(("127.0.0.1", PORT))
        s.sendall(json.dumps({"command": "eval", "params": {"code": code}}).encode() + b"\n")
        buf = b""
        while True:
            chunk = s.recv(4096)
            if not chunk:
                break
            buf += chunk
            try:
                r = json.loads(buf.decode())
                return r.get("result") if isinstance(r, dict) else r
            except:
                continue
        return None
    except:
        return None
    finally:
        s.close()

print("=== R73 OPTIMIZED FPS BENCHMARK ===\n")

# Restore research
for p in ["Electricity", "Batteries", "SolarPanels", "WindTurbine",
          "Geothermal", "WoodFiredGenerator", "Stonecutting", "Smithing",
          "Smelting", "Machining", "Fabrication", "AdvancedFabrication",
          "MicroelectronicsBasics", "MultiAnalyzer", "Hospital",
          "Medicine", "MedicineProduction", "VitalsMonitor",
          "AirConditioning", "Firefoam", "IEDs", "GunTurrets",
          "HeavyTurrets", "MortarShell", "TransportPod",
          "PodLauncher", "CryptosleepCasket", "ShipBasics",
          "ShipCryptosleep", "ShipReactor"]:
    ev(f'ResearchManager._complete_project("{p}")\nreturn 1')

ev('ThingManager.spawn_item_stacks("MealSimple", 50, Vector2i(55, 65))\nreturn 1')

# Benchmark
print("Speed | FPS")
print("------|-----")

for speed in [1, 2, 3]:
    ev(f"TickManager.set_speed({speed})\nreturn 1")
    time.sleep(8)
    fps = ev("return Engine.get_frames_per_second()")
    fps_v = int(fps) if isinstance(fps, (int, float)) else 0
    tick = ev("return TickManager.current_tick")
    tick_v = int(tick) if isinstance(tick, (int, float)) else 0
    print(f"  {speed}x   | {fps_v} (Tick={tick_v})")

# Extended 3x test
ev("TickManager.set_speed(3)\nreturn 1")
print("\n--- Extended 3x test (30s) ---")
tick_start = ev("return TickManager.current_tick")
tick_start = int(tick_start) if isinstance(tick_start, (int, float)) else 0
time.sleep(30)
tick_end = ev("return TickManager.current_tick")
tick_end = int(tick_end) if isinstance(tick_end, (int, float)) else 0
fps = ev("return Engine.get_frames_per_second()")
fps_v = int(fps) if isinstance(fps, (int, float)) else 0
ticks_gained = tick_end - tick_start
print(f"  Ticks gained: {ticks_gained} in 30s = {ticks_gained/30:.0f} tps")
print(f"  FPS: {fps_v}")

things = ev("return ThingManager.things.size()")
print(f"  Things: {things}")

ev("TickManager.set_speed(1)\nreturn 1")
print("\n=== DONE ===")
