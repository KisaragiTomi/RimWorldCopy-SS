import socket, json

def tcp_eval(code):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(5)
    s.connect(("127.0.0.1", 9090))
    msg = json.dumps({"command": "eval", "params": {"code": code}}) + "\n"
    s.sendall(msg.encode())
    data = b""
    while b"\n" not in data:
        data += s.recv(4096)
    s.close()
    return json.loads(data.decode().strip())

for i in range(11):
    r = tcp_eval(f'var p = PawnManager.pawns[{i}]\nreturn p.pawn_name + "|" + p.current_job_name')
    print(f"  {i}: {r.get('result', 'ERR')}")

print("\nSage capabilities:")
code = """var sage = null
for p in PawnManager.pawns:
\tif p.pawn_name == "Sage":
\t\tsage = p
\t\tbreak
if sage == null:
\treturn "NOT_FOUND"
var caps = ""
var work_types = ["Growing", "Cooking", "Hauling", "Cleaning", "Mining", "Hunting", "Construction", "Crafting", "Research"]
for w in work_types:
\tcaps += w + "=" + str(sage.is_capable_of(w)) + " "
return caps + "| job=" + sage.current_job_name + " drafted=" + str(sage.drafted) + " downed=" + str(sage.downed)"""
print(tcp_eval(code))
