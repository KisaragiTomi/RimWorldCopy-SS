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

print("=== R81 Stack Cleanup v3 ===\n")

things_before = ev("return ThingManager.things.size()")
print(f"Before: {things_before} things")

# Simple approach: find and remove excess items one type at a time
for item_type, keep in [("Wood", 5), ("MealSimple", 5), ("Leather", 3), ("Meat", 3), ("RawFood", 3), ("NutrientPaste", 3)]:
    code = f"""var removed = 0
var kept = 0
var rem = []
for t in ThingManager.get_items():
    if t.def_name == "{item_type}":
        if kept < {keep}:
            kept += 1
        else:
            rem.append(t)
for t in rem:
    ThingManager.remove_thing(t)
    removed += 1
return removed"""
    r = ev(code)
    print(f"  {item_type}: removed={r} (kept {keep})")

things_after = ev("return ThingManager.things.size()")
print(f"\nAfter: {things_after} things (reduced {int(things_before or 0) - int(things_after or 0)})")

# Quick 3x test
ev("TickManager.set_speed(3)")
time.sleep(15)
fps = ev("return Engine.get_frames_per_second()")
ev("TickManager.set_speed(1)")
print(f"3x FPS: {fps}")

print("\n=== DONE ===")
