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

print("=== R76 Final Benchmark ===\n")

# Unlock research
ev("for p in ResearchManager.projects:\n\tResearchManager._complete_project(p)")

# Check how many pawns (including enemies)
total_pawns = ev("return PawnManager.pawns.size()")
alive_pawns = ev("var c = 0\nfor p in PawnManager.pawns:\n\tif not p.dead: c += 1\nreturn c")
enemy_pawns = ev("var c = 0\nfor p in PawnManager.pawns:\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": c += 1\nreturn c")
print(f"Pawns: total={total_pawns} alive={alive_pawns} enemies={enemy_pawns}")

# Clean up dead/enemy pawns
ev("var to_remove = []\nfor p in PawnManager.pawns:\n\tif p.dead or (p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\"):\n\t\tto_remove.append(p)\nfor p in to_remove:\n\tPawnManager.pawns.erase(p)")

pawns_after = ev("return PawnManager.pawns.size()")
print(f"Pawns after cleanup: {pawns_after}")

# Benchmark 1x, 2x, 3x
for speed in [1, 2, 3]:
    ev(f"TickManager.set_speed({speed})")
    time.sleep(5)
    fps = ev("return Engine.get_frames_per_second()")
    tick = ev("return TickManager.current_tick")
    things = ev("return ThingManager.things.size()")
    print(f"  {speed}x: FPS={fps} tick={tick} things={things}")

# Extended 3x
print("\n--- Extended 3x (60s) ---")
ev("TickManager.set_speed(3)")
tick_start = ev("return TickManager.current_tick")
for i in range(4):
    time.sleep(15)
    fps = ev("return Engine.get_frames_per_second()")
    things = ev("return ThingManager.things.size()")
    plants = ev("return ThingManager.get_plants().size()")
    tick = ev("return TickManager.current_tick")
    
    pawns = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append(p.current_job_name)\nreturn r")
    
    print(f"  [{(i+1)*15}s] fps={fps} tick={tick} things={things} plants={plants} jobs={pawns}")

tick_end = ev("return TickManager.current_tick")
if isinstance(tick_start, (int,float)) and isinstance(tick_end, (int,float)):
    tps = (int(tick_end) - int(tick_start)) / 60
    print(f"\n  TPS: {tps:.0f}")

# Final colonist check
pawns = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append({\"name\": p.pawn_name, \"job\": p.current_job_name, \"food\": p.get_need(\"Food\"), \"mood\": p.get_need(\"Mood\")})\nreturn r")
if pawns:
    print(f"\n  Colonists ({len(pawns)}):")
    for p in pawns:
        print(f"    {p['name']}: job={p['job']} food={p.get('food',0):.2f} mood={p.get('mood',0):.2f}")

ev("TickManager.set_speed(1)")
print(f"\n=== DONE ===")
