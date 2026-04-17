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

print("=== R75 Tech Verification v2 ===\n")

# Unlock all research
unlock = ev("var unlocked = 0\nfor p in ResearchManager.projects:\n\tif not ResearchManager.is_completed(p):\n\t\tResearchManager._complete_project(p)\n\t\tunlocked += 1\nreturn {\"unlocked\": unlocked, \"total\": ResearchManager.projects.size(), \"completed\": ResearchManager.completed_projects.size()}")
print(f"Research unlock: {unlock}")

# List completed projects
completed = ev("var r = []\nfor p in ResearchManager.completed_projects:\n\tr.append(p)\nreturn r")
print(f"Completed projects ({len(completed) if completed else 0}): {completed}")

# Check all project names
projects = ev("var r = []\nfor p in ResearchManager.projects:\n\tr.append(p)\nreturn r")
print(f"All projects ({len(projects) if projects else 0}): {projects}")

# Building types from ThingManager
bld_types = ev("var types = {}\nfor t in ThingManager.things:\n\tvar n = t.def_name\n\tif not types.has(n):\n\t\ttypes[n] = 0\n\ttypes[n] += 1\nreturn types")
print(f"\nThings breakdown: {bld_types}")

# Get recipes
recipes = ev("var r = []\nfor key in CraftingManager.RECIPES:\n\tr.append(key)\nreturn r")
print(f"\nRecipe keys: {recipes}")

# Spawn test materials and queue crafting
ev("ThingManager.spawn_item_stacks([{\"def_name\":\"Steel\",\"count\":100},{\"def_name\":\"Cloth\",\"count\":50},{\"def_name\":\"Wood\",\"count\":100},{\"def_name\":\"Components\",\"count\":20},{\"def_name\":\"Leather\",\"count\":50}])")
time.sleep(0.5)

# Queue crafting items to verify
if recipes:
    for r in recipes[:7]:
        result = ev(f"return CraftingManager.add_to_queue(\"{r}\", 1)")
        print(f"  Queue {r}: {result}")

queue = ev("return CraftingManager.craft_queue.size()")
print(f"\nCraft queue size: {queue}")

# Fast-forward to let crafting happen
print("\n--- Fast-forward 30s at 3x for crafting ---")
ev("TickManager.set_speed(3)")
time.sleep(30)
crafted = ev("return CraftingManager.total_crafted")
queue_after = ev("return CraftingManager.craft_queue.size()")
fps = ev("return Engine.get_frames_per_second()")
tick = ev("return TickManager.current_tick")
print(f"  Crafted: {crafted}")
print(f"  Queue remaining: {queue_after}")
print(f"  FPS: {fps}")
print(f"  Tick: {tick}")

# Quality stats
quality = ev("return CraftingManager.quality_stats")
print(f"  Quality stats: {quality}")

ev("TickManager.set_speed(1)")
print(f"\n=== DONE ===")
