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

print("=== R71 PERFORMANCE OPTIMIZATION ===\n")

# Check current state
tc = ev("return ThingManager.things.size()")
print(f"Things before: {tc}")

# Check what types of things exist
breakdown = ev("""
var d = {}
for t in ThingManager.things:
    var n = t.def_name if t.has_method("get") else str(t)
    d[n] = d.get(n, 0) + 1
return d
""")
if isinstance(breakdown, dict):
    print("\nThings breakdown:")
    for k, v in sorted(breakdown.items(), key=lambda x: -x[1]):
        print(f"  {k}: {v}")

# Baseline 3x FPS
ev("TickManager.set_speed(3)\nreturn 1")
time.sleep(5)
fps_before = ev("return Engine.get_frames_per_second()")
print(f"\n3x FPS before cleanup: {fps_before}")

# Remove excess items (keep some of each)
ev("TickManager.set_speed(1)\nreturn 1")
removed = ev("""
var removed = 0
var keep = {"MealSimple": 20, "Potato": 20, "Steel": 30, "Wood": 20,
            "RawFood": 20, "Cloth": 20, "Component": 10, "Meat": 10}
var counts = {}
var to_remove = []
for t in ThingManager.things:
    var n = t.def_name
    counts[n] = counts.get(n, 0) + 1
    var limit = keep.get(n, 999)
    if counts[n] > limit:
        to_remove.append(t)
for t in to_remove:
    t.queue_free()
    removed += 1
return removed
""")
print(f"\nRemoved {removed} excess items")

# Wait for cleanup
time.sleep(3)
tc2 = ev("return ThingManager.things.size()")
print(f"Things after: {tc2}")

# Test 3x FPS after cleanup
ev("TickManager.set_speed(3)\nreturn 1")
time.sleep(10)
fps_after = ev("return Engine.get_frames_per_second()")
print(f"3x FPS after cleanup: {fps_after}")

# Quick FF test
time.sleep(20)
tick = ev("return TickManager.current_tick")
fps_final = ev("return Engine.get_frames_per_second()")
tick_v = int(tick) if isinstance(tick, (int, float)) else 0
print(f"\nAfter 20s FF: Tick={tick_v}, FPS={fps_final}")

# Back to 1x
ev("TickManager.set_speed(1)\nreturn 1")
time.sleep(3)
fps1x = ev("return Engine.get_frames_per_second()")
print(f"1x FPS: {fps1x}")

print(f"\nFPS improvement: {fps_before} -> {fps_after} at 3x")

print("\n=== R71 DONE ===")
