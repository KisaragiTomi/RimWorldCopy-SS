import socket, json, base64, sys
sys.stdout.reconfigure(line_buffering=True)

def tcp(cmd, params=None, timeout=12):
    s = socket.socket()
    s.settimeout(timeout)
    s.connect(("127.0.0.1", 9090))
    msg = {"command": cmd}
    if params:
        msg["params"] = params
    s.sendall((json.dumps(msg) + "\n").encode())
    buf = b""
    try:
        while True:
            chunk = s.recv(4096)
            if not chunk:
                break
            buf += chunk
    except socket.timeout:
        pass
    s.close()
    if buf:
        return json.loads(buf.decode())
    return None

# 1. Game state
print("=== GAME STATE ===")
r = tcp("eval", {"code": "var t = get_node(\"/root/TickManager\")\nvar d = t.get_date()\nreturn {\"tick\": t.current_tick, \"year\": d.year, \"day\": d.day, \"quadrum\": d.quadrum}"})
print(json.dumps(r.get("result", {}) if r else {}, indent=2))

# 2. Research
print("\n=== RESEARCH ===")
r = tcp("eval", {"code": "var rm = get_node(\"/root/ResearchManager\")\nreturn {\"completed\": rm._completed.size(), \"total\": DefDB.get_all(\"ResearchProjectDef\").size()}"})
print(json.dumps(r.get("result", {}) if r else {}, indent=2))

# 3. Colonists
print("\n=== COLONISTS ===")
r = tcp("eval", {"code": "var pm = get_node(\"/root/PawnManager\")\nvar result = []\nfor p in pm.pawns:\n\tresult.append({\"name\": p.pawn_name, \"job\": p.current_job_name, \"food\": snappedf(p.get_need(\"Food\"), 0.01), \"mood\": snappedf(p.get_need(\"Mood\"), 0.01), \"rest\": snappedf(p.get_need(\"Rest\"), 0.01)})\nreturn {\"count\": pm.pawns.size(), \"pawns\": result}"})
print(json.dumps(r.get("result", {}) if r else {}, indent=2))

# 4. Power
print("\n=== POWER ===")
r = tcp("eval", {"code": "var eg = get_node(\"/root/ElectricityGrid\")\neg._dirty = true\neg._on_rare_tick(0)\nreturn {\"nets\": eg.nets.size(), \"gen\": eg.get_total_generation(), \"con\": eg.get_total_consumption(), \"stability\": eg.get_grid_stability()}"})
print(json.dumps(r.get("result", {}) if r else {}, indent=2))

# 5. Crafting
print("\n=== CRAFTING ===")
r = tcp("eval", {"code": "var cm = get_node(\"/root/CraftingManager\")\nreturn {\"crafted\": cm.total_crafted, \"queue\": cm.craft_queue.size(), \"health\": cm.get_manufacturing_health(), \"quality\": cm._quality_counts}"})
print(json.dumps(r.get("result", {}) if r else {}, indent=2))

# 6. TurretAI
print("\n=== TURRET ===")
r = tcp("eval", {"code": "var ta = get_node(\"/root/TurretAI\")\nreturn {\"turrets\": ta._turrets.size()}"})
print(json.dumps(r.get("result", {}) if r else {}, indent=2))

# 7. Things count
print("\n=== MAP ===")
r = tcp("eval", {"code": "var tm = get_node(\"/root/ThingManager\")\nvar bld = 0\nvar items = 0\nvar plants = 0\nfor t in tm.things:\n\tif t is Building:\n\t\tbld += 1\n\telif t is Item:\n\t\titems += 1\n\telif t is Plant:\n\t\tplants += 1\nreturn {\"total\": tm.things.size(), \"buildings\": bld, \"items\": items, \"plants\": plants}"})
print(json.dumps(r.get("result", {}) if r else {}, indent=2))

# 8. Screenshot
r = tcp("screenshot")
if r and r.get("data"):
    with open("screenshots/r6_final.png", "wb") as f:
        f.write(base64.b64decode(r["data"]))
    print("\nScreenshot: screenshots/r6_final.png")

print("\nALL TESTS COMPLETE")
