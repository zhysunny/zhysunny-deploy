#!/bin/sh
   
# Author      : 章云
# Date        : 2019/10/14 17:10
# Description : 设置免秘钥，最好在设置完静态IP和域名以后执行脚本
# 所有节点必须安装expect，安装命令 yum install expect
# 目前只支持单机版

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

# 使用密码ssh登录虚拟机
login_for_secret(){
expect <<EOF
spawn ssh ${username}@$1
expect {
    "yes/no" { send "yes\n";exp_continue}
    "password" { send "${password}\n"}
}
expect eof
EOF
}

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
# 所有节点的秘钥，用于写入authorized_keys文件
authorized_keys=""
# ip host 列表，用于写入/etc/hosts文件
declare -a ip_host_arrays
# ip host 列表的索引
index=0
# 循环节点列表
for ip in ${arrays[*]}
do
    # 先登录
    login_for_secret ${ip}
    # 判断是否有秘钥文件
    secret_file=${ssh_path}"/id_rsa.pub"
    if [[ ! -e "${secret_file}" ]]
    then
        ssh-keygen -t rsa -P '' -f "${ssh_path}/id_rsa"
    fi
    # 读取id_rsa.pub文件
    authorized_keys=`cat ${secret_file}`"\n"
    hostname=`hostname`
    ip_host_arrays[${index}]=${ip}=${hostname}
    index=${index}+1
done

# 编辑/etc/hosts文件
cp /etc/hosts ./hosts
for ip_host in ${ip_host_arrays[*]}
do
    ip=`echo ${ip_host} | awk -F= '{print $1}'`
    hostname=`echo ${ip_host} | awk -F= '{print $2}'`
    ${LOCAL_PATH}/properties_config_tools.sh put "hosts" ${ip} ${hostname} 2
done
# 编辑authorized_keys文件
echo -e ${authorized_keys} > "authorized_keys"
cp ${ssh_path}"/known_hosts" ./known_hosts

# 将/etc/hosts、authorized_keys、known_hosts(免密文件所在目录)文件复制到每个节点上
for ip in ${arrays[*]}
do
expect <<EOF
spawn scp hosts ${ip}:/etc
expect {
    "yes/no" { send "yes\n";exp_continue}
    "password" { send "${password}\n"}
}
expect "*#"
spawn scp authorized_keys ${ip}:${ssh_path}
expect {
    "yes/no" { send "yes\n";exp_continue}
    "password" { send "${password}\n"}
}
expect "*#"
spawn scp known_hosts ${ip}:${ssh_path}
expect {
    "yes/no" { send "yes\n";exp_continue}
    "password" { send "${password}\n"}
}
expect "*#"
EOF
done

rm -rf hosts
rm -rf authorized_keys
rm -rf known_hosts
