import socket, json, time

def send_cmd(cmd_dict, host="127.0.0.1", port=9090, timeout=15):
    s = socket.create_connection((host, port), timeout=timeout)
    s.sendall(json.dumps(cmd_dict).encode() + b"\n")
    buf = b""
    while True:
        chunk = s.recv(65536)
        if not chunk: break
        buf += chunk
        if b"\n" in buf: break
    s.close()
    return json.loads(buf.split(b"\n")[0].decode())

# Reload current scene
r = send_cmd({"command": "eval", "params": {"code": 'get_tree().reload_current_scene()\nreturn "reloading"'}})
print("Reload:", r)
time.sleep(3)

# Check scene
r2 = send_cmd({"command": "eval", "params": {"code": 'return str(get_tree().current_scene.name)'}})
print("Scene:", r2)

# Switch to game
r3 = send_cmd({"command": "eval", "params": {"code": 'var main = get_tree().root.get_node("Main")\nmain.switch_to_game()\nreturn "switching"'}})
print("Switch:", r3)
time.sleep(5)

# Check Main children after switch
r4 = send_cmd({"command": "eval", "params": {"code": 'var main = get_tree().root.get_node("Main")\nvar ch = []\nfor c in main.get_children():\n\tch.append(c.name)\nreturn ch'}})
print("Main children:", r4)

# Check active_map
r5 = send_cmd({"command": "eval", "params": {"code": 'return GameState.active_map != null'}})
print("has_map:", r5)

# Check buildings
r6 = send_cmd({"command": "eval", "params": {"code": 'return ThingManager.get_buildings().size()'}})
print("buildings:", r6)

# Check glow sprites
r7 = send_cmd({"command": "eval", "params": {"code": 'var hud = get_tree().root.get_node_or_null("Main/GameHUD")\nif hud == null:\n\treturn "no_hud"\nfor c in hud.get_children():\n\tif c is SubViewportContainer:\n\t\tfor sv in c.get_children():\n\t\t\tif sv is SubViewport:\n\t\t\t\tfor mvp in sv.get_children():\n\t\t\t\t\tif mvp.name == "MapViewport":\n\t\t\t\t\t\treturn {"map": mvp.map_data != null, "glow": mvp._glow_sprites.size()}\nreturn "no_mvp"'}})
print("MapViewport:", r7)
