#!/bin/sh
   
# Author : 章云
# Date   : 2019/8/21 15:50

Usage()
{
    echo "Usage: sh scala_manager.sh install | uninstall"
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
SCALA_VERSION=`awk -F= '{if($1~/^version.scala$/) print $2}' ${LOCAL_CONFIG_DEPLOY_FILE}`
SCALA_NAME="scala"
SCALA_PACKAGE_NAME=${SCALA_NAME}-${SCALA_VERSION}
SCALA_INSTALL_FILE=${LOCAL_LIB_PATH}/${SCALA_NAME}/${SCALA_PACKAGE_NAME}.tar.gz
# 已安装的程序目录
installed_file=${INSTALL_PATH}/${SCALA_PACKAGE_NAME}

install(){
    if [[ -e ${installed_file} ]]
    then
        rm -rf ${installed_file}
    fi
    tar -xvf ${SCALA_INSTALL_FILE} -C ${INSTALL_PATH} >>${LOCAL_LOGS_FILE} 2>&1
    # 修改环境变量
    SCALA_HOME=${installed_file}
    result=(`cat ${ENVIRONMENT_VARIABLE_FILE} | grep "export SCALA_HOME="`)
    if [[ ${#result[*]} -eq 0 ]]
    then
        # 没有SCALA_HOME增加
        echo "export SCALA_HOME=$SCALA_HOME" >> ${ENVIRONMENT_VARIABLE_FILE}
    else
        SCALA_HOME=`echo ${SCALA_HOME} | sed 's#\/#\\\/#g'`
        sed -i "s/^export SCALA_HOME=.*/export SCALA_HOME=$SCALA_HOME/g" ${ENVIRONMENT_VARIABLE_FILE}
        SCALA_HOME=`echo ${SCALA_HOME} | sed 's#\\\/#\/#g'`
    fi
    # 增加PATH
    sed -i 's/^export PATH=/export PATH=${SCALA_HOME}\/bin:/g' ${ENVIRONMENT_VARIABLE_FILE}
    source ${ENVIRONMENT_VARIABLE_FILE}
    [[ $? -ne 0 ]] && exit $?
    echo ""
    echo "Install scala successfully!!!"
    echo ""
    echo "# scala版本" >> ${LOCAL_VERSION_FILE}
    echo "version.scala=${SCALA_VERSION}" >> ${LOCAL_VERSION_FILE}
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
