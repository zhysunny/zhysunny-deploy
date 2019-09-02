#!/bin/sh
   
# Author : 章云
# Date   : 2019/8/21 8:57

Usage()
{
    echo "Usage："
	echo "sh zhysunny_service.sh installVM <hostname>"
	echo "sh zhysunny_service.sh getApps [apps]?"
	echo "sh zhysunny_service.sh install [apps]?"
	echo "sh zhysunny_service.sh uninstall [apps]?"
	echo "sh zhysunny_service.sh prepare | install :   prepareOnlyCloudera & prepareOnlyES [--mysqlhost=] "
	echo "sh zhysunny_service.sh start             :   startOnlyCloudera & startOnlyES  "
	echo "sh zhysunny_service.sh stop              :   stopOnlyCloudera & stopOnlyES  "
	echo "sh zhysunny_service.sh restart           :   restartOnlyCloudera & restartOnlyES  "
	echo "sh zhysunny_service.sh clean | uninstall :   cleanOnlyCloudera & cleanOnlyES  "
    exit 1
}

# 当前文件所在目录，这里是相对路径
LOCAL_PATH=`dirname $0`
# 当前文件所在目录转为绝对路径
LOCAL_PATH=`cd ${LOCAL_PATH};pwd`
# config目录，存放配置文件
LOCAL_CONFIG_PATH=${LOCAL_PATH}/config
# config/deploy.properties，全局配置文件
LOCAL_CONFIG_DEPLOY_FILE=${LOCAL_CONFIG_PATH}/deploy.properties
# config/virtual.properties，虚拟机配置文件
LOCAL_CONFIG_VIRTUAL_FILE=${LOCAL_CONFIG_PATH}/virtual.properties
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
# 修改文件配置的脚本
XML_CONFIG_TOOLS=${LOCAL_TOOLS_PATH}/xml_config_tools.sh
# 修改文件配置的脚本
PROPERTIES_CONFIG_TOOLS=${LOCAL_TOOLS_PATH}/properties_config_tools.sh
# mysql root密码
MYSQL_ROOT_PASSWORD=`awk -F= '{if($1~/^mysql.root.password$/) print $2}' ${LOCAL_CONFIG_DEPLOY_FILE}`
source ${LOCAL_TOOLS_PATH}/Arrays.sh

export LOCAL_PATH
export LOCAL_CONFIG_PATH
export LOCAL_CONFIG_DEPLOY_FILE
export LOCAL_CONFIG_VIRTUAL_FILE
export LOCAL_LIB_PATH
export LOCAL_TOOLS_PATH
export LOCAL_TOOLS_APPS_PATH
export INSTALL_PATH
export LOCAL_LOGS_FILE
export ENVIRONMENT_VARIABLE_FILE
export LOCAL_VERSION_FILE
export XML_CONFIG_TOOLS
export PROPERTIES_CONFIG_TOOLS
export MYSQL_ROOT_PASSWORD

# 步骤
declare -i step
declare -a INSTALL_APPS
declare -a UNINSTALL_APPS
step=1
export step
export INSTALL_APPS
export UNINSTALL_APPS

installVM(){
    if [[ $# -ne 1 ]]
    then
        Usage
        exit 1
    fi
    echo "初始化虚拟机节点配置"
    echo ""
    # 必须手动设置过静态IP
    echo "Step $step : 配置域名"
    echo ""
    step=${step}+1
    ${LOCAL_TOOLS_APPS_PATH}/virtual_manager.sh modifyHostname $1
    echo ""
    echo "Step $step : 关闭防火墙、selinux"
    echo ""
    step=${step}+1
    ${LOCAL_TOOLS_APPS_PATH}/virtual_manager.sh closeFirewall
    echo ""
    echo "Step $step : 初始化免秘钥"
    echo ""
    step=${step}+1
    ${LOCAL_TOOLS_APPS_PATH}/virtual_manager.sh secretKey
    # 其他操作
    ${LOCAL_TOOLS_APPS_PATH}/virtual_manager.sh other
}

install(){
    # 安装之前先卸载，如果新的安装包不一样，需要用老版本deploy卸载
    getApps $*
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
        step=${step}+1
    else
        JAVA_HOME=`${PROPERTIES_CONFIG_TOOLS} get ${ENVIRONMENT_VARIABLE_FILE} "JAVA_HOME"`
    fi
    export JAVA_HOME

    if [[ `contains "scala" ${INSTALL_APPS[*]}` -eq 0 ]]
    then
        echo ""
        echo "Step $step Start install scala ..."
        echo ""
        ${LOCAL_TOOLS_APPS_PATH}/scala_manager.sh install
        step=${step}+1
    else
        SCALA_HOME=`${PROPERTIES_CONFIG_TOOLS} get ${ENVIRONMENT_VARIABLE_FILE} "SCALA_HOME"`
    fi
    export SCALA_HOME

    if [[ `contains "mysql" ${INSTALL_APPS[*]}` -eq 0 ]]
    then
        echo ""
        echo "Step $step Start install mysql ..."
        echo ""
        ${LOCAL_TOOLS_APPS_PATH}/mysql_manager.sh install
        step=${step}+1
    else
        MYSQL_HOME=`${PROPERTIES_CONFIG_TOOLS} get ${ENVIRONMENT_VARIABLE_FILE} "MYSQL_HOME"`
    fi
    export MYSQL_HOME

    if [[ `contains "hadoop" ${INSTALL_APPS[*]}` -eq 0 ]]
    then
        echo ""
        echo "Step $step Start install hadoop ..."
        echo ""
        ${LOCAL_TOOLS_APPS_PATH}/hadoop_manager.sh install
        step=${step}+1
    else
        HADOOP_HOME=`${PROPERTIES_CONFIG_TOOLS} get ${ENVIRONMENT_VARIABLE_FILE} "HADOOP_HOME"`
    fi
    export HADOOP_HOME

    if [[ `contains "hive" ${INSTALL_APPS[*]}` -eq 0 ]]
    then
        echo ""
        echo "Step $step Start install hive ..."
        echo ""
        ${LOCAL_TOOLS_APPS_PATH}/hive_manager.sh install
        step=${step}+1
    else
        HIVE_HOME=`${PROPERTIES_CONFIG_TOOLS} get ${ENVIRONMENT_VARIABLE_FILE} "HIVE_HOME"`
    fi
    export HIVE_HOME

    if [[ `contains "zookeeper" ${INSTALL_APPS[*]}` -eq 0 ]]
    then
        echo ""
        echo "Step $step Start install zookeeper ..."
        echo ""
        ${LOCAL_TOOLS_APPS_PATH}/zookeeper_manager.sh install
        step=${step}+1
    fi

    if [[ `contains "redis" ${INSTALL_APPS[*]}` -eq 0 ]]
    then
        echo ""
        echo "Step $step Start install redis ..."
        echo ""
        ${LOCAL_TOOLS_APPS_PATH}/redis_manager.sh install
        step=${step}+1
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
    getApps $*
    source ${ENVIRONMENT_VARIABLE_FILE}

    if [[ `contains "jdk" ${INSTALL_APPS[*]}` -eq 0 ]]
    then
        echo ""
        echo "Step $step Start uninstall jdk ..."
        echo ""
        ${LOCAL_TOOLS_APPS_PATH}/jdk_manager.sh uninstall
        step=${step}+1
    fi

    if [[ `contains "scala" ${INSTALL_APPS[*]}` -eq 0 ]]
    then
        echo ""
        echo "Step $step Start uninstall scala ..."
        echo ""
        ${LOCAL_TOOLS_APPS_PATH}/scala_manager.sh uninstall
        step=${step}+1
    fi

    if [[ `contains "mysql" ${INSTALL_APPS[*]}` -eq 0 ]]
    then
        echo ""
        echo "Step $step Start uninstall mysql ..."
        echo ""
        ${LOCAL_TOOLS_APPS_PATH}/mysql_manager.sh uninstall
        step=${step}+1
    fi

    if [[ `contains "hadoop" ${INSTALL_APPS[*]}` -eq 0 ]]
    then
        echo ""
        echo "Step $step Start uninstall hadoop ..."
        echo ""
        ${LOCAL_TOOLS_APPS_PATH}/hadoop_manager.sh uninstall
        step=${step}+1
    fi

    if [[ `contains "hive" ${INSTALL_APPS[*]}` -eq 0 ]]
    then
        echo ""
        echo "Step $step Start uninstall hive ..."
        echo ""
        ${LOCAL_TOOLS_APPS_PATH}/hive_manager.sh uninstall
        step=${step}+1
    fi

    if [[ `contains "zookeeper" ${INSTALL_APPS[*]}` -eq 0 ]]
    then
        echo ""
        echo "Step $step Start uninstall zookeeper ..."
        echo ""
        ${LOCAL_TOOLS_APPS_PATH}/zookeeper_manager.sh uninstall
        step=${step}+1
    fi

    if [[ `contains "redis" ${INSTALL_APPS[*]}` -eq 0 ]]
    then
        echo ""
        echo "Step $step Start uninstall redis ..."
        echo ""
        ${LOCAL_TOOLS_APPS_PATH}/redis_manager.sh uninstall
        step=${step}+1
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
    if [[ $# -gt 0 ]]
    then
        # 优先使用传入的参数
        INSTALL_APPS=($*)
        UNINSTALL_APPS=($*)
    else
        # 否则读取配置文件
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
    fi
    echo ""
    echo "Install apps: ${INSTALL_APPS[*]}"
    echo ""
    echo "Uninstall apps: ${UNINSTALL_APPS[*]}"
    echo ""
}

COMMAND=$1

#参数位置左移1
shift

case ${COMMAND} in
    installVM )
        installVM $*
        ;;
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
		getApps $*
		;;
    * )
		Usage
        exit 1
        ;;
esac
