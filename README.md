# Snow Temizlik

Erzurum'da ev, ofis ve inşaat sonrası temizlik hizmeti veren Snow Temizlik'in web sitesi.

Statik site, GitHub Pages ile https://snowtemizlik.com adresinde yayınlanır (CNAME).

- `index.html` – ana sayfa
- `ev-temizligi.html`, `ofis-temizligi.html`, `insaat-sonrasi-temizlik.html` – hizmet sayfaları
- `style.css`, `main.js` – ortak stil ve teklif formu (WhatsApp)

İletişim: 0553 668 25 25 · snowartreos@gmail.com

## Keyubu VDS (nginx)

- `deploy/setup-vds.sh` – VDS ilk kurulum (root): `curl -fsSL https://raw.githubusercontent.com/snowartreos-art/sno-wash/main/deploy/setup-vds.sh | bash`. Sunucudaki diğer sitelere dokunmaz, yalnızca snowtemizlik.com için ayrı server bloğu ekler.
- `deploy/nginx-snowtemizlik.conf` – nginx server bloğu (HTTPS'i certbot ekler).
- `.github/workflows/deploy-vds.yml` – main'e her push'ta rsync ile VDS'e dağıtım. `VDS_HOST`, `VDS_USER`, `VDS_SSH_KEY` gizli değerleri tanımlı değilse atlanır.
