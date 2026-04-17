"""检查运行时光晕精灵属性"""
import socket, json

def eval_code(code, timeout=10):
    s = socket.create_connection(('127.0.0.1', 9090), timeout=timeout)
    msg = {'command': 'eval', 'params': {'code': code}}
    s.sendall(json.dumps(msg).encode() + b'\n')
    buf = b''
    while b'\n' not in buf:
        chunk = s.recv(65536)
        if not chunk: break
        buf += chunk
    s.close()
    return json.loads(buf.split(b'\n')[0])

# Step 1: Find MapViewport
code1 = """var main = get_tree().root.get_node("Main")
var names = []
for c in main.get_children():
	names.append(c.name)
	for cc in c.get_children():
		names.append("  " + cc.name)
return str(names)"""

r1 = eval_code(code1)
print("Children:", r1.get('result', r1)[:600])

# Step 2: Count glow sprites and check properties
code2 = """var results = []
var main = get_tree().root.get_node("Main")
var queue = [main]
while queue.size() > 0:
	var node = queue.pop_front()
	if node is Sprite2D and node.material is CanvasItemMaterial:
		var mat = node.material as CanvasItemMaterial
		if mat.blend_mode == CanvasItemMaterial.BLEND_MODE_ADD:
			results.append({
				"name": node.name,
				"scale_x": snappedf(node.scale.x, 0.01),
				"mod_a": snappedf(node.modulate.a, 0.01),
				"self_mod": [snappedf(node.self_modulate.r, 0.01), snappedf(node.self_modulate.g, 0.01), snappedf(node.self_modulate.b, 0.01)],
				"z": node.z_index,
				"tex_w": node.texture.get_width() if node.texture else 0,
				"base_a": snappedf(node.get_meta("base_alpha", -1.0), 0.01),
			})
	for c in node.get_children():
		queue.append(c)
return str(results)"""

r2 = eval_code(code2)
print("Glow sprites:", r2.get('result', r2)[:800])
