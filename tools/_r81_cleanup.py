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

print("=== R81 Stack Cleanup ===\n")

# Before
things_before = ev("return ThingManager.things.size()")
items_before = ev("return ThingManager.get_items().size()")
fps_before = ev("return Engine.get_frames_per_second()")
print(f"Before: things={things_before} items={items_before} fps={fps_before}")

# Consolidate stacks: for each item type, keep total count and remove excess
# This removes all items of a type and respawns as minimal stacks
cleanup_code = """var types = {}
var to_remove = []
for t in ThingManager.get_items():
    var d = t.def_name
    var c = t.stack_count if t.get("stack_count") else 1
    if d in types:
        types[d] += c
        to_remove.append(t)
    else:
        types[d] = c
for t in to_remove:
    ThingManager.remove_thing(t)
return {"removed": to_remove.size(), "types": types.size()}"""

r = ev(cleanup_code)
print(f"Cleanup result: {r}")

time.sleep(1)

# After
things_after = ev("return ThingManager.things.size()")
items_after = ev("return ThingManager.get_items().size()")
print(f"After: things={things_after} items={items_after}")
print(f"Reduction: {int(things_before or 0) - int(things_after or 0)} things")

# Stack check
stacks = ev("var r = {}\nfor t in ThingManager.get_items():\n\tvar d = t.def_name\n\tvar c = t.stack_count if t.get(\"stack_count\") else 1\n\tif d in r:\n\t\tr[d] = {\"count\": r[d].count + c, \"stacks\": r[d].stacks + 1}\n\telse:\n\t\tr[d] = {\"count\": c, \"stacks\": 1}\nreturn r")
print(f"\nItem stacks after:")
if isinstance(stacks, dict):
    for name, info in sorted(stacks.items(), key=lambda x: -x[1].get("stacks", 0) if isinstance(x[1], dict) else 0):
        if isinstance(info, dict):
            print(f"  {name:25s}: {info.get('count',0)} units in {info.get('stacks',0)} stacks")

# Quick FPS test at 3x
ev("TickManager.set_speed(3)")
time.sleep(10)
fps_after = ev("return Engine.get_frames_per_second()")
ev("TickManager.set_speed(1)")
print(f"\nFPS after cleanup: {fps_after} (was {fps_before})")

ev("GameState.save_game()")
print("\n=== DONE ===")
