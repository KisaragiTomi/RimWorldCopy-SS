import json

data = json.load(open("logs/game_raw_data.json"))
print(f"Entries: {len(data)}")
if data:
    print(f"Keys: {list(data[0].keys())}")
    # Show first and last entries
    print(f"\nFirst entry (tick {data[0].get('tick', '?')}):")
    print(json.dumps(data[0], indent=2)[:800])
    print(f"\nLast entry (tick {data[-1].get('tick', '?')}):")
    print(json.dumps(data[-1], indent=2)[:800])
    
    # Analyze pawn jobs distribution
    job_counts = {}
    mood_sum = 0
    food_sum = 0
    rest_sum = 0
    count = 0
    for entry in data:
        pawn = entry.get("pawn", {})
        job = pawn.get("job", "unknown")
        job_counts[job] = job_counts.get(job, 0) + 1
        mood_sum += pawn.get("mood", 0)
        food_sum += pawn.get("food", 0)
        rest_sum += pawn.get("rest", 0)
        count += 1
    
    print(f"\nJob distribution ({count} samples):")
    for job, cnt in sorted(job_counts.items(), key=lambda x: -x[1]):
        print(f"  {job}: {cnt} ({cnt*100//count}%)")
    
    if count > 0:
        print(f"\nAverage needs:")
        print(f"  Mood: {mood_sum/count:.2f}")
        print(f"  Food: {food_sum/count:.2f}")
        print(f"  Rest: {rest_sum/count:.2f}")
