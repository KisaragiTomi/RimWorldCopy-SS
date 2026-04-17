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

print("=== R74 Cleanup ===\n")

# Test basic connectivity
tick = ev("return TickManager.current_tick")
print(f"Current tick: {tick}")

fps = ev("return Engine.get_frames_per_second()")
print(f"FPS: {fps}")

things = ev("return ThingManager.things.size()")
print(f"Things: {things}")

animals = ev("return AnimalManager.animals.size()")
print(f"Animals: {animals}")

# Get types
types = ev("var c = {}; for t in ThingManager.things:\n\tvar n = t.def_name\n\tif not c.has(n): c[n] = 0\n\tc[n] += 1\nreturn c")
print(f"Types: {types}")

# Remove excess - keep max 3 of each type
result = ev("var tc = {}; var rem = 0\nfor t in ThingManager.things:\n\tvar n = t.def_name\n\tif not tc.has(n): tc[n] = 0\n\ttc[n] += 1\nvar to_del = []\nvar tc2 = {}\nfor t in ThingManager.things:\n\tvar n = t.def_name\n\tif not tc2.has(n): tc2[n] = 0\n\ttc2[n] += 1\n\tif tc2[n] > 3: to_del.append(t)\nfor t in to_del:\n\tThingManager.things.erase(t)\n\trem += 1\nreturn {\"removed\": rem, \"remaining\": ThingManager.things.size()}")
print(f"Cleanup: {result}")

# Remove dead animals
aresult = ev("var b = AnimalManager.animals.size()\nvar alive = []\nfor a in AnimalManager.animals:\n\tif not a.dead: alive.append(a)\nAnimalManager.animals = alive\nreturn {\"before\": b, \"after\": alive.size()}")
print(f"Animal cleanup: {aresult}")

time.sleep(1)

# Unlock research
ev("for p in ResearchManager.projects:\n\tResearchManager._complete_project(p)")

# Set 3x and benchmark
ev("TickManager.set_speed(3)")
time.sleep(15)

fps3 = ev("return Engine.get_frames_per_second()")
things_after = ev("return ThingManager.things.size()")
tick_after = ev("return TickManager.current_tick")
print(f"\n3x FPS: {fps3}, Things: {things_after}, Tick: {tick_after}")

# Set 1x back
ev("TickManager.set_speed(1)")

print("\n=== DONE ===")
