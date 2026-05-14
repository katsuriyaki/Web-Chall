# 🔐 RKS CTF — Subdomain Takeover Challenge
> Domain: rksctfdlubawnk.pnc.ac.id | Politeknik Negeri Cilacap

---

## 📋 Deskripsi Challenge

> *Halo,*
>
> *Kami adalah tim di balik platform rksctfdlubawnk.pnc.ac.id. Kami memiliki beberapa subdomain — binggo untuk blog dan apanih untuk support.*
>
> *Baru-baru ini ada oknum yang mengklaim bisa men-takeover sesuatu dari infrastruktur kami dan meminta tebusan. Tolong bantu kami temukan apa yang bisa mereka ambil alih!*
>
> *Website kami: https://rksctfdlubawnk.pnc.ac.id*
>
> *Hint: Jangan lupa tambahkan IP target ke /etc/hosts untuk rksctfdlubawnk.pnc.ac.id ;)*

**Difficulty:** Easy  
**Category:** Web / Recon / Subdomain Enumeration  
**Flag:** `RKS{73rnY474_y4n6_p4l1n6_54k17_4d4l4h_b3rpur4_pur4_b41k_b41k_54j4}`

---

## 🚀 Setup & Menjalankan

### Requirement
- Docker + Docker Compose

### Jalankan
```bash
cd takeover-ctf
docker compose up -d
```

### Tambah ke /etc/hosts (di mesin attacker)
```
TARGET_IP   rksctfdlubawnk.pnc.ac.id
TARGET_IP   binggo.rksctfdlubawnk.pnc.ac.id
TARGET_IP   apanih.rksctfdlubawnk.pnc.ac.id
TARGET_IP   petunjukuntukdapat2004flag.apanih.rksctfdlubawnk.pnc.ac.id
```
> Kalau lokal: ganti `TARGET_IP` dengan `127.0.0.1`  
> Kalau di VM/server: ganti dengan IP mesin tersebut

### Stop
```bash
docker compose down
```

---

## 🏴 Solve Guide (SPOILER)

### Step 1 — Tambah domain ke hosts
```bash
echo "TARGET_IP rksctfdlubawnk.pnc.ac.id" | sudo tee -a /etc/hosts
```

### Step 2 — Port scan
```bash
nmap -sV TARGET_IP
# Output: 22/ssh, 80/http, 443/https
```

### Step 3 — Subdomain enumeration (vhost)

**Pakai ffuf:**
```bash
ffuf -H "Host: FUZZ.rksctfdlubawnk.pnc.ac.id" \
     -u https://TARGET_IP \
     -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt \
     -fs 0 -k
```

**Atau gobuster:**
```bash
gobuster vhost \
  -u https://rksctfdlubawnk.pnc.ac.id \
  -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt \
  --append-domain -k
```

**Ditemukan:**
- `binggo.rksctfdlubawnk.pnc.ac.id`
- `apanih.rksctfdlubawnk.pnc.ac.id`

### Step 4 — Tambah ke hosts
```bash
echo "TARGET_IP binggo.rksctfdlubawnk.pnc.ac.id apanih.rksctfdlubawnk.pnc.ac.id" | sudo tee -a /etc/hosts
```

### Step 5 — Inspect SSL cert apanih (INI KUNCINYA!)

**Pakai nmap:**
```bash
nmap -p 443 --script ssl-cert apanih.rksctfdlubawnk.pnc.ac.id
```

**Atau openssl:**
```bash
openssl s_client -connect apanih.rksctfdlubawnk.pnc.ac.id:443 2>/dev/null \
  | openssl x509 -text -noout | grep -A2 "Subject Alternative Name"
```

**Atau buka di browser:**
Klik ikon 🔒 di address bar → Certificate → Subject Alternative Names

**Output yang ditemukan:**
```
X509v3 Subject Alternative Name:
    DNS:apanih.rksctfdlubawnk.pnc.ac.id,
    DNS:petunjukuntukdapat2004flag.apanih.rksctfdlubawnk.pnc.ac.id
```
**🔑 Secret subdomain ketemu!**

### Step 6 — Akses secret subdomain
```bash
echo "TARGET_IP petunjukuntukdapat2004flag.apanih.rksctfdlubawnk.pnc.ac.id" | sudo tee -a /etc/hosts

curl http://petunjukuntukdapat2004flag.apanih.rksctfdlubawnk.pnc.ac.id
```

### 🏁 FLAG
```
RKS{73rnY474_y4n6_p4l1n6_54k17_4d4l4h_b3rpur4_pur4_b41k_b41k_54j4}
```

---

## 🗂️ Infrastruktur

```
rksctfdlubawnk.pnc.ac.id            (443 HTTPS) — Main site
├── binggo.rksctfdlubawnk.pnc.ac.id  (443 HTTPS) — Blog
├── apanih.rksctfdlubawnk.pnc.ac.id  (443 HTTPS) — Support
│       └── SSL cert SAN berisi:
│           petunjukuntukdapat2004flag.apanih.rksctfdlubawnk.pnc.ac.id
└── petunjukuntukdapat2004flag.apanih.rksctfdlubawnk.pnc.ac.id (80 HTTP) ← FLAG
```

---

## 📁 Struktur File

```
takeover-ctf/
├── docker-compose.yml
├── nginx/
│   ├── nginx.conf
│   ├── conf.d/
│   │   ├── futurevera.conf   → main domain
│   │   ├── blog.conf         → binggo
│   │   ├── support.conf      → apanih (pakai cert berisi SAN tersembunyi)
│   │   └── secret.conf       → petunjukuntukdapat2004flag.apanih... (HTTP, FLAG)
│   └── ssl/
│       ├── main.crt / main.key
│       ├── binggo.crt / binggo.key
│       └── apanih.crt / apanih.key  ← SAN: petunjukuntukdapat2004flag...
└── html/
    ├── futurevera/   ← main page
    ├── blog/         ← binggo page
    ├── support/      ← apanih page
    └── secret/       ← FLAG page
```

---

## 🎓 Lesson Learned

Subdomain lama yang DNS-nya tidak dibersihkan = attack surface terbuka. Attacker bisa:
1. Claim subdomain yang tidak dipakai di cloud (Netlify, Heroku, dll)
2. Host konten berbahaya di subdomain yang terlihat legitim
3. Phishing, cookie theft, session hijacking

**Defense:** Audit DNS record + SAN SSL cert secara rutin. Hapus subdomain yang tidak aktif.
