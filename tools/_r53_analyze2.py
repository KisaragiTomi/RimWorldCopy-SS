import json
from collections import Counter

print("=== R53 DATA ANALYSIS (v2) ===\n")

with open("logs/game_raw_data.json", "r") as f:
    data = json.load(f)

print(f"Total entries: {len(data)}")
if not data:
    exit()

sample = data[0]
print(f"Top keys: {list(sample.keys())}")
pawn_data = sample.get("pawn", {})
print(f"Pawn keys: {list(pawn_data.keys())}")
print(f"Sample pawn: {json.dumps(pawn_data, default=str)[:300]}\n")

# Parse nested structure
jobs = Counter()
pawn_jobs = {}
food_vals = []
mood_vals = []
rest_vals = []
joy_vals = []
terrains = Counter()
ticks = []
gear_counts = Counter()

for entry in data:
    tick = entry.get("tick", 0)
    ticks.append(tick)
    p = entry.get("pawn", {})
    
    name = p.get("name", "?")
    job = p.get("job", p.get("current_job", "?"))
    
    jobs[job] += 1
    if name not in pawn_jobs:
        pawn_jobs[name] = Counter()
    pawn_jobs[name][job] += 1
    
    food = p.get("food")
    mood = p.get("mood")
    rest = p.get("rest")
    joy = p.get("joy")
    
    if isinstance(food, (int, float)):
        food_vals.append(food)
    if isinstance(mood, (int, float)):
        mood_vals.append(mood)
    if isinstance(rest, (int, float)):
        rest_vals.append(rest)
    if isinstance(joy, (int, float)):
        joy_vals.append(joy)
    
    cell = p.get("cell", {})
    if isinstance(cell, dict):
        t = cell.get("terrain", "?")
        terrains[t] += 1
    
    gear = p.get("gear", {})
    if isinstance(gear, dict):
        for slot, item in gear.items():
            if item:
                gear_counts[f"{slot}:{item}"] += 1

print(f"Tick range: {min(ticks)} - {max(ticks)} (span: {max(ticks)-min(ticks)})")

print(f"\n--- Jobs ({sum(jobs.values())} samples) ---")
for job, count in jobs.most_common(20):
    pct = count / sum(jobs.values()) * 100
    print(f"  {job:20s}: {count:4d} ({pct:5.1f}%)")

productive = ["Research", "Sow", "Harvest", "Cook", "Craft", "Haul", "Chop",
              "DeliverResources", "Clean", "TendPatient", "RangedAttack", "Hunt"]
idle = ["Wander", "Idle", "None"]
p_count = sum(jobs.get(j, 0) for j in productive)
i_count = sum(jobs.get(j, 0) for j in idle)
total = sum(jobs.values())
if total > 0:
    print(f"\nProductive: {p_count}/{total} ({p_count/total*100:.1f}%)")
    print(f"Idle: {i_count}/{total} ({i_count/total*100:.1f}%)")

print("\n--- Per-Pawn ---")
for name in sorted(pawn_jobs.keys()):
    top = pawn_jobs[name].most_common(3)
    s = ", ".join(f"{j}={c}" for j, c in top)
    print(f"  {name:8s}: {s}")

print("\n--- Needs ---")
for label, vals in [("Food", food_vals), ("Mood", mood_vals), ("Rest", rest_vals), ("Joy", joy_vals)]:
    if vals:
        print(f"  {label}: avg={sum(vals)/len(vals):.3f} min={min(vals):.3f} max={max(vals):.3f} (n={len(vals)})")

print("\n--- Terrain ---")
for t, c in terrains.most_common(10):
    print(f"  {t}: {c}")

print("\n--- Gear ---")
for g, c in gear_counts.most_common(10):
    print(f"  {g}: {c}")

print("\n=== DONE ===")
