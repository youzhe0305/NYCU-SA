sudo mkdir /home/sftp
sudo mkdir /home/sftp/public
sudo mkdir /home/sftp/hidden

cd /home
chmod 755 sftp
sudo setfacl -m user:sysadm:rwxpDdaARWcCos::allow sftp
sudo setfacl -m user:sysadm:rwxpDdaARWcCos::allow sftp/public
sudo setfacl -m user:sysadm:rwxpDdaARWcCos::allow sftp/hidden

cd sftp
sudo chmod 775 public
sudo chmod +t public
sudo chmod 771 hidden

sudo mkdir treasure
cd treasure
sudo touch secret


### 如果遇到gptid出問題，請改:
sudo sysctl kern.geom.label.gpt.enable=1
sudo sysctl kern.geom.label.gptid.enable=1
sudo sysctl kern.geom.label.disk_ident.enable=1
#也可以直接改sysctl之類的檔案，讓他重開機還是在，這個要問GPT

### 如果遇到無法ssh進來，但是已經放authorized_keys的狀況
### 很有可能是因為已經換掉sysadm的home，導致authorized_keys放錯地方
