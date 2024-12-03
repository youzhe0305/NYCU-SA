# 清除現有規則
ipfw -q -f flush

# 默認策略：拒絕所有流量
# ipfw add 00010 deny all from any to any

# 允許來自 192.168.{ID}.0/24 的 ICMP echo-request
ipfw add 100 allow icmp from 192.168.105.0/24 to any icmptypes 8

# 拒絕其他來源的 ICMP echo-request
ipfw add 200 deny icmp from any to any icmptypes 8

# 允許ssh進去
ipfw add 300 allow tcp from any to me 22 setup keep-state

ipfw add 400 allow tcp from any to me 80,443 setup keep-state

ipfw add 500 allow tcp from 192.168.105.0/24 to me 8080 setup keep-state

ipfw add 600 deny tcp from any to me 8080

# 允許所有其他流量 (根據需求可調整)
ipfw add 65000 allow ip from any to any