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

# Method 1: Get HUD children
code1 = 'var hud = get_tree().root.get_node("Main/GameHUD")\nvar ch = []\nfor c in hud.get_children():\n\tch.append(c.name + ":" + c.get_class())\nreturn ch.slice(0, 5)'
r1 = send_cmd({"command": "eval", "params": {"code": code1}})
print("HUD children:", json.dumps(r1, indent=2))

# Method 2: Find any node named MapViewport in the tree
code2 = 'var nodes = get_tree().get_nodes_in_group("map_viewport")\nreturn nodes.size()'
r2 = send_cmd({"command": "eval", "params": {"code": code2}})
print("Group:", r2)

# Method 3: Get HUD first child details
code3 = 'var hud = get_tree().root.get_node("Main/GameHUD")\nvar first = hud.get_child(0)\nvar info = {"name": first.name, "class": first.get_class()}\nif first.get_child_count() > 0:\n\tvar sub = first.get_child(0)\n\tinfo["sub_name"] = sub.name\n\tinfo["sub_class"] = sub.get_class()\n\tif sub.get_child_count() > 0:\n\t\tvar sub2 = sub.get_child(0)\n\t\tinfo["sub2_name"] = sub2.name\n\t\tinfo["sub2_class"] = sub2.get_class()\n\t\tinfo["sub2_has_map"] = sub2.get("map_data") != null if sub2.get("map_data") is Variant else false\nreturn info'
r3 = send_cmd({"command": "eval", "params": {"code": code3}})
print("First child tree:", json.dumps(r3, indent=2))
