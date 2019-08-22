#!/bin/sh
   
# Author : 章云
# Date   : 2019/8/21 15:50

Usage()
{
    echo "Usage: sh hadoop_manager.sh install | uninstall"
    exit 1
}

# parameter is necessary
if [[ "$1" = "" ]]
then
    Usage
fi

# 当前文件所在目录，这里是相对路径
LOCAL_PATH=`dirname $0`
# 当前文件所在目录转为绝对路径
LOCAL_PATH=`cd ${LOCAL_PATH};pwd`
HADOOP_VERSION=`awk -F= '{if($1~/^version.hadoop$/) print $2}' ${LOCAL_CONFIG_DEPLOY_FILE}`
HADOOP_NAME="hadoop"
HADOOP_PACKAGE_NAME=${HADOOP_NAME}-${HADOOP_VERSION}
HADOOP_INSTALL_FILE=${LOCAL_LIB_PATH}/${HADOOP_NAME}/${HADOOP_PACKAGE_NAME}.tar.gz
# 已安装的程序目录
installed_file=${INSTALL_PATH}/${HADOOP_PACKAGE_NAME}

install(){
    if [[ -e ${installed_file} ]]
    then
        rm -rf ${installed_file}
    fi
    tar -xvf ${HADOOP_INSTALL_FILE} -C ${INSTALL_PATH} >>${LOCAL_LOGS_FILE} 2>&1
    # 修改环境变量
    HADOOP_HOME=${installed_file}
    result=(`cat ${ENVIRONMENT_VARIABLE_FILE} | grep "export HADOOP_HOME="`)
    if [[ ${#result[*]} -eq 0 ]]
    then
        # 没有HADOOP_HOME增加
        echo "export HADOOP_HOME=$HADOOP_HOME" >> ${ENVIRONMENT_VARIABLE_FILE}
    else
        HADOOP_HOME=`echo ${HADOOP_HOME} | sed 's#\/#\\\/#g'`
        sed -i "s/^export HADOOP_HOME=.*/export HADOOP_HOME=$HADOOP_HOME/g" ${ENVIRONMENT_VARIABLE_FILE}
        HADOOP_HOME=`echo ${HADOOP_HOME} | sed 's#\\\/#\/#g'`
    fi
    # 增加PATH
    sed -i 's/^export PATH=/export PATH=${HADOOP_HOME}\/bin:/g' ${ENVIRONMENT_VARIABLE_FILE}
    source ${ENVIRONMENT_VARIABLE_FILE}

    # 修改配置
    HADOOP_CONFIG_PATH=${HADOOP_HOME}/etc/hadoop
    hostname=`hostname`
    HDFS_REPLICATION=`awk -F= '{if($1~/^hdfs.replication$/) print $2}' ${LOCAL_CONFIG_DEPLOY_FILE}`
    # 目前只做单机版
    echo ${hostname} > $HADOOP_CONFIG_PATH/slaves
    HADOOP_HOME=`echo ${HADOOP_HOME} | sed 's#\/#\\\/#g'`
    ${MODIFY_CONFIG_XML_VALUE_TOOL} ${HADOOP_CONFIG_PATH}/core-site.xml hadoop.tmp.dir "file:${HADOOP_HOME}\/tmp"
    ${MODIFY_CONFIG_XML_VALUE_TOOL} ${HADOOP_CONFIG_PATH}/core-site.xml fs.default.name "hdfs:\/\/${hostname}:8020"
    ${MODIFY_CONFIG_XML_VALUE_TOOL} ${HADOOP_CONFIG_PATH}/hdfs-site.xml dfs.namenode.secondary.http-address ${hostname}:9001
    ${MODIFY_CONFIG_XML_VALUE_TOOL} ${HADOOP_CONFIG_PATH}/hdfs-site.xml dfs.namenode.name.dir "file:${HADOOP_HOME}\/dfs\/name"
    ${MODIFY_CONFIG_XML_VALUE_TOOL} ${HADOOP_CONFIG_PATH}/hdfs-site.xml dfs.namenode.data.dir "file:${HADOOP_HOME}\/dfs\/data"
    ${MODIFY_CONFIG_XML_VALUE_TOOL} ${HADOOP_CONFIG_PATH}/hdfs-site.xml hdfs.replication ${HDFS_REPLICATION}
    ${MODIFY_CONFIG_XML_VALUE_TOOL} ${HADOOP_CONFIG_PATH}/yarn-site.xml yarn.resourcemanager.address ${hostname}:8032
    ${MODIFY_CONFIG_XML_VALUE_TOOL} ${HADOOP_CONFIG_PATH}/yarn-site.xml yarn.resourcemanager.scheduler.address ${hostname}:8030
    ${MODIFY_CONFIG_XML_VALUE_TOOL} ${HADOOP_CONFIG_PATH}/yarn-site.xml yarn.resourcemanager.resource-tracker.address ${hostname}:8035
    ${MODIFY_CONFIG_XML_VALUE_TOOL} ${HADOOP_CONFIG_PATH}/yarn-site.xml yarn.resourcemanager.admin.address ${hostname}:8033
    ${MODIFY_CONFIG_XML_VALUE_TOOL} ${HADOOP_CONFIG_PATH}/yarn-site.xml yarn.resourcemanager.webapp.address ${hostname}:8088
    HADOOP_HOME=`echo ${HADOOP_HOME} | sed 's#\\\/#\/#g'`
    JAVA_HOME=`echo ${JAVA_HOME} | sed 's#\/#\\\/#g'`
    sed -i "s/^.*export JAVA_HOME=.*/export JAVA_HOME=$JAVA_HOME/g" ${HADOOP_CONFIG_PATH}/hadoop-env.sh
    sed -i "s/^.*export JAVA_HOME=.*/export JAVA_HOME=$JAVA_HOME/g" ${HADOOP_CONFIG_PATH}/yarn-env.sh

    # 初始化namenode
    ${HADOOP_HOME}/bin/hadoop namenode -format >>${LOCAL_LOGS_FILE} 2>&1
    ${HADOOP_HOME}/sbin/start-all.sh

    [[ $? -ne 0 ]] && exit $?
    echo ""
    echo "Install hadoop successfully!!!"
    echo ""
    echo "# hadoop版本" >> ${LOCAL_VERSION_FILE}
    echo "version.hadoop=${HADOOP_VERSION}" >> ${LOCAL_VERSION_FILE}
    export HADOOP_HOME
}

uninstall(){
    ${HADOOP_HOME}/sbin/stop-all.sh
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
