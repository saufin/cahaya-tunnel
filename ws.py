import socket
import threading
import select
import time

LISTEN_PORT = 80
TARGET_PORT = 109
BUFLEN = 8192

class WsProxy(threading.Thread):
    def __init__(self, client, addr):
        threading.Thread.__init__(self)
        self.client = client
        self.addr = addr

    def run(self):
        try:
            data = self.client.recv(BUFLEN).decode()
            response = "HTTP/1.1 101 Switching Protocols\r\n"
            response += "Upgrade: websocket\r\n"
            response += "Connection: Upgrade\r\n\r\n"
            self.client.send(response.encode())
            
            # ========== TAMBAHAN: CATAT USERNAME ==========
            # Ambil username dari Host header (subdomain)
            username = "unknown"
            for line in data.split('\r\n'):
                if line.lower().startswith('host:'):
                    host = line.split(':')[1].strip()
                    # Ambil bagian sebelum titik pertama (subdomain)
                    username = host.split('.')[0]
                    break
            
            # Catat ke file log
            with open('/var/log/ws_users.log', 'a') as f:
                f.write(f"{username}|{self.addr[0]}|{time.ctime()}\n")
            # =============================================
            
            target = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            target.connect(("127.0.0.1", TARGET_PORT))
            socks = [self.client, target]
            while True:
                r, _, e = select.select(socks, [], socks, 3)
                if e:
                    break
                for sock in r:
                    d = sock.recv(BUFLEN)
                    if not d:
                        break
                    if sock is self.client:
                        target.send(d)
                    else:
                        self.client.send(d)
        except:
            pass
        finally:
            try:
                self.client.close()
            except:
                pass

def main():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(("0.0.0.0", LISTEN_PORT))
    s.listen(200)
    print(f"WebSocket proxy on port {LISTEN_PORT} -> 127.0.0.1:{TARGET_PORT}")
    while True:
        c, a = s.accept()
        WsProxy(c, a).start()

if __name__ == "__main__":
    main()
