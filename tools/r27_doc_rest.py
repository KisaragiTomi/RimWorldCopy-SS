import json

with open("d:/MyProject/RimWorldCopy/logs/game_raw_data.json", "r") as f:
    data = json.load(f)

doc_entries = [e for e in data if e["pawn"]["name"] == "Doc"]
doc_entries.sort(key=lambda e: e["pawn"]["rest"])

print(f"Doc entries: {len(doc_entries)}")
print("\n=== Lowest Rest Entries ===")
for e in doc_entries[:10]:
    p = e["pawn"]
    print(f"  tick={e['tick']} job={p['job']} rest={p['rest']:.3f} food={p['food']:.3f} mood={p['mood']:.3f} pos={p['pos']}")

print("\n=== Doc Job Timeline (last 30 entries by tick) ===")
doc_by_tick = sorted(doc_entries, key=lambda e: e["tick"])
for e in doc_by_tick[-30:]:
    p = e["pawn"]
    print(f"  tick={e['tick']} job={p['job']:15s} rest={p['rest']:.3f} food={p['food']:.3f}")
