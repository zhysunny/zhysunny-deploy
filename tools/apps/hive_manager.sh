#!/bin/sh
   
# Author : 章云
# Date   : 2019/8/22 10:41

Usage()
{
    echo "Usage: sh hive_manager.sh (install | uninstall | prepare | clean)"
    exit 1
}

HIVE_VERSION=`awk -F= '{if($1~/^version.hive$/) print $2}' ${LOCAL_CONFIG_DEPLOY_FILE}`
HIVE_NAME="hive"
HIVE_PACKAGE_NAME=${HIVE_NAME}-${HIVE_VERSION}
HIVE_INSTALL_FILE=${LOCAL_LIB_PATH}/${HIVE_NAME}/apache-${HIVE_PACKAGE_NAME}-bin.tar.gz
# 已安装的程序目录
installed_file=${INSTALL_PATH}/${HIVE_PACKAGE_NAME}
MYSQL_JAR_FILE_NAME=mysql-connector-*.jar

install(){
    source ${ENVIRONMENT_VARIABLE_FILE}
    if [[ -z "${HADOOP_HOME}" ]]
    then
        echo "HADOOP_HOME is empty，can not install hive"
        exit 1
    fi
    if [[ -z "${MYSQL_HOME}" ]]
    then
        echo "MYSQL_HOME is empty，can not install hive"
        exit 1
    fi
    if [[ -e ${installed_file} ]]
    then
        echo "hive已安装"
        exit 1
    fi
    tar -xvf ${HIVE_INSTALL_FILE} -C ${INSTALL_PATH} >>${LOCAL_LOGS_FILE} 2>&1
    mv ${INSTALL_PATH}/apache-${HIVE_PACKAGE_NAME}-bin ${installed_file}
    # 修改配置
    HIVE_HOME=${installed_file}
    HIVE_CONFIG_PATH=${HIVE_HOME}/conf
    cp ${HIVE_CONFIG_PATH}/hive-default.xml.template ${HIVE_CONFIG_PATH}/hive-default.xml
    ${XML_CONFIG_TOOLS} createXmlFile ${HIVE_CONFIG_PATH}/hive-site.xml
    rm -rf ${HADOOP_HOME}/share/hadoop/yarn/lib/jline*.jar
    cp ${HIVE_HOME}/lib/jline*.jar ${HADOOP_HOME}/share/hadoop/yarn/lib
    rm -rf ${HIVE_HOME}/lib/${MYSQL_JAR_FILE_NAME}
    cp ${LOCAL_LIB_PATH}/jars/${MYSQL_JAR_FILE_NAME} ${HIVE_HOME}/lib/
    # 修改xml配置
    hostname=`hostname`
    HIVE_TEMP_PATH="${HIVE_HOME}/tmp"
    # 必须修改的配置，否则报错
    ${XML_CONFIG_TOOLS} put ${HIVE_CONFIG_PATH}/hive-site.xml "hive.exec.scratchdir" "${HIVE_TEMP_PATH}/hive"
    ${XML_CONFIG_TOOLS} put ${HIVE_CONFIG_PATH}/hive-site.xml "hive.hbase.snapshot.restoredir" "${HIVE_TEMP_PATH}"
    ${XML_CONFIG_TOOLS} put ${HIVE_CONFIG_PATH}/hive-site.xml "hive.exec.local.scratchdir" "${HIVE_TEMP_PATH}"
    ${XML_CONFIG_TOOLS} put ${HIVE_CONFIG_PATH}/hive-site.xml "hive.downloaded.resources.dir" "${HIVE_TEMP_PATH}/\${hive.session.id}_resources"
    ${XML_CONFIG_TOOLS} put ${HIVE_CONFIG_PATH}/hive-site.xml "hive.querylog.location" "${HIVE_TEMP_PATH}"
    ${XML_CONFIG_TOOLS} put ${HIVE_CONFIG_PATH}/hive-site.xml "hive.server2.logging.operation.log.location" "${HIVE_TEMP_PATH}/operation_logs"
    # 数据库配置
    ${XML_CONFIG_TOOLS} put ${HIVE_CONFIG_PATH}/hive-site.xml "javax.jdo.option.ConnectionDriverName" "com.mysql.jdbc.Driver"
    ${XML_CONFIG_TOOLS} put ${HIVE_CONFIG_PATH}/hive-site.xml "javax.jdo.option.ConnectionURL" "jdbc:mysql://${hostname}:3306/hive?createDatabaseIfNotExist=true"
    ${XML_CONFIG_TOOLS} put ${HIVE_CONFIG_PATH}/hive-site.xml "javax.jdo.option.ConnectionUserName" "root"
    ${XML_CONFIG_TOOLS} put ${HIVE_CONFIG_PATH}/hive-site.xml "javax.jdo.option.ConnectionPassword" "${MYSQL_ROOT_PASSWORD}"
    # hiveserver2配置
    ${XML_CONFIG_TOOLS} put ${HIVE_CONFIG_PATH}/hive-site.xml "hive.server2.thrift.bind.host" "${hostname}"
    # 其他配置
    ${XML_CONFIG_TOOLS} put ${HIVE_CONFIG_PATH}/hive-site.xml "hive.cli.print.header" "true"
    ${XML_CONFIG_TOOLS} put ${HIVE_CONFIG_PATH}/hive-site.xml "hive.enforce.bucketing" "true"
    ${XML_CONFIG_TOOLS} put ${HIVE_CONFIG_PATH}/hive-site.xml "hive.cli.print.current.db" "true"
    # 创建数据库，并设置编码
    ${MYSQL_HOME}/bin/mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "create database hive DEFAULT CHARSET latin1;" >>${LOCAL_LOGS_FILE} 2>&1
    # 修改环境变量
    ${PROPERTIES_CONFIG_TOOLS} put ${ENVIRONMENT_VARIABLE_FILE} "HIVE_HOME" ${HIVE_HOME} 1
    # 增加PATH
    sed -i 's/^export PATH=/export PATH=${HIVE_HOME}\/bin:/g' ${ENVIRONMENT_VARIABLE_FILE}
    source ${ENVIRONMENT_VARIABLE_FILE}
    # 增加udf
    HIVE_AUXLIB_PATH="${HIVE_HOME}/auxlib"
    mkdir -p ${HIVE_AUXLIB_PATH}
    cp ${LOCAL_TOOLS_PATH}/lib/zhysunny-hive-1.1.jar ${HIVE_AUXLIB_PATH}
    # 修改日志配置
    HIVE_LOG4J_FILE="${HIVE_HOME}/conf/hive-log4j.properties"
    cp ${HIVE_LOG4J_FILE}.template ${HIVE_LOG4J_FILE}
    ${XML_CONFIG_TOOLS} put ${HIVE_LOG4J_FILE} "hive.log.dir" "${HIVE_HOME}/logs"

    ${PROPERTIES_CONFIG_TOOLS} put ${LOCAL_VERSION_FILE} "version.hive" ${HIVE_VERSION}
    echo ""
    echo "Install hive successfully!!!"
    echo ""
    # 测试hive，在mysql中初始化hive元数据表
    echo "测试hive,展示数据库列表"
    ${HIVE_HOME}/bin/hive -S -e "show databases;"
    export HIVE_HOME
}

uninstall(){
    # 删除mysql数据库
    ${MYSQL_HOME}/bin/mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "drop database hive;" >>${LOCAL_LOGS_FILE} 2>&1
    if [[ -e ${installed_file} ]]
    then
        rm -rf ${installed_file}
    fi
    # 删除环境变量
    HIVE_HOME=${installed_file}
    sed -i "/export HIVE_HOME=.*/d" ${ENVIRONMENT_VARIABLE_FILE}
    # 删除PATH
    sed -i 's/${HIVE_HOME}\/bin://g' ${ENVIRONMENT_VARIABLE_FILE}
    sed -i 's/$HIVE_HOME\/bin://g' ${ENVIRONMENT_VARIABLE_FILE}

    [[ $? -ne 0 ]] && exit $?
    echo ""
    echo "Uninstall hive successfully!!!"
    echo ""
    if [[ -e "${LOCAL_VERSION_FILE}" ]]
    then
        sed -i "/.*hive.*/d" ${LOCAL_VERSION_FILE}
    fi
}

prepare(){
    # 建库、建表、加载数据，加载udf
    ${HIVE_HOME}/bin/hive << EOF
create database if not exists badou;
create table if not exists badou.aisles(aisle_id string, aisle string)row format delimited fields terminated by ',' stored as textfile;
create table if not exists badou.departments(department_id string, department string)row format delimited fields terminated by ',' stored as textfile;
create table if not exists badou.order_products_prior(order_id string, product_id string, add_to_cart_order string, reordered string)row format delimited fields terminated by ',' stored as textfile;
create table if not exists badou.order_products_train(order_id string, product_id string, add_to_cart_order string, reordered string)row format delimited fields terminated by ',' stored as textfile;
create table if not exists badou.orders(order_id string, user_id string, eval_set string, order_number string, order_dow string, order_hour_of_day string, days_since_prior_order string)row format delimited fields terminated by ',' stored as textfile;
create table if not exists badou.products(product_id string, product_name string, aisle_id string, department_id string)row format delimited fields terminated by ',' stored as textfile;
create table if not exists badou.udata(user_id string, item_id string, rating string, \`timestamp\` string)row format delimited fields terminated by '\t' stored as textfile;
create database if not exists test;
create table if not exists test.course(cid string, name string, tid string)row format delimited fields terminated by '\t' stored as textfile;
create table if not exists test.score(sid string, cid string, score int)row format delimited fields terminated by '\t' stored as textfile;
create table if not exists test.student(sid string, name string, birth string, gender int)row format delimited fields terminated by '\t' stored as textfile;
create table if not exists test.teacher(tid string, name string)row format delimited fields terminated by '\t' stored as textfile;
load data local inpath "${LOCAL_PATH}/data/hive/aisles.csv" into table badou.aisles;
load data local inpath "${LOCAL_PATH}/data/hive/departments.csv" into table badou.departments;
load data local inpath "${LOCAL_PATH}/data/hive/order_products_prior.csv" into table badou.order_products_prior;
load data local inpath "${LOCAL_PATH}/data/hive/order_products_train.csv" into table badou.order_products_train;
load data local inpath "${LOCAL_PATH}/data/hive/orders.csv" into table badou.orders;
load data local inpath "${LOCAL_PATH}/data/hive/products.csv" into table badou.products;
load data local inpath "${LOCAL_PATH}/data/hive/u.data" into table badou.udata;
load data local inpath "${LOCAL_PATH}/data/hive/course.txt" into table test.course;
load data local inpath "${LOCAL_PATH}/data/hive/score.txt" into table test.score;
load data local inpath "${LOCAL_PATH}/data/hive/student.txt" into table test.student;
load data local inpath "${LOCAL_PATH}/data/hive/teacher.txt" into table test.teacher;
create function to_age as 'com.zhysunny.hive.udf.BirthToAge';
create function avg_age as 'com.zhysunny.hive.udaf.AvgBirthToAge';
EOF
}

clean(){
    # 删除数据库，cascade表示如果有表存在先删表在删库，不加cascade情况下有表的数据库不能删除
    ${HIVE_HOME}/bin/hive << EOF
drop database if exists badou cascade;
drop database if exists test cascade;
drop function to_age;
drop function avg_age;
EOF
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
    prepare )
		prepare $*
		;;
	clean )
		clean $*
		;;
    * )
		Usage
        exit 1
        ;;
esac
