#!/bin/sh
   
# Author : 章云
# Date   : 2019/8/21 15:50

Usage()
{
    echo "Usage: sh kafka_manager.sh install | uninstall"
    exit 1
}

KAFKA_VERSION=`awk -F= '{if($1~/^version.kafka$/) print $2}' ${LOCAL_CONFIG_DEPLOY_FILE}`
KAFKA_NAME="kafka"
KAFKA_PACKAGE_NAME=${KAFKA_NAME}_${KAFKA_VERSION}
KAFKA_INSTALL_FILE=${LOCAL_LIB_PATH}/${KAFKA_NAME}/${KAFKA_PACKAGE_NAME}.tgz
# 已安装的程序目录
installed_file=${INSTALL_PATH}/${KAFKA_PACKAGE_NAME}

install(){
    if [[ -e ${installed_file} ]]
    then
        echo "kafka已安装"
        exit 1
    fi
    tar -xvf ${KAFKA_INSTALL_FILE} -C ${INSTALL_PATH} >> ${LOCAL_LOGS_FILE} 2>&1
    # 修改环境变量
    KAFKA_HOME=${installed_file}
    ${PROPERTIES_CONFIG_TOOLS} put ${ENVIRONMENT_VARIABLE_FILE} "KAFKA_HOME" ${KAFKA_HOME} 1
    # 增加PATH
    sed -i 's/^export PATH=/export PATH=${KAFKA_HOME}\/bin:/g' ${ENVIRONMENT_VARIABLE_FILE}
    source ${ENVIRONMENT_VARIABLE_FILE}

    KAFKA_CONFIG_PATH=${KAFKA_HOME}/config
    hostname=`hostname`
    # 目前只做单机版
    ${PROPERTIES_CONFIG_TOOLS} put ${KAFKA_CONFIG_PATH}/server.properties "broker.id" "0"
    ${PROPERTIES_CONFIG_TOOLS} put ${KAFKA_CONFIG_PATH}/server.properties "listeners" "PLAINTEXT://${hostname}:9092"
    ${PROPERTIES_CONFIG_TOOLS} put ${KAFKA_CONFIG_PATH}/server.properties "host.name" "${hostname}"
    ${PROPERTIES_CONFIG_TOOLS} put ${KAFKA_CONFIG_PATH}/server.properties "delete.topic.enable" "true"
    ${PROPERTIES_CONFIG_TOOLS} put ${KAFKA_CONFIG_PATH}/server.properties "log.dirs" "${KAFKA_HOME}/logs"
    ${PROPERTIES_CONFIG_TOOLS} put ${KAFKA_CONFIG_PATH}/server.properties "message.max.bytes" "5242880"
    ${PROPERTIES_CONFIG_TOOLS} put ${KAFKA_CONFIG_PATH}/server.properties "replica.fetch.max.bytes" "5242880"
    ${PROPERTIES_CONFIG_TOOLS} put ${KAFKA_CONFIG_PATH}/server.properties "default.replication.factor" "1"
    ${PROPERTIES_CONFIG_TOOLS} put ${KAFKA_CONFIG_PATH}/server.properties "zookeeper.connect" "${hostname}:2181"

    chmod 777 ${KAFKA_HOME}/bin/*.sh
    # 设置开机自启动
    cp ${LOCAL_TOOLS_SERVICE_PATH}/kafka.sh /etc/init.d/kafka
    ${PROPERTIES_CONFIG_TOOLS} put /etc/init.d/kafka "ENVIRONMENT" ${ENVIRONMENT_VARIABLE_FILE}
	service kafka start
	chkconfig --add kafka
	chkconfig --level 345 kafka on

    [[ $? -ne 0 ]] && exit $?
    ${PROPERTIES_CONFIG_TOOLS} put ${LOCAL_VERSION_FILE} "version.kafka" ${KAFKA_VERSION}
    echo ""
    echo "Install kafka successfully!!!"
    echo ""
    export KAFKA_HOME
}

uninstall(){
    chkconfig --del kafka
    service kafka stop
    rm -rf /etc/init.d/kafka
    if [[ -e ${installed_file} ]]
    then
        rm -rf ${installed_file}
    fi
    # 删除环境变量
    KAFKA_HOME=${installed_file}
    sed -i "/export KAFKA_HOME=.*/d" ${ENVIRONMENT_VARIABLE_FILE}
    # 删除PATH
    sed -i 's/${KAFKA_HOME}\/bin://g' ${ENVIRONMENT_VARIABLE_FILE}
    sed -i 's/$KAFKA_HOME\/bin://g' ${ENVIRONMENT_VARIABLE_FILE}

    [[ $? -ne 0 ]] && exit $?
    echo ""
    echo "Uninstall kafka successfully!!!"
    echo ""
    if [[ -e "${LOCAL_VERSION_FILE}" ]]
    then
        sed -i "/.*kafka.*/d" ${LOCAL_VERSION_FILE}
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
