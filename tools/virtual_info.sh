#!/bin/sh
   
# Author      : 章云
# Date        : 2019/8/21 14:47
# Description : 查看linux环境配置信息

Usage(){
    echo "Usage：(-k | -m | -g | empty) as first argument"
    exit 1
}

param=$1
unit="KB"
if [[ -z ${param} ]]
then
    param="-k"
elif [[ "${param}" = "-k" ]]
then
    unit="KB"
elif [[ "${param}" = "-m" ]]
then
    unit="MB"
elif [[ "${param}" = "-g" ]]
then
    unit="GB"
else
    Usage
fi

mem_arrays=(`free ${param} | grep Mem | awk '{print $2,$3,$4,$6}'`)
echo "总内存大小：${mem_arrays[0]} ${unit}"
echo "已用内存大小：${mem_arrays[1]} ${unit}"
echo "空闲内存大小：${mem_arrays[2]} ${unit}"
echo "缓存内存大小：${mem_arrays[3]} ${unit}"

cpu_count=`grep 'processor' /proc/cpuinfo |wc -l`
echo "CPU核数：${cpu_count}"
