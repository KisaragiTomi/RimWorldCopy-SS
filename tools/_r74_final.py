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

print("=== R74 FINAL BENCHMARK ===\n")

# Unlock all research
ev("for p in ResearchManager.projects:\n\tResearchManager._complete_project(p)")

# Spawn some resources for gameplay
ev("ThingManager.spawn_item_stacks([{\"def_name\":\"MealSimple\",\"count\":20},{\"def_name\":\"Wood\",\"count\":50},{\"def_name\":\"Steel\",\"count\":30}])")
time.sleep(1)

things = ev("return ThingManager.things.size()")
print(f"Things count: {things}")

# Benchmark 1x
ev("TickManager.set_speed(1)")
time.sleep(5)
fps1 = ev("return Engine.get_frames_per_second()")
tick1 = ev("return TickManager.current_tick")
print(f"1x FPS: {fps1}, Tick: {tick1}")

# Benchmark 2x
ev("TickManager.set_speed(2)")
time.sleep(5)
fps2 = ev("return Engine.get_frames_per_second()")
tick2 = ev("return TickManager.current_tick")
print(f"2x FPS: {fps2}, Tick: {tick2}")

# Benchmark 3x
ev("TickManager.set_speed(3)")
time.sleep(5)
fps3 = ev("return Engine.get_frames_per_second()")
tick3 = ev("return TickManager.current_tick")
print(f"3x FPS: {fps3}, Tick: {tick3}")

# Extended 3x test
tick_start = ev("return TickManager.current_tick")
time.sleep(30)
tick_end = ev("return TickManager.current_tick")
fps3_ext = ev("return Engine.get_frames_per_second()")
things_end = ev("return ThingManager.things.size()")

if isinstance(tick_start, (int,float)) and isinstance(tick_end, (int,float)):
    gained = int(tick_end) - int(tick_start)
    tps = gained / 30
else:
    gained = "?"
    tps = "?"

print(f"\n--- Extended 3x (30s) ---")
print(f"  Ticks: {tick_start} -> {tick_end} (gained {gained})")
print(f"  TPS: {tps}")
print(f"  FPS: {fps3_ext}")
print(f"  Things: {things_end}")

# Check colony status
pawns = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append({\"name\": p.pawn_name, \"job\": p.current_job_name, \"food\": p.get_need(\"Food\"), \"mood\": p.get_need(\"Mood\")})\nreturn r")
print(f"\nColonists: {json.dumps(pawns, indent=2) if pawns else pawns}")

season = ev("return SeasonManager.get_summary()")
print(f"Season: {season}")

ev("TickManager.set_speed(1)")
print("\n=== DONE ===")
