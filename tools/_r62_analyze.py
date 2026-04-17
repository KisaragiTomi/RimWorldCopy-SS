import json
from collections import Counter

print("=== R62 COMPREHENSIVE ANALYSIS ===\n")

with open("logs/game_raw_data.json", "r") as f:
    data = json.load(f)

print(f"Total entries: {len(data)}")
if not data:
    exit()

# Parse
jobs = Counter()
pawn_jobs = {}
food_vals = []
mood_vals = []
rest_vals = []
ticks = []
positions = Counter()
downed = []
gear_types = Counter()
terrains = Counter()

for entry in data:
    tick = entry.get("tick", 0)
    ticks.append(tick)
    p = entry.get("pawn", {})
    name = p.get("name", "?")
    job = p.get("job", "?")
    
    jobs[job] += 1
    if name not in pawn_jobs:
        pawn_jobs[name] = Counter()
    pawn_jobs[name][job] += 1
    
    food = p.get("food")
    mood = p.get("mood")
    rest = p.get("rest")
    
    if isinstance(food, (int, float)): food_vals.append(food)
    if isinstance(mood, (int, float)): mood_vals.append(mood)
    if isinstance(rest, (int, float)): rest_vals.append(rest)
    
    if p.get("downed"):
        downed.append({"tick": tick, "name": name})
    
    cell = p.get("cell", {})
    if isinstance(cell, dict):
        terrains[cell.get("terrain", "?")] += 1
    
    gear = p.get("gear", {})
    if isinstance(gear, dict):
        for slot, item in gear.items():
            if item:
                gear_types[f"{slot}:{item}"] += 1

print(f"Tick range: {min(ticks)} - {max(ticks)} (span: {max(ticks)-min(ticks)})")

# Overall job analysis
total = sum(jobs.values())
productive = ["Research", "Sow", "Harvest", "Cook", "Craft", "Haul", "Chop",
              "DeliverResources", "Clean", "TendPatient", "RangedAttack", "Hunt"]
basic = ["Rest", "Eat", "JoyActivity"]

print(f"\n=== JOB DISTRIBUTION ({total} samples) ===")
for job, count in jobs.most_common(20):
    pct = count / total * 100
    tag = " [PROD]" if job in productive else " [BASIC]" if job in basic else ""
    print(f"  {job:20s}: {count:4d} ({pct:5.1f}%){tag}")

p_count = sum(jobs.get(j, 0) for j in productive)
b_count = sum(jobs.get(j, 0) for j in basic)
idle = total - p_count - b_count
print(f"\n  Productive: {p_count}/{total} ({p_count/total*100:.1f}%)")
print(f"  Basic needs: {b_count}/{total} ({b_count/total*100:.1f}%)")
print(f"  Other/Idle: {idle}/{total} ({idle/total*100:.1f}%)")

# Per-pawn efficiency
print(f"\n=== PER-PAWN EFFICIENCY ===")
for name in sorted(pawn_jobs.keys()):
    total_p = sum(pawn_jobs[name].values())
    prod_p = sum(pawn_jobs[name].get(j, 0) for j in productive)
    top = pawn_jobs[name].most_common(3)
    s = ", ".join(f"{j}={c}" for j, c in top)
    print(f"  {name:8s}: {prod_p}/{total_p} ({prod_p/total_p*100:.0f}%) | {s}")

# Needs analysis
print(f"\n=== NEEDS ANALYSIS ===")
for label, vals in [("Food", food_vals), ("Mood", mood_vals), ("Rest", rest_vals)]:
    if vals:
        critical = sum(1 for v in vals if v < 0.15)
        low = sum(1 for v in vals if 0.15 <= v < 0.3)
        ok = sum(1 for v in vals if 0.3 <= v < 0.7)
        good = sum(1 for v in vals if v >= 0.7)
        print(f"  {label}: avg={sum(vals)/len(vals):.3f} | Good={good} OK={ok} Low={low} Critical={critical}")

# Gear analysis
print(f"\n=== GEAR ===")
for g, c in gear_types.most_common(10):
    print(f"  {g}: {c}")

# Terrain
print(f"\n=== TERRAIN ===")
for t, c in terrains.most_common(5):
    print(f"  {t}: {c}")

# Optimization opportunities
print(f"\n=== OPTIMIZATION NOTES ===")
if food_vals:
    avg_food = sum(food_vals)/len(food_vals)
    if avg_food < 0.4:
        print("  [!] Low avg food - need more farming/cooking")
    else:
        print("  [OK] Food stable")

if mood_vals:
    avg_mood = sum(mood_vals)/len(mood_vals)
    low_mood = sum(1 for v in mood_vals if v < 0.5)
    if low_mood > 0:
        print(f"  [!] {low_mood} low mood events - check colonist needs")
    else:
        print("  [OK] Mood stable")

print("\n=== ANALYSIS COMPLETE ===")
