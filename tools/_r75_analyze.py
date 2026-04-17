import json
from collections import Counter

with open('logs/game_raw_data.json', 'r') as f:
    data = json.load(f)

print(f"=== R75 Game Raw Data Analysis ===")
print(f"Total entries: {len(data)}")

if not data:
    print("No data!")
    exit()

# Tick range
ticks = [e.get("tick", 0) for e in data if isinstance(e.get("tick"), (int, float))]
frames = [e.get("frame", 0) for e in data]
print(f"Tick range: {min(ticks) if ticks else '?'} - {max(ticks) if ticks else '?'}")
print(f"Frame range: {min(frames)} - {max(frames)}")

# Job distribution
jobs = Counter()
pawn_jobs = {}
pawn_needs = {}
pawn_gear = {}
terrains = Counter()
zones = Counter()

for e in data:
    p = e.get("pawn", {})
    name = p.get("name", "?")
    job = p.get("job", "?")
    jobs[job] += 1
    
    if name not in pawn_jobs:
        pawn_jobs[name] = Counter()
    pawn_jobs[name][job] += 1
    
    # Track latest needs
    pawn_needs[name] = {
        "food": p.get("food", 0),
        "mood": p.get("mood", 0),
        "rest": p.get("rest", 0),
        "joy": p.get("joy", 0),
        "downed": p.get("downed", False),
        "drafted": p.get("drafted", False),
    }
    
    # Track gear
    gear = p.get("gear", {})
    if gear:
        pawn_gear[name] = gear
    
    # Track terrain/zone
    cell = p.get("cell", {})
    if cell:
        terrains[cell.get("terrain", "?")] += 1
        z = cell.get("zone", "")
        if z:
            zones[z] += 1

print(f"\n--- Job Distribution ---")
for j, c in jobs.most_common():
    pct = c / len(data) * 100
    print(f"  {j}: {c} ({pct:.1f}%)")

idle_jobs = {"Wander", "JoyActivity", ""}
productive = sum(c for j, c in jobs.items() if j not in idle_jobs)
total = sum(jobs.values())
print(f"\nProductivity: {productive}/{total} = {productive/total*100:.1f}%")

print(f"\n--- Per-Pawn Jobs ---")
for name, jcounts in sorted(pawn_jobs.items()):
    top3 = jcounts.most_common(3)
    total_p = sum(jcounts.values())
    productive_p = sum(c for j, c in jcounts.items() if j not in idle_jobs)
    print(f"  {name} ({total_p} entries, {productive_p/total_p*100:.0f}% prod): {', '.join(f'{j}={c}' for j,c in top3)}")

print(f"\n--- Latest Pawn Needs ---")
for name, needs in sorted(pawn_needs.items()):
    print(f"  {name}: food={needs['food']:.2f} mood={needs['mood']:.2f} rest={needs.get('rest',0):.2f} joy={needs.get('joy',0):.2f} downed={needs['downed']}")

print(f"\n--- Pawn Gear ---")
for name, gear in sorted(pawn_gear.items()):
    equipped = [f"{k}={v}" for k, v in gear.items() if v]
    print(f"  {name}: {', '.join(equipped) if equipped else 'none'}")

print(f"\n--- Terrain ---")
for t, c in terrains.most_common(5):
    print(f"  {t}: {c}")

print(f"\n--- Zones ---")
for z, c in zones.most_common():
    print(f"  {z}: {c}")

# Check for anomalies
print(f"\n--- Anomalies ---")
downed = [n for n, nd in pawn_needs.items() if nd.get("downed")]
low_food = [n for n, nd in pawn_needs.items() if isinstance(nd.get("food"), (int,float)) and nd["food"] < 0.2]
low_mood = [n for n, nd in pawn_needs.items() if isinstance(nd.get("mood"), (int,float)) and nd["mood"] < 0.3]
print(f"  Downed: {downed if downed else 'None'}")
print(f"  Low food (<0.2): {low_food if low_food else 'None'}")
print(f"  Low mood (<0.3): {low_mood if low_mood else 'None'}")

print(f"\n=== DONE ===")
