#!/usr/bin/env bash
    
# Author : 章云
# Date   : 2019/9/1 11:35

# 当前文件所在目录，这里是相对路径
LOCAL_PATH=`dirname $0`
# 当前文件所在目录转为绝对路径
LOCAL_PATH=`cd ${LOCAL_PATH};pwd`

export LOCAL_PATH

sh ${LOCAL_PATH}/test/function_test.sh
