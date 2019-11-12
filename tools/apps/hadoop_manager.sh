#!/bin/sh
   
# Author : 章云
# Date   : 2019/8/21 15:50

Usage()
{
    echo "Usage: sh hadoop_manager.sh install | uninstall"
    exit 1
}

HADOOP_VERSION=`awk -F= '{if($1~/^version.hadoop$/) print $2}' ${LOCAL_CONFIG_DEPLOY_FILE}`
HADOOP_NAME="hadoop"
HADOOP_PACKAGE_NAME=${HADOOP_NAME}-${HADOOP_VERSION}
HADOOP_INSTALL_FILE=${LOCAL_LIB_PATH}/${HADOOP_NAME}/${HADOOP_PACKAGE_NAME}.tar.gz
# 已安装的程序目录
installed_file=${INSTALL_PATH}/${HADOOP_PACKAGE_NAME}

install(){
    if [[ -e ${installed_file} ]]
    then
        echo "hadoop已安装"
        exit 1
    fi
    tar -xvf ${HADOOP_INSTALL_FILE} -C ${INSTALL_PATH} >> ${LOCAL_LOGS_FILE} 2>&1
    # 修改环境变量
    HADOOP_HOME=${installed_file}
    ${PROPERTIES_CONFIG_TOOLS} put ${ENVIRONMENT_VARIABLE_FILE} "HADOOP_HOME" ${HADOOP_HOME} 1
    # 增加PATH
    sed -i 's/^export PATH=/export PATH=${HADOOP_HOME}\/bin:/g' ${ENVIRONMENT_VARIABLE_FILE}
    source ${ENVIRONMENT_VARIABLE_FILE}

    # 修改配置,hadoop2.x
    HADOOP_CONFIG_PATH=${HADOOP_HOME}/etc/hadoop
    hostname=`hostname`
    HDFS_REPLICATION=`awk -F= '{if($1~/^hdfs.replication$/) print $2}' ${LOCAL_CONFIG_DEPLOY_FILE}`
    # 目前只做单机版
    echo ${hostname} > $HADOOP_CONFIG_PATH/slaves
    ${XML_CONFIG_TOOLS} put ${HADOOP_CONFIG_PATH}/core-site.xml "hadoop.tmp.dir" "file://${HADOOP_HOME}/tmp"
    ${XML_CONFIG_TOOLS} put ${HADOOP_CONFIG_PATH}/core-site.xml "fs.default.name" "hdfs://${hostname}:8020"

    cp ${HADOOP_CONFIG_PATH}/mapred-site.xml.template ${HADOOP_CONFIG_PATH}/mapred-site.xml
    ${XML_CONFIG_TOOLS} put ${HADOOP_CONFIG_PATH}/mapred-site.xml "mapreduce.framework.name" "yarn"

    ${XML_CONFIG_TOOLS} put ${HADOOP_CONFIG_PATH}/hdfs-site.xml "dfs.namenode.secondary.http-address" "${hostname}:9001"
    ${XML_CONFIG_TOOLS} put ${HADOOP_CONFIG_PATH}/hdfs-site.xml "dfs.namenode.name.dir" "file://${HADOOP_HOME}/dfs/name"
    ${XML_CONFIG_TOOLS} put ${HADOOP_CONFIG_PATH}/hdfs-site.xml "dfs.namenode.data.dir" "file://${HADOOP_HOME}/dfs/data"
    ${XML_CONFIG_TOOLS} put ${HADOOP_CONFIG_PATH}/hdfs-site.xml "hdfs.replication" "${HDFS_REPLICATION}"

    ${XML_CONFIG_TOOLS} put ${HADOOP_CONFIG_PATH}/yarn-site.xml "yarn.nodemanager.aux-services" "mapreduce_shuffle"
    ${XML_CONFIG_TOOLS} put ${HADOOP_CONFIG_PATH}/yarn-site.xml "yarn.nodemanager.aux-services.mapreduce.shuffle.class" "org.apache.hadoop.mapred.ShuffleHandler"
    ${XML_CONFIG_TOOLS} put ${HADOOP_CONFIG_PATH}/yarn-site.xml "yarn.resourcemanager.address" "${hostname}:8032"
    ${XML_CONFIG_TOOLS} put ${HADOOP_CONFIG_PATH}/yarn-site.xml "yarn.resourcemanager.scheduler.address" "${hostname}:8030"
    ${XML_CONFIG_TOOLS} put ${HADOOP_CONFIG_PATH}/yarn-site.xml "yarn.resourcemanager.resource-tracker.address" "${hostname}:8035"
    ${XML_CONFIG_TOOLS} put ${HADOOP_CONFIG_PATH}/yarn-site.xml "yarn.resourcemanager.admin.address" "${hostname}:8033"
    ${XML_CONFIG_TOOLS} put ${HADOOP_CONFIG_PATH}/yarn-site.xml "yarn.resourcemanager.webapp.address" "${hostname}:8088"
    ${PROPERTIES_CONFIG_TOOLS} put ${HADOOP_CONFIG_PATH}/hadoop-env.sh "JAVA_HOME" ${JAVA_HOME} 1
    ${PROPERTIES_CONFIG_TOOLS} put ${HADOOP_CONFIG_PATH}/yarn-env.sh "JAVA_HOME" ${JAVA_HOME} 1

    # 初始化namenode
    ${HADOOP_HOME}/bin/hadoop namenode -format >>${LOCAL_LOGS_FILE} 2>&1
    # 设置开机自启动
    cp ${LOCAL_TOOLS_SERVICE_PATH}/hadoop.sh /etc/init.d/hadoop
    ${PROPERTIES_CONFIG_TOOLS} put /etc/init.d/hadoop "ENVIRONMENT" ${ENVIRONMENT_VARIABLE_FILE}
	service hadoop start
	chkconfig --add hadoop
	chkconfig --level 345 hadoop on

    [[ $? -ne 0 ]] && exit $?
    ${PROPERTIES_CONFIG_TOOLS} put ${LOCAL_VERSION_FILE} "version.hadoop" ${HADOOP_VERSION}
    echo ""
    echo "Install hadoop successfully!!!"
    echo ""
    export HADOOP_HOME
}

uninstall(){
    chkconfig --del hadoop
    service hadoop stop
    rm -rf /etc/init.d/hadoop
    if [[ -e ${installed_file} ]]
    then
        rm -rf ${installed_file}
    fi
    # 删除环境变量
    HADOOP_HOME=${installed_file}
    sed -i "/export HADOOP_HOME=.*/d" ${ENVIRONMENT_VARIABLE_FILE}
    # 删除PATH
    sed -i 's/${HADOOP_HOME}\/bin://g' ${ENVIRONMENT_VARIABLE_FILE}
    sed -i 's/$HADOOP_HOME\/bin://g' ${ENVIRONMENT_VARIABLE_FILE}

    [[ $? -ne 0 ]] && exit $?
    echo ""
    echo "Uninstall hadoop successfully!!!"
    echo ""
    if [[ -e "${LOCAL_VERSION_FILE}" ]]
    then
        sed -i "/.*hadoop.*/d" ${LOCAL_VERSION_FILE}
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
