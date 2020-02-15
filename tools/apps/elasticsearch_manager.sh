#!/bin/sh
   
# Author : 章云
# Date   : 2019/8/21 15:50

Usage()
{
    echo "Usage: sh elasticsearch_manager.sh install | uninstall"
    exit 1
}

ES_VERSION=`awk -F= '{if($1~/^version.elasticsearch$/) print $2}' ${LOCAL_CONFIG_DEPLOY_FILE}`
ES_NAME="elasticsearch"
ES_PACKAGE_NAME=${ES_NAME}-${ES_VERSION}
ES_INSTALL_FILE=${LOCAL_LIB_PATH}/${ES_NAME}/${ES_PACKAGE_NAME}.tar.gz
# 已安装的程序目录
installed_file=${INSTALL_PATH}/${ES_PACKAGE_NAME}
# node
NODE_PACKAGE_NAME=node-v10.16.0
NODE_INSTALL_FILE=${LOCAL_LIB_PATH}/${ES_NAME}/${NODE_PACKAGE_NAME}.tar.gz
node_installed_file=${INSTALL_PATH}/${NODE_PACKAGE_NAME}
# head
HEAD_PACKAGE_NAME=elasticsearch-head
HEAD_INSTALL_FILE=${LOCAL_LIB_PATH}/${ES_NAME}/${HEAD_PACKAGE_NAME}.tar.gz
head_installed_file=${INSTALL_PATH}/${HEAD_PACKAGE_NAME}

install(){
    if [[ -e ${installed_file} ]]
    then
        echo "elasticsearch已安装"
        exit 1
    fi
    if [[ ! -e ${node_installed_file} ]]
    then
        tar -xvf ${NODE_INSTALL_FILE} -C ${INSTALL_PATH} >> ${LOCAL_LOGS_FILE} 2>&1
    fi
    if [[ ! -e ${head_installed_file} ]]
    then
        tar -xvf ${HEAD_INSTALL_FILE} -C ${INSTALL_PATH} >> ${LOCAL_LOGS_FILE} 2>&1
    fi
    tar -xvf ${ES_INSTALL_FILE} -C ${INSTALL_PATH} >> ${LOCAL_LOGS_FILE} 2>&1
    # elasticsearch用户是否存在
	if [[ -z "`cat /etc/shadow|grep elasticsearch`" ]]
	then
		useradd elasticsearch
        echo "elasticsearch" | passwd --stdin elasticsearch
	fi
	chown -R elasticsearch ${installed_file}
    # 修改环境变量
    ES_HOME=${installed_file}
    NODE_HOME=${node_installed_file}
    HEAD_HOME=${head_installed_file}
    ${PROPERTIES_CONFIG_TOOLS} put ${ENVIRONMENT_VARIABLE_FILE} "ES_HOME" ${ES_HOME} 1
    ${PROPERTIES_CONFIG_TOOLS} put ${ENVIRONMENT_VARIABLE_FILE} "NODE_HOME" ${NODE_HOME} 1
    ${PROPERTIES_CONFIG_TOOLS} put ${ENVIRONMENT_VARIABLE_FILE} "HEAD_HOME" ${HEAD_HOME} 1
    # 增加PATH
    sed -i 's/^export PATH=/export PATH=${ES_HOME}\/bin:/g' ${ENVIRONMENT_VARIABLE_FILE}
    sed -i 's/^export PATH=/export PATH=${NODE_HOME}\/bin:/g' ${ENVIRONMENT_VARIABLE_FILE}
    source ${ENVIRONMENT_VARIABLE_FILE}

    ES_CONFIG_PATH=${ES_HOME}/config
    hostname=`hostname`
    # 目前只做单机版
    ${PROPERTIES_CONFIG_TOOLS} put ${ES_CONFIG_PATH}/elasticsearch.yml "cluster.name" "${hostname}-elasticsearch-es" 3
    ${PROPERTIES_CONFIG_TOOLS} put ${ES_CONFIG_PATH}/elasticsearch.yml "path.data" "${ES_HOME}/data" 3
    ${PROPERTIES_CONFIG_TOOLS} put ${ES_CONFIG_PATH}/elasticsearch.yml "path.logs" "${ES_HOME}/logs" 3
    ${PROPERTIES_CONFIG_TOOLS} put ${ES_CONFIG_PATH}/elasticsearch.yml "network.host" "${hostname}" 3
    ${PROPERTIES_CONFIG_TOOLS} put ${ES_CONFIG_PATH}/elasticsearch.yml "http.cors.enabled" "true" 3
    ${PROPERTIES_CONFIG_TOOLS} put ${ES_CONFIG_PATH}/elasticsearch.yml "http.cors.allow-origin" "\"*\"" 3
    ${PROPERTIES_CONFIG_TOOLS} put ${ES_CONFIG_PATH}/elasticsearch.yml "node.master" "true" 3
    ${PROPERTIES_CONFIG_TOOLS} put ${ES_CONFIG_PATH}/elasticsearch.yml "node.data" "true" 3
    # linux默认es操作文件句柄数太小
    if [[ -z `cat /etc/security/limits.conf | grep "elasticsearch hard nofile 65536"` ]]
    then
        echo "elasticsearch hard nofile 65536" >> /etc/security/limits.conf
    fi
    if [[ -z `cat /etc/security/limits.conf | grep "elasticsearch soft nofile 65536"` ]]
    then
        echo "elasticsearch soft nofile 65536" >> /etc/security/limits.conf
    fi
    sysctl -w vm.max_map_count=655360

    chmod 777 ${ES_HOME}/bin/*.sh
    # 设置开机自启动
    cp ${LOCAL_TOOLS_SERVICE_PATH}/elasticsearch.sh /etc/init.d/elasticsearch
    ${PROPERTIES_CONFIG_TOOLS} put /etc/init.d/elasticsearch "ENVIRONMENT" ${ENVIRONMENT_VARIABLE_FILE}
	service elasticsearch start
	chkconfig --add elasticsearch
	chkconfig --level 345 elasticsearch on

    [[ $? -ne 0 ]] && exit $?
    ${PROPERTIES_CONFIG_TOOLS} put ${LOCAL_VERSION_FILE} "version.elasticsearch" ${ES_VERSION}
    echo ""
    echo "Install elasticsearch successfully!!!"
    echo ""
    export ES_HOME
}

uninstall(){
    chkconfig --del elasticsearch
    service elasticsearch stop
    rm -rf /etc/init.d/elasticsearch
    if [[ -e ${installed_file} ]]
    then
        rm -rf ${installed_file}
        rm -rf ${node_installed_file}
        rm -rf ${head_installed_file}
    fi
    # mysql用户是否存在
	if [[ -n "`cat /etc/shadow|grep elasticsearch`" ]]
	then
		userdel elasticsearch
		rm -rf /home/elasticsearch
	fi
    # 删除环境变量
    ES_HOME=${installed_file}
    NODE_HOME=${node_installed_file}
    HEAD_HOME=${head_installed_file}
    sed -i "/export ES_HOME=.*/d" ${ENVIRONMENT_VARIABLE_FILE}
    sed -i "/export NODE_HOME=.*/d" ${ENVIRONMENT_VARIABLE_FILE}
    sed -i "/export HEAD_HOME=.*/d" ${ENVIRONMENT_VARIABLE_FILE}
    # 删除PATH
    sed -i 's/${ES_HOME}\/bin://g' ${ENVIRONMENT_VARIABLE_FILE}
    sed -i 's/$ES_HOME\/bin://g' ${ENVIRONMENT_VARIABLE_FILE}
    sed -i 's/${NODE_HOME}\/bin://g' ${ENVIRONMENT_VARIABLE_FILE}
    sed -i 's/$NODE_HOME\/bin://g' ${ENVIRONMENT_VARIABLE_FILE}

    [[ $? -ne 0 ]] && exit $?
    echo ""
    echo "Uninstall elasticsearch successfully!!!"
    echo ""
    if [[ -e "${LOCAL_VERSION_FILE}" ]]
    then
        sed -i "/.*elasticsearch.*/d" ${LOCAL_VERSION_FILE}
    fi
}

COMMAND=$1

#参数位置左移1
shift

case ${COMMAND} in
    install )
        install $*
        ;;
    uninstall )
		uninstall $*
		;;
    * )
		Usage
        exit 1
        ;;
esac
