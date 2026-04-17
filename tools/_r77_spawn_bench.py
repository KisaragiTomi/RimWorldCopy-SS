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

print("=== Spawn Crafting Benches ===\n")

# Spawn a CraftingSpot
result = ev("var b = Building.new(\"CraftingSpot\")\nb.build_state = Building.BuildState.COMPLETE\nThingManager.spawn_thing(b, Vector2i(58, 58))\nreturn \"spawned\"")
print(f"CraftingSpot: {result}")

# Spawn a Smithy
result2 = ev("var b = Building.new(\"Smithy\")\nb.build_state = Building.BuildState.COMPLETE\nThingManager.spawn_thing(b, Vector2i(56, 58))\nreturn \"spawned\"")
print(f"Smithy: {result2}")

# Spawn a TailoringBench
result3 = ev("var b = Building.new(\"TailoringBench\")\nb.build_state = Building.BuildState.COMPLETE\nThingManager.spawn_thing(b, Vector2i(54, 58))\nreturn \"spawned\"")
print(f"TailoringBench: {result3}")

time.sleep(0.5)

# Check bench count now
bench_count = ev("var c = 0\nfor t in ThingManager.things:\n\tif t is Building:\n\t\tvar b = t as Building\n\t\tif b.build_state == Building.BuildState.COMPLETE and b.def_name in [\"CraftingSpot\",\"TailoringBench\",\"Smithy\",\"MachiningTable\"]:\n\t\t\tc += 1\nreturn c")
print(f"\nBench count: {bench_count}")

# Check can_craft now
can = ev("return CraftingManager.can_craft(\"Flak_Vest\", PawnManager.pawns[5])")
has = ev("return CraftingManager.has_ingredients(\"Flak_Vest\")")
print(f"Flak_Vest: can_craft={can} has_ingredients={has}")

can2 = ev("return CraftingManager.can_craft(\"SimpleClothes\", PawnManager.pawns[5])")
has2 = ev("return CraftingManager.has_ingredients(\"SimpleClothes\")")
print(f"SimpleClothes: can_craft={can2} has_ingredients={has2}")

# Check what materials exist
materials = ev("var r = {}\nfor t in ThingManager.things:\n\tif t is Item:\n\t\tvar n = t.def_name\n\t\tif not r.has(n): r[n] = 0\n\t\tr[n] += t.stack_count\nreturn r")
print(f"\nMaterials: {materials}")

# Spawn needed materials
ev("ThingManager.spawn_item_stacks([{\"def_name\":\"Steel\",\"count\":200},{\"def_name\":\"Cloth\",\"count\":100},{\"def_name\":\"Wood\",\"count\":200},{\"def_name\":\"Components\",\"count\":50},{\"def_name\":\"Leather\",\"count\":100}])")
time.sleep(0.5)

has3 = ev("return CraftingManager.has_ingredients(\"Flak_Vest\")")
has4 = ev("return CraftingManager.has_ingredients(\"SimpleClothes\")")
has5 = ev("return CraftingManager.has_ingredients(\"SteelSword\")")
print(f"\nAfter material spawn:")
print(f"  Flak_Vest: has_ingredients={has3}")
print(f"  SimpleClothes: has_ingredients={has4}")
print(f"  SteelSword: has_ingredients={has5}")

# Fast-forward and verify crafting happens
print(f"\n--- 3x fast-forward 60s ---")
ev("TickManager.set_speed(3)")
for i in range(4):
    time.sleep(15)
    tick = ev("return TickManager.current_tick")
    crafted = ev("return CraftingManager.total_crafted")
    queue = ev("return CraftingManager.craft_queue.size()")
    fps = ev("return Engine.get_frames_per_second()")
    
    pawns = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append(p.current_job_name)\nreturn r")
    
    print(f"  [{(i+1)*15}s] tick={tick} fps={fps} crafted={crafted} queue={queue} jobs={pawns}")

ev("TickManager.set_speed(1)")
print(f"\n=== DONE ===")
