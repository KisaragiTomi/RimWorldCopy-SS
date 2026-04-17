import socket, json

def tcp_eval(code, timeout=10):
    s = socket.socket()
    s.settimeout(timeout)
    s.connect(('127.0.0.1', 9090))
    msg = json.dumps({'command': 'eval', 'params': {'code': code}}) + '\n'
    s.sendall(msg.encode())
    result = s.recv(65536).decode()
    s.close()
    return result

print("=== Game Status ===")
print(tcp_eval('return {"tick": TickManager.current_tick, "speed": TickManager.current_speed, "pawns": PawnManager.pawns.size()}'))

print("\n=== Pawn Details ===")
code_pawns = (
    'var result = []\n'
    'for p in PawnManager.pawns:\n'
    '\tif p.dead:\n'
    '\t\tcontinue\n'
    '\tresult.append({"name": p.pawn_name, "job": p.current_job_name, '
    '"food": snappedf(p.get_need("Food"), 0.001), '
    '"rest": snappedf(p.get_need("Rest"), 0.001), '
    '"mood": snappedf(p.get_need("Mood"), 0.001), '
    '"pos": [p.grid_pos.x, p.grid_pos.y], '
    '"downed": p.downed})\n'
    'return result'
)
print(tcp_eval(code_pawns))

print("\n=== Bed Count ===")
code_beds = (
    'var count = 0\n'
    'for t in ThingManager._buildings:\n'
    '\tif t.def_name == "Bed":\n'
    '\t\tcount += 1\n'
    'return {"beds": count, "alive_pawns": PawnManager.pawns.filter(func(p): return not p.dead).size()}'
)
print(tcp_eval(code_beds))

print("\n=== Growing Zone Status ===")
code_zones = (
    'var grow_cells = 0\n'
    'var mature_plants = 0\n'
    'var growing_plants = 0\n'
    'for t in ThingManager._plants:\n'
    '\tif t.def_name.begins_with("Plant_"):\n'
    '\t\tif t.get_meta("growth", 0.0) >= 1.0:\n'
    '\t\t\tmature_plants += 1\n'
    '\t\telse:\n'
    '\t\t\tgrowing_plants += 1\n'
    'return {"mature": mature_plants, "growing": growing_plants}'
)
print(tcp_eval(code_zones))

print("\n=== Research Status ===")
code_research = (
    'var rm = ResearchManager\n'
    'return {"current": rm.current_project, "completed": rm.completed_projects.size(), '
    '"queue": rm.research_queue.size(), "available": rm.get_available_projects().size()}'
)
print(tcp_eval(code_research))

print("\n=== Food Stock ===")
code_food = (
    'var meals = 0\n'
    'var raw = 0\n'
    'for t in ThingManager._items:\n'
    '\tif "Meal" in t.def_name:\n'
    '\t\tmeals += 1\n'
    '\telif "Meat" in t.def_name or "Berries" in t.def_name or "Potato" in t.def_name or "Rice" in t.def_name or "Corn" in t.def_name:\n'
    '\t\traw += 1\n'
    'return {"meals": meals, "raw_food": raw}'
)
print(tcp_eval(code_food))
