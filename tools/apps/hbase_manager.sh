#!/bin/sh
   
# Author : 章云
# Date   : 2019/8/21 15:50

Usage()
{
    echo "Usage: sh hbase_manager.sh install | uninstall"
    exit 1
}

HBASE_VERSION=`awk -F= '{if($1~/^version.hbase$/) print $2}' ${LOCAL_CONFIG_DEPLOY_FILE}`
HBASE_NAME="hbase"
HBASE_PACKAGE_NAME=${HBASE_NAME}-${HBASE_VERSION}
HBASE_INSTALL_FILE=${LOCAL_LIB_PATH}/${HBASE_NAME}/${HBASE_PACKAGE_NAME}-bin.tar.gz
# 已安装的程序目录
installed_file=${INSTALL_PATH}/${HBASE_PACKAGE_NAME}

install(){
    if [[ -e ${installed_file} ]]
    then
        rm -rf ${installed_file}
    fi
    tar -xvf ${HBASE_INSTALL_FILE} -C ${INSTALL_PATH} >>${LOCAL_LOGS_FILE} 2>&1
    # 修改环境变量
    HBASE_HOME=${installed_file}
    ${PROPERTIES_CONFIG_TOOLS} put ${ENVIRONMENT_VARIABLE_FILE} "HBASE_HOME" ${HBASE_HOME} 1
    # 增加PATH
    sed -i 's/^export PATH=/export PATH=${HBASE_HOME}\/bin:/g' ${ENVIRONMENT_VARIABLE_FILE}
    source ${ENVIRONMENT_VARIABLE_FILE}

    # 修改配置
    HADOOP_CONFIG_PATH=${HADOOP_HOME}/etc/hadoop
    hostname=`hostname`
    HDFS_REPLICATION=`awk -F= '{if($1~/^hdfs.replication$/) print $2}' ${LOCAL_CONFIG_DEPLOY_FILE}`
    # 目前只做单机版
    echo ${hostname} > $HADOOP_CONFIG_PATH/slaves
    ${XML_CONFIG_TOOLS} put ${HADOOP_CONFIG_PATH}/core-site.xml hadoop.tmp.dir "file:${HADOOP_HOME}/tmp"
    ${XML_CONFIG_TOOLS} put ${HADOOP_CONFIG_PATH}/core-site.xml fs.default.name "hdfs://${hostname}:8020"
    ${XML_CONFIG_TOOLS} put ${HADOOP_CONFIG_PATH}/hdfs-site.xml dfs.namenode.secondary.http-address ${hostname}:9001
    ${XML_CONFIG_TOOLS} put ${HADOOP_CONFIG_PATH}/hdfs-site.xml dfs.namenode.name.dir "file:${HADOOP_HOME}/dfs/name"
    ${XML_CONFIG_TOOLS} put ${HADOOP_CONFIG_PATH}/hdfs-site.xml dfs.namenode.data.dir "file:${HADOOP_HOME}/dfs/data"
    ${XML_CONFIG_TOOLS} put ${HADOOP_CONFIG_PATH}/hdfs-site.xml hdfs.replication ${HDFS_REPLICATION}
    ${XML_CONFIG_TOOLS} put ${HADOOP_CONFIG_PATH}/yarn-site.xml yarn.resourcemanager.address ${hostname}:8032
    ${XML_CONFIG_TOOLS} put ${HADOOP_CONFIG_PATH}/yarn-site.xml yarn.resourcemanager.scheduler.address ${hostname}:8030
    ${XML_CONFIG_TOOLS} put ${HADOOP_CONFIG_PATH}/yarn-site.xml yarn.resourcemanager.resource-tracker.address ${hostname}:8035
    ${XML_CONFIG_TOOLS} put ${HADOOP_CONFIG_PATH}/yarn-site.xml yarn.resourcemanager.admin.address ${hostname}:8033
    ${XML_CONFIG_TOOLS} put ${HADOOP_CONFIG_PATH}/yarn-site.xml yarn.resourcemanager.webapp.address ${hostname}:8088
    ${PROPERTIES_CONFIG_TOOLS} put ${HADOOP_CONFIG_PATH}/hadoop-env.sh "JAVA_HOME" ${JAVA_HOME} 1
    ${PROPERTIES_CONFIG_TOOLS} put ${HADOOP_CONFIG_PATH}/yarn-env.sh "JAVA_HOME" ${JAVA_HOME} 1

    # 初始化namenode
    ${HADOOP_HOME}/bin/hadoop namenode -format >>${LOCAL_LOGS_FILE} 2>&1
    # 设置开机自启动
    cp ${LOCAL_TOOLS_SERVICE_PATH}/hbase.sh /etc/init.d/hbase
    ${PROPERTIES_CONFIG_TOOLS} put /etc/init.d/hbase "ENVIRONMENT" ${ENVIRONMENT_VARIABLE_FILE}
	service hbase start
	chkconfig --add hbase
	chkconfig --level 345 hbase on

    [[ $? -ne 0 ]] && exit $?
    ${PROPERTIES_CONFIG_TOOLS} put ${LOCAL_VERSION_FILE} "version.hbase" ${HBASE_VERSION}
    echo ""
    echo "Install hbase successfully!!!"
    echo ""
    export HBASE_HOME
}

uninstall(){
    chkconfig --del hbase
    service hbase stop
    rm -rf /etc/init.d/hbase
    if [[ -e ${installed_file} ]]
    then
        rm -rf ${installed_file}
    fi
    # 删除环境变量
    HBASE_HOME=${installed_file}
    sed -i "/export HBASE_HOME=.*/d" ${ENVIRONMENT_VARIABLE_FILE}
    # 删除PATH
    sed -i 's/${HBASE_HOME}\/bin://g' ${ENVIRONMENT_VARIABLE_FILE}
    sed -i 's/$HBASE_HOME\/bin://g' ${ENVIRONMENT_VARIABLE_FILE}

    [[ $? -ne 0 ]] && exit $?
    echo ""
    echo "Uninstall hbase successfully!!!"
    echo ""
    if [[ -e "${LOCAL_VERSION_FILE}" ]]
    then
        sed -i "/.*hbase.*/d" ${LOCAL_VERSION_FILE}
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
