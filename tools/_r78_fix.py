import socket, json, time, subprocess, os

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

print("=== R78 Fix & Verify ===\n")

# 1. Save before restart
print("Saving game...")
ev("GameState.save_game()")
time.sleep(2)

# 2. Kill and restart Godot
print("Restarting Godot...")
subprocess.run(["taskkill", "/F", "/IM", "godot.windows.editor.x86_64.exe"], 
               capture_output=True, timeout=5)
time.sleep(3)

godot = os.path.join(os.environ.get("GODOT_SOURCE", ""), "bin", "godot.windows.editor.x86_64.exe")
project = r"d:\MyProject\RimWorldCopy"
subprocess.Popen([godot, "--path", project, "res://scenes/main.tscn"], 
                 cwd=project, creationflags=0x00000010)

print("Waiting for game startup...")
for i in range(30):
    time.sleep(2)
    r = ev("return 'alive'")
    if r == "alive":
        print(f"  Game ready after {(i+1)*2}s")
        break
else:
    print("  TIMEOUT waiting for game")
    exit(1)

time.sleep(3)

# 3. Unlock all research
ev("for p in ResearchManager.projects:\n\tResearchManager._complete_project(p)")

# 4. Spawn missing materials (Cloth, Stone, extra Steel)
ev("ThingManager.spawn_item_stacks([{\"def_name\":\"Cloth\",\"count\":200},{\"def_name\":\"Stone\",\"count\":200},{\"def_name\":\"Steel\",\"count\":200},{\"def_name\":\"MealSimple\",\"count\":50}])")

# 5. Unassign all stuck craft entries
ev("for entry in CraftingManager.craft_queue:\n\tentry[\"assigned\"] = false")

# 6. Verify state
queue = ev("return CraftingManager.craft_queue.size()")
crafted = ev("return CraftingManager.total_crafted")
tick = ev("return TickManager.current_tick")

print(f"\nPost-restart: tick={tick} queue={queue} crafted={crafted}")

# Check materials now
mats = ev("var r = {}\nfor t in ThingManager.things:\n\tif t is Item and t.def_name in [\"Steel\",\"Cloth\",\"Stone\",\"Wood\",\"Components\",\"Leather\"]:\n\t\tvar d = t.def_name\n\t\tvar c = t.stack_count if t.get(\"stack_count\") else 1\n\t\tif d in r:\n\t\t\tr[d] += c\n\t\telse:\n\t\t\tr[d] = c\nreturn r")
print(f"Materials: {mats}")

# Check queue entries
for i in range(min(5, int(queue or 0))):
    item = ev(f"return CraftingManager.craft_queue[{i}]")
    print(f"  queue[{i}]: {item}")

# 7. Run at 3x for 60s to verify crafting
print("\n--- Testing crafting at 3x speed (60s) ---")
ev("TickManager.set_speed(3)")

for i in range(4):
    time.sleep(15)
    c = ev("return CraftingManager.total_crafted")
    qs = ev("return CraftingManager.craft_queue.size()")
    jobs = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append(p.pawn_name + \":\" + p.current_job_name)\nreturn r")
    print(f"  [{(i+1)*15}s] crafted={c} queue={qs} jobs={jobs}")

ev("TickManager.set_speed(1)")

# Final
crafted_end = ev("return CraftingManager.total_crafted")
queue_end = ev("return CraftingManager.craft_queue.size()")
print(f"\nFinal: crafted={crafted_end} queue={queue_end}")
print(f"Craft gain: +{int(crafted_end or 0) - int(crafted or 0)}")

print("\n=== DONE ===")
