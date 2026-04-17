import socket, json, time

PORT = 9090

def ev(code):
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(10)
        s.connect(("127.0.0.1", PORT))
        cmd = {"command": "eval", "params": {"code": code}}
        s.sendall(json.dumps(cmd).encode() + b"\n")
        buf = b""
        while True:
            chunk = s.recv(4096)
            if not chunk:
                break
            buf += chunk
            try:
                r = json.loads(buf.decode())
                if isinstance(r, dict) and "result" in r:
                    return r["result"]
                return r
            except:
                continue
        return None
    except:
        return None
    finally:
        s.close()

print("=== R79 DefDB & Research ===\n")

# Check DefDB
defdb_methods = ev("var r = []\nfor m in DefDB.get_method_list():\n\tif not m.name.begins_with(\"_\"):\n\t\tr.append(m.name)\nreturn r")
print(f"DefDB methods: {defdb_methods}")

# Check DefDB properties
defdb_props = ev("var r = []\nfor p in DefDB.get_property_list():\n\tif not p.name.begins_with(\"_\") and p.usage & 4096:\n\t\tr.append(p.name)\nreturn r")
print(f"DefDB props: {defdb_props}")

# Try to get building defs from DefDB
bld_defs = ev("return DefDB.buildings.keys() if \"buildings\" in DefDB else \"no buildings prop\"")
print(f"DefDB.buildings: {bld_defs}")

# Try get_building_def
bld = ev("return DefDB.get_building_def(\"Wall\") if DefDB.has_method(\"get_building_def\") else \"no method\"")
print(f"get_building_def(Wall): {bld}")

# Check all DefDB keys
all_keys = ev("var r = []\nfor p in DefDB.get_script().get_script_property_list():\n\tr.append(p.name)\nreturn r")
print(f"Script props: {all_keys}")

# Research Manager 
res_methods = ev("var r = []\nfor m in ResearchManager.get_method_list():\n\tif not m.name.begins_with(\"_\"):\n\t\tr.append(m.name)\nreturn r")
print(f"\nResearchManager methods: {res_methods}")

# Research projects - try dict keys
res_keys = ev("return ResearchManager.projects.keys()")
print(f"Research keys: {res_keys}")

# All completed?
completed = ev("var c = 0\nfor key in ResearchManager.projects:\n\tvar p = ResearchManager.projects[key]\n\tif p is Dictionary and p.get(\"completed\", false):\n\t\tc += 1\n\telif p is bool and p:\n\t\tc += 1\nreturn {\"total\": ResearchManager.projects.size(), \"completed\": c}")
print(f"Research status: {completed}")

# Current tick and game day
tick = ev("return TickManager.current_tick")
print(f"\nCurrent tick: {tick}")

# Check ElectricityGrid
elec = ev("var r = []\nfor m in ElectricityGrid.get_method_list():\n\tif not m.name.begins_with(\"_\"):\n\t\tr.append(m.name)\nreturn r")
print(f"\nElectricityGrid methods: {elec}")

print(f"\n=== DONE ===")
