#!/bin/sh
   
# Author : 章云
# Date   : 2019/8/22 10:41

Usage()
{
    echo "Usage: sh phoenix_manager.sh (install | uninstall | prepare | clean)"
    exit 1
}

PHOENIX_VERSION=`awk -F= '{if($1~/^version.phoenix$/) print $2}' ${LOCAL_CONFIG_DEPLOY_FILE}`
PHOENIX_NAME="phoenix"
PHOENIX_PACKAGE_NAME=${PHOENIX_NAME}-${PHOENIX_VERSION}
PHOENIX_INSTALL_FILE=${LOCAL_LIB_PATH}/${PHOENIX_NAME}/apache-${PHOENIX_PACKAGE_NAME}-bin.tar.gz
# 已安装的程序目录
installed_file=${INSTALL_PATH}/${PHOENIX_PACKAGE_NAME}
MYSQL_JAR_FILE_NAME=mysql-connector-*.jar

install(){
    source ${ENVIRONMENT_VARIABLE_FILE}
    if [[ -z "${HBASE_HOME}" ]]
    then
        echo "HBASE_HOME is empty，can not install phoenix"
        exit 1
    fi
    if [[ -e ${installed_file} ]]
    then
        echo "phoenix已安装"
        exit 1
    fi
    tar -xvf ${PHOENIX_INSTALL_FILE} -C ${INSTALL_PATH} >>${LOCAL_LOGS_FILE} 2>&1
    mv ${INSTALL_PATH}/apache-${PHOENIX_PACKAGE_NAME}-bin ${installed_file}
    # 修改配置
    PHOENIX_HOME=${installed_file}
    # 修改xml配置
    hostname=`hostname`
    cp ${PHOENIX_HOME}/phoenix-core-${PHOENIX_VERSION}.jar ${HBASE_HOME}/lib/
    ${XML_CONFIG_TOOLS} put ${PHOENIX_HOME}/bin/hbase-site.xml "phoenix.schema.isNamespaceMappingEnabled" "true"
    # 重启hbase
    service hbase stop
    service hbase start
    # 修改环境变量
    ${PROPERTIES_CONFIG_TOOLS} put ${ENVIRONMENT_VARIABLE_FILE} "PHOENIX_HOME" ${PHOENIX_HOME} 1
    # 增加PATH
    sed -i 's/^export PATH=/export PATH=${PHOENIX_HOME}\/bin:/g' ${ENVIRONMENT_VARIABLE_FILE}
    source ${ENVIRONMENT_VARIABLE_FILE}
    [[ $? -ne 0 ]] && exit $?
    ${PROPERTIES_CONFIG_TOOLS} put ${LOCAL_VERSION_FILE} "version.phoenix" ${PHOENIX_VERSION}
    echo ""
    echo "Install phoenix successfully!!!"
    echo ""
    export PHOENIX_HOME
}

uninstall(){
    if [[ -e ${installed_file} ]]
    then
        rm -rf ${installed_file}
    fi
    # 删除环境变量
    PHOENIX_HOME=${installed_file}
    sed -i "/export PHOENIX_HOME=.*/d" ${ENVIRONMENT_VARIABLE_FILE}
    # 删除PATH
    sed -i 's/${PHOENIX_HOME}\/bin://g' ${ENVIRONMENT_VARIABLE_FILE}
    sed -i 's/$PHOENIX_HOME\/bin://g' ${ENVIRONMENT_VARIABLE_FILE}

    [[ $? -ne 0 ]] && exit $?
    echo ""
    echo "Uninstall phoenix successfully!!!"
    echo ""
    if [[ -e "${LOCAL_VERSION_FILE}" ]]
    then
        sed -i "/.*phoenix.*/d" ${LOCAL_VERSION_FILE}
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
