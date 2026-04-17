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

check_code = (
    'var map = GameState.active_map\n'
    'var spots = []\n'
    'var candidates = [\n'
    '\tVector2i(58, 57), Vector2i(58, 61),\n'
    '\tVector2i(57, 58), Vector2i(57, 59), Vector2i(57, 60),\n'
    '\tVector2i(57, 57), Vector2i(57, 61),\n'
    '\tVector2i(56, 58), Vector2i(56, 59), Vector2i(56, 60),\n'
    '\tVector2i(59, 58), Vector2i(59, 59), Vector2i(59, 60),\n'
    ']\n'
    'for pos in candidates:\n'
    '\tvar cell = map.get_cell_v(pos)\n'
    '\tif cell and cell.is_passable() and not cell.building:\n'
    '\t\tspots.append([pos.x, pos.y])\n'
    'return {"available_spots": spots}'
)
print("Available bed spots:")
print(tcp_eval(check_code))

place_code = (
    'var map = GameState.active_map\n'
    'var candidates = [\n'
    '\tVector2i(57, 58), Vector2i(57, 59), Vector2i(57, 60),\n'
    '\tVector2i(56, 58), Vector2i(56, 59), Vector2i(56, 60),\n'
    '\tVector2i(58, 57), Vector2i(58, 61),\n'
    '\tVector2i(57, 57), Vector2i(57, 61),\n'
    ']\n'
    'var placed = 0\n'
    'var needed = 10\n'
    'for pos in candidates:\n'
    '\tif placed >= needed:\n'
    '\t\tbreak\n'
    '\tvar cell = map.get_cell_v(pos)\n'
    '\tif cell and cell.is_passable() and not cell.building:\n'
    '\t\tThingManager.place_blueprint("Bed", pos)\n'
    '\t\tplaced += 1\n'
    'return {"placed": placed}'
)
print("\nPlacing beds:")
print(tcp_eval(place_code))

print("\nVerifying bed count:")
code_verify = (
    'var count = 0\n'
    'for t in ThingManager._buildings:\n'
    '\tif t.def_name == "Bed":\n'
    '\t\tcount += 1\n'
    'var alive = PawnManager.pawns.filter(func(p): return not p.dead).size()\n'
    'return {"beds": count, "pawns": alive}'
)
print(tcp_eval(code_verify))
