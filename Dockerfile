FROM ubuntu:22.04

# 1. Cài đặt các công cụ cơ bản
RUN apt-get update && apt-get install -y \
    openssh-server \
    curl \
    wget \
    sudo \
    python3 \
    && mkdir /var/run/sshd

# 2. Tạo User 'trthaodev' (Pass: thaodev@)
RUN useradd -m trthaodev && \
    echo "trthaodev:thaodev@" | chpasswd && \
    adduser trthaodev sudo

# Cấu hình SSH
RUN echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config

# 3. Cài đặt Tunnelmole (tmole)
# Tải trực tiếp file binary về
RUN curl -L https://tunnelmole.com/downloads/tmole-linux-amd64 -o /usr/local/bin/tmole && \
    chmod +x /usr/local/bin/tmole

# 4. Script chạy Tunnelmole TCP
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'service ssh start' >> /start.sh && \
    echo 'echo "=== DANG KHOI TAO TUNNELMOLE ==="' >> /start.sh && \
    echo 'echo "Doi 5 giay..."' >> /start.sh && \
    # Chạy tmole ở chế độ background cho port 22
    echo 'tmole 22 > /var/log/tmole.log 2>&1 &' >> /start.sh && \
    echo 'sleep 5' >> /start.sh && \
    echo 'echo "=== THONG TIN NHAP VAO BITVISE ==="' >> /start.sh && \
    # Lọc lấy dòng chứa địa chỉ tcp://
    echo 'grep "tcp://" /var/log/tmole.log' >> /start.sh && \
    echo 'echo "=================================="' >> /start.sh && \
    echo 'echo "Server dang chay..."' >> /start.sh && \
    echo 'tail -f /var/log/tmole.log & python3 -m http.server 8080' >> /start.sh && \
    chmod +x /start.sh

# 5. Chạy
EXPOSE 8080 22
CMD ["/start.sh"]
