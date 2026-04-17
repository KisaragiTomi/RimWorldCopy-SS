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

print("=== R79 Building Defs ===\n")

# Check BuildingDefs availability
has = ev("return \"BuildingDefs\" in get_tree().root.get_children().map(func(c): return c.name)")
print(f"BuildingDefs autoload: {has}")

# Try different ways to get building definitions
defs1 = ev("var r = []\nfor key in BuildingDefs.ALL.keys():\n\tr.append(key)\nreturn r")
print(f"BuildingDefs.ALL keys: {defs1}")

# Check if BuildingDefs exists
exists = ev("return BuildingDefs != null")
print(f"BuildingDefs exists: {exists}")

# List all autoloads
autoloads = ev("var r = []\nfor c in get_tree().root.get_children():\n\tr.append(c.name)\nreturn r")
print(f"Autoloads: {autoloads}")

# Check building defs file
defs_path = ev("return BuildingDefs.get_script().resource_path if BuildingDefs else \"\"")
print(f"BuildingDefs path: {defs_path}")

# Try to get building categories
cats = ev("var r = {}\nfor key in BuildingDefs.ALL:\n\tvar d = BuildingDefs.ALL[key]\n\tvar cat = d.get(\"category\", \"unknown\")\n\tif cat not in r:\n\t\tr[cat] = []\n\tr[cat].append(key)\nreturn r")
print(f"Categories: {cats}")

# List all buildable things with basic info
all_b = ev("var r = []\nfor key in BuildingDefs.ALL:\n\tvar d = BuildingDefs.ALL[key]\n\tr.append({\"name\": key, \"cat\": d.get(\"category\", \"?\"), \"cost\": d.get(\"cost\", {})})\nreturn r")
print(f"\nAll buildings: {all_b}")

# Research projects
projects = ev("var r = []\nfor key in ResearchManager.projects:\n\tvar p = ResearchManager.projects[key]\n\tr.append({\"name\": key, \"completed\": p.get(\"completed\", false)})\nreturn r")
print(f"\nResearch: {projects}")

# Power system
power_methods = ev("var r = []\nfor m in PowerManager.get_method_list():\n\tr.append(m.name)\nreturn r")
print(f"\nPowerManager methods: {power_methods}")

print(f"\n=== DONE ===")
