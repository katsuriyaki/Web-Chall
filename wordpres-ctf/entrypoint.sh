#!/bin/bash
set -e

echo "[*] Setar WEB CTF setup..."

mkdir -p /var/run/mysqld /var/log/mysql
chown -R mysql:mysql /var/run/mysqld /var/log/mysql
chmod 777 /var/run/mysqld

echo "[*] Initializing MySQL..."
rm -rf /var/lib/mysql/*
mkdir -p /var/lib/mysql
chown -R mysql:mysql /var/lib/mysql
mysqld --initialize-insecure --user=mysql --datadir=/var/lib/mysql
echo "[+] MySQL initialized"

mysqld --user=mysql &
MYSQL_PID=$!

for i in $(seq 1 30); do
    if [ -S /var/run/mysqld/mysqld.sock ]; then
        echo "[+] MySQL socket ready"
        break
    fi
    echo "    waiting... ($i/30)"
    sleep 2
done

if ! [ -S /var/run/mysqld/mysqld.sock ]; then
    echo "[!] MySQL failed"
    cat /var/log/mysql/error.log 2>/dev/null
    exit 1
fi

mysql --socket=/var/run/mysqld/mysqld.sock -u root <<SQL
CREATE DATABASE IF NOT EXISTS wpcyscom CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'cyscomgen2024'@'localhost' IDENTIFIED BY 'CysComG2024EN@!';
GRANT ALL PRIVILEGES ON wpcyscom.* TO 'cyscomgen2024'@'localhost';
FLUSH PRIVILEGES;
SQL

echo "[+] MySQL ready"

cd /var/www/html
if [ ! -f wp-config.php ]; then
    wp config create --dbname=wpcyscom --dbuser=cyscomgen2024 --dbpass='CysComG2024EN@!' --dbhost=localhost --allow-root
    wp config set AUTOMATIC_UPDATER_DISABLED true --raw --allow-root
    wp config set WP_AUTO_UPDATE_CORE false --raw --allow-root
fi
if ! wp core is-installed --allow-root 2>/dev/null; then
    wp core install --url="http://cyscom.pnc.ac.id" --title="Cyscom" --admin_user="atnan" --admin_password="AtnanMagwrBangets" --admin_email="atnan@cyscom.pnc" --allow-root
fi
echo "[+] WordPress installed"

if ! wp user get syam --allow-root &>/dev/null; then
    wp user create syam syam@cyscom.pnc --role=author --user_pass="Eurovision" --display_name="Syam Tidwur" --allow-root
fi
if ! wp user get nura --allow-root &>/dev/null; then
    wp user create nura nura@cyscom.pnc --role=author --user_pass="greatest1" --display_name="Nura Turwu" --allow-root
fi
wp user update atnan --display_name="Atnan Magerk" --allow-root
echo "[+] Users created"

SYAM_ID=$(wp user get syam --field=ID --allow-root)
ATNAN_ID=$(wp user get atnan --field=ID --allow-root)
NURA_ID=$(wp user get nura --field=ID --allow-root)
POST_COUNT=$(wp post list --post_type=post --post_status=publish --format=count --allow-root 2>/dev/null || echo "0")
if [ "$POST_COUNT" -lt 3 ]; then
    wp post create --post_title="Perusaahaan Tidak Mau Bayar" --post_content="<p>Perusahaan tidak membayar dan data bocor ke publik. Reputasi hancur dan bangkrut.</p>" --post_status=publish --post_author=$NURA_ID --allow-root
    wp post create --post_title="Kebocoran data di perusahaan" --post_content="<p>Perusahaan saya telah di retas oleh kelompok blackhat bernama Eur0v1s1n, meminta tebusan 500 juta.</p>" --post_status=publish --post_author=$SYAM_ID --allow-root
    wp post create --post_title="Selamat datang di Web Orang Pemalas" --post_content="<p>Di malam hari sekitar jam 00:00-03:20 saya mendapat telpon dari perusahaan temapt saya bekerja.</p><p>- BlueSecc</p>" --post_status=publish --post_author=$ATNAN_ID --allow-root
    wp post delete 1 --force --allow-root 2>/dev/null || true
fi
echo "[+] Blog posts created"
# ─── Custom Theme CSS ─────────────────────────────────────
cat > /tmp/cyscom.css << 'CSSEOF'
@import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&family=Space+Mono:wght@400;700&display=swap');

:root {
    --pink: #ff6b9d;
    --pink-dark: #c44569;
    --bg: #0d0d14;
    --card: rgba(255,255,255,0.04);
    --border: rgba(255,107,157,0.18);
    --text: #f0f0f0;
    --muted: #888899;
}

* { box-sizing: border-box; }

body {
    font-family: 'Poppins', sans-serif !important;
    background: var(--bg) !important;
    background-image:
        radial-gradient(ellipse at 10% 20%, rgba(255,107,157,0.12) 0%, transparent 55%),
        radial-gradient(ellipse at 90% 80%, rgba(196,69,105,0.08) 0%, transparent 55%) !important;
    color: var(--text) !important;
}

/* ── Header ── */
#masthead {
    background: rgba(13,13,20,0.97) !important;
    backdrop-filter: blur(20px) !important;
    border-bottom: 1px solid var(--border) !important;
    position: sticky !important;
    top: 0 !important;
    z-index: 999 !important;
}

.site-title a {
    font-family: 'Space Mono', monospace !important;
    font-size: 1.4rem !important;
    font-weight: 700 !important;
    color: var(--pink) !important;
    text-decoration: none !important;
}

.site-title a::before { content: '◈ '; }

.site-description {
    color: var(--muted) !important;
    font-size: 0.75rem !important;
    text-transform: uppercase !important;
    letter-spacing: 0.12em !important;
}

/* ── Navigation ── */
.main-navigation a {
    color: var(--muted) !important;
    font-size: 0.85rem !important;
    font-weight: 500 !important;
    transition: color 0.2s !important;
}
.main-navigation a:hover { color: var(--pink) !important; }

/* ── Posts / Cards ── */
.hentry, article.post, article.page {
    background: var(--card) !important;
    border: 1px solid var(--border) !important;
    border-radius: 16px !important;
    padding: 2rem !important;
    margin-bottom: 1.8rem !important;
    transition: border-color 0.3s, transform 0.2s, box-shadow 0.3s !important;
    backdrop-filter: blur(8px) !important;
}

.hentry:hover, article.post:hover {
    border-color: rgba(255,107,157,0.45) !important;
    transform: translateY(-3px) !important;
    box-shadow: 0 12px 40px rgba(255,107,157,0.12) !important;
}

.entry-title { margin-bottom: 0.5rem !important; }

.entry-title a {
    color: var(--text) !important;
    font-weight: 700 !important;
    font-size: 1.35rem !important;
    text-decoration: none !important;
    transition: color 0.2s !important;
    line-height: 1.3 !important;
}
.entry-title a:hover { color: var(--pink) !important; }

.entry-meta, .entry-meta a { color: var(--muted) !important; font-size: 0.8rem !important; }
.entry-meta a { color: var(--pink) !important; text-decoration: none !important; }

.entry-content {
    color: rgba(240,240,240,0.75) !important;
    line-height: 1.85 !important;
    font-size: 0.95rem !important;
    margin-top: 1rem !important;
}

/* ── Buttons ── */
.more-link, .button, input[type="submit"], button {
    background: linear-gradient(135deg, var(--pink), var(--pink-dark)) !important;
    color: white !important;
    border: none !important;
    border-radius: 8px !important;
    padding: 0.55rem 1.3rem !important;
    font-family: 'Poppins', sans-serif !important;
    font-weight: 600 !important;
    font-size: 0.83rem !important;
    text-decoration: none !important;
    display: inline-block !important;
    cursor: pointer !important;
    transition: opacity 0.2s, transform 0.15s !important;
}
.more-link:hover, .button:hover, input[type="submit"]:hover {
    opacity: 0.82 !important;
    transform: translateY(-1px) !important;
    color: white !important;
}

/* ── Sidebar ── */
#secondary {
    background: var(--card) !important;
    border: 1px solid var(--border) !important;
    border-radius: 16px !important;
    padding: 1.5rem !important;
}
.widget-title {
    font-family: 'Space Mono', monospace !important;
    color: var(--pink) !important;
    font-size: 0.78rem !important;
    text-transform: uppercase !important;
    letter-spacing: 0.12em !important;
    border-bottom: 1px solid var(--border) !important;
    padding-bottom: 0.6rem !important;
    margin-bottom: 1rem !important;
}
.widget a { color: var(--muted) !important; text-decoration: none !important; }
.widget a:hover { color: var(--pink) !important; }

/* ── Footer ── */
#colophon {
    background: rgba(13,13,20,0.98) !important;
    border-top: 1px solid var(--border) !important;
    text-align: center !important;
    padding: 2rem !important;
    color: var(--muted) !important;
    font-size: 0.78rem !important;
    margin-top: 3rem !important;
}
#colophon a { color: var(--pink) !important; }

/* ── Tags & Cats ── */
.cat-links a, .tags-links a {
    background: rgba(255,107,157,0.1) !important;
    color: var(--pink) !important;
    padding: 0.15rem 0.55rem !important;
    border-radius: 5px !important;
    font-size: 0.73rem !important;
    border: 1px solid rgba(255,107,157,0.2) !important;
    text-decoration: none !important;
}

/* ── Inputs ── */
input[type="text"], input[type="email"], input[type="password"], textarea, input[type="search"] {
    background: rgba(255,255,255,0.05) !important;
    border: 1px solid var(--border) !important;
    border-radius: 8px !important;
    color: var(--text) !important;
    padding: 0.55rem 1rem !important;
    font-family: 'Poppins', sans-serif !important;
}
input:focus, textarea:focus {
    border-color: var(--pink) !important;
    outline: none !important;
    box-shadow: 0 0 0 3px rgba(255,107,157,0.12) !important;
}

/* ── Scrollbar ── */
::-webkit-scrollbar { width: 5px; }
::-webkit-scrollbar-track { background: var(--bg); }
::-webkit-scrollbar-thumb { background: var(--pink-dark); border-radius: 3px; }
::selection { background: rgba(255,107,157,0.25); }

/* ── Admin bar ── */
#wpadminbar { background: #0d0d14 !important; border-bottom: 1px solid var(--border) !important; }
CSSEOF

wp eval '
$css = file_get_contents("/tmp/cyscom.css");
$theme = wp_get_theme()->get_stylesheet();
wp_update_custom_css_post($css, array("stylesheet" => $theme));
echo "[+] CysCom CSS injected\n";
' --allow-root

wp option update blogname "CysCom" --allow-root
wp option update blogdescription "Cyber Community — Politeknik Negeri Cilacap" --allow-root
echo "[+] Site identity updated"

# ─── Logo & Splash Screen ─────────────────────────────────
mkdir -p /var/www/html/wp-content/mu-plugins
LOGO_ID=$(wp media import /opt/cyscom-logo.png --title="CysCom Logo" --allow-root --porcelain)
wp option update site_icon $LOGO_ID --allow-root
wp theme mod set custom_logo $LOGO_ID --allow-root
echo "[+] Logo set"

wp eval '
$splash = <<<HTML
<style>
#cyscom-splash {
    position: fixed;
    inset: 0;
    z-index: 99999;
    background: #0d0d14;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 1.5rem;
    animation: splashFade 0.5s ease 2.8s forwards;
}
#cyscom-splash img {
    width: 120px;
    height: 120px;
    object-fit: contain;
    animation: splashPop 0.6s cubic-bezier(0.34,1.56,0.64,1) 0.3s both;
}
#cyscom-splash .splash-title {
    font-family: "Space Mono", monospace;
    font-size: 2rem;
    font-weight: 700;
    color: #ff6b9d;
    animation: splashUp 0.5s ease 0.8s both;
    letter-spacing: -0.02em;
}
#cyscom-splash .splash-sub {
    font-family: "Poppins", sans-serif;
    font-size: 0.85rem;
    color: #888899;
    text-transform: uppercase;
    letter-spacing: 0.15em;
    animation: splashUp 0.5s ease 1s both;
}
#cyscom-splash .splash-divider {
    width: 60px;
    height: 2px;
    background: linear-gradient(90deg, #ff6b9d, #c44569);
    border-radius: 2px;
    animation: splashUp 0.5s ease 0.9s both;
}
#cyscom-splash .splash-dots {
    display: flex;
    gap: 6px;
    animation: splashUp 0.5s ease 1.2s both;
}
#cyscom-splash .splash-dots span {
    width: 7px;
    height: 7px;
    background: #ff6b9d;
    border-radius: 50%;
    opacity: 0.3;
    animation: dotPulse 1s ease infinite;
}
#cyscom-splash .splash-dots span:nth-child(2) { animation-delay: 0.2s; }
#cyscom-splash .splash-dots span:nth-child(3) { animation-delay: 0.4s; }

@keyframes splashFade { to { opacity: 0; pointer-events: none; } }
@keyframes splashPop  { from { opacity: 0; transform: scale(0.5); } to { opacity: 1; transform: scale(1); } }
@keyframes splashUp   { from { opacity: 0; transform: translateY(16px); } to { opacity: 1; transform: translateY(0); } }
@keyframes dotPulse   { 0%,100% { opacity: 0.3; } 50% { opacity: 1; } }
</style>

<div id="cyscom-splash">
    <img src="/wp-content/uploads/2026/05/cyscom-logo.png" alt="CysCom Logo" onerror="this.style.display=none">
    <div class="splash-title">CysCom</div>
    <div class="splash-divider"></div>
    <div class="splash-sub">CyberComunity &mdash; Politeknik Negeri Cilacap</div>
    <div class="splash-dots"><span></span><span></span><span></span></div>
</div>

<script>
(function(){
    if(sessionStorage.getItem("cyscom_splash")) {
        document.getElementById("cyscom-splash").remove();
        return;
    }
    sessionStorage.setItem("cyscom_splash","1");
    setTimeout(function(){
        var el = document.getElementById("cyscom-splash");
        if(el) el.remove();
    }, 3300);
})();
</script>
HTML;

add_action("wp_footer", function() use ($splash) {
    echo $splash;
}, 999);

// Simpan ke option biar persistent
update_option("cyscom_splash_html", $splash);

// Inject via wp_footer hook permanent
$current = get_option("theme_mods_twentyseventeen", []);
update_option("theme_mods_twentyseventeen", $current);

// Buat mu-plugin biar splash permanent
$muplugin = "<?php\nadd_action(\"wp_footer\", function(){\n    echo get_option(\"cyscom_splash_html\");\n}, 999);";
file_put_contents(WPMU_PLUGIN_DIR . "/cyscom-splash.php", $muplugin);
echo "[+] Splash screen installed\n";
' --allow-root

cat > /etc/apache2/sites-available/000-default.conf <<'APACHE'
<VirtualHost *:80>
    ServerName cyscom.pnc.ac.id
    DocumentRoot /var/www/html
    <Directory /var/www/html>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
APACHE

chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

id atnan &>/dev/null || useradd -m -s /bin/bash atnan
echo "atnan:AtnanMagwrBangets" | chpasswd
echo "RKS{5e5e0r4n6_t0l0n6_b3r1th4u_54y4}" > /home/atnan/user.txt
chmod 644 /home/atnan/user.txt && chown atnan:atnan /home/atnan/user.txt

mkdir -p /opt/lohapanich
echo "RKS{b3r1_t4hu_54y4_c4r4_m3ny4t4k4n_p3r4544n}" > /opt/lohapanich/user.txt
chmod 644 /opt/lohapanich/user.txt
echo "RKS{4gHHh_d14_p3r61_54n64t_j4uh_1_m155_u}" > /root/root.txt
chmod 600 /root/root.txt
echo "[+] Flags placed"

[ -f /usr/bin/syscheck.c ] && gcc /usr/bin/syscheck.c -o /usr/sbin/syscheck && chown root:root /usr/sbin/syscheck && chmod 4755 /usr/sbin/syscheck && echo "[+] syscheck SUID set"

mkdir -p /var/run/sshd
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
grep -q "^AllowUsers atnan" /etc/ssh/sshd_config || echo "AllowUsers atnan" >> /etc/ssh/sshd_config
/usr/sbin/sshd
echo "[+] SSH started"

smbd --daemon 2>/dev/null || true
nmbd --daemon 2>/dev/null || true
echo "[+] Samba started"

sed -i 's/^disable_functions.*/disable_functions =/' /etc/php/7.4/apache2/php.ini
apachectl start
echo "[+] Apache started"

echo "=========================================="
echo "  WEB CTF udh jdi bozeh"
echo "  http://cyscom.pnc.ac.id"
echo "=========================================="

wait $MYSQL_PID
