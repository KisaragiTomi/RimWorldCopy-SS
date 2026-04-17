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

print("=== Craft Debug ===\n")

# Check each pawn's crafting capability
for i in range(6):
    capable = ev(f"return PawnManager.pawns[{i}].is_capable_of(\"Crafting\")")
    name = ev(f"return PawnManager.pawns[{i}].pawn_name")
    skill = ev(f"return PawnManager.pawns[{i}].get_skill_level(\"Crafting\")")
    print(f"  {name}: capable={capable} skill={skill}")

# Check can_craft for each recipe
queue_items = ev("var r = []\nfor item in CraftingManager.craft_queue:\n\tr.append(item.recipe)\nreturn r")
print(f"\nQueue: {queue_items}")

if queue_items:
    recipe = queue_items[0] if isinstance(queue_items, list) else "Flak_Vest"
    can_craft = ev(f"return CraftingManager.can_craft(\"{recipe}\", PawnManager.pawns[0])")
    has_ing = ev(f"return CraftingManager.has_ingredients(\"{recipe}\")")
    print(f"\n  Recipe '{recipe}': can_craft={can_craft} has_ingredients={has_ing}")

# Check available benches
benches = ev("var r = []\nfor t in ThingManager.things:\n\tif t is Building:\n\t\tvar b = t as Building\n\t\tif b.build_state == Building.BuildState.COMPLETE:\n\t\t\tr.append(b.def_name)\nreturn r")
print(f"\nBuildings on map: {benches}")

# Check BENCH_DEFS match
bench_count = ev("var c = 0\nfor t in ThingManager.things:\n\tif t is Building:\n\t\tvar b = t as Building\n\t\tif b.build_state == Building.BuildState.COMPLETE and b.def_name in [\"CraftingSpot\",\"TailoringBench\",\"Smithy\",\"MachiningTable\",\"FabricationBench\",\"StonecuttersTable\",\"DrugLab\",\"BreweryVat\",\"AdvancedComponentAssembly\"]:\n\t\t\tc += 1\nreturn c")
print(f"Bench count: {bench_count}")

# Try to directly call try_issue_job
result = ev("var giver = JobGiverCraft.new()\nreturn giver.get_craft_summary()")
print(f"\nCraft summary: {json.dumps(result, indent=2) if result else result}")

print(f"\n=== DONE ===")
