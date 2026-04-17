import json
from collections import Counter

with open('logs/game_raw_data.json', 'r') as f:
    data = json.load(f)

print(f'=== R77 Game Data Analysis ===')
print(f'Entries: {len(data)}')
ticks = [e.get('tick', 0) for e in data if isinstance(e.get('tick'), (int, float))]
print(f'Tick range: {min(ticks) if ticks else "?"} - {max(ticks) if ticks else "?"}')

jobs = Counter()
pawn_jobs = {}
pawn_needs = {}
for e in data:
    p = e.get('pawn', {})
    name = p.get('name', '?')
    job = p.get('job', '?')
    jobs[job] += 1
    if name not in pawn_jobs:
        pawn_jobs[name] = Counter()
    pawn_jobs[name][job] += 1
    pawn_needs[name] = {
        'food': p.get('food', 0),
        'mood': p.get('mood', 0),
    }

print(f'\nJobs:')
for j, c in jobs.most_common():
    print(f'  {j}: {c} ({c / len(data) * 100:.1f}%)')

idle = {'Wander', 'JoyActivity', ''}
productive = sum(c for j, c in jobs.items() if j not in idle)
total = sum(jobs.values())
print(f'\nProductivity: {productive}/{total} = {productive / total * 100:.1f}%')

print(f'\nPer-pawn:')
for name in sorted(pawn_jobs):
    jc = pawn_jobs[name]
    total_p = sum(jc.values())
    prod_p = sum(c for j, c in jc.items() if j not in idle)
    top = jc.most_common(3)
    print(f'  {name} ({prod_p / total_p * 100:.0f}% prod): {", ".join(f"{j}={c}" for j, c in top)}')

print(f'\nLatest needs:')
for name in sorted(pawn_needs):
    n = pawn_needs[name]
    print(f'  {name}: food={n["food"]:.2f} mood={n["mood"]:.2f}')

print(f'\n=== DONE ===')
