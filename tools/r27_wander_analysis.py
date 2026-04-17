import json

with open("d:/MyProject/RimWorldCopy/logs/game_raw_data.json", "r") as f:
    data = json.load(f)

from collections import Counter

wander_by_pawn = Counter()
total_by_pawn = Counter()
empty_by_pawn = Counter()
joy_by_pawn = Counter()

for e in data:
    name = e["pawn"]["name"]
    job = e["pawn"]["job"]
    total_by_pawn[name] += 1
    if job == "Wander":
        wander_by_pawn[name] += 1
    elif job == "":
        empty_by_pawn[name] += 1
    elif job == "JoyActivity":
        joy_by_pawn[name] += 1

print("=== Wander by pawn ===")
for name in sorted(total_by_pawn.keys()):
    w = wander_by_pawn.get(name, 0)
    e = empty_by_pawn.get(name, 0)
    j = joy_by_pawn.get(name, 0)
    t = total_by_pawn[name]
    print(f"  {name:10s}: Wander={w}/{t} ({100*w//t}%)  Empty={e}/{t}  Joy={j}/{t}")

wander_entries = [e for e in data if e["pawn"]["job"] == "Wander"]
print(f"\n=== Wander joy levels ===")
joys = []
for e in wander_entries[:20]:
    p = e["pawn"]
    print(f"  {p['name']:10s} tick={e['tick']} rest={p['rest']:.3f} food={p['food']:.3f}")
