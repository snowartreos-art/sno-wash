#!/usr/bin/env bash
# Snow Temizlik - Keyubu VDS ilk kurulum (Ubuntu/Debian, root olarak çalıştırın)
#
#   curl -fsSL https://raw.githubusercontent.com/snowartreos-art/sno-wash/main/deploy/setup-vds.sh | bash
#
# Yaptıkları: nginx + certbot kurar (yoksa), siteyi /var/www/snowtemizlik'e çeker,
# yalnızca snowtemizlik.com için AYRI bir server bloğu ekler, otomatik dağıtım için
# "deploy" kullanıcısı ve SSH anahtarı oluşturur.
# Sunucudaki diğer sitelere, default ayarına, portlara ve sertifikalara dokunmaz.
# Yeni ayar "nginx -t" testinden geçmezse geri alınır ve nginx yeniden yüklenmez.
# HTTPS sertifikası DNS VDS'e döndükten sonra ayrıca alınır (en altta yazıyor).
set -euo pipefail

REPO=https://github.com/snowartreos-art/sno-wash.git
WEBROOT=/var/www/snowtemizlik
CONF=/etc/nginx/sites-available/snowtemizlik.conf

[ "$(id -u)" -eq 0 ] || { echo "Root olarak çalıştırın (sudo -i)"; exit 1; }

# 80/443'ü nginx dışında bir program (Apache, Docker, panel) kullanıyorsa dur
OTHER=$(ss -ltnpH '( sport = :80 or sport = :443 )' 2>/dev/null | grep -v nginx || true)
if [ -n "$OTHER" ]; then
  echo "DUR: 80/443 portunu nginx dışında bir program kullanıyor, hiçbir şey değiştirilmedi:"
  echo "$OTHER"; exit 1
fi

# Bu alan adı zaten başka bir ayarda tanımlıysa dur
if [ -d /etc/nginx ] && grep -rlsE "server_name[^;]*snowtemizlik\.com" /etc/nginx --exclude=snowtemizlik.conf | grep -q .; then
  echo "DUR: snowtemizlik.com başka bir nginx ayarında zaten var:"
  grep -rlsE "server_name[^;]*snowtemizlik\.com" /etc/nginx --exclude=snowtemizlik.conf; exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-upgrade nginx certbot python3-certbot-nginx git rsync curl

# Site dosyaları
TMP=$(mktemp -d)
git clone --depth 1 "$REPO" "$TMP/site"
mkdir -p "$WEBROOT"
rsync -a --delete --exclude '.git' --exclude '.github' --exclude 'deploy' \
      --exclude 'README.md' --exclude 'CNAME' "$TMP/site/" "$WEBROOT/"

# nginx: yalnızca kendi dosyamızı ekle, test et, geçmezse geri al
cp "$TMP/site/deploy/nginx-snowtemizlik.conf" "$CONF"
ln -sf "$CONF" /etc/nginx/sites-enabled/snowtemizlik.conf
if ! nginx -t; then
  rm -f /etc/nginx/sites-enabled/snowtemizlik.conf "$CONF"
  echo "DUR: nginx -t başarısız, eklenen ayar geri alındı. Diğer siteler etkilenmedi."; exit 1
fi
systemctl enable nginx
systemctl is-active --quiet nginx && systemctl reload nginx || systemctl start nginx
rm -rf "$TMP"

# Güvenlik duvarı (ufw açıksa yalnızca 80/443 izni ekler, mevcut kurallara dokunmaz)
if command -v ufw >/dev/null && ufw status | grep -q "Status: active"; then
  ufw allow 80/tcp; ufw allow 443/tcp
fi

# Otomatik dağıtım kullanıcısı (GitHub Actions bununla rsync yapar)
id deploy >/dev/null 2>&1 || useradd -m -s /bin/bash deploy
chown -R deploy:deploy "$WEBROOT"
install -d -m 700 -o deploy -g deploy /home/deploy/.ssh
KEY=/home/deploy/.ssh/github_actions
if [ ! -f "$KEY" ]; then
  sudo -u deploy ssh-keygen -t ed25519 -N "" -C "github-actions-snowtemizlik" -f "$KEY" >/dev/null
  cat "$KEY.pub" >> /home/deploy/.ssh/authorized_keys
  chown deploy:deploy /home/deploy/.ssh/authorized_keys
  chmod 600 /home/deploy/.ssh/authorized_keys
fi

IP=$(curl -fsS4 https://api.ipify.org || hostname -I | awk '{print $1}')
echo
echo "================= KURULUM TAMAM ================="
echo "Sunucu IP: $IP"
echo "Test (DNS değişmeden):  curl -H 'Host: snowtemizlik.com' http://$IP/"
echo
echo "GitHub'a eklenecek gizli değerler (Settings > Secrets > Actions):"
echo "  VDS_HOST = $IP"
echo "  VDS_USER = deploy"
echo "  VDS_SSH_KEY = aşağıdaki anahtarın tamamı (BEGIN/END satırları dahil):"
cat "$KEY"
echo
echo "DNS VDS'e döndükten sonra HTTPS için:"
echo "  certbot --nginx --cert-name snowtemizlik.com -d snowtemizlik.com -d www.snowtemizlik.com --redirect -m snowartreos@gmail.com --agree-tos -n"
echo "================================================="
