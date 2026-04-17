import json, collections

with open(r"d:\MyProject\RimWorldCopy\logs\game_raw_data.json", "r", encoding="utf-8") as f:
    data = json.load(f)

print(f"Total entries: {len(data)}")
print(f"Tick range: {data[0]['tick']} - {data[-1]['tick']}")

jobs = collections.Counter()
pawns = set()
food_crit = 0
rest_crit = 0
mood_min = {}
food_min = {}
rest_min = {}

for e in data:
    p = e.get("pawn", {})
    if isinstance(p, dict):
        name = p.get("name", "?")
        job = p.get("job", "None")
        food = p.get("food", 1.0)
        rest = p.get("rest", 1.0)
        mood = p.get("mood", 1.0)
    else:
        name = str(p)
        job = e.get("job", "None")
        food = e.get("food", 1.0)
        rest = e.get("rest", 1.0)
        mood = e.get("mood", 1.0)
    pawns.add(name)
    jobs[job] += 1
    if food < 0.2:
        food_crit += 1
    if rest < 0.2:
        rest_crit += 1
    if name not in mood_min or mood < mood_min[name]:
        mood_min[name] = mood
    if name not in food_min or food < food_min[name]:
        food_min[name] = food
    if name not in rest_min or rest < rest_min[name]:
        rest_min[name] = rest

total = len(data)
print(f"\nPawns ({len(pawns)}): {sorted(pawns)}")
print(f"\nJob distribution:")
for job, cnt in jobs.most_common():
    print(f"  {job}: {cnt} ({cnt*100//total}%)")

print(f"\nCritical food (<0.2): {food_crit}")
print(f"Critical rest (<0.2): {rest_crit}")

print(f"\nPer-pawn minimums:")
for name in sorted(pawns):
    print(f"  {name}: food={food_min.get(name,1):.3f} rest={rest_min.get(name,1):.3f} mood={mood_min.get(name,1):.3f}")
