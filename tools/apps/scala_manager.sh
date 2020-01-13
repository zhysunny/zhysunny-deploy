#!/bin/sh
   
# Author : 章云
# Date   : 2019/8/21 15:50

Usage()
{
    echo "Usage: sh scala_manager.sh install | uninstall"
    exit 1
}

SCALA_VERSION=`awk -F= '{if($1~/^version.scala$/) print $2}' ${LOCAL_CONFIG_DEPLOY_FILE}`
SCALA_NAME="scala"
SCALA_PACKAGE_NAME=${SCALA_NAME}-${SCALA_VERSION}
SCALA_INSTALL_FILE=${LOCAL_LIB_PATH}/${SCALA_NAME}/${SCALA_PACKAGE_NAME}.tar.gz
# 已安装的程序目录
installed_file=${INSTALL_PATH}/${SCALA_PACKAGE_NAME}

install(){
    if [[ -e ${installed_file} ]]
    then
        echo "scala已安装"
        exit 1
    fi
    tar -xvf ${SCALA_INSTALL_FILE} -C ${INSTALL_PATH} >>${LOCAL_LOGS_FILE} 2>&1
    # 修改环境变量
    SCALA_HOME=${installed_file}
    ${PROPERTIES_CONFIG_TOOLS} put ${ENVIRONMENT_VARIABLE_FILE} "SCALA_HOME" ${SCALA_HOME} 1
    # 增加PATH
    sed -i 's/^export PATH=/export PATH=${SCALA_HOME}\/bin:/g' ${ENVIRONMENT_VARIABLE_FILE}
    source ${ENVIRONMENT_VARIABLE_FILE}
    [[ $? -ne 0 ]] && exit $?
    ${PROPERTIES_CONFIG_TOOLS} put ${LOCAL_VERSION_FILE} "version.scala" ${SCALA_VERSION}
    echo ""
    echo "Install scala successfully!!!"
    echo ""
    export SCALA_HOME
}

uninstall(){
    if [[ -e ${installed_file} ]]
    then
        rm -rf ${installed_file}
    fi
    # 删除环境变量
    SCALA_HOME=${installed_file}
    sed -i "/export SCALA_HOME=.*/d" ${ENVIRONMENT_VARIABLE_FILE}
    # 删除PATH
    sed -i 's/${SCALA_HOME}\/bin://g' ${ENVIRONMENT_VARIABLE_FILE}
    sed -i 's/$SCALA_HOME\/bin://g' ${ENVIRONMENT_VARIABLE_FILE}
    
    [[ $? -ne 0 ]] && exit $?
    echo ""
    echo "Uninstall scala successfully!!!"
    echo ""
    if [[ -e "${LOCAL_VERSION_FILE}" ]]
    then
        sed -i "/.*scala.*/d" ${LOCAL_VERSION_FILE}
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
