import json

with open('d:/MyProject/RimWorldCopy/logs/game_raw_data.json', 'r') as f:
    data = json.load(f)

print(f"Total entries: {len(data)}")
print(f"Tick range: {data[0]['tick']} - {data[-1]['tick']}")

job_counts = {}
rest_below_30 = 0
rest_below_15 = 0
food_below_25 = 0
names_seen = set()
low_rest_no_sleep = 0

for entry in data:
    p = entry.get('pawn', entry)
    name = p.get('name', '?')
    names_seen.add(name)
    job = p.get('job', '?')
    rest = p.get('rest', 1.0)
    food = p.get('food', 1.0)
    job_counts[job] = job_counts.get(job, 0) + 1
    if rest < 0.3:
        rest_below_30 += 1
        if job not in ('Rest', 'Sleep'):
            low_rest_no_sleep += 1
    if rest < 0.15:
        rest_below_15 += 1
    if food < 0.25:
        food_below_25 += 1

print(f"\nPawns: {sorted(names_seen)}")
print(f"\n--- Job Distribution ---")
for job, count in sorted(job_counts.items(), key=lambda x: -x[1]):
    pct = count / len(data) * 100
    print(f"  {job:20s}: {count:4d} ({pct:5.1f}%)")

print(f"\n--- Need Alerts ---")
print(f"  Rest < 0.30:     {rest_below_30} entries ({rest_below_30/len(data)*100:.1f}%)")
print(f"  Rest < 0.15:     {rest_below_15} entries")
print(f"  Low rest but NOT sleeping: {low_rest_no_sleep}")
print(f"  Food < 0.25:     {food_below_25} entries")

last_10_pct = data[int(len(data)*0.9):]
late_jobs = {}
for entry in last_10_pct:
    p = entry.get('pawn', entry)
    job = p.get('job', '?')
    late_jobs[job] = late_jobs.get(job, 0) + 1
print(f"\n--- Last 10% Jobs (tick {last_10_pct[0]['tick']}+) ---")
for job, count in sorted(late_jobs.items(), key=lambda x: -x[1]):
    print(f"  {job:20s}: {count}")

print(f"\n--- Per-Pawn Rest Min ---")
pawn_rest_min = {}
for entry in data:
    p = entry.get('pawn', entry)
    name = p.get('name', '?')
    rest = p.get('rest', 1.0)
    if name not in pawn_rest_min or rest < pawn_rest_min[name]:
        pawn_rest_min[name] = rest
for name, rmin in sorted(pawn_rest_min.items(), key=lambda x: x[1]):
    print(f"  {name:12s}: {rmin:.3f}")
