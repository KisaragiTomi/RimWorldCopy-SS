import socket, json, time, sys, os, base64
from datetime import datetime

HOST = "127.0.0.1"
PORT = 9090
SCREENSHOT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "screenshots")
RESULTS_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "monitor_results.json")
os.makedirs(SCREENSHOT_DIR, exist_ok=True)

def send_cmd(sock, cmd, params=None):
    payload = {"command": cmd}
    if params:
        payload["params"] = params
    msg = json.dumps(payload) + "\n"
    sock.sendall(msg.encode("utf-8"))
    buf = b""
    deadline = time.time() + 30
    while time.time() < deadline:
        chunk = sock.recv(65536)
        if not chunk:
            raise ConnectionError("Server closed")
        buf += chunk
        if b"\n" in buf:
            break
    return json.loads(buf.decode("utf-8").strip())

def eval_code(sock, code):
    return send_cmd(sock, "eval", {"code": code})

def take_screenshot(sock, label):
    resp = send_cmd(sock, "screenshot")
    if resp.get("success"):
        ts = datetime.now().strftime("%H%M%S")
        fname = label + "_" + ts + ".png"
        fpath = os.path.join(SCREENSHOT_DIR, fname)
        with open(fpath, "wb") as f:
            f.write(base64.b64decode(resp["data"]))
        print("  Screenshot: " + fname)
        return fpath
    print("  Screenshot failed")
    return ""

def get_perf(sock):
    return send_cmd(sock, "get_performance")

def get_date(sock):
    r = eval_code(sock, "return TickManager.get_date()")
    return r.get("result", {}) if r.get("success") else {}

def get_tick(sock):
    r = eval_code(sock, "return TickManager.current_tick")
    return int(r.get("result", 0)) if r.get("success") else 0

def get_pawn_count(sock):
    r = eval_code(sock, "return PawnManager.pawns.size()")
    return int(r.get("result", 0)) if r.get("success") else 0

def get_thing_count(sock):
    r = eval_code(sock, "return ThingManager.things.size()")
    return int(r.get("result", 0)) if r.get("success") else 0

def set_ultra_speed(sock, tpf=20):
    eval_code(sock, "TickManager._ticks_per_frame[3] = " + str(tpf))
    eval_code(sock, "TickManager.set_speed(3)")
    r = eval_code(sock, "return TickManager._ticks_per_frame[3]")
    actual = r.get("result", "?")
    print("  Speed Ultra, ticks_per_frame=" + str(actual))
    return actual

def trigger_save(sock, slot="monitor_test"):
    code = 'var map_viewport = get_tree().root.get_node_or_null("Main/GameHUD/MapViewport/SubViewport/MapDisplay")\nvar map = null\nif map_viewport and map_viewport.has_method("get_map_data"):\n    map = map_viewport.get_map_data()\nif map:\n    var err = SaveLoad.save_game("' + slot + '", map)\n    return {"saved": true, "error_code": err}\nreturn {"saved": false, "reason": "no_map"}'
    return eval_code(sock, code)

def trigger_autosave(sock):
    code = 'if AutosaveManager and AutosaveManager.has_method("_do_autosave"):\n    AutosaveManager._do_autosave()\n    return {"ok": true}\nreturn {"ok": false}'
    return eval_code(sock, code)

def verify_save(sock, slot="monitor_test"):
    code = 'var d = SaveLoad.load_game("' + slot + '")\nif d.is_empty():\n    return {"loaded": false}\nvar p = d.get("pawns", [])\nvar t = d.get("things", [])\nvar gs = d.get("game_state", {})\nreturn {"loaded": true, "version": d.get("version",0), "pawn_count": p.size(), "thing_count": t.size(), "game_state": gs}'
    return eval_code(sock, code)

def tick_date_check(t0, d0, t1, d1):
    quadrums = ["Aprimay", "Jugust", "Septober", "Decembary"]
    def to_hours(d):
        qi = quadrums.index(d["quadrum"]) if d.get("quadrum") in quadrums else 0
        y = d.get("year", 5500) - 5500
        total_days = y * 60 + qi * 15 + d.get("day", 1) - 1
        return total_days * 24 + d.get("hour", 0)
    h0, h1 = to_hours(d0), to_hours(d1)
    expected = (h1 - h0) * 250
    actual = t1 - t0
    dev = abs(expected - actual)
    pct = dev / max(expected, 1) * 100
    return {"expected": expected, "actual": actual, "deviation": dev, "pct": round(pct, 4), "pass": pct < 0.1}

def main():
    results = {"start_time": datetime.now().isoformat(), "quadrum_data": [], "perf_snapshots": []}

    print("Connecting to game MCP...")
    sock = socket.socket()
    sock.settimeout(30)
    sock.connect((HOST, PORT))
    print("Connected!")

    time.sleep(2)

    d0 = get_date(sock)
    t0 = get_tick(sock)
    perf0 = get_perf(sock)
    pawns0 = get_pawn_count(sock)
    things0 = get_thing_count(sock)

    print("\n=== Initial State ===")
    print("  Tick:", t0, "Date:", d0)
    print("  FPS:", perf0.get("fps"), "Mem:", perf0.get("memory_static"))
    print("  Pawns:", pawns0, "Things:", things0)

    results["initial"] = {"tick": t0, "date": d0, "fps": perf0.get("fps"), "mem": perf0.get("memory_static"), "pawns": pawns0, "things": things0}

    take_screenshot(sock, "00_initial")
    tpf = set_ultra_speed(sock, 20)
    results["ticks_per_frame"] = tpf

    last_q = d0.get("quadrum", "")
    snap_n = 1
    t_start = time.time()
    max_time = 8 * 60

    print("\n=== Ultra-Speed Monitor (max 8 min) ===")

    while time.time() - t_start < max_time:
        time.sleep(6)
        try:
            d = get_date(sock)
            t = get_tick(sock)
            p = get_perf(sock)
        except Exception as e:
            print("  Error:", e)
            break

        cur_q = d.get("quadrum", "")
        elapsed = time.time() - t_start

        if cur_q != last_q:
            yr = d.get("year", 0)
            pawns = get_pawn_count(sock)
            things = get_thing_count(sock)
            print("\n--- " + last_q + " -> " + cur_q + " (Year " + str(yr) + ") ---")
            print("  Tick:", t, "| Real:", str(round(elapsed)) + "s")
            print("  FPS:", p.get("fps"), "Mem:", p.get("memory_static"), "Obj:", p.get("object_count"))
            print("  Nodes:", p.get("object_node_count"), "Orphans:", p.get("object_orphan_node_count"))
            print("  Pawns:", pawns, "Things:", things)

            ss = take_screenshot(sock, str(snap_n).zfill(2) + "_" + cur_q + "_" + str(yr))

            rec = {
                "quadrum": cur_q, "year": yr, "tick": t, "real_s": round(elapsed, 1),
                "fps": p.get("fps"), "mem": p.get("memory_static"),
                "objects": p.get("object_count"), "nodes": p.get("object_node_count"),
                "orphans": p.get("object_orphan_node_count"), "pawns": pawns, "things": things
            }
            results["quadrum_data"].append(rec)
            snap_n += 1
            last_q = cur_q

            if len(results["quadrum_data"]) >= 8:
                print("\n  Got 8 quadrum snapshots. Stopping.")
                break
        else:
            results["perf_snapshots"].append({"tick": t, "date": d, "fps": p.get("fps"), "mem": p.get("memory_static")})

    d1 = get_date(sock)
    t1 = get_tick(sock)
    p1 = get_perf(sock)
    pawns1 = get_pawn_count(sock)
    things1 = get_thing_count(sock)

    print("\n=== Final State ===")
    print("  Tick:", t1, "Date:", d1)
    print("  FPS:", p1.get("fps"), "Mem:", p1.get("memory_static"))
    print("  Pawns:", pawns1, "Things:", things1)

    results["final"] = {"tick": t1, "date": d1, "fps": p1.get("fps"), "mem": p1.get("memory_static"), "pawns": pawns1, "things": things1}
    take_screenshot(sock, "99_final")

    print("\n=== Save/Load Verification ===")
    save_r = trigger_save(sock)
    print("  Save:", save_r.get("result"))
    auto_r = trigger_autosave(sock)
    print("  Autosave:", auto_r.get("result"))
    time.sleep(2)
    verify_r = verify_save(sock)
    vdata = verify_r.get("result", {})
    print("  Verify:", vdata)

    results["save_verify"] = {
        "save": save_r.get("result"), "autosave": auto_r.get("result"), "verify": vdata,
        "runtime_pawns": pawns1, "saved_pawns": vdata.get("pawn_count", -1),
        "match": vdata.get("pawn_count", -1) == pawns1
    }

    tc = tick_date_check(t0, d0, t1, d1)
    results["tick_date"] = tc
    print("\n=== Tick-Date Check ===")
    print("  Expected:", tc["expected"], "Actual:", tc["actual"], "Dev:", tc["deviation"], "Pass:", tc["pass"])

    results["end_time"] = datetime.now().isoformat()
    results["total_real_s"] = round(time.time() - t_start, 1)

    with open(RESULTS_FILE, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, ensure_ascii=False, default=str)
    print("\nResults saved to " + RESULTS_FILE)

    sock.close()
    print("Done!")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nInterrupted.")
    except Exception as e:
        print("Fatal: " + str(e))
        import traceback
        traceback.print_exc()
        sys.exit(1)