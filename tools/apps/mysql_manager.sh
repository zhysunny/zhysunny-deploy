#!/bin/sh
   
# Author : 章云
# Date   : 2019/8/21 15:50

Usage()
{
    echo "Usage: sh mysql_manager.sh install | uninstall"
    exit 1
}

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
        echo "mysql已安装"
        exit 1
    fi
    tar -xvf ${MYSQL_INSTALL_FILE} -C ${MYSQL_INSTALL_PATH} >>${LOCAL_LOGS_FILE} 2>&1
    # mysql用户组是否存在
	if [[ -z "`cat /etc/group|grep mysql`" ]]
	then
		groupadd mysql
	fi
	# mysql用户是否存在
	if [[ -z "`cat /etc/shadow|grep mysql`" ]]
	then
		useradd -g mysql mysql
        echo "mysql" | passwd --stdin mysql
	fi
	# mysql数据库是否存在
	if [[ -z "`ls $installed_file/data`" ]]
	then
		chown -R mysql:mysql ${installed_file}
		${installed_file}/scripts/mysql_install_db --user=mysql --defaults-file=${installed_file}/my.cnf --basedir=${installed_file} --datadir=${installed_file}/data >>${LOCAL_LOGS_FILE} 2>&1
	fi
	# 设置开机自启动
	cp ${installed_file}/support-files/mysql.server /etc/init.d/mysqld
	service mysqld start
	chkconfig --add mysqld
	chkconfig --level 345 mysqld on

    # 修改环境变量
    MYSQL_HOME=${installed_file}
    ${PROPERTIES_CONFIG_TOOLS} put ${ENVIRONMENT_VARIABLE_FILE} "MYSQL_HOME" ${MYSQL_HOME} 1
    # 增加PATH
    sed -i 's/^export PATH=/export PATH=${MYSQL_HOME}\/bin:/g' ${ENVIRONMENT_VARIABLE_FILE}
	source ${ENVIRONMENT_VARIABLE_FILE}
	# 设置mysql root密码
	${MYSQL_HOME}/bin/mysql -uroot -e "UPDATE mysql.user SET PASSWORD=PASSWORD(\"$MYSQL_ROOT_PASSWORD\") WHERE USER='root';flush privileges;grant all privileges on *.* to root@'%' identified by \"$MYSQL_ROOT_PASSWORD\" with grant option;"

    [[ $? -ne 0 ]] && exit $?
    ${PROPERTIES_CONFIG_TOOLS} put ${LOCAL_VERSION_FILE} "version.mysql" ${MYSQL_VERSION}
    echo ""
    echo "Install mysql successfully!!!"
    echo ""
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
	if [[ -n "`cat /etc/shadow|grep mysql`" ]]
	then
		userdel mysql
		rm -rf /home/mysql
	fi
    # mysql用户组是否存在
	if [[ -n "`cat /etc/group|grep mysql`" ]]
	then
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
