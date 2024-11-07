# 01 紀錄log

sudo touch /var/log/sftp.log
sudo chmod 644 /var/log/sftp.log

# 修改/etc/ssh/sshd_config以下:
Subsystem sftp internal-sftp -f LOCAL5 -l INFO # -f AUTH: 意味著 SFTP 日誌會標記為 AUTH facility(驗證設施), -l INFO: level-INFO 可以記錄一般的 SFTP 活動，但略過debuf

# 修改/etc/syslog.conf如下:
local5.info                                        /var/log/sftp.log


# 重新啟動ssh, syslog:
sudo service sshd restart
sudo service syslogd restart

