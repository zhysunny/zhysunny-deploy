#!/usr/bin/env bash
    
# Author : 章云
# Date   : 2019/9/1 11:35


expect <<EOF
spawn ssh root@192.168.1.44
expect {
    "yes/no" { send "yes\n";exp_continue}
    "password" { send "123456\n"}
}
if [[ ! -e "/root/.ssh/id_rsa.pub" ]]
then
    ssh-keygen -t rsa -P '' -f "/root/.ssh/id_rsa"
fi
expect eof
EOF
