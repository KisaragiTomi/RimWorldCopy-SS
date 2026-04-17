import json

with open(r"d:\MyProject\RimWorldCopy\logs\game_raw_data.json", "r", encoding="utf-8") as f:
    data = json.load(f)

entries = data if isinstance(data, list) else data.get("entries", [])
print(f"Total entries: {len(entries)}")

if not entries:
    print("No data")
    exit()

e0 = entries[0]
e1 = entries[-1]
print(f"First tick: {e0.get('tick', '?')}")
print(f"Last tick: {e1.get('tick', '?')}")

pawns = set()
jobs = {}
total_jobs = 0
critical_food = 0
critical_rest = 0
critical_joy = 0
mood_perfect = 0
mood_total = 0
wander = 0

for e in entries:
    p = e.get("pawn", {})
    if isinstance(p, dict):
        name = p.get("name", "?")
        job = p.get("job", "")
        food = p.get("food", 1.0)
        rest = p.get("rest", 1.0)
        joy = p.get("joy", 1.0)
        mood = p.get("mood", 1.0)
    else:
        name = str(p)
        job = e.get("job", "")
        food = e.get("food", 1.0)
        rest = e.get("rest", 1.0)
        joy = e.get("joy", 1.0)
        mood = e.get("mood", 1.0)

    pawns.add(name)
    if job:
        jobs[job] = jobs.get(job, 0) + 1
        total_jobs += 1
    if job in ("Wander", "WanderAround"):
        wander += 1
    if food < 0.15:
        critical_food += 1
    if rest < 0.15:
        critical_rest += 1
    if joy < 0.15:
        critical_joy += 1
    mood_total += 1
    if mood >= 0.5:
        mood_perfect += 1

print(f"Unique pawns: {len(pawns)}")
print(f"Pawn names: {sorted(pawns)}")
print(f"Total job samples: {total_jobs}")
print(f"Wander: {wander} ({100 * wander / max(total_jobs, 1):.1f}%)")
print(f"Critical food: {critical_food}")
print(f"Critical rest: {critical_rest}")
print(f"Critical joy: {critical_joy}")
mood_pct = 100 * mood_perfect / max(mood_total, 1)
print(f"Mood>=0.5: {mood_perfect}/{mood_total} ({mood_pct:.0f}%)")
print("Job distribution:")
for j, c in sorted(jobs.items(), key=lambda x: -x[1]):
    print(f"  {j}: {c} ({100 * c / max(total_jobs, 1):.1f}%)")
