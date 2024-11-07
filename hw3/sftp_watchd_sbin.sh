#!/bin/sh

# 記得讓他可執行: chmod 755 /sbin/sftp_watchd
public_dir=/home/sftp/public
hidden_dir=/home/sftp/hidden/.violated # 記得要創.violated的資料夾

while true; do
	for file in $(ls "$public_dir"); do # 檢查public裡面有沒有.exe檔
		echo "$public_dir/$file"
		mime_type=$(file --mime-type -b "$public_dir/$file")
		echo "mine_type: $mime_type"
		case "$mime_type" in
			*application*) 
				echo "gotcha"
				user=$(stat -f "%Su" "$public_dir/$file") # -f 代表顯示文件的擴展屬性，後面可以接特殊字，%su代表擁有者
				mv "$public_dir/$file" "$hidden_dir/$file"

				#需要在/etc/syslog.conf添加local1.warning                                  /var/log/sftp_watchd.log
				# 因為local1.warning這代表訊息的類別跟優先級，會自動去syslog.conf找
				# 記得sudo service syslogd restart
				# 還要記得先創/var/log/sftp_watchd.log，權限設644
				logger -p local1.warning "$public_dir/$file violate file detected. Uploaded by ${user}." # logger會自動顯示出Oct 9 17:47:25 freebsd-141 sftp_watchd[3256]:之類的
				;;
			*)
				;;
		esac
	done
done