#!/bin/sh
   
# Author : 章云
# Date   : 2019/8/21 15:50

Usage()
{
    echo "Usage: sh zookeeper_manager.sh install | uninstall"
    exit 1
}

ZOOKEEPER_VERSION=`awk -F= '{if($1~/^version.zookeeper$/) print $2}' ${LOCAL_CONFIG_DEPLOY_FILE}`
ZOOKEEPER_NAME="zookeeper"
ZOOKEEPER_PACKAGE_NAME=${ZOOKEEPER_NAME}-${ZOOKEEPER_VERSION}
ZOOKEEPER_INSTALL_FILE=${LOCAL_LIB_PATH}/${ZOOKEEPER_NAME}/${ZOOKEEPER_PACKAGE_NAME}.tar.gz
# 已安装的程序目录
installed_file=${INSTALL_PATH}/${ZOOKEEPER_PACKAGE_NAME}
echo ${INSTALL_APPS[*]}
install(){
    if [[ -e ${installed_file} ]]
    then
        echo "zookeeper已安装"
        exit 1
    fi
    tar -xvf ${ZOOKEEPER_INSTALL_FILE} -C ${INSTALL_PATH} >> ${LOCAL_LOGS_FILE} 2>&1
    # 修改配置
    mkdir -p ${installed_file}/data
    echo "1" > ${installed_file}/data/myid
    cp ${installed_file}/conf/zoo_sample.cfg ${installed_file}/conf/zoo.cfg
    ${PROPERTIES_CONFIG_TOOLS} put ${installed_file}/conf/zoo.cfg "dataDir" ${installed_file}/data
    echo 'server.1='`hostname`':2888:3888' >> ${installed_file}/conf/zoo.cfg
    # 修改环境变量
    ZOOKEEPER_HOME=${installed_file}
    ${PROPERTIES_CONFIG_TOOLS} put ${ENVIRONMENT_VARIABLE_FILE} "ZOOKEEPER_HOME" ${ZOOKEEPER_HOME} 1
    # 增加PATH
    sed -i 's/^export PATH=/export PATH=${ZOOKEEPER_HOME}\/bin:/g' ${ENVIRONMENT_VARIABLE_FILE}
    source ${ENVIRONMENT_VARIABLE_FILE}
    # 设置开机自启动
    cp ${LOCAL_TOOLS_SERVICE_PATH}/zookeeper.sh /etc/init.d/zookeeper
    ${PROPERTIES_CONFIG_TOOLS} put /etc/init.d/zookeeper "ENVIRONMENT" ${ENVIRONMENT_VARIABLE_FILE}
	service zookeeper start
	chkconfig --add zookeeper
	chkconfig --level 345 zookeeper on

    [[ $? -ne 0 ]] && exit $?
    ${PROPERTIES_CONFIG_TOOLS} put ${LOCAL_VERSION_FILE} "version.zookeeper" ${ZOOKEEPER_VERSION}
    echo ""
    echo "Install zookeeper successfully!!!"
    echo ""
    export ZOOKEEPER_HOME
}

uninstall(){
    chkconfig --del zookeeper
    service zookeeper stop
    rm -rf /etc/init.d/zookeeper
    if [[ -e ${installed_file} ]]
    then
        rm -rf ${installed_file}
    fi
    # 删除环境变量
    ZOOKEEPER_HOME=${installed_file}
    sed -i "/export ZOOKEEPER_HOME=.*/d" ${ENVIRONMENT_VARIABLE_FILE}
    # 删除PATH
    sed -i 's/${ZOOKEEPER_HOME}\/bin://g' ${ENVIRONMENT_VARIABLE_FILE}
    sed -i 's/$ZOOKEEPER_HOME\/bin://g' ${ENVIRONMENT_VARIABLE_FILE}

    [[ $? -ne 0 ]] && exit $?
    echo ""
    echo "Uninstall zookeeper successfully!!!"
    echo ""
    if [[ -e "${LOCAL_VERSION_FILE}" ]]
    then
        sed -i "/.*zookeeper.*/d" ${LOCAL_VERSION_FILE}
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
