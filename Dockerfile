FROM ubuntu:22.04

# 1. Cài đặt SSH và các công cụ cần thiết
RUN apt-get update && apt-get install -y \
    openssh-server \
    curl \
    wget \
    sudo \
    python3 \
    && mkdir /var/run/sshd

# 2. Cài đặt Cloudflared (Tool kết nối của Cloudflare)
RUN curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb && \
    dpkg -i cloudflared.deb && \
    rm cloudflared.deb

# 3. Tạo User 'trthaodev' (Mật khẩu: thaodev@)
RUN useradd -m trthaodev && \
    echo "trthaodev:thaodev@" | chpasswd && \
    adduser trthaodev sudo

# 4. Cấu hình SSH
RUN echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config

# 5. Tạo Script chạy tự động (All-in-one)
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'echo "=== KHOI DONG SSH SERVICE ==="' >> /start.sh && \
    echo 'service ssh start' >> /start.sh && \
    echo 'if [ -z "$CLOUDFLARE_TOKEN" ]; then' >> /start.sh && \
    echo '  echo "❌ LOI: Thieu bien moi truong CLOUDFLARE_TOKEN!"' >> /start.sh && \
    echo 'else' >> /start.sh && \
    echo '  echo "=== KET NOI CLOUDFLARE TUNNEL ==="' >> /start.sh && \
    echo '  nohup cloudflared tunnel run --token $CLOUDFLARE_TOKEN > /var/log/cloudflared.log 2>&1 &' >> /start.sh && \
    echo '  echo "✅ Cloudflare da chay. Hay ket noi qua domain ban da cau hinh."' >> /start.sh && \
    echo 'fi' >> /start.sh && \
    echo 'echo "=== GIU CONTAINER HOAT DONG (PORT 8080) ==="' >> /start.sh && \
    echo 'python3 -m http.server 8080' >> /start.sh && \
    chmod +x /start.sh

# 6. Mở Port và Chạy
EXPOSE 8080 22
CMD ["/start.sh"]
