import json
from collections import Counter

with open("logs/game_raw_data.json", "r") as f:
    data = json.load(f)

print(f"=== R79 Game Raw Data Analysis ===\n")
print(f"Total records: {len(data)}")

if not data:
    print("No data!")
    exit()

tick_min = min(r.get("tick", 0) for r in data)
tick_max = max(r.get("tick", 0) for r in data)
print(f"Tick range: {tick_min} - {tick_max} ({tick_max - tick_min} ticks)")

# Job distribution
jobs = Counter()
for r in data:
    pawn = r.get("pawn", {})
    job = pawn.get("job", "Unknown")
    jobs[job] += 1

print(f"\n--- Job Distribution ---")
total = sum(jobs.values())
for job, count in jobs.most_common():
    pct = count / total * 100
    print(f"  {job:20s}: {count:4d} ({pct:5.1f}%)")

# Idle/Wander check
idle_count = jobs.get("", 0) + jobs.get("Wander", 0) + jobs.get("Idle", 0)
print(f"\nIdle/Wander: {idle_count} ({idle_count/total*100:.1f}%)")

# Productive work
productive = sum(count for job, count in jobs.items() 
    if job in ["Sow", "Harvest", "Cook", "Craft", "Hunt", "Haul", "Mine", "Chop", 
               "Research", "Construct", "DeliverResources", "Clean", "Repair", 
               "TendPatient", "Butcher", "Deconstruct"])
print(f"Productive: {productive} ({productive/total*100:.1f}%)")

# Needs analysis
food_values = [r["pawn"]["food"] for r in data if "pawn" in r and "food" in r["pawn"]]
mood_values = [r["pawn"]["mood"] for r in data if "pawn" in r and "mood" in r["pawn"]]
rest_values = [r["pawn"]["rest"] for r in data if "pawn" in r and "rest" in r["pawn"]]

if food_values:
    print(f"\n--- Needs ---")
    print(f"  Food: min={min(food_values):.2f} avg={sum(food_values)/len(food_values):.2f} max={max(food_values):.2f}")
if mood_values:
    print(f"  Mood: min={min(mood_values):.2f} avg={sum(mood_values)/len(mood_values):.2f} max={max(mood_values):.2f}")
if rest_values:
    print(f"  Rest: min={min(rest_values):.2f} avg={sum(rest_values)/len(rest_values):.2f} max={max(rest_values):.2f}")

# Critical needs events
critical_food = sum(1 for v in food_values if v < 0.25)
critical_rest = sum(1 for v in rest_values if v < 0.2)
low_mood = sum(1 for v in mood_values if v < 0.3)
print(f"\n  Critical food (<0.25): {critical_food} ({critical_food/len(food_values)*100:.1f}%)")
print(f"  Critical rest (<0.2): {critical_rest} ({critical_rest/len(rest_values)*100:.1f}%)" if rest_values else "")
print(f"  Low mood (<0.3): {low_mood} ({low_mood/len(mood_values)*100:.1f}%)" if mood_values else "")

# Gear check
gear_equipped = Counter()
for r in data[-50:]:
    pawn = r.get("pawn", {})
    gear = pawn.get("gear", {})
    for slot, item in gear.items():
        if item:
            gear_equipped[f"{slot}:{item}"] += 1

if gear_equipped:
    print(f"\n--- Recent Gear (last 50) ---")
    for g, c in gear_equipped.most_common(10):
        print(f"  {g}: {c}")

# Terrain distribution
terrain_counter = Counter()
for r in data:
    cell = r.get("pawn", {}).get("cell", {})
    terrain = cell.get("terrain", "Unknown")
    terrain_counter[terrain] += 1

print(f"\n--- Terrain Activity ---")
for t, c in terrain_counter.most_common(10):
    print(f"  {t:15s}: {c:4d} ({c/total*100:.1f}%)")

# Zone activity
zone_counter = Counter()
for r in data:
    cell = r.get("pawn", {}).get("cell", {})
    zone = cell.get("zone", None)
    zone_counter[str(zone)] += 1

print(f"\n--- Zone Activity ---")
for z, c in zone_counter.most_common():
    print(f"  {z:15s}: {c:4d} ({c/total*100:.1f}%)")

print(f"\n=== DONE ===")
