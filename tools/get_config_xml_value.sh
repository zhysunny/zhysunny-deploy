#!/bin/sh
   
# Author : 章云
# Date   : 2019/8/21 8:46

Usage()
{
    echo "Usage: sh get_config_xml_value.sh <filename> <propertyname>"
    exit 1
}

if [ $# -ne 2 ]
then
    Usage
fi

FILE_NAME=$1
PROPERTY_NAME=$2

declare -i Dline
getline()
{
    # 找到 $PROPERTY_NAME 对应的行号
	grep -n $PROPERTY_NAME $FILE_NAME | head -1 | cut -d ":" -f 1;
}


getlinenum()
{
    # $PROPERTY_NAME 行号+1 为value的行号
	awk "BEGIN{a=`getline`;b="1";c=(a+b);print c}";
}

Dline=`getlinenum`;
# 获取 value 标签的值
sed -n "${Dline}p" $FILE_NAME | sed 's/.*<.*>\([^<].*\)<.*>.*/\1/'
