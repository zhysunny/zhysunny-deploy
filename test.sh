#!/bin/sh
   
# Author : 章云
# Date   : 2019/8/21 14:39

# 当前文件所在目录，这里是相对路径
LOCAL_PATH=`dirname $0`
# 当前文件所在目录转为绝对路径
LOCAL_PATH=`cd ${LOCAL_PATH};pwd`

source ${LOCAL_PATH}/tools/Arrays.sh
remove $*