#!/bin/sh
# chkconfig: 2345 60 40
# Author      : 章云
# Date        : 2020/2/15 8:57
# Description : 开机自启动脚本，适用于单机版，集群版由于启动时间不一致会导致组件启动失败

Usage()
{
    echo "Usage：(start | stop | restart) as first argument"
    exit 1
}

ENVIRONMENT=/etc/profile
source ${ENVIRONMENT}

start(){
    cd ${ES_HOME}/bin
    sudo -u elasticsearch sh elasticsearch > /dev/null &
    cd ${HEAD_HOME}
    grunt server -d > /dev/null &
    echo "Start Elasticsearch Server..."
}

stop(){
    cd ${ES_HOME}/bin
    kill $(jps|grep Elasticsearch|awk '{print $1}')
    for exists_head in `lsof -i:9100 | sed -n '2,$p' | awk '{print $2}'`;do
        if [[ ! -z "${exists_head}" ]];then
          kill ${exists_head}
        fi
      done
    echo "Stop Elasticsearch Server..."
}

restart(){
    stop $*
    start $*
}


COMMAND=$1

#参数位置左移1
shift

case ${COMMAND} in
    start )
        start $*
        ;;
	stop )
        stop $*
        ;;
	restart )
        restart $*
        ;;
    * )
		Usage
        exit 1
        ;;
esac
