#!/bin/bash

echo "=== Bắt đầu dịch vụ SSH ==="
service ssh start

# Kiểm tra biến môi trường PLAYIT_SECRET
if [ -z "$PLAYIT_SECRET" ]; then
  echo "⚠️  Lỗi: Chưa có PLAYIT_SECRET!"
  echo "➡️  Vui lòng vào link Playit của bạn, copy Secret Key và thêm vào Environment Variables của Railway."
  exit 1
fi

echo "=== Khởi động Playit Agent ==="
# Chạy Playit với secret key để kết nối thẳng vào tài khoản của bạn
# Nó sẽ tự động map port 22 ra địa chỉ mà bạn đã thấy trên web Playit
nohup playit --secret "$PLAYIT_SECRET" > /var/log/playit.log 2>&1 &

# Giữ container sống bằng web server ảo
echo "=== Container đang chạy ==="
python3 -m http.server 8080
