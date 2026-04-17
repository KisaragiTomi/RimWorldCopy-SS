import json

with open("d:/MyProject/RimWorldCopy/logs/game_raw_data.json", "r") as f:
    data = json.load(f)

taylor = [e for e in data if e["pawn"]["name"] == "Taylor"]
taylor.sort(key=lambda e: e["tick"])

print(f"Taylor entries: {len(taylor)}")
print("\n=== Taylor Timeline ===")
for e in taylor:
    p = e["pawn"]
    print(f"  tick={e['tick']} job={p['job']:15s} rest={p['rest']:.3f} food={p['food']:.3f} mood={p['mood']:.3f}")

print(f"\n=== Mood distribution ===")
moods = [e["pawn"]["mood"] for e in taylor]
print(f"  min={min(moods):.3f} max={max(moods):.3f} avg={sum(moods)/len(moods):.3f}")
print(f"  <0.6: {sum(1 for m in moods if m < 0.6)}")
print(f"  <0.7: {sum(1 for m in moods if m < 0.7)}")
