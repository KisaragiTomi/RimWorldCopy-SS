import socket, json

def tcp_eval(code):
    s = socket.socket()
    s.settimeout(15)
    s.connect(('127.0.0.1', 9090))
    s.sendall((json.dumps({'command':'eval','params':{'code':code}}) + '\n').encode())
    data = b''
    while b'\n' not in data:
        chunk = s.recv(4096)
        if not chunk: break
        data += chunk
    s.close()
    return json.loads(data.strip())

code = """var food_items = []
var other_items = []
for t in ThingManager.things:
\tif not (t is Item): continue
\tvar name = t.def_name
\tif name in ["MealFine","MealSimple","MealLavish","NutrientPaste","RawFood","Meat","Rice","Corn","Berries","Pemmican"]:
\t\tfood_items.append({"def": name, "pos": [t.grid_pos.x, t.grid_pos.y], "count": t.stack_count if "stack_count" in t else 1})
\telif t is Item:
\t\tother_items.append(name)
var food_counts = {}
for f in food_items:
\tif f.def in food_counts:
\t\tfood_counts[f.def] += f.count
\telse:
\t\tfood_counts[f.def] = f.count
var item_counts = {}
for n in other_items:
\tif n in item_counts:
\t\titem_counts[n] += 1
\telse:
\t\titem_counts[n] = 1
return {"food_items": food_items.size(), "food_counts": food_counts, "item_summary": item_counts}
"""

r = tcp_eval(code)
print(json.dumps(r, indent=2))
