sudo apt install nginx

# 編輯 /etc/hosts
sudo vim /etc/hosts
# 加入: 在本地使用這些網址時，會指向localhost，方便測試用
    127.0.0.1 nasa.105.cs.nycu
    127.0.0.1 file.105.cs.nycu
    127.0.0.1 adminer.105.cs.nycu

# 安裝dnsmasq
sudo pkg install dnsmasq
sudo vim /usr/local/etc/dnsmasq.conf # 改設定
    address=/.105.cs.nycu/127.0.0.1

# 更改依賴的DNS解析伺服器
sudo vim /etc/resolv.conf
nameserver 127.0.0.1
nameserver 8.8.8.8
nameserver 140.113.1.1
nameserver 140.113.6.2


# 編輯nginx的設定
sudo vim /usr/local/etc/nginx/nginx.conf

sudo nginx -t # 確認有沒有語法錯誤
sudo nginx -s reload # 重新加載配置
sudo service nginx onerestart # 重新啟動

curl http://any.105.cs.nycu # 測試有沒有成功
curl -I https://nasa.105.cs.nycu

# 創建CA
sudo openssl genrsa -out  /home/judge/ca.key 2048 # 這會生成一個 2048 位的 RSA 私鑰
sudo openssl req -x509 -new -nodes -key /home/judge/ca.key -sha256 -days 3650 -out /home/judge/ca.crt # 生成證書簽名請求
sudo cp /home/judge/ca.crt /usr/local/share/certs/
sudo certctl rehash # 掃描並信任/usr/local/share/certs/, /usr/share/certs/untrusted, /usr/share/certs/trusted等等的證書
sudo openssl verify -CAfile /home/judge/ca.crt /home/judge/ca.crt # 驗證CA是否被信任，看有沒有顯示OK
# 用CA來簽署其他證書
sudo openssl genrsa -out /home/judge/wildcard.key 2048
sudo openssl req -new -key /home/judge/wildcard.key -out /home/judge/wildcard.csr
sudo openssl x509 -req -in /home/judge/wildcard.csr -CA /home/judge/ca.crt -CAkey /home/judge/ca.key -CAcreateserial -out /home/judge/wildcard.crt -days 365 -sha256

#  HTTP 基本身份驗證 (Basic Authentication)
sudo pkg install apache24
htpasswd -c /home/judge/.htpasswd sa-admin

# 繼續改nginx.conf


# 配置/usr/local/etc/logrotate.d/webserver

/home/judge/webserver/log/access.log {
    size 300
    compress
    compresscmd /usr/bin/gzip
    maxsize 300
    minsize 150
    rotate 3
    missingok
    notifempty
    create 0640 judge judge
    olddir /home/judge/webserver/log/
    postrotate
        gzip /home/judge/webserver/log/access.log.1
        gzip /home/judge/webserver/log/access.log.2
        gzip /home/judge/webserver/log/access.log.3
        # 重命名壓縮的日誌文件
        mv /home/judge/webserver/log/access.log.1.gz /home/judge/webserver/log/compressed.log.1.gz
        mv /home/judge/webserver/log/access.log.2.gz /home/judge/webserver/log/compressed.log.2.gz
        mv /home/judge/webserver/log/access.log.3.gz /home/judge/webserver/log/compressed.log.3.gz
    endscript
}

# size 300：当日志文件大于 300 字节时进行轮转。
# minsize 150：只有文件大小超过 150 字节时才会检查是否需要轮转。
# rotate 3：最多保留 3 个压缩的日志文件。
# compress：压缩旧日志。
# compresscmd /usr/bin/gzip：指定使用 gzip 压缩。
# missingok：如果日志文件不存在，不报错。
# notifempty：如果文件为空，不进行轮转。
# olddir /home/judge/webserver/log/：将旧的日志文件存储到目标目录中。

# 測試輪轉
logrotate -d /usr/local/etc/logrotate.d/webserver
# 正式使用
sudo logrotate /usr/local/etc/logrotate.d/webserver

# Database
# 在VM插入更多的3網卡:
# 接著進去改第i張卡的ip
sudo ifconfig em1 inet 192.168.105.1 netmask 255.255.255.0
sudo ifconfig em2 inet 192.168.105.2 netmask 255.255.255.0
sudo ifconfig em3 inet 192.168.105.0 netmask 255.255.255.0

sudo pkg install postgresql15-server postgresql15-client

sudo sysrc postgresql_enable="YES"
sudo service postgresql initdb
sudo service postgresql start

sudo su - postgres
psql
CREATE USER root WITH PASSWORD 'sa-hw4-105';
CREATE DATABASE "sa-hw4";
GRANT ALL PRIVILEGES ON DATABASE "sa-hw4" TO root;
\q
psql -d sa-hw4
GRANT ALL PRIVILEGES ON SCHEMA public TO root;
# 退出並改用root登入
psql -U root -d sa-hw4
CREATE TABLE "user" (
    id SERIAL PRIMARY KEY,
    name TEXT,
    age INTEGER,
    birthday DATE
);


# 測試API
# SQL
insert into "user" (id, name, age, birthday) values (529, 'nijika', 18, '2006-05-29');

curl http://192.168.105.1:8080/ip
curl -X 'POST' \
  'http://192.168.105.1:8080/upload' \
  -F 'file=@upload_test1.txt'
curl -O http://192.168.105.1:8080/file/upload_test1.txt
curl http://192.168.105.1:8080/db/nijika

# Adminer
sudo pkg install php82 php82-mysqli
sudo sysrc php_fpm_enable=YES
sudo service php-fpm start

cd /usr/local/www/nginx
sudo wget https://www.adminer.org/latest.php -O adminer.php
# 修改postgres設定，讓他可以被adminer連到
sudo su - postgres
cd /var/db/postgres/data15
vim /var/db/postgres/data15/pg_hba.conf
# 貼上
host    all             all             192.168.105.1/32          md5
# 改nginx.conf
sudo vim /usr/local/etc/nginx/nginx.conf
sudo nginx -t
sudo nginx -s reload
sudo service nginx onerestart

# 修改/var/db/postgres/data15/postgresql.conf
sudo vim /var/db/postgres/data15/postgresql.conf
# 加入:
listen_addresses = '*'

# 測試
psql -h 192.168.105.1 -U root -d sa-hw4
curl https://adminer.105.cs.nycu

# ... 東西挺複雜，先不記了


# FireWall
sysrc firewall_script="/etc/ipfw.rules"
sudo sysrc firewall_script="/etc/ipfw.rules"
sudo vim /etc/ipfw.rules
service ipfw start

sudo pkg install py311-fail2ban
sudo cp /usr/local/etc/fail2ban/jail.conf /usr/local/etc/fail2ban/jail.local
sudo vim /usr/local/etc/fail2ban/jail.local

    [DEFAULT]
    # Ban 時間（秒），設置為 60 秒
    bantime = 60
    # 記錄失敗次數的時間窗口（秒）
    findtime = 300
    # 最大嘗試次數
    maxretry = 3
    # 使用的防火牆動作
    backend = auto
    banaction = ipfw

    [sshd]
    enabled = true
    port = ssh
    filter = sshd
    logpath = /var/log/auth.log
    maxretry = 3

sudo touch /usr/local/etc/fail2ban/action.d/ipfw.conf
sudo vim /usr/local/etc/fail2ban/action.d/ipfw.conf
    [Definition]
    # actionstart = ipfw -q -f flush
    actionban = ipfw add 100 deny tcp from <ip> to any 22
    actionunban = ipfw delete 100 deny tcp from <ip> to any 22

# nfs...
sudo sysrc rpcbind_enable="YES"
sudo sysrc nfs_server_enable="YES"
sudo sysrc mountd_enable="YES"
sudo sysrc mountd_flags="-r"

sudo service rpcbind start
sudo service nfsd start
sudo service mountd start





sudo service dnsmasq onestart