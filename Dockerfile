FROM ubuntu:22.04

# ----------------------------------------------------
# 1. Cài đặt môi trường
# ----------------------------------------------------
RUN apt-get update && apt-get install -y \
    openssh-server \
    curl \
    sudo \
    python3 \
    net-tools \
    iputils-ping \
    && mkdir /var/run/sshd

# ----------------------------------------------------
# 2. Tạo User 'trthaodev' (Pass: thaodev@)
# ----------------------------------------------------
RUN useradd -m trthaodev && \
    echo "trthaodev:thaodev@" | chpasswd && \
    adduser trthaodev sudo

# Cấu hình SSH
RUN echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && \
    echo 'GatewayPorts yes' >> /etc/ssh/sshd_config

# ----------------------------------------------------
# 3. Tạo Script khởi chạy Serveo
# ----------------------------------------------------
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'echo "=== KHOI DONG SSH ==="' >> /start.sh && \
    echo 'service ssh start' >> /start.sh && \
    echo 'echo "=== DANG KET NOI SERVEO.NET... ==="' >> /start.sh && \
    echo '# Thu tao mot alias ngau nhien' >> /start.sh && \
    echo '# Luu y: Serveo doi khi hay bi die do qua tai, hay kien nhan' >> /start.sh && \
    echo 'nohup ssh -o StrictHostKeyChecking=no -R 0:localhost:22 serveo.net > /var/log/serveo.log 2>&1 &' >> /start.sh && \
    echo 'echo "Dang cho lay dia chi..."' >> /start.sh && \
    echo 'sleep 7' >> /start.sh && \
    echo 'echo "=== THONG TIN KET NOI CUA BAN ==="' >> /start.sh && \
    echo 'cat /var/log/serveo.log' >> /start.sh && \
    echo 'echo "================================="' >> /start.sh && \
    echo 'echo "Server dang chay..."' >> /start.sh && \
    echo 'tail -f /var/log/serveo.log & python3 -m http.server 8080' >> /start.sh && \
    chmod +x /start.sh

# ----------------------------------------------------
# 4. Chạy
# ----------------------------------------------------
EXPOSE 8080 22
CMD ["/start.sh"]
