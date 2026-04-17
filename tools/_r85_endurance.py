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

print("=== R85 Endurance Test ===\n")

# Setup
ev("for p in ResearchManager.get_all_projects():\n\tResearchManager._complete_project(p.get(\"defName\",\"\"))")
ev("ThingManager.spawn_item_stacks(\"MealSimple\", 100, Vector2i(25, 25))\nreturn \"ok\"")
ev("CraftingManager.add_to_queue(\"SimpleClothes\", 3)")
ev("CraftingManager.add_to_queue(\"ComponentIndustrial\", 3)")
ev("for entry in CraftingManager.craft_queue:\n\tentry[\"assigned\"] = false")

tick0 = ev("return TickManager.current_tick")
c0 = ev("return CraftingManager.total_crafted")
print(f"Start: tick={tick0} crafted={c0}")
target = 1000000

# Run at 3x with periodic cleanup (8 min)
ev("TickManager.set_speed(3)")
transitions = []
last_season = ev("return SeasonManager.current_season")

for i in range(32):
    time.sleep(15)
    tick = ev("return TickManager.current_tick")
    
    if tick is None:
        print(f"  [{(i+1)*15}s] CONNECTION LOST")
        break
    
    season = ev("return SeasonManager.current_season")
    fps = ev("return Engine.get_frames_per_second()")
    things = ev("return ThingManager.things.size()")
    
    if season != last_season:
        s_old = {0:"Sp",1:"Su",2:"Fa",3:"Wi"}.get(last_season, "?")
        s_new = {0:"Sp",1:"Su",2:"Fa",3:"Wi"}.get(season, "?")
        transitions.append(f"{s_old}->{s_new}@t{tick}")
        last_season = season
    
    s_name = {0:"Sp",1:"Su",2:"Fa",3:"Wi"}.get(season, "?")
    
    # Periodic cleanup every 90s
    if (i + 1) % 6 == 0:
        for item_type in ["Wood", "MealSimple", "Leather", "Meat", "RawFood", "NutrientPaste"]:
            for _ in range(25):
                cnt = ev(f"var c = 0\nfor t in ThingManager.get_items():\n\tif t.def_name == \"{item_type}\":\n\t\tc += 1\nreturn c")
                if not isinstance(cnt, (int, float)) or int(cnt) <= 5:
                    break
                ev(f"for t in ThingManager.get_items():\n\tif t.def_name == \"{item_type}\":\n\t\tThingManager.remove_thing(t)\n\t\treturn 1\nreturn 0")
        things = ev("return ThingManager.things.size()")
    
    pct = int(tick or 0) / target * 100
    print(f"  [{(i+1)*15:3d}s] t={tick} {s_name} fps={fps} th={things} [{pct:.0f}% to 1M]")
    
    if int(tick or 0) >= target:
        print(f"  *** REACHED 1M TICKS! ***")
        break

ev("TickManager.set_speed(1)")

# Final
tick_end = ev("return TickManager.current_tick")
c_end = ev("return CraftingManager.total_crafted")
quality = ev("return CraftingManager._quality_counts")
raids = ev("return RaidManager.total_raids")

pawns = ev("var r = []\nfor p in PawnManager.pawns:\n\tif p.dead: continue\n\tif p.has_meta(\"faction\") and p.get_meta(\"faction\") == \"enemy\": continue\n\tr.append({\"name\": p.pawn_name, \"food\": p.get_need(\"Food\"), \"mood\": p.get_need(\"Mood\")})\nreturn r")

alive = len(pawns) if isinstance(pawns, list) else 0

print(f"\n=== Summary ===")
print(f"Ticks: {tick0} -> {tick_end} (+{int(tick_end or 0)-int(tick0 or 0)})")
print(f"Transitions: {transitions}")
print(f"Crafted: {c0} -> {c_end} (+{int(c_end or 0)-int(c0 or 0)})")
print(f"Raids: {raids}")
print(f"Colonists: {alive}/6")
reached = int(tick_end or 0) >= target
print(f"Target 1M: {'REACHED!' if reached else f'{int(tick_end or 0)/target*100:.0f}%'}")

ev("GameState.save_game()")
print(f"\nSaved at tick {tick_end}.")
print("\n=== DONE ===")
