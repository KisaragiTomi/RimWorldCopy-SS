import socket, json, time, sys, os, base64
from datetime import datetime

HOST = "127.0.0.1"
PORT = 9090
SS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "screenshots")
os.makedirs(SS_DIR, exist_ok=True)

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

def screenshot(sock, label):
    r = send_cmd(sock, "screenshot")
    if r.get("success"):
        ts = datetime.now().strftime("%H%M%S")
        path = os.path.join(SS_DIR, label + "_" + ts + ".png")
        with open(path, "wb") as f:
            f.write(base64.b64decode(r["data"]))
        print("  SS: " + label, flush=True)

def connect():
    for i in range(30):
        try:
            s = socket.socket()
            s.settimeout(15)
            s.connect((HOST, PORT))
            return s
        except:
            time.sleep(2)
    raise TimeoutError("Cannot connect")

def main():
    print("=== Phase 2: Continued Monitoring ===", flush=True)
    sock = connect()
    print("Connected!", flush=True)

    # Switch to game
    send_cmd(sock, "call_method", {"node_path": "/root/Main", "method": "switch_to_game", "args": []})
    time.sleep(8)

    # Check if game loaded
    r = eval_code(sock, "return TickManager.current_tick")
    tick0 = int(r.get("result", 0)) if r.get("success") else 0
    d0 = eval_code(sock, "return TickManager.get_date()").get("result", {})
    print("Game loaded. Tick=" + str(tick0) + " Date=" + str(d0), flush=True)

    screenshot(sock, "phase2_start")

    # Set ultra speed
    eval_code(sock, "TickManager._ticks_per_frame[3] = 15")
    eval_code(sock, "TickManager.set_speed(3)")
    print("Speed: Ultra (15 tpf)", flush=True)

    last_q = d0.get("quadrum", "")
    data = []
    t_start = time.time()
    max_time = 5 * 60

    while time.time() - t_start < max_time:
        time.sleep(6)
        try:
            d = eval_code(sock, "return TickManager.get_date()").get("result", {})
            t = int(eval_code(sock, "return TickManager.current_tick").get("result", 0))
            p = send_cmd(sock, "get_performance")
            pawns = int(eval_code(sock, "return PawnManager.pawns.size()").get("result", 0))
            things = int(eval_code(sock, "return ThingManager.things.size()").get("result", 0))
        except Exception as e:
            print("  Error: " + str(e), flush=True)
            break

        cur_q = d.get("quadrum", "")
        elapsed = time.time() - t_start

        if cur_q != last_q:
            yr = d.get("year", 0)
            rec = {
                "q": cur_q, "year": yr, "tick": t, "s": round(elapsed),
                "fps": p.get("fps"), "mem": p.get("memory_static"),
                "obj": p.get("object_count"), "nodes": p.get("object_node_count"),
                "orphans": p.get("object_orphan_node_count"), "pawns": pawns, "things": things
            }
            data.append(rec)
            print("\n--- " + last_q + " -> " + cur_q + " (Y" + str(yr) + ") ---", flush=True)
            print("  Tick:" + str(t) + " FPS:" + str(p.get("fps")) + " Mem:" + str(p.get("memory_static")), flush=True)
            print("  Obj:" + str(p.get("object_count")) + " Nodes:" + str(p.get("object_node_count")) + " Orphans:" + str(p.get("object_orphan_node_count")), flush=True)
            print("  Pawns:" + str(pawns) + " Things:" + str(things), flush=True)
            screenshot(sock, str(len(data)).zfill(2) + "_" + cur_q + "_" + str(yr))
            last_q = cur_q
            if len(data) >= 5:
                break

    # Final state
    d1 = eval_code(sock, "return TickManager.get_date()").get("result", {})
    t1 = int(eval_code(sock, "return TickManager.current_tick").get("result", 0))
    p1 = send_cmd(sock, "get_performance")
    pawns1 = int(eval_code(sock, "return PawnManager.pawns.size()").get("result", 0))
    things1 = int(eval_code(sock, "return ThingManager.things.size()").get("result", 0))

    print("\n=== Final ===", flush=True)
    print("  Tick:" + str(t1) + " Date:" + str(d1), flush=True)
    print("  FPS:" + str(p1.get("fps")) + " Mem:" + str(p1.get("memory_static")), flush=True)
    print("  Pawns:" + str(pawns1) + " Things:" + str(things1), flush=True)
    screenshot(sock, "phase2_final")

    # Tick-Date check
    quadrums = ["Aprimay", "Jugust", "Septober", "Decembary"]
    def to_hrs(d):
        qi = quadrums.index(d["quadrum"]) if d.get("quadrum") in quadrums else 0
        y = d.get("year", 5500) - 5500
        return (y * 60 + qi * 15 + d.get("day", 1) - 1) * 24 + d.get("hour", 0)
    exp = (to_hrs(d1) - to_hrs(d0)) * 250
    act = t1 - tick0
    dev = abs(exp - act)
    pct = dev / max(exp, 1) * 100
    print("\n=== Tick-Date Check ===", flush=True)
    print("  Expected:" + str(exp) + " Actual:" + str(act) + " Dev:" + str(dev) + " " + str(round(pct,3)) + "% PASS:" + str(pct < 0.1), flush=True)

    # Save/Load verification
    print("\n=== Save/Load Verification ===", flush=True)

    # Get map data node path
    code_save = """
var save_ok = false
var map = null
# Try to find map data from game scene hierarchy
var game_hud = get_tree().root.get_node_or_null("Main/GameHUD")
if game_hud:
    for child in game_hud.get_children():
        if child.has_method("get_map_data"):
            map = child.get_map_data()
            break
if map == null:
    # Try MapData from map_generator
    var mg = get_tree().root.get_node_or_null("Main/GameHUD")
    if mg:
        for child in mg.get_children():
            for sub in child.get_children():
                if sub.has_method("get_map_data"):
                    map = sub.get_map_data()
                    break
if map:
    var err = SaveLoad.save_game("monitor_v2", map)
    return {"saved": true, "err": err}
return {"saved": false, "nodes": game_hud.get_child_count() if game_hud else -1}
"""
    save_r = eval_code(sock, code_save)
    print("  Save: " + str(save_r.get("result")), flush=True)

    # Verify
    code_verify = """
var d = SaveLoad.load_game("monitor_v2")
if d.is_empty():
    return {"loaded": false}
return {
    "loaded": true,
    "version": d.get("version", 0),
    "pawns": d.get("pawns", []).size(),
    "things": d.get("things", []).size(),
    "state": d.get("game_state", {})
}
"""
    verify_r = eval_code(sock, code_verify)
    vd = verify_r.get("result", {})
    print("  Verify: " + str(vd), flush=True)
    print("  Pawn match: runtime=" + str(pawns1) + " saved=" + str(vd.get("pawns", -1)) + " match=" + str(vd.get("pawns", -1) == pawns1), flush=True)

    # Autosave check
    code_auto = """
if AutosaveManager and AutosaveManager.has_method("_do_autosave"):
    AutosaveManager._do_autosave()
    return {"ok": true}
return {"ok": false}
"""
    auto_r = eval_code(sock, code_auto)
    print("  Autosave: " + str(auto_r.get("result")), flush=True)

    # Save results JSON
    results = {
        "phase": 2,
        "initial": {"tick": tick0, "date": d0},
        "final": {"tick": t1, "date": d1, "fps": p1.get("fps"), "mem": p1.get("memory_static"), "pawns": pawns1, "things": things1},
        "quadrum_data": data,
        "tick_date": {"expected": exp, "actual": act, "dev": dev, "pct": round(pct, 4), "pass": pct < 0.1},
        "save": {"save": save_r.get("result"), "verify": vd, "pawns_match": vd.get("pawns", -1) == pawns1}
    }
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "monitor_results_v2.json")
    with open(out, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, ensure_ascii=False, default=str)
    print("\nResults: " + out, flush=True)

    sock.close()
    print("Done!", flush=True)

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print("Fatal: " + str(e), flush=True)
        import traceback
        traceback.print_exc()
        sys.exit(1)