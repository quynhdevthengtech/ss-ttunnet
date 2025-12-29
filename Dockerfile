FROM ubuntu:22.04

# --- 1. CẤU HÌNH MÔI TRƯỜNG ---
ENV DEBIAN_FRONTEND=noninteractive
ENV VNC_RESOLUTION=1280x720
ENV VNC_PW=123456
ENV USER=trthaodev
ENV PASS=thaodev@

# --- 2. CÀI ĐẶT CÁC GÓI CẦN THIẾT (GỘP LẠI ĐỂ TỐI ƯU) ---
RUN apt-get update && apt-get install -y \
    openssh-server \
    curl \
    wget \
    tar \
    sudo \
    python3 \
    gnupg2 \
    software-properties-common \
    supervisor \
    xfce4 \
    xfce4-terminal \
    tigervnc-standalone-server \
    novnc \
    websockify \
    net-tools \
    dbus-x11 \
    xz-utils \
    && mkdir /var/run/sshd \
    && rm -rf /var/lib/apt/lists/*

# --- 3. CÀI FIREFOX (BẢN PPA - KHÔNG DÙNG SNAP) ---
RUN add-apt-repository ppa:mozillateam/ppa -y && \
    echo 'Package: *' > /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin: release o=LP-PPA-mozillateam' >> /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin-Priority: 1001' >> /etc/apt/preferences.d/mozilla-firefox && \
    apt-get update && \
    apt-get install -y firefox

# --- 4. CÀI QBITTORRENT (WEB UI) ---
RUN apt-get install -y qbittorrent-nox

# --- 5. TẠO USER & CẤU HÌNH SSH ---
RUN useradd -m $USER && \
    echo "$USER:$PASS" | chpasswd && \
    adduser $USER sudo && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config

# --- 6. CÀI ĐẶT BORE (TUNNEL) ---
RUN wget https://github.com/ekzhang/bore/releases/download/v0.5.1/bore-v0.5.1-x86_64-unknown-linux-musl.tar.gz && \
    tar -xf bore-v0.5.1-x86_64-unknown-linux-musl.tar.gz && \
    mv bore /usr/local/bin/bore && \
    rm bore-v0.5.1-x86_64-unknown-linux-musl.tar.gz && \
    chmod +x /usr/local/bin/bore

# --- 7. CẤU HÌNH SUPERVISOR (QUẢN LÝ ĐA NHIỆM) ---
RUN mkdir -p /var/log/supervisor
RUN echo "[supervisord]" > /etc/supervisor/conf.d/supervisord.conf && \
    echo "nodaemon=true" >> /etc/supervisor/conf.d/supervisord.conf && \
    # > Service 1: SSHD
    echo "[program:sshd]" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "command=/usr/sbin/sshd -D" >> /etc/supervisor/conf.d/supervisord.conf && \
    # > Service 2: Xvnc (Màn hình ảo)
    echo "[program:xvnc]" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "command=/usr/bin/Xvnc :1 -geometry $VNC_RESOLUTION -depth 24 -rfbauth /root/.vnc/passwd" >> /etc/supervisor/conf.d/supervisord.conf && \
    # > Service 3: XFCE (Giao diện Desktop)
    echo "[program:xfce]" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "command=dbus-launch /usr/bin/startxfce4" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "environment=DISPLAY=\":1\",HOME=\"/root\",USER=\"root\"" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "autorestart=true" >> /etc/supervisor/conf.d/supervisord.conf && \
    # > Service 4: noVNC (Web Remote)
    echo "[program:novnc]" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "command=/usr/share/novnc/utils/launch.sh --vnc localhost:5901 --listen 6080" >> /etc/supervisor/conf.d/supervisord.conf && \
    # > Service 5: qBittorrent
    echo "[program:qbittorrent]" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "command=qbittorrent-nox --webui-port=8080 --confirm-legal-notice" >> /etc/supervisor/conf.d/supervisord.conf && \
    # > Service 6: Bore (Tunnel SSH ra ngoài)
    echo "[program:bore]" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "command=bore local 22 --to bore.pub" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "stdout_logfile=/var/log/bore.log" >> /etc/supervisor/conf.d/supervisord.conf

# --- 8. SCRIPT KHỞI ĐỘNG (LOGIC IN PORT) ---
RUN echo '#!/bin/bash' > /start.sh && \
    # Thiết lập mật khẩu VNC
    echo 'mkdir -p /root/.vnc' >> /start.sh && \
    echo 'echo $VNC_PW | vncpasswd -f > /root/.vnc/passwd' >> /start.sh && \
    echo 'chmod 600 /root/.vnc/passwd' >> /start.sh && \
    # In thông tin hướng dẫn ra màn hình console
    echo 'echo "============================================="' >> /start.sh && \
    echo 'echo "   CONTAINER DANG KHOI DONG..."' >> /start.sh && \
    echo 'echo "   - Web VNC: http://localhost:6080 (Pass: 123456)"' >> /start.sh && \
    echo 'echo "   - Torrent: http://localhost:8080 (User: admin)"' >> /start.sh && \
    echo 'echo "   - SSH User: trthaodev / thaodev@"' >> /start.sh && \
    echo 'echo "============================================="' >> /start.sh && \
    # Chạy Supervisor ở chế độ nền (để script này tiếp tục chạy đoạn dưới)
    echo '/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf &' >> /start.sh && \
    # Vòng lặp chờ file log của Bore có dữ liệu để in PORT ra
    echo 'echo "Dang cho ket noi Bore..."' >> /start.sh && \
    echo 'while [ ! -f /var/log/bore.log ]; do sleep 1; done' >> /start.sh && \
    echo 'while ! grep -q "remote_port=" /var/log/bore.log; do sleep 1; done' >> /start.sh && \
    echo 'echo "=== KET NOI BORE THANH CONG ==="' >> /start.sh && \
    echo 'PORT=$(grep -o "remote_port=[0-9]*" /var/log/bore.log | head -n1 | cut -d= -f2)' >> /start.sh && \
    echo 'echo " Host: bore.pub"' >> /start.sh && \
    echo 'echo " Port: $PORT"' >> /start.sh && \
    echo 'echo "==============================="' >> /start.sh && \
    # Giữ container luôn chạy
    echo 'tail -f /var/log/bore.log' >> /start.sh && \
    chmod +x /start.sh

# Mở Port
EXPOSE 6080 8080 22 5901

# Chạy
CMD ["/start.sh"]
