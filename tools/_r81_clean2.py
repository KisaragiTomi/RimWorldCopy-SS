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

print("=== R81 Stack Cleanup v2 ===\n")

# Before
things_before = ev("return ThingManager.things.size()")
items_before = ev("return ThingManager.get_items().size()")
print(f"Before: things={things_before} items={items_before}")

# Remove excess items by type, keeping only keep_count stacks
def cleanup_item(def_name, keep_stacks):
    code = f"""var removed = 0
var kept = 0
var to_remove: Array[Thing] = []
for t in ThingManager.get_items():
    if t.def_name == "{def_name}":
        if kept < {keep_stacks}:
            kept += 1
        else:
            to_remove.append(t)
for t in to_remove:
    ThingManager.remove_thing(t)
    removed += 1
return removed"""
    return ev(code)

# Clean excessive stacks
cleanups = [
    ("Wood", 5),       # Keep 5 stacks
    ("MealSimple", 5), # Keep 5 meals
    ("Leather", 3),    # Keep 3 stacks
    ("Meat", 3),       # Keep 3 stacks
    ("RawFood", 3),    # Keep 3 stacks
    ("NutrientPaste", 3),
]

for item, keep in cleanups:
    removed = cleanup_item(item, keep)
    print(f"  {item}: removed {removed} stacks (kept {keep})")

time.sleep(1)

# After
things_after = ev("return ThingManager.things.size()")
items_after = ev("return ThingManager.get_items().size()")
print(f"\nAfter: things={things_after} items={items_after}")
print(f"Reduction: {int(things_before or 0) - int(things_after or 0)} things ({int(items_before or 0) - int(items_after or 0)} items)")

# FPS test at 3x
ev("TickManager.set_speed(3)")
fps_samples = []
for i in range(4):
    time.sleep(10)
    fps = ev("return Engine.get_frames_per_second()")
    fps_samples.append(float(fps or 0))
    print(f"  3x FPS [{i*10+10}s]: {fps}")

ev("TickManager.set_speed(1)")
avg_fps = sum(fps_samples) / len(fps_samples)
print(f"\n3x Avg FPS: {avg_fps:.0f}")

ev("GameState.save_game()")
print("\n=== DONE ===")
