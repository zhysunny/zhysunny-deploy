#!/bin/sh
   
# Author : 章云
# Date   : 2019/8/22 10:41

Usage()
{
    echo "Usage: sh hive_manager.sh install | uninstall"
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
HIVE_VERSION=`awk -F= '{if($1~/^version.hive$/) print $2}' ${LOCAL_CONFIG_DEPLOY_FILE}`
HIVE_NAME="hive"
HIVE_PACKAGE_NAME=${HIVE_NAME}-${HIVE_VERSION}
HIVE_INSTALL_FILE=${LOCAL_LIB_PATH}/${HIVE_NAME}/${HIVE_PACKAGE_NAME}.tar.gz
# 已安装的程序目录
installed_file=${INSTALL_PATH}/${HIVE_PACKAGE_NAME}

install(){
    source ${ENVIRONMENT_VARIABLE_FILE}
    if [[ -z "${HADOOP_HOME}" ]]
    then
        echo "HADOOP_HOME is empty，can not install hive"
        exit 1
    fi
    if [[ -e ${installed_file} ]]
    then
        rm -rf ${installed_file}
    fi
    tar -xvf ${HIVE_INSTALL_FILE} -C ${INSTALL_PATH} >>${LOCAL_LOGS_FILE} 2>&1
    # 修改配置
    HIVE_HOME=${installed_file}
    HIVE_CONFIG_PATH=${HIVE_HOME}/conf
    cp ${HIVE_CONFIG_PATH}/hive-default.xml.template ${HIVE_CONFIG_PATH}/hive-default.xml
    cp ${HIVE_CONFIG_PATH}/hive-default.xml.template ${HIVE_CONFIG_PATH}/hive-site.xml
    rm -rf ${HADOOP_HOME}/share/hadoop/yarn/lib/jline*.jar
    cp ${HIVE_HOME}/lib/jline*.jar ${HADOOP_HOME}/share/hadoop/yarn/lib
    # 修改xml配置
    HIVE_HOME=`echo ${HIVE_HOME} | sed 's#\/#\\\/#g'`
    hostname=`hostname`
    HIVE_TEMP_PATH="${HIVE_HOME}\/tmp"
    ${MODIFY_CONFIG_XML_VALUE_TOOL} ${HIVE_CONFIG_PATH}/hive-site.xml hive.exec.scratchdir "${HIVE_TEMP_PATH}\/hive"
    ${MODIFY_CONFIG_XML_VALUE_TOOL} ${HIVE_CONFIG_PATH}/hive-site.xml hive.hbase.snapshot.restoredir ${HIVE_TEMP_PATH}
    ${MODIFY_CONFIG_XML_VALUE_TOOL} ${HIVE_CONFIG_PATH}/hive-site.xml hive.exec.local.scratchdir ${HIVE_TEMP_PATH}
    ${MODIFY_CONFIG_XML_VALUE_TOOL} ${HIVE_CONFIG_PATH}/hive-site.xml hive.downloaded.resources.dir "${HIVE_TEMP_PATH}\/\${hive.session.id}_resources"
    ${MODIFY_CONFIG_XML_VALUE_TOOL} ${HIVE_CONFIG_PATH}/hive-site.xml hive.querylog.location ${HIVE_TEMP_PATH}
    ${MODIFY_CONFIG_XML_VALUE_TOOL} ${HIVE_CONFIG_PATH}/hive-site.xml hive.server2.logging.operation.log.location "${HIVE_TEMP_PATH}\/operation_logs"
    ${MODIFY_CONFIG_XML_VALUE_TOOL} ${HIVE_CONFIG_PATH}/hive-site.xml javax.jdo.option.ConnectionDriverName com.mysql.jdbc.Driver
    ${MODIFY_CONFIG_XML_VALUE_TOOL} ${HIVE_CONFIG_PATH}/hive-site.xml javax.jdo.option.ConnectionURL "jdbc:mysql:\/\/${hostname}:3306\/hive?createDatabaseIfNotExist=true"
    ${MODIFY_CONFIG_XML_VALUE_TOOL} ${HIVE_CONFIG_PATH}/hive-site.xml javax.jdo.option.ConnectionUserName root
    ${MODIFY_CONFIG_XML_VALUE_TOOL} ${HIVE_CONFIG_PATH}/hive-site.xml javax.jdo.option.ConnectionPassword ${MYSQL_ROOT_PASSWORD}
    ${MODIFY_CONFIG_XML_VALUE_TOOL} ${HIVE_CONFIG_PATH}/hive-site.xml hive.cli.print.header true
    ${MODIFY_CONFIG_XML_VALUE_TOOL} ${HIVE_CONFIG_PATH}/hive-site.xml hive.enforce.bucketing true
    HIVE_HOME=`echo ${HIVE_HOME} | sed 's#\\\/#\/#g'`
    # 创建数据库，并设置编码
    ${MYSQL_HOME}/bin/mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "create database hive DEFAULT CHARSET latin1;" >>${LOCAL_LOGS_FILE} 2>&1
    # 修改环境变量
    result=(`cat ${ENVIRONMENT_VARIABLE_FILE} | grep "export HIVE_HOME="`)
    if [[ ${#result[*]} -eq 0 ]]
    then
        # 没有HIVE_HOME增加
        echo "export HIVE_HOME=$HIVE_HOME" >> ${ENVIRONMENT_VARIABLE_FILE}
    else
        HIVE_HOME=`echo ${HIVE_HOME} | sed 's#\/#\\\/#g'`
        sed -i "s/^export HIVE_HOME=.*/export HIVE_HOME=$HIVE_HOME/g" ${ENVIRONMENT_VARIABLE_FILE}
        HIVE_HOME=`echo ${HIVE_HOME} | sed 's#\\\/#\/#g'`
    fi
    # 增加PATH
    sed -i 's/^export PATH=/export PATH=${HIVE_HOME}\/bin:/g' ${ENVIRONMENT_VARIABLE_FILE}
    source ${ENVIRONMENT_VARIABLE_FILE}
    [[ $? -ne 0 ]] && exit $?
    echo ""
    echo "Install hive successfully!!!"
    echo ""
    # 测试hive，在mysql中初始化hive元数据表
    echo "测试hive,展示数据库列表"
    ${HIVE_HOME}/bin/hive -S -e "show databases;"
    echo "# hive版本" >> ${LOCAL_VERSION_FILE}
    echo "version.hive=${HIVE_VERSION}" >> ${LOCAL_VERSION_FILE}
    export HIVE_HOME
}

uninstall(){
    # 清楚mysql数据库
    ${MYSQL_HOME}/bin/mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "drop database hive;" >>${LOCAL_LOGS_FILE} 2>&1
    if [[ -e ${installed_file} ]]
    then
        rm -rf ${installed_file}
    fi
    # 删除环境变量
    HIVE_HOME=${installed_file}
    sed -i "/export HIVE_HOME=.*/d" ${ENVIRONMENT_VARIABLE_FILE}
    # 删除PATH
    sed -i 's/${HIVE_HOME}\/bin://g' ${ENVIRONMENT_VARIABLE_FILE}
    sed -i 's/$HIVE_HOME\/bin://g' ${ENVIRONMENT_VARIABLE_FILE}

    [[ $? -ne 0 ]] && exit $?
    echo ""
    echo "Uninstall hive successfully!!!"
    echo ""
    if [[ -e "${LOCAL_VERSION_FILE}" ]]
    then
        sed -i "/.*hive.*/d" ${LOCAL_VERSION_FILE}
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
