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

place_code = (
    'var map = GameState.active_map\n'
    'var placed = 0\n'
    'var needed = 10\n'
    'var cx = 58\n'
    'var cy = 59\n'
    'for ring in range(1, 8):\n'
    '\tif placed >= needed:\n'
    '\t\tbreak\n'
    '\tfor dx in range(-ring, ring + 1):\n'
    '\t\tfor dy in range(-ring, ring + 1):\n'
    '\t\t\tif abs(dx) != ring and abs(dy) != ring:\n'
    '\t\t\t\tcontinue\n'
    '\t\t\tvar pos = Vector2i(cx + dx, cy + dy)\n'
    '\t\t\tvar cell = map.get_cell_v(pos)\n'
    '\t\t\tif cell and cell.is_passable() and not cell.building:\n'
    '\t\t\t\tvar has_bed = false\n'
    '\t\t\t\tfor t in ThingManager.get_things_at(pos):\n'
    '\t\t\t\t\tif t.def_name == "Bed":\n'
    '\t\t\t\t\t\thas_bed = true\n'
    '\t\t\t\t\t\tbreak\n'
    '\t\t\t\tif not has_bed:\n'
    '\t\t\t\t\tThingManager.place_blueprint("Bed", pos)\n'
    '\t\t\t\t\tplaced += 1\n'
    '\t\t\t\t\tif placed >= needed:\n'
    '\t\t\t\t\t\tbreak\n'
    '\t\tif placed >= needed:\n'
    '\t\t\tbreak\n'
    'var total_beds = 0\n'
    'for t in ThingManager._buildings:\n'
    '\tif t.def_name == "Bed":\n'
    '\t\ttotal_beds += 1\n'
    'var alive = PawnManager.pawns.filter(func(p): return not p.dead).size()\n'
    'return {"placed": placed, "total_beds": total_beds, "alive_pawns": alive}'
)
print("Placing more beds in spiral pattern:")
print(tcp_eval(place_code))
