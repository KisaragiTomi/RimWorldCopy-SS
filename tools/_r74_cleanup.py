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

print("=== R74 Things Cleanup ===\n")

before = ev("ThingManager.things.size()")
print(f"Things before cleanup: {before}")

# Get item type distribution
dist = ev("""
var counts = {}
for t in ThingManager.things:
    var n = t.def_name if t.has_method('get') else t.get_class()
    if not counts.has(n):
        counts[n] = 0
    counts[n] += 1
return counts
""")
print(f"Item distribution: {dist}")

# Remove excess items - keep max 5 of each type
cleanup_code = """
var type_counts = {}
var to_remove = []
for t in ThingManager.things:
    var n = t.def_name
    if not type_counts.has(n):
        type_counts[n] = 0
    type_counts[n] += 1
    if type_counts[n] > 5:
        to_remove.append(t)

var removed = 0
for t in to_remove:
    if t.has_method("queue_free"):
        t.queue_free()
    ThingManager.things.erase(t)
    removed += 1
return {"removed": removed, "remaining": ThingManager.things.size()}
"""
result = ev(cleanup_code)
print(f"Cleanup result: {result}")

time.sleep(1)

after = ev("ThingManager.things.size()")
print(f"Things after cleanup: {after}")

# Also clean up dead animals
animal_cleanup = ev("""
var before = AnimalManager.animals.size()
var alive = []
for a in AnimalManager.animals:
    if not a.dead:
        alive.append(a)
AnimalManager.animals = alive
return {"before": before, "after": alive.size()}
""")
print(f"Animal cleanup: {animal_cleanup}")

# Now benchmark
print("\n--- Post-cleanup FPS Benchmark ---")
ev("TickManager.set_speed(3)")
time.sleep(10)
fps3 = ev("Engine.get_frames_per_second()")
things_now = ev("ThingManager.things.size()")
tick_now = ev("TickManager.current_tick")
print(f"  3x FPS: {fps3}, Things: {things_now}, Tick: {tick_now}")

print("\n=== DONE ===")
