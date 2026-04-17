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

print("=== R78 Craft Debug 2 ===\n")

# Simple queue check
qs = ev("return CraftingManager.craft_queue.size()")
print(f"Queue size: {qs}")

tc = ev("return CraftingManager.total_crafted")
print(f"Total crafted: {tc}")

# Queue items - try different access patterns
if qs and int(qs) > 0:
    for i in range(min(int(qs), 5)):
        item = ev(f"return CraftingManager.craft_queue[{i}]")
        print(f"  queue[{i}]: {item}")

# All building def names
blds = ev("var r = []\nfor t in ThingManager.things:\n\tif t is Building:\n\t\tr.append(t.def_name)\nreturn r")
print(f"\nAll buildings: {blds}")

# Check if workbenches exist using _buildings
blds2 = ev("var r = []\nfor b in ThingManager._buildings:\n\tr.append(b.def_name)\nreturn r")
print(f"_buildings: {blds2}")

# Check JobGiverCraft source code structure
bench_defs = ev("return JobGiverCraft.BENCH_DEFS if \"BENCH_DEFS\" in JobGiverCraft else \"no_attr\"")
print(f"\nBENCH_DEFS: {bench_defs}")

# Check all thing def names
all_defs = ev("var r = {}\nfor t in ThingManager.things:\n\tvar d = t.def_name\n\tif d in r:\n\t\tr[d] += 1\n\telse:\n\t\tr[d] = 1\nreturn r")
print(f"\nAll thing defs: {all_defs}")
