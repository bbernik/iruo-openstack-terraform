#cloud-config
# Lagani TCP round-robin load balancer u Pythonu (bez instalacije paketa).
# Slusa na portu 80 i izmjenicno salje na 2 app VM-ke (backends su templateani).

write_files:
  - path: /opt/lb/lb.py
    permissions: "0755"
    owner: root:root
    content: |
      import socket, threading, itertools
      BACKENDS = [ ${backends} ]
      rr = itertools.cycle(BACKENDS)
      lock = threading.Lock()

      def pipe(src, dst):
          try:
              while True:
                  data = src.recv(65536)
                  if not data:
                      break
                  dst.sendall(data)
          except OSError:
              pass
          finally:
              try: src.close()
              except OSError: pass
              try: dst.close()
              except OSError: pass

      def handle(client):
          with lock:
              backend = next(rr)
          try:
              up = socket.create_connection(backend, timeout=5)
          except OSError:
              client.close()
              return
          threading.Thread(target=pipe, args=(client, up), daemon=True).start()
          threading.Thread(target=pipe, args=(up, client), daemon=True).start()

      srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
      srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
      srv.bind(("0.0.0.0", 80))
      srv.listen(128)
      while True:
          conn, _ = srv.accept()
          handle(conn)
  - path: /opt/lb/run.sh
    permissions: "0755"
    owner: root:root
    content: |
      #!/bin/bash
      PY=$(command -v python3 || echo /usr/libexec/platform-python)
      exec "$PY" /opt/lb/lb.py
  - path: /etc/systemd/system/techsprint-lb.service
    permissions: "0644"
    owner: root:root
    content: |
      [Unit]
      Description=TechSprint TCP load balancer (port 80)
      After=network-online.target
      [Service]
      ExecStart=/opt/lb/run.sh
      Restart=always
      [Install]
      WantedBy=multi-user.target

runcmd:
  - systemctl daemon-reload
  - systemctl enable --now techsprint-lb.service
