#!/bin/sh
   
# Author : 章云
# Date   : 2019/8/21 8:57

Usage()
{
    echo ""
	echo "================================ERROR: wrong arguments!================================================="
    echo "====================================Deploy Explanation=================================================="
	echo " The arguments in [] are required, and the arguments in <> are optional.   "
	echo " Deploy command include as follows       :   prepare | start | stop | restart | clean , etc. "
	echo " excute sequence                         :   prepare  -> start "
	echo " ./zhysunny_service.sh prepare | install :   prepareOnlyCloudera & prepareOnlyES [--mysqlhost=] "
	echo " ./zhysunny_service.sh start             :   startOnlyCloudera & startOnlyES  "
	echo " ./zhysunny_service.sh stop              :   stopOnlyCloudera & stopOnlyES  "
	echo " ./zhysunny_service.sh restart           :   restartOnlyCloudera & restartOnlyES  "
	echo " ./zhysunny_service.sh clean | uninstall :   cleanOnlyCloudera & cleanOnlyES  "
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
# config目录，存放配置文件
LOCAL_CONFIG_PATH=${LOCAL_PATH}/config
# config/deploy.properties，全局配置文件
LOCAL_CONFIG_DEPLOY_FILE=${LOCAL_CONFIG_PATH}/deploy.properties
# lib目录，安装文件和jar包
LOCAL_LIB_PATH=${LOCAL_PATH}/lib
# tools目录，独立应用程序的操作脚本，工具
LOCAL_TOOLS_PATH=${LOCAL_PATH}/tools
# tools/apps目录，独立应用程序的操作脚本
LOCAL_TOOLS_APPS_PATH=${LOCAL_TOOLS_PATH}/apps
# 安装目录
INSTALL_PATH=`awk -F= '{if($1~/^bigdata.install.home$/) print $2}' ${LOCAL_CONFIG_DEPLOY_FILE}`
if [[ ! -e ${INSTALL_PATH} ]]
then
    mkdir -p ${INSTALL_PATH}
fi
# 日志目录
LOCAL_LOGS_PATH=${LOCAL_PATH}/logs
if [[ ! -e ${LOCAL_LOGS_PATH} ]]
then
    mkdir -p ${LOCAL_LOGS_PATH}
fi
# 日志文件
LOCAL_LOGS_FILE=${LOCAL_LOGS_PATH}/zhysunny-deploy-$(date +%Y-%m-%d).log
# 环境变量配置文件
ENVIRONMENT_VARIABLE_FILE=`awk -F= '{if($1~/^environment.variable.file$/) print $2}' ${LOCAL_CONFIG_DEPLOY_FILE}`
# 版本信息文件，显示安装的版本号
LOCAL_VERSION_FILE=${LOCAL_PATH}/version.info
DEPLOY_VERSION=`awk -F= '{if($1~/^version.deploy$/) print $2}' ${LOCAL_CONFIG_DEPLOY_FILE}`
# 修改xml配置的脚本
MODIFY_CONFIG_XML_VALUE_TOOL=${LOCAL_TOOLS_PATH}/modify_config_xml_value.sh
# mysql root密码
MYSQL_ROOT_PASSWORD=`awk -F= '{if($1~/^mysql.root.password$/) print $2}' ${LOCAL_CONFIG_DEPLOY_FILE}`

export LOCAL_PATH
export LOCAL_CONFIG_PATH
export LOCAL_CONFIG_DEPLOY_FILE
export LOCAL_LIB_PATH
export LOCAL_TOOLS_PATH
export LOCAL_TOOLS_APPS_PATH
export INSTALL_PATH
export LOCAL_LOGS_FILE
export ENVIRONMENT_VARIABLE_FILE
export LOCAL_VERSION_FILE
export MODIFY_CONFIG_XML_VALUE_TOOL
export MYSQL_ROOT_PASSWORD

# 步骤
step=1
export step

install(){
    # 安装之前先卸载，如果新的安装包不一样，需要用老版本deploy卸载
    getApps
    # 版本信息
    echo "# 一键部署工程版本" > ${LOCAL_VERSION_FILE}
    echo "version.deploy=${DEPLOY_VERSION}" >> ${LOCAL_VERSION_FILE}
    # PATH环境变量，如果不存在添加一个，后面应用程序只增加PATH值
    result=(`cat ${ENVIRONMENT_VARIABLE_FILE} | grep "export PATH="`)
    if [[ ${#result[*]} -eq 0 ]]
    then
        # 没有PATH增加
        echo 'export PATH=${PATH}' >> ${ENVIRONMENT_VARIABLE_FILE}
    fi

    if [[ `contains "jdk" ${INSTALL_APPS[*]}` -eq 0 ]]
    then
        echo ""
        echo "Step $step Start install jdk ..."
        echo ""
        ${LOCAL_TOOLS_APPS_PATH}/jdk_manager.sh install
        step=$((step+1))
    fi

    if [[ `contains "scala" ${INSTALL_APPS[*]}` -eq 0 ]]
    then
        echo ""
        echo "Step $step Start install scala ..."
        echo ""
        ${LOCAL_TOOLS_APPS_PATH}/scala_manager.sh install
        step=$((step+1))
    fi

    if [[ `contains "mysql" ${INSTALL_APPS[*]}` -eq 0 ]]
    then
        echo ""
        echo "Step $step Start install mysql ..."
        echo ""
        ${LOCAL_TOOLS_APPS_PATH}/mysql_manager.sh install
        step=$((step+1))
    fi

    if [[ `contains "hadoop" ${INSTALL_APPS[*]}` -eq 0 ]]
    then
        echo ""
        echo "Step $step Start install hadoop ..."
        echo ""
        ${LOCAL_TOOLS_APPS_PATH}/hadoop_manager.sh install
        step=$((step+1))
    fi

    if [[ `contains "hive" ${INSTALL_APPS[*]}` -eq 0 ]]
    then
        echo ""
        echo "Step $step Start install hive ..."
        echo ""
        ${LOCAL_TOOLS_APPS_PATH}/hive_manager.sh install
        step=$((step+1))
    fi

    # 安装版本信息
    [[ $? -ne 0 ]] && exit $?
}

prepare(){
    echo ""
}

start(){
    echo ""
}

stop(){
    echo ""
}

restart(){
    echo ""
}

clean(){
    echo ""
}

uninstall(){
    getApps
    source ${ENVIRONMENT_VARIABLE_FILE}
    if [[ `contains "jdk" ${INSTALL_APPS[*]}` -eq 0 ]]
    then
        echo ""
        echo "Step $step Start uninstall jdk ..."
        echo ""
        ${LOCAL_TOOLS_APPS_PATH}/jdk_manager.sh uninstall
        step=$((step+1))
    fi

    if [[ `contains "scala" ${INSTALL_APPS[*]}` -eq 0 ]]
    then
        echo ""
        echo "Step $step Start uninstall scala ..."
        echo ""
        ${LOCAL_TOOLS_APPS_PATH}/scala_manager.sh uninstall
        step=$((step+1))
    fi

    if [[ `contains "mysql" ${INSTALL_APPS[*]}` -eq 0 ]]
    then
        echo ""
        echo "Step $step Start uninstall mysql ..."
        echo ""
        ${LOCAL_TOOLS_APPS_PATH}/mysql_manager.sh uninstall
        step=$((step+1))
    fi

    if [[ `contains "hadoop" ${INSTALL_APPS[*]}` -eq 0 ]]
    then
        echo ""
        echo "Step $step Start uninstall hadoop ..."
        echo ""
        ${LOCAL_TOOLS_APPS_PATH}/hadoop_manager.sh uninstall
        step=$((step+1))
    fi

    if [[ `contains "hive" ${INSTALL_APPS[*]}` -eq 0 ]]
    then
        echo ""
        echo "Step $step Start uninstall hive ..."
        echo ""
        ${LOCAL_TOOLS_APPS_PATH}/hive_manager.sh uninstall
        step=$((step+1))
    fi

    [[ $? -ne 0 ]] && exit $?
}

getServerHosts(){
    echo ""
}

getVersion(){
    echo ""
}

getApps(){
    # 获取需要安装的程序和不需要安装的程序
    # 加括号变数组
    source ${LOCAL_TOOLS_PATH}/Arrays.sh
    install_apps=(`awk -F= '{if($1~/^install.apps$/) print $2}' ${LOCAL_CONFIG_DEPLOY_FILE}`)
    uninstall_apps=(`awk -F= '{if($1~/^uninstall.apps$/) print $2}' ${LOCAL_CONFIG_DEPLOY_FILE}`)
    INSTALL_APPS=()
    UNINSTALL_APPS=${uninstall_apps[*]}
    if [[ ${#uninstall_apps[*]} -gt 0 ]]
    then
        for install in ${install_apps[*]}
        do
            if [[ `contains ${install} ${uninstall_apps[*]}` -eq 0 ]]
            then
                INSTALL_APPS=(`remove ${install} ${install_apps[*]}`)
            fi
        done
    else
        INSTALL_APPS=${install_apps[*]}
    fi
    echo ""
    echo "Install apps: ${INSTALL_APPS[*]}"
    echo ""
    echo "Uninstall apps: ${UNINSTALL_APPS[*]}"
    echo ""
    # 设置全局变量
    export INSTALL_APPS
}

COMMAND=$1

#参数位置左移1
shift

case ${COMMAND} in
    install )
        install $*
        ;;
    prepare )
        prepare $*
        ;;
    start )
        start $*
        ;;
	stop )
        stop $*
        ;;
	restart )
        restart $*
        ;;
	clean )
		clean $*
		;;
    uninstall )
		uninstall $*
		;;
	getServerHosts )
	    getServerHosts
	    ;;
	getVersion )
		getVersion
		;;
	getApps )
		getApps
		;;
    * )
		Usage
        exit 1
        ;;
esac
