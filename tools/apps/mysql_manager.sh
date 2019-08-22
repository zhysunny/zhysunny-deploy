#!/bin/sh
   
# Author : 章云
# Date   : 2019/8/21 15:50

Usage()
{
    echo "Usage: sh mysql_manager.sh install | uninstall"
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
MYSQL_VERSION=`awk -F= '{if($1~/^version.mysql$/) print $2}' ${LOCAL_CONFIG_DEPLOY_FILE}`
MYSQL_NAME="mysql"
MYSQL_PACKAGE_NAME=${MYSQL_NAME}
MYSQL_INSTALL_FILE=${LOCAL_LIB_PATH}/${MYSQL_NAME}/${MYSQL_NAME}-${MYSQL_VERSION}.tar.gz
# 安装目录不能变，这里写死
MYSQL_INSTALL_PATH=/usr/local
# 已安装的程序目录
installed_file=${MYSQL_INSTALL_PATH}/${MYSQL_PACKAGE_NAME}

install(){
    # mysql目录是否已存在
    if [[ -e ${installed_file} ]]
    then
        rm -rf ${installed_file}
    fi
    tar -xvf ${MYSQL_INSTALL_FILE} -C ${MYSQL_INSTALL_PATH} >>${LOCAL_LOGS_FILE} 2>&1
    # mysql用户组是否存在
	if [[ -z "`cat /etc/group|grep mysql`" ]]
	then
		groupadd mysql
	else
		echo "mysql用户组已存在"
	fi
	# mysql用户是否存在
	if [[ -z "`cat /etc/shadow|grep mysql`" ]]
	then
		echo "添加mysql用户并设置mysql用户密码"
		useradd -g mysql mysql
        echo "mysql" | passwd --stdin mysql
	else
		echo "mysql用户已存在"
	fi
	# mysql数据库是否存在
	if [[ -z "`ls $installed_file/data`" ]]
	then
		echo "开始初始化数据库"
		chown -R mysql:mysql ${installed_file}
		${installed_file}/scripts/mysql_install_db --user=mysql --defaults-file=${installed_file}/my.cnf --basedir=${installed_file} --datadir=${installed_file}/data >>${LOCAL_LOGS_FILE} 2>&1
	else
		echo "数据库目录已存在，不需要初始化数据库库"
	fi
	echo "启动mysql服务,并设置开机自启动"
	cp ${installed_file}/support-files/mysql.server /etc/init.d/mysqld
	service mysqld start
	chkconfig --add mysqld
	chkconfig --level 345 mysqld on


    # 修改环境变量
    MYSQL_HOME=${installed_file}
    result=(`cat ${ENVIRONMENT_VARIABLE_FILE} | grep "export MYSQL_HOME="`)
    if [[ ${#result[*]} -eq 0 ]]
    then
        # 没有MYSQL_HOME增加
        echo "export MYSQL_HOME=$MYSQL_HOME" >> ${ENVIRONMENT_VARIABLE_FILE}
    else
        MYSQL_HOME=`echo ${MYSQL_HOME} | sed 's#\/#\\\/#g'`
        sed -i "s/^export MYSQL_HOME=.*/export MYSQL_HOME=$MYSQL_HOME/g" ${ENVIRONMENT_VARIABLE_FILE}
        MYSQL_HOME=`echo ${MYSQL_HOME} | sed 's#\\\/#\/#g'`
    fi
    # 增加PATH
    sed -i 's/^export PATH=/export PATH=${MYSQL_HOME}\/bin:/g' ${ENVIRONMENT_VARIABLE_FILE}
	source ${ENVIRONMENT_VARIABLE_FILE}
	# 设置mysql root密码
	${MYSQL_HOME}/bin/mysql -uroot -e "UPDATE mysql.user SET PASSWORD=PASSWORD(\"$MYSQL_ROOT_PASSWORD\") WHERE USER='root';flush privileges;grant all privileges on *.* to root@'%' identified by \"$MYSQL_ROOT_PASSWORD\" with grant option;"

    [[ $? -ne 0 ]] && exit $?
    echo ""
    echo "Install mysql successfully!!!"
    echo ""
    echo "# mysql版本" >> ${LOCAL_VERSION_FILE}
    echo "version.mysql=${MYSQL_VERSION}" >> ${LOCAL_VERSION_FILE}
    export MYSQL_HOME
}

uninstall(){
    # 关闭mysql，取消开机自启动
    chkconfig --del mysqld
    service mysqld stop
    rm -rf /etc/init.d/mysqld
    if [[ -e ${installed_file} ]]
    then
        rm -rf ${installed_file}
    fi
    # mysql用户是否存在
	if [[ -z "`cat /etc/shadow|grep mysql`" ]]
	then
		echo "mysql用户不存在"
	else
		echo "删除mysql用户"
		userdel mysql
	fi
    # mysql用户组是否存在
	if [[ -z "`cat /etc/group|grep mysql`" ]]
	then
		echo "mysql用户组不存在"
	else
		echo "删除mysql用户组"
		groupdel mysql
	fi
    # 删除环境变量
    MYSQL_HOME=${installed_file}
    sed -i "/export MYSQL_HOME=.*/d" ${ENVIRONMENT_VARIABLE_FILE}
    # 删除PATH
    sed -i 's/${MYSQL_HOME}\/bin://g' ${ENVIRONMENT_VARIABLE_FILE}
    sed -i 's/$MYSQL_HOME\/bin://g' ${ENVIRONMENT_VARIABLE_FILE}

    [[ $? -ne 0 ]] && exit $?
    echo ""
    echo "Uninstall mysql successfully!!!"
    echo ""
    if [[ -e "${LOCAL_VERSION_FILE}" ]]
    then
        sed -i "/.*mysql.*/d" ${LOCAL_VERSION_FILE}
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
