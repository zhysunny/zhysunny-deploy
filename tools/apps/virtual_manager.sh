#!/usr/bin/env bash

# Author      : 章云
# Date        : 2019/9/1 13:33
# Description : 虚拟机一键配置管理

modifyStaticIP(){
    IFCONFIG_FILE="/etc/sysconfig/network-scripts/ifcfg-"`ifconfig|head -1|cut -d ':' -f1`
    IFCONFIG_GATEWAY=`${PROPERTIES_CONFIG_TOOLS} get ${LOCAL_CONFIG_VIRTUAL_FILE} "ifconfig.gateway"`
    IFCONFIG_DNS1=`${PROPERTIES_CONFIG_TOOLS} get ${LOCAL_CONFIG_VIRTUAL_FILE} "ifconfig.dns1"`
    IFCONFIG_DNS2=`${PROPERTIES_CONFIG_TOOLS} get ${LOCAL_CONFIG_VIRTUAL_FILE} "ifconfig.dns2"`
    ${PROPERTIES_CONFIG_TOOLS} put ${IFCONFIG_FILE} "BOOTPROTO" "static"
    # 静态IP不允许修改
#    ${PROPERTIES_CONFIG_TOOLS} put ${IFCONFIG_FILE} "IPADDR" $1
    ${PROPERTIES_CONFIG_TOOLS} put ${IFCONFIG_FILE} "NETMASK" "255.255.255.0"
    ${PROPERTIES_CONFIG_TOOLS} put ${IFCONFIG_FILE} "GATEWAY" ${IFCONFIG_GATEWAY}
    ${PROPERTIES_CONFIG_TOOLS} put ${IFCONFIG_FILE} "DNS1" ${IFCONFIG_DNS1}
    ${PROPERTIES_CONFIG_TOOLS} put ${IFCONFIG_FILE} "DNS2" ${IFCONFIG_DNS2}
    service network restart
}

modifyHostname(){
    if [[ $# -ne 1 ]]
    then
        echo "sh virtual_manager.sh modifyHostname <hostname>"
        exit 1
    fi
    # 固定文件，不需要放配置文件中配置
    NETWORK_FILE="/etc/sysconfig/network"
    ${PROPERTIES_CONFIG_TOOLS} put ${NETWORK_FILE} "NETWORKING" "yes"
    ${PROPERTIES_CONFIG_TOOLS} put ${NETWORK_FILE} "HOSTNAME" $1
    ${PROPERTIES_CONFIG_TOOLS} put ${NETWORK_FILE} "NETWORKING_IPV6" "no"
    ${PROPERTIES_CONFIG_TOOLS} put ${NETWORK_FILE} "PEERNTP" "no"
    hostname $1
}

closeFirewall(){
    systemctl stop firewalld.service
    systemctl disable firewalld.service
    setenforce 0
    SELINUX_FILE="/etc/selinux/config"
    ${PROPERTIES_CONFIG_TOOLS} put ${SELINUX_FILE} "SELINUX" "disabled"
}

secretKey(){
    echo "secretKey"
}

other(){
    # 设置时区
    echo ""
    echo "Step $step : 设置时区 Asia/Shanghai"
    echo ""
    step=${step}+1
    timedatectl set-timezone Asia/Shanghai
    # 或者 cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
}

COMMAND=$1
#参数位置左移1
shift

case ${COMMAND} in
    modifyStaticIP )
        modifyStaticIP $*
        ;;
    modifyHostname )
        modifyHostname $*
        ;;
    closeFirewall )
        closeFirewall $*
        ;;
    secretKey )
        secretKey $*
        ;;
    other )
        other $*
        ;;
    * )
        echo "Usage: "
        echo "sh virtual_manager.sh modifyStaticIP <ip>"
        echo "sh virtual_manager.sh modifyHostname <hostname>"
        echo "sh virtual_manager.sh closeFirewall"
        echo "sh virtual_manager.sh secretKey"
        echo "sh virtual_manager.sh other"
        exit 1
        ;;
esac