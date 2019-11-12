#!/bin/sh
   
# Author : 章云
# Date   : 2019/8/21 15:50

Usage()
{
    echo "Usage: sh jdk_manager.sh install | uninstall"
    exit 1
}

JDK_VERSION=`awk -F= '{if($1~/^version.jdk$/) print $2}' ${LOCAL_CONFIG_DEPLOY_FILE}`
JDK_NAME="jdk"
JDK_PACKAGE_NAME=${JDK_NAME}-${JDK_VERSION}
JDK_INSTALL_FILE=${LOCAL_LIB_PATH}/${JDK_NAME}/${JDK_PACKAGE_NAME}.tar.gz
# 已安装的程序目录
installed_file=${INSTALL_PATH}/${JDK_PACKAGE_NAME}

install(){
    if [[ -e ${installed_file} ]]
    then
        echo "jdk已安装"
        exit 1
    fi
    tar -xvf ${JDK_INSTALL_FILE} -C ${INSTALL_PATH} >>${LOCAL_LOGS_FILE} 2>&1
    # 修改环境变量
    JAVA_HOME=${installed_file}
    ${PROPERTIES_CONFIG_TOOLS} put ${ENVIRONMENT_VARIABLE_FILE} "JAVA_HOME" ${JAVA_HOME} 1
    # 增加PATH
    sed -i 's/^export PATH=/export PATH=${JAVA_HOME}\/bin:/g' ${ENVIRONMENT_VARIABLE_FILE}
    source ${ENVIRONMENT_VARIABLE_FILE}
    [[ $? -ne 0 ]] && exit $?
    ${PROPERTIES_CONFIG_TOOLS} put ${LOCAL_VERSION_FILE} "version.jdk" ${JDK_VERSION}
    echo ""
    echo "Install jdk successfully!!!"
    echo ""
    export JAVA_HOME
}

uninstall(){
    if [[ -e ${installed_file} ]]
    then
        rm -rf ${installed_file}
    fi
    # 删除环境变量
    JAVA_HOME=${installed_file}
    sed -i "/export JAVA_HOME=.*/d" ${ENVIRONMENT_VARIABLE_FILE}
    # 删除PATH
    sed -i 's/${JAVA_HOME}\/bin://g' ${ENVIRONMENT_VARIABLE_FILE}
    sed -i 's/$JAVA_HOME\/bin://g' ${ENVIRONMENT_VARIABLE_FILE}

    [[ $? -ne 0 ]] && exit $?
    echo ""
    echo "Uninstall jdk successfully!!!"
    echo ""
    if [[ -e "${LOCAL_VERSION_FILE}" ]]
    then
        sed -i "/.*jdk.*/d" ${LOCAL_VERSION_FILE}
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
