# 01 紀錄log

sudo touch /var/log/sftp.log
sudo chmod 644 /var/log/sftp.log

# 修改/etc/ssh/sshd_config以下:
Subsystem sftp internal-sftp -f LOCAL5 -l INFO

# 修改/etc/syslog.conf如下:
local5.info                                        /var/log/sftp.log


# 重新啟動ssh, syslog:
sudo service sshd restart
sudo service syslogd restart

