import socket, json, base64, pathlib, time

def send_cmd(cmd_dict, host="127.0.0.1", port=9090, timeout=15):
    s = socket.create_connection((host, port), timeout=timeout)
    s.sendall(json.dumps(cmd_dict).encode() + b"\n")
    buf = b""
    while True:
        chunk = s.recv(65536)
        if not chunk:
            break
        buf += chunk
        if b"\n" in buf:
            break
    s.close()
    line = buf.split(b"\n")[0]
    return json.loads(line.decode())

code = """var furniture = []
for t in ThingManager.things:
\tif t is Building and t.state == Thing.ThingState.SPAWNED and t.def_name != "Wall":
\t\tfurniture.append({"def": t.def_name, "pos": [t.grid_pos.x, t.grid_pos.y]})
return furniture
"""
result = send_cmd({"command": "eval", "params": {"code": code}})
print(json.dumps(result.get("result", []), indent=2))

avg_x = 0
avg_y = 0
items = result.get("result", [])
for f in items:
    avg_x += f["pos"][0]
    avg_y += f["pos"][1]
if items:
    avg_x /= len(items)
    avg_y /= len(items)
    print(f"\nFurniture center: ({avg_x:.0f}, {avg_y:.0f})")

    code2 = f"""var mvp = get_tree().root.get_node("Main/GameHUD/@SubViewportContainer@313/@SubViewport@314/MapViewport")
var cam = null
for c in mvp.get_children():
\tif c is Camera2D:
\t\tcam = c
\t\tbreak
if cam == null:
\treturn "no camera"
cam.position = Vector2({avg_x} * 16 + 8, {avg_y} * 16 + 8)
cam.zoom = Vector2(4.0, 4.0)
return "zoomed"
"""
    send_cmd({"command": "eval", "params": {"code": code2}})
    time.sleep(0.5)
    result2 = send_cmd({"command": "screenshot"}, timeout=15)
    img_b64 = result2.get("data") or result2.get("result", {}).get("image", "")
    pathlib.Path("screenshots/art_r200_furniture.png").write_bytes(base64.b64decode(img_b64))
    print("Saved furniture screenshot at 4x zoom")
