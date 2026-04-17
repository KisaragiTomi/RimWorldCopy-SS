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

code = """var results = []
for p in PawnManager.pawns:
\tif p.dead: continue
\tvar food = p.get_need("Food")
\tvar entry = {"name": p.pawn_name, "food": snapped(food, 0.001), "job": p.current_job_name}
\tif food < 0.4:
\t\tvar food_found = 0
\t\tvar food_blocked = 0
\t\tfor t in ThingManager.things:
\t\t\tif not (t is Item): continue
\t\t\tvar item = t as Item
\t\t\tif item.state != Thing.ThingState.SPAWNED: continue
\t\t\tvar dname = item.def_name
\t\t\tif dname in ["MealFine","MealSimple","MealLavish","NutrientPaste","RawFood","Meat","Rice","Corn","Berries","Pemmican"]:
\t\t\t\tif item.forbidden or item.hauled_by >= 0:
\t\t\t\t\tfood_blocked += 1
\t\t\t\telse:
\t\t\t\t\tfood_found += 1
\t\tentry["food_available"] = food_found
\t\tentry["food_blocked"] = food_blocked
\tresults.append(entry)
return results
"""

r = tcp_eval(code)
print(json.dumps(r, indent=2))
