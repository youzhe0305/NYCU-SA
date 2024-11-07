#!/bin/sh
# 先開wireguard
sudo wg-quick up wg0

cd /dev
# 把ada1掛上GPT的scheme
sudo gpart create -s GPT ada1
sudo gpart create -s GPT ada2
sudo gpart create -s GPT ada3
sudo gpart create -s GPT ada4

# 標label跟type
sudo gpart add -t freebsd-zfs -l mypool-1 ada1
sudo gpart add -t freebsd-zfs -l mypool-2 ada2
sudo gpart add -t freebsd-zfs -l mypool-3 ada3
sudo gpart add -t freebsd-zfs -l mypool-4 ada4
# 查看有沒有標對
gpart show
gpart show -l /dev/ada1
...

# enable gpt id (我已經設成開機自動有了，可以用沒有=1跟sudo的指令檢查)
sudo sysctl kern.geom.label.gpt.enable=1
sudo sysctl kern.geom.label.gptid.enable=1
sudo sysctl kern.geom.label.disk_ident.enable=1

# 創一個zfs pool，放四個參數，自動分成RAID10
sudo zpool create mypool mirror /dev/gpt/mypool-1 /dev/gpt/mypool-2 mirror /dev/gpt/mypool-3 /dev/gpt/mypool-4

# mount zfs到/home/sftp 
sudo zfs set mountpoint=/home/sftp mypool

# 用df可以看有沒有掛載成功
df
# 看其他資訊:
zpool list
zpool status mypool
# 設定開機自啟動，會將 zfs_enable="YES" 添加到 /etc/rc.conf
sysrc zfs_enable="YES"

# 啟用LZ4壓縮跟取消atime，減少磁碟操作
cd /home/sftp
sudo zfs create mypool/public
sudo zfs create mypool/hidden
sudo zfs set compression=lz4 mypool/public
sudo zfs set compression=lz4 mypool/hidden
sudo zfs set compression=lz4 mypool
sudo zfs set atime=off mypool/public
sudo zfs set atime=off mypool/hidden
sudo zfs set atime=off mypool
# 檢查有沒有成功改到設定，顯示local是指設定是直接設定在public, hidden而非繼承自父級
zfs get compression,atime mypool/public
zfs get compression,atime mypool/hidden
zfs get compression,atime mypool



### 補充

# 使用zfsbak的import新增一個pool之後，要先unmount才能把它用rm -rf砍掉
sudo zfs unmount mypool/public2
sudo rm -rf /home/sftp/public2