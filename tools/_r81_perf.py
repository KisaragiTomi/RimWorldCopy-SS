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

print("=== R81 Performance Check ===\n")

# Thing breakdown
things = ev("return ThingManager.things.size()")
plants = ev("return ThingManager.get_plants().size()")
items = ev("return ThingManager.get_items().size()")
buildings = ev("var c = 0\nfor b in ThingManager._buildings:\n\tc += 1\nreturn c")
print(f"Things: {things} (plants={plants} items={items} buildings={buildings})")

# Item breakdown - which items are accumulating
item_counts = ev("var r = {}\nfor t in ThingManager.get_items():\n\tvar d = t.def_name\n\tvar c = t.stack_count if t.get(\"stack_count\") else 1\n\tif d in r:\n\t\tr[d] += c\n\telse:\n\t\tr[d] = c\nreturn r")
print(f"\nItem breakdown:")
if isinstance(item_counts, dict):
    for name, count in sorted(item_counts.items(), key=lambda x: -x[1]):
        print(f"  {name:25s}: {count}")

# Item stack counts (number of stacks)
stack_counts = ev("var r = {}\nfor t in ThingManager.get_items():\n\tvar d = t.def_name\n\tif d in r:\n\t\tr[d] += 1\n\telse:\n\t\tr[d] = 1\nreturn r")
print(f"\nStacks per type:")
if isinstance(stack_counts, dict):
    for name, count in sorted(stack_counts.items(), key=lambda x: -x[1]):
        if count > 1:
            print(f"  {name:25s}: {count} stacks")

# Tick signal connections
tick_count = ev("return TickManager.tick.get_connections().size()")
rare_count = ev("return TickManager.rare_tick.get_connections().size()")
long_count = ev("return TickManager.long_tick.get_connections().size() if TickManager.has_signal(\"long_tick\") else 0")
print(f"\nTick connections: tick={tick_count} rare={rare_count} long={long_count}")

# Check autoload count
autoload_count = ev("return get_tree().root.get_child_count()")
print(f"Autoload count: {autoload_count}")

# Animal count
animals = ev("return AnimalManager.animals.size()")
print(f"Animals: {animals}")

print(f"\n=== DONE ===")
