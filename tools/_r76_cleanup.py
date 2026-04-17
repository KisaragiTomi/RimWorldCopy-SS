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

print("=== R76 Proper Cleanup ===\n")

before = ev("return ThingManager.things.size()")
plants_before = ev("return ThingManager.get_plants().size()")
print(f"Before: things={before} plants={plants_before}")

# Remove excess trees (keep max 20)
tree_result = ev("var removed = 0\nvar trees = []\nfor t in ThingManager.get_plants():\n\tvar p = t as Plant\n\tif p.def_name == \"Tree\":\n\t\ttrees.append(t)\nvar keep = 20\nfor i in range(trees.size()):\n\tif i >= keep:\n\t\tThingManager.remove_thing(trees[i])\n\t\tremoved += 1\nreturn {\"removed\": removed, \"trees_before\": trees.size()}")
print(f"Tree cleanup: {tree_result}")

# Remove excess items (keep max 5 of each non-building type)
item_result = ev("var removed = 0\nvar counts = {}\nvar to_remove = []\nfor t in ThingManager.get_items():\n\tvar n = t.def_name\n\tif not counts.has(n): counts[n] = 0\n\tcounts[n] += 1\n\tif counts[n] > 5: to_remove.append(t)\nfor t in to_remove:\n\tThingManager.remove_thing(t)\n\tremoved += 1\nreturn {\"removed\": removed}")
print(f"Item cleanup: {item_result}")

time.sleep(1)
after = ev("return ThingManager.things.size()")
plants_after = ev("return ThingManager.get_plants().size()")
print(f"\nAfter: things={after} plants={plants_after}")

# Benchmark
ev("TickManager.set_speed(3)")
time.sleep(15)
fps = ev("return Engine.get_frames_per_second()")
things_now = ev("return ThingManager.things.size()")
ev("TickManager.set_speed(1)")
print(f"3x FPS: {fps}, things={things_now}")

print(f"\n=== DONE ===")
