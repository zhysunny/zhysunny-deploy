#!/bin/sh
   
# Author : 章云
# Date   : 2019/8/21 15:50

Usage()
{
    echo "Usage: sh spark_manager.sh install | uninstall"
    exit 1
}

SPARK_VERSION=`awk -F= '{if($1~/^version.spark$/) print $2}' ${LOCAL_CONFIG_DEPLOY_FILE}`
SPARK_NAME="spark"
SPARK_PACKAGE_NAME=${SPARK_NAME}-${SPARK_VERSION}
SPARK_INSTALL_FILE=${LOCAL_LIB_PATH}/${SPARK_NAME}/${SPARK_PACKAGE_NAME}.tgz
# 已安装的程序目录
installed_file=${INSTALL_PATH}/${SPARK_PACKAGE_NAME}
MYSQL_JAR_FILE_NAME=mysql-connector-*.jar

install(){
    if [[ -e ${installed_file} ]]
    then
        echo "spark已安装"
        exit 1
    fi
    tar -xvf ${SPARK_INSTALL_FILE} -C ${INSTALL_PATH} >> ${LOCAL_LOGS_FILE} 2>&1
    # 修改环境变量
    SPARK_HOME=${installed_file}
    ${PROPERTIES_CONFIG_TOOLS} put ${ENVIRONMENT_VARIABLE_FILE} "SPARK_HOME" ${SPARK_HOME} 1
    # 增加PATH
    sed -i 's/^export PATH=/export PATH=${SPARK_HOME}\/bin:/g' ${ENVIRONMENT_VARIABLE_FILE}
    source ${ENVIRONMENT_VARIABLE_FILE}

    SPARK_CONFIG_PATH=${SPARK_HOME}/conf
    hostname=`hostname`
    # 目前只做单机版
    echo ${hostname} > ${SPARK_CONFIG_PATH}/slaves
    cp ${SPARK_CONFIG_PATH}/spark-env.sh.template ${SPARK_CONFIG_PATH}/spark-env.sh
    ${PROPERTIES_CONFIG_TOOLS} put ${SPARK_CONFIG_PATH}/spark-env.sh "JAVA_HOME" "${JAVA_HOME}" 1
    ${PROPERTIES_CONFIG_TOOLS} put ${SPARK_CONFIG_PATH}/spark-env.sh "HADOOP_HOME" "${HADOOP_HOME}" 1
    ${PROPERTIES_CONFIG_TOOLS} put ${SPARK_CONFIG_PATH}/spark-env.sh "SCALA_HOME" "${SCALA_HOME}" 1
    ${PROPERTIES_CONFIG_TOOLS} put ${SPARK_CONFIG_PATH}/spark-env.sh "HADOOP_CONF_DIR" "${HADOOP_HOME}/etc/hadoop" 1

    ${PROPERTIES_CONFIG_TOOLS} put ${SPARK_CONFIG_PATH}/spark-env.sh "SPARK_MASTER_HOST" "${hostname}"
    ${PROPERTIES_CONFIG_TOOLS} put ${SPARK_CONFIG_PATH}/spark-env.sh "SPARK_LOCAL_DIRS" "${SPARK_HOME}"
    ${PROPERTIES_CONFIG_TOOLS} put ${SPARK_CONFIG_PATH}/spark-env.sh "SPARK_DRIVER_MEMORY" "1G"

    # spark sql 需要将hive元数据配置放到conf目录下
    cp ${HIVE_HOME}/conf/hive-site.xml ${SPARK_CONFIG_PATH}
    rm -rf ${SPARK_HOME}/jars/${MYSQL_JAR_FILE_NAME}
    cp ${LOCAL_LIB_PATH}/jars/${MYSQL_JAR_FILE_NAME} ${SPARK_HOME}/jars/

    # 设置开机自启动
    cp ${LOCAL_TOOLS_SERVICE_PATH}/spark.sh /etc/init.d/spark
    ${PROPERTIES_CONFIG_TOOLS} put /etc/init.d/spark "ENVIRONMENT" ${ENVIRONMENT_VARIABLE_FILE}
	service spark start
	chkconfig --add spark
	chkconfig --level 345 spark on

    [[ $? -ne 0 ]] && exit $?
    ${PROPERTIES_CONFIG_TOOLS} put ${LOCAL_VERSION_FILE} "version.spark" ${SPARK_VERSION}
    echo ""
    echo "Install spark successfully!!!"
    echo ""
    export SPARK_HOME
}

uninstall(){
    chkconfig --del spark
    service spark stop
    rm -rf /etc/init.d/spark
    if [[ -e ${installed_file} ]]
    then
        rm -rf ${installed_file}
    fi
    # 删除环境变量
    SPARK_HOME=${installed_file}
    sed -i "/export SPARK_HOME=.*/d" ${ENVIRONMENT_VARIABLE_FILE}
    # 删除PATH
    sed -i 's/${SPARK_HOME}\/bin://g' ${ENVIRONMENT_VARIABLE_FILE}
    sed -i 's/$SPARK_HOME\/bin://g' ${ENVIRONMENT_VARIABLE_FILE}

    [[ $? -ne 0 ]] && exit $?
    echo ""
    echo "Uninstall spark successfully!!!"
    echo ""
    if [[ -e "${LOCAL_VERSION_FILE}" ]]
    then
        sed -i "/.*spark.*/d" ${LOCAL_VERSION_FILE}
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
