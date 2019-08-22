#!/bin/sh
   
# Author : 章云
# Date   : 2019/8/21 15:50

Usage()
{
    echo "Usage: sh jdk_manager.sh install | uninstall"
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
JDK_VERSION=`awk -F= '{if($1~/^version.jdk$/) print $2}' ${LOCAL_CONFIG_DEPLOY_FILE}`
JDK_NAME="jdk"
JDK_PACKAGE_NAME=${JDK_NAME}-${JDK_VERSION}
JDK_INSTALL_FILE=${LOCAL_LIB_PATH}/${JDK_NAME}/${JDK_PACKAGE_NAME}.tar.gz
# 已安装的程序目录
installed_file=${INSTALL_PATH}/${JDK_PACKAGE_NAME}

install(){
    if [[ -e ${installed_file} ]]
    then
        rm -rf ${installed_file}
    fi
    tar -xvf ${JDK_INSTALL_FILE} -C ${INSTALL_PATH} >>${LOCAL_LOGS_FILE} 2>&1
    # 修改环境变量
    JAVA_HOME=${installed_file}
    result=(`cat ${ENVIRONMENT_VARIABLE_FILE} | grep "export JAVA_HOME="`)
    if [[ ${#result[*]} -eq 0 ]]
    then
        # 没有JAVA_HOME增加
        echo "export JAVA_HOME=$JAVA_HOME" >> ${ENVIRONMENT_VARIABLE_FILE}
    else
        JAVA_HOME=`echo ${JAVA_HOME} | sed 's#\/#\\\/#g'`
        sed -i "s/^export JAVA_HOME=.*/export JAVA_HOME=$JAVA_HOME/g" ${ENVIRONMENT_VARIABLE_FILE}
    fi
    # 增加PATH
    sed -i 's/export PATH=/export PATH=${JAVA_HOME}\/bin:/g' ${ENVIRONMENT_VARIABLE_FILE}
    source ${ENVIRONMENT_VARIABLE_FILE}
    [[ $? -ne 0 ]] && exit $?
    echo ""
    echo "Install jdk successfully!!!"
    echo ""
    echo "# jdk版本" >> ${LOCAL_VERSION_FILE}
    echo "version.jdk=${JDK_VERSION}" >> ${LOCAL_VERSION_FILE}
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
