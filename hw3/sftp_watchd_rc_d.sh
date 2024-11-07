#!/bin/sh
# 記得讓他可執行: chmod 755 /etc/rc.d/sftp_watchd

# 還要:
# sudo touch /var/run/sftp_watchd.pid
# sudo chmod 777 /var/run/sftp_watchd.pid
# 確保pid這個檔案存在並可以access
# secret-7c928944.bin

# . /path是source的縮寫，在當前shell(process)執行這個檔案，也就是會把變數、函式之類的引進來
. /etc/rc.subr # 可以使用 rc.subr裡面提供的函數或變數


name=sftp_watchd
rcvar=sftp_watchd_enable # rcvar用來控制服務是否在開機時啟動

load_rc_config $name # 讀取/etc/rc.conf的name(sftp_watchd)配置，如果sftp_watchd_enable="YES"，那就啟動
sftp_watchd_enable=${sftp_watchd_enable:-"NO"} # 空值就關掉它(預設不啟動)


command="/sbin/${name}" # sftp_watchd腳本的執行路徑，sbin是system binary，也就是裡面存放的執行檔是用來做系統服務的
pidfile="/var/run/$name.pid" # 儲存process id的路徑，可以幫助做其他操作
required_files="/sbin/${name}" # 需要這個執行路徑(sftp_watchd)存在

extra_commands="status" # 額外指令，允許檢查服務狀態
start_cmd="sftp_watchd_start" # 啟動之類的會對應的函數，下面以此類推
stop_cmd="sftp_watchd_stop"
restart_cmd="sftp_watchd_restart"
status_cmd="sftp_watchd_status"


sftp_watchd_start() {
	echo "Starting sftp_watchd."
	/usr/sbin/daemon -f -p "${pidfile}" "${command}" # daemon是用來在背景執行的工具 -f 指讓他在前台運行 -p 會把process id寫入對應文件，最後接要執行的
}
sftp_watchd_stop() {
	pid=$(cat $pidfile)
	pid_info=$(ps -p $pid -o pid=) # -o pid代表顯示pid，=代表不顯示標題，確保process不存在時回傳空的
	echo "Kill: $(test -n "$pid_info" && echo "$pid")" # 檢查pid還在不在，存在就砍掉 pid
	if [ -n "$pid_info" ] ; then
		kill $pid
	fi
}
sftp_watchd_restart() {
	sftp_watchd_stop
	sleep 0.3 # 停一下，避免還沒完全kill掉就又開始
	sftp_watchd_start
}
sftp_watchd_status() {
	pid=`cat $pidfile`
	echo "sftp_watchd is running as pid $pid."
}


run_rc_command "$1" # 拿到的參數通常是service sftp_watchd start的start或之類的，這是rc.subr的函數，會去叫跟啟動某個服務