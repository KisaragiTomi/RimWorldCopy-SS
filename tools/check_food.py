import socket, json

def tcp_eval(code):
    s = socket.socket()
    s.settimeout(10)
    s.connect(('127.0.0.1', 9090))
    cmd = json.dumps({'command': 'eval', 'params': {'code': code}})
    s.sendall((cmd + '\n').encode())
    r = b''
    while True:
        try:
            d = s.recv(4096)
            if not d: break
            r += d
        except: break
    s.close()
    return r.decode()

code = """var food_items := {}
var other_items := {}
for t in ThingManager.things:
\tif t is Item:
\t\tvar item = t as Item
\t\tvar d = item.def_name
\t\tif d in ["MealFine","MealSimple","MealLavish","NutrientPaste","RawFood","Meat","Rice","Corn","Berries","Pemmican","Potato"]:
\t\t\tfood_items[d] = food_items.get(d, 0) + item.stack_count
\t\telse:
\t\t\tother_items[d] = other_items.get(d, 0) + item.stack_count
return {"food": food_items, "other": other_items, "total_items": ThingManager.things.size()}"""

print(tcp_eval(code))
