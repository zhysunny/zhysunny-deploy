#!/bin/sh
   
# Author : 章云
# Date   : 2019/8/22 10:41

Usage()
{
    echo "Usage: sh hive_manager.sh install | uninstall"
    exit 1
}

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
    if [[ -z "${MYSQL_HOME}" ]]
    then
        echo "MYSQL_HOME is empty，can not install hive"
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
    hostname=`hostname`
    HIVE_TEMP_PATH="${HIVE_HOME}/tmp"
    ${XML_CONFIG_TOOLS} put ${HIVE_CONFIG_PATH}/hive-site.xml hive.exec.scratchdir "${HIVE_TEMP_PATH}/hive"
    ${XML_CONFIG_TOOLS} put ${HIVE_CONFIG_PATH}/hive-site.xml hive.hbase.snapshot.restoredir ${HIVE_TEMP_PATH}
    ${XML_CONFIG_TOOLS} put ${HIVE_CONFIG_PATH}/hive-site.xml hive.exec.local.scratchdir ${HIVE_TEMP_PATH}
    ${XML_CONFIG_TOOLS} put ${HIVE_CONFIG_PATH}/hive-site.xml hive.downloaded.resources.dir "${HIVE_TEMP_PATH}/\${hive.session.id}_resources"
    ${XML_CONFIG_TOOLS} put ${HIVE_CONFIG_PATH}/hive-site.xml hive.querylog.location ${HIVE_TEMP_PATH}
    ${XML_CONFIG_TOOLS} put ${HIVE_CONFIG_PATH}/hive-site.xml hive.server2.logging.operation.log.location "${HIVE_TEMP_PATH}/operation_logs"
    ${XML_CONFIG_TOOLS} put ${HIVE_CONFIG_PATH}/hive-site.xml javax.jdo.option.ConnectionDriverName com.mysql.jdbc.Driver
    ${XML_CONFIG_TOOLS} put ${HIVE_CONFIG_PATH}/hive-site.xml javax.jdo.option.ConnectionURL "jdbc:mysql://${hostname}:3306/hive?createDatabaseIfNotExist=true"
    ${XML_CONFIG_TOOLS} put ${HIVE_CONFIG_PATH}/hive-site.xml javax.jdo.option.ConnectionUserName root
    ${XML_CONFIG_TOOLS} put ${HIVE_CONFIG_PATH}/hive-site.xml javax.jdo.option.ConnectionPassword ${MYSQL_ROOT_PASSWORD}
    ${XML_CONFIG_TOOLS} put ${HIVE_CONFIG_PATH}/hive-site.xml hive.cli.print.header true
    ${XML_CONFIG_TOOLS} put ${HIVE_CONFIG_PATH}/hive-site.xml hive.enforce.bucketing true
    # 创建数据库，并设置编码
    ${MYSQL_HOME}/bin/mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "create database hive DEFAULT CHARSET latin1;" >>${LOCAL_LOGS_FILE} 2>&1
    # 修改环境变量
    ${PROPERTIES_CONFIG_TOOLS} put ${ENVIRONMENT_VARIABLE_FILE} "HIVE_HOME" ${HIVE_HOME} 1
    # 增加PATH
    sed -i 's/^export PATH=/export PATH=${HIVE_HOME}\/bin:/g' ${ENVIRONMENT_VARIABLE_FILE}
    source ${ENVIRONMENT_VARIABLE_FILE}
    [[ $? -ne 0 ]] && exit $?
    ${PROPERTIES_CONFIG_TOOLS} put ${LOCAL_VERSION_FILE} "version.hive" ${HIVE_VERSION}
    echo ""
    echo "Install hive successfully!!!"
    echo ""
    # 测试hive，在mysql中初始化hive元数据表
    echo "测试hive,展示数据库列表"
    ${HIVE_HOME}/bin/hive -S -e "show databases;"
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
