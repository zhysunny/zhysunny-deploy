#!/bin/sh
   
# Author : 章云
# Date   : 2019/8/21 13:58

function contains(){
    # 第一个为需要判断的值，后面为数组
    element=$1
    shift
    array=$*
    container=1
    for str in ${array[*]}
    do
        if [[ "${element}" = "${str}" ]]
        then
            container=0
            break
        fi
    done
    echo ${container}
}

function remove() {
    # 第一个为需要删除的元素，后面为数组
    # 删除数组中所有匹配的元素
    element=$1
    shift
    array=$*
    declare -a result=()
    for str in ${array[*]}
    do
        if [[ "${element}" != "${str}" ]]
        then
            result=(${result[*]} ${str})
        fi
    done
    echo ${result[*]}
}