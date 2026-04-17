import json

with open("d:/MyProject/RimWorldCopy/logs/game_raw_data.json") as f:
    data = json.load(f)

empty = [e for e in data if e["pawn"]["job"] == ""]
print(f"Empty job entries: {len(empty)}")
for e in empty[:5]:
    p = e["pawn"]
    print(f"  tick={e['tick']}, name={p['name']}, food={p['food']:.3f}, rest={p['rest']:.3f}, mood={p['mood']:.3f}, pos={p['pos']}")
