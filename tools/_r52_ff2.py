import socket, json, time

PORT = 9090

def send_cmd(cmd, timeout=10):
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(timeout)
        s.connect(("127.0.0.1", PORT))
        s.sendall(json.dumps(cmd).encode() + b"\n")
        buf = b""
        while True:
            chunk = s.recv(4096)
            if not chunk:
                break
            buf += chunk
            try:
                return json.loads(buf.decode())
            except:
                continue
        return json.loads(buf.decode()) if buf else None
    except Exception as e:
        return {"error": str(e)}
    finally:
        s.close()

def ev(code):
    r = send_cmd({"command": "eval", "params": {"code": code}})
    if isinstance(r, dict) and "result" in r:
        return r["result"]
    return r

print("=== R52 CONTINUE FF ===\n")

# Check season tick thresholds
total = ev("return SeasonManager.total_changes")
day = ev("return SeasonManager.days_in_season")
progress = ev("return SeasonManager.season_progress_pct")
tick = ev("return TickManager.current_tick")
print(f"Start: tick={tick} changes={total} days={day} progress={progress}%")

ev("TickManager.set_speed(3)\nreturn 1")

for chunk in range(10):
    time.sleep(20)
    s = ev("return SeasonManager.current_season")
    t = ev("return TickManager.current_tick")
    ch = ev("return SeasonManager.total_changes")
    fps = ev("return Engine.get_frames_per_second()")
    prog = ev("return SeasonManager.season_progress_pct")
    print(f"  [{chunk+1}] Season={s} Tick={t} Changes={ch} Prog={prog}% FPS={fps}")
    if str(s) in ["Summer", "1"]:
        print("  >>> SUMMER!")
        break

# Final status
print("\n--- Final Check ---")
summary = ev("return SeasonManager.get_summary()")
for k in ["current_season", "days_until_next", "total_changes", "growth_factor"]:
    print(f"  {k}: {summary.get(k) if isinstance(summary, dict) else 'N/A'}")

pcount = ev("return PawnManager.pawns.size()")
for i in range(int(pcount)):
    name = ev(f"return PawnManager.pawns[{i}].pawn_name")
    job = ev(f"return PawnManager.pawns[{i}].current_job_name")
    food = ev(f'return PawnManager.pawns[{i}].get_need("Food")')
    f = food if isinstance(food, (int, float)) else 0
    print(f"  {name:8s} | {str(job):18s} | F={f:.2f}")

ev("TickManager.set_speed(1)\nreturn 1")
ev("var logger = get_node_or_null('/root/_DataLogger')\nif logger:\n\tvar log = logger.get_meta('log', [])\n\tlogger._save_to_disk(log)\nreturn 1")

print("\n=== R52 FF2 DONE ===")
