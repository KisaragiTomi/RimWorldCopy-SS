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

print("=== R81 Stack Cleanup v4 ===\n")

things_before = ev("return ThingManager.things.size()")
print(f"Before: {things_before} things")

# Remove one item at a time in a loop
for item_type, keep in [("Wood", 5), ("MealSimple", 5), ("Leather", 3), ("Meat", 3), ("RawFood", 3), ("NutrientPaste", 3)]:
    total_removed = 0
    for attempt in range(100):
        # Count current stacks
        count = ev(f"var c = 0\nfor t in ThingManager.get_items():\n\tif t.def_name == \"{item_type}\":\n\t\tc += 1\nreturn c")
        
        if not isinstance(count, (int, float)) or int(count) <= keep:
            break
        
        # Remove one item
        r = ev(f"for t in ThingManager.get_items():\n\tif t.def_name == \"{item_type}\":\n\t\tThingManager.remove_thing(t)\n\t\treturn 1\nreturn 0")
        if r == 1:
            total_removed += 1
        else:
            break
    
    print(f"  {item_type:20s}: removed {total_removed} stacks (target keep={keep})")

things_after = ev("return ThingManager.things.size()")
print(f"\nAfter: {things_after} things (reduced {int(things_before or 0) - int(things_after or 0)})")

# FPS test
ev("TickManager.set_speed(3)")
time.sleep(15)
fps = ev("return Engine.get_frames_per_second()")
ev("TickManager.set_speed(1)")
print(f"3x FPS: {fps}")

ev("GameState.save_game()")
print("\n=== DONE ===")
