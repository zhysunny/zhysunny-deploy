#!/bin/sh
   
# Author : 章云
# Date   : 2019/8/21 15:50

Usage()
{
    echo "Usage: sh redis_manager.sh install | uninstall"
    exit 1
}

REDIS_VERSION=`awk -F= '{if($1~/^version.redis$/) print $2}' ${LOCAL_CONFIG_DEPLOY_FILE}`
REDIS_NAME="redis"
REDIS_PACKAGE_NAME=${REDIS_NAME}-${REDIS_VERSION}
REDIS_INSTALL_FILE=${LOCAL_LIB_PATH}/${REDIS_NAME}/${REDIS_PACKAGE_NAME}.tar.gz
# 已安装的程序目录
installed_file=${INSTALL_PATH}/${REDIS_PACKAGE_NAME}

install(){
    if [[ -e ${installed_file} ]]
    then
        echo "redis已安装"
        exit 1
    fi
    tar -xvf ${REDIS_INSTALL_FILE} -C ${INSTALL_PATH} >>${LOCAL_LOGS_FILE} 2>&1
    # 编译
    cd ${installed_file}
    make MALLOC=libc >>${LOCAL_LOGS_FILE} 2>&1
    cd src && make install >>${LOCAL_LOGS_FILE} 2>&1
    # 修改配置
    port=`${PROPERTIES_CONFIG_TOOLS} get ${installed_file}/redis.conf port`
    ${PROPERTIES_CONFIG_TOOLS} put ${installed_file}/redis.conf "bind" `hostname` 2
    ${PROPERTIES_CONFIG_TOOLS} put ${installed_file}/redis.conf "daemonize" "yes" 2
    ${PROPERTIES_CONFIG_TOOLS} put ${installed_file}/redis.conf "pidfile" ${installed_file}/redis_${port}.pid 2
    ${PROPERTIES_CONFIG_TOOLS} put ${installed_file}/redis.conf "logfile" ${installed_file}/redis_${port}.log 2
    # 修改自启动配置
    ${PROPERTIES_CONFIG_TOOLS} put ${installed_file}/utils/redis_init_script "REDISPORT" ${port}
    ${PROPERTIES_CONFIG_TOOLS} put ${installed_file}/utils/redis_init_script "EXEC" ${installed_file}/src/redis-server
    ${PROPERTIES_CONFIG_TOOLS} put ${installed_file}/utils/redis_init_script "CLIEXEC" ${installed_file}/src/redis-cli
    ${PROPERTIES_CONFIG_TOOLS} put ${installed_file}/utils/redis_init_script "PIDFILE" ${installed_file}/redis_${port}.pid
    ${PROPERTIES_CONFIG_TOOLS} put ${installed_file}/utils/redis_init_script "CONF" ${installed_file}/redis.conf
    sed -i 's/$CLIEXEC -p $REDISPORT shutdown/$CLIEXEC -h '`hostname`' -p $REDISPORT shutdown/g' ${installed_file}/utils/redis_init_script
    # 设置开机自启动
    cp ${installed_file}/utils/redis_init_script /etc/init.d/redisd
    service redisd start
	chkconfig --add redisd
	chkconfig --level 345 redisd on
    # 修改环境变量
    REDIS_HOME=${installed_file}
    ${PROPERTIES_CONFIG_TOOLS} put ${ENVIRONMENT_VARIABLE_FILE} "REDIS_HOME" ${REDIS_HOME} 1
    # 增加PATH
    sed -i 's/^export PATH=/export PATH=${REDIS_HOME}\/src:/g' ${ENVIRONMENT_VARIABLE_FILE}
    source ${ENVIRONMENT_VARIABLE_FILE}
    [[ $? -ne 0 ]] && exit $?
    ${PROPERTIES_CONFIG_TOOLS} put ${LOCAL_VERSION_FILE} "version.redis" ${REDIS_VERSION}
    echo ""
    echo "Install redis successfully!!!"
    echo ""
    export REDIS_HOME
}

uninstall(){
    chkconfig --del redisd
    service redisd stop
    rm -rf /etc/init.d/redisd
    rm -rf /usr/local/bin/redis-*
    if [[ -e ${installed_file} ]]
    then
        rm -rf ${installed_file}
    fi
    # 删除环境变量
    REDIS_HOME=${installed_file}
    sed -i "/export REDIS_HOME=.*/d" ${ENVIRONMENT_VARIABLE_FILE}
    # 删除PATH
    sed -i 's/${REDIS_HOME}\/src://g' ${ENVIRONMENT_VARIABLE_FILE}
    sed -i 's/$REDIS_HOME\/src://g' ${ENVIRONMENT_VARIABLE_FILE}
    
    [[ $? -ne 0 ]] && exit $?
    echo ""
    echo "Uninstall redis successfully!!!"
    echo ""
    if [[ -e "${LOCAL_VERSION_FILE}" ]]
    then
        sed -i "/.*redis.*/d" ${LOCAL_VERSION_FILE}
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
