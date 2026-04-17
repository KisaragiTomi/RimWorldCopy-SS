import json
from collections import Counter

print("=== R56 DATA ANALYSIS ===\n")

with open("logs/game_raw_data.json", "r") as f:
    data = json.load(f)

print(f"Total entries: {len(data)}")
if not data:
    exit()

# Parse nested
jobs = Counter()
pawn_jobs = {}
food_vals = []
mood_vals = []
rest_vals = []
ticks = []
downed_events = []

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
    
    if isinstance(food, (int, float)):
        food_vals.append(food)
    if isinstance(mood, (int, float)):
        mood_vals.append(mood)
    if isinstance(rest, (int, float)):
        rest_vals.append(rest)
    
    if p.get("downed"):
        downed_events.append({"tick": tick, "name": name, "job": job})

print(f"Tick range: {min(ticks)} - {max(ticks)} (span: {max(ticks)-min(ticks)})")

# Job distribution
print(f"\n--- Jobs ({sum(jobs.values())} samples) ---")
productive = ["Research", "Sow", "Harvest", "Cook", "Craft", "Haul", "Chop",
              "DeliverResources", "Clean", "TendPatient", "RangedAttack", "Hunt"]
for job, count in jobs.most_common(20):
    pct = count / sum(jobs.values()) * 100
    tag = " [P]" if job in productive else ""
    print(f"  {job:20s}: {count:4d} ({pct:5.1f}%){tag}")

total = sum(jobs.values())
p_count = sum(jobs.get(j, 0) for j in productive)
idle_jobs = ["Wander", "Idle", "None"]
i_count = sum(jobs.get(j, 0) for j in idle_jobs)
print(f"\n  Productive: {p_count}/{total} ({p_count/total*100:.1f}%)")
print(f"  Idle: {i_count}/{total} ({i_count/total*100:.1f}%)")

# Per-pawn
print("\n--- Per-Pawn ---")
for name in sorted(pawn_jobs.keys()):
    top = pawn_jobs[name].most_common(4)
    s = ", ".join(f"{j}={c}" for j, c in top)
    total_p = sum(pawn_jobs[name].values())
    prod_p = sum(pawn_jobs[name].get(j, 0) for j in productive)
    print(f"  {name:8s}: {s}  [{prod_p}/{total_p}={prod_p/total_p*100:.0f}%]")

# Needs
print("\n--- Needs ---")
for label, vals in [("Food", food_vals), ("Mood", mood_vals), ("Rest", rest_vals)]:
    if vals:
        low = sum(1 for v in vals if v < 0.2)
        print(f"  {label}: avg={sum(vals)/len(vals):.3f} min={min(vals):.3f} max={max(vals):.3f} critical(<0.2)={low}")

# Downed events
if downed_events:
    print(f"\n--- Downed Events ({len(downed_events)}) ---")
    for d in downed_events[:5]:
        print(f"  Tick {d['tick']}: {d['name']} (job={d['job']})")

print("\n=== DONE ===")
