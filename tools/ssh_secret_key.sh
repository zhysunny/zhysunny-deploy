#!/bin/sh
   
# Author      : 章云
# Date        : 2019/10/17 17:10
# Description : 设置免秘钥，最好在设置完静态IP和域名以后执行脚本
# 执行节点必须安装expect，安装命令 yum install expect
# 依赖:
#   function.sh
#   lib/zhysunny-shell-tool-*.jar

Usage()
{
    echo "Usage: "
    echo "sh ssh_secret_key.sh <ip_string> <password> <username:root>"
    echo "多个IP地址以","分隔。可输入ip范围，以"-"分隔。"
    echo "如：192.9.200.164,192.9.200.190-192.9.200.194,192.9.200.198"
    echo "username 用户名 password 用户名对应的密码 username默认是root"
    exit 1
}

if [[ $# -lt 2 ]]
then
    Usage
    exit 1
fi

# 当前文件所在目录，这里是相对路径
LOCAL_PATH=`dirname $0`
# 当前文件所在目录转为绝对路径
LOCAL_PATH=`cd ${LOCAL_PATH};pwd`
# ip字符串分割方法
source ${LOCAL_PATH}/function.sh
splitIp $1
# 用户名密码，用户名默认是root
password=$2
username=$3
if [[ -z "${username}" ]]
then
    username="root"
fi
# 免秘钥路径
ssh_path="/root/.ssh"
if [[ "${username}" != "root" ]]
then
    ssh_path="/home/${username}/.ssh"
fi

# 执行java程序，生成hosts和authorized_keys文件并分发到各个节点
java -cp ${LOCAL_PATH}/lib/zhysunny-shell-tool-*.jar com.zhysunny.tool.shell.main.AuthorizedKeys $1 ${username} ${password}

# 对于known_hosts认证尚未解决
# 循环节点列表
for ip in ${arrays[*]}
do
    hostname=`cat /etc/hosts | grep ${ip} | awk '{print $2}'`
    expect <<EOF
spawn ssh ${username}@${hostname}
expect {
    "yes/no" { send "yes\n";exp_continue}
}
expect eof
EOF
done

cp ${ssh_path}"/known_hosts" ./known_hosts

for ip in ${arrays[*]}
do
    scp ./known_hosts ${ip}:${ssh_path}
done

rm -rf known_hosts

echo "免秘钥配置完成"
