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

print("=== R80 Long Season Cycle ===\n")

# Setup
ev("for p in ResearchManager.get_all_projects():\n\tResearchManager._complete_project(p.get(\"defName\",\"\"))")
for mat, count in [("MealSimple", 100), ("Steel", 300), ("Cloth", 200), ("Stone", 200), ("Wood", 200)]:
    ev(f"ThingManager.spawn_item_stacks(\"{mat}\", {count}, Vector2i(25, 25))\nreturn \"ok\"")

# Reset stuck craft queue
ev("for entry in CraftingManager.craft_queue:\n\tentry[\"assigned\"] = false")

tick0 = ev("return TickManager.current_tick")
season0 = ev("return SeasonManager.current_season")
c0 = ev("return CraftingManager.total_crafted")
s0_name = {0:"Spring",1:"Summer",2:"Fall",3:"Winter"}.get(season0, "?")
print(f"Start: tick={tick0} season={s0_name} crafted={c0}")

# Long run at 3x (5 min)
ev("TickManager.set_speed(3)")
transitions = []
last_season = season0

for i in range(20):
    time.sleep(15)
    tick = ev("return TickManager.current_tick")
    season = ev("return SeasonManager.current_season")
    fps = ev("return Engine.get_frames_per_second()")
    c = ev("return CraftingManager.total_crafted")
    gen = ev("return ElectricityGrid.get_total_generation()")
    cons = ev("return ElectricityGrid.get_total_consumption()")
    things = ev("return ThingManager.things.size()")
    raids = ev("return RaidManager.total_raids")
    
    marker = ""
    if season != last_season:
        s_old = {0:"Sp",1:"Su",2:"Fa",3:"Wi"}.get(last_season, "?")
        s_new = {0:"Sp",1:"Su",2:"Fa",3:"Wi"}.get(season, "?")
        transitions.append(f"{s_old}->{s_new}@t{tick}")
        last_season = season
        marker = f" *** {s_old}->{s_new} ***"
    
    s_name = {0:"Sp",1:"Su",2:"Fa",3:"Wi"}.get(season, "?")
    power_status = "OK" if float(gen or 0) >= float(cons or 0) else "BROWNOUT"
    
    jobs = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append(p.current_job_name)\nreturn r")
    
    job_summary = {}
    for j in (jobs or []):
        j = j or "Idle"
        job_summary[j] = job_summary.get(j, 0) + 1
    top_jobs = sorted(job_summary.items(), key=lambda x: -x[1])[:3]
    job_str = " ".join(f"{j}={c}" for j,c in top_jobs)
    
    print(f"  [{(i+1)*15:3d}s] t={tick} {s_name} fps={fps} pwr={power_status} c={c} things={things} raids={raids} {job_str}{marker}")

ev("TickManager.set_speed(1)")

# Final
tick_end = ev("return TickManager.current_tick")
c_end = ev("return CraftingManager.total_crafted")
q_end = ev("return CraftingManager.craft_queue.size()")
quality = ev("return CraftingManager._quality_counts")
gen_f = ev("return ElectricityGrid.get_total_generation()")
cons_f = ev("return ElectricityGrid.get_total_consumption()")
things = ev("return ThingManager.things.size()")
plants = ev("return ThingManager.get_plants().size()")
raids = ev("return RaidManager.total_raids")

pawns = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append({\"name\": p.pawn_name, \"job\": p.current_job_name, \"food\": p.get_need(\"Food\"), \"mood\": p.get_need(\"Mood\"), \"rest\": p.get_need(\"Rest\")})\nreturn r")

print(f"\n=== Summary ===")
print(f"Ticks: {tick0} -> {tick_end} (+{int(tick_end or 0)-int(tick0 or 0)})")
print(f"Transitions: {len(transitions)}")
for t in transitions:
    print(f"  {t}")
print(f"Crafted: {c0} -> {c_end} (+{int(c_end or 0)-int(c0 or 0)})")
print(f"Quality: {quality}")
print(f"Power: gen={gen_f}W cons={cons_f}W")
print(f"Things: {things}, Plants: {plants}")
print(f"Raids: {raids}")

if pawns:
    print(f"Colonists ({len(pawns)}):")
    for p in pawns:
        print(f"  {p['name']:8s}: {p.get('job',''):15s} food={p.get('food',0):.2f} mood={p.get('mood',0):.2f} rest={p.get('rest',0):.2f}")

ev("GameState.save_game()")
print("\nGame saved.")
print("\n=== DONE ===")
