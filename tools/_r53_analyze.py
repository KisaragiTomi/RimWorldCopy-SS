import json
from collections import Counter

print("=== R53 game_raw_data ANALYSIS ===\n")

with open("logs/game_raw_data.json", "r") as f:
    data = json.load(f)

print(f"Total entries: {len(data)}")
if not data:
    print("No data!")
    exit()

# Determine structure
sample = data[0]
print(f"Sample keys: {list(sample.keys())[:10]}")
print(f"Sample: {json.dumps(sample, default=str)[:200]}")

# Aggregate jobs
jobs = Counter()
needs_sum = {"Food": [], "Mood": [], "Rest": [], "Joy": []}
pawn_jobs = {}
ticks = []

for entry in data:
    pname = entry.get("pawn_name", entry.get("name", "?"))
    job = entry.get("current_job_name", entry.get("job", "?"))
    tick = entry.get("tick", 0)
    
    jobs[job] += 1
    ticks.append(tick)
    
    if pname not in pawn_jobs:
        pawn_jobs[pname] = Counter()
    pawn_jobs[pname][job] += 1
    
    for need in ["Food", "Mood", "Rest", "Joy"]:
        val = entry.get(need, entry.get(need.lower()))
        if isinstance(val, (int, float)):
            needs_sum[need].append(val)

# Tick range
if ticks:
    print(f"\nTick range: {min(ticks)} - {max(ticks)} ({max(ticks)-min(ticks)} span)")

# Job distribution
print(f"\n--- Job Distribution ({sum(jobs.values())} samples) ---")
for job, count in jobs.most_common(20):
    pct = count / sum(jobs.values()) * 100
    print(f"  {job:20s}: {count:5d} ({pct:5.1f}%)")

# Productive vs idle
productive = ["Research", "Sow", "Harvest", "Cook", "Craft", "Haul", "Chop",
              "DeliverResources", "Clean", "TendPatient", "RangedAttack", "Hunt"]
idle = ["Wander", "Idle", "None"]
p_count = sum(jobs.get(j, 0) for j in productive)
i_count = sum(jobs.get(j, 0) for j in idle)
total = sum(jobs.values())
print(f"\nProductive: {p_count} ({p_count/total*100:.1f}%)")
print(f"Idle/Wander: {i_count} ({i_count/total*100:.1f}%)")
print(f"Other: {total-p_count-i_count} ({(total-p_count-i_count)/total*100:.1f}%)")

# Per-pawn jobs
print("\n--- Per-Pawn Top Jobs ---")
for pname in sorted(pawn_jobs.keys()):
    top3 = pawn_jobs[pname].most_common(3)
    jobs_str = ", ".join(f"{j}={c}" for j, c in top3)
    print(f"  {pname:8s}: {jobs_str}")

# Needs averages
print("\n--- Avg Needs ---")
for need, vals in needs_sum.items():
    if vals:
        print(f"  {need}: avg={sum(vals)/len(vals):.2f} min={min(vals):.2f} max={max(vals):.2f}")

print("\n=== ANALYSIS COMPLETE ===")
