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

print("=== Research Debug ===\n")

# Check ResearchManager existence
exists = ev("return ResearchManager != null")
print(f"ResearchManager exists: {exists}")

# Check properties
props = ev("return {\"has_projects\": ResearchManager.projects != null, \"proj_size\": ResearchManager.projects.size() if ResearchManager.projects else -1, \"completed_size\": ResearchManager.completed_projects.size() if ResearchManager.completed_projects else -1, \"current\": ResearchManager.current_project}")
print(f"Properties: {props}")

# Try direct project list
projects = ev("return ResearchManager.projects.keys() if ResearchManager.projects is Dictionary else []")
print(f"Project keys: {projects}")

# Check type of projects
ptype = ev("return typeof(ResearchManager.projects)")
print(f"Projects type: {ptype}")

# Try to iterate differently
proj_list = ev("var r = \"\"\nif ResearchManager.projects is Dictionary:\n\tfor k in ResearchManager.projects:\n\t\tr += k + \",\"\nreturn r")
print(f"Project list: {proj_list}")

# Unlock and verify
unlock_result = ev("var count = 0\nif ResearchManager.projects is Dictionary:\n\tfor k in ResearchManager.projects:\n\t\tResearchManager._complete_project(k)\n\t\tcount += 1\nreturn {\"unlocked\": count, \"completed_now\": ResearchManager.completed_projects.size()}")
print(f"Unlock result: {unlock_result}")

# Continue fast-forward for crafting completion
print(f"\n--- Continue 3x fast-forward (60s) ---")
ev("TickManager.set_speed(3)")
tick_start = ev("return TickManager.current_tick")
time.sleep(60)
tick_end = ev("return TickManager.current_tick")
fps = ev("return Engine.get_frames_per_second()")
crafted = ev("return CraftingManager.total_crafted")
queue = ev("return CraftingManager.craft_queue.size()")
things = ev("return ThingManager.things.size()")

if isinstance(tick_start, (int,float)) and isinstance(tick_end, (int,float)):
    gained = int(tick_end) - int(tick_start)
    tps = gained / 60
else:
    gained = "?"
    tps = "?"

print(f"  Ticks: {tick_start} -> {tick_end} (gained {gained})")
print(f"  TPS: {tps}")
print(f"  FPS: {fps}")
print(f"  Crafted total: {crafted}")
print(f"  Queue remaining: {queue}")
print(f"  Things: {things}")

# Check season
season = ev("return SeasonManager.get_summary()")
print(f"  Season: {season.get('current_season','?') if isinstance(season,dict) else season}")

# Check colonists
pawns = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append({\"name\": p.pawn_name, \"job\": p.current_job_name, \"food\": p.get_need(\"Food\"), \"mood\": p.get_need(\"Mood\")})\nreturn r")
if pawns:
    print(f"\n  Colonists ({len(pawns)}):")
    for p in pawns:
        print(f"    {p['name']}: job={p['job']} food={p.get('food',0):.2f} mood={p.get('mood',0):.2f}")

ev("TickManager.set_speed(1)")
print(f"\n=== DONE ===")
