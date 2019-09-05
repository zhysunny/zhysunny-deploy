#!/bin/sh
   
# Author : 章云
# Date   : 2019/8/21 14:47

# 把所有shell文件格式改为unix

# 当前文件所在目录，这里是相对路径
local_path=`dirname $0`
# 当前文件所在上级目录目录
path=`cd ${local_path}/../;pwd`

format(){
    dir=$1
    files=(`ls ${dir}`)
    for f in ${files[*]}
    do
        file=${dir}/${f}
        if [[ "$file" == *".sh" || "$file" == *".properties" ]]
        then
            sed -i 's/\r$//' ${file}
        fi
    done
}

format ${path}
format ${path}/tools
format ${path}/tools/apps
format ${path}/tools/service
format ${path}/config
format ${path}/test
