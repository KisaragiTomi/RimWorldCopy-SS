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

print("=== Plant Count Tracking ===\n")

# Set speed to 1 for controlled testing
ev("TickManager.set_speed(1)")

# Track plant count over time
for i in range(10):
    plants = ev("return ThingManager.get_plants().size()")
    things = ev("return ThingManager.things.size()")
    tick = ev("return TickManager.current_tick")
    
    # Count by type
    types = ev("var r = {}\nfor t in ThingManager.get_plants():\n\tvar p = t as Plant\n\tvar n = p.def_name\n\tif not r.has(n): r[n] = 0\n\tr[n] += 1\nreturn r")
    
    print(f"  [{i}] tick={tick} plants={plants} things={things} types={types}")
    time.sleep(3)

# Now try 3x for 30s
print("\n--- 3x speed 30s ---")
p_before = ev("return ThingManager.get_plants().size()")
tick_before = ev("return TickManager.current_tick")
ev("TickManager.set_speed(3)")
time.sleep(30)
p_after = ev("return ThingManager.get_plants().size()")
tick_after = ev("return TickManager.current_tick")
things_after = ev("return ThingManager.things.size()")
types_after = ev("var r = {}\nfor t in ThingManager.get_plants():\n\tvar p = t as Plant\n\tvar n = p.def_name\n\tif not r.has(n): r[n] = 0\n\tr[n] += 1\nreturn r")
ev("TickManager.set_speed(1)")

print(f"  Plants: {p_before} -> {p_after} (diff: {int(p_after or 0) - int(p_before or 0)})")
print(f"  Ticks: {tick_before} -> {tick_after}")
print(f"  Things: {things_after}")
print(f"  Types: {types_after}")

print(f"\n=== DONE ===")
