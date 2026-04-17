import json
from collections import Counter

with open("d:/MyProject/RimWorldCopy/logs/game_raw_data.json") as f:
    data = json.load(f)

print(f"Total entries: {len(data)}")
print(f"Tick range: {data[0]['tick']} - {data[-1]['tick']}")

jobs = Counter()
pawn_names = set()
food_min = {}
rest_min = {}
mood_min = {}
eat_count = 0
rest_count = 0

for entry in data:
    p = entry["pawn"]
    name = p["name"]
    pawn_names.add(name)
    jobs[p["job"]] += 1
    
    if name not in food_min or p["food"] < food_min[name]:
        food_min[name] = p["food"]
    if name not in rest_min or p["rest"] < rest_min[name]:
        rest_min[name] = p["rest"]
    if name not in mood_min or p["mood"] < mood_min[name]:
        mood_min[name] = p["mood"]
    
    if p["job"] == "Eat":
        eat_count += 1
    if p["job"] == "Rest":
        rest_count += 1

print(f"\nPawns: {sorted(pawn_names)}")
print(f"\n=== Job Distribution ===")
total = len(data)
for job, count in jobs.most_common():
    print(f"  {job}: {count} ({count*100//total}%)")

print(f"\n=== Need Minimums ===")
for name in sorted(pawn_names):
    print(f"  {name}: food_min={food_min.get(name, '?'):.3f}, rest_min={rest_min.get(name, '?'):.3f}, mood_min={mood_min.get(name, '?'):.3f}")

print(f"\n=== Key Metrics ===")
print(f"  Eat jobs seen: {eat_count} ({eat_count*100//total}%)")
print(f"  Rest jobs seen: {rest_count} ({rest_count*100//total}%)")
critical_food = sum(1 for e in data if e["pawn"]["food"] < 0.25)
critical_rest = sum(1 for e in data if e["pawn"]["rest"] < 0.2)
print(f"  Critical food (<0.25): {critical_food}")
print(f"  Critical rest (<0.2): {critical_rest}")
