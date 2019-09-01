#!/usr/bin/env bash
    
# Author : 章云
# Date   : 2019/9/1 11:47

Usage(){
    echo "testResult <'$?'> <fileName> <command> <param>"
}

function testResult(){
    if [[ $# -lt 3 ]]
    then
        Usage
        exit 1
    fi
    test=$0
    shift
    file=$1
    shift
    command=$2
    shift
    params=$*
    if [[ ${test} -ne 0 ]]
    then
        echo "Test ${file} ${command} ${params} failure !!!"
        exit ${test}
    else
        echo "Test ${file} ${command} ${params} successful !!!"
    fi
}