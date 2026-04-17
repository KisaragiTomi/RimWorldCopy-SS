import json

with open("d:/MyProject/RimWorldCopy/logs/game_raw_data.json", "r") as f:
    data = json.load(f)

miner = [e for e in data if e["pawn"]["name"] == "Miner"]
miner.sort(key=lambda e: e["tick"])

print(f"Miner entries: {len(miner)}")
print("\n=== Miner Timeline ===")
for e in miner:
    p = e["pawn"]
    print(f"  tick={e['tick']} job={p['job']:15s} rest={p['rest']:.3f} food={p['food']:.3f} mood={p['mood']:.3f}")

moods = [e["pawn"]["mood"] for e in miner]
print(f"\n=== Mood stats ===")
print(f"  min={min(moods):.3f} max={max(moods):.3f} avg={sum(moods)/len(moods):.3f}")
print(f"  <0.6: {sum(1 for m in moods if m < 0.6)}/{len(moods)}")
print(f"  <0.7: {sum(1 for m in moods if m < 0.7)}/{len(moods)}")
print(f"  <0.8: {sum(1 for m in moods if m < 0.8)}/{len(moods)}")
