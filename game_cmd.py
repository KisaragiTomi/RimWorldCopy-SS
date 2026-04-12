import socket, json, time, sys, base64

def send_cmd(cmd_dict, timeout=3):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect(('127.0.0.1', 9090))
    s.sendall((json.dumps(cmd_dict) + '\n').encode())
    time.sleep(2)
    s.settimeout(timeout)
    data = b''
    try:
        while True:
            chunk = s.recv(1048576)
            if not chunk:
                break
            data += chunk
    except socket.timeout:
        pass
    s.close()
    return data.decode('utf-8', 'replace')

if __name__ == '__main__':
    action = sys.argv[1] if len(sys.argv) > 1 else 'eval'
    if action == 'screenshot':
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect(('127.0.0.1', 9090))
        s.sendall(b'{"command":"screenshot"}\n')
        time.sleep(2)
        s.settimeout(5)
        data = b''
        try:
            while True:
                chunk = s.recv(1048576)
                if not chunk: break
                data += chunk
        except: pass
        s.close()
        resp = json.loads(data.decode('utf-8'))
        if 'data' in resp:
            img = base64.b64decode(resp['data'])
            with open('d:/MyProject/RimWorldCopy/screenshot.png', 'wb') as f:
                f.write(img)
            print('Screenshot: %sx%s' % (resp.get('width','?'), resp.get('height','?')))
        else:
            print('Error:', resp)
    else:
        expr = ' '.join(sys.argv[1:]) if len(sys.argv) > 1 else 'Engine.get_version_info()'
        result = send_cmd({'command': 'eval', 'params': {'code': expr}})
        print(result[:2000])